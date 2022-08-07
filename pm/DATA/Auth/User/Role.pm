package DATA::Auth::User::Role ;

=head1 DATA::Auth::User::Role

Implements the user role domain object for the auth application.

=cut

use strict ;
use warnings ;
use Carp ;

our $userid ;

sub new {

  my $proto = shift ;
  my $class = ref ( $proto ) || $proto ;
  my $self = { } ;
  $self -> { USERID } = undef ;
  $self -> { ROLE } = undef ;
  $self -> { FETCHED } = undef ;

  bless ( $self , $class ) ;
  return $self ;

}

sub _fetched {

  my $self = shift ;
  if ( @_ ) { $self -> { FETCHED } = shift }
  return $self -> { FETCHED } ;

}

=head2 Accessors

=cut

sub userid {

=head3 userid

Of course, this is the userid associated with a user role as opposed to the
accessor for the userid associated with a user, which is implemented in the user
domain object.

=cut

  my $proto = shift ;

  if ( ref $proto ) {

    # Called as object method
    my $self = $proto ;
    if ( @_ ) { $self -> { USERID } = shift }
    return $self -> { USERID } ;

  } else {

    # Called as class method
    if ( @_ ) { $userid = shift }
    return $userid ;

  }

}

sub role {

=head3 role

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { ROLE } = shift }
  return $self -> { ROLE } ;

}

=head2 Persistence

Persistence methods for the user role object. These use the database to store
objects.

=cut

sub fetch {

=head3 fetch

Class method that instantiates the user role objects for a user from the
database.

=cut

  my ( $class , $dbh ) = @_ ;

  if ( ref $class ) { confess 'Class method called as object method' }

  my $sth = $dbh -> prepare (

    'SELECT *
       FROM auth_user_role
      WHERE userid = :userid'

  ) ;

  $sth -> bind_param ( ':userid' , $userid ) ;

  $sth -> execute ;

  my @user_roles ;

  while ( my $row = $sth -> fetchrow_hashref ) {

    my $user_role = new DATA::Auth::User::Role ;

    $user_role -> _fetched  ( 1               ) ;
    $user_role -> userid    ( $row -> { userid  }  ) ;
    $user_role -> role    ( $row -> { role    }  ) ;

    push @user_roles , $user_role ;

  }

  return @user_roles ;

}

sub save {

=head3 save

Saves a user role object to the database, either as an insert or update
depending on whether that user role is new to the database or not.

=cut

  my ( $self , $dbh ) = @_ ;

  my $sth ;

  if ( $self -> _fetched ) {

    # This is an update

  } else {

    # This is an insert
    my $this_userid ;

    if ( $self -> userid ) { $this_userid = $self -> userid }
    else { $this_userid = $userid } ;

    $sth = $dbh -> prepare (

      'INSERT
         INTO auth_user_role (
                 userid  ,
                 role
      ) VALUES (  :userid ,
                 :role
      )'

    ) ;

    $sth -> bind_param ( ':userid' , $this_userid  ) ;
    $sth -> bind_param ( ':role'   , $self -> role ) ;

    $sth -> execute ;

  }

}

1 ;

__END__
