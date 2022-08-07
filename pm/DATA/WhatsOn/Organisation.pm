package DATA::WhatsOn::Organisation ;

=head1 DATA::WhatsOn::Organisation

=cut

use strict ;
use warnings ;
use Carp ;
use Hash::Case::Lower ;
use DATA::WhatsOn::Event ;
use DATA::WhatsOn::Organisation::Function ;
use DATA::WhatsOn::Organisation::Handle ;

sub new {

=head2 new

=cut

  my $proto = shift ;
  my $class = ref ( $proto ) || $proto ;
  my $self = { } ;
  $self -> { ROWID } = undef ;
  $self -> { NAME } = '' ;
  $self -> { TYPE } = '' ;
  $self -> { STATUS } = '' ;
  $self -> { PAID_IN_PERIOD } = undef ;
  $self -> { EMAIL } = '' ;
  $self -> { WEBSITE } = '' ;
  $self -> { DESCRIPTION } = '' ;
  $self -> { ADDRESS1 } = '' ;
  $self -> { ADDRESS2 } = '' ;
  $self -> { ADDRESS3 } = '' ;
  $self -> { ADDRESS4 } = '' ;
  $self -> { POSTCODE } = '' ;
  $self -> { CONTACTS } = [ ] ;
  $self -> { EVENTS } = [ ] ;
  $self -> { FUNCTIONS } = [ ] ;
  $self -> { HANDLES } = [ ] ;

  bless ( $self , $class ) ;
  return $self ;

}

=head2 Accessor Methods

=cut

sub rowid {

=head3 rowid

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { ROWID } = shift }
  return $self -> { ROWID } ;

}

sub name {

=head3 name

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { NAME } = shift }
  return $self -> { NAME } ;

}

sub type {

=head3 type

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { TYPE } = shift }
  return $self -> { TYPE } ;

}

sub status {

=head3 status

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { STATUS } = shift }
  return $self -> { STATUS } ;

}

sub paid_in_period {

=head3 paid_in_period

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { PAID_IN_PERIOD } = shift }
  return $self -> { PAID_IN_PERIOD }  ;

}

sub email {

=head3 email

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { EMAIL } = shift }
  return $self -> { EMAIL } ;

}

sub website {

=head3 website

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { WEBSITE } = shift }
  return $self -> { WEBSITE } ;

}

sub description {

=head3 description

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { DESCRIPTION } = shift }
  return $self -> { DESCRIPTION } ;

}

sub address1 {

=head3 address1

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { ADDRESS1 } = shift }
  return $self -> { ADDRESS1 } ;

}

sub address2 {

=head3 address2

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { ADDRESS2 } = shift }
  return $self -> { ADDRESS2 } ;

}

sub address3 {

=head3 address3

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { ADDRESS3 } = shift }
  return $self -> { ADDRESS3 } ;

}

sub address4 {

=head3 address4

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { ADDRESS4 } = shift }
  return $self -> { ADDRESS4 } ;

}

sub postcode {

=head3 postcode

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { POSTCODE } = shift }
  return $self -> { POSTCODE } ;

}

sub contacts {

=head3 events

=cut

  my $self = shift ;
  if ( @_ ) { push @ { $self -> { CONTACTS } } , @_ }
  return $self -> { CONTACTS } ;

}

sub events {

=head3 events

=cut

  my $self = shift ;
  if ( @_ ) { push @ { $self -> { EVENTS } } , @_ }
  return $self -> { EVENTS } ;

}

sub functions {

=head3 functions

=cut

  my $self = shift ;
  if ( @_ ) { push @ { $self -> { FUNCTIONS } } , @_ }
  return $self -> { FUNCTIONS } ;

}

sub handles {

=head3 handles

=cut

  my $self = shift ;
  if ( @_ ) { push @ { $self -> { HANDLES } } , @_ }
  return $self -> { HANDLES }

}

