package DATA::WhatsOn ;

=head1 DATA::WhatsOn

Extends the DATA::Main class to provide public actions,event management and
organisation management run modes, all of which are action run modes.

=cut

use strict ;
use warnings ;

use base qw / DATA::Main / ;

use Encode qw / encode / ;
use HTML::HTMLDoc ;
use PDF::API2 ;

use DATA::Auth::Constraints ;
use DATA::WhatsOn::Constraints ;
use DATA::WhatsOn::Contact ;
use DATA::WhatsOn::Event ;
use DATA::WhatsOn::Organisation ;

use Data::FormValidator::Constraints qw / email  / ;
use Data::FormValidator::Constraints::DateTime qw / :all / ;
use Data::FormValidator::Constraints::MethodsFactory qw / :bool :set / ;

use String::Random ;

my $_messages = {

  constraints => {

    # A hash reference containing messages associated with constraints

    contact_is_subscribed          => 'contact_is_subscribed'          ,
    contact_not_subscribed         => 'contact_not_subscribed'         ,
    email_confirmed                => 'email_confirmed'                ,
    email_valid                    => 'email_valid'                    ,
    end_date_not_before_start_date => 'end_date_not_before_start_date' ,
    end_date_valid                 => 'end_date_valid'                 ,
    event_description_valid        => 'event_description_valid'        ,
    event_image_provided           => 'event_image_provided'           ,
    event_image_valid              => 'event_image_valid'              ,
    event_status_valid             => 'event_status_valid'             ,
    event_use_desc_valid           => 'event_use_desc_valid'           ,
    not_a_robot                    => 'not_a_robot'                    ,
    start_date_after_today         => 'start_date_after_today'         ,
    start_date_valid               => 'start_date_valid'               ,
    status_valid                   => 'status_valid'                   ,
    unsubscribe_valid              => 'unsubscribe_valid'              ,
    venue_exists                   => 'venue_exists'                   ,

  } , # End of constraints hash

} ; # End of $_messages hash

sub _secret {

  # Internal method that is called whenever we want a secret string
  my $string = new String::Random ;
  my $secret = $string -> randregex ( '[a-z0-9]{20}' ) ;
  return $secret ;

}

sub setup {

  my $self = shift ;

  $self -> run_modes ( {

    #
    # Public Actions
    #

    # Send an expression of interest for join DATA to the webmin
    'join_us'             =>  'join_us'            ,
    # Register an individual member
    'membership'          => 'membership'          ,
    # Notify the webmin of an event
    'notify_event'        => 'notify_event'         ,
    # Return a PDF cotaining coming events in a one page, printable format
    'printed_listing'     => 'printed_listing'     ,

    #
    # Event Management
    #

    # Add or update an event (programme listing)
    'event_programme'     => 'event_programme'      ,
    # Update an event (oneline promotion)
    'event_online'        => 'event_online'         ,
    # Show an event programme listing for rep update
    'rep_event_programme' => 'rep_event_display'    ,
    # Show an event online listing for rep update
    'rep_event_online'    => 'rep_event_display'    ,

    #
    # Organisation Management
    #

    # Add or update an organisation
    'organisation'        => 'organisation'         ,
    # Show society details for update
    'rep_society'         => 'rep_society_display' ,
    # Show society contacts
    'rep_contacts'        => 'rep_society_display'  ,

  } ) ;

} # End of setup sub

=head2 Public Actions

These are public actions, i.e. they can be invoked without having to be
authenticated or have specific authorisation.

=cut

sub join_us {

=head3 join_us

Make an enquiry for a performing arts society that isn't yet a member of DATA to
join. The enquiry gets emailed to the webmin.

=cut

  my $self = shift ;
  my $query = $self -> query ;
  my $env = $self -> conf -> param ( 'env' ) ;

  my $join_us_form = {

    required => [ qw /
      contact_email
      contact_confirm_email
      contact_message
    / ] ,

    constraint_methods => {

      contact_email => {
        constraint_method  => email ,
        name              => 'email_valid'
      } ,

      contact_confirm_email => {
        constraint_method => FV_eq_with ( 'contact_email' ) ,
        name => 'email_confirmed'
      } ,

    } , # End of constraint_methods

    msgs => $_messages

  } ; # End of $join_us_form profile

#-------------------------------------------------------------------------------
# Add recaptcha check unless recaptcha is disabled for this environment

  if ( $env -> { use_captcha } ) {

    push @{ $join_us_form -> { required } } , 'g-recaptcha-response' ;

    $join_us_form -> { constraint_methods } -> { 'g-recaptcha-response' } = {
      constraint_method => not_a_robot ( $env -> { recaptcha_secret_key } ) ,
      name              => 'not_a_robot'
    }

  }

#-------------------------------------------------------------------------------
# Validate the inputs

  my $results = $self -> check_rm ( 'form_response' , $join_us_form )
  || return \$self -> check_rm_error_page ;

#-------------------------------------------------------------------------------
# We have passed validation, send the message to webmin and redirect

  my $webmin = $env -> { webmin } ;
  my $contact_email = scalar $query -> param ( 'contact_email' ) ;
  my $contact_message = scalar $query -> param ( 'contact_message' ) ;

  $self -> sendmail (
    $webmin ,
    'DATA Diary - Membership Enquiry' ,
    {
      contact => {
        email => $contact_email ,
        message => $contact_message
      }
    }
  ) ;

  $self -> redirect ( $env -> { root } . $query -> param ( 'onSuccess' ) ) ;

}

