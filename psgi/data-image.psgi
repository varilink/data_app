use strict ;
use warnings ;

use DATA::Image::Dispatch ;
use CGI::PSGI ;

sub {

   my $env = shift ;

   # Dispatch the request

   my $app = DATA::Image::Dispatch -> as_psgi (

      args_to_new => {
         QUERY => CGI::PSGI -> new ( $env )
      }

   ) ;

   return $app -> ( $env ) ;

}
