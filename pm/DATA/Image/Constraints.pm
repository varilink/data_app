package DATA::Image::Constraints ;

=head1 DATA::Image::Constraints

Constraints applied to an image referenced by its URL, i.e. the validated value
is the URL of the image. These can be applied to an image that's either hosted
on our own site or hosted externally.

=cut

use strict ;
use warnings ;

use base qw / Exporter / ;

use File::LibMagic ;
use LWP::UserAgent ;

our @EXPORT = qw /

  image_valid

/ ;

# Package scoped variable so that we can retain the retrieved image once it is
# validated, rather than have to retrieve it again.
our $image = { } ;

sub image {
  return $image ;
}

=head2 Constraints

=cut

sub image_valid {

=head3 image_valid

Effectively tests three things:
1. That the URL given corresponds to a valid location - returns HTTP 200;
2. That an image object of a valid image MIME type is retrieved;
3. That the image does not exceed the file limit.

=cut

  my $max_size = shift ;

  return sub {

    my ( $dfv , $value ) = @_ ; # value will be the URL of the image
    my $rc = 0 ; # Return code - assume failure until proved otherwise

    my $ua = new LWP::UserAgent ;
    # Set a maxiumum response size. The header 'Client-Aborted' will be set in
    # the response if this size limit is applied.
    $ua -> max_size ( $max_size ) ;
    my $response = $ua -> get ( $value ) ;

    if (
      $response -> is_success && !$response -> header ( 'Client-Aborted')
    ) {

      my $magic = new File::LibMagic ;
      my $mime_type = $magic ->
        info_from_string ( $response -> content ) -> { mime_type } ;

      if (
        $mime_type eq 'image/gif'   ||
        $mime_type eq 'image/jpeg'  ||
        $mime_type eq 'image/png'
      ) {

        $rc = 1 ;
        $image -> { MIME_TYPE } = $mime_type ;
        $image -> { BLOB } = $response -> content ;

      }

    }

    return $rc ;

  }

}

1 ;

__END__
