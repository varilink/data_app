=head1 twitter-events

This script tweets about events on behalf of Derby Arts and Theatre Association.

=cut

use strict ;
use warnings ;

use Config::General ;
use Config::Simple ;
use DateTime ;
use DBI ;
use Image::Grab qw / grab / ;
use Twitter::API ;
use DATA::WhatsOn::Event ;

#-------------------------------------------------------------------------------

# 1. Process parameters

=head2 Parameters

In production use this script is run without parameters. For testing purposes
though, parameters can be supplied as follows:

=over

=item -d

Turn debugging on. This enables the output of more messages than will be output
with debugging off.

=item -t offset_days [offset_hours]

Time offset, which can be used to offset the current time so that events become
eligible for Tweeting when that wouldn't otherwise be the case. Up to two
integers can follow this flag, the first is the number of offset days and the
second is the number of offset hours. Either can be positive, which moves the
time in to the future, or negative, which moves it in to the past.

=back

=cut

my $debug = 0 ;
my $time = DateTime -> now ( time_zone => 'Europe/London' ) ;

if ( @ARGV ) {

  if ( grep /^-d$/ , @ARGV ) {

    $debug = 1 ;
    print "Debugging enabled\n" ;

  }

  if ( my $posn = grep /^-t$/ , @ARGV ) {

    print "Applying a time offset\n" ;
    my $offset_days = $ARGV [ $posn + 1 ] ;
    print "Offset days=$offset_days\n" ;
    my $offset_hours = 0 ;

    if ( $ARGV [ $posn + 2 ] &&  $ARGV [ $posn + 2 ] =~ /-?[0-9]{1,2}/ ) {

      $offset_hours = $ARGV [ $posn + 2 ] ;
      print "Offset hours=$offset_hours\n" ;

    }

    my $offset_seconds = $offset_days * 24 * 60 * 60 ;
    $offset_seconds += $offset_hours * 60 * 60 if $offset_hours ;

    my $true = DateTime -> now ;
    my $from_epoch = $true -> epoch ;

    no warnings 'redefine' ;
    local *DateTime::_core_time =
      sub { return $from_epoch + $offset_seconds } ;
    $time = DateTime -> now ( time_zone => 'Europe/London' ) ;

  }

}

#-------------------------------------------------------------------------------

# 2. Determine if this is the time to do something and exit if it isn't

# Create a DateTime object from the current datetime in the local timezone
my $hour = $time -> hour ;
print  "London time: $time\n" if $debug ;

# Create a DateTime object using the current date in UTC
my $now = new DateTime (
  year  => $time -> year ,
  month  => $time -> month ,
  day  => $time -> day
) ;

# We have five hour slots during which we will Tweet - 10am -> 11am, 12pm - 1pm,
# 2pm - 3pm, 4pm - 5pm and 6pm - 7pm

unless ( $hour >= 9 && $hour <= 18 ) {

  print "It isn't tweeting time - exit\n" if $debug ;
  goto EXIT ;

}

#-------------------------------------------------------------------------------

# 3. Get the relevant information from the configuration files

my $name                = 'derbyartsandtheatre.org.uk' ;
my $ini                  = new Config::Simple (
                          "/usr/local/etc/DATA/$name.ini"
                        ) ;
my $home                = $ini -> param ( 'home' ) ;
my $confObj              = new Config::General ( "$ENV{'DATA_CONF'}/app.cfg" ) ;
my %conf                = $confObj -> getall ;
my $consumer_key        = $conf { env } -> { twitter_consumer_key          } ;
my $consumer_secret      = $conf { env } -> { twitter_consumer_secret      } ;
my $access_token        = $conf { env } -> { twitter_access_token          } ;
my $access_token_secret  = $conf { env } -> { twitter_access_token_secret  } ;
my $database            = $conf { env } -> { database                      } ;
my $root                = $conf { env } -> { root                          } ;
my $upload_path          = $conf { env } -> { image_upload_path            } ;

#-------------------------------------------------------------------------------

# 4. Retrieve information about the future events from the database

# Copy now and add 60 days
my $to = $now -> clone ;
$to -> add ( days => 60 ) ;

my $dbh = DBI -> connect (  "dbi:SQLite:dbname=$database" , '' , '' ) ;
my $filter = {
  from    =>  substr ( $time  , 0 , 10 ) ,
  to      =>  substr ( $to  , 0 , 10 ) ,
  status  =>  'PUBLISHED'
} ;
my @events = DATA::WhatsOn::Event -> fetch ( $dbh , $filter ) ;

#-------------------------------------------------------------------------------

# 5. Create the Net::Twitter object to handle the status updates

my $client = Twitter::API -> new_with_traits (
  traits              => 'Enchilada'          ,
  consumer_key        => $consumer_key        ,
  consumer_secret      => $consumer_secret      ,
  access_token        => $access_token        ,
  access_token_secret  => $access_token_secret  ,
) ;

#-------------------------------------------------------------------------------

# 6. Do the business (or not)

