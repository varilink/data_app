package SiteFunk::Auth::User::Role ;

use strict ;
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

sub userid {

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

	my $self = shift ;
	if ( @_ ) { $self -> { ROLE } = shift }
	return $self -> { ROLE } ;

}

sub fetch {

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

		my $user_role = new SiteFunk::Auth::User::Role ;

		$user_role -> _fetched	( 1 							) ;
		$user_role -> userid		( $row -> { userid	}	) ;
		$user_role -> role		( $row -> { role		}	) ;

		push @user_roles , $user_role ;

	}

	return @user_roles ;

}

sub save {

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
