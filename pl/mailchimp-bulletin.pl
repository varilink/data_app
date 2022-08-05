use strict ;
use warnings ;

use Config::General ;
use Config::Simple ;
use CSS::Inliner ;
use Data::Dumper ;
use DateTime ;
use DateTime::Duration ;
use DBI ;
use File::Basename ;
use File::Slurp ;
use HTML::Packer ;
use Image::Grab qw / grab / ;
use Mail::Chimp3 ;
use MIME::Base64 ;
use DATA::WhatsOn::Event ;
use DATA::WhatsOn::NewsItem ;
use Template ;

#-------------------------------------------------------------------------------

#
# Process the command line arguments
#

my $help = << 'EndofHelp'
Options:

-h
Print this message and exit. Any other options provided are ignored.

-d n
The number of days (integer n) from today that event listings should start from.
If this is omitted then they will start from the current system date.

-e n
The number of events (integer n) to list. If this is omitted then this will
default to twelve.

-g filepath
The filepath to a file containing HTML that is to be used in the guidance to
member representatives section. If this is omitted then that section will not
be included in the bulletin.

-n n
The number of news items (integer n) to list. If this is omitted then that
section will not be included in the bulletin.

-o filepath
If this is set then this script will output the generated HTML that it uses for
the Mailchimp template to a file. This file can then be downloaded and syntax
checked.

EndofHelp
;

my %params ;

my $option	; # Used to capture valid options
my $getint	; # Used to indicate that an integer value is expected for an option
my $getpath ;	# Used to indicate that a filepath value for an existing file is
							# expected for an option
my $getdir	; # Used to indicate that a filepage value for a new file but within
							# an existing directory is expected for an option

ARG:
foreach my $arg ( @ARGV ) {

	if ( $option && ( $getint || $getpath || $getdir ) ) {

		# Check for valid values for an option flag on the previous loop

		if ( $getint ) {

			# Look for an integer value for an option
			unless ( $arg eq int ( $arg ) && $arg > 0 ) {

				print STDERR "Invalid value specified - not positive integer\n" ;
				print STDERR $help ;
				exit ;

			}

		} elsif ( $getpath ) {

			# Look for a filepath value for an option and test it corresponds to an
			# existing text file
			unless ( -T $arg ) {

				print STDERR "Invalid guidance filepath specified\n" ;
				print STDERR $help ;
				exit ;

			}

		} elsif ( $getdir ) {

			# Look for a filepath value for an option and test that the directory of
			# the filepath exists. By contrast to $getpath this option will create a
			# file so the file itself doesn't need to exist already, only the
			# directory within which the file will reside.
			my $dir = dirname $arg ;
			unless ( -e $dir && -e $dir ) {

				print STDERR "Directory for output file does not exist\n" ;
				print STDERR $help ;
				exit ;

			}

		}

		$params { $option } = $arg ;
		$option = undef; $getint = undef; $getpath = undef; $getdir = undef;
		next ARG ;

	}


	if ( $arg eq '-h' ) {

		print $help ;
		exit ;

	} elsif ( $arg eq '-d' ) {

		# Valid days option, which must have an integer value
		$option = 'days' ; $getint = 1 ;

	} elsif ( $arg eq '-e') {

		# Valid events option, which must have an integer value
		$option = 'events'; $getint = 1 ;

	} elsif ( $arg eq '-g' ) {

		# Valid guidance option, which must have a filepath value
		$option = 'guidance'; $getpath = 1;

	} elsif ( $arg eq '-n' ) {

		# Valid news items option, which must have an integer value
		$option = 'news'; $getint = 1 ;

	} elsif ( $arg eq '-o' ) {

		# Valid output option, which must have a filepath value
		$option = 'output'; $getdir = 1;

	} else {

		print STDERR "Invalid option $arg specified\n" ;
		print STDERR $help ;
		exit ;

	}

}

$params { events } = 12 unless $params { events } ;

#-------------------------------------------------------------------------------

#
# Load up configuration
#

my $ini = new Config::Simple (
	'/usr/local/etc/DATA/derbyartsandtheatre.org.uk.ini'
) ;

my $home = $ini -> param ( 'home' ) ;

