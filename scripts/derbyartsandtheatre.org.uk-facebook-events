#!/usr/bin/perl

use strict ;
use warnings ;

use Config::General ;
use Config::Simple ;
use Data::Dumper ;
use DateTime ;
use DBI ;
use Facebook::Graph ;
use SiteFunk::WhatsOn::Event ;

#-------------------------------------------------------------------------------

# 1. Process paramters

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
print	"London time: $time\n" if $debug ;

# Create a DateTime object using the current date in UTC
my $now = new DateTime (
	year	=> $time -> year ,
	month	=> $time -> month ,
	day	=> $time -> day
) ;

# We will only post between 9am and 6pm

unless ( $hour >= 9 && $hour <= 18 ) {

	print "It isn't posting time - exit\n" if $debug ;
	goto EXIT ;

}

#-------------------------------------------------------------------------------

# 3. Load Environment Configuration

my $name = 'derbyartsandtheatre.org.uk' ;
my $ini = new Config::Simple ( "/usr/local/etc/sitefunk/$name.ini" ) ;
my $home = $ini -> param ( 'home' ) ;
my $confObj = new Config::General ( "$home/env.cfg" ) ;
my %conf = $confObj -> getall ;
my $access_token	= $conf { env } -> { facebook_page_access_token	} ;
my $app_id				= $conf { env } -> { facebook_app_id						} ;
my $app_secret		= $conf { env } -> { facebook_app_secret				} ;
my $database			= $conf { env } -> { database										} ;
my $page_id				= $conf { env } -> { facebook_page_id						} ;
my $root					= $conf { env } -> { root												} ;

#-------------------------------------------------------------------------------

# 4. Retrieve information about the future events from the database

# Copy now and add 60 days
my $to = $now -> clone ;
$to -> add ( days => 60 ) ;

my $dbh = DBI -> connect (	"dbi:SQLite:dbname=$database" , '' , '' ) ;
my $filter = {
	from		=>	substr ( $time	, 0 , 10 ) ,
	to			=>	substr ( $to		, 0 , 10 ) ,
	status	=>	'PUBLISHED'
} ;
my @events = SiteFunk::WhatsOn::Event -> fetch ( $dbh , $filter ) ;

#-------------------------------------------------------------------------------

# 5. Create the Facebook and Pagefeed objects ready to handle posts

my $fb = new Facebook::Graph (
	access_token	=> $access_token	,
	app_id				=> $app_id				,
	secret				=> $app_secret		,
) ;

my $pf = $fb -> add_page_feed ;
$pf -> set_page_id ( $page_id ) ;

#-------------------------------------------------------------------------------

# 6. Post to the Page

foreach my $event ( @events ) {

	my ( $message , $days_ahead ) = $event -> post ( $now ) ;

	if (
		( $days_ahead ==	60	&& $hour == 20	) ||	# 60	days out			8pm - 9pm
		( $days_ahead ==	50	&& $hour == 19	) ||	# 50	days out			7pm - 8pm
		( $days_ahead ==	40	&& $hour == 18	) ||	# 40	days out			6pm - 7pm
		( $days_ahead ==	30	&& $hour == 17	) ||	# 30	days out			5pm - 6pm
		( $days_ahead ==	23	&& $hour == 16	) ||	# 23	days out			4pm - 5pm
		( $days_ahead ==	16	&& $hour == 15	) ||	# 16	days out			3pm - 4pm
		( $days_ahead ==	11	&& $hour == 14	) ||	# 11	days out			2pm - 3pm
		( $days_ahead ==	6		&& $hour == 13	) ||	# 6		days out			1pm - 2pm
		( $days_ahead ==	4		&& $hour == 12	) ||	# 4		days out			12pm - 1pm
		( $days_ahead ==	2		&& $hour == 11	) ||	# 2		days out			11am - 12pm
		( $days_ahead ==	1		&& $hour == 10	) ||	# 1		day out				10am - 11am
		( $days_ahead <=	0		&& $hour == 9		)			# Each day during		9am - 10am
	) {

		# Time to post to the page

		$pf -> set_message ( $message ) ;
		#$pf -> set_link_uri ( $root . 'event/' . $event -> rowid ) ;
		$pf -> set_link_uri (
			$root . 'event/' . $event -> rowid
		) ;
		my $response = $pf -> publish ;

		# Report on the Tweet to stdout, which will send an email to the root email
		# address if the script is running under cron.
		print "\n\nPost:\t\t"		. $event -> name ;
		print "\nStart Date:\t"	. $event -> start_date ;
		print "\nEnd Date:\t"		. $event -> end_date ;
		print "\nDays Ahead:\t"	. $days_ahead . "\n" ;
		print "\nMessage:\t"		. $message ;
		print Dumper $response if $response -> response -> code != 200 ;

	} elsif ( $debug ) {

		# Report a skipped event but only if we're in debug mode

		print "\n\nSkip:\t\t"		. $event -> name ;
		print "\nStart Date:\t"	. $event -> start_date ;
		print "\nEnd Date:\t"		. $event -> end_date ;
		print "\nDays Ahead:\t"	. $days_ahead . "\n" ;

	}

}

#-------------------------------------------------------------------------------

EXIT:

1 ;

__END__
