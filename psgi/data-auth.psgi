use strict ;
use warnings ;

use DATA::Auth::Dispatch ;
use CGI::PSGI qw / -utf8 / ;

sub {

   my $env = shift ;

   # Dispatch the request

   my $app = DATA::Auth::Dispatch -> as_psgi (

      args_to_new => {
         QUERY => CGI::PSGI -> new ( $env )
      }

   ) ;

   return $app -> ( $env ) ;

}