sub as_hash {

=head3 as_hash

Returns the organisation as an unblessed hash with lower case keys

=cut

  my $self = shift ;

  my %organisation = %{ $self } ;
  tie my %hash , 'Hash::Case::Lower' , \%organisation ;

  if ( $hash { 'address1' } || $hash { 'address2' } || $hash { 'address3' } ||
       $hash { 'address4' } || $hash { 'postcode' } )
    { $hash { 'location' } = 1 }
  else
    { $hash { 'location' } = 0 }

  my @functions ;

  foreach my $function ( @{ $hash { 'functions' } } ) {

    my %function = %{ $function } ;
    tie my %subhash , 'Hash::Case::Lower' , \%function ;
    push @functions , \%subhash ;

  }

  @{ $hash { 'functions' } } = @functions ;

  return %hash ;

}

sub load {

  my ( $class , $path , $dbh ) = @_ ;

  if ( ref $class ) { confess 'Class method called as object method' }

  open my $fh , '<' , $path ;

  my $rec = <$fh> ;

ORG:

  while ( $rec ) {

    chomp $rec ;

    my ( $name , $type , $status , $email , $website ,   $address1 , $address2 ,
           $address3 , $address4 , $postcode , $function , $function_email )
      = split /\|/ , $rec ;

    my $org = new DATA::WhatsOn::Organisation ;
    $org -> name ( $name ) ;
    $org -> type ( $type ) ;
    $org -> email ( $email ) ;
    $org -> website ( $website ) ;
    $org -> status ( $status ) ;
    $org -> address1 ( $address1 ) ;
    $org -> address2 ( $address2 ) ;
    $org -> address3 ( $address3 ) ;
    $org -> address4 ( $address4 ) ;
    $org -> postcode ( $postcode ) ;

    my $prev_name = $name ;

ORG_FUN:

    while ( $name eq $prev_name ) {

      if ( $function ne '' ) {

        my $org_fun = new DATA::WhatsOn::Organisation::Function ;
        $org_fun -> name ( $function ) ;
        $org_fun -> email ( $function_email ) ;

        $org -> functions ( $org_fun ) ;

      }

      $rec = <$fh> ;

      chomp $rec ;

      ( $name , $type , $email , $website , $status , $address1 , $address2 ,
           $address3 , $address4 , $postcode , $function , $function_email )
        = split /\|/ , $rec ;

    } # End of ORG_RUN

    $org -> save ( $dbh ) ;

  } # End of ORG

  close $fh ;

}

=head2 Data Persistence Methods

=cut

