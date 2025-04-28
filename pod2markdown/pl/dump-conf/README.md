# [dump-conf.pl](https://github.com/varilink/data_app/blob/main/pl/dump-conf.pl)

Script for testing configurations for the DATA web application, which replicates
the approach taken by the
[DATA::Plugin::Config](https://github.com/varilink/data_app/tree/main/pod2markdown/pm/Plugin/Config)
module.

This script can be called with our without a argument. If it is called without
an argument, it will dump the raw (without context) configuration. If it is
called with an argument, that argument must be a URL path within the DATA
website. The script will then dump the configuration in the context of that
path according to the applied
[Config::Context](https://metacpan.org/pod/Config::Context)
matching rules. 