foreach my $event ( @events ) {

  # Report what we are doing, note that we build some of the status content
  # before we've decided if we're going to Tweet or not because otherwise we
  # would have to repeat this logic multiple times in the big if structure
  # below.

  my $rel_who ;

  if ( $event -> presented_by ) {

    if ( $event -> presented_by =~ /^"(.+)"$/ ) {

      $rel_who = lcfirst $1 ;

    } else {

      $rel_who = 'presented by ' . $event -> presented_by ;

    }

  } else {

    $rel_who = 'presented by ' . $event -> society_name ;

  }

  my $rel_who_where = $rel_who . ' at ' . $event -> venue_name ;

  my $twitter_handle = '' ;

  if ( $event -> society_rowid ) {

    # This is an event associated with a member society (the vast majority of
    # them are). See if we have their Twitter handle on record so that we can
    # include it in the Tweet.

    my $society = new DATA::WhatsOn::Organisation ;
    $society -> rowid ( $event -> society_rowid ) ;
    $society -> fetch ( $dbh ) ;

    #use Data::Dumper ;
    #print Dumper $society ;

    foreach my $handle ( @{ $society -> handles } ) {

      if ( $handle -> platform_name eq 'Twitter' ) {

        $twitter_handle = $handle -> handle ;

      }

    }

  }

  my ( $status , $days_ahead ) = $event -> post ( $now ) ;

  if (
    ( $days_ahead ==  60  && $hour == 20  ) ||  # 60  days out      8pm - 9pm
    ( $days_ahead ==  50  && $hour == 19  ) ||  # 50  days out      7pm - 8pm
    ( $days_ahead ==  40  && $hour == 18  ) ||  # 40  days out      6pm - 7pm
    ( $days_ahead ==  30  && $hour == 17  ) ||  # 30  days out      5pm - 6pm
    ( $days_ahead ==  23  && $hour == 16  ) ||  # 23  days out      4pm - 5pm
    ( $days_ahead ==  16  && $hour == 15  ) ||  # 16  days out      3pm - 4pm
    ( $days_ahead ==  11  && $hour == 14  ) ||  # 11  days out      2pm - 3pm
    ( $days_ahead ==  6    && $hour == 13  ) ||  # 6    days out      1pm - 2pm
    ( $days_ahead ==  4    && $hour == 12  ) ||  # 4    days out      12pm - 1pm
    ( $days_ahead ==  2    && $hour == 11  ) ||  # 2    days out      11am - 12pm
    ( $days_ahead ==  1    && $hour == 10  ) ||  # 1    day out        10am - 11am
    ( $days_ahead <=  0    && $hour == 9    )      # Each day during    9am - 10am
  ) {

    # Time to Tweet.

    # Append the URL for the event on our website to the Tweet
    $status .= " $root" . 'event/' . $event -> rowid ;

    # If we have a Twitter handle on record for the society then append that
    # also to the status update

    if ( $twitter_handle ) {

      $status .= " $twitter_handle" ;

    }

    # Report on the Tweet to stdout, which will send an email to the root email
    # address if the script is running under cron.
    print "\n\nTweet:\t\t"  . $event -> name ;
    print "\nStart Date:\t"  . $event -> start_date ;
    print "\nEnd Date:\t"    . $event -> end_date ;
    print "\nDays Ahead:\t"  . $days_ahead . "\n" ;
    print "\nStatus:\t"      . $status ;

    # Go ahead and Tweet

    my $media_id ;

    if ( $event -> image ) {

      # The event has an image associated with it. So, before we Tweet we upload
      # the image so that it can be used in the Tweet.

      # First get the image as a raw binary file

      my $url = '' ;

      if ( $event -> image =~ /^$upload_path/ ) {

        # An uploaded image has been used
        $url = $root . $event -> image ;

      } else {

        # A link to an image on a remote website has been used
        $url = $event -> image ;

      }

      my $image = grab ( URL => $url ) ;

      my $response =
        $client -> upload_media ( [ undef , '' , Content => $image ] ) ;

      $media_id = $response -> { media_id } ;

    }

    if ( $event -> image ) {

      # Include the image along with the status update

      eval {
        $client -> update ( { status => $status , media_ids => "$media_id" } )
      } ; warn $@ if $@ ;

    } else {

      # No image to include, just do a straight text status update

      eval {
        $client -> update ( $status )
      } ; warn $@ if $@ ;

    }

    # If we're not debugging, sleep a while so that Tweets don't get posted
    # bang on top of each other in an obvious machine way.
    sleep 600 unless $debug ;

  } elsif ( $debug ) {

    # There is no status update to Tweet. Report a skipped event if in debug.

    print "\n\nSkip:\t\t"    . $event -> name ;
    print "\nStart Date:\t"  . $event -> start_date ;
    print "\nEnd Date:\t"    . $event -> end_date ;
    print "\nDays Ahead:\t"  . $days_ahead . "\n" ;

  }

}

#-------------------------------------------------------------------------------

EXIT:

1 ;

__END__
