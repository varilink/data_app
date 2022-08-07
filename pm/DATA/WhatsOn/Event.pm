package DATA::WhatsOn::Event ;

=head1 DATA::WhatsOn::Event

=cut

use strict ;
use warnings ;

use Carp ;
use Encode qw / encode decode / ;

use DATA::WhatsOn::Organisation ;

#
# Internal methods, not for use from outside of this package
#

sub _datetostr {

#
# Converts the database representation of a date to the string representation
#

  my $date = shift ;

  # Convert yyyy-mm-dd to dd/mm/yyyy
  my $string =  substr ( $date , 8 , 2 ) . '/' .
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
  my $date =  substr ( $string , 6 , 4 ) . '-' .
              substr ( $string , 3 , 2 ) . '-' .
              substr ( $string , 0 , 2 ) ;

  return $date ;

} ;

sub new {

=head2 new

=cut

  my $proto = shift ;
  my $class = ref ( $proto ) || $proto ;
  my $self = { } ;
  $self -> { ROWID } = undef ;
  $self -> { NAME } = '' ;
  $self -> { DATES } = '' ;
  $self -> { START_DATE } = '' ;
  $self -> { START_DAY } = '' ;
  $self -> { END_DATE } = '' ;
  $self -> { END_DAY } = '' ;
  $self -> { TIMES } = '' ;
  $self -> { VENUE_NAME } = '' ;
  $self -> { VENUE_ROWID } = undef ;
  $self -> { SOCIETY_NAME } = '' ;
  $self -> { SOCIETY_ROWID } = undef ;
  $self -> { PRESENTED_BY } = '' ;
  $self -> { BOX_OFFICE } = '' ;
  $self -> { STATUS } = '' ;
  $self -> { USE_DESC } = 0 ;
  $self -> { DESCRIPTION } = '' ;
  $self -> { IMAGE } = '' ;
  $self -> { TEMP } = {} ;

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

sub dates {

=head3 dates

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { DATES } = shift }
  return $self -> { DATES } ;

}

sub dates_derived {

=head3 dates_derived

Derives the dates range from the start_date and end_date

=cut

  my $self = shift ;

  my @months = (
    'Jan' , 'Feb' , 'Mar' , 'Apr' , 'May' , 'Jun' ,
    'Jul' , 'Aug' , 'Sep' ,  'Oct' , 'Nov' , 'Dec'
  ) ;

  my $dates = '' ;

  if ( $self -> end_date eq $self -> start_date ) {

    # Single day event

    $dates = sprintf (
      "%01d %s"                                ,
      ( substr $self -> start_date , 0 , 2 )              ,
      $months [ ( substr $self -> start_date , 3 , 2 ) - 1 ]
    ) ;

  } elsif (
    substr ( $self -> start_date , 3 , 2 ) eq
    substr ( $self -> end_date , 3 , 2 )
  ) {

    # Multiple day event within single month

    $dates = sprintf (
      "%01d - %01d %s"                            ,
      ( substr $self -> start_date , 0 , 2 )              ,
      ( substr $self -> end_date , 0 , 2 )              ,
      $months [ ( substr $self -> start_date , 3 , 2 ) - 1 ]
    ) ;

  } else {

    # Event spans months

    $dates = sprintf (
      "%01d %s - %01d %s"                          ,
      ( substr $self -> start_date , 0 , 2 )              ,
      $months [ ( substr $self -> start_date , 3 , 2 ) - 1 ]  ,
      ( substr $self -> end_date , 0 , 2 )              ,
      $months [ ( substr $self -> end_date , 3 , 2 ) - 1 ]
    ) ;

  }

  return $dates ;

}

sub dates_valid {

=head3 dates_valid

Checks if the dates field is consistent with start_date and end_date

=cut

}

sub start_date {

=head3 start_date

=cut

   my $self = shift ;

   if ( @_ ) {

      my $input = shift ;

      if ( $input =~ /\d\d\/\d\d\/\d\d\d\d/ ) {

         $self -> { START_DATE } = $input ;

      } else {

         $self -> { START_DATE } = _datetostr ( $input ) ;

      }

   }

   return $self -> { START_DATE } ;

}

sub start_day {

=head3 start_day

A read-only method that returns to day name associated with the start date. This
method was added after the post method. Possibly the post method can use this
method to simplify its own logic. We could convert more logic in post to
methods; for example to derive rel_who_where, etc.

=cut

  my $self = shift ;

  my $start_date = new DateTime (
    year  => substr ( $self -> start_date , 6 , 4 ) ,
    month => substr ( $self -> start_date , 3 , 2 ) ,
    day   => substr ( $self -> start_date , 0 , 2 )
  ) ;

  return $start_date -> day_name ;

}

