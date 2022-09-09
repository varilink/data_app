=head1 facebook-unsubscribe

This script posts an invitation to subscribe to the monthly, DATA, email
bulletin via Facebook.

=cut

use strict ;
use warnings ;

use Config::General ;
use Config::Simple ;
use Data::Dumper ;
use Facebook::Graph ;

#-------------------------------------------------------------------------------

# 1. Get the relevant information from the configuration files

my $name                = 'derbyartsandtheatre.org.uk' ;
my $ini                  = new Config::Simple (
                          "/usr/local/etc/DATA/$name.ini"
                        ) ;
my $home                = $ini -> param ( 'home' ) ;
my $confObj              = new Config::General ( "$home/env.cfg" ) ;
my %conf                = $confObj -> getall ;
my $access_token  = $conf { env } -> { facebook_page_access_token  } ;
my $app_id        = $conf { env } -> { facebook_app_id            } ;
my $app_secret    = $conf { env } -> { facebook_app_secret        } ;
my $page_id        = $conf { env } -> { facebook_page_id            } ;
my $signup_form   = $conf { env } -> { mailchimp_signup_form_url  } ;

#-------------------------------------------------------------------------------

# 2. Create Facebook and Pagefeed objects ready to handle posts

my $fb = new Facebook::Graph (
  access_token  => $access_token  ,
  app_id        => $app_id        ,
  secret        => $app_secret    ,
) ;

my $pf = $fb -> add_page_feed ;
$pf -> set_page_id ( $page_id ) ;

#-------------------------------------------------------------------------------

# 3. Post the subscribe invitation

my $message = <<EOF ;
You can subscribe to DATA's monthly email bulletin by registering as a DATA
Contact via the link below.
EOF

$pf -> set_message ( $message ) ;
$pf -> set_link_uri ( $signup_form ) ;
my $response = $pf -> publish ;

print Dumper $response if $response -> response -> code != 200 ;

1 ;

__END__
