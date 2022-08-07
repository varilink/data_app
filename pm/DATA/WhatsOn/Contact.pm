package DATA::WhatsOn::Contact ;

use Carp ;
use strict ;
use warnings ;

use DATA::WhatsOn::Organisation ;
use DATA::WhatsOn::Contact::Organisation ;

use String::Random ;

sub _secret {

	# Internal method that is called whenever we want a secret string
	my $string = new String::Random ;
	my $secret = $string -> randregex ( '[a-z0-9]{20}' ) ;
	return $secret ;

}

sub new {

   my $proto = shift ;
   my $class = ref ( $proto ) || $proto ;
   my $self = { } ;
   $self -> { ROWID } = undef ;
   $self -> { EMAIL } = '' ;
   $self -> { FIRST_NAME } = '' ;
   $self -> { SURNAME } = '' ;
	$self -> { SUBSCRIBER } = 0 ;
	$self -> { SECRET } = '' ;
   $self -> { TITLE } = '' ;
   $self -> { TELEPHONE } = '' ;
   $self -> { ADDRESS1 } = '' ;
   $self -> { ADDRESS2 } = '' ;
   $self -> { ADDRESS3 } = '' ;
   $self -> { ADDRESS4 } = '' ;
   $self -> { POSTCODE } = '' ;
	$self -> { ROLE } = '' ;
	$self -> { PRIMARY_CONTACT } = 0 ;
   $self -> { ORGANISATIONS } = [ ] ;

   bless ( $self , $class ) ;
   return $self ;

}

sub rowid {

   my $self = shift ;
   if ( @_ ) { $self -> { ROWID } = shift }
   return $self -> { ROWID } ;

}

sub email {

   my $self = shift ;
   if ( @_ ) { $self -> { EMAIL } = shift }
   return $self -> { EMAIL } ; 
}

sub first_name {

   my $self = shift ;
   if ( @_ ) { $self -> { FIRST_NAME } = shift }
   return $self -> { FIRST_NAME } ;

}

sub surname {

   my $self = shift ;
   if ( @_ ) { $self -> { SURNAME } = shift }
   return $self -> { SURNAME } ;

}

sub subscriber {

	my $self = shift ;
	if ( @_ ) { $self -> { SUBSCRIBER } = shift }
	return $self -> { SUBSCRIBER } ;

}

sub secret {

	my $self = shift ;
	if ( @_ ) { $self -> { SECRET } = shift }
	return $self -> { SECRET } ;

}

sub title {

   my $self = shift ;
   if ( @_ ) { $self -> { TITLE } = shift }
   return $self -> { TITLE } ;

}

sub telephone {

   my $self = shift ;
   if ( @_ ) { $self -> { TELEPHONE } = shift }
   return $self -> { TELEPHONE } ;

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

sub role {

=head3 role

The role of a contact in an organisation. Where contacts are fetched for a
single organisation, the role within the organisation is merged in to the
contact object.

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { ROLE } = shift }
   return $self -> { ROLE } ; 
}

sub primary_contact {

=head3 primary_contact

Whether a contact is the primary contact for an organisation or not. Where
contacts are fetched for a single organisation, this flag is merged in to the
contact object.

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { PRIMARY_CONTACT } = shift }
   return $self -> { PRIMARY_CONTACT } ; 
}

sub organisations {

=head3 organisations

Sets or returns a reference to an array containing object instances of
DATA::WhatsOn::Contact::Organisation

=cut

   my $self = shift ;
   if ( @_ ) { $self -> { ORGANISATIONS } = shift }
   return $self -> { ORGANISATIONS } ; 

}

sub add_org {

=head3 add_org

=cut

	my $self	= shift					;	# Contact object
	my $org_in		= shift			;	# Name of organisation supplied
	my $role_in		= shift if @_	;	# Role supplied (optional)

	my $existing_relationship = 0 ;
	my @orgs = ( ) ;

	foreach my $org ( @{ $self -> organisations } ) {

		if ( $org -> name eq $org_in ) {

			$org -> role ( $role_in ) if $role_in ;
			$existing_relationship = 1 ;

		}

		push @orgs , ( $org ) ;

	}

	unless ( $existing_relationship ) {

		my $org = new DATA::WhatsOn::Contact::Organisation ;
		$org -> person_rowid ( $self -> rowid ) if $self -> rowid ;
		$org -> name ( $org_in ) ;
		$org -> role ( $role_in) if $role_in ;
		push @orgs , ( $org ) ;

	}

	$self -> organisations ( \@orgs ) ;

}