sub end_date {

=head3 end_date

=cut

   my $self = shift ;

   if ( @_ ) {

      my $input = shift ;

      if ( $input =~ /\d\d\/\d\d\/\d\d\d\d/ ) {

         $self -> { END_DATE } = $input ;

      } else {

         $self -> { END_DATE } = _datetostr ( $input ) ;

      }

   }

   return $self -> { END_DATE } ;

}

sub end_day {

=head3 end_day

A read-only method that returns to day name associated with the end date. This
method was added after the post method. Possibly the post method can use this
method to simplify its own logic. We could convert more logic in post to
methods; for example to derive rel_who_where, etc.

=cut

  my $self = shift ;

  my $end_date = new DateTime (
    year  => substr ( $self -> end_date , 6 , 4 ) ,
    month => substr ( $self -> end_date , 3 , 2 ) ,
    day   => substr ( $self -> end_date , 0 , 2 )
  ) ;

  return $end_date -> day_name ;

}

sub times {

=head3 times

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { TIMES } = shift }
   return $self -> { TIMES } ;

}

sub venue_name {

=head3 venue_name

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { VENUE_NAME } = shift }
   return $self -> { VENUE_NAME } ;

}

sub venue_rowid {

=head3 venue_rowid

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { VENUE_ROWID } = shift }
   return $self -> { VENUE_ROWID } ;

}

sub society_name {

=head3 society_name

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { SOCIETY_NAME } = shift }
   return $self -> { SOCIETY_NAME } ;

}

sub society_rowid {

=head3 society_rowid

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { SOCIETY_ROWID } = shift }
   return $self -> { SOCIETY_ROWID } ;

}

sub presented_by {

=head3 presented_by

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { PRESENTED_BY } = shift }
   return $self -> { PRESENTED_BY } ;

}

sub box_office {

=head3 box_office

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { BOX_OFFICE } = shift }
   return $self -> { BOX_OFFICE } ;

}

sub status {

=head3 status

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { STATUS } = shift }
   return $self -> { STATUS } ;

}

sub use_desc {

=head3 use_desc

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { USE_DESC } = shift }
   return $self -> { USE_DESC } ;

}

sub description {

=head3 description

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { DESCRIPTION } = shift }
   return $self -> { DESCRIPTION } ;

}

sub image {

=head3 image

=cut

  my $self = shift ;
  if ( @_ ) { $self -> { IMAGE } = shift }
  return $self -> { IMAGE } ;

}

sub temp {

=head3 temp

Provides the ability to set and retrieve temporary values for an event object.
Temporary values are not persisted in the database. It can be useful for
programs to be able to associate values temporarily with an event object for
working purposes.

=cut

  my $self = shift ;
  my $key = shift ;
  if ( @_ ) { $self -> { TEMP } -> { $key } = shift }
  return $self -> { TEMP } -> { $key } ;

}

sub as_hash {

=head3 as_hash

=cut

  my $self = shift ;

  my %event = %{ $self } ;
  tie my %hash , 'Hash::Case::Lower' , \%event ;

  return %hash ;

}

=head2 Data Persistence Methods

=cut

