use strict ;
use warnings ;

use Config::General ;
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
use Template ;

use DATA::WhatsOn::Event ;
use DATA::WhatsOn::NewsItem ;

#-------------------------------------------------------------------------------
# 1. Process the command line arguments.
#-------------------------------------------------------------------------------

my $help = << 'EndofHelp'
Options:

-h
Print this message and exit. Any other options provided are ignored.

-a filepath
The filepath to a file containing HTML that is an announcment for subscribers
who have NOT registered an interest in "Latest DATA Membership News".

-d n
The number of days (integer n) from today that event listings should start from.
If this is omitted then they will start from the current system date.

-e n
The number of events (integer n) to list. If this is omitted then no events will
be included in the bulletin.

-g filepath
The filepath to a file containing HTML that is an announcement for subscribers
who have registered an interest in "Guidance to Member Society Representatives".

-m filepath
The filepath to a file containing HTML that is an announcement for subscribers
who have registered an interest in "Latest DATA Membership News".

-n n
The number of news items (integer n) to list. If this is omitted then that no
news items will be included in the bulletin and if -m is also ommitted then
there will be no news section in the bulletin.

-o filepath
If this is set then this script will output the generated HTML that it uses for
the Mailchimp template to a file. This file can then be downloaded and syntax
checked.

-p n
Pin events to the top of the bulletin If this is omitted or set to a negative
value, e.g. 0, then any news insert and/or news items will appear above events.
However, if this flag is provided and set to a positive value, e.g. 1, then
events will be pinned at the top of the bulletin.

-s string
This option sets a custom subject line for the bulletin email. If the bulletin
the regular monthly bulletin to advertise upcoming events then this can be
omitted and the subject line will be derived automatically.

EndofHelp
;

my %params ;

my $option  ; # Used to capture valid options
my $getdir  ; # Used to indicate that a filepath value for a new file but within
              # an existing directory is expected for an option
my $getint  ; # Used to indicate that an integer value is expected for an option
my $getpath ; # Used to indicate that a filepath value for an existing file is
              # expected for an option
my $getstr  ; # Used to indicate that a string value is expected for an option

ARG:
foreach my $arg ( @ARGV ) {

  if ( $option && ( $getdir || $getint || $getpath || $getstr ) ) {

    # Check for valid values for an option flag on the previous loop

    if ( $getdir ) {

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

    } elsif ( $getint ) {

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

    }

    $params { $option } = $arg ;
    $option = undef; $getint = undef; $getpath = undef; $getdir = undef;
    next ARG ;

  }

  if ( $arg eq '-h' ) {

    print $help ;
    exit ;

  } elsif ( $arg eq '-a') {

    # Valid announcement (subscribers who have NOT registered an interest in
    # "Latest DATA Membership News") option, which must have a filepath value.

    $option = 'non_member_insert'; $getpath = 1;

  } elsif ( $arg eq '-d' ) {

    # Valid days option, which must have an integer value.
    $option = 'days' ; $getint = 1 ;

  } elsif ( $arg eq '-e') {

    # Valid events option, which must have an integer value.
    $option = 'events'; $getint = 1 ;

  } elsif ( $arg eq '-g' ) {

    # Valid announcement (subscribers who have registered an interest in
    # "Guidance to Member Society Representatives"), which must have a filepath
    # value.
    $option = 'guidance'; $getpath = 1;

  } elsif ( $arg eq '-m' ) {

    # Valid announcement (subscribers who NOT registered an interest in "Latest
    # DATA Membership News") option, which must have a filepath value.
    $option = 'member_insert'; $getpath = 1;

  } elsif ( $arg eq '-n' ) {

    # Valid news items option, which must have an integer value
    $option = 'news'; $getint = 1 ;

  } elsif ( $arg eq '-o' ) {

    # Valid output option, which must have a filepath value
    $option = 'output'; $getdir = 1;

  } elsif ( $arg eq '-p' ) {

    # Valid pin_events option, which must have an integer value
    $option = 'pin_events'; $getint = 1 ;

  } elsif ( $arg eq '-s' ) {

    # Valid output option, which must have a string value
    $option = 'subject'; $getstr = 1;

  } else {

    print STDERR "Invalid option $arg specified\n" ;
    print STDERR $help ;
    exit ;

  }

}

