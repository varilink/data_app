#!/usr/bin/perl

=head1 derbyartsandtheatre.org.uk-sitemap

This script generates a sitemap for the derbyartsandtheatre.org.uk website.

=cut

use strict ;
use warnings ;

use Config::General ;
use Config::Simple ;
use Data::Dumper ;
use DateTime ;
use DBI ;
use SiteFunk::WhatsOn::Event ;
use SiteFunk::WhatsOn::NewsItem ;
use SiteFunk::WhatsOn::Organisation ;
use XML::Output ;

my $today = DateTime -> today ;

#-------------------------------------------------------------------------------

#
# Load up configuration
#

my $ini = new Config::Simple (
  '/usr/local/etc/sitefunk/derbyartsandtheatre.org.uk.ini'
) ;

my $home = $ini -> param ( 'home' ) ;

my $cObj = new Config::General ( "$home/env.cfg" ) ;
my %cHash = $cObj -> getall ;
my $env = $cHash { env } ;

my $database  = $env -> { database } ;
my $root      = $env -> { root } ;
my $dbh = DBI -> connect (	"dbi:SQLite:dbname=$database" , '' , '' ) ;

#-------------------------------------------------------------------------------

#
# Get the pages which need to go in to the sitemap
#

opendir my $dir , "$home/src/pages" or die "Cannot open directory: $!" ;
my @tmpls = readdir $dir ;
closedir $dir ;

foreach my $exclusion (
    '.'               , # Current folder
    '..'              , # Parent folder
    'account'         , # Account folder
    'error.tt'        , # The server error page
    'not_found.tt'    , # Page not found page
    'secure'          , # Secure folder
    'unauthorised.tt' , # Unauthorised access page
) {

  my $index = 0 ;
  $index++ until ( $index == scalar @tmpls || $tmpls[$index] eq $exclusion ) ;
  splice ( @tmpls , $index , 1 ) if $index < scalar @tmpls ;

}

#-------------------------------------------------------------------------------

#
#
#

open ( my $oFH , '>' , "$home/htdocs/sitemap.xml" )
  or die "Can't open > sitemap.xml: $!" ;
print $oFH '<?xml version="1.0" encoding="UTF-8"?>' , "\n" ;
my $xo = new XML::Output ( { 'fh' => $oFH } ) ;
$xo -> open ( 'urlset' , {
  'xmlns'
    => 'http://www.sitemaps.org/schemas/sitemap/0.9'              ,
} ) ;

