package DATA::Plugin::Config ;

=head1 DATA::Plugin::Config

Plugin to load the application configuration in to any DATA application.

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
