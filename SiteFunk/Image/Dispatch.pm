package SiteFunk::Image::Dispatch ;

=head1 SiteFunk::Image::Dispatch

=cut

use base 'CGI::Application::Dispatch::PSGI' ;

sub dispatch_args {

   my $table ;

   return {

      prefix => 'SiteFunk' ,

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