sub membership {

=head3 membership

Register an individual member.

=cut

  my $self = shift ;
  my $query = $self -> query ;
  my $env = $self -> conf -> param ( 'env' ) ;

  my $membership_form = {

    required => [ qw /
      contact_first_name
      contact_surname
      contact_email
      contact_confirm_email
    / ] ,

    constraint_methods => {

      contact_email => {
        constraint_method  => email ,
        name              => 'email_valid'
      } ,

      contact_confirm_email => {
        constraint_method => FV_eq_with ( 'contact_email' ) ,
        name => 'email_confirmed'
      } ,

    } , # End of constraint_methods

    msgs => $_messages

  } ; # End of $membership_form profile

#-------------------------------------------------------------------------------
# Add recaptcha check unless recaptcha is disabled for this environment

  if ( $env -> { use_captcha } ) {

    push @{ $membership_form -> { required } } , 'g-recaptcha-response' ;

    $membership_form -> { constraint_methods } -> { 'g-recaptcha-response' } = {
      constraint_method => not_a_robot ( $env -> { recaptcha_secret_key } ) ,
      name              => 'not_a_robot'
    }

  }

#-------------------------------------------------------------------------------
# Validate the inputs

  my $results = $self -> check_rm ( 'form_response' , $membership_form )
  || return \$self -> check_rm_error_page ;

#-------------------------------------------------------------------------------
# We have passed validation, send the message to webmin and redirect

  my $webmin = $env -> { webmin } ;
  my $contact_first_name = scalar $query -> param ( 'contact_first_name' ) ;
  my $contact_surname = scalar $query -> param ( 'contact_surname' ) ;
  my $contact_email = scalar $query -> param ( 'contact_email' ) ;
  my $contact_groups = scalar $query -> param ( 'contact_groups' ) ;

  $self -> sendmail (
    $webmin ,
    'DATA Membership Registration' ,
    {
      contact => {
        first_name => $contact_first_name ,
        surname => $contact_surname ,
        email => $contact_email ,
        groups => $contact_groups
      }
    }
  ) ;

  $self -> redirect ( $env -> { root } . $query -> param ( 'onSuccess' ) ) ;

}

sub notify_event {

=head3 notify_event

Process an event notification via the event notification form. The details are
sent via eamil to the webmin.

=cut

  my $self = shift ;
  my $query = $self -> query ;
  my $env = $self -> conf -> param ( 'env' ) ;

  my $notify_event_form = {

    required => [ qw /
      contact_email
      contact_confirm_email
      event_name
      event_start_date
      event_society
      event_venue
      event_box_office
    / ] , # End of required array

    optional => [ qw /
      event_end_date
      event_times
    / ] , # End of optional array

    constraint_methods => {

      contact_email => {
        constraint_method  => email ,
        name              => 'email_valid'
      } ,

      contact_confirm_email => {
        constraint_method  => FV_eq_with ( 'contact_email' ) ,
        name              => 'email_confirmed'
      } ,

      event_start_date => [
        {
          constraint_method  => to_datetime ( '%d/%m/%Y' ) ,
          name              => 'start_date_valid'
        } ,
        {
          constraint_method  => FV_and (
            to_datetime ( '%d/%m/%Y' ) ,  after_today ( '%d/%m/%Y' )
          ) ,
          name              => 'start_date_after_today'
        } ,
      ] , # End of event_start_date array

      event_end_date => [
        {
          constraint_method  => to_datetime ( '%d/%m/%Y' ) ,
          name              => 'end_date_valid'
        } ,
        {
          constraint_method  => FV_and (
            to_datetime ( '%d/%m/%Y' ) ,
            FV_not ( before_datetime ( '%d/%m/%Y' , 'event_start_date' ) )
          ) ,
          name              => 'end_date_not_before_start_date'
        } ,
      ] , # End of event_end_date array

    } , # End of constraint_methods hash

    msgs => $_messages

  } ; # End of $notify_event_form profile

#-------------------------------------------------------------------------------
# Add recaptcha check unless recaptcha is disabled for this environment

  if ( $env -> { use_captcha } ) {

    push @{ $notify_event_form -> { required } } , 'g-recaptcha-response' ;

    $notify_event_form
    -> { constraint_methods } -> { 'g-recaptcha-response' } = {
      constraint_method  => not_a_robot ( $env -> { recaptcha_secret_key } ) ,
      name              => 'not_a_robot'
    }

  }

#-------------------------------------------------------------------------------
# Validate the inputs

  my $results = $self -> check_rm ( 'form_response' , $notify_event_form )
  || return \$self -> check_rm_error_page ;

#-------------------------------------------------------------------------------
# We have passed validation, send the message to webmin and redirect

  # We don't particularly need to use a Contact or an Event object since we're
  # only copying values over to embed in the email templte. However, it's a
  # convenient way of creating a hash with the correct keys in it. Who knows,
  # we may utilise one of the methods that the object gives us at some point.

  # Contact
  my $contact = new DATA::WhatsOn::Contact ;
  $contact -> email ( scalar $query -> param ( 'contact_email' ) ) ;

  # Event
  my $event = new DATA::WhatsOn::Event ;
  $event -> name ( scalar $query -> param ( 'event_name' ) ) ;
  $event -> start_date ( scalar $query -> param ( 'event_start_date' ) ) ;
  if ( scalar $query -> param ( 'event_end_date' ) ) {
    $event -> end_date ( scalar $query -> param ( 'event_end_date' ) ) ;
  } else {
    $event -> end_date ( scalar $query -> param ( 'event_start_date' ) ) ;
  }
  $event -> dates ( scalar $query -> param ( 'event_dates' ) ) ;
  $event -> times ( scalar $query -> param ( 'event_times' ) ) ;
  $event -> presented_by ( scalar $query -> param ( 'event_presented_by' ) ) ;
  $event -> box_office ( $query -> param ( 'event_box_office' ) ) ;

  # Venue - Try fetch on name to see if it is already known or not.
  $event -> venue_name ( scalar $query -> param ( 'event_venue' ) ) ;
  my $venue = new DATA::WhatsOn::Organisation ;
  $venue -> name ( scalar $event -> venue_name ) ;
  $event -> venue_rowid ( $venue -> rowid )
  if ( $venue -> fetch ( $self -> dbh ) && $venue -> type eq 'whatson_venue' ) ;

  # Society - Get the name using the rowid that's provided by the form
  my $society = new DATA::WhatsOn::Organisation ;
  $society -> rowid ( scalar $query -> param ( 'event_society' ) ) ;
  $society -> fetch ( $self -> dbh ) ;
  $event -> society_name ( $society -> name ) ;

  # Send the message
  my $webmin = $env -> { webmin } ;
  $self -> sendmail (
    $webmin ,
    'DATA Diary - Event Notification' ,
    { contact => $contact , event => $event }
  ) ;

  $self -> redirect ( $env -> { root } . $query -> param ( 'onSuccess' ) ) ;

}