#-------------------------------------------------------------------------------
# 2. Load the configuration.
#-------------------------------------------------------------------------------

my $conf = new Config::General (
  -ConfigFile => "$ENV{'DATA_APP_CONF_DIR'}/$ENV{'DATA_APP_CONF_FILE'}",
  -IncludeRelative => 'yes',
  -UseApacheInclude => 'yes'
) ;
my %conf = $conf->getall;
my $upload_path = $conf{image_upload_path};

#-------------------------------------------------------------------------------
# 3. Derive today as a datetime and offset it if we've been told to.
#-------------------------------------------------------------------------------

my $today = DateTime -> today ;
my $date_to_use = $today -> clone ;

if ( $params { days} ) {

  my $offset = new DateTime::Duration ( { days  => $params { days } }  ) ;
  $date_to_use -> add ( $offset ) ;

}

print  'Building bulletin as of '                    .
  sprintf ( '%02d' , $date_to_use -> day    ) . '/' .
  sprintf ( '%02d' , $date_to_use -> month  ) . '/' .
  $date_to_use -> year . "\n" ;

my $month = $date_to_use -> month_name . ' '  . $date_to_use -> year ;

my $bulletin;
if ( $params { subject } ) {
  $bulletin = $params { subject } ;
} else {
  $bulletin = 'DATA Bulletin - ' . $month ;
}

print "Building a bulletin called \"$bulletin\"\n" ;

#-------------------------------------------------------------------------------
# 4. Create the mailchimp API object ready to use.
#-------------------------------------------------------------------------------

my $mailchimp = new Mail::Chimp3 (

  api_key => $conf{mailchimp}{api_key}

) ;

my $response ; # We will use to capture Mailchimp API responses throughout

#-------------------------------------------------------------------------------
# 5. Clear down any content that we are obviously replacing. We do this by
# deleting objects in the following sequence:
#   i.   Images;
#   ii.  Folders (in the content management system) that contain the images;
#   iii. Campaigns;
#   iv.  Templates.
#-------------------------------------------------------------------------------

print "***** STARTING CLEARDOWN *****\n" ;

# Look for objects added recently, in the last day
my $one_day = new DateTime::Duration ( { days  => 1 }  ) ;
my $yday = $today -> clone ;
$yday -> subtract ( $one_day ) ;

#----------
# i. Images
#----------

$response = $mailchimp -> file_manager_files (
  count             => 30     , # Up to 30, which should be sufficient
  since_created_at => "$yday" , # Created since yesterday
  type             => 'image' , # It is an image file
) ;