sub fetch {

  my $proto = shift ;
  my $dbh = shift ;

  my $where = '' ;  # Where clause that reflects the filter if one is provided.

  my $filter = shift if @_ ;

  # Only get events that haven't ended compared to sqlite 'now'
  $where .= 'date ( end_date ) >= date ( \'now\' )'
    if $filter -> { from } && $filter -> { from } eq 'now' ;

  # Only get events that haven't ended compared to a specified date
  $where .= 'date ( end_date ) >= date ( \'' . $filter -> { from } . '\' )'
    if $filter -> { from } && $filter -> { from } ne 'now' ;

  # Only events falling within the next year
  if ( $filter -> { to } && $filter -> { to } eq 'this-year' ) {
    my ( $sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst )
      = localtime ( ) ;
    $year = $year + 1901 ;
    $mon++ ;
    my $this_year =
      $year                       . '-' .
      sprintf ( '%02d' , $mon )   . '-' .
      sprintf ( '%02d' , $mday )  ;
    $where .= ' AND ' if $where ;
    $where .= 'date ( start_date ) <= date ( \'' . $this_year . '\' )' ;
  }

  # Only get events up to a particular point in time if speficied
  if ( $filter -> { to } && $filter -> { to } ne 'this-year' ) {
    $where .= ' AND ' if $where ;
    $where .= 'date ( start_date ) <= date ( \'' . $filter -> { to } . '\' )' ;
  }

  # Add a status clause if specified
  if ( $filter -> { status } && $filter -> { status } ) {
    $where .= ' AND ' if $where ;
    $where .= 'status = \'' . $filter -> { status } . '\'' ;
  }

  if ( ref $proto ) {

    # Called as object method, fetch full details for individual event

    my $self = $proto ;

    if ( $filter -> { userid } && $filter -> { userid } ) {

      $where .= ' AND ' if $where ;
      $where .=
        "society_rowid IN (
          SELECT rowid
                  FROM whatson_organisation
                 WHERE type = 'whatson_society'
                    AND rowid IN (
            SELECT organisation_rowid
              FROM whatson_contact_organisation
             WHERE person_rowid = (
              SELECT rowid
                FROM whatson_contact
               WHERE userid = :userid ) ) )" ;

    }

    my $stmt = 'SELECT * FROM whatson_event WHERE rowid = :rowid' ;
    $stmt .= ' AND ' . $where if $where ;

    my $sth = $dbh -> prepare ( $stmt ) ;

    $sth -> bind_param ( ':rowid' , $self -> rowid ) ;
    $sth -> bind_param ( ':userid' , $filter -> { userid } )
      if $filter -> { userid } ;

    $sth -> execute ;

    if ( my $row = $sth -> fetchrow_hashref ) {

      $self -> dates ( $row -> { dates } ) ;
      $self -> name ( $row -> { name } ) ;
      $self -> start_date ( $row -> { start_date } ) ;
      $self -> end_date ( $row -> { end_date } ) ;
      $self -> status ( $row -> { status } ) ;
      $self -> venue_rowid ( $row -> { venue_rowid } ) ;
      $self -> venue_name ( $row -> { venue_name } ) ;
      $self -> society_rowid ( $row -> { society_rowid } ) ;
      $self -> society_name ( $row -> { society_name } ) ;
      $self -> presented_by ( $row -> { presented_by } ) ;
      $self -> times ( $row -> { times } ) ;
      $self -> box_office ( $row -> { box_office } ) ;
      $self -> use_desc ( $row -> { use_desc } ) ;
      $self -> description ( $row -> { description } ) ;
      $self -> image ( $row -> { image } ) ;

      return 1 ; # Tell the caller it was a success

    } else {

      return 0 ; # Tell the caller it was a failure

    }


  } else {

    # Called as a class method, fetch summary for a list of events

    my $class = $proto ;

    if ( $filter -> { userid } && $filter -> { userid } ) {

      # The filter specifies a userid. This is a complicated business.
      # We need to add to the where clause date ranges based on the events
      # belonging to the member societies that the rep with this userid
      # is a member of.

      my $stmt =
        "SELECT start_date , end_date
         FROM whatson_event
         WHERE $where
          AND society_rowid IN (
              SELECT rowid
                FROM whatson_organisation
               WHERE type = 'whatson_society'
                 AND rowid IN (
                    SELECT organisation_rowid
                      FROM whatson_contact_organisation
                     WHERE person_rowid = (
                          SELECT rowid
                            FROM whatson_contact
                           WHERE userid = :userid ) ) )" ;

      my $sth = $dbh -> prepare ( $stmt ) ;

      $sth -> bind_param ( ':userid' , $filter -> { userid } ) ;

      $sth -> execute ;

      my $range = 0 ;
      while ( my $row = $sth -> fetchrow_hashref ) {

        $range++ ;

        # If we appending to a where clause, then add an AND.
        $where .= ' AND ' if $where && $range == 1 ;
        # Add an opening bracket for the ranges, this is superfluous if
        # there is only a singe date range but it does no harm.
        $where .= '( ' if $range == 1 ;
        # If this is the second or more of a number of ranges then we need
        # an OR.
        $where .= ' OR ' if $range > 1 ;
        $where .= "( date ( start_date ) <= date ( '" ;
        $where .= $row -> { end_date } ;
        $where .= "' ) AND date ( end_date ) >= date ( '" ;
        $where .= $row -> { start_date } ;
        $where .= "' )" ;
        $where .= ' )' ;
        $where .= ' )' if $range == 1 ;
      }

      if ( $range == 0 ) {

        # We haven't found any future events for this society.
        # Right now that means we're about to return future events for ALL
        # societies since we won't restrict on any overlapping date ranges!
        # Do something to stop this from happening.
        $where .= ' AND ' if $where ;
        $where .= " 'x' = 'y'" ;

      }

    }

    if ( $filter -> { society } ) {

      # Restrict to the events organised by a specific member society
      $where .= ' AND ' if $where ;
      $where .= 'society_rowid = ' . $filter -> { society } ;

    }

    # Add a limit clause if specified. We append this to the where clause
    # but strictly speaking it isn't part of the where clause but no matter.
    my $limit .= ' LIMIT ' . $filter -> { limit } if $filter -> { limit } ;

    my $stmt = 'SELECT * FROM whatson_event' ;
    $stmt .= ' WHERE ' . $where if $where ;
    $stmt .= ' ORDER BY date ( start_date ) , date ( end_date ) , rowid' ;
    $stmt .= $limit if $limit ;

    my $sth = $dbh -> prepare ( $stmt ) ;

     $sth -> execute ;

     my @events ;

     while ( my $row = $sth -> fetchrow_hashref ) {

        my $event = new DATA::WhatsOn::Event ;

        $event -> rowid ( $row -> { rowid } ) ;
        $event -> dates ( $row -> { dates } ) ;
        $event -> name ( $row -> { name } ) ;
        $event -> start_date ( $row -> { start_date } ) ;
        $event -> end_date ( $row -> { end_date } ) ;
        $event -> status ( $row -> { status } ) ;
        $event -> venue_rowid ( $row -> { venue_rowid } ) ;
        $event -> venue_name ( $row -> { venue_name } || '' ) ;
        $event -> society_rowid ( $row -> { society_rowid } ) ;
        $event -> society_name ( $row -> { society_name } || '' ) ;
        $event -> presented_by ( $row -> { presented_by } ) ;
        $event -> times ( $row -> { times } ) ;
        $event -> box_office ( $row -> { box_office } ) ;
        $event -> use_desc ( $row -> { use_desc } ) ;
        $event -> description ( $row -> { description } ) ;
        $event -> image ( $row -> { image } ) ;

        push @events , $event ;

     }

     return @events ;

  }

}