sub printed_listing {

=head3 printed_listing

Produce a one page PDF listing of coming events on either an A4 or A5 page for
printing.

=cut

  my $self = shift ;
  my $query = $self -> query ;
  my $env = $self -> conf -> param ( 'env' ) ;

  my $printed_listing_form = {

    optional => [ qw /
      flyer_start_date
    / ] ,

    constraint_methods => {

      flyer_start_date => [
        {
          constraint_method => to_datetime ( '%d/%m/%Y' ) ,
          name              => 'start_date_valid'
        } ,
        {
          constraint_method => FV_and (
            to_datetime ( '%d/%m/%Y' ) ,  after_today ( '%d/%m/%Y' )
          ) ,
          name              => 'start_date_after_today'
        } ,
      ] ,

    } ,

    msgs => $_messages ,

  } ;

#-------------------------------------------------------------------------------
# Validate the inputs

  my $results = $self -> check_rm ( 'form_response' , $printed_listing_form )
    || return \$self -> check_rm_error_page ;

#-------------------------------------------------------------------------------

# Retrieve Data

  my $filter = {
    from   => 'now'       ,
    status => 'PUBLISHED'
  } ;

  if ( my $flyer_start_date = scalar $query -> param ( 'flyer_start_date' ) ) {

    $filter -> { from } =
      substr ( $flyer_start_date , 6 , 4 ) . '-' .
      substr ( $flyer_start_date , 3 , 2 ) . '-' .
      substr ( $flyer_start_date , 0 , 2 ) ;

  }

  # Turn on the unicode flag for data retrieved from the database
  $self -> dbh -> { sqlite_unicode } = 1 ;

  my @events = DATA::WhatsOn::Event -> fetch ( $self -> dbh , $filter ) ;

  foreach my $event ( @events ) {

    $event -> dates ( $event -> dates_derived )
      unless $event -> dates ;

    $event -> times ( '7.30pm' )
      unless $event -> times ;

    $event -> presented_by ( $event -> society_name )
      unless $event -> presented_by ;

  }

#-------------------------------------------------------------------------------

# Produce Output as HTML

  my $tmpl = $self -> template -> load ;
  $tmpl -> param ( 'events' => \@events ) ;
  my $pagesize = $query -> param ( 'flyer_pagesize' ) ;
  $tmpl -> param ( 'pagesize' => $pagesize ) ;

  my $exceeds ; # lowest no. of events found to exceed what can fit on one page
  my $fits ; # highest no of events found to fit on one page
  my $limit ; # no. of events to limit the generated PDF to

  if (
    $pagesize eq 'A4'
    && scalar @events > $self -> conf -> param ( 'pdf_a4_seed' )
  ) {

    # The page size is A4 and there are more events than we THINK can fit on to
    # an A4 page, so limit the events on the page to how many we THINK can fit.
    $limit = $self -> conf -> param ( 'pdf_a4_seed' ) ;

  } elsif (
    $pagesize eq 'A5'
    && scalar @events > $self -> conf -> param ( 'pdf_a5_seed' )
  ) {

    # The page size is A5 and there are more events than we THINK can fit on to
    # an A5 page, so limit the events on the page to how many we THINK can fit.
    $limit = $self -> conf -> param ( 'pdf_a5_seed' ) ;

  }

GENPDF:

  $tmpl -> param ( 'limit' => $limit ) if $limit ;
  my $html = $tmpl -> output ;
  my $htmldoc = new HTML::HTMLDoc ;
  $htmldoc -> set_bodyfont ( 'Arial' ) ;
  $htmldoc -> set_charset ( 'iso-8859-1' ) ;
  $htmldoc -> set_footer ( '.' , '.' , '.' ) ;
  $htmldoc -> set_header ( '.' , 'l' , '.' ) ;
  $htmldoc -> set_html_content ( encode ( 'iso-8859-1' , $$html ) ) ;
  $htmldoc -> set_logoimage ( $env -> { assets } . '/img/logo.jpg' ) ;
  # Set page up for A4 or A5. Note that A4 is the default page size.
  if ( $pagesize eq 'A5' ) {
    $htmldoc -> set_fontsize ( 10 ) ;
    $htmldoc -> set_page_size ( '148x210mm' ) ;
    $htmldoc -> set_left_margin ( 10 , 'mm' ) ;
    $htmldoc -> set_right_margin ( 10 , 'mm' ) ;
    $htmldoc -> set_top_margin ( 14 , 'mm' ) ;
    $htmldoc -> set_bottom_margin ( 14 , 'mm' ) ;
  } else { # Page size = A4, either explicitly or because it's the default.
    $htmldoc -> set_fontsize ( 11 ) ;
    $htmldoc -> set_left_margin ( 14 , 'mm' ) ;
    $htmldoc -> set_right_margin ( 14 , 'mm' ) ;
    $htmldoc -> set_top_margin ( 20 , 'mm' ) ;
    $htmldoc -> set_bottom_margin ( 20 , 'mm' ) ;
  }

  my $pdf = PDF::API2 -> from_string ( $htmldoc -> generate_pdf -> to_string ) ;

  if ( $pdf -> page_count == 1 ) {

    # The generated PDF fits on to one page.

    # If this is the most events than we've found so far can fit on one page,
    # then register that.
    $fits = $limit if ! $fits || $fits < $limit ;

    if ( $limit && ! $exceeds || $exceeds > $limit + 1 ) {

      # We have not included all events and it may be possible to add more
      # without exeeding the no. of events that can fit on one page. Let's see
      # if we can get more events on to a single page.

      if ( ! $exceeds ) {

        # We have not yet specified a number of events that exceed one page, so
        # lets increase our limit by the configured increment for the page size
        # that we are using.

        if ( $pagesize eq 'A4' ) {
          $limit += $self -> conf -> param ( 'pdf_a4_incr' ) ;
        } else {
          # Page size = A5.
          $limit += $self -> conf -> param ( 'pdf_a5_incr' ) ;
        }

      } else {

        # We know that the limit we just used fits on one page and we know a
        # number of events that exceeds one page, so let's try half way
        # inbetween as the next limit.
        $limit = int ( ( $limit + $exceeds ) / 2 ) ;

      }

      # Try again with our new limit.
      goto GENPDF ;

    }

  } else {

    # The generated PDF does NOT fit on to one page.

    # If this is the least no. of events that we've found so far that can not
    # fit on one page, then register that.
    $exceeds = $limit if ! $exceeds || $exceeds > $limit ;

    if ( ! $fits ) {

      # We have not yet specified a number of events that fits on one page, so
      # lets decrease our limit by the configured increment for the page size
      # that we are using.

      if ( $pagesize eq 'A4' ) {
        $limit -= $self -> conf -> param ( 'pdf_a4_incr' ) ;
      } else {
        # Page size = A5.
        $limit -= $self -> conf -> param ( 'pdf_a5_incr' ) ;
      }

      # Try again with our new limit.
      goto GENPDF ;

    } elsif ( $fits < $limit - 1 ) {

      # We know that the limit we just used exceeds one page and we know a
      # number of events that fits on one page, so let's try half way
      # inbetween as the next limit.

      $limit = int ( ( $limit + $fits ) / 2 ) ;

      # Try again with our new limit.
      goto GENPDF ;

    } else {

      $limit -= 1 ;
      goto GENPDF ;

    }

  }

  my $output = $pdf -> to_string ;
  $self -> header_add (
    -type                  => 'application/pdf'                    ,
    -Content_Disposition  => 'attachment; filename="events.PDF"'  ,
    -Content_Length        => length $output
  ) ;

  return $output ;

}

