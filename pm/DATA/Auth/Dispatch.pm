package DATA::Auth::Dispatch ;

=head1 DATA::Auth::Dispatch

Dispatcher for the auth app, which tests requests to access secure resources via
its request run mode.

=cut

use strict ;
use warnings ;

use base 'CGI::Application::Dispatch::PSGI' ;

sub dispatch_args {

   my $table ;

   return {

      prefix => 'DATA' ,

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
