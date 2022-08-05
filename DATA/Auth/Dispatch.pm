package SiteFunk::Auth::Dispatch ;

=head1 SiteFunk::Auth::Dispatch

=cut

use base 'CGI::Application::Dispatch::PSGI' ;

sub dispatch_args {

   my $table ;

   return {

      prefix => 'SiteFunk' ,

      table => [

         'auth/request' => {

            app => 'Auth::Request'    ,
            rm  => 'request' ,

         } ,

      ] ,

   } ;

}

1 ;

__END__
