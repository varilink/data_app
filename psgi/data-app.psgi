#!/usr/bin/perl

use strict ;
use warnings ;

use lib qw ( /usr/local/lib/perl_overrides ) ;

use CGI::Application::Dispatch::PSGI ;
use Config::Simple ;
use Config::Context ;
use YAML qw / LoadFile / ;

sub {

  my $env = shift ;

  # Get the site name, which will always be the last but one level of the
  # document root
  my @labels = split ( '/' , $env -> { DOCUMENT_ROOT } ) ;
  my $name = $labels [ -2 ] ;

  # Find the home for the site's configuratoin from the site's ini file
  my $ini = new Config::Simple ( "/usr/local/etc/sitefunk/$name.ini" ) ;
  my $home = $ini -> param ( 'home' ) ;

  my $conf = Config::Context -> new (

    file => "$home/conf/sitefunk.cfg" ,

    driver => 'ConfigGeneral' ,

    match_sections => [

      {
        name => 'Location' ,
        match_type => 'path' ,
      } ,
      {
        name => 'LocationMatch' ,
        match_type => 'regex' ,
      } ,

    ] ,

    driver_options => {

      ConfigGeneral => {
        -AllowMultiOptions => 'yes' ,
        -IncludeDirectories => 'yes' ,
        -MergeDuplicateOptions => 'no' ,
        -UseApacheInclude => 'yes' ,
      } ,

    } ,

  ) ;

  my $rules = LoadFile "/home/david/vhosts/$name/conf/table.yml" ;

  my $table = [ ] ;

  foreach my $rule ( @{ $rules } ) {

    my @keys = keys %{ $rule } ;

    my $path = $keys[0] ;
    my $app = $conf -> context ( $path ) -> { app } ;

    my $rm = $rule -> { $path } ;

    push @{ $table } , $path => { app => $app , rm => $rm } ;

  }

  # Dispatch the request
  my $app = CGI::Application::Dispatch::PSGI -> as_psgi (

    prefix => 'SiteFunk' ,

    args_to_new => {

      PARAMS => {
        home => $home
      } ,

    } ,

    table => $table ,

  ) ;

  return $app -> ( $env ) ;

}