sub fetch {

=head3 fetch

=cut

  my $proto = shift ;
  my $dbh = shift ;

  if ( ref $proto ) {

    # Called as object, fetch an individual organisation

    my $self = $proto ;

    # I introduced a filter for the class call and then later realised it was
    # useful for the object call also. It may be that we can combine and
    # rationalise logic associated with filters across the object and class
    # legs.
    my $filter = shift if @_ ;

    my $where = '' ; # Ready to build according to the filter

    # Add a type clause if specified
    $where .= ' AND type = \'' . $filter -> { type } . '\''
      if $filter -> { type } ;

    # Add a status clause if specified
    if ( $filter -> { status } ) {
      $where .= ' AND status = \'' . $filter -> { status } . '\'' ;
    }

    my $sth ; # Declare here as we have branches directly below

    if ( $self -> rowid ) {

      # Fetch based on rowid

      my $stmt =
        'SELECT *
           FROM whatson_organisation
          WHERE rowid = :rowid' ;

      $stmt .= $where if $where ;

      $sth = $dbh -> prepare ( $stmt ) ;

        $sth -> bind_param ( ':rowid' , $self -> rowid ) ;

      } elsif ( $self -> name ) {

        # Fetch based on name

        my $stmt =
          'SELECT rowid , *
             FROM whatson_organisation
            WHERE name = :name' ;

        $stmt .= $where if $where ;

        $sth = $dbh -> prepare ( $stmt ) ;

        $sth -> bind_param ( ':name' , $self -> name ) ;

      }

      $sth -> execute ;

      if ( my $row = $sth -> fetchrow_hashref ) {

        $self -> rowid          ( $row -> { rowid           } ) ;
        $self -> name           ( $row -> { name            } ) ;
        $self -> type           ( $row -> { type            } ) ;
        $self -> status         ( $row -> { status          } ) ;
        $self -> paid_in_period ( $row -> { paid_in_period  } ) ;
        $self -> email          ( $row -> { email           } ) ;
        $self -> website        ( $row -> { website         } ) ;
        $self -> description    ( $row -> { description     } ) ;
        $self -> address1       ( $row -> { address1        } ) ;
        $self -> address2       ( $row -> { address2        } ) ;
        $self -> address3       ( $row -> { address3        } ) ;
        $self -> address4       ( $row -> { address4        } ) ;
        $self -> postcode       ( $row -> { postcode        } ) ;

        DATA::WhatsOn::Organisation::Function
          -> organisation_rowid ( $self -> rowid ) ;

        my @functions = DATA::WhatsOn::Organisation::Function
          -> fetch ( $dbh ) ;

        $self -> functions ( @functions ) ;

        DATA::WhatsOn::Organisation::Handle
          -> organisation_rowid ( $self -> rowid ) ;

        my @handles = DATA::WhatsOn::Organisation::Handle
          -> fetch ( $dbh ) ;

        $self -> handles ( @handles ) ;

        return 1 ; # Tell the caller it was a success

    } else {

      return 0 ; # Tell the caller it was a failure

    }

  } else {

    # Called as class, fetch a list of organisations

    my $class = $proto ;

    my $filter = shift if @_ ;

    #
    # Filter should be a hash reference that optionally contains values for
    # the following keys.
    #
    # type:
    # If set will only retrive organisations whose type matches the value set.
    # is fetched. If not set or not set to one of these values then
    # organsiations of all types will be fetched.
    #
    # status:
    # If set will only retrieve organisations whose status matches.
    #
    # userid:
    # If set will only retrieve organisations that userid is a member of.
    #

    my $where = '' ; # Ready to build according to the filter

    # Add a type clause if specified
    $where .= 'type = \'' . $filter -> { type } . '\''
      if $filter -> { type } ;

    # Add a status clause if specified
    if ( $filter -> { status } ) {
      $where .= ' AND ' if $where ;
      $where .= 'status = \'' . $filter -> { status } . '\'' ;
    }

    # Add a userid clause if specified
    if ( $filter -> { userid } ) {
      $where .= ' AND ' if $where ;
      $where .= 'rowid IN (
           SELECT organisation_rowid
          FROM whatson_contact_organisation
         WHERE person_rowid = (
          SELECT rowid
            FROM whatson_contact
           WHERE userid = \'' . $filter -> { userid } . '\' ) )' ;
    }

    my $stmt = 'SELECT * FROM whatson_organisation' ;
    $stmt .= ' WHERE ' . $where if $where ;
    $stmt .= ' ORDER BY name' ;

    my $sth = $dbh -> prepare ( $stmt ) ;

    $sth -> execute ;

    my @orgs ;

    while ( my $row = $sth -> fetchrow_hashref ) {

      my $org = new DATA::WhatsOn::Organisation ;

      $org -> rowid        ( $row -> { rowid        } ) ;
      $org -> name        ( $row -> { name        } ) ;
      $org -> type        ( $row -> { type        } ) ;
      $org -> status        ( $row -> { status      } ) ;
      $org -> paid_in_period  ( $row -> { paid_in_period  } ) ;
      $org -> email        ( $row -> { email        } ) ;
      $org -> website      ( $row -> { website      } ) ;
      $org -> description    ( $row -> { description    } ) ;
      $org -> address1      ( $row -> { address1      } ) ;
      $org -> address2      ( $row -> { address2      } ) ;
      $org -> address3      ( $row -> { address3      } ) ;
      $org -> address4      ( $row -> { address4      } ) ;
      $org -> postcode      ( $row -> { postcode      } ) ;

      push @orgs , $org ;

    }

     return @orgs ;

  }

}

sub fetch_by_rowid {

=head3 fetch_by_rowid

=cut

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'SELECT *
         FROM whatson_organisation
        WHERE rowid = ?'

   ) ;

   $sth -> bind_param ( 1 , $self -> rowid ) ;

   $sth -> execute ;

   my $row = $sth -> fetchrow_hashref ;

   $self -> name ( $row -> { name } ) ;
   $self -> email ( $row -> { email } ) ;
   $self -> address1 ( $row -> { address1 } ) ;
   $self -> address2 ( $row -> { address2 } ) ;
   $self -> address3 ( $row -> { address3 } ) ;
   $self -> address4 ( $row -> { address4 } ) ;
   $self -> postcode ( $row -> { postcode } ) ;
   $self -> website ( $row -> { website } ) ;

   return ;

}

