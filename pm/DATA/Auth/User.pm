package DATA::Auth::User ;

=head1 DATA::Auth::User

Implements the User domain object for the Auth application.

=cut

use strict ;
use warnings ;
use Carp ;

use DateTime ;
use Digest::MD5 qw / md5_hex / ;

sub new {

   my $proto = shift ;
   my $class = ref ( $proto ) || $proto ;
   my $self = { } ;
  $self -> { FETCHED } = 0 ; # Will be updated to 1 or true after a fetch
   $self -> { USERID } = '' ;
   $self -> { ROLE } = '' ;
   $self -> { EMAIL } = undef ;
   $self -> { FIRST_NAME } = '' ;
   $self -> { SURNAME } = '' ;
   $self -> { PASSWORD } = '' ;
  $self -> { STATUS } = '' ;
  $self -> { SECRET } = '' ;
  $self -> { DATETIME } = '' ;
  $self -> { ROWID } = undef ;
   bless( $self , $class) ;
   return $self ;

}

sub _fetched {

  my $self = shift ;
  if ( @_ ) { $self -> { _FETCHED } = shift }
  return $self -> { _FETCHED } ;

}

sub userid {

=head3 userid

Userid accessor method

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { USERID } = shift }
   return $self -> { USERID } ;

}

sub role {

=head3 role

Role accessor method

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { ROLE } = shift }
   return $self -> { ROLE } ;

}

sub email {

=head3 email

Email accessor method

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { EMAIL } = shift }
   return $self -> { EMAIL } ;

}

sub first_name {

=head3 first_name

First name accessor method

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { FIRST_NAME } = shift }
   return $self -> { FIRST_NAME } ;

}

sub surname {

=head3 surname

Surname accessor method

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { SURNAME } = shift }
   return $self -> { SURNAME } ;

}

sub password {

=head3

Password accessor method

=cut

   my $self = shift ;

   if ( @_ ) {

    # If the password isn't a hash then hash it
    my $input = shift ;
    if ( $input =~ /^[0-9a-f]{32}$/ ) { $self -> { PASSWORD } = $input }
    else { $self -> { PASSWORD } = md5_hex $input }

  }

   return $self -> { PASSWORD } ;

}

sub status {

=head3 status

Status accessor method

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { STATUS } = shift }
   return $self -> { STATUS } ;

}

sub secret {

=head3 secret

Secret accessor method

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { SECRET } = shift }
  return $self -> { SECRET } ;

}

sub datetime {

=head3 datetime

Datetime accessor method

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { DATETIME } = shift }
  return $self -> { DATETIME } ;

}

sub rowid {

=head3 rowid

Rowid (person rowid) accessor method

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { ROWID } = shift }
  return $self -> { ROWID } ;

}

=head2 Persistence

Persistence methods for the user object. These use the database to store
objects.

=cut

sub as_hash {

  my $self = shift ;
  my %user = %{ $self } ;
  tie my %hash , 'Hash::Case::Lower' , \%user ;
  return %hash ;

}

sub load {

  my ( $class , $path , $dbh ) = @_ ;

  if ( ref $class ) { confess 'Class method called as object method' }

  open my $fh , '<' , $path ;

  my $rec = <$fh> ;

USER:

  while ( $rec ) {

    chomp $rec ;

    my ( $userid , $password , $email , $first_name , $surname , $role )
      = split /\|/ , $rec ;

    my $user = new DATA::Auth::User ;
    $user -> userid ( $userid ) ;
      $user -> role ( $role ) ;
    $user -> password ( $password ) ;
    $user -> email ( $email ) ;
    $user -> first_name ( $first_name ) ;
    $user -> surname ( $surname ) ;
    $user -> status ( 'CONFIRMED' ) ;

    $user -> save ( $dbh ) ;

    $rec = <$fh> ;

  } # End of USER

  close $fh ;

}