sub _authorised {

  # This is an internal subroutine that implements a data based _authorisation
  # check prior to executing the run mode. The associated data based rules are
  # as follows:
  # 1. A user with the role of 'admin' can do anything;
  # 2. A user with the role of 'rep' can only update the societies that they
  #    represent and can only update the events associated with those societies.

  my ( $self , $rmObj ) = @_ ; # $rmObj = 'event' or 'society'
  my $query = $self -> query ;

  my $society_rowid ; # Ready to be allocated a value immediately below

  if ( $rmObj eq 'event' && $query -> param ( 'event_society') ) {

    # This is an event action (as opposed to page display) with the
    # society_rowid as one of the query object parameters.
    $society_rowid = scalar $query -> param ( 'event_society') ;

  } elsif ( $rmObj eq 'event' && $query -> param ( 'event_rowid' ) ) {

    # This is an event action (as opposed to page display) with the event_rowid
    # as one of the query object parameters. Check to see if there is a
    # corresponding society_rowid.

    my $event = new DATA::WhatsOn::Event ;
    $event -> rowid ( $query -> param ( 'event_rowid' ) ) ;
    $event -> fetch ( $self -> dbh ) ;
    $society_rowid = $event -> society_rowid if $event -> society_rowid ;

  } elsif ( $rmObj eq 'event' && $self -> param ( 'rowid' ) ) {

    # This is an event page display (as opposed to action) so we have the event
    # rowid as an application parameter and must check to see if there is a
    # corresponding society_rowid.
    my $event = new DATA::WhatsOn::Event ;
    $event -> rowid ( $self -> param ( 'rowid' ) ) ;
    $event -> fetch ( $self -> dbh ) ;
    $society_rowid = $event -> society_rowid if $event -> society_rowid ;

  } elsif ( $rmObj eq 'society' && $query -> param ( 'organisation_rowid' ) ) {

    # This is a society action (as opposed to page display) with the
    # organisation_rowid (which corresponds to the society_rowid) as one of the
    # query parameter objects.
    $society_rowid = scalar $query -> param ( 'organisation_rowid' ) ;

  } elsif ( $rmObj eq 'society' && $self -> param ( 'rowid') ) {

    # This is a society page display (as opposed to action) so the society
    # rowid is an application parameter.
    $society_rowid = $self -> param ( 'rowid' ) ;

  } else {

    # We could conceivably end up here if an event is added or updated with no
    # associated society OR if a society is being added and doesn't yet have a
    # rowid assigned. If that's the case then the user role MUST be 'admin'
    # and they will be authorised through their role alone.

  }

  # Build an input hash of the parameters required for the authorisation check
  my $input_hash = {
    society_rowid  => $society_rowid  ,
    user_role      => $self -> session -> param ( 'role' )    ,
    user_userid    => $self -> session  -> param ( 'userid' )  ,
  } ;

  my $dfv_profile = {

    required => [ qw /
      user_role
      user_userid
    / ] ,

    # Admins can be acting on an event that is not associated with a society
    optional => [ qw /
      society_rowid
    / ] ,

    # Reps MUST always act on behalf of a member society whereas admins may
    # not; for exmaple, when they create an event that isn't linked to a
    # member society.
    dependencies => {
      'user_role' => {
        rep => [ qw / society_rowid / ] ,
      } ,
    } ,

    constraint_methods => {

      user_userid => {
        constraint_method => user_is_authorised ( $self -> dbh )
      }

    }

  } ;

  my $results = Data::FormValidator -> check ( $input_hash , $dfv_profile ) ;

  if ( %{ $results -> invalid } ) {

    return 0 ; # Unauthorised

  } else {

    return 1 ; # Authorised

  }

}

