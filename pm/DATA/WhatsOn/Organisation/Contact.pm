package DATA::WhatsOn::Organisation::Contact ;

use strict ;
use Carp ;

our $organisation_rowid ;

sub new {

   my $proto = shift ;
   my $class = ref ( $proto ) || $proto ;
   my $self = { } ;
   $self -> { ORGANISATION_ROWID } = undef ;
   $self -> { NAME } = undef ;
   $self -> { EMAIL } = undef ;
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

sub name {

   my $self = shift ;
   if ( @_ ) { $self -> { NAME } = shift }
   return $self -> { NAME } ;

}

sub email {

   my $self = shift ;
   if ( @_ ) { $self -> { EMAIL } = shift }
   return $self -> { EMAIL } ;

}

sub fetch {

  my ( $class , $dbh ) = @_ ;

  if ( ref $class ) { confess 'Class method called as object method' }

  my $sth = $dbh -> prepare (

    'SELECT *
      FROM whatson_organisation_function
        WHERE organisation_rowid = :organisation_rowid'

  ) ;

  $sth -> bind_param ( ':organisation_rowid' , $organisation_rowid ) ;

  $sth -> execute ;

  my @functions = ( ) ;

  while ( my $row = $sth -> fetchrow_hashref ) {

    my $function = new DATA::WhatsOn::Organisation::Function ;

    $function -> organisation_rowid ( $row -> { organisation_rowid } ) ;
    $function -> name ( $row -> { name } ) ;
    $function -> email ( $row -> { email } ) ;
    $function -> _fetched  ( 1 ) ;

    push @functions , $function ;

  }

  return @functions ;

}

sub save {

  my ( $self , $dbh ) = @_ ;

  my $sth ;

  if ( $self -> _fetched ) {

    # This is an update

  } else {

    # This is an insert

    my $this_org_rowid ;

    $self -> organisation_rowid
      ? $this_org_rowid = $self -> organisation_rowid
      : $this_org_rowid = $organisation_rowid ;

    $sth = $dbh -> prepare (

      'INSERT
            INTO whatson_organisation_function (
                   organisation_rowid  ,
                   name                ,
                   email
        ) VALUES ( :organisation_rowid ,
                   :name               ,
                   :email              )'

    ) ;

      $sth -> bind_param (
      ':organisation_rowid' , $this_org_rowid ) ;
      $sth -> bind_param (
      ':name'               , $self -> name               ) ;
      $sth -> bind_param (
      ':email'              , $self -> email              ) ;

    $sth -> execute ;

  }

}

1 ;

__END__
