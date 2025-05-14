package DATA::Plugin::Config ;

=head1 L<DATA::Plugin::Config|https://github.com/varilink/data_app/pm/Plugin/Config.pm>

Plugin to load the application configuration in to any
L<CGI::Application|https://metacpan.org/pod/CGI::Application>
module within the DATA web application. The DATA web application uses 
L<Config::Context|https://metacpan.org/pod/Config::Context>
for its configuration with the underlying driver for
L<Config::General|https://metacpan.org/pod/Config::General>.

This plugin supports the variable interpolation feature of C<Config::General>
for some specific configuration items. For those items a value can be passed to
the DATA web application via an environment variable. If a value isn't passed
then a default value applies instead. The table below gives the details of those
configuration variables for which this approach is supported.

 Env Var              Config Var       Default
 ------------------   --------------   ---------
 DATA_APP_LOG_LEVEL   file_log_level   emergency

=cut

use strict ;
use warnings ;

use base qw / Exporter / ;

sub _init {

  my $self = shift ;

  $self -> conf -> init (

    # Locate the configuration using the home parameter passed via the ini file
    file   => "$ENV{'DATA_APP_CONF_DIR'}/$ENV{'DATA_APP_CONF_FILE'}" ,

    driver => 'ConfigGeneral' ,

    driver_options => {

      ConfigGeneral => {
        -AllowMultiOptions => 'yes' ,
        -IncludeDirectories => 'yes' ,
        -MergeDuplicateOptions => 'no' ,
        -UseApacheInclude => 'yes'
      }

    } ,

  ) ;

}

sub import {

  my $caller = scalar caller ;

  $caller -> add_callback (

    'init' , \&_init

  ) ;

  goto &Exporter::import ;

}

1 ;

__END__
