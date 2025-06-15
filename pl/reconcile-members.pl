=head1 reconcile-members.pl

This script compares a file containing people considered to be individual
members of DATA to the DATA Mailchimp subscriber list. We have adopted a
principle that if a person subscribes to the DATA Mailchimp subscriber list and
registers an interest in "Latest DATA Membership News", then they are de-facto
an individual member of DATA. At times in the past we have either required an
individual member fee or that members register without a fee but without using
the Mailchimp subscriber list to capture their registration.

These now outdated records of individual members should be supplied to this
script in a CSV file containing the following fields:

=over
=item last name
=item first name
=item email address
=back

=cut

use strict;
use warnings;

use Config::General;
use DATA::WhatsOn::Contact;
use DATA::WhatsOn::Organisation;
use DBI;
use Digest::MD5 qw(md5_hex);
use List::Util qw(any);
use Mail::Chimp3;
use Text::CSV;

# -----------------
# Get configuration
# -----------------

my $cg = new Config::General(
    -ConfigFile => "$ENV{'DATA_APP_CONF_DIR'}/$ENV{'DATA_APP_CONF_FILE'}",
    -IncludeRelative => 'yes',
    -UseApacheInclude => 'yes'
);
my %conf = $cg->getall;

# ------------------------------
# Get Mailchimp audience via API
# ------------------------------

my $mc = new Mail::Chimp3(api_key => $conf{mailchimp}{api_key});
my $count = 100;
my $more_to_find = 1;
my $offset = 0;
my @audience = ();
while ($more_to_find) {
    my $r = $mc->members(
        list_id => $conf{mailchimp}{list_id},
        fields => 'members.email_address,members.full_name,members.status'
            . ',members.interests',
        count => $count,
        offset => $offset
    );
    push @audience, @{$r->{content}->{members}};
    if (@{$r->{content}->{members}} < $count) { $more_to_find = 0 }
    else { $offset += $count }
}

# ----------------------------------------------
# Compare members CSV file to Mailchimp audience
# ----------------------------------------------

my $csv = Text::CSV->new({ eol => "\n" });
my @first_names = ();
my @last_names = ();
open my $members_in, '<', "$conf{inputs}/members.csv"
  or die "Could not open file '$conf{inputs}/members.csv': $!";
open my $members_out, '>',  "$conf{outputs}/members.csv"
  or die "Could not open file '$conf{outputs}/members.csv': $!";
$csv->print($members_out, [
    'Last name', 'First name', 'Email address', 'Found', 'Status',
    'Member interest', 'Notes'
]);
while (my $row = $csv->getline($members_in)) {
    my ($last_name, $first_name, $email_address) = @$row;
    my @matches =
        grep { lc($_->{email_address}) eq lc($email_address) } @audience;
    my ($found, $status, $member, $member_interest, $notes)
        = (0, '', undef, 'N/A', 'scenario not catered for');
    if (@matches) {
        $found = 1;
        $member = $matches[0];
    }
    else { $found = 0 }
    if ($found) {
        $status = $member->{status};
        if (
            $status eq 'subscribed' &&
            $member->{interests}{$conf{mailchimp}{member_interest_id}}
        ) {
            $member_interest = 'yes';
            $notes = 'okay';
        }
        elsif (
            $status eq 'subscribed' &&
            !$member->{interests}{$conf{mailchimp}{member_interest_id}}
        ) {
            $member_interest = 'no';
            $notes = 'register member interest';
        }
        elsif ( $status eq 'unsubscribed' ) {
            $notes = 'can NOT be fixed';
        }
    }
    else {
        $status = 'N/A';
        $member_interest = 'N/A';
        $notes = 'subscribe'
    }
    if (!$found || $status eq 'unsubscribed') {
        push @first_names, $first_name;
        push @last_names, $last_name;
    }
    $csv->print($members_out, [
        $last_name, $first_name, $email_address, $found ? 'yes' : 'no', $status,
        $member_interest, $notes
    ]);
}

# ------------------------------------------------------
# Look for members matched on name but not email address
# ------------------------------------------------------

my @name_matches = grep {
    my $full_name = $_->{full_name};
    my $is_first = any { $full_name =~ /^\Q$_\E\b/i } @first_names;
    my $is_last = any { $full_name =~ /\b\Q$_\E$/i } @last_names;
    $is_first || $is_last;
} @audience;

open my $others, '>',  "$conf{outputs}/others.csv"
  or die "Could not open file '$conf{outputs}/others.csv': $!";
$csv->print($others, [
    'Full name', 'Email address', 'Status', 'Member interest'
]);
foreach my $member (
    sort { lc($a->{full_name}) cmp lc($b->{full_name}) } @name_matches
) {
    my $member_interest;
    if ($member->{status} eq 'subscribed') {
        $member_interest =
            $member->{interests}{$conf{mailchimp}{member_interest_id}}
                ? 'yes'
                : 'no';
    }
    else { $member_interest = 'N/A' }
    $csv->print($others, [
        $member->{full_name}, $member->{email_address}, $member->{status},
        $member_interest
    ]);
}

1;

close $members_in;
close $members_out;
close $others;

1;

__END__