=head2 Event Management

Run modes that support the management of events

=cut

sub event_programme {

=head3 event_programme

Handle the addition of event programme details or a change to existing event
programme details.

=cut

  my $self = shift ;
  my $query = $self -> query ;

  # Initialise redirect with the root
  # We will append the location within the root according to the submit button
  my $env = $self -> conf -> param ( 'env' ) ;
  my $redirect = $env -> { root } ;

#-------------------------------------------------------------------------------

#
# Check the authorisation of the user before we go any further
#

  unless ( _authorised ( $self , 'event' ) ) {

    $redirect .= '/unauthorised' ;
    goto REDIRECT ;

  }

#-------------------------------------------------------------------------------

#
# We have reached here so we know that the user is authorised. Now check if this
# is a delete request. Delete requests are very much more simple than adds or
# updates.
#

  if ( defined $query -> param ( 'delete' ) ) {

    # This is a request to delete
    my $event = new DATA::WhatsOn::Event ;
    # The delete button is only enabled where there is a rowid
    # So we can safely assume that it is present without validating
    $event -> rowid ( scalar $query -> param ( 'event_rowid' ) ) ;
    $event -> delete ( $self -> dbh ) ;
    $redirect .= $self -> conf -> param ( 'onDelete' ) ;
    goto REDIRECT ;

  }

#-------------------------------------------------------------------------------

#
# We have an add or update
#

  my $event_form = {

    required => [ qw /
      event_name
      event_start_date
      event_status
    / ] , # End of required array

    optional => [ qw /
      event_box_office
      event_dates
      event_end_date
      event_presented_by
      event_rowid
      event_society
      event_times
      event_venue
    / ] , # End of optional array

    require_some => {

      # We require at least one of event_society and event_presented_by
      society_or_presented_by => [ qw /
        event_society
        event_presented_by
      / ] ,

    } , # End of require_some hash

    dependencies => {

      # If event status is Published,
      # require event_venue and event_box_office
      'event_status' => {
        PUBLISHED => [ qw / event_venue event_box_office / ] ,
      }

    } , # End of dependencies hash

    constraint_methods => {

      event_end_date => [
        {
          constraint_method => to_datetime ( '%d/%m/%Y' ) ,
          name => 'end_date_valid'
        } ,
        {
          constraint_method => FV_or (
            FV_not ( to_datetime ( '%d/%m/%Y' ) ) ,
            FV_not (
              before_datetime ( '%d/%m/%Y' , 'event_start_date' )
            )
          ) ,
          name => 'end_date_not_before_start_date'
        } ,
      ] , # End of event_end_date array

      event_start_date => [
        {
          constraint_method => to_datetime ( '%d/%m/%Y' ) ,
          name => 'start_date_valid'
        } ,
        {
          constraint_method => FV_or (
            FV_not ( to_datetime ( '%d/%m/%Y' ) ) ,
            after_today ( '%d/%m/%Y' )
          ) ,
          name => 'start_date_after_today'
        } ,
      ] , # End of event_start_date array

      event_status => {
        constraint_method =>
          FV_set ( 1 , qw / PUBLISHED PLACEHOLDER / ) ,
          name => 'event_status_valid'
      } , # End of event_status hash

      event_venue => {
        constraint_method =>
          venue_exists ( $self -> dbh ) ,
          name => 'venue_exists'
      } , # End of event_venue hash

    } , # End of constraint_methods hash

    msgs => $_messages

  } ; # End of $event_form

  my $results = $self -> check_rm (
    'form_response' ,
    $event_form  ,
  ) || return \$self -> check_rm_error_page ;

  # We have passed validation, build and save the event object

  my $event = new DATA::WhatsOn::Event ;

  # event_rowid
  if ( scalar $query -> param ( 'event_rowid' ) ) {

    $event -> rowid ( scalar $query -> param ( 'event_rowid' ) ) ;

    # Need a fetch here for the online promotion values, which aren't part
    # of the programme listing run mode.

    $event -> fetch ( $self -> dbh ) ;

  } else {

    $event -> use_desc ( 0 ) ;

  }

#-------------------------------------------------------------------------------
# Process each update in turn. Log if we have updated existing event details.

  my $updated = 0 ; # Boolean to capture if details have been updated

  # event_name
  $updated = 1 if scalar $query -> param ( 'event_rowid' )
    && $event -> name ne scalar $query -> param ( 'event_name' ) ;
  $event -> name ( scalar $query -> param ( 'event_name' ) ) ;

  # event_status
  $updated = 1 if scalar $query -> param ( 'event_rowid' )
    && $event -> status ne scalar $query -> param ( 'event_status' ) ;
  $event -> status ( scalar $query -> param ( 'event_status' ) ) ;

  # event_start_date
  $updated = 1 if scalar $query -> param ( 'event_rowid' )
    && $event -> start_date ne scalar $query -> param ( 'event_start_date' ) ;
  $event -> start_date ( scalar $query -> param ( 'event_start_date' ) ) ;

  # event_end_date
  $updated = 1 if scalar $query -> param ( 'event_rowid' )
    && $event -> end_date ne scalar $query -> param ( 'event_end_date' ) ;
  if ( scalar $query -> param ( 'event_end_date' ) ) {
    $event -> end_date ( scalar $query -> param ( 'event_end_date' ) ) ;
  } else {
    # Default event end_date to event start_date if not provided
    $event -> end_date ( scalar $query -> param ( 'event_start_date' ) ) ;
  }

  # event_dates
  $updated = 1 if scalar $query -> param ( 'event_rowid' )
    && $event -> dates ne scalar $query -> param ( 'event_dates' ) ;
  if ( scalar $query -> param ( 'event_dates' ) ) {
    $event -> dates ( scalar $query -> param ( 'event_dates' ) ) ;
  } else {
    # Derive event dates from event start_date and event end_date
    $event -> dates ( $event -> dates_derived ) ;
  }

  # event_times
  $updated = 1 if scalar $query -> param ( 'event_rowid' )
    && $event -> times ne scalar $query -> param ( 'event_times' ) ;
  scalar $query -> param ( 'event_times' )
    ? $event -> times ( scalar $query -> param ( 'event_times' ) )
    : $event -> times ( '7.30pm' ) ;

  # event_society
  $updated = 1 if scalar $query -> param ( 'event_rowid' )
    && $event -> society_rowid ne scalar $query -> param ( 'event_society' ) ;
  $event -> society_rowid ( scalar $query -> param ( 'event_society' ) ) ;

  # event_presented_by
  $updated = 1 if scalar $query -> param ( 'event_rowid' ) &&
    $event -> presented_by ne scalar $query -> param ( 'event_presented_by' ) ;
  $event -> presented_by ( scalar $query -> param ( 'event_presented_by' ) ) ;

  # event_venue
  $updated = 1 if scalar $query -> param ( 'event_rowid' ) &&
    $event -> venue_name ne scalar $query -> param ( 'event_venue' ) ;
  if ( scalar $query -> param ( 'event_venue' ) ) {
    my $venue = new DATA::WhatsOn::Organisation ;
    $venue -> name ( scalar $query -> param ( 'event_venue' ) ) ;
    $venue -> type ( 'whatson_venue' ) ;
    $venue -> fetch ( $self -> dbh ) ;
    $event -> venue_rowid ( $venue -> rowid ) ;
  }

  # event_box_office
  $updated = 1 if scalar $query -> param ( 'event_rowid' ) &&
    $event -> box_office ne scalar $query -> param ( 'event_box_office' ) ;
  $event -> box_office ( scalar $query -> param ( 'event_box_office' ) ) ;

#-------------------------------------------------------------------------------
# Save the results and notify the webmin that this has happened

  # Save will give us back the event rowid, whether it's an update or an insert
  my $rowid = $event -> save ( $self -> dbh ) ;

  my $webmin = $env -> { webmin } ;

  $self -> sendmail (
    $webmin                                              ,
    'DATA Diary - Event Programme Listing'              ,
    {
      event => $event                                    ,
      userid => $self -> session  -> param ( 'userid' )  ,
    }                                                    ,
  ) ;

#-------------------------------------------------------------------------------
# Determine where to go based on the save mode selected by the user

  if ( defined $query -> param ( 'save_and_continue' ) ) {

    $redirect .= $self -> conf -> param ( 'onSaveAndContinue' ) ;

  } elsif ( defined $query -> param ( 'save_and_exit' ) ) {

    $redirect .= $self -> conf -> param ( 'onSaveAndExit' ) ;

  } elsif ( defined $query -> param ( 'save_and_online' ) ) {

    $redirect .= $self -> conf -> param ( 'onSaveAndOnline' ) ;

  } elsif ( defined $query -> param ( 'save_and_preview' ) ) {

    $redirect .= $self -> conf -> param ( 'onSaveAndPreview' ) ;

  }


#-------------------------------------------------------------------------------
# Check if they've updated the programme listing and have a custom online card

  # Updated flag set above & if use_desc = 1 or 2 (true), we have a custom card
  if ( $updated && $event -> use_desc ) {

    $self -> session -> param ( 'show_warning' , 'event_updated' ) ;
    $self -> session -> flush ;

  }

REDIRECT:
  my $role = $self -> session -> param ( 'role' ) ;
  $redirect =~ s/:role/$role/;
  $redirect =~ s/:rowid/$rowid/;
  $self -> redirect ( $redirect ) ;

}

