package DATA::Plugin::DBH;

=head1 DATA::Plugin::Config

Plugin DATA application integration with DBH, which is used to access a SQLite
database.

=cut

use strict;
use warnings;

use base qw/Exporter/;

sub _init {

   my $self = shift;
   my $database =  $self->conf->param('database');
   $self->dbh_config(
      'dbi:SQLite:dbname=' . $database,
      '',
      '',
   );

}

sub import {

   my $caller = scalar caller;

   $caller->add_callback(
      'init', \&_init
   );

   goto &Exporter::import;

}

1;

__END__
