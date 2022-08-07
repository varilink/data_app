package DATA::WhatsOn::NewsItem ;

=head1 DATA::WhatsOn::NewsItem

=cut

use strict ;
use warnings ;

sub new {

=head2 new

=cut

   my $proto = shift ;
   my $class = ref ( $proto ) || $proto ;
   my $self = { } ;
   $self -> { ROWID } = undef ;
   $self -> { PUBLISHED_DATE } = '' ;
  $self -> { TITLE } = '' ;
  $self -> { IMAGE } = '' ;
  $self -> { MAILCHIMP_IMAGE } = '' ;
  $self -> { PRECIS } = '' ;
  $self -> { ITEM_TEXT } = '' ;
  $self -> { TEMP } = {} ;

   bless ( $self , $class ) ;
   return $self ;

}

#
# Internal methods, not for use from outside of this package
#

sub _datetostr {

#
# Converts the database representation of a date to the string representation
#

   my $date = shift ;

   # Convert yyyy-mm-dd to dd/mm/yyyy
   my $string = substr ( $date , 8 , 2 ) . '/' .
                substr ( $date , 5 , 2 ) . '/' .
                substr ( $date , 0 , 4 ) ;

   return $string ;

}

sub _strtodate {

#
# Converts the string representation of a date to the database representation
#

   my $string = shift ;

   # Convert dd/mm/yyyy to yyyy-mm-dd
   my $date = substr ( $string , 6 , 4 ) . '-' .
              substr ( $string , 3 , 2 ) . '-' .
              substr ( $string , 0 , 2 ) ;

   return $date ;

} ;

=head2 Accessor Methods

=cut

sub rowid {

=head3 rowid

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { ROWID } = shift }
   return $self -> { ROWID } ;

}

sub published_date {

=head3 published_date

=cut

   my $self = shift ;
   if ( @_ ) {

      my $input = shift ;

      if ( $input =~ /\d\d\/\d\d\/\d\d\d\d/ ) {

         $self -> { PUBLISHED_DATE } = $input ;

      } else {

         $self -> { PUBLISHED_DATE } = _datetostr ( $input ) ;

      }

   }
   return $self -> { PUBLISHED_DATE } ;

}

sub title {

=head3 title

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { TITLE } = shift }
   return $self -> { TITLE } ;

}

sub image {

=head3 image

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { IMAGE } = shift }
   return $self -> { IMAGE } ;

}

sub mailchimp_image {

=head3 mailchimp_image

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { MAILCHIMP_IMAGE } = shift }
   return $self -> { MAILCHIMP_IMAGE } ;

}

sub precis {

=head3 precis

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { PRECIS } = shift }
   return $self -> { PRECIS } ;

}

sub item_text {

=head3 item_text

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { ITEM_TEXT } = shift }
   return $self -> { ITEM_TEXT } ;

}

sub temp {

=head3 temp

Provides the ability to set and retrieve temporary values for an news_items
object. Temporary values are not persisted in the database. It can be useful for
programs to be able to associate values temporarily with an news_item object for
working purposes.

=cut

  my $self = shift ;
  my $key = shift ;
  if ( @_ ) { $self -> { TEMP } -> { $key } = shift }
  return $self -> { TEMP } -> { $key } ;

}

=head2 Data Persistence Methods

=cut

sub fetch {

=head3 fetch

=cut

  my $proto = shift ;
  my $dbh = shift ;
  my $filter = shift if @_ ;

  if ( ref $proto ) {

    # Called as object, fetch an individual news item

    my $self = $proto ;

    my $sth = $dbh -> prepare (
      'SELECT * FROM whatson_news_item WHERE rowid = :rowid'
    ) ;

      $sth -> bind_param ( ':rowid' , $self -> rowid ) ;

     $sth -> execute ;

    if ( my $row = $sth -> fetchrow_hashref ) {

       $self -> rowid          ( $row -> { rowid          } ) ;
       $self -> published_date    ( $row -> { published_date    } ) ;
         $self -> title          ( $row -> { title          } ) ;
         $self -> image          ( $row -> { image          } ) ;
         $self -> mailchimp_image  ( $row -> { mailchimp_image  } ) ;
         $self -> precis        ( $row -> { precis        } ) ;
         $self -> item_text      ( $row -> { item_text      } ) ;

      return 1 ; # Tell the caller it was a success

    } else {

      return 0 ; # Tell the caller it was a failure

    }

  } else {

    # Called as class, fetch a list of news items

    my $class = $proto ;

    my $stmt
      = 'SELECT * FROM whatson_news_item ORDER BY published_date DESC, rowid DESC' ;

    $stmt .= ' LIMIT ' . $filter -> { limit } if $filter -> { limit } ;

    my $sth = $dbh -> prepare ( $stmt ) ;

    $sth -> execute ;

    my @newsitems ;

    while ( my $row = $sth -> fetchrow_hashref ) {

      my $newsitem = new DATA::WhatsOn::NewsItem ;

      $newsitem -> rowid        ( $row -> { rowid          } ) ;
      $newsitem -> published_date  ( $row -> { published_date    } ) ;
      $newsitem -> title        ( $row -> { title          } ) ;
      $newsitem -> image        ( $row -> { image          } ) ;
      $newsitem -> mailchimp_image  ( $row -> { mailchimp_image  } ) ;
      $newsitem -> precis        ( $row -> { precis        } ) ;
      $newsitem -> item_text      ( $row -> { item_text      } ) ;

      push @newsitems , $newsitem ;

    }

     return @newsitems ;

  }

}

sub save {

   my ( $self , $dbh ) = @_ ;

   my $published_date = _strtodate ( $self -> published_date ) ;

  if ( $self -> rowid ) {

    # This is an update

    my $sth = $dbh -> prepare ('

      UPDATE  whatson_news_item
      SET    published_date    = :published_date  ,
            title          = :title        ,
            image          = :image        ,
            precis        = :precis      ,
            item_text      = :item_text
      WHERE    rowid          = :rowid

    ') ;

    $sth -> bind_param ( ':published_date'  , $published_date    ) ;
    $sth -> bind_param ( ':title'        , $self -> title    ) ;
    $sth -> bind_param ( ':image'        , $self -> image    ) ;
    $sth -> bind_param ( ':precis'      , $self -> precis    ) ;
    $sth -> bind_param ( ':item_text'    , $self -> item_text  ) ;
    $sth -> bind_param ( ':rowid'        , $self -> rowid    ) ;

    $sth -> execute ;

  } else {

    # This is an insert

     my $sth = $dbh -> prepare ('

      INSERT
      INTO      whatson_news_item  (
                published_date    ,
                title          ,
                image          ,
                precis        ,
                item_text
      ) VALUES (
                :published_date  ,
                :title        ,
                :image        ,
                :precis        ,
                :item_text
      )

     ') ;

    $sth -> bind_param ( ':published_date'  , $published_date    ) ;
    $sth -> bind_param ( ':title'        , $self -> title    ) ;
    $sth -> bind_param ( ':image'        , $self -> image    ) ;
    $sth -> bind_param ( ':precis'      , $self -> precis    ) ;
    $sth -> bind_param ( ':item_text'    , $self -> item_text  ) ;

    $sth -> execute ;

    $self -> fetch ( $dbh ) ;

  }

}

sub delete {

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'DELETE
         FROM whatson_news_item
        WHERE rowid = ?'

   ) ;

   $sth -> execute ( $self -> rowid ) ;

}

1 ;

__END__
