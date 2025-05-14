package DATA::Plugin::Email;

=head1 DATA::Plugin::Email

Plugin for enabling the sending of emails by the DATA web application. It
defines a sendmail method that can be accessed via the CGI:Application object.

=cut

use strict;
use warnings;

use base qw/Exporter/;

use Email::MIME;

our @EXPORT = qw/sendmail/;

sub sendmail {

    my (
        $self,    # CGI::Application object
        $to,      # recipient
        $subject, # subject line
        $params   # parameters to be passed to the email template
    ) = @_;

    my $original = undef;
    if (
        $self->conf->param('all_emails_to_webmin')
        && $to ne $self->conf->param('webmin')
    ) {

        # We're in a testing mode in which all emails that aren't for the webmin
        # are redirected to the webmin and the recipient for this email is NOT
        # the webmin, so redirect.

        $original = $to;
        $to = $self->conf->param('webmin');

    }

    # Get the template for emails produced by the current runmode.
    my $tmpl = $self->template->load (
        $self->get_current_runmode . '_email'
    );

    # Populate the template with any parameters supplied.
    foreach my $name ( keys %{ $params } ) {
        my $value = $params->{ $name };
        $tmpl->param( $name => $value );
    }

    # If the recipient email address has been overridden with the webmin email
    # address then pass the original email address to the template. Templates
    # can use this to include an explanation that the recipient email address
    # has been overridden for visibility during testing.
    $tmpl->param( 'original' => $original ) if $original;

    # We create both HTML and text emails to cater for recipients who are not
    # accepting emails in HTML format.
    my $html_part = $tmpl->output ( part => 'html' );
    my $text_part = $tmpl->output ( part => 'text' );
    my @parts = (
        Email::MIME->create(
            attributes => {
                content_type => 'text/plain',
                charset => 'utf-8',
                encoding => 'quoted-printable',
            },
            body => $text_part,
        ),
        Email::MIME->create(
            attributes => {
                content_type => 'text/html',
                charset => 'utf-8',
                encoding => 'quoted-printable',
            },
            body => $html_part,
        ),
    );

    # Create the email
    my $email = Email::MIME->create(
        header_str => [
            From => 'admin@derbyartsandtheatre.org.uk',
            To => $to,
            Subject => $subject,
            'Content-Type' => 'multipart/alternative',
        ],
        parts => [ @parts ],
    );

    # Send the email
    open(
        SENDMAIL, '|/usr/sbin/sendmail -t -f admin@derbyartsandtheatre.org.uk'
    ) or die 'Cannot open sendmail';
    print SENDMAIL $email->as_string;
    close SENDMAIL;

}

sub import {

    goto &Exporter::import;

}

1 ;

__END__
