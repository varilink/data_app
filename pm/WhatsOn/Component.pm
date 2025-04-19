package DATA::WhatsOn::Component ;

=head1 DATA::WhatsOn::Component

=cut

use strict ;
use warnings ;

use base qw / Exporter / ;

use DATA::WhatsOn::Contact ;
use DATA::WhatsOn::Event ;
use DATA::WhatsOn::NewsItem ;
use DATA::WhatsOn::Organisation ;

my @run_modes = qw /

  whatson_contact
  whatson_contacts
  whatson_event
  whatson_events
  whatson_news_item
  whatson_news_items
  whatson_society
  whatson_societies
  whatson_venue
  whatson_venues

/ ;

sub _init {

  # Register run modes from the run modes array

  my $c = shift ;

  $c -> run_modes ( [ @run_modes ] ) ;

}

# Export the run modes
our @EXPORT = @run_modes ;

# Allow all the run modes to be exported
our @EXPORT_OK = @run_modes ;

sub import {

   # Determine my caller
   my $caller = scalar caller ;

   # Use the _init method as an init stage cgi application call back
   $caller -> add_callback (
      'init' ,
      \&_init
   ) ;

   # Inherit the import method of the base class
   goto &Exporter::import ;

}

sub whatson_contact {

=head2 whatson_contact

=cut

   my $self = shift ;

   my $rowid = $self -> param ( 'rowid' ) ;

   my $contact = new DATA::WhatsOn::Contact ;

   $contact -> rowid ( $rowid ) ;

   $contact -> fetch ( $self -> dbh ) ;

   my $tmpl = $self -> template -> load ;

   $tmpl -> param ( contact => $contact ) ;

   return $tmpl -> output ;

}

sub whatson_contacts {

=head2 whatson_contacts

=cut

   my $self = shift ;
  my $containing_tmpl = shift ;

  # This component can optionally take a number of positional (note, position
  # is therefore important) parameters.

  my $filter ;
  $filter -> { org_id }  = shift if @_ ; # Organisation Identifier

   my @contacts = DATA::WhatsOn::Contact -> fetch (
    $self -> dbh , $filter
  ) ;

  my $output = "[% whatson_contacts %]" ;

   my $tmpl = $self -> template -> load ( \$output ) ;

   $tmpl -> param ( contacts => \@contacts ) ;

   return $tmpl -> output ;

}

sub whatson_event {

=head2 whatson_event

=cut

  my $self = shift ;
  my $containing_template = shift ;

  my $params = shift if @_ ;

  # Controls what data will be returned
  my $filter = $params -> { filter } if $params -> { filter } ;
  # Controls component behaviour, e.g. where or not defaults are returned
  my $behaviour = $params -> { behaviour } if $params -> { behaviour } ;

   my $event = new DATA::WhatsOn::Event ;

   $event -> rowid ( $filter -> { rowid } ) ;

   if ( $event -> fetch ( $self -> dbh , $filter ) ) {

    if ( $behaviour -> { defaults } ) {

      # Apply some of the default values on optional fields

      $event -> dates ( $event -> dates_derived )
        unless $event -> dates ;

      $event -> times ( '7.30pm' )
        unless $event -> times ;

      $event -> presented_by ( $event -> society_name )
        unless $event -> presented_by ;

    }

    my $caller = $containing_template -> param ( 'template' ) -> { 'name' } ;

    my $output = "[% whatson_event ( caller = \"$caller\" ) %]" ;

     my $tmpl = $self -> template -> load ( \$output ) ;

     $tmpl -> param ( event => $event ) ;

     return $tmpl -> output ;

  } else {

    if (
      $filter -> { userid }                &&
      delete $filter -> { userid }            &&
      $event -> fetch ( $self -> dbh , $filter )
    ) {

      $self -> header_props ( -status => '403' ) ;

    } else {

      $self -> header_props ( -status => '404' ) ;

    }

  }

}

sub whatson_events {

=head2 whatson_events

=cut

  my $self =  shift ;
  my $containing_template = shift ;

  my $params = shift if @_ ;

  # Controls what data will be returned
  my $filter = $params -> { filter } if $params ;
  # Controls component behaviour, e.g. where or not defaults are returned
  my $behaviour = $params -> { behaviour } if $params -> { behaviour } ;

  my @events = ( ) ;

  @events = DATA::WhatsOn::Event -> fetch ( $self -> dbh , $filter ) ;

  foreach my $event ( @events ) {

    if ( $behaviour -> { defaults } ) {

      # Apply some of the default values on optional fields

      $event -> dates ( $event -> dates_derived ) unless $event -> dates ;

      $event -> times ( '7.30pm' ) unless $event -> times ;

      if (
        $event -> presented_by
        &&
        $event -> presented_by =~ /^"(.+)"$/
      ) {

        # Remove the quotes for pages that request defaults to be populated.
        # These will ONLY be the read only pages.
        # Update pages will require the raw database fields.
        # $event -> presented_by ( $1 ) ;

      } elsif ( ! $event -> presented_by ) {

        $event -> presented_by ( $event -> society_name ) ;

      }

    }

  }

  my $caller = $containing_template -> param ( 'template' ) -> { 'name' } ;

  my $output = "[% whatson_events ( caller = \"$caller\" ) %]" ;

  my $tmpl = $self -> template -> load ( \$output ) ;

  $tmpl -> param ( events => \@events ) ;

  return $tmpl -> output ;

}