sub fetch {

=head3 fetch

Restores the details of a user from the database. Can do this either via userid
or via email.

=cut

  my $proto = shift ;
  my $dbh = shift ;

  my $sth ;

  if ( ref $proto ) {

    # Called as an object, fetch and individual user

    my $self = $proto ;

    my $class = ref $proto ;

    if ( $self -> userid ) {

      $sth = $dbh -> prepare (

        'SELECT *
           FROM auth_user
          WHERE userid = :userid'

      ) ;

      $sth -> bind_param ( ':userid' , $self -> userid ) ;

    } elsif ( $self -> email ) {

      $sth = $dbh -> prepare (

        'SELECT *
          FROM auth_user
          WHERE email = :email'

      ) ;

      $sth -> bind_param ( ':email' , $self -> email ) ;

    }

    $sth -> execute ;

    my $row ;

    if ( $row = $sth -> fetchrow_hashref ) {

      $self -> _fetched ( 1 ) ;
      $self -> rowid     ( $row -> { rowid     } ) ;
      $self -> userid     ( $row -> { userid     } ) ;
      $self -> role     ( $row -> { role     } ) ;
      $self -> email      ( $row -> { email      } ) ;
      $self -> first_name ( $row -> { first_name } ) ;
      $self -> surname    ( $row -> { surname    } ) ;
      $self -> password   ( $row -> { password   } ) ;
      $self -> status     ( $row -> { status     } ) ;
      $self -> secret     ( $row -> { secret     } ) ;
      if ( $row -> { datetime } ) {
        $self -> datetime ( new DateTime (
          year   => substr ( $row -> { datetime } , 0  , 4 ) ,
           month  => substr ( $row -> { datetime } , 5  , 2 ) ,
           day    => substr ( $row -> { datetime } , 8  , 2 ) ,
             hour   => substr ( $row -> { datetime } , 11 , 2 ) ,
           minute => substr ( $row -> { datetime } , 14 , 2 ) ,
           second => substr ( $row -> { datetime } , 17 , 2 ) ,
         ) )
      }

      return 1 ;

    } else {

      return 0 ;

    }

  } else {

    # Called as a class, fetch a list of users

    my $class = $proto ;

    my $sth = $dbh -> prepare (

      'SELECT *
         FROM auth_user'

    ) ;      

    my @users ;

    while ( my $row = $sth -> fetchrow_hashref ) {

      my $user = new DATA::Auth::User ;

      $user -> _fetched ( 1 ) ;
      $user -> rowid ( $row -> { rowid } ) ;
      $user -> userid     ( $row -> { userid     } ) ;
      $user -> role     ( $row -> { role     } ) ;
      $user -> email      ( $row -> { email      } ) ;
      $user -> first_name ( $row -> { first_name } ) ;
      $user -> surname    ( $row -> { surname    } ) ;
      $user -> password   ( $row -> { password   } ) ;
      $user -> status     ( $row -> { status     } ) ;
      $user -> secret     ( $row -> { secret     } ) ;
      $user -> datetime   ( $row -> { datetime   } ) ;

      push @users , $user ;

    }

    return @users ;

  }

}

sub save {

  my ( $self , $dbh ) = @_ ;

  if ( $self -> _fetched ) {

    # This is an update

    my $sth ;

    if ( $self -> rowid ) {

      $sth = $dbh -> prepare (

        'UPDATE auth_user
            SET userid     = :userid     ,
                role       = :role       ,
              email      = :email      ,
                   first_name = :first_name ,
                   surname    = :surname    ,
                   password   = :password   ,
                   status     = :status     ,
                   secret     = :secret     ,
                   datetime   = :datetime
          WHERE rowid = :rowid' 

      ) ;

      $sth -> bind_param ( ':rowid'    , $self -> rowid      ) ;

    } else {

      $sth = $dbh -> prepare (

        'UPDATE auth_user
            SET role       = :role       ,
              email      = :email      ,
                   first_name = :first_name ,
                   surname    = :surname    ,
                   password   = :password   ,
                   status     = :status     ,
                   secret     = :secret     ,
                   datetime   = :datetime
          WHERE userid = :userid' 

      ) ;

    }

    $sth -> bind_param ( ':userid'    , $self -> userid      ) ;
    $sth -> bind_param ( ':role'      , $self -> role      ) ;
    $sth -> bind_param ( ':email'      , $self -> email      ) ;
    $sth -> bind_param ( ':first_name'  , $self -> first_name  ) ;
    $sth -> bind_param ( ':surname'    , $self -> surname    ) ;
    $sth -> bind_param ( ':password'    , $self -> password    ) ;
    $sth -> bind_param ( ':status'    , $self -> status      ) ;
    $sth -> bind_param ( ':secret'    , $self -> secret      ) ;
    $sth -> bind_param ( ':datetime'    , $self -> datetime    ) ;

    $sth -> execute ;

  } else {

    # This is an insert

    my $sth = $dbh -> prepare (

      'INSERT
         INTO auth_user (
                 userid      ,
                    role        ,
                 email       ,
                 first_name  ,
                 surname     ,
                 password    ,
                 status      ,
                 secret      ,
                 datetime
     ) VALUES (   :userid     , 
                    :role       ,
                    :email      ,
                 :first_name ,
                 :surname    ,
                 :password   ,
                 :status     ,
                 :secret     ,
                 :datetime
     )'

    ) ;

    $sth -> bind_param ( ':userid'     , $self -> userid     ) ;
    $sth -> bind_param ( ':role'       , $self -> role       ) ;
    $sth -> bind_param ( ':email'      , $self -> email      ) ;
    $sth -> bind_param ( ':first_name' , $self -> first_name ) ;
    $sth -> bind_param ( ':surname'    , $self -> surname    ) ;
    $sth -> bind_param ( ':password'   , $self -> password   ) ;
    $sth -> bind_param ( ':status'     , $self -> status     ) ;
    $sth -> bind_param
      ( ':secret' , $self -> secret ? $self -> secret : '' ) ;
    $sth -> bind_param ( ':datetime'   , $self -> datetime
      ? $self -> datetime -> strftime ( "%Y-%m-%d %H:%M:%S" ) : '' ) ;

    $sth -> execute ;

  }

}