sub save {

=head3 save

Save an event to the database either as an update to an existing event or an
insert of a new event.

=cut

  my ( $self , $dbh ) = @_ ;

  my $start_date = _strtodate ( $self -> start_date ) ;

  my $end_date ;

  if ( $self -> end_date ) {

    $end_date = _strtodate ( $self -> end_date ) ;

  } else {

    $end_date = $start_date ;

  }

  my $sth ;

  if ( $self -> rowid ) {

    # This is an update

    $sth = $dbh -> prepare (

      'UPDATE event SET
        name          = :name           ,
        dates         = :dates          ,
        start_date    = :start_date     ,
        end_date      = :end_date       ,
        times         = :times          ,
        presented_by  = :presented_by   ,
        box_office    = :box_office     ,
        use_desc      = :use_desc       ,
        image         = :image          ,
        description   = :description    ,
        society_rowid = :society_rowid  ,
        venue_rowid   = :venue_rowid    ,
        status        = :status
      WHERE rowid = :rowid'

    ) ;

    $sth -> bind_param ( ':rowid' , $self -> rowid  ) ;

  } else {

    # This is an add

    if  ( $self -> venue_name && !$self -> venue_rowid ) {

      my $venue = new DATA::WhatsOn::Organisation ;
      $venue -> name ( $self -> venue_name ) ;
      $venue -> fetch ( $dbh ) ;
      $self -> venue_rowid ( $venue -> rowid ) ;

    }

    if ( $self -> society_name && !$self -> society_rowid ) {

      my $society = new DATA::WhatsOn::Organisation ;
      $society -> name ( $self -> society_name ) ;
      $society -> fetch ( $dbh ) ;
      $self -> society_rowid ( $society -> rowid ) ;

    }

    $sth = $dbh -> prepare (

      'INSERT INTO event (
        name            ,
        dates           ,
        start_date      ,
        end_date        ,
        times           ,
        presented_by    ,
        box_office      ,
        use_desc        ,
        image           ,
        description     ,
        society_rowid   ,
        venue_rowid     ,
        status
      ) VALUES (
        :name           ,
        :dates          ,
        :start_date     ,
        :end_date       ,
        :times          ,
        :presented_by   ,
        :box_office     ,
        :use_desc       ,
        :image          ,
        :description    ,
        :society_rowid  ,
        :venue_rowid    ,
        :status
      )'

    ) ;

  }

  $sth -> bind_param ( ':name'          , $self -> name           ) ;
  $sth -> bind_param ( ':dates'         , $self -> dates          ) ;
  $sth -> bind_param ( ':start_date'    , $start_date             ) ;
  $sth -> bind_param ( ':end_date'      , $end_date               ) ;
  $sth -> bind_param ( ':times'         , $self -> times          ) ;
  $sth -> bind_param ( ':presented_by'  , $self -> presented_by   ) ;
  $sth -> bind_param ( ':box_office'    , $self -> box_office     ) ;
  $sth -> bind_param ( ':use_desc'      , $self -> use_desc       ) ;
  $sth -> bind_param ( ':image'         , $self -> image          ) ;
  $sth -> bind_param ( ':description'   , $self -> description    ) ;
  $sth -> bind_param ( ':society_rowid' , $self -> society_rowid  ) ;
  $sth -> bind_param ( ':venue_rowid'   , $self -> venue_rowid    ) ;
  $sth -> bind_param ( ':status'        , $self -> status         ) ;

  $sth -> execute ;

  # Return the rowid of the event
  if ( $self -> rowid ) {
    return $self -> rowid ; # Update
  } else {
    return $dbh -> sqlite_last_insert_rowid ; # Insert
  }

}