sub event_online {

=head3 event_online

Handle the addition of an event online listing or changes to an existing event
online listing.

=cut

  my $self = shift ;
  my $query = $self -> query ;

  # Initialise redirect with the root
  # We will append the location within the root according to the submit button
  my $env = $self -> conf -> param ( 'env' ) ;
  my $redirect = $env -> { root } ;

#-------------------------------------------------------------------------------

#
# Check the authorisation of the user before we go any further
#

  unless ( _authorised ( $self , 'event' ) ) {

    $redirect .= '/unauthorised' ;
    goto REDIRECT ;

  }

#-------------------------------------------------------------------------------

#
# We have reached here so we know that the user is authorised. Now check if this
# is a delete request. Delete requests are very much more simple than adds or
# updates.
#

  if ( defined $query -> param ( 'delete' ) ) {

    # This is a request to delete
    my $event = new DATA::WhatsOn::Event ;
    # The delete button is only enabled where there is a rowid
    # So we can safely assume that it is present without validating
    $event -> rowid ( scalar $query -> param ( 'event_rowid' ) ) ;
    $event -> delete ( $self -> dbh ) ;
    $redirect .= $self -> conf -> param ( 'onDelete' ) ;
    goto REDIRECT ;

  }

#-------------------------------------------------------------------------------

#
# We have an add or update
#

  my $event_form = {

    required => [ qw /
      event_use_desc
    / ] , # End of required array

    optional => [ qw /
      mceEventDescription
      mceEventImage
    / ] , # End of optional array

    dependencies => {

      # Require description and imagae according to event_use_desc
      'event_use_desc' => {
        1 => [ qw / mceEventDescription mceEventImage / ] ,
        2 => [ qw / mceEventDescription / ] ,
      }

    } , # End of dependencies hash

    constraint_methods => {

      event_use_desc => {
        constraint_method  => FV_set_num ( 1 , ( 0 , 1 , 2 ) ) ,
        name              => 'event_use_desc_valid'
      } , # End of event_use_desc hash

      mceEventDescription => {
        constraint_method  => event_description_valid ,
        name              => 'event_description_valid'
      } , # End of mceEventDescription hash

      mceEventImage => {
        constraint_method =>  event_image_valid ( $env -> { root } ) ,
        name              => 'event_image_valid'
      } , # End of mceEventImage hash

    } , # End of constraint_methods hash

    msgs => $_messages

  } ; # End of event_form sub

  # If mceEventImage is the 'click_me' image then this is effecitvely null input
  $query -> param ( 'mceEventImage' , '' )
    if $query -> param ( 'mceEventImage' ) eq $query -> param ( 'click_me' ) ;

  my $results = $self -> check_rm ( 'form_response' , $event_form )
    || return \$self -> check_rm_error_page ;

  # We have passed validation, build and save the event object

  # If mceEventDescription matches the default event description then this is
  # effectively null input and so we null it out so that we dont store anything
  # for the description. This would effectively be denormalisation. Note that
  # we do not do this prior to validation as we don't want to tell people they
  # haven't given any input if they say yes to a custom description and then
  # don't actually edit the default description.
  $query -> param ( 'mceEventDescription' , '' )
    if $query -> param ( 'mceEventDescription' )
    eq $query -> param ( 'event_default_description' ) ;

#-------------------------------------------------------------------------------
# mceEventImage contains the HTML in the image card section but we only
# want to store the URL of any image that's been selected.

  my $image = '' ;

  if ( $query -> param ( 'mceEventImage' ) ) {

    my $html = scalar $query -> param ( 'mceEventImage' ) ;
    $html =~ /^
      <p>
        <img\s
          src="(.+?)"\s
          (?:width="\d+"\sheight="\d+"\s)?
        \/>
      <\/p>
    $/x ;
    $image = $1 ;

  }

#-------------------------------------------------------------------------------
# Fetch the event object and process each update in turn logging if there has
# been a change to the value that was already stored.

  # Fetch
  my $event = new DATA::WhatsOn::Event ;
  $event -> rowid ( scalar $query -> param ( 'event_rowid' ) ) ;
  $event -> fetch ( $self -> dbh ) ;

  my $updated = 0 ; # Boolean to capture if details have been updated

  $updated = 1
  if scalar $query -> param ( 'event_use_desc' ) ne $event -> use_desc ;
  $event -> use_desc ( scalar $query -> param ( 'event_use_desc' ) ) ;

  $updated = 1
  if scalar $query -> param ( 'mceEventDescription' ) ne $event -> description ;
  $event -> description ( scalar $query -> param ( 'mceEventDescription' ) ) ;

  $updated = 1 if $image ne $event -> image ;
  $event -> image ( $image ) ;

#-------------------------------------------------------------------------------
# Save the results and notify the webmin that this has happened

  # Save will give us back the event rowid, whether it's an update or an insert
  my $rowid = $event -> save ( $self -> dbh ) ;

  my $webmin = $env -> { webmin } ;

  $self -> sendmail (
    $webmin                                              ,
    'DATA Diary - Event Online Promotion'                ,
    {
      event => $event                                    ,
      userid => $self -> session  -> param ( 'userid' )  ,
    }                                                    ,
  ) ;

#-------------------------------------------------------------------------------
# Determine where to go based on the save mode selected by the user

if ( defined $query -> param ( 'save_and_continue' ) ) {

  $redirect .= $self -> conf -> param ( 'onSaveAndContinue' ) ;

} elsif ( defined $query -> param ( 'save_and_exit' ) ) {

  $redirect .= $self -> conf -> param ( 'onSaveAndExit' ) ;

} elsif ( defined $query -> param ( 'save_and_programme' ) ) {

  $redirect .= $self -> conf -> param ( 'onSaveAndProgramme' ) ;

} elsif ( defined $query -> param ( 'save_and_preview' ) ) {

  $redirect .= $self -> conf -> param ( 'onSaveAndPreview' ) ;

}

REDIRECT:
  my $role = $self -> session -> param ( 'role' ) ;
  $redirect =~ s/:role/$role/;
  $redirect =~ s/:rowid/$rowid/;
  $self -> redirect ( $redirect ) ;

}

