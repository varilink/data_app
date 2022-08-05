package SiteFunk::Project ;

=head1 SiteFunk::Project

A Foundation Project

=cut

use strict ;

use Env qw / HOME / ;
use Config::General ;
use Cwd ;
use File::Basename ;
use File::Find ;
use File::Path qw / make_path remove_tree / ;

use SiteFunk::Project::Image ;
use SiteFunk::Project::Javascript ;
use SiteFunk::Project::Layout ;
use SiteFunk::Project::Page ;
use SiteFunk::Project::Partial ;
use SiteFunk::Project::Stylesheet ;

use YAML qw / LoadFile / ;

sub _isHTML {

	my $file = shift ;

	if ( -f $file ) {

		my $pwd = cwd ;

		my ( $name , $path , $suffix )
			= fileparse ( $pwd . '/' . $file , '.html' ) ;

		$suffix eq '.html' ? return 1 : return undef ;

	} else {

	return undef ;

	}

}

sub new {

=head2 new

=cut

	my $proto = shift ;
	my $class = ref $proto || $proto ;

	my $self = { } ;

	# name can be set by the constructor if passed as a parameter
	if ( @_ ) {
		$self -> { NAME } = shift
	} else {
		$self -> { NAME } = undef
	} ;
	$self -> { MODE } = undef ;
	$self -> { IMAGES } = [ ] ;
	$self -> { JAVASCRIPTS } = [ ] ;
	$self -> { LAYOUTS } = [ ] ;
	$self -> { PAGES } = [ ] ;
	$self -> { PARTIALS } = [ ] ;
	$self -> { STYLESHEETS } = [ ] ;

	bless $self , $class ;
	return $self ;

}

sub name {

=head2 name

The name of the project

=cut

	my $self = shift ;
	if ( @_ ) { $self -> { NAME } = shift }
	return $self -> { NAME } ;

}

sub mode {

=head2 mode

The mode, which is one of deploy or test

=cut

	my $self = shift ;
	if ( @_ ) { $self -> { MODE } = shift }
	return $self -> { MODE } ;

}

sub images {

=head2 images

=cut

	my $self = shift ;
	my $sitename = $self -> name ;

	sub _image {

		my $file = $_ ;

		if ( -f $file ) {

			my $image = new SiteFunk::Project::Image ( $sitename ) ;
			$image -> load ( $file ) ;
			push @{ $self -> { IMAGES} } , $image ;

		} 

	} # end of the subroutine _image

	unless ( @{ $self -> { IMAGES } } ) {

		find ( \&_image , "$HOME/Projects/$sitename/dist/assets/img" ) ;

	}

	return @{ $self -> { IMAGES } } ;

}

sub javascripts {

=head2 javascripts

=cut

	my $self = shift ;
	my $sitename = $self -> name ;

	sub _javascript {

		my $file = $_ ;

		if ( -f $file ) {

			my $javascript = new SiteFunk::Project::Javascript ( $sitename ) ;
			$javascript -> load ( $file ) ;
			push @{ $self -> { JAVASCRIPTS } } , $javascript ;

		} 

	} # end of the subroutine _javascript

	unless ( @{ $self -> { JAVASCRIPTS } } ) {

		find ( \&_javascript , "$HOME/Projects/$sitename/dist/assets/js" ) ;

	}

	return @{ $self -> { JAVASCRIPTS } } ;

}

sub layouts {

=head2 layouts

=cut

	my $self = shift ;
	my $sitename = $self -> name ;

	sub _layout {

		my $project = shift ; # Deliberately passed as a parameter to localise

		my $file = $_ ;

		if ( _isHTML $file ) {

			my $layout = new SiteFunk::Project::Layout ( $sitename ) ;
			$layout -> load ( $file ) ;
			push @{ $project -> { LAYOUTS } } , $layout ;

		} 

	} # end of the subroutine _layout

	unless ( @{ $self -> { LAYOUTS } } ) {

		find (
			{ wanted => sub { _layout ( $self ) } } ,
			"$HOME/Projects/$sitename/src/layouts"
		) ;

	}

	return @{ $self -> { LAYOUTS } } ;

}

sub pages {

=head2 pages

=cut

	my $self = shift ;
	my $sitename = $self -> name ;

	sub _page {

		my $file = $_ ;

		if ( _isHTML $file ) {

			my $page = new SiteFunk::Project::Page ( $sitename ) ;
			$page -> load ( $file ) ;
			push @{ $self -> { PAGES } } , $page ;

		} 

	} # end of the subroutine _page

	unless ( @{ $self -> { PAGES } } ) {

		find ( \&_page , "$HOME/Projects/$sitename/src/pages" ) ;

	}

	return @{ $self -> { PAGES } } ;

}

