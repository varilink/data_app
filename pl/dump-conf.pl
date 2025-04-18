use strict;
use warnings;

use Config::General;
use Data::Dumper;

my $conf = new Config::General (
  -ConfigFile => "$ENV{'DATA_APP_CONF_DIR'}/$ENV{'DATA_APP_CONF_FILE'}",
  -IncludeRelative => 'yes',
  -UseApacheInclude => 'yes'
);

my %conf = $conf->getall;

print Dumper %conf
