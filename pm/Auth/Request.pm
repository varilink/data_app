package DATA::Auth::Request;

=head1 DATA::Auth::Request

CGI application modules that handles requests for secure resources. It tests
whether the request comes from an authenticated user. If access to the
resource is restricted to specific roles, whether that user is authorised, i.e.
is allocated to a role that gives them access.

=cut

use strict;
use warnings;

# We do not base this module on DATA::Main since it doesn't require the
# template and database capability that DATA::Main imparts.
use base qw/CGI::Application/;

# Use CGI::Application plugins
use CGI::Application::Plugin::Config::Context;
use CGI::Application::Plugin::LogDispatch;
use CGI::Application::Plugin::Session;

# Use DATA customisation of CGI::Application::Plugin::Config::Context
use DATA::Plugin::Config;

# Use other DATA customisations of CGI:Application plugins
use DATA::Plugin::LogDispatch;
use DATA::Plugin::Session;

sub cgiapp_init {

my $self = shift;

    $self->run_modes([
        'request',
    ]);

}

=head2 run modes

=cut

sub request {

=head3 request

This run mode tests if the user is permitted to access a secure resource.

=cut

    my $self = shift;

    $self->log->notice(
        'Entered request run mode of the Auth::Request application'
    );

    my $query = $self->query;

    if ( $self->session->param('userid') ) {

        # Already authenticated, check if authorised

        # Get the target
        my $target = $query->env->{'HTTP_X_ORIGINAL_URI'};
        $target =~ s/\/+/\//g ; # Replace one or more / with a single /

        my $config = $self->conf->context($target);

        if ( $config->{'role'} ) {

            # This area of the site requires that the user has a specific role.
            # Check that they do.
            $self->session->param('role') eq $config->{'role'}
                ? $self->header_props( -status => '200' )
                : $self->header_props( -status => '403' );

        } else {

            # This area of the site is secure but does not require that the user
            # has a specific role. It is sufficient just that they are
            # authenticated.
            $self->header_props( -status => '200');

        }

    } else {

        # Not authenticated, prompt for login
        $self->header_props( -status => '401' );

    }

    return;

}

1 ;

__END__