my $cObj = new Config::General ( "$home/env.cfg" ) ;
my %cHash = $cObj -> getall ;
my $env = $cHash { env } ;
my $upload_path = $env -> { image_upload_path } ;

#-------------------------------------------------------------------------------

#
# Derive today as a datetime and offset it if we've been told to
#

my $today = DateTime -> today ;
my $date_to_use = $today -> clone ;

if ( $params { days} ) {

	my $offset = new DateTime::Duration ( { days	=> $params { days } }	) ;
	$date_to_use -> add ( $offset ) ;

}

print	'Building bulletin as of '										.
	sprintf ( '%02d' , $date_to_use -> day		) . '/' .
	sprintf ( '%02d' , $date_to_use -> month	) . '/' .
	$date_to_use -> year . "\n" ;

my $month = $date_to_use -> month_name . ' '  . $date_to_use -> year ;
my $bulletin = 'DATA Bulletin - ' . $month ;

print "Building a bulletin called $bulletin\n" ;

#-------------------------------------------------------------------------------

#
# Create the mailchimp API object ready to use
#

my $mailchimp = new Mail::Chimp3 (

  api_key => $env -> { mailchimp_api_key }

) ;

my $response ; # We will use to capture Mailchimp API responses throughout

#-------------------------------------------------------------------------------

#
# Clear down any content that we are obviously replacing. We do this by deleting
# objects in the following sequence:
# 1. Images;
# 2. Folders (in the content management system) that contain the images;
# 3. Campaigns;
# 4. Templates.

print "***** STARTING CLEARDOWN *****\n" ;

# Look for objects added recently, in the last day
my $one_day = new DateTime::Duration ( { days	=> 1 }	) ;
my $yday = $today -> clone ;
$yday -> subtract ( $one_day ) ;

#-------------------------------------------------------------------------------
# 1. Images

$response = $mailchimp -> file_manager_files (
	count							=> 30				, # Up to 30, which should be sufficient
	since_created_at	=> "$yday"	, # Created since yesterday
	type							=> 'image'	, # It is an image file
) ;

# Double check that this is truly a file that we want to delete.
# If it is then it will be in a folder whose name is the same as this month's
# bulletin name.
foreach my $image ( @{ $response -> { content } -> { files } } ) {

	if ( $image -> { folder_id } ) {

		# This image is in a folder. Find out if it's the correct one.

		$response = $mailchimp -> file_manager_folder (
			folder_id => $image -> { folder_id }
		) ;

		my $folder_name = $response -> { content } -> { name } ;

		if ( $folder_name eq $bulletin ) {

			print 'Deleting image ' .
				$image -> { name } . ' in folder ' . $folder_name . "\n" ;

			$response = $mailchimp -> delete_file_manager_file (
				file_id => $image -> { id }
			) ;

		}

	}

}

#-------------------------------------------------------------------------------
# 2. Folders

$response = $mailchimp -> file_manager_folders (
	since_created_at => "$yday"
) ;

if ( $response -> { error } && $response -> { error } ) {

	print STDERR Dumper $response -> { content } ;

} else {

	foreach my $folder ( @{ $response -> { content } -> { folders } } ) {

		if ( $folder -> { name } eq $bulletin ) {

			# There has been a folder created within the last couple of days that has
			# the name of the bulletin that we're trying to create. We're going to
			# recreate this folder so delete the one that is currently there.

			print 'Deleting folder ' . $folder -> { name } . "\n" ;
			$response = $mailchimp -> delete_file_manager_folder (
				folder_id => $folder -> { id }
			) ;
			print STDERR Dumper $response -> { content } if $response -> { error } ;

		}

	}

}

#-------------------------------------------------------------------------------
# 3. Campaigns

$response = $mailchimp -> campaigns (
	status => 'save'
) ;

foreach my $campaign ( @{ $response -> { content } -> { campaigns } } ) {

	my $subject_line = $campaign -> { settings } -> { subject_line } ;

	if ( $subject_line eq $bulletin ) {

		print "Deleting campaign $subject_line\n" ;
		$response = $mailchimp -> delete_campaign (
			campaign_id => $campaign -> { id } ,
		) ;

	}

}

#-------------------------------------------------------------------------------
# 4. Templates