sub rep_event_display {

=head3 rep_event_display

Display the details of an event or a society for a rep to update. This would be
handled by the auto run mode in the Main module except that we need an
application specific, data based authorisation check. So, the relevent run modes
are directed to here in this module instead.

=cut

  my $self = shift ;
  my $env = $self -> conf -> param ( 'env' ) ;

  if ( _authorised ( $self , 'event' ) ) {

    my $tmpl = $self -> template -> load ;
    return $tmpl -> output ;

  } else {

    return $self -> redirect ( $env -> { root } . 'unauthorised' ) ;

  }

}

=head2 Organisation Management

Run modes that support the management of organisations

=cut

sub organisation {

=head3 organisation

Adds or updates a member society record.

=cut

  my $self = shift ;
  my $query = $self -> query ;

  # Initialise redirect with the root
  # We will append the location within the root later
  my $env = $self -> conf -> param ( 'env' ) ;
  my $redirect = $env -> { root } ;

#-------------------------------------------------------------------------------

#
# Check the authorisation of the user before we go any further
#

  unless ( _authorised ( $self , 'society' ) ) {

    $redirect .= '/unauthorised' ;
    goto REDIRECT ;

  }

  my $organisation_form = {

    required => [ qw /
      organisation_name
      organisation_status
      organisation_type
    / ] ,

    optional => [ qw /
      organisation_description
      organisation_email
      organisation_rowid
      organisation_website
    / ] ,

    constraint_methods => {

      organisation_status => {
        constraint_method  => FV_set ( 1 , qw / ACTIVE INACTIVE / ) ,
        name              => 'status_valid'
      } ,

    } ,

    msgs => $_messages

  } ; # End of organisation_form profile

  my $results = $self -> check_rm ( 'form_response' , $organisation_form )
  || return \$self -> check_rm_error_page ;

  my $organisation = new DATA::WhatsOn::Organisation ;

  $organisation
    -> rowid        ( scalar $query -> param ( 'organisation_rowid'        ) ) ;
  $organisation
    -> type          ( scalar $query -> param ( 'organisation_type'        ) ) ;
  $organisation
    -> name          ( scalar $query -> param ( 'organisation_name'        ) ) ;
  $organisation
    -> status        ( scalar $query -> param ( 'organisation_status'      ) ) ;
  $organisation
    -> website      ( scalar $query -> param ( 'organisation_website'      ) ) ;
  $organisation
    -> email        ( scalar $query -> param ( 'organisation_email'        ) ) ;
  $organisation
    -> description  ( scalar $query -> param ( 'organisation_description'  ) ) ;

  $organisation -> save ( $self -> dbh ) ;

  $redirect .= scalar $query -> param ( 'onSuccess' ) ;

REDIRECT:
  $self -> redirect ( $redirect ) ;

} # End of organisation sub

sub rep_society_display {

=head3 rep_society_display

Display the details of a society for a rep to view or update. This would be
handled by the auto run mode in the Main module except that we need an
application specific, data based authorisation check. So, the relevent run modes
are directed to here in this module instead.

=cut

  my $self = shift ;
  my $env = $self -> conf -> param ( 'env' ) ;

  if ( _authorised ( $self , 'society' ) ) {

    my $tmpl = $self -> template -> load ;
    return $tmpl -> output ;

  } else {

    return $self -> redirect ( $env -> { root } . 'unauthorised' ) ;

  }

}

1 ;

__END__