sub delete {

=head3 delete

Delete an event from the database.

=cut

  my ( $self , $dbh ) = @_ ;

  my $sth = $dbh -> prepare (

    'DELETE FROM event WHERE rowid = ?'

  ) ;

  $sth -> execute ( $self -> rowid ) ;

}

=head2 Other methods

=cut

sub post {

=head3 post

Produce a shortened description of an event (lacking the full detail) suitable
for a post that includes the full detail via a link to the event page.

=cut

  my ( $self , $now ) = @_ ;

  my $post ; # We will build and return this

  my $start_date = new DateTime (
    year  => substr ( $self -> start_date , 6 , 4 ) ,
    month => substr ( $self -> start_date , 3 , 2 ) ,
    day   => substr ( $self -> start_date , 0 , 2 )
  ) ;

  my $end_date = new DateTime (
    year  => substr ( $self -> end_date , 6 , 4 ) ,
    month => substr ( $self -> end_date , 3 , 2 ) ,
    day   => substr ( $self -> end_date , 0 , 2 )
  ) ;

  my $days_ahead  =
    ( $start_date -> subtract_datetime_absolute ( $now ) ) ->
      in_units ( 'seconds' ) / ( 60 * 60 * 24 ) ;

  my $rel_who ; # Relationship between event and an organisation

  if ( $self -> presented_by ) {

    if ( $self -> presented_by =~ /^"(.+)"$/ ) {

      $rel_who = lcfirst $1 ;

    } else {

      $rel_who = 'presented by ' . $self -> presented_by ;

    }

  } else {

    $rel_who = 'presented by ' . $self -> society_name ;

  }

  my $rel_who_where = $rel_who . ' at ' . $self -> venue_name ; # Adds venue

  if ( $days_ahead > 7 ) {

    # We are more than one week out from the start date

    if ( $self -> end_date eq $self -> start_date ) {

      $post = $self -> name . ' will be ' . $rel_who_where . ' on ' .
        $self -> start_date ;

    } else {

      $post = $self -> name . ' will be ' . $rel_who_where . ' from ' .
        $self -> start_date . ' to ' . $self -> end_date ;

    }

  } elsif ( $days_ahead < 7 && $days_ahead > 1 ) {

    if ( $self -> end_date eq $self -> start_date ) {

      $post = $self -> name . ' will be ' . $rel_who_where . ' on ' .
        $start_date -> day_name ;

    } else {

      $post = $self -> name . ' will be ' . $rel_who_where . ' from ' .
        $start_date -> day_name . ' to ' . $end_date -> day_name ;

    }

  } elsif ( $days_ahead == 1 ) {

    if ( $self -> end_date eq $self -> start_date ) {

      $post = $self -> name . ' will be ' . $rel_who_where . ' tomorrow' ;

    } else {

      $post = $self -> name . ' will be ' . $rel_who_where . ' from tomorrow' ;

    }

  } elsif ( $days_ahead == 0 ) {

    if ( $self -> end_date eq $self -> start_date ) {

      $post = $self -> name . ' will be ' . $rel_who_where . ' today' ;

    } else {

      $post = $self -> name . ' will be ' . $rel_who_where . ' from today' ;

    }

  } elsif ( $days_ahead < 0 ) {

    $post = 'Still time to catch ' . $self -> name . ' ' .
      $rel_who_where . ' - don\'t miss it!' ;

  }

  return ( $post , $days_ahead ) ;

}

1 ;

__END__
