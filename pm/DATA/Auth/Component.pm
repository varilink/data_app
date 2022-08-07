package DATA::Auth::Component ;

=head1 DATA::Auth::Component

=cut

use strict ;

use base qw / Exporter / ;

use DATA::Auth::User ;

my @run_modes = qw /

   auth_current_user

/ ;

sub _init {

   # Register run modes from the run modes array

   my $c = shift ;

   $c -> run_modes ( [ @run_modes ] ) ;

}

# Export the run modes
our @EXPORT = @run_modes ;

# Allow all the run modes to be exported
our @EXPORT_OK = @run_modes ;

sub import {

   # Determine my caller
   my $caller = scalar caller ;

   # Use the _init method as an init stage cgi application call back
   $caller -> add_callback (
      'init' ,
      \&_init
   ) ;

   # Inherit the import method of the base class
   goto &Exporter::import ;

}

sub auth_current_user {

=head3 auth_current_user

Display details of the currently authenticated user

=cut

   my $self = shift ;
	my $containing_template = shift ;

	# This component gets the details for the user corresponding to the current,
	# authenticated session, rather than being passed search keys.
   my $user = new DATA::Auth::User ;
   $user -> userid ( $self -> session -> param ( 'userid' ) ) ;
   $user -> fetch ( $self -> dbh ) ;

	my $caller = $containing_template -> param ( 'template' ) -> { 'name' } ;

	my $output = "[% auth_current_user ( caller = \"$caller\" ) %]" ;

   my $tmpl = $self -> template -> load ( \$output ) ;

   $tmpl -> param ( user => $user ) ;

   return $tmpl -> output ;

}

1 ;

__END__