sub insert {

=head3 insert

Insert a user to the database.

=cut

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'INSERT
         INTO auth_user (
                 userid ,
                 email ,
                 first_name ,
                 surname ,
                 password ,
                 status ,
                 secret ,
                 datetime )
       VALUES ( ? , ? , ? , ? , ? , ? , ? , ? )'

   ) ;

   $sth -> bind_param ( 1 , $self -> userid ) ;
   $sth -> bind_param ( 2 , $self -> email ) ;
   $sth -> bind_param ( 3 , $self -> first_name ) ;
   $sth -> bind_param ( 4 , $self -> surname ) ;
   $sth -> bind_param ( 5 , md5 ( $self -> password ) ) ;
   $sth -> bind_param ( 6 , $self -> status ) ;
   $sth -> bind_param ( 7 , $self -> secret ) ;
  $sth -> bind_param (
    8 , $self -> datetime -> strftime ( "%Y-%m-%d %H:%M:%S" )
  ) ;

   $sth -> execute ;

} 
                   

sub store {

=head3 store

Store a user in the database. Performs either an insert or an update.

=cut

  my ( $self , $dbh ) = @_ ;

  my $sth ;

  if ( $self -> rowid ) {

    # We have a rowid so this is an update

    $sth = $dbh -> prepare (

      'UPDATE auth_user
             SET userid     = :userid     ,
                 email      = :email      ,
                 first_name = :first_name ,
                 surname    = :surname    ,
                 password   = :password   ,
                 status     = :status     ,
                 secret     = :secret     ,
                 datetime   = :datetime
           WHERE rowid      = :rowid'

    ) ;

    $sth -> bind_param ( ':rowid' , $self -> rowid ) ;

  } else {

    # We don't have a rowid so this is an insert

    $sth = $dbh -> prepare (

      'INSERT
            INTO auth_user ( userid      ,
                             email       ,
                             first_name  ,
                             surname     ,
                             password    ,
                             status      ,
                             secret      ,
                             datetime )
          VALUES           ( :userid     ,
                             :email      ,
                             :first_name ,
                             :surname    ,
                             :password   ,
                             :status     ,
                             :secret     ,
                             :datetime )' 

    ) ;

  }

  $sth -> bind_param ( ':userid' , $self -> userid ) ;
  $sth -> bind_param ( ':email' , $self -> email ) ;
  $sth -> bind_param ( ':first_name' , $self -> first_name ) ;
  $sth -> bind_param ( ':surname' , $self -> surname ) ;
  $self -> password =~ /^[a-zA-Z0-9]+$/
    ? $sth -> bind_param ( ':password' , md5 ( $self -> password ) )
    : $sth -> bind_param ( ':password' , $self -> password ) ;
  $sth -> bind_param ( ':status' , $self -> status ) ;
  $sth -> bind_param ( ':secret' , $self -> secret ) ;
  $sth -> bind_param (
    ':datetime' , $self -> datetime -> strftime ( "%Y-%m-%d %H:%M:%S" )
  ) ;

  $sth -> execute ;

  if ( !$self -> rowid && $self -> roles ) {

    # We have inserted a new auth_user and it has roles defined.
    # We need to insert the roles too.

    foreach my $role ( @{ $self -> roles } ) {

      $sth = $dbh -> prepare (

        'INSERT
             INTO auth_user_role ( userid  ,
                                   role      )
           VALUES                ( :userid ,
                                   :role     )'

      ) ;

      $sth -> bind_param ( ':userid' , $self -> userid ) ;
      $sth -> bind_param ( ':role' , $role ) ;

      $sth -> execute ;

    } # End foreach

  }

}

sub generate_password {

=head3 generate_password

Class method to generate a password

=cut

  my $proto = shift ;

  use App::Genpass ;
  my $genpass = App::Genpass -> new ;
  my $password = $genpass -> generate ( 1 ) ;

  if ( ref $proto ) {

    # Called as an object, populate self with the generated password
    my $self = $proto ;
    my $class = ref $proto ;
    $self -> password ( $password ) ;

  } else {

    # Called as a class, return the generated password
    my $class = $proto ;
    return $password ;

  }

}

sub already_user {

=head3 already_user

Test if there is already a userid registered for the email address.

=cut

  my ( $self , $dbh ) = @_ ;

  my $sth = $dbh -> prepare (

    'SELECT NULL
       FROM auth_user
      WHERE email= :email'

  ) ;

  $sth -> bind_param ( ':email' , $self -> email ) ;
  $sth -> execute ;

  if ( my $row = $sth -> fetchrow_hashref ) { return 1 }
  else { return 0 }

}

sub duplicate_userid {

=head3 not_unique

Test if a userid is a duplicate of one already known.

=cut

  my ( $self , $dbh ) = @_ ;

  my $sth = $dbh -> prepare (

    'SELECT NULL
       FROM auth_user
      WHERE userid = :userid'

  ) ;

  $sth -> bind_param ( ':userid' , $self -> userid ) ;
  $sth -> execute ;

  if ( my $row = $sth -> fetchrow_hashref ) { return 1 }
  else { return 0 }

}

1 ;

__END__