sub whatson_news_item {

=head2 whatson_news_item

=cut

   my $self = shift ;
  my $containing_template = shift ;

   my $rowid = $self -> param ( 'rowid' ) ;

   my $news_item = new DATA::WhatsOn::NewsItem ;

   $news_item -> rowid ( $rowid ) ;

   if ( $news_item -> fetch ( $self -> dbh ) ) {

    my $caller = $containing_template -> param ( 'template' ) -> { 'name' } ;

    my $output = "[% whatson_news_item ( caller = \"$caller\" ) %]" ;

     my $tmpl = $self -> template -> load ( \$output ) ;

     $tmpl -> param ( news_item => $news_item ) ;

     return $tmpl -> output ;

  } else {

    # Set the redirect headers for the application to not found
    $self -> redirect ( '/not_found' ) ;

  }

}

sub whatson_news_items {

=head2 whatson_news_items

=cut

  my $self = shift ;
  my $containing_template = shift ;

  my $params = shift if @_ ;

  my @news_items = ( ) ;

  my $filter = $params -> { filter } if $params ;

  @news_items =
    DATA::WhatsOn::NewsItem -> fetch ( $self -> dbh , $filter ) ;

  my $caller = $containing_template -> param ( 'template' ) -> { 'name' } ;

  my $output = "[% whatson_news_items ( caller = \"$caller\" ) %]" ;

  my $tmpl = $self -> template -> load ( \$output ) ;

  $tmpl -> param ( news_items => \@news_items ) ;

  return $tmpl -> output ;

}

sub whatson_society {

   my $self = shift ;
  my $containing_template = shift ;

  my $params = shift if @_ ;

  # Controls what data will be returned
  my $filter = $params -> { filter } if $params ;

  #my $filter = { } ;
  $filter -> { type }    = 'whatson_society' ;
  #$filter -> { status }  = shift if @_ ;

   #my $rowid = $self -> param ( 'rowid' ) ;

   my $society = new DATA::WhatsOn::Organisation ;

   $society -> rowid ( $filter -> { rowid } ) ;

   if ( $society -> fetch ( $self -> dbh , $filter ) ) {

    my $caller = $containing_template -> param ( 'template' ) -> { 'name' } ;

    my $output = "[% whatson_society ( caller = \"$caller\" ) %]" ;

     my $tmpl = $self -> template -> load ( \$output ) ;

     $tmpl -> param ( society => $society ) ;

     return $tmpl -> output ;

  } else {

    if (
      $filter -> { userid }                &&
      delete $filter -> { userid }            &&
      $society -> fetch ( $self -> dbh , $filter )
    ) {

      $self -> header_props ( -status => '403' ) ;

    } else {

      $self -> header_props ( -status => '404' ) ;

    }

  }

}

sub whatson_societies {

=head2 whatson_societies

List all the societies

=cut

   my $self =  shift ;
  my $containing_template = shift ;

  my $params = shift if @_ ;

  # Controls what data will be returned
  my $filter = $params -> { filter } if $params ;

  # This component can optionally take a number of positional (note, position
  # is therefore important) parameters.

  $filter -> { type } = 'whatson_society' ;

  #$filter -> { status }  = shift if @_ ; # Status of organisations
  #$filter -> { userid }  = shift if @_ ; # Userid of member society rep

   my @societies = DATA::WhatsOn::Organisation -> fetch (
    $self -> dbh , $filter
  ) ;

  my $caller ;

  if (
    $containing_template -> param ( 'template' ) -> { 'name' } eq 'input text'
  ) {
    $caller = $containing_template -> param ( 'template' ) -> { 'caller' } ;
  } else {
    $caller = $containing_template -> param ( 'template' ) -> { 'name' } ;
  }

  my $output = "[% whatson_societies ( caller = \"$caller\" ) %]" ;

   my $tmpl = $self -> template -> load ( \$output ) ;

   $tmpl -> param ( societies => \@societies ) ;

   return $tmpl -> output ;

}

sub whatson_venue {

=head2 whatson_venue

=cut

  my $self = shift ;
  my $containing_template = shift ;

  my $params = shift if @_ ;

  # Controls what data will be returned
  my $filter = $params -> { filter } if $params ;

   my $event_rowid = $filter -> { event } ;

  my $event = new DATA::WhatsOn::Event ;
  $event -> rowid ( $event_rowid ) ;
  $event -> fetch ( $self -> dbh ) ;

  my $output = '[% whatson_venue %]' ;

  my $tmpl = $self -> template -> load ( \$output ) ;

  if ( $event -> venue_rowid ) {

    my $venue = new DATA::WhatsOn::Organisation ;
    $venue -> rowid ( $event -> venue_rowid ) ;
    $venue -> fetch ( $self -> dbh ) ;

    $tmpl -> param ( venue => $venue ) ;

  }

  return $tmpl -> output ;

}

sub whatson_venues {

=head2 whatson_venues

=cut

  my $self = shift ;
  my $containing_template = shift ;

  my $filter ;

  if ( my $param = shift ) {

    # A parameter has been supplied. For this component that can only be a
    # status filter.

    $filter = { type => 'whatson_venue' , status => $param } ;

  } else {

    $filter = { type => 'whatson_venue' } ;

  }

   my @venues = DATA::WhatsOn::Organisation -> fetch (
    $self -> dbh , $filter
  ) ;

  my $output = '[% whatson_venues %]' ;

   my $tmpl = $self -> template -> load ( \$output ) ;

   $tmpl -> param ( venues => \@venues ) ;

   return $tmpl -> output ;

}

1 ;

__END__
