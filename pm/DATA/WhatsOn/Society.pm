package DATA::WhatsOn::Society ;

=head1 DATA::WhatsOn::Society

=cut

use strict ;
use warnings ;
use Carp ;

sub new {

=head2 new

=cut

   my $proto = shift ;
   my $class = ref ( $proto ) || $proto ;
   my $self = { } ;
   $self -> { ROWID } = undef ;
   $self -> { NAME } = undef ;
   $self -> { CONTACT } = undef ;
   $self -> { EMAIL } = undef ;
   $self -> { ADDRESS1 } = undef ;
   $self -> { ADDRESS2 } = undef ;
   $self -> { ADDRESS3 } = undef ;
   $self -> { ADDRESS4 } = undef ;
   $self -> { POSTCODE } = undef ;
   $self -> { WEBSITE } = undef ;
   $self -> { EVENTS } = [ ] ;

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

sub contact {

=head3 contact

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { CONTACT } = shift }
   return $self -> { CONTACT } ;

}

sub email {

=head3 email

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { EMAIL } = shift }
   return $self -> { EMAIL } ;
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

sub website {

=head3 website

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { WEBSITE } = shift }
   return $self -> { WEBSITE } ;
}

sub events {

=head3 events

=cut

   my $self = shift ;
   if ( @_ ) { push @ { $self -> { EVENTS } } , @_ }
   return $self -> { EVENTS } ;

}

=head2 Data Persistence Methods

=cut

sub fetch_by_rowid {

=head3 fetch_by_rowid

=cut

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'SELECT *
         FROM whatson_society
        WHERE rowid = ?'

   ) ;

   $sth -> bind_param ( 1 , $self -> rowid ) ;

   $sth -> execute ;

   my $row = $sth -> fetchrow_hashref ;

   $self -> name ( $row -> { name } ) ;
   $self -> contact ( $row -> { contact } ) ;
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
         FROM whatson_society'

   ) ;

   $sth -> execute ;

   my @societies ;

   while ( my $row = $sth -> fetchrow_hashref ) {

      my $society = new DATA::WhatsOn::Society ;

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

sub add {

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'INSERT
         INTO whatson_society (
                 name ,
                 contact ,
                 email ,
                 address1 ,
                 address2 ,
                 address3 ,
                 address4 ,
                 postcode ,
                 website
     ) VALUES ( ? , ? , ? , ? , ? , ? , ? , ? , ? )'

   ) ;

   $sth -> execute (
      $self -> name ,
      $self -> contact ,
      $self -> email ,
      $self -> address1 ,
      $self -> address2 ,
      $self -> address3 ,
      $self -> address4 ,
      $self -> postcode ,
      $self -> website
   ) ;

}

sub update {

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'UPDATE whatson_society
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
         FROM whatson_society
        WHERE rowid = ?'

   ) ;

   $sth -> execute ( $self -> rowid ) ;

}

1 ;

__END__
