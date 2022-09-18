use strict ;
use warnings ;

use Config::General ;
use Config::Simple ;
use DBI ;
use Encode qw / decode encode / ;
use HTML::HTMLDoc ;
use DATA::WhatsOn::Event ;
use Template ;

#-------------------------------------------------------------------------------

# Get Environment Settings

my $project = 'derbyartsandtheatre.org.uk' ;
my $ini = new Config::Simple ( "/usr/local/etc/DATA/$project.ini" ) ;
my $home = $ini -> param ( 'home' ) ;
my $confObj = new Config::General ( "$ENV{'DATA_CONF'}/app.cfg" ) ;
my %conf = $confObj -> getall ;
my $database = $conf { env } -> { database } ;

#-------------------------------------------------------------------------------

# Retrieve Data

my $dbh = DBI -> connect (  "dbi:SQLite:dbname=$database" , '' , '' ) ;

# Turn the UTF-8 flag on for all text strings coming out of the database
$dbh -> { sqlite_unicode } = 1 ;

my $filter = {
  from    => 'now'        ,
  status  => 'PUBLISHED'
} ;
my @events = DATA::WhatsOn::Event -> fetch ( $dbh , $filter ) ;

foreach my $event ( @events ) {

  $event -> dates ( $event -> dates_derived )
    unless $event -> dates ;

  $event -> times ( '7.30pm' )
    unless $event -> times ;

  $event -> presented_by ( $event -> society_name )
    unless $event -> presented_by ;

}

#-------------------------------------------------------------------------------

# Produce output

my $template = new Template ( {

  ENCODING => 'utf8' ,

  INCLUDE_PATH => [
    "$home/src/print"                   ,
    "$home/src/partials/event_formats"
  ]

} ) || die Template -> error ( ) , "\n" ;

my $vars = {
  events => \@events
} ;

# Produce on listing with page size A4 and one with page size A5
foreach my $pagesize ( 'A4' , 'A5') {

  my $limit ;

  # Keep increasing the number of events to find where we go to two pages
  for ( my $this_limit = 1 ; $this_limit <= scalar @events ;  $this_limit++ ) {

    # Generate the HTML
    my $html = '' ;
    $vars -> { limit } = $this_limit ;
    $vars -> { pagesize } = $pagesize ;
    $template -> process (
      'printed_listing.tt' ,
      $vars ,
      \$html
    ) || die $template -> error ( ) , "\n" ;

    # Set up the htmldoc object
    my $htmldoc = new HTML::HTMLDoc ;
    $htmldoc -> set_bodyfont ( 'Arial' ) ;
    $htmldoc -> set_charset ( 'iso-8859-1' ) ;
    $htmldoc -> set_footer ( '.' , '.' , '.' ) ;
    $htmldoc -> set_header ( '.' , 'l' , '1' ) ;
    $htmldoc -> set_html_content ( encode ( 'iso-8859-1' , $html ) ) ;
    $htmldoc -> set_logoimage ( $home . '/htdocs/assets/img/logo.jpg' ) ;
    # Set page up for A5 or A4. Note that A4 is the default page size.
    if ( $pagesize eq 'A5' ) {
      $htmldoc -> set_fontsize ( 10 ) ;
      $htmldoc -> set_page_size ( '148x210mm' ) if $pagesize eq 'A5' ;
      $htmldoc -> set_left_margin ( 10 , 'mm' ) ;
      $htmldoc -> set_right_margin ( 10 , 'mm' ) ;
      $htmldoc -> set_top_margin ( 14 , 'mm' ) ;
      $htmldoc -> set_bottom_margin ( 14 , 'mm' ) ;
    } else { # Page size = A4
      $htmldoc -> set_fontsize ( 11 ) ;
      $htmldoc -> set_left_margin ( 14 , 'mm' ) ;
      $htmldoc -> set_right_margin ( 14 , 'mm' ) ;
      $htmldoc -> set_top_margin ( 20 , 'mm' ) ;
      $htmldoc -> set_bottom_margin ( 20 , 'mm' ) ;
    }

    # Find when this_limit takes us beyond page one
    my $pdf = $htmldoc -> generate_pdf ;
    my $error =  $htmldoc -> error ;
    $error =~ /PAGES:\s(\d+)/s ;
    last if $1 >= 2 ;

    # We're still on page one, capture the limit
    $limit = $this_limit ;

  }

  # Regenerate the HTML with the limit we have determined fills one page
  my $html = '' ;
  $vars -> { limit } = $limit ;
  $vars -> { pagesize } = $pagesize ;
  $template -> process (
    'printed_listing.tt' ,
    $vars ,
    \$html
  ) || die $template -> error ( ) , "\n" ;

  # Regenerate the PDF with the page number in the footer this time
  my $htmldoc = new HTML::HTMLDoc ;
  $htmldoc -> set_bodyfont ( 'Arial' ) ;
  $htmldoc -> set_charset ( 'iso-8859-1' ) ;
  $htmldoc -> set_footer ( '.' , '.' , '.' ) ;
  $htmldoc -> set_header ( '.' , 'l' , '.' ) ;
  $htmldoc -> set_html_content ( encode ( 'iso-8859-1' , $html ) ) ;
  $htmldoc -> set_logoimage ( $home . '/htdocs/assets/img/logo.jpg' ) ;
  # Set page up for A5 or A4. Note that A4 is the default page size.
  if ( $pagesize eq 'A5' ) {
    $htmldoc -> set_fontsize ( 10 ) ;
    $htmldoc -> set_page_size ( '148x210mm' ) if $pagesize eq 'A5' ;
    $htmldoc -> set_left_margin ( 10 , 'mm' ) ;
    $htmldoc -> set_right_margin ( 10 , 'mm' ) ;
    $htmldoc -> set_top_margin ( 14 , 'mm' ) ;
    $htmldoc -> set_bottom_margin ( 14 , 'mm' ) ;
  } else { # Page size = A4
    $htmldoc -> set_fontsize ( 11 ) ;
    $htmldoc -> set_left_margin ( 14 , 'mm' ) ;
    $htmldoc -> set_right_margin ( 14 , 'mm' ) ;
    $htmldoc -> set_top_margin ( 20 , 'mm' ) ;
    $htmldoc -> set_bottom_margin ( 20 , 'mm' ) ;
  }

  # Find when this_limit takes us beyond page one
  my $pdf = $htmldoc -> generate_pdf ;
  $pdf -> to_file ( '/tmp/' . $pagesize . '.pdf' ) ;

}

1 ;

__END__
