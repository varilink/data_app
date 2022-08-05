package DATA::WhatsOn::Organisation::Handle ;

use strict ;
use Carp ;

our $organisation_rowid ;

sub new {

  my $proto = shift ;
  my $class = ref ( $proto ) || $proto ;
  my $self = { } ;
  $self -> { ORGANISATION_ROWID } = undef ;
  $self -> { TYPE } = undef ;
  $self -> { ADDRESS } = undef ;
	$self -> { FETCHED } = undef ;

  bless ( $self , $class ) ;
  return $self ;

}

sub _fetched {

  my $self = shift ;
  if ( @_ ) { $self -> { FETCHED } = shift }
  return $self -> { FETCHED } ;

}

sub organisation_rowid {

  my $proto = shift ;

  if ( ref $proto ) {

    # Called as object method
    my $self = $proto ;
    if ( @_ ) { $self -> { ORGANISATION_ROWID } = shift }
    return $self -> { ORGANISATION_ROWID } ;

  } else {

    # Called as class method
    if ( @_ ) { $organisation_rowid = shift }
    return $organisation_rowid ;

  }

}

sub platform_name {

  my $self = shift ;
  if ( @_ ) { $self -> { PLATFORM_NAME } = shift }
  return $self -> { PLATFORM_NAME } ;

}

sub handle {

  my $self = shift ;
  if ( @_ ) { $self -> { HANDLE } = shift }
  return $self -> { HANDLE } ;

}

sub fetch {

  my ( $class , $dbh ) = @_ ;

  if ( ref $class ) { confess 'Class method called as object method' }

  my $sth = $dbh -> prepare (

    'SELECT *
       FROM whatson_social_media_handle
       WHERE organisation_rowid = :organisation_rowid'

  ) ;

  $sth -> bind_param ( ':organisation_rowid' , $organisation_rowid ) ;

  $sth -> execute ;

  my @handles = ( ) ;

  while ( my $row = $sth -> fetchrow_hashref ) {

    my $handle = new DATA::WhatsOn::Organisation::Handle ;

    $handle -> organisation_rowid ( $row -> { organisation_rowid  } ) ;
    $handle -> platform_name      ( $row -> { platform_name       } ) ;
    $handle -> handle             ( $row -> { handle              } ) ;
    $handle -> _fetched           ( 1                               ) ;

    push @handles , $handle ;

  }

  return @handles ;

}

1 ;

__END__
