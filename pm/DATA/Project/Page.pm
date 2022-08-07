package DATA::Project::Page ;

=head1 DATA::Project::Page

=cut

use strict ;

use base qw / DATA::Project::Source / ;

sub role {

	my $self = shift ;

	my $role = undef ;

	if ( $self -> path =~ /src\/pages\/secure\/(\w+)\// ) { $role = $1 }

	return $role ;

}

sub run_mode {

	my $self = shift ;

	my $run_mode ;

	if ( $self -> role ) { $run_mode = $self -> role . '_' . $self -> name }
	else { $run_mode = $self -> name } ;

	return $run_mode ;

}

1 ;

__END__
