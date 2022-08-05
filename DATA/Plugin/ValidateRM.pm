package DATA::Plugin::ValidateRM ;

use strict ;

use base qw / Exporter / ;

sub _init {

   my $c = shift ;

   #
   # DFV

   $c -> param ( 'dfv_defaults' ) ||
      $c -> param ( 'dfv_defaults' , {
         missing_optional_valid => 1 ,
         filters => 'trim' ,
         msgs => {
            any_errors => 'error' ,
            prefix     => 'error_' ,
            invalid    => 'Invalid' ,
            missing    => 'Missing' ,
            format => '%s' ,
         } ,
      } )
   ;

}

sub import {

   my $caller = scalar caller ;

   $caller -> add_callback (

      'init' , \&_init

   ) ;

   goto &Exporter::import ;

}

1 ;

