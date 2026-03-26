package DATA::WhatsOn::Constraints;

=head1 DATA::WhatsOn::Constraints

This package provides a library of constraint functions for the DATA::WhastOn
application. The constraints are implemented via the Data::FormValidator
package.

=cut

use strict;
use warnings;

use base qw/Exporter/;

use DATA::Auth::User;
use DATA::WhatsOn::Contact;
use DATA::WhatsOn::Event;
use DATA::WhatsOn::Organisation;

use File::LibMagic;
use LWP::UserAgent;
use URI;

our @EXPORT = qw/
    event_description_valid
    event_image_provided
    event_image_valid
    user_is_authorised
    user_is_rep_for_event
    venue_exists
/;

sub event_description_valid {

=head2 event_description_valid

Tests if the event description has non HTML content in it, i.e. it does contain
descriptive text and not just markup tags. If it just contained markup tags then
that would equate to no description being provided.

=cut

    return sub {
        my ($dfv, $value) = @_;
        $value =~ s/<.+?>//g; # Strip the HTML from the value
        return $value; # If there's content left this will be true
    }

}

sub event_image_provided {

=head2 event_image_provided

Tests that am image has been provided for an event where one has been promised,
as it were, by indicating that an online promotion listing WITH IMAGE is
required.

=cut

    my ( $root, $upload_path, $click_me_param ) = @_;

    return sub {

        sub extract_img_src {
            my ($html) = @_;
            $html =~ m{<img[^>]+src="([^"]+)"}i
                or return undef;
            return $1;
        }

        sub normalise_src {
            my ($src, $root, $upload_path) = @_;
            my $base = $root . '/' . $upload_path;
            my $uri = URI->new_abs($src, $base);
            return $uri->path;
        }

        my ($dfv, $value) = @_;
        my $data = $dfv->get_filtered_data;
        if ( $data->{ event_use_desc } == 1 ) {
            my $submitted_src = extract_img_src($data->{ mceEventImage });
            my $initial_src = extract_img_src($click_me_param);
            $submitted_src = normalise_src(
                $submitted_src, $root, $upload_path
            );
            $initial_src = normalise_src(
                $initial_src, $root, $upload_path
            );
            return 0 if $submitted_src eq $initial_src;
        }
        return 1;

    }

}

sub event_image_valid {

=head2 event_image_valid

Tests that an image provided for the online promotion representation of an event
is valid. Images are validated for MIME type and size.

=cut

    my $root = shift;

    return sub {
        my ($dfv, $value) = @_;
        return 1;
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

    my $dbh = shift;

    return sub {

        my $dfv = shift;
        my $rc = 0;
        my $data = $dfv->get_filtered_data;

        if ( $data->{ user_role } eq 'admin' ) {
            $rc = 1; # Admins can do anything
        } elsif ( $data->{ user_role } eq 'rep' ) {

            my $user_userid = $dfv->get_current_constraint_value;
            my $user = new DATA::Auth::User;
            $user->userid($user_userid);
            $user->fetch($dbh);

            my $contact = new DATA::WhatsOn::Contact;
            $contact->email($user->email);
            $contact->fetch($dbh);

            my $society_rowid = $data->{society_rowid};

            foreach my $organisation ( @{ $contact->organisations } ) {
                $rc = 1
                if $organisation->organisation_rowid == $society_rowid;
            }

        }

        return $rc;

    }

}

sub user_is_rep_for_event {

=head2 user_is_rep_for_event

Given a userid and the rowid for an event this constraint verifies that the user
is a representative for the event, which is the same as saying that the user is
a representative for the society that is presenting the event.

=cut

    my $dbh = shift;

    return sub {

        my $dfv = shift;

        # This constraint is on userid so get the value of userid
        my $user_userid = $dfv->get_current_constraint_value;
        my $user = new DATA::Auth::User;
        $user->userid($user_userid);
        $user->fetch($dbh);
        my $contact = new DATA::WhatsOn::Contact;
        $contact->email($user->email);
        $contact->fetch($dbh);
        my $data = $dfv->get_filtered_data;
        my $event_rowid = $data->{ event_rowid };
        my $event = new DATA::WhatsOn::Event;
        $event->rowid($event_rowid);
        $event->fetch($dbh);

        my $user_is_rep_for_event = 0;
        foreach my $organisation ( @{ $contact->organisations } ) {
            $user_is_rep_for_event = 1
                if $organisation->organisation_rowid == $event->society_rowid;
        }
        return $user_is_rep_for_event;

    }

}

sub venue_exists {

=head2 venue_exists

Tests if an organisation exists in database and is of the venue organisation
type.

=cut

    my $dbh = shift;

    return sub {
        my ($dfv, $value) = @_;
        my $venue = new DATA::WhatsOn::Organisation;
        $venue->name($value);
        $venue->type('whatson_venue');
        return $venue->fetch($dbh);
    }

}

1;

__END__
