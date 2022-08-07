package DATA::Auth::Dispatch ;

=head1 DATA::Auth::Dispatch

=cut

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
