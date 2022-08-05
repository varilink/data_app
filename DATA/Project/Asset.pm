package DATA::Project::Asset ;

=head1 DATA::Project::Asset

=cut

use strict ;

sub new {

=head2 new

=cut

	my $proto = shift ;
	my $class = ref $proto || $proto ;
	my $self = { } ;
	$self -> { NAME } = undef ;
	$self -> { PATH } = undef ;
	# name can be set by the constructor if passed as a parameter
	if ( @_ ) { $self -> { SITENAME } = shift }
	else { $self -> { SITENAME } = undef } ;

	bless $self , $class ;
	return $self ;

}

sub content {

	my $self = shift ;
	if ( @_ ) {
		my ( $input , $type ) = @_ ;
		$self -> { CONTENT } = $input ;
	}
	return $self -> { CONTENT } ; 

}

sub name {

	my $self = shift ;
	if ( @_ ) { $self -> { NAME } = shift }
	return $self -> { NAME } ;

}

sub path {

	my $self = shift ;
	if ( @_ ) { $self -> { PATH } = shift }
	return $self -> { PATH } ;

}

sub sitename {

	my $self = shift ;
	if ( @_ ) { $self -> { SITENAME } = shift }
	return $self -> { SITENAME } ;

}

1 ;

__END__
