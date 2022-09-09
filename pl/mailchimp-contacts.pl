use strict ;
use warnings ;

use Config::General ;
use Config::Simple ;
use Data::Dumper ;
use DBI ;
use Digest::MD5 qw / md5_hex / ;
use JSON::PP ;
use Mail::Chimp3 ;
use DATA::WhatsOn::Contact ;
use DATA::WhatsOn::Organisation ;

#-------------------------------------------------------------------------------

#
#  Get configuration, connect to the database and create the Mailchimp object
#

my $name = 'derbyartsandtheatre.org.uk' ;

my $confSim = new Config::Simple ( "/usr/local/etc/DATA/$name.ini" ) ;
my $home = $confSim -> param ( 'home' ) ;

my $confGen = new Config::General ( "$home/env.cfg" ) ;
my %conf = $confGen -> getall ;
my $env = $conf { env } ;

my $database = $env -> { database } ;

my $dbh = DBI -> connect (
  'dbi:SQLite:dbname=' . $env -> { database }  ,
  ''                              ,
  ''
) ;

my $mailchimp = new Mail::Chimp3 (

  api_key => $env -> { mailchimp_api_key }

) ;

#-------------------------------------------------------------------------------

#
# Delete all the current members of the list
#

{

  my $response = $mailchimp -> members (

    list_id => $env -> { mailchimp_list_id } ,
    count => 200

  ) ;

  foreach my $member ( @{ $response -> { content } -> { members } } ) {

    $mailchimp -> delete_member (

      list_id => $env -> { mailchimp_list_id } ,
      subscriber_hash => $member -> { id }

    ) ;

  }

}

#-------------------------------------------------------------------------------

#
#  Get the list of the member society rowids and the DATA rowid
#

my @society_rowids = ( ) ;
my $data_rowid ;

my @organisations = DATA::WhatsOn::Organisation -> fetch ( $dbh ) ;

foreach my $organisation ( @organisations ) {

  push @society_rowids , $organisation -> rowid
    if $organisation -> type eq 'whatson_society' ;

  $data_rowid = $organisation -> rowid if $organisation -> name eq 'DATA' ;

}

#-------------------------------------------------------------------------------

#
# List the contacts in the current database and add the to the subscription list
#

my @contacts = DATA::WhatsOn::Contact -> fetch ( $dbh ) ;

foreach my $contact ( @contacts ) {

  if ( $contact -> email ) {

    my ( $isRepresentative , $isMember ) = ( \0 , \0 ) ;

    foreach my $contact_organisation ( @{ $contact -> organisations } ) {

      my $organisation_rowid = $contact_organisation -> organisation_rowid ;

        $isRepresentative = \1
          if grep ( /^$organisation_rowid$/ , @society_rowids ) ;

        $isMember = \1
          if grep ( /^$organisation_rowid$/ , @society_rowids ) ||
            $organisation_rowid == $data_rowid ;

    }

    my $response = $mailchimp -> add_member (

      list_id => $env -> { mailchimp_list_id } ,
      email_address => $contact -> email ,
      status => 'subscribed' ,
      merge_fields => {
        FNAME => $contact -> first_name ,
        LNAME => $contact -> surname
      } ,
      interests => {
        $env -> { mailchimp_representative_interest_id }
          => $isRepresentative  ,
        $env -> { mailchimp_member_interest_id }
          => $isMember
      }

    ) ;

    print Dumper $response if $response -> { code } ne '200' ;

  }

}

#-------------------------------------------------------------------------------

#
# Do the same for organisations
#

foreach my $organisation ( @organisations ) {

  if ( $organisation -> email ) {

    my $response = $mailchimp -> add_member (

      list_id => $env -> { mailchimp_list_id } ,
      email_address => $organisation -> email ,
      status => 'subscribed'

    ) ;

    print Dumper $response if $response -> { code } ne '200' ;

  }

  # Now fetch the individual organisation to get its functions

  $organisation -> fetch ( $dbh ) ;

  foreach my $function ( @{ $organisation -> functions } ) {

    if ( $function -> email ) {

      my $response = $mailchimp -> add_member (

        list_id => $env -> { mailchimp_list_id } ,
        email_address => $function -> email ,
        status => 'subscribed'

      ) ;

      print Dumper $response if $response -> { code } ne '200' ;

    }

  }

}

1 ;

__END__