foreach my $image ( @{ $response -> { content } -> { files } } ) {

  # Double check that this is truly an image that we want to delete. If it is
  # then it will be in a folder whose name is the same as the bulletin's name
  # since we put all images associated with a bulletin in a folder that is
  # specific to that bulletin.

  if ( $image -> { folder_id } ) {

    # This image is in a folder. Find out if it is the bulletin's folder.

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

#------------
# ii. Folders
#------------

$response = $mailchimp -> file_manager_folders (
  since_created_at => "$yday"
) ;

if ( $response -> { error } && $response -> { error } ) {

  print STDERR Dumper $response -> { content } ;
  exit ;

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

#---------------
# iii. Campaigns
# --------------

$response = $mailchimp -> campaigns (
  status => 'save'
) ;

foreach my $campaign ( @{ $response -> { content } -> { campaigns } } ) {

  my $subject_line = $campaign -> { settings } -> { subject_line } ;

  if ( $subject_line && $subject_line eq $bulletin ) {

    print "Deleting campaign $subject_line\n" ;
    $response = $mailchimp -> delete_campaign (
      campaign_id => $campaign -> { id } ,
    ) ;

  }

}

#--------------
# iv. Templates
#--------------

$response = $mailchimp -> templates (
  created_by => 'David Williamson' ,
  type => 'user' ,
) ;

print STDERR Dumper $response -> { content } if $response -> { error } ;

foreach my $template ( @{ $response -> { content } -> { templates } } ) {

  my $name = $template -> { name } ;

  if ( $name =~ /^$bulletin\s\(.+\)$/ ) {

    print "Deleting template $name\n" ;
    $response = $mailchimp -> delete_template (
      template_id  => $template -> { id }
    ) ;

  }

}

print "***** CLEARDOWN FINISHED *****\n" ;
print "***** STARTING BUILD *****\n" ;

#-------------------------------------------------------------------------------
# 6. Create a folder in the content manager to put the images in to.
#-------------------------------------------------------------------------------

print "Creating folder $bulletin\n" ;

$response = $mailchimp -> add_file_manager_folder (
  name => $bulletin
) ;

my $folder_id = $response -> { content } -> { id } ;

#-------------------------------------------------------------------------------
# 7. Get content:
#   i.   Fetch news items from the database;
#   ii.  Fetch events from the database;
#   iii. Read member notice and/or representative guidance from HTML files.
#-------------------------------------------------------------------------------

my $dbh = DBI -> connect (
  'dbi:SQLite:dbname=' . $conf{database}, "", ""
) ;

#---------------------------------------
# i. Fetch news items from the database.
#---------------------------------------

my @news_items = ( ) ;

if ( $params { news } ) {

  print "Fetching news items\n";

  @news_items = DATA::WhatsOn::NewsItem -> fetch (
    $dbh , { limit => $params { news } }
  ) ;

  foreach my $news_item ( @news_items ) {

    if ( $news_item -> image ) {

      my $image = grab(URL => $conf{root} . $news_item->image);

      $news_item -> image =~ /^\/assets\/img\/news_items\/(\S+)$/ ;

      # Note the + 0 on the folder id otherwise API complains it's not an
      # integer! Also, image must be base64 encoded.
      print "Uploading image $1\n" ;
      $response = $mailchimp -> add_file_manager_file (
        folder_id  => $folder_id                ,
        name      => $1                        ,
        file_data  => encode_base64 ( $image  )  ,
      ) ;

      if ( $response -> { error } ) {
        print STDERR Dumper $response -> { content } if $response -> { error } ;
      } else {

        $news_item -> temp (
          'full_size_url'  => $response -> { content } -> { full_size_url }
        ) ;

      }

    }

  }

} else {

  print "No news items to fetch\n";

}

# -----------------------------------
# ii. Fetch events from the database.
# -----------------------------------

my @events = ( ) ;

if ( $params { events } ) {

  # We have been asked to fetch some events from the database for inclusion in
  # the bulletin.

  print "Fetching events\n";

  # Determine the "from" value for the events filter before fetching events

  my $from = 'now' ; # If no "days" (offset) is specified then default to now

  if ( $params { days } ) {

    # We have been asked to offset the date so use $today instead of now
    $from =                $date_to_use -> year    . '-' .
      sprintf ( "%02d" ,  $date_to_use -> month )  . '-' .
      sprintf ( "%02d"  ,  $date_to_use -> day    ) ;

  }

  @events = DATA::WhatsOn::Event -> fetch (
    $dbh ,
    { from => $from , status => 'PUBLISHED' , limit => $params { events } }
  ) ;

  foreach my $event ( @events ) {

    # Populate the default fields

    $event -> dates ( $event -> dates_derived )
      unless $event -> dates ;

    $event -> times ( '7.30pm' )
      unless $event -> times ;

    $event -> presented_by ( $event -> society_name )
      unless $event -> presented_by ;

    # If the event has an image associated with it then we must upload this to
    # the Mailchimp content library for use in our mailshot.

    if ( $event -> image ) {

      # Has the image already been uploaded? If not then we don't need to do it
      # again of course.



      # The event has an image associated with it. So, before we mail out we
      # must upload the image to the Mailchimp Content Manager so that it can be
      # used in the email bulletin.

      # First get the image as a raw binary variable

      my $url = '' ;

      if ( $event -> image =~ /^$upload_path/ ) {

        # An uploaded image has been used
        # $url = $conf -> { root } . $event -> image ;
        $url = 'https://www.derbyartsandtheatre.org.uk' . $event -> image ;

      } else {

        # A link to an image on a remote website has been used
        $url = $event -> image ;

      }

      my $image = grab ( URL => $url ) ;

      $event -> image =~ /^\/upload\/img\/(\S+)$/ ;

      # Note the + 0 on the folder id otherwise API complains it's not an
      # integer! Also, image must be base64 encoded.
      print "Uploading image $1\n" ;
      $response = $mailchimp -> add_file_manager_file (
        folder_id  => $folder_id                ,
        name      => $1                        ,
        file_data  => encode_base64 ( $image  )  ,
      ) ;

      if ( $response -> { error } ) {

        print STDERR Dumper $response -> { content } ;
        exit ;

      } else {

        $event -> temp (
          'full_size_url'  => $response -> { content } -> { full_size_url }
        ) ;

      }

    }

  }

} else {

  print "Skipping fetching evens\n";

}

#------------------------------------------------------------------------
# iii. Read member insert and/or representative guidance from HTML files.
#------------------------------------------------------------------------

my $notice = read_file ( $params { member_insert } )
  if $params { member_insert } ;
my $guidance = read_file ( $params { guidance } )
  if $params { guidance } ;

#-------------------------------------------------------------------------------
# 8. Create the template and campaign for each required audience segment
#-------------------------------------------------------------------------------

TEMPLATE:
foreach my $segment (

  # The audience for the campaign is segmented if the content dictates that it
  # be so. Each segment contains a different subset of our subscribers, which is
  # determined by the subscribers' selected interest categories as follows:

  'none' ,
  # Subscribers who have selected no interest categories.

  'news' ,
  # Subscribers who have selected the "Latest DATA Membership News" interest
  # category.

  'guidance' ,
  # Subscribers who have selected the "Guidance to DATA Member Society
  # Representatives" interest category.

  'both',
  # Subscribers who have selected both the "Latest DATA Membership News" and
  # "Guidance to DATA Member Society Representatives" interest categories.

  'all'
  # All subscribers, regardless of what interest categories they have or haven't
  # selected. Technically this isn't actually a segment and is used when the
  # bulletin's content is such that we don't need to segment the audience.

) {

# -----------
# i. Template
# -----------

  # There are the following categories of content:
  #
  # Events:
  # The only category of content that should be sent to all subscribers.
  #
  # Non Member Inserts:
  # Only for subscribers who have NOT opted to receive "Latest DATA Membership
  # News".
  #
  # Member Inserts:
  # Only for subscribers who have opted to receive "Latest DATA Membership
  # News".
  #
  # News Items
  # Also only for subscribers who have opted to receive "Latest DATA Membership
  # News".
  #
  # Guidance:
  # Only for subscribers who have opted to receive "Guidance to DATA Member
  # Society Representatives".
  #
  # Depending on the content in this specific bulletin a template or templates
  # is created and other templates that are not required are skipped of course.

  if ( $segment eq 'none' ) {

    next TEMPLATE unless

      # The bulletin contains:
      #
      # Content that is available to subscribers who have NOT opted to receive
      # "Latest DATA Membership News" or "Guidance to DATA Member Society
      # Representatives".
      #
      # and
      #
      # Content that is NOT available to subscribers who have NOT opted to
      # receive "Latest DATA Membership News" or "Guidance to DATA Member
      # Society Representatives".

      (
        $params{ events }
        || $params{ non_member_insert }
      )
      &&
      (
        $params{ member_insert }
        || $params{ news }
        || $params{ guidance }
      )

  } elsif ( $segment eq 'news' ) {

    next TEMPLATE unless

    # The bulletin contains:
    #
    # Content that is only for subscribers who have opted to receive "Latest
    # DATA Membership News" or is specifically NOT for those subscribers.

    $params{ non_member_insert }
    || $params{ member_insert }
    || $params{ news}

  } elsif ( $segment eq 'guidance' ) {

    next TEMPLATE unless

    # The bulletin contains:
    #
    # Content that is only for subscribers who have opted to receive "Guidance
    # to DATA Member Society Representatives".

    $params { guidance } ;

  } elsif ( $segment eq 'both' ) {

    next TEMPLATE unless

    # The bulletin contains both:
    #
    # Content that is only for subscribers who have opted to receive "Latest
    # DATA Membership News" or is specifically NOT for those subscribers.
    #
    # and
    #
    # Content that is only for subscribers who have opted to receive "Guidance
    # to DATA Member Society Representatives".

    (
      $params{ non_member_insert }
      || $params{ member_insert }
      || $params{ news}
    )
    && $params{ guidance }

  } elsif ( $segment eq 'all' ) {

    next TEMPLATE unless

    # The bulletin includes events only and no content that is only applicable
    # to segments within our subscriber audience.

    $params{ events }
    && ! $params{ non_member_insert }
    && ! $params{ member_insert }
    && ! $params{ news }
    && ! $params{ guidance }

  }

  print "Producing template for audience segment \"$segment\"\n" ;

  my $template = new Template ( {

    ABSOLUTE => 1,

    ENCODING => 'utf8' ,

    INCLUDE_PATH => [
      $conf{tmpl_dir} . '/mailchimp',
      $conf{tmpl_dir} . '/mailchimp/fragments',
      $conf{tmpl_dir} . '/mailchimp/sections',
    ]

  } ) || die Template -> error ( ) , "\n" ;

  my $raw = '' ;

  my $vars = {
    conf => \%conf,
    events => \@events
  } ;

  if ( $segment eq 'none' ) {
    $vars->{news_insert} = $params{non_member_insert}
      if $params{non_member_insert};
  }
  elsif ( $segment eq 'news' || $segment eq 'both' ) {
    $vars->{news_items} = \@news_items if @news_items;
    $vars->{news_insert} = $params{member_insert} if $params{member_insert};
  }
  elsif ( $segment eq 'guidance' || $segment eq 'both' ) {
    $vars->{guidance} = $guidance;
  }

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
    <style\stype="text\/css">                  # Style tag
    .*?                                        # Content before the first @media
    \@media                                    # First @media
    (.*)                                      # The remainder
    /<style type="text\/css">\n\@media$1/sx ;

  print "Uploading template to Mailchimp for segment=$segment\n" ;

  $response = $mailchimp -> add_template (

    name => $bulletin . ' (' . $segment . ')' ,
    html => $packed

  ) ;

  my $template_id;
  if ( $response -> { error } ) {
    print STDERR Dumper $response -> { content } ;
    exit ;
  } else {
    $template_id = $response -> { content } -> { id } ;
  }

#-------------
# ii. Campaign
#-------------

  my $recipients = {
    list_id => $conf{mailchimp}{list_id}
  } ;

  my $settings = {
    subject_line => "$bulletin" ,
    title => "$bulletin ($segment)" ,
    from_name => 'Derby Arts and Theatre Association' ,
    reply_to => 'admin@derbyartsandtheatre.org.uk' ,
    inline_css => \0 ,
    template_id => $template_id
  } ;

  unless ( $params{ subject } ) {

    # If no custom subject line was been provided then this is the regular
    # monthly bulletin, so use the standard preview that we use for those.

    my $preview = << "EndofPreview" ;
Derby Arts and Theatre Association's monthly bulletin for $month showcasing the
coming events presented by DATA's member societies.
EndofPreview

    $settings -> { preview_text } = $preview ;

  }

  # Set the segmentation options required (if any) for this campaign. If the
  # segment that we've derived is "all" then actually this indicates that we do
  # NOT need to segment the audience, so we only need to segment for other
  # segment values.

  unless ( $segment eq 'all' ) {

    my $segment_opts = { match => 'all' } ;

    if ( $segment eq 'none' ) {

      # Recipients MUST NOT have registered an interest in neither news NOR
      # guidance.

      $segment_opts -> { conditions } = [
        {
          condition_type => 'Interests' ,
          op => 'interestnotcontains' ,
          field => 'interests-' . $conf{mailchimp}{interest_category_id},
          value => [
            $conf{mailchimp}{representative_interest_id},
            $conf{mailchimp}{member_interest_id},
          ] ,
        } ,
      ] ;

    } elsif ( $segment eq 'news' ) {

      # Recipients MUST have registered an interest in news.

      $segment_opts -> { conditions } = [
        {
          condition_type => 'Interests' ,
          op => 'interestcontains' ,
          field =>
            'interests-' . $conf{mailchimp}{interest_category_id},
          value => [
            $conf{mailchimp}{member_interest_id},
          ] ,
        } ,
      ] ;

      # If there is also a "guidance" segment in the bulletin then we must
      # exclude subscribers who are also in that segment, as they will get
      # picked up under the "both" segment.

      if ( $params{guidance} ) {

        push @{ $segment_opts->{conditions} },
        {
          condition_type => 'Interests',
          op => 'interestnotcontains',
          field => 'interests-' . $conf{mailchimp}{interest_category_id},
          value => [$conf{mailchimp}{representative_interest_id}],
        };

      }

    } elsif ( $segment eq 'guidance' ) {

      # Recipients MUST have registered an interest in guidance.

      $segment_opts -> { conditions } = [
        {
          condition_type => 'Interests' ,
          op => 'interestcontains' ,
          field =>
            'interests-' . $conf{mailchimp}{interest_category_id},
          value => [
            $conf{mailchimp}{representative_interest_id},
          ] ,
        } ,
      ] ;

      # If there is also a "news" segment in the bulletin then we must exclude
      # subscribers who are also in that segment, as they will get picked up
      # under the "guidance" segment.

      if (
        $params{ non_member_insert }
        || $params{ member_insert }
        || $params{ news}
      ) {

        push @{ $segment_opts->{conditions} },
        {
          condition_type => 'Interests' ,
          op => 'interestnotcontains' ,
          field =>
            'interests-' . $conf->{mailchimp}->{interest_category_id},
          value => [
            $conf->{mailchimp}->{member_interest_id},
          ] ,
        };

      }

    } elsif ( $segment eq 'both' ) {

      # Recipients MUST have registered an interest in both news AND guidance.

      $segment_opts -> { conditions } = [
        {
          condition_type => 'Interests' ,
          op => 'interestcontainsall' ,
          field =>
            'interests-' . $conf{mailchimp}{interest_category_id},
          value => [
            $conf{mailchimp}{representative_interest_id},
            $conf{mailchimp}{member_interest_id},
          ] ,
        } ,
      ] ;

    }

    $recipients -> { segment_opts } = $segment_opts ;

  }

  print "Uploading campaign to Mailchimp for segment=$segment\n" ;

  $response = $mailchimp -> add_campaign (

    type => 'regular' ,

    recipients => $recipients ,

    settings => $settings ,

  ) ;

  if ( $response -> { error } ) {

    print Dumper $response -> { content } ;
    exit ;

  }

}

1 ;

__END__