$response = $mailchimp -> templates (
	created_by => 'David Williamson' ,
#	since_date_created => $yday ,
	type => 'user' ,
) ;

print STDERR Dumper $response -> { content } if $response -> { error } ;

foreach my $template ( @{ $response -> { content } -> { templates } } ) {

	my $name = $template -> { name } ;

	if ( $name =~ /^$bulletin\s\(.+\)$/ ) {

		print "Deleting template $name\n" ;
		$response = $mailchimp -> delete_template (
			template_id	=> $template -> { id }
		) ;

	}

}

print "***** CLEARDOWN FINISHED *****\n" ;
print "***** STARTING BUILD *****\n" ;

#-------------------------------------------------------------------------------

#
# Create a folder in the content manager to put the images in to
#

print 'Creating folder ' . $bulletin . "\n" ;

$response = $mailchimp -> add_file_manager_folder (
	name => $bulletin
) ;

my $folder_id = $response -> { content } -> { id } ;

#-------------------------------------------------------------------------------

#
# Get content:
# 1. Connect to the database and fetch the news items and events;
# 2. Read guidance from HTML file.
#

my $dbh = DBI -> connect (
	'dbi:SQLite:dbname=' . $env -> { database } , "" , ""
) ;

my @news_items = DATA::WhatsOn::NewsItem -> fetch (
	$dbh , { limit => $params { news } }
) if $params { news } ;

foreach my $news_item ( @news_items ) {

	if ( $news_item -> image ) {

		my $image = grab ( URL => $env -> { root } . $news_item -> image ) ;

		$news_item -> image =~ /^\/assets\/img\/news_items\/(\S+)$/ ;

		# Note the + 0 on the folder id otherwise API complains it's not an integer!
		# Also, image must be base64 encoded.
		print "Uploading image $1\n" ;
		$response = $mailchimp -> add_file_manager_file (
			folder_id	=> $folder_id								,
			name			=> $1												,
			file_data	=> encode_base64 ( $image	)	,
		) ;

		if ( $response -> { error } ) {
			print STDERR Dumper $response -> { content } if $response -> { error } ;
		} else {

			$news_item -> temp (
				'full_size_url'	=> $response -> { content } -> { full_size_url }
			) ;

		}

	}

}

# Determine the "from" value for the events filter before fetching events

my $from = 'now' ; # If no "days" (offset) is specified then default to now

if ( $params { days } ) {

	# We have been asked to offset the date so use $today instead of now
	$from =								$date_to_use -> year		. '-' .
		sprintf ( "%02d" ,	$date_to_use -> month )	. '-' .
		sprintf ( "%02d"	,	$date_to_use -> day		) ;

}

my @events = DATA::WhatsOn::Event -> fetch (
	$dbh , { from => $from , status => 'PUBLISHED' , limit => $params { events } }
) ;

foreach my $event ( @events ) {

	# Populate the default fields

	$event -> dates ( $event -> dates_derived )
		unless $event -> dates ;

	$event -> times ( '7.30pm' )
		unless $event -> times ;

	$event -> presented_by ( $event -> society_name )
		unless $event -> presented_by ;

	# If the event has an image associated with it then we must upload this to the
	# Mailchimp content library for use in our mailshot.

	if ( $event -> image ) {

		# Has the image already been uploaded? If not then we don't need to do it
		# again of course.



		# The event has an image associated with it. So, before we mail out we must
		# upload the image to the Mailchimp Content Manager so that it can be used
		# in the email bulletin.

		# First get the image as a raw binary variable

		my $url = '' ;

		if ( $event -> image =~ /^$upload_path/ ) {

			# An uploaded image has been used
			$url = $env -> { root } . $event -> image ;

		} else {

			# A link to an image on a remote website has been used
			$url = $event -> image ;

		}

		my $image = grab ( URL => $url ) ;

		$event -> image =~ /^\/upload\/img\/(\S+)$/ ;

		# Note the + 0 on the folder id otherwise API complains it's not an integer!
		# Also, image must be base64 encoded.
		print "Uploading image $1\n" ;
		$response = $mailchimp -> add_file_manager_file (
			folder_id	=> $folder_id								,
			name			=> $1												,
			file_data	=> encode_base64 ( $image	)	,
		) ;

		if ( $response -> { error } ) {
			print STDERR Dumper $response -> { content } if $response -> { error } ;
		} else {

			$event -> temp (
				'full_size_url'	=> $response -> { content } -> { full_size_url }
			) ;

		}

	}

}

