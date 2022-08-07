package DATA::WhatsOn::Constraints ;

=head1 DATA::WhatsOn::Constraints

=cut

use strict ;

use base qw / Exporter / ;

use DATA::Auth::User ;
use DATA::WhatsOn::Contact ;
use DATA::WhatsOn::Event ;
use DATA::WhatsOn::Organisation ;

use File::LibMagic ;
use LWP::UserAgent ;

our @EXPORT = qw /

  contact_is_subscribed
  event_description_valid
  event_image_provided
  event_image_valid
  unsubscribe_valid
  user_is_authorised
  user_is_rep_for_event
  venue_exists

/ ;

sub contact_is_subscribed {

=head2 contact_is_subscribed

=cut

  my $dbh = shift ;

  return sub {

    my ( $dfv , $value ) = @_ ;

    my $contact = new DATA::WhatsOn::Contact ;
    $contact -> email ( $value ) ;
    return 1 if $contact -> fetch ( $dbh ) && $contact -> subscriber ;
    return 0 ;

  }

}

sub event_description_valid {

=head2 event_description_valid

Tests if the event description has non HTML content in it, i.e. it does contain
descriptive text and not just markup tags.

=cut

  return sub {

    my ( $dfv , $value ) = @_ ;

    $value =~ s/<.+?>//g ; # Strip the HTML from the value
    return $value ; # If there's content left this will be true

  }

}

sub event_image_provided {

=head2 event_image_provided

=cut

  my $root = shift ;

  return sub {

    my ( $dfv , $value ) = @_ ;

    return 1 if $value =~ /<p><img src="(.+)" \/><\/p>/ ;

    return 0 ;

  }

}

sub event_image_valid {

=head2 event_image_valid

This constraint is called in two circumstances:
1.  When a save is executed and we're validating the contents of a tinymce
    editor instance;
2.  When we're attempting to copy an image from an external URL after that URL
    has been entered in to the tincymce image dialog box.

=cut

  my $root = shift ;

  return sub {

    my ( $dfv , $value ) = @_ ;

    my $rc = 0 ;

    my $url ;

    if (
      $value =~ /^
        <p>
          <img\s
            src="(.+?)"\s
            (?:width="\d+"\sheight="\d+"\s)?
          \/>
        <\/p>
      $/x
    ) {

      # We're validating the image identified in a tinymce editor instance
      $url = $1 ;

    } else {

      # We're validating the image identified via the tinymce image dialog
      $url = $value ;

    }

    $url = $root . $url if $url =~ /^\/upload\/img\// ;

    my $ua = new LWP::UserAgent ;

    my $response = $ua -> get ( $url ) ;

    if ( $response -> is_success ) {

      my $magic = new File::LibMagic ;
      my $mime_type = $magic ->
        info_from_string ( $response -> content ) -> { mime_type } ;

      $rc = 1 if
        $mime_type eq 'image/gif'    ||
        $mime_type eq 'image/jpeg'    ||
        $mime_type eq 'image/png'    ;

    }

    return $rc ;

  }

}

sub unsubscribe_valid {

  my $dbh = shift ;

  return sub {

    my ( $dfv , $email ) = @_ ;

    my $contact = new DATA::WhatsOn::Contact ;
    $contact -> email ( $email ) ;

    my $data = $dfv -> get_filtered_data ;

    if ( $contact -> fetch ( $dbh )                            &&
         $data -> { contact_secret } eq $contact -> secret
    ) {

      return 1 ;

    }

    return 0 ;

  }

}

sub user_is_authorised {

=head2 user_is_authorised

This constraint tests that the user is authorised to undertake an action on a
WhatsOn Event or Society. It enforces the following:
1. An admin can add or update any event or a society;
2. A rep can add or update events for the society or societies that they
   represent;
3. A rep can update a society or societies that they represent but they can not
   add a society.

=cut

  my $dbh = shift ;

  return sub {

    my $dfv = shift ;

    my $rc = 0 ;

    my $data = $dfv -> get_filtered_data ;

    if ( $data -> { user_role } eq 'admin' ) {

      $rc = 1 ; # Admins can do anything

    } elsif ( $data -> { user_role } eq 'rep' ) {

      my $user_userid = $dfv -> get_current_constraint_value ;

      my $user = new DATA::Auth::User ;
      $user -> userid ( $user_userid ) ;
      $user -> fetch ( $dbh ) ;

      my $contact = new DATA::WhatsOn::Contact ;
      $contact -> email ( $user -> email ) ;
      $contact -> fetch ( $dbh ) ;

      my $society_rowid = $data -> { society_rowid } ;

      foreach my $organisation ( @{ $contact -> organisations } ) {

        $rc = 1
          if $organisation -> organisation_rowid == $society_rowid ;

      }


    }

    return $rc ;

  }

}

sub user_is_rep_for_event {

=head2 user_is_rep_for_event

Given a userid and the rowid for an event this constraint verifies that the user
is a representative for the event, which is the same as saying that the user is
a representative for the society that is presenting the event.

=cut

  my $dbh = shift ;

  return sub {

    my $dfv = shift ;

    # This constraint is on userid so get the value of userid
    my $user_userid = $dfv -> get_current_constraint_value ;

    my $user = new DATA::Auth::User ;
    $user -> userid ( $user_userid ) ;
    $user -> fetch ( $dbh ) ;

    my $contact = new DATA::WhatsOn::Contact ;
    $contact -> email ( $user -> email ) ;
    $contact -> fetch ( $dbh ) ;

    my $data = $dfv -> get_filtered_data ;
    my $event_rowid = $data -> { event_rowid } ;

    my $event = new DATA::WhatsOn::Event ;
    $event -> rowid ( $event_rowid ) ;
    $event -> fetch ( $dbh ) ;

    my $user_is_rep_for_event = 0 ;
    foreach my $organisation ( @{ $contact -> organisations } ) {

      $user_is_rep_for_event = 1
        if $organisation -> organisation_rowid == $event -> society_rowid ;

    }

    return $user_is_rep_for_event ;

  }

}

sub venue_exists {

=head2 venue_exists

Tests if an organisation exists.

=cut

  my $dbh = shift ;

  return sub {

    my ( $dfv , $value ) = @_ ;

    my $venue = new DATA::WhatsOn::Organisation ;
    $venue -> name ( $value ) ;
    $venue -> type ( 'whatson_venue' ) ;
    return $venue -> fetch ( $dbh ) ;

  }

}

1 ;

__END__