sub partials {

=head2 partials

=cut

	my $self = shift ;
	my $sitename = $self -> name ;

	sub _partial {

		my $file = $_ ;

		if ( _isHTML $file ) {

			my $partial = new SiteFunk::Project::Partial ( $sitename ) ;
			$partial -> load ( $file ) ;
			push @{ $self -> { PARTIALS } } , $partial ;

		} 

	} # end of the subroutine _partial

	unless ( @{ $self -> { PARTIALS } } ) {

		find ( \&_partial , "$HOME/Projects/$sitename/src/partials" ) ;

	}

	return @{ $self -> { PARTIALS } } ;

}

sub stylesheets {

=head2 stylesheets

=cut

	my $self = shift ;
	my $sitename = $self -> name ;

	sub _stylesheet {

		my $file = $_ ;

		if ( -f $file ) {

			my $stylesheet = new SiteFunk::Project::Stylesheet ( $sitename ) ;
			$stylesheet -> load ( $file ) ;
			push @{ $self -> { STYLESHEETS } } , $stylesheet ;

		} 

	} # end of the subroutine _stylesheet

	unless ( @{ $self -> { STYLESHEETS } } ) {

		find ( \&_stylesheet , "$HOME/Projects/$sitename/dist/assets/css" ) ;

	}

	return @{ $self -> { STYLESHEETS } } ;

}

sub reset {

=head2 reset

Might just do this in the constructor?

=cut

	my $self = shift ;

	my $sitename = $self -> name ;

	if ( $self -> mode eq 'test' ) {
		remove_tree ( "$HOME/vhosts/$sitename" ) ;
	} elsif ( $self -> mode eq 'deploy' ) {
		remove_tree ( "$HOME/vhosts/$sitename/src" ) ;
	}

}

sub config {

	my $self = shift ;
	my $sitename = $self -> name ;

	my @includes = ( ) ;
	my @locations = ( );

	# Iterate through the pages and add:
	# 1. A template include path for every folder that contains pages.
	# 2. A location for every page, with its associated run mode.
	foreach my $page ( $self -> pages ) {

		my $path = $page -> path ;

		push @includes , $path unless grep /^$path$/ , @includes ;

		$path =~ s/^src\/pages// ;

		push @locations , {
			$path . $page -> name => { rm => $page -> run_mode }
		} ;
			

	}

	# Iterate through the partials and add:
	# 1. A template include page for every folder that contains partials.
	foreach my $partial ( $self -> partials ) {

		my $path = $partial -> path ;

		push @includes , $path unless grep /^$path$/ , @includes ;

	}

	# Iterate through the actions and add a run mode for each
	my $actions = LoadFile "$HOME/Projects/$sitename/src/data/action.yml" ;

	foreach my $action ( @{ $actions } ) {
		
		push @locations , $action ;

	}

	# Get the mapping of roles to locations from the role YAML file in the data
	# folder.
	my $roles = LoadFile "$HOME/Projects/$sitename/src/data/role.yml" ;

	foreach my $name ( keys %{ $roles } ) {

		my $role = $roles -> { $name } ;
		push @locations , {
			$role -> { Location } => { role => $name }
		}

	}

	# Get the environment parameters
	my $env = LoadFile "$HOME/Projects/$sitename/src/data/env.yml" ;

	my %config = (

		app => 'Main' ,

		env => $env ,

		tmpl_path => [ @includes ] ,

		Location => [ @locations ] ,

	) ;

	my $conf = new Config::General (

		-ConfigHash => \%config

	) ;

	$conf -> save_file ( "$HOME/vhosts/$sitename/sitefunk.cfg" ) ;

}

sub validate {

=head2 validate

This method tests a project to ensure that all of its template files have a
unique name.

=cut

	my $self = shift ;

	my @names      = ( ) ; # The names of the tempate files
	my @duplicates = ( ) ; # Any names that have been flagged as duplicated
	my @files      = ( ) ; # The offending files with duplicate names

	foreach my $template ( $self -> pages , $self -> partials ) {

		my $name = $template -> name ;

		if ( grep /^$name$/ , @names ) {
			push @duplicates , $template -> name
		}

		push @names , $template -> name ;

	}

	foreach my $template ( $self -> pages , $self -> partials ) {

		my $name = $template -> name ;

		if ( grep /^$name$/ , @duplicates ) {
			push @files , $template -> path . $template -> name
		}

	}

	return @files ;

}

sub write_pages {

=head2 write_pages

=cut

	my $self = shift ;

	my $sitename = $self -> name ;

	foreach my $page ( $self -> pages ) {

		my $path = $page -> path ;
		my $name = $page -> name ;

		my $out = "$HOME/vhosts/$sitename/$path$name.tt" ;

		my $dir = dirname ( $out ) ;

		make_path ( $dir ) ;

		print "$out\n" ;

		open TT , '>' , $out ;

		print TT $page -> template ;
	
		close TT ;

	}

}

1 ;

__END__
