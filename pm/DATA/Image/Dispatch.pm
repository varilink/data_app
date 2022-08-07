package DATA::Image::Dispatch ;

=head1 DATA::Image::Dispatch

Dispatcher for the image app, which uploads images via its upload run mode.

=cut

use strict ;
use warnings ;

use base 'CGI::Application::Dispatch::PSGI' ;

sub dispatch_args {

   my $table ;

   return {

      prefix => 'DATA' ,

      table => [

         'image/upload' => {

            app => 'Image'    ,
            rm  => 'upload' ,

         } ,

      ] ,

   } ;

}

1 ;

__END__