foreach my $tmpl ( @tmpls ) {

  $tmpl =~ /^(\w+)\.tt$/ ;
  my $reloc = $1 ;
  $reloc = '' if $reloc eq 'index' ;

  if ( $reloc eq 'event' ) {

    my @events = SiteFunk::WhatsOn::Event -> fetch (
      $dbh , { from => 'now' , status => 'PUBLISHED' }
    ) ;

    foreach my $event ( @events ) {

      $xo -> open ( 'url' ) ;

#-------------------------------------------------------------------------------
# Write location

      $xo -> open ( 'loc' ) ;
      $xo -> pcdata ( $root . $reloc . '/' . $event -> rowid ) ;
      $xo -> close ;

#-------------------------------------------------------------------------------
# Write lastmod

      $xo -> open ( 'lastmod' ) ;
      $xo -> pcdata (
        sprintf '%04d-%02d-%02d' ,
        $today -> year , $today -> month , $today -> day
      ) ;
      $xo -> close ;

#-------------------------------------------------------------------------------
# Write changefreq

      $xo -> open ( 'changefreq' ) ;
      $xo -> pcdata ( 'daily' ) ;
      $xo -> close ;

#-------------------------------------------------------------------------------
# Write the priority

      $xo -> open ( 'priority' ) ;
      $xo -> pcdata ( '1.0' ) ;
      $xo -> close ;

      $xo -> close ;

    }

  } elsif ( $reloc eq 'news_item' ) {

    my @news_items = SiteFunk::WhatsOn::NewsItem -> fetch ( $dbh ) ;

    foreach my $news_item ( @news_items ) {

      $xo -> open ( 'url' ) ;

#-------------------------------------------------------------------------------
# Write location

      $xo -> open ( 'loc' ) ;
      $xo -> pcdata ( $root . $reloc . '/' . $news_item -> rowid ) ;
      $xo -> close ;

#-------------------------------------------------------------------------------
# Write lastmod

      $xo -> open ( 'lastmod' ) ;
      $xo -> pcdata (
        sprintf '%04d-%02d-%02d' ,
        $today -> year , $today -> month , $today -> day
      ) ;
      $xo -> close ;

#-------------------------------------------------------------------------------
# Write changefreq

      $xo -> open ( 'changefreq' ) ;
      $xo -> pcdata ( 'weekly' ) ;
      $xo -> close ;

#-------------------------------------------------------------------------------
# Write the priority

      $xo -> open ( 'priority' ) ;
      $xo -> pcdata ( '0.8' ) ;
      $xo -> close ;

      $xo -> close ;

    }

  } elsif ( $reloc eq 'society' ) {

    my @societies = SiteFunk::WhatsOn::Organisation -> fetch (
      $dbh , { type => 'whatson_society' , status => 'ACTIVE' }
    ) ;

    foreach my $society ( @societies ) {

      $xo -> open ( 'url' ) ;

#-------------------------------------------------------------------------------
# Write location

      $xo -> open ( 'loc' ) ;
      $xo -> pcdata ( $root . $reloc . '/' . $society -> rowid ) ;
      $xo -> close ;

#-------------------------------------------------------------------------------
# Write lastmod

      $xo -> open ( 'lastmod' ) ;
      $xo -> pcdata (
        sprintf '%04d-%02d-%02d' ,
        $today -> year , $today -> month , $today -> day
      ) ;
      $xo -> close ;

#-------------------------------------------------------------------------------
# Write changefreq

      $xo -> open ( 'changefreq' ) ;
      $xo -> pcdata ( 'daily' ) ;
      $xo -> close ;

#-------------------------------------------------------------------------------
# Write the priority

      $xo -> open ( 'priority' ) ;
      $xo -> pcdata ( '0.8' ) ;
      $xo -> close ;

      $xo -> close ;

    }

  } else {

    $xo -> open ( 'url' ) ;

#-------------------------------------------------------------------------------
# Write location

    $xo -> open ( 'loc' ) ;
    $xo -> pcdata ( $root . $reloc ) ;
    $xo -> close ;

#-------------------------------------------------------------------------------
# Write lastmod

    $xo -> open ( 'lastmod' ) ;
    if ( $reloc eq '' || $reloc eq 'events' ) {
      # For pages with dynamic content set the lastmod date to today, since if
      # there has been a database change the page content will have changed or
      # if time has advanced the page content may also have changed; for example
      # because the coming events list has moved on.
      $xo -> pcdata (
        sprintf '%04d-%02d-%02d' ,
        $today -> year , $today -> month , $today -> day
      ) ;
    } else {
      # For pages without dynamic content look at the last modified date of the
      # template file and use that for lastmod.
      my (
       $dev , $ino , $mode , $nlink , $uid , $gid , $rdev , $size , $atime ,
       $mtime , $ctime , $blksize , $blocks
      ) = stat "$home/src/pages/$tmpl" ;
      my $lastmod = DateTime -> from_epoch ( epoch => $mtime ) ;
      $xo -> pcdata (
        sprintf "%04d-%02d-%02d" ,
        $lastmod -> year , $lastmod -> month , $lastmod -> day
      ) ;
    }
    $xo -> close ;

#-------------------------------------------------------------------------------
# Write changefreq

    $xo -> open ( 'changefreq' ) ;
    if ( $reloc eq '' || $reloc eq 'events' ) {
      $xo -> pcdata ( 'daily' ) ;
    } elsif ( $reloc eq 'news' ) {
      $xo -> pcdata ( 'weekly' ) ;
    } else {
      $xo -> pcdata ( 'monthly' ) ;
    }
    $xo -> close ;

#-------------------------------------------------------------------------------
# Write the priority

    $xo -> open ( 'priority' ) ;
    if ( $reloc eq '' || $reloc eq 'events' ) {
      $xo -> pcdata ( '1.0' ) ;
    } elsif (
      $reloc eq 'societies' || $reloc eq 'news' || $reloc eq 'diary_scheme'
    ) {
      $xo -> pcdata ( '0.8' ) ;
    } elsif ( $reloc eq 'privacy' || $reloc eq 'join_us' ) {
      $xo -> pcdata ( '0.2' ) ;
    } else {
      $xo -> pcdata ( '0.5' ) ;
    }
    $xo -> close ;

    $xo -> close ;

  }

}

$xo -> close ;
close $oFH ;

1 ;

__END__