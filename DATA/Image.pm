package DATA::Image ;

=head1 DATA::Image

DATA image upload (from own PC) or copy (from external website) handler.

=cut

use strict ;

use base qw / DATA::Main / ;

use Data::FormValidator ;
use Data::FormValidator::Constraints::Upload qw /
	file_format
	file_max_bytes
	image_max_dimensions
	image_min_dimensions
/ ;
use JSON ;
use DATA::Image::Constraints ;

sub _filepath {

	my ( $self , $suffix ) = @_ ;
	my $env = $self -> conf -> param ( 'env' ) ;
	my $upload_path = $env -> { image_upload_path } ;

	my ( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst )
		= localtime ( time ) ;

	my $filepath =
		$upload_path																				.
		( $year += 1900 )																		. '_' .
		sprintf ( "%02d" , $mon + 1 )												. '_' .
		sprintf ( "%02d" , $mday )													. '-' .
		$hour . ':' . $min . ':' . $sec . '.' . $suffix ;

	return $filepath ;

}

sub setup {

	my $self = shift ;

	$self -> run_modes ( {

		'upload'	=> 'upload' ,
		'proxy'		=> 'proxy'

	} ) ;

}

=head2 run modes

=cut

sub upload {

=head3 upload

Upload a file from the users own PC

=cut

	my $self = shift ;
	my $query = $self -> query ;

	my $profile = {

		required => [ qw / file / ] ,

		constraint_methods => {

			file => [
				file_format ( ) ,
				file_max_bytes ( 2000000 ) ,
			] ,
		}

	} ;

	my $results = Data::FormValidator -> check ( $query , $profile ) ;

	my $response ;

	if ( my $errors = $results -> invalid ( 'file' ) ) {

		$self -> header_props (	-status => '400' ) ;

		if ( grep /^file_format$/ , @{ $errors } ) {

			$response =
				'Invalid file format, must be a JPG/JPEG, GIF or PNG image.' ;

		} elsif ( grep /^file_max_bytes$/ , @{ $errors } ) {

			# I am not sure that this will ever be returned since nginx imposes a
			# limit on upload size before we ever get to the app
			$response = 'File is too large, must not exceed 2Mbytes.' ;

		}

		goto RESPONSE ;

	}

	# In the case of an upload, the file is provided as a BLOB accessed via the

	my $tmpfile = $query -> upload ( 'file' ) ;
	my $filename = $query -> param ( 'file' ) ;
	my $type = $query -> uploadInfo ( $filename ) -> { 'Content-Type' } ;

	my $suffix ;
	if 		( $type eq 'image/jpeg' )	{ $suffix = 'jpg' }
	elsif	( $type eq 'image/gif' )	{ $suffix = 'gif' }
	elsif	( $type eq 'image/png' )	{ $suffix = 'png' } ;

	my $filepath = $self -> _filepath ( $suffix ) ;

	unless (
		open ( LOCAL , ">$filepath" )
	) {
		$self -> header_props ( -status => '400' ) ;
		$response =
			'Error uploading, please report to admin@derbyartsandtheatre.org.uk' ;
		goto RESPONSE ;
	} ;

	while ( <$tmpfile> ) { print LOCAL $_ ; }
	close LOCAL ;

	$response = encode_json ( { 'location' => $filepath } ) ;

RESPONSE:

	return $response ;

}

sub proxy {

=head3 proxy

Server side handler for TinyMCE imagetools_proxy. This retrieves a remote (not
within our domain) image and pipes it back to TinyMCE as if it was local.

=cut

	my $self = shift ;
	my $query = $self -> query ;

	my $max_size = $self -> conf -> param ( 'max_image_size' ) ;

	my $profile = {

		required => [ qw / url / ] ,

		constraint_methods => {

			url => {
				constraint_method	=> image_valid ( $max_size ) ,
				name							=> 'image_valid'
			} ,
		} ,

	} ;

	my $results = Data::FormValidator -> check ( $query , $profile ) ;

	my $response ;

	if ( my $errors = $results -> invalid ( 'url' ) ) {

		$self -> header_props (	-status => '400' ) ;

		$response =
			'Invalid - the image must be in JPG/JPEG, GIF or PNG format and not ' .
			'greater than 2Mbytes in size. Please try again.' ;

		goto RESPONSE ;

	}

	my $image = DATA::Image::Constraints -> image ;
	my $type = $image -> { MIME_TYPE } ;
	$response = $image -> { BLOB } ;

#	my $suffix ;
#	if 		( $type eq 'image/jpeg' )	{ $suffix = 'jpg' }
#	elsif	( $type eq 'image/gif' )	{ $suffix = 'gif' }
#	elsif	( $type eq 'image/png' )	{ $suffix = 'png' } ;

#	my $filepath = $self -> _filepath ( $suffix ) ;

#	unless (
#		open ( LOCAL , ">/var/local/www-data$filepath" )
#	) {
#		$self -> header_props ( -status => '400' ) ;
#		$response =
#			'Error uploading, please report to admin@derbyartsandtheatre.org.uk' ;
#		goto RESPONSE ;
#	} ;

#	print LOCAL $blob ;
#	close LOCAL ;

#	$response = encode_json ( { 'location' => $filepath } ) ;

	$self -> header_props ( -type => $type ) ;

RESPONSE:

	return $response ;

}

1 ;

__END__
