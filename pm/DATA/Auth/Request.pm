package DATA::Auth::Request ;

=head1 DATA::Auth::Request

CGI application that handles requests for secured resources. Tests whether the
request comes from an authenticated user and if access to the resource is
restricted to specific roles whether that user is authorised.

=cut

use strict ;

use base qw / CGI::Application / ;

use CGI::Application::Plugin::Session ;

use DATA::Plugin::Session ;

use Config::Context ;

sub cgiapp_init {

  my $self = shift ;

  $self -> run_modes ( [

    'request'         ,

  ] ) ;

}

sub request {

=head3 request

Tests whether a request to access a protected resource is permitted.

=cut

  my $self = shift ;

  my $query = $self -> query ;

  if ( $self -> session -> param ( 'userid' ) ) {

    # Already authenticated, check if authorised

		# Get the target
		my $target = $query -> env -> { 'HTTP_X_ORIGINAL_URI' } ;
		$target =~ s/\/+/\//g ; # Replace one or more / with a single /

		# Get the configuration location
		my $home = $query -> env -> { 'HTTP_X_CONFIG' } ;

      my $conf = new Config::Context (

         file => "$ENV{'DATA_CONF'}/data.cfg" ,

         driver => 'ConfigGeneral' ,

      	match_sections => [

         	{
         	   name => 'Location' ,
         	   match_type => 'path' ,
         	} ,
         	{
         	   name => 'LocationMatch' ,
         	   match_type => 'regex' ,
         	} ,

	      ] ,

   	   driver_options => {

   	      ConfigGeneral => {
   	         -AllowMultiOptions => 'yes' ,
   	         -IncludeDirectories => 'yes' ,
   	         -MergeDuplicateOptions => 'no' ,
   	         -UseApacheInclude => 'yes' ,
   	      } ,

   	   } ,

   	) ;

		my $config = $conf -> context ( $target ) ;

		if ( $config -> { 'role' } ) {

			# This area of the site requires that the user has a specific role.
			# Check that they do.

			$self -> session -> param ( 'role' ) eq $config -> { 'role' }
	         ? $self -> header_props ( -status => '200' )
			   : $self -> header_props ( -status => '403' ) ;

		} else {

			# This area of the site is secure but does not require that the user
			# has a specific role. It is sufficient just that they are
			# authenticated.

			$self -> header_props ( -status => '200' ) ;

		}

   } else {

      # Not authenticated, prompt for login

      $self -> header_props ( -status => '401' ) ;

   }

   return ;

}

1 ;

__END__
