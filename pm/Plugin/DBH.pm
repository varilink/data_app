package DATA::Plugin::DBH ;

=head1 DATA::Plugin::Config

Plugin DATA application integration with DBH.

=cut

use strict ;
use warnings ;

use base qw / Exporter / ;

sub _init {

  my $self = shift ;

  my $database =  $self->conf->param('database');

   $self -> dbh_config (

      'dbi:SQLite:dbname=' . $database ,
      '' ,
      '' ,

   ) ;

  # I dont fully understand why but do NOT enable the sqlite_unicode flag here
  # $self -> dbh -> { sqlite_unicode } = 1 ;

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