sub as_hash {

=head3 as_hash

Returns the contact as an unblessed hash with lower case keys

=cut

	my $self = shift ;

	my %contact = %{ $self } ;
	tie my %hash , 'Hash::Case::Lower' , \%contact ;

	my @organisations ;

	foreach my $organisation ( @{ $hash { 'organisations' } } ) {

		my %organisation = %{ $organisation } ;
		tie my %subhash , 'Hash::Case::Lower' , \%organisation ;
		push @organisations , \%subhash ;

	}

	@{ $hash { 'organisations' } } = @organisations ;

	return %hash ;

}

sub load {

   my ( $class , $path , $dbh ) = @_ ;

   if ( ref $class ) { confess 'Class method called as object method' }

	my (
		$email , $first_name , $name , $org_name , $primary_contact , $role ,
		$surname , $title
	) ;

   open my $fh , '<' , $path ;

	my $rec = <$fh> ;

	my $process_rec = sub {

		chomp $rec ;

		( $email , $name , $title , $role , $primary_contact , $org_name )
			= split /\|/ , $rec ;
		$name =~ /^(.*)\s([\w\-]*?)$/ ;
		( $first_name , $surname ) = ( $1 , $2 ) ;

		return 1 ;

	} ;

CON:

	while ( $rec && &$process_rec ) {

		# Parse record

		# Create Contact
		my $con = new DATA::WhatsOn::Contact ; 
		$con -> email ( $email ) ;
		$con -> first_name ( $first_name ) ;
		$con -> surname ( $surname ) ;
		$con -> title ( $title ) ;

		# Set sensible default values for new fields
		$con -> subscriber ( 1 ) ;
		$con -> secret ( &_secret ) ;

		my $prev_email = $email ;

CON_ORG:

		my @con_orgs = ( ) ;			

		while ( $rec && &$process_rec && $email eq $prev_email ) {

			if ( $org_name ne '' ) {

				# Create contact organisation
				my $con_org = new DATA::WhatsOn::Contact::Organisation ;
				$con_org -> name ( $org_name ) ;
				$con_org -> role ( $role ) ;
				$con_org -> primary_contact ( $primary_contact ) ;

				push @con_orgs , ( $con_org ) ;

			}

			$rec = <$fh> ;

		} # End CON_ORG

		$con -> organisations ( \@con_orgs ) ; # Always pass an array reference

		$con -> save ( $dbh ) ;

	} # End CON

   close $fh ;

}

