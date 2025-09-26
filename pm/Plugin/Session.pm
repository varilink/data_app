package DATA::Plugin::Session ;

=head1 DATA::Plugin::Config

Plugin for DATA web app session management.

=cut

use strict ;
use warnings ;

use base qw / Exporter / ;

sub _init {

  my $self = shift ;

  $self -> session_config (
    CGI_SESSION_OPTIONS => [
      "driver:File" , $self->query , { Directory => '/cookies' }
    ] ,
    COOKIE_PARAMS => { -path  => '/', -samesite => 'Strict' } ,
    SEND_COOKIE => 1
  ) ;

}

sub _postrun {

   my $c = shift ;

   # Flush session to storage before exiting
   $c -> session -> flush if $c -> session_loaded ;

}

sub import {

   my $caller = scalar caller ;

   $caller -> add_callback (

    'init' , \&_init

   ) ;

   $caller -> add_callback (

      'postrun' , \&_postrun

   ) ;

   goto &Exporter::import ;

}

1 ;

__END__
