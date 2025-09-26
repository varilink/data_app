package DATA::Image;

=head1 DATA::Image

DATA image upload handler.

=cut

use strict;
use warnings;

use base qw/DATA::Main/;

use Data::Dumper;
use Data::FormValidator;
use Data::FormValidator::Constraints::Upload qw/
    file_format
    file_max_bytes
    image_max_dimensions
    image_min_dimensions
/;
use JSON;
use DATA::Image::Constraints;

sub _filepath {

  my ( $self , $suffix ) = @_ ;
  my $upload_path = $self->conf->param('image_upload_path');

  my ( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst )
    = localtime ( time ) ;

  my $filepath =
    $upload_path                                        .
    ( $year += 1900 )                                    . '_' .
    sprintf ( "%02d" , $mon + 1 )                        . '_' .
    sprintf ( "%02d" , $mday )                          . '-' .
    $hour . ':' . $min . ':' . $sec . '.' . $suffix ;

  return $filepath ;

}

sub setup {
    my $self = shift;
    $self->run_modes({ 'upload' => 'upload' });
}

=head2 run modes

=cut

sub upload {

=head3 upload

Upload a file from the users own PC

=cut

  my $self = shift ;
  $self->log->notice( "Entered upload run mode of Image application\n" );
  my $query = $self -> query ;
  $self->log->debug(Dumper($query));

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

    $self -> header_props (  -status => '400' ) ;

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
  if     ( $type eq 'image/jpeg' )  { $suffix = 'jpg' }
  elsif  ( $type eq 'image/gif' )  { $suffix = 'gif' }
  elsif  ( $type eq 'image/png' )  { $suffix = 'png' } ;

  my $filepath = $self -> _filepath ( $suffix ) ;

  $self->log->info("\$filepath=$filepath\n");

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

1;

__END__
