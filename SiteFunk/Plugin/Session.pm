package SiteFunk::Plugin::Session ;

use strict ;

use base qw / Exporter / ;

sub _postrun {

   my $c = shift ;

   # Flush session to storage before exiting
   $c -> session -> flush if $c -> session_loaded ;

}

sub import {

   my $caller = scalar caller ;

   $caller -> add_callback (

      'postrun' , \&_postrun

   ) ;

   goto &Exporter::import ;

}

1 ;

__END__
