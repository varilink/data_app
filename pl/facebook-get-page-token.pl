use strict ;
use warnings ;

use Config::General ;
use Data::Dumper ;
use Facebook::OpenGraph ;

my $confObj = new Config::General ( '/usr/local/etc/data/env.cfg' ) ;
my %conf = $confObj -> getall ;
my $app_id = $conf { env } -> { facebook_app_id } ;
my $app_secret = $conf { env } -> { facebook_app_secret } ;
my $page_id = $conf { env } -> { facebook_page_id } ;

$short_term_user_token = $ARGV [ 0 ] ;

my $fb = new Facebook::OpenGraph ( {
  app_id => $app_id ,
  secret => $app_secret ,
  version => 'v14.0'
} ) ;

# 1. Get long term user token
# ---------------------------

my $long_term_user_token = $fb -> request ( 'GET' , '/oauth/access_token' , {
  grant_type => 'fb_exchange_token' ,
  client_id => $app_id ,
  client_secret => $app_secret ,
  fb_exchange_token => $short_term_user_token
} ) -> as_hashref -> { access_token } ;

# 2. Get page token
# -----------------

my $page_token = $fb -> request ( 'GET' , "/$page_id" , {
  fields => 'access_token' ,
  access_token => $long_term_user_token
} ) -> as_hashref -> { access_token } ;

# 3. Report page token
# --------------------

$fb -> set_access_token ( $fb -> get_app_token -> { access_token } ) ;

my $expires_at = $fb -> request ( 'GET' , '/debug_token' , {
  input_token => $page_token
} ) -> as_hashref -> { data } -> { data_access_expires_at } ;

print
  "\nPage token:\n\n$page_token\n\nExpires at " ,
  scalar localtime $expires_at ,
  "\n" ;