sub fetch {

=head3 fetch

=cut

	my $proto = shift ; # Can be an object or class
	my $dbh = shift ;

	#
	# Filter should be a hash reference that optionally contains values for
	# the following keys
	#
	# org_id:
	# The organisation that the contact must be in.
	#

	my $filter = shift if @_ ;

   my $sth ;

	if ( ref $proto ) {

		# Called as object, fetch an individual contact
		my $self = $proto ;

	   if ( $self -> rowid ) {

   	   $sth = $dbh -> prepare (

   	      'SELECT *
   	         FROM whatson_contact
   	        WHERE rowid = :rowid'

   	   ) ;

	      $sth -> bind_param ( ':rowid' , $self -> rowid ) ;

	   } elsif ( $self -> email ) {

	      $sth = $dbh -> prepare (

	         'SELECT rowid , *
	            FROM whatson_contact
	           WHERE email = :email'

			) ;

	      $sth -> bind_param ( ':email' , $self -> email ) ;

	   } elsif ( $self -> surname && $self -> first_name ) {

			# This is a dangerous option of last resort. It is susceptible to
			# error if we have two entries with the same surname and first_name.

			$sth = $dbh -> prepare (

				'SELECT rowid, *
				   FROM whatson_contact
				  WHERE first_name = :first_name
				    AND surname = :surname'

			) ;

			$sth -> bind_param ( ':surname' , $self -> surname ) ;
			$sth -> bind_param ( ':first_name' , $self -> first_name ) ;

		}

	   $sth -> execute ;

	   my $row ;

	   return 0 unless $row = $sth -> fetchrow_hashref ;

	   $self -> rowid			( $row -> { rowid			} ) ;
	   $self -> email			( 
		$row -> { email } ? $row -> { email } : '' ) ; # Convert null to empty string
	   $self -> first_name	( $row -> { first_name	} ) ;
	   $self -> surname		( $row -> { surname		} ) ;
	   $self -> subscriber	( $row -> { subscriber	} ) ;
	   $self -> secret   	( $row -> { secret	} ) ;
	   $self -> title			( $row -> { title			} ) ;
	   $self -> telephone	( $row -> { telephone	} ) ;
   	$self -> address1		( $row -> { address1		} ) ;
   	$self -> address2		( $row -> { address2		} ) ;
   	$self -> address3		( $row -> { address3		} ) ;
   	$self -> address4		( $row -> { address4		} ) ;
   	$self -> postcode		( $row -> { postcode		} ) ;

		unless ( $filter -> { no_orgs } ) {

			DATA::WhatsOn::Contact::Organisation
				-> person_rowid ( $self -> rowid ) ;

			my @organisations = DATA::WhatsOn::Contact::Organisation
				-> fetch ( $dbh ) ;

			$self -> organisations ( \@organisations ) ;

		}

		return 1 ;

	} else {

		# Called as a class, fetch a list of contacts

		my $class = $proto ;

		my $sth ;
		
		if ( $filter -> { org_id } ) {

			$sth = $dbh -> prepare (

				'SELECT con.rowid								AS rowid					,
				        con.email								AS email					,
				        con.first_name						AS first_name			,
				        con.surname							AS surname				,
				        con.subscriber						AS subscriber			,
				        con.secret							AS secret				,
				        con.title								AS title					,
				        con.telephone						AS telephone			,
	   	           con.address1							AS address1				,
				        con.address2							AS address2				,
				        con.address3							AS address3				,
				        con.address4							AS address4				,
				        con.postcode							AS postcode				,
				        org.role								AS role					,
				        org.primary_contact				AS primary_contact
				   FROM whatson_contact						con						,
				        whatson_contact_organisation	org
				  WHERE con.rowid = org.person_rowid
				    AND org.organisation_rowid = :org_id_in
			  ORDER BY con.surname , con.first_name
				'

			) ;	

	      $sth -> bind_param ( ':org_id_in' , $filter -> { org_id } ) ;

		} else {

			# No parameters pass, so return a list of all contacts

			$sth = $dbh -> prepare (

				'SELECT con.rowid								AS rowid					,
				        con.email								AS email					,
				        con.first_name						AS first_name			,
				        con.surname							AS surname				,
				        con.subscriber						AS subscriber			,
				        con.secret							AS secret				,
				        con.title								AS title					,
				        con.telephone						AS telephone			,
	   	           con.address1							AS address1				,
				        con.address2							AS address2				,
				        con.address3							AS address3				,
				        con.address4							AS address4				,
				        con.postcode							AS postcode          ,
				        null									AS role					,
				        null									AS primary_contact
				   FROM whatson_contact con
			  ORDER BY con.surname , con.first_name
				'

			) ;	

		}

		$sth -> execute ;

		my @contacts ;

		while ( my $row = $sth -> fetchrow_hashref ) {

			my $contact = new DATA::WhatsOn::Contact ;

		   $contact -> rowid					( $row -> { rowid					} ) ;
		   $contact -> email	
				( $row -> { email	} ? $row -> { email } : '' ) ;
		   $contact -> first_name			( $row -> { first_name			} ) ;
		   $contact -> surname				( $row -> { surname				} ) ;
		   $contact -> subscriber			( $row -> { subscriber			} ) ;
		   $contact -> secret				( $row -> { secret				} ) ;
		   $contact -> title					( $row -> { title					} ) ;
		   $contact -> telephone			( $row -> { telephone			} ) ;
			$contact -> address1				( $row -> { address1				} ) ;
			$contact -> address2				( $row -> { address2				} ) ;
			$contact -> address3				( $row -> { address3				} ) ;
			$contact -> address4				( $row -> { address4				} ) ;
			$contact -> postcode 		   ( $row -> { postcode				} ) ;
			$contact -> role					( $row -> { role					} ) ;
			$contact -> primary_contact	( $row -> { primary_contact	} ) ;

			# Move this to the main query perhaps as something smarter?
			unless ( $filter -> { no_orgs } ) {

				DATA::WhatsOn::Contact::Organisation
					-> person_rowid ( $contact -> rowid ) ;

				my @organisations = DATA::WhatsOn::Contact::Organisation
					-> fetch ( $dbh ) ;

				$contact -> organisations ( \@organisations ) ;

			}

			push @contacts , $contact ;

		}

		return @contacts ;

	}

}