sub fetch_events {

=head3 fetch_events

Fetch the coming events organised by a society

=cut

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'SELECT dates        ,
              name         ,
              start_date   ,
              end_date     ,
              status       ,
              venue        ,
              presented_by ,
              times        ,
              box_office
         FROM whatson_event_coming
        WHERE society = :society
     ORDER BY date ( start_date ) ,
              date ( end_date ) ,
              rowid'

   ) ;

   $sth -> bind_param ( ':society' , $self -> rowid ) ;

   $sth -> execute ;

   while ( my $row = $sth -> fetchrow_hashref ) {

      my $event = new DATA::WhatsOn::Event ;

      $event -> dates ( $row -> { dates } ) ;
      $event -> name ( $row -> { name } ) ;
      $event -> start_date ( $row -> { start_date } ) ;
      $event -> end_date ( $row -> { end_date } ) ;
      $event -> status ( $row -> { status } ) ;
      $event -> venue ( $row -> { venue } ) ;
      $event -> presented_by ( $row -> { presented_by } ) ;
      $event -> times ( $row -> { times } ) ;
      $event -> box_office ( $row -> { box_office } ) ;

      $self -> events ( $event ) ;

   }

}

sub list {

   my ( $class , $dbh ) = @_ ;

   if ( ref $class ) { confess "Class method called as object method" }

   my $sth = $dbh -> prepare (

      'SELECT rowid ,
              name ,
              email ,
              address1 ,
              address2 ,
              address3 ,
              address4 ,
              postcode ,
              website
         FROM whatson_organisation'

   ) ;

   $sth -> execute ;

   my @societies ;

   while ( my $row = $sth -> fetchrow_hashref ) {

      my $society = new DATA::WhatsOn::Organisation ;

      $society -> rowid ( $row -> { rowid } ) ;
      $society -> name ( $row -> { name } ) ;
      $society -> email ( $row -> { email } ) ;
      $society -> address1 ( $row -> { address1 } ) ;
      $society -> address2 ( $row -> { address2 } ) ;
      $society -> address3 ( $row -> { address3 } ) ;
      $society -> address4 ( $row -> { address4 } ) ;
      $society -> postcode ( $row -> { postcode } ) ;
      $society -> website ( $row -> { website } ) ;

      push @societies , $society ;

   }

   return @societies ;

}