my $guidance = read_file ( $params { guidance } ) if $params { guidance } ;

#-------------------------------------------------------------------------------

#
# Create the monthly mailshot templates, populated with the relevant data
#

TEMPLATE:
foreach my $segment (
	'events only' , 'events + news' , 'events + guidance' , 'all sections'
) {

	# Produce up to (depending on params) four templates as follows:
	# events only				- Only coming events
	# events + news			- Coming events plus latest member news
	# events + guidance	- Coming events plus guidance to member society reps
	# all sections			-	Coming events plus news plus guidance (the works)

	next TEMPLATE if (
		( $segment eq 'events + news' && ! $params { news } )
		||
		( $segment eq 'events + guidance' && ! $params { guidance } )
		||
		( $segment eq 'all sections'
				&& ! ( $params { news } && $params { guidance } )
		)
	) ;

	print "Producing template for segment=\"$segment\"\n" ;

	my $template = new Template ( {

		ENCODING => 'utf8' ,

		INCLUDE_PATH => [
			"$home/src/mailchimp" ,
			"$home/src/mailchimp/fragments" ,
			"$home/src/mailchimp/sections" ,
		]

	} ) || die Template -> error ( ) , "\n" ;

	my $raw = '' ;

	my $vars = {
		conf => $env ,
		events => \@events
	} ;

	$vars -> { news_items } = \@news_items
		if $segment eq 'events + news' || $segment eq 'all sections' ;
	$vars -> { guidance } = $guidance
		if $segment eq 'events + guidance' || $segment eq 'all sections' ;

	$template -> process (
		'monthly_mailshot.tt' ,
		$vars ,
		\$raw
	) || die $template -> error ( ) , "\n" ;

	my $inliner = new CSS::Inliner ( {
		leave_style => 1
	} );

	$inliner -> read ( { html => $raw } ) ;

	my $inlined = $inliner -> inlinify ;

	my $packer = HTML::Packer -> init ;

	my $packed = $packer -> minify ( \$inlined , { do_stylesheet => 'pretty' } ) ;

	# Strip CSS prior to the first @media query
	$packed =~ s/
		<style\stype="text\/css">									# Style tag
		.*?																				# Content before the first @media
		\@media																		# First @media
		(.*)																			# The remainder
		/<style type="text\/css">\n\@media$1/sx ;

	print "Uploading template to Mailchimp for segment=$segment\n" ;

	my $response = $mailchimp -> add_template (

		name => $bulletin . ' (' . $segment . ')' ,
		html => $packed

	) ;

	print STDERR Dumper $response -> { content } if $response -> { error } ;

	my $template_id = $response -> { content } -> { id } ;

	my $recipients = {
		list_id => $env -> { mailchimp_list_id }
	} ;

	my $preview = << "EndofPreview" ;
Derby Arts and Theatre Association's montly bulletin for $month showcasing the
coming events presented by DATA's member societies.
EndofPreview

#-------------------------------------------------------------------------------

#
# Determine the segmentation options required (if any) for this campaign
#

	my $settings = {
		subject_line => $bulletin ,
		preview_text => $preview ,
		title => "$bulletin ($segment)" ,
		from_name => 'Derby Arts and Theatre Association' ,
		reply_to => 'admin@derbyartsandtheatre.org.uk' ,
		inline_css => \0 ,
		template_id => $template_id
	} ;

	my $segment_opts = { match => 'all' } ;

	if ( $segment eq 'all sections' ) {

		# Recipient MUST have registered their interest in news AND guidance
		$segment_opts -> { conditions } = [
			{
				condition_type => 'Interests' ,
				op => 'interestcontainsall' ,
				field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
				value => [
					$env -> { mailchimp_representative_interest_id } ,
					$env -> { mailchimp_member_interest_id } ,
				] ,
			} ,
		] ;

	} elsif ( $segment eq 'events only' ) {

		# If there are either news or guidance or both present then the recipient
		# must NOT have expressed an interest in them

		#Uncomment to debug how the segments are decided upon
		#print "At the point of creating segment_opts for segment $segment\n" ;
		#print "And the value of $vars that we base this on is\n" ;
		#print Dumper $vars ;

		if ( $params { news } && $params { guidance } ) {

			# Receipient must NOT have an interest in either news or guidance
			$segment_opts -> { conditions } = [
				{
					condition_type => 'Interests' ,
					op => 'interestnotcontains' ,
					field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
					value => [
						$env -> { mailchimp_representative_interest_id } ,
						$env -> { mailchimp_member_interest_id } ,
					] ,
				} ,
			] ;

		} elsif ( $params { news } ) {

			# Receipient must NOT have an interest in news
			$segment_opts -> { conditions } = [
				{
					condition_type => 'Interests' ,
					op => 'interestnotcontains' ,
					field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
					value => [
						$env -> { mailchimp_member_interest_id } ,
					] ,
				} ,
			] ;

		} elsif ( $params { guidance } ) {

			# Receipient must NOT have an interest in guidance
			$segment_opts -> { conditions } = [
				{
					condition_type => 'Interests' ,
					op => 'interestnotcontains' ,
					field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
					value => [
						$env -> { mailchimp_representative_interest_id } ,
					] ,
				} ,
			] ;

		}

	} elsif ( $segment eq 'events + news' ) {

		# If guidance is also present then the recipient must have expressed an
		# interest in news but NOT guidance. They will receive the "all sections"
		# bulletin if they've also expressed an interest in guidance. If there is
		# no guidance this month then it's enough that they've expressed an interest
		# in news.

		if ( $params { guidance } ) {

			# Receipient must have an interest in news but NOT in guidance
			$segment_opts -> { conditions } = [
				{
					condition_type => 'Interests' ,
					op => 'interestcontains' ,
					field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
					value => [
						$env -> { mailchimp_member_interest_id } ,
					] ,
				} ,
				{
					condition_type => 'Interests' ,
					op => 'interestnotcontains' ,
					field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
					value => [
						$env -> { mailchimp_representative_interest_id } ,
					] ,
				} ,
			] ;

		} else {

			# There is no guidance this month, it suffices that the recipient has
			# expressed an interest in news
			$segment_opts -> { conditions } = [
				{
					condition_type => 'Interests' ,
					op => 'interestcontains' ,
					field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
					value => [
						$env -> { mailchimp_member_interest_id } ,
					] ,
				} ,
			] ;

		}

	} elsif ( $segment eq 'events + guidance' ) {

		# If news is also present then the recipient must have expressed an
		# interest in guidance but NOT new. They will receive the "all sections"
		# bulletin if they've also expressed an interest in news. If there is
		# no news this month then it's enough that they've expressed an interest
		# in guidance.

		if ( $params { news } ) {

			# Receipient must have an interest in news but NOT in guidance
			$segment_opts -> { conditions } = [
				{
					condition_type => 'Interests' ,
					op => 'interestcontains' ,
					field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
					value => [
						$env -> { mailchimp_representative_interest_id } ,
					] ,
				} ,
				{
					condition_type => 'Interests' ,
					op => 'interestnotcontains' ,
					field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
					value => [
						$env -> { mailchimp_member_interest_id } ,
					] ,
				} ,
			] ;

		} else {

			# There is no news this month, it suffices that the recipient has
			# expressed an interest in guidance
			$segment_opts -> { conditions } = [
				{
					condition_type => 'Interests' ,
					op => 'interestcontains' ,
					field => 'interests-' . $env -> { mailchimp_interest_category_id } ,
					value => [
						$env -> { mailchimp_representative_interest_id } ,
					] ,
				} ,
			] ;

		}

	}

	$recipients -> { segment_opts } = $segment_opts ;

	print "Uploading campaign to Mailchimp for segment=$segment\n" ;

	#Uncomment to debug the recipients hash
	#print "Recipients hash:\n" ;
	#print Dumper $recipients ;

	$response = $mailchimp -> add_campaign (

		type => 'regular' ,

		recipients => $recipients ,

		settings => $settings ,

	) ;

	print Dumper $response -> { content } if $response -> { error } ;

}

1 ;

__END__
