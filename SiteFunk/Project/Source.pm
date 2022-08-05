package SiteFunk::Project::Source ;

=head1 SiteFunk::Project::Source

=cut

use strict ;
use Env qw / HOME / ;
use Cwd ;
use File::Basename ;
use File::Path qw / make_path / ;

use SiteFunk::Project::Source::Parser ;

sub new {

=head2 new

=cut

	my $proto = shift ;
	my $class = ref $proto || $proto ;
	my $self = { } ;
	$self -> { CONTENT } = ( ) ;
	$self -> { NAME } = undef ;
	$self -> { PATH } = undef ;
	$self -> { MODE } = undef ;
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

sub mode {

	my $self = shift ;
	if ( @_ ) { $self -> { MODE } = shift }
	return $self -> { MODE } ;

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

sub output {

	my ( $self , $output ) = @_ ;

	my $name = $self -> name ;
	my $path = $self -> path ;

	my $sitename = $self -> sitename ;

	my $out ;

	if ( $self -> type eq 'page' ) {

		my $run_mode = $self -> run_mode ;
		$out = "$HOME/vhosts/$sitename/$path$run_mode.tt" ;

	} elsif ( $self -> type eq 'partial' ) {

		$out = "$HOME/vhosts/$sitename/$path$name.tt" ;

	}

	my $dir = dirname ( $out ) ;

	make_path ( $dir ) ;

	open TT , '>' , $out ;

	print TT $output ;
	
	close TT ;	

}

sub type {

	my $self = shift ;

	my $type ;

	if ( $self -> path =~ /^src\/partials/ ) { $type = 'partial' }
	elsif ( $self -> path =~ /^src\/pages/ ) { $type = 'page' }

	return $type ;

}

sub load {

	my ( $self , $file ) = @_ ;

	my $pwd = cwd ;

	my ( $name , $path , $suffix ) = fileparse ( $pwd . '/' . $file , '.html' ) ;

	my $root = $HOME . '/Projects/' . $self -> sitename ;

	$path =~ /$root\/(.*)/ ;

	my $relpath = $1 ;

	open GULP , $file ;
	my @lines = <GULP> ;
	close GULP ;

	$self -> name ( $name ) ;
	$self -> path ( $relpath ) ;
	$self -> content ( \@lines ) ;

}

sub template {

	my $self = shift ;

	return parse ( $self ) ;

}

1 ;

__END__
