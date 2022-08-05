=head1 facebook-events.pl

This script implements integration of the DATA Diary with the pages associated
with the Derby Arts and Theatre Association's Facebook business account. It does
this via a DATA Diary Facebook application.

The Derby Arts and Theatre Association's Facebook business account has two
pages:

=over

=item Derby Arts & Theatre Association

Public page for Derby Arts and Theatre Association

=item Derby Arts and Theatre Association - Testing

Private (unpublished) page for Derby Arts and Theatre Association that can be
used for testing

=back

=cut

use strict ;
use warnings ;

use Config::General ;
use Data::Dumper ;
use DateTime ;
use DateTime::Duration ;
use DBI ;
use Facebook::OpenGraph ;
use DATA::WhatsOn::Event ;

# 1. Process paramters
# --------------------

=head2 Parameters

In production use this script is run without parameters. For testing purposes
though, parameters can be supplied as follows:

=over

=item -d

Turn debugging on. This enables the output of more messages than will be output
with debugging off.

=item -t offset_days [offset_hours]

Time offset, which can be used to offset the current time so that events become
eligible for posting when that wouldn't otherwise be the case. At least one and
up to two integers can follow this flag, the first is the number of offset days
and the second is the number of offset hours. Either can be positive, which
moves the time in to the future, or negative, which moves it in to the past. To
enter offset hours without offset days set the offset days to 0 and follow with
the offset hours.

=back

=cut

my $debug = 0 ;
my $now = DateTime -> now ( time_zone => 'Europe/London' ) ;

if ( @ARGV ) {

	if ( grep /^-d$/ , @ARGV ) {

		$debug = 1 ;
		print "Debugging enabled\n" ;

	}

	if ( my $posn = grep /^-t$/ , @ARGV ) {

    print	"Applying a time offset\nTrue time: $now\n" if $debug ;

    my $offset_days = $ARGV [ $posn + 1 ] ;
    print "Offset days=$offset_days\n" if $debug ;

    my $offset_hours = 0 ;
    if (
      $ARGV [ $posn + 2 ]
      && $ARGV [ $posn + 2 ] =~ /^-?[0-9]{1,2}$/
			&& $ARGV [ $posn + 2 ] >= -12 && $ARGV [ $posn + 2 ] <= 12
    ) {
      $offset_hours = $ARGV [ $posn + 2 ] ;
      print "Offset hours=$offset_hours\n" if $debug ;
    } else {
			print $posn , $ARGV [ $posn + 2 ] , "\n" ;
      print "Offset hours must be an integer between -12 and 12\n" ;
			goto EXIT ;
    }

    $now -> add ( days => $offset_days, hours => $offset_hours ) ;
    print	"Offset time: $now\n" if $debug ;

	} else {

    print	"Time: $now\n" if $debug ;

  }

}

# 2. Determine if this is the time to do something and exit if it isn't
# ---------------------------------------------------------------------

# We will only post between 9am and 6pm

my $hour = $now -> hour ;
unless ( $hour >= 9 && $hour <= 18 ) {

  print "It isn't posting time - exit\n" if $debug ;
  goto EXIT ;

}

# 3. Load Environment Configuration
# ---------------------------------

my $confObj = new Config::General ( '/usr/local/etc/data/env.cfg' ) ;
my %conf = $confObj -> getall ;
my $access_token = $conf { env } -> { facebook_page_access_token } ;
my $app_id       = $conf { env } -> { facebook_app_id            } ;
my $app_secret   = $conf { env } -> { facebook_app_secret        } ;
my $database     = $conf { env } -> { database                   } ;
my $page_id      = $conf { env } -> { facebook_page_id           } ;
my $root         = $conf { env } -> { root                       } ;

print Dumper $conf { env } if $debug ;

# 4. Retrieve information about the future events from the database
# -----------------------------------------------------------------

# Set from to date only (no time) of now
my $from = new DateTime (
  year	=> $now -> year ,
  month	=> $now -> month ,
  day	=> $now -> day
) ;
# Set to by adding 60 days to from
my $to = $from -> clone ;
$to -> add ( days => 60 ) ;

my $dbh = DBI -> connect (	"dbi:SQLite:dbname=$database" , '' , '' ) ;
my $filter = {
  from   => substr ( $from , 0 , 10 ) ,
  to     => substr ( $to   , 0 , 10 ) ,
  status => 'PUBLISHED'
} ;
my @events = DATA::WhatsOn::Event -> fetch ( $dbh , $filter ) ;
print scalar @events, ' events found between ',	substr ( $from , 0 , 10 ),
  ' and ', substr ( $to , 0 , 10 ), "\n" if $debug ;

# 5. Create the Facebook and Pagefeed objects ready to handle posts
# -----------------------------------------------------------------

my $fb = new Facebook::OpenGraph ({
  app_id       => $app_id       ,
  secret       => $app_secret   ,
	access_token => $access_token ,
  version      => 'v14.0'
}) ;

#-------------------------------------------------------------------------------

# 6. Post to the Page

foreach my $event ( @events ) {

	my ( $message , $days_ahead ) = $event -> post ( $from ) ;

  if (
    ( $days_ahead == 60 && $hour == 20 ) || # 60 days out      8pm - 9pm
    ( $days_ahead == 50 && $hour == 19 ) || # 50 days out      7pm - 8pm
    ( $days_ahead == 40 && $hour == 18 ) || # 40 days out      6pm - 7pm
    ( $days_ahead == 30 && $hour == 17 ) || # 30 days out      5pm - 6pm
    ( $days_ahead == 23 && $hour == 16 ) || # 23 days out      4pm - 5pm
    ( $days_ahead == 16 && $hour == 15 ) || # 16 days out      3pm - 4pm
    ( $days_ahead == 11 && $hour == 14 ) || # 11 days out      2pm - 3pm
    ( $days_ahead ==  6 && $hour == 13 ) || #  6 days out      1pm - 2pm
    ( $days_ahead ==  4 && $hour == 12 ) || #  4 days out     12pm - 1pm
    ( $days_ahead ==  2 && $hour == 11 ) || #  2 days out     11am - 12pm
    ( $days_ahead ==  1 && $hour == 10 ) || #  1 day out      10am - 11am
    ( $days_ahead <=  0 && $hour ==  9 )    # Each day during  9am - 10am
  ) {

    # Time to post to the page

    my $response = $fb -> request (
      'POST' ,
      "/$page_id/feed" ,
      {
        message => $message ,
        link => 'https://derbyartsandtheatre.org.uk/event/' . $event -> rowid
      }
    ) ;

		# Report on the post to stdout, which will send an email to the root email
		# address if the script is running under cron.
		print "\n\nPost:\t\t"		. $event -> name ;
		print "\nStart Date:\t"	. $event -> start_date ;
		print "\nEnd Date:\t"		. $event -> end_date ;
		print "\nDays Ahead:\t"	. $days_ahead . "\n" ;
		print "\nMessage:\t"		. $message ;
		print Dumper $response if ! $response -> is_success ;

	} elsif ( $debug ) {

		# Report a skipped event but only if we're in debug mode

		print "\n\nSkip:\t\t"		. $event -> name ;
		print "\nStart Date:\t"	. $event -> start_date ;
		print "\nEnd Date:\t"		. $event -> end_date ;
		print "\nDays Ahead:\t"	. $days_ahead . "\n" ;

	}

}

EXIT:

1 ;

__END__