sub save {

	my ( $self , $dbh ) = @_ ;

	if ( $self -> rowid ) {

		# This is an update

		my $sth = $dbh -> prepare (

			'UPDATE whatson_contact
             SET email      = :email      ,
                 first_name = :first_name ,
                 surname    = :surname    ,
                 subscriber = :subscriber ,
			        secret     = :secret     ,
                 title      = :title      ,
                 telephone  = :telephone  ,
                 address1   = :address1   ,
                 address2   = :address2   ,
                 address3   = :address3   ,
                 address4   = :address4   ,
                 postcode   = :postcode
           WHERE rowid = :rowid'

		) ;

		$sth -> bind_param ( ':rowid'			, $self -> rowid			) ;

		# Convert empty string to undef before storing it to get a null value in
		# the database. This is necessary because email is unique in the database
		# and so storing as empty strings would conflict with that constraint.		
		$sth -> bind_param (
			':email'	, $self -> email ? $self -> email : undef	) ;
		$sth -> bind_param ( ':first_name'	, $self -> first_name	) ;
		$sth -> bind_param ( ':surname'		, $self -> surname		) ;
		$sth -> bind_param ( ':subscriber'	, $self -> subscriber	) ;
		$sth -> bind_param ( ':secret'		, $self -> secret			) ;
		$sth -> bind_param ( ':title'			, $self -> title			) ;
		$sth -> bind_param ( ':telephone'	, $self -> telephone		) ;
		$sth -> bind_param ( ':address1'		, $self -> address1		) ;
		$sth -> bind_param ( ':address2'		, $self -> address2		) ;
		$sth -> bind_param ( ':address3'		, $self -> address3		) ;
		$sth -> bind_param ( ':address4'		, $self -> address4		) ;
		$sth -> bind_param ( ':postcode'		, $self -> postcode		) ;

		$sth -> execute ;

		DATA::WhatsOn::Contact::Organisation
			-> person_rowid ( $self -> rowid ) ;

		foreach my $con_org ( @{ $self -> organisations } ) {
			$con_org -> save ( $dbh ) ;
		} ;


	} else {

		# This is an insert

		my $sth = $dbh -> prepare (

			'INSERT
			   INTO whatson_contact (
			           email       ,
                    first_name  ,
			           surname     ,
			           subscriber  ,
			           secret      ,	
			           title       ,
			           telephone   ,
			           address1    ,
			           address2    ,
			           address3    ,
			           address4    ,
			           postcode
		  ) VALUES (  :email      ,
			           :first_name ,
			           :surname    ,
			           :subscriber ,
		              :secret     ,
			           :title      ,
			           :telephone  ,
			           :address1   ,
			           :address2   ,
			           :address3   ,
			           :address4   ,
			           :postcode
		  )'

		) ;

		# Convert to empty string to undef before storing it to get a null value		
		$sth -> bind_param (
			':email'	, $self -> email ? $self -> email : undef	) ;
		$sth -> bind_param ( ':first_name'	, $self -> first_name	) ;
		$sth -> bind_param ( ':surname'		, $self -> surname		) ;
		$sth -> bind_param ( ':subscriber'	, $self -> subscriber	) ;
		$sth -> bind_param ( ':secret'		, $self -> secret			) ;
		$sth -> bind_param ( ':title'			, $self -> title			) ;
		$sth -> bind_param ( ':telephone' 	, $self -> telephone		) ;
		$sth -> bind_param ( ':address1'  	, $self -> address1		) ;
		$sth -> bind_param ( ':address2'  	, $self -> address2		) ;
		$sth -> bind_param ( ':address3'  	, $self -> address3		) ;
		$sth -> bind_param ( ':address4'  	, $self -> address4		) ;
		$sth -> bind_param ( ':postcode'  	, $self -> postcode		) ;

		$sth -> execute ;

		$self -> fetch ( $dbh , { no_orgs => 1 } ) ;

		DATA::WhatsOn::Contact::Organisation
			-> person_rowid ( $self -> rowid ) ;

		foreach my $con_org ( @{ $self -> organisations } ) {

			my $organisation = new DATA::WhatsOn::Organisation ;
			$organisation -> name ( $con_org -> name ) ;
			$organisation -> fetch ( $dbh ) ;
			$con_org -> organisation_rowid ( $organisation -> rowid ) ;			
			$con_org -> save ( $dbh ) ;

		} ;

	}

}

