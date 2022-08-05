package SiteFunk::WhatsOn::Contact::Organisation ;

=head1 SiteFunk::WhatsOn::Contact::Organsiation

Class for handling the organisations associated with a contact. See class
SiteFunk::WhatsOn::Organisation::Contact for the complementary class for
handling contacts associated with an organisation.

=cut

use strict ;
use Carp ;

# Define class variable so that person rowid doesn't have to be set for every
# object instance for the same person.
our $person_rowid ;

sub new {

   my $proto = shift ;
   my $class = ref ( $proto ) || $proto ;
   my $self = { } ;

	# Rowids = foreign keys to person and organisation parents
   $self -> { PERSON_ROWID } = undef ;
   $self -> { ORGANISATION_ROWID } = undef ;
	# Business data values
	$self -> { ROLE } = '' ;
	$self -> { STATUS } = '' ;
   $self -> { PRIMARY_CONTACT } = 0 ;
   $self -> { NAME } = '' ;
	# Special flags to ensure the correct CRUD operation
	$self -> { FETCHED } = 0 ;
	$self -> { DELETE } = 0 ;

   bless ( $self , $class ) ;
   return $self ;

}

sub person_rowid {

	my $proto = shift ;

	if ( ref $proto ) {

		# Called as object method

		my $self = $proto ;
	   if ( @_ ) { $self -> { PERSON_ROWID } = shift }
	   return $self -> { PERSON_ROWID } ;

	} else {

		# Called as class method
		if ( @_ ) { $person_rowid = shift }
		return $person_rowid ;

	}

}

sub organisation_rowid {

   my $self = shift ;
   if ( @_ ) { $self -> { ORGANISATION_ROWID } = shift }
   return $self -> { ORGANISATION_ROWID } ; 
}

sub role {

   my $self = shift ;
   if ( @_ ) { $self -> { ROLE } = shift }
   return $self -> { ROLE } ; 
}

sub status {

   my $self = shift ;
   if ( @_ ) { $self -> { STATUS } = shift }
   return $self -> { STATUS } ; 
}

sub primary_contact {

   my $self = shift ;
   if ( @_ ) { $self -> { PRIMARY_CONTACT } = shift }
   return $self -> { PRIMARY_CONTACT } ;

}

sub name {

   my $self = shift ;
   if ( @_ ) { $self -> { NAME } = shift }
   return $self -> { NAME } ;

}

sub delete {

   my $self = shift ;
   if ( @_ ) { $self -> { DELETE } = shift }
   return $self -> { DELETE } ;

}

sub _fetched {

	# Note that this method is not for use outside of this package

	my $self = shift ;
   if ( @_ ) { $self -> { FETCHED } = shift }
	return $self -> { FETCHED } ;

}

sub fetch {

	my ( $class , $dbh ) = @_ ;

	if ( ref $class ) { confess 'Class method called as object method' }

	my $sth = $dbh -> prepare (

		'SELECT *
		   FROM whatson_contact_organisation
		  WHERE person_rowid = :person_rowid'

	) ;

	$sth -> bind_param ( ':person_rowid' , $person_rowid ) ;

	$sth -> execute ;

	my @organisations = ( ) ;

	while ( my $row = $sth -> fetchrow_hashref ) {

		my $organisation = new SiteFunk::WhatsOn::Contact::Organisation ;

		$organisation -> person_rowid ( $row -> { person_rowid } ) ;
		$organisation -> organisation_rowid ( $row -> { organisation_rowid } ) ;
		$organisation -> role ( $row -> { role } ) ;
		$organisation -> status ( $row -> { status } ) ;
		$organisation -> primary_contact ( $row -> { primary_contact } ) ;
		$organisation -> name ( $row -> { name } ) ;
		$organisation -> _fetched ( 1 ) ;

		push @organisations , $organisation ;

	}

	return @organisations ;

}

sub save {

	my ( $self , $dbh ) = @_ ;

	my $this_person_rowid ;

	# If this object instance has person_rowid set then use it, otherwise use the
	# value of the class variable $person_rowid
	$self -> person_rowid
		? ( $this_person_rowid = $self -> person_rowid )
		: ( $this_person_rowid = $person_rowid ) ;

	# We MUST now have a person_rowid by one means or another so croak if not

	croak "Missing person_rowid for whatson_contact_organisation insert!"
		if !$this_person_rowid ;

	if ( $self -> _fetched && !$self -> delete ) {

		# Fetched and not marked for deletion so update in the database

		my $sth = $dbh -> prepare (

			'UPDATE whatson_contact_organisation
			    SET role					= :role ,
			        status					= :status ,
			        primary_contact		= :primary_contact
			  WHERE person_rowid			= :person_rowid
			    AND organisation_rowid = :organisation_rowid'

		) ;

		$sth -> bind_param ( ':person_rowid' , $this_person_rowid ) ;
		$sth -> bind_param (
			':organisation_rowid' , $self -> organisation_rowid
		) ;
		$sth -> bind_param ( ':role' , $self -> role ) ;
		$sth -> bind_param ( ':status' , $self -> status ) ;
		$sth -> bind_param ( ':primary_contact' , $self -> primary_contact ) ;

		$sth -> execute ;

	} elsif ( $self -> _fetched && $self -> delete ) {

		# Fetched and marked for deletion so delete from the database

	} elsif ( !$self -> _fetched && !$self -> delete ) {

		# Not fetched and not marked for deletion so insert in to the database

		my $sth = $dbh -> prepare (

			'INSERT
			   INTO whatson_contact_organisation (
				        person_rowid        ,
			           organisation_rowid  ,
                    role                ,
                    status              ,
			           primary_contact     ,
                    name
		  ) VALUES (  :person_rowid       ,
		              :organisation_rowid ,
		              :role               ,
		              :status             ,
		              :primary_contact    ,
                    :name
		  )'

		) ;

		$sth -> bind_param ( ':person_rowid' , $this_person_rowid ) ;
		$sth -> bind_param (
			':organisation_rowid' , $self -> organisation_rowid
		) ;
		$sth -> bind_param ( ':role' , $self -> role ) ;
		$sth -> bind_param ( ':status' , $self -> status ) ;
		$sth -> bind_param ( ':primary_contact' , $self -> primary_contact ) ;
		$sth -> bind_param ( ':name' , $self -> name ) ;

		$sth -> execute ;

	}

}

1 ;

__END__