sub save {

   my ( $self , $dbh ) = @_ ;

  if ( $self -> rowid ) {

    # This is an update

    my $sth = $dbh -> prepare (

      'UPDATE whatson_organisation
             SET name        = :name        ,
                 type        = :type        ,
                 status        = :status      ,
              paid_in_period  = :paid_in_period  ,
                 email        = :email        ,
                 website      = :website      ,
                 description    = :description    ,
                 address1      = :address1      ,
                 address2      = :address2      ,
                 address3      = :address3      ,
                 address4      = :address4      ,
                 postcode      = :postcode
           WHERE rowid = :rowid'

    ) ;

    $sth -> bind_param ( ':name'        , $self -> name        ) ;
    $sth -> bind_param ( ':type'        , $self -> type        ) ;
    $sth -> bind_param ( ':status'      , $self -> status        ) ;
    $sth -> bind_param ( ':paid_in_period'  , $self -> paid_in_period  ) ;
    $sth -> bind_param ( ':email'        , $self -> email        ) ;
    $sth -> bind_param ( ':website'      , $self -> website      ) ;
    $sth -> bind_param ( ':description'    , $self -> description    ) ;
    $sth -> bind_param ( ':address1'      , $self -> address1      ) ;
    $sth -> bind_param ( ':address2'      , $self -> address2      ) ;
    $sth -> bind_param ( ':address3'      , $self -> address3      ) ;
    $sth -> bind_param ( ':address4'      , $self -> address4      ) ;
    $sth -> bind_param ( ':postcode'      , $self -> postcode      ) ;
    $sth -> bind_param ( ':rowid'        , $self -> rowid        ) ;

    $sth -> execute ;

  } else {

    # This is an insert

     my $sth = $dbh -> prepare (

        'INSERT
           INTO whatson_organisation (
                   name        ,
                   type        ,
                   status        ,
                 paid_in_period  ,
                   email        ,
                   website      ,
                   description    ,
                   address1      ,
                   address2      ,
                   address3      ,
                   address4      ,
                   postcode
       ) VALUES ( :name        ,
                :type        ,
                :status        ,
                :paid_in_period  ,
                :email        ,
                :website      ,
                :description    ,
                :address1      ,
                :address2      ,
                :address3      ,
                :address4      ,
                :postcode
      )'

     ) ;

    $sth -> bind_param ( ':name'        , $self -> name        ) ;
    $sth -> bind_param ( ':type'        , $self -> type        ) ;
    $sth -> bind_param ( ':status'      , $self -> status        ) ;
    $sth -> bind_param ( ':paid_in_period'  , $self -> paid_in_period  ) ;
    $sth -> bind_param ( ':email'        , $self -> email        ) ;
    $sth -> bind_param ( ':website'      , $self -> website      ) ;
    $sth -> bind_param ( ':description'    , $self -> description    ) ;
    $sth -> bind_param ( ':address1'      , $self -> address1      ) ;
    $sth -> bind_param ( ':address2'      , $self -> address2      ) ;
    $sth -> bind_param ( ':address3'      , $self -> address3      ) ;
    $sth -> bind_param ( ':address4'      , $self -> address4      ) ;
    $sth -> bind_param ( ':postcode'      , $self -> postcode      ) ;

    $sth -> execute ;

    $self -> fetch ( $dbh ) ;

    DATA::WhatsOn::Organisation::Function
      -> organisation_rowid ( $self -> rowid ) ;

    foreach my $function ( @{ $self -> functions } ) {

         $function -> save ( $dbh ) ;

      } ;

  }

}

sub update {

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'UPDATE whatson_organisation
          SET name     = ? ,
              website  = ? ,
              email    = ? ,
              address1 = ? ,
              address2 = ? ,
              address3 = ? ,
              address4 = ? ,
              postcode = ?
        WHERE rowid = ?'

   ) ;

   $sth -> bind_param ( 1 , $self -> name ) ;
   $sth -> bind_param ( 2 , $self -> website ) ;
   $sth -> bind_param ( 3 , $self -> email ) ;
   $sth -> bind_param ( 4 , $self -> address1 ) ;
   $sth -> bind_param ( 5 , $self -> address2 ) ;
   $sth -> bind_param ( 6 , $self -> address3 ) ;
   $sth -> bind_param ( 7 , $self -> address4 ) ;
   $sth -> bind_param ( 8 , $self -> postcode ) ;
   $sth -> bind_param ( 9 , $self -> rowid ) ;

   $sth -> execute ;

}

sub delete {

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'DELETE
         FROM whatson_organisation
        WHERE rowid = ?'

   ) ;

   $sth -> execute ( $self -> rowid ) ;

}

1 ;

__END__