sub list {

   my $class = shift ;
   my $dbh = shift ;

   if ( ref $class ) { confess "Class method called as object method" }

   my $sth ;

   if ( @_ ) {

      my $society_fk = shift ;

      $sth = $dbh -> prepare (

         'SELECT contact.rowid ,
                 contact.name ,
                 contact.email ,
                 society_contact.lead
            FROM whatson_contact ,
                 whatson_society_contact
           WHERE society_contact.society_fk = ?
             AND contact.rowid = society_contact.contact_fk
        ORDER BY contact.name'

      ) ;

      $sth -> bind_param ( 1 , $society_fk ) ;

      $sth -> execute ;

   } else {

      $sth = $dbh -> prepare (
   
         'SELECT rowid , *
            FROM whatson_contact
        ORDER BY name'

      ) ;

      $sth -> execute ;

   }

   my @contacts ;

   while ( my $row = $sth -> fetchrow_hashref ) {

      my $contact = new DATA::WhatsOn::Contact ;

      $contact -> rowid ( $row -> { rowid } ) ;
      $contact -> email ( $row -> { email } ) ;
      $contact -> name ( $row -> { name } ) ;
      $contact -> organisation ( $row -> { organisation } ) ;
      $contact -> title ( $row -> { title } ) ;

      push @contacts , $contact ;

   }

   return @contacts ;

}

sub representative {

=head3 representative

Tests if an email address corresponds to a known representative of one or more
member socities. Returs true if it does and false if it doesn't.

=cut

	my ( $self , $dbh ) = @_ ;

	my $sth = $dbh -> prepare (

		'SELECT NULL
		   FROM whatson_organisation				org    	,
		        whatson_contact_organisation	con_org	,
		        whatson_contact						con
		  WHERE con.email 				= :email
		    AND con_org.person_rowid	= con.rowid
		    AND org.rowid					= con_org.organisation_rowid
		    AND org.type					= \'whatson_society\''

   ) ;

   $sth -> bind_param ( ':email' , $self -> email ) ;

   $sth -> execute ;

   $sth -> fetchrow_hashref
		? return 1
		: return 0 ;

}

sub committee_member {

=head3 committee_member

Tests if an email address corresponds to a known DATA committee member.

=cut

	my ( $self , $dbh ) = @_ ;

	my $sth = $dbh -> prepare (

		'SELECT NULL
		   FROM whatson_organisation				org    	,
		        whatson_contact_organisation	con_org	,
		        whatson_contact						con
		  WHERE con.email 				= :email
		    AND con_org.person_rowid	= con.rowid
		    AND con_org.role IN (
		        \'Secretary\' , \'Treasurer\' , \'Chairman\' , \'Committee\' )
		    AND org.rowid					= con_org.organisation_rowid
		    AND org.name					= \'DATA\'
		    AND org.type					= \'whatson_organisation\''

   ) ;

   $sth -> bind_param ( ':email' , $self -> email ) ;

   $sth -> execute ;

   $sth -> fetchrow_hashref
		? return 1
		: return 0 ;

}




sub add {

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'INSERT
         INTO whatson_contact (
                 email ,
                 first_name ,
                 surname ,
                 title
     ) VALUES ( ?1 , ?2 , ?3 , ?4 )'

   ) ;

	$sth -> bind_param ( 1 , $self -> email ) ;
	$sth -> bind_param ( 2 , $self -> first_name ) ;
	$sth -> bind_param ( 3 , $self -> surname ) ;
	$sth -> bind_param ( 4 , $self -> title ) ;

   $sth -> execute ;

	$self -> fetch ( $dbh ) ;

	foreach my $con_in_org ( @{ $self -> organisations } ) {

		$sth = $dbh -> prepare (

			'INSERT
            INTO whatson_contact_organisation (
                    person_rowid          ,
                    organisation_rowid    ,
                    role                  ,
                    primary_contact
        ) VALUES ( ?1 , ?2 , ?3 , ?4 )'

		) ;

		my $organisation = new DATA::WhatsOn::Organisation ;
		$organisation -> name ( $con_in_org -> name ) ;
		$organisation -> fetch ( $dbh ) ;

		$sth -> bind_param ( 1 , $self -> rowid ) ;
		$sth -> bind_param ( 2 , $organisation -> rowid ) ;
		$sth -> bind_param ( 3 ,
			$con_in_org -> role ? $con_in_org -> role : undef
		) ;
      $sth -> bind_param ( 4 , $con_in_org -> primary_contact ) ;

	   $sth -> execute ;

	}

}

sub update {

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'UPDATE whatson_contact
          SET name         = ? ,
              email        = ? ,
              organisation = ?
        WHERE rowid = ?'

   ) ;

   $sth -> execute (
      $self -> name ,
      $self -> email ,
      $self -> organisation ,
      $self -> rowid
   ) ;

}

sub delete {

   my ( $self , $dbh ) = @_ ;

   my $sth = $dbh -> prepare (

      'DELETE
         FROM whatson_contact
        WHERE rowid = ?'

   ) ;

   $sth -> execute ( $self -> rowid ) ;

}

1 ;

__END__
