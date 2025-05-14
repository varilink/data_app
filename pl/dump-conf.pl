=head1 L<dump-conf.pl|https://github.com/varilink/data_app/blob/main/pl/dump-conf.pl>

Script for testing configurations for the DATA web application, which replicates
the approach taken by the
L<DATA::Plugin::Config|https://github.com/varilink/data_app/tree/main/pod2markdown/pm/Plugin/Config>
module.

This script can be called with our without a argument. If it is called without
an argument, it will dump the raw (without context) configuration. If it is
called with an argument, that argument must be a URL path within the DATA
website. The script will then dump the configuration in the context of that
path according to the applied
L<Config::Context|https://metacpan.org/pod/Config::Context>
matching rules. 

=cut

use strict;
use warnings;

use Config::Context;
use Config::General;
use Data::Dumper;

my %env_vars = (
    DATA_APP_LOG_LEVEL => $ENV{DATA_APP_LOG_LEVEL} // 'emergency',
);

my $general = new Config::General (
    -ConfigFile => "$ENV{'DATA_APP_CONF_DIR'}/$ENV{'DATA_APP_CONF_FILE'}",
    -DefaultConfig => \%env_vars,
    -IncludeDirectories => 'yes',
    -InterPolateVars => 'yes',
    -IncludeRelative => 'yes',
    -UseApacheInclude => 'yes'
);

my %config = $general->getall;

my $context = Config::Context->new(
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

if (defined $ARGV[0]) {
    print Dumper $context->context($ARGV[0])
} else {
    print Dumper $context->raw;
}
