=head1 L<data-app.psgi|https://github.com/varilink/data_app/blob/main/psgi/data-app.psgi>

PSGI script for the DATA web application. This uses
-L<CGI::Application::Dispatch::PSGI|https://metacpan.org/pod/CGI::Application::Dispatch::PSGI>
to dispatch requests. It builds the dispatch table by combining the contents of
C<conf/context.cfg> and C<conf/dispatch.yml> from the
-L<DATA - App|https://github.com/varilink/data_app> repository. To do this it
requires that the C<conf/> directory be present at the location
C<$ENV{'DATA_APP_CONF_DIR'}/app/> in the environment in which it is run.

C<conf/context.cfg> contains the mapping between locations within the DATA web
application and the -L<CGI::Application|https://metacpan.org/pod/CGI::Application>
modules that combine for the DATA web application. C<conf/dispatch.yml> contains
the mapping between those locations and their run mode names.

=cut

use strict;
use warnings;

use CGI::Application::Dispatch::PSGI;
use Config::Context;
use Config::General;
use Data::Dumper;
use Log::Dispatch;
use YAML qw/LoadFile/;

sub {

    my $env = shift;

    my %env_vars = (
        DATA_APP_LOG_LEVEL => $ENV{DATA_APP_LOG_LEVEL} // 'emergency',
    );

    my $general = Config::General->new(
        -ConfigFile => "$ENV{'DATA_APP_CONF_DIR'}/$ENV{'DATA_APP_CONF_FILE'}",
        -DefaultConfig => \%env_vars,
        -IncludeDirectories => 'yes',
        -IncludeRelative => 'yes',
        -InterPolateVars => 'yes',
        -UseApacheInclude => 'yes'
    );

    my %config = $general->getall;

    my $conf = Config::Context->new(
        config => \%config,
        driver => 'ConfigGeneral',
        match_sections => [
            {
                name => 'Location',
                match_type => 'path',
            },
            {
                name => 'LocationMatch',
                match_type => 'regex',
            },
        ],
    );

    my $log = Log::Dispatch->new(
        outputs => [
            [
                'File',
                filename => '/tmp/data_app.log',
                min_level =>
                    $conf->context($env->{REQUEST_URI})->{file_log_level},
                mode => 'append',
                newline => 1
            ]
        ],
        callbacks => sub { my %h = @_; return time().': '.$h{message}; },
    );

    $log->debug(Dumper($env));
    $log->notice(
        'Entered the PSGI script with request URI: ' . $env->{REQUEST_URI}
    );

    # rule = key pair in which the key is the path and the value is the run mode
    my $rules = LoadFile "$ENV{'DATA_APP_CONF_DIR'}/app/dispatch.yml";
    my $table = [];

    foreach my $rule ( @{$rules} ) {

        # Get the patch from the rule
        my @keys = keys %{$rule} ;
        my $path = $keys[0];
        # Get the app for that path
        my $app = $conf->context($path)->{app};
        # Get the run mode
        my $rm = $rule->{$path};
        push @{$table}, $path => { app => $app, rm => $rm };

    }

    # Dispatch the request using the dispatch table that we just built
    my $app = CGI::Application::Dispatch::PSGI->as_psgi(
        prefix => 'DATA',
        table => $table ,
    );

    return $app->($env);

}
