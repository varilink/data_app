package DATA::Plugin::Template ;

=head1 DATA::Plugin::Template

Template plugin for DATA applications. Implements template configuration and
actions that are required for all DATA applications.

=cut

use strict ;

use base qw / Exporter / ;

sub _init {

  my $self = shift ;

  $self -> template -> config (

    default_type => 'TemplateToolkit' ,

    TemplateToolkit => {

      # I do not fully understand why but do NOT enable the ENCODING flag here
      # ENCODING => 'utf8' ,
      RECURSION => 1 ,
      template_extension => '.tt' ,

    } ,

  ) ;

}

=head2 Hooks

This plugin installs the following hooks in to a DATA application

=cut

sub _prerun {

=head3 prerun

Load the template paths from the configuration file. Note that since this plugin
has a dependency on the configuration we're using the prerun hoook rather than
the init hook to ensure that the configuration is loaded first.

=cut

  my $self = shift ;

  my @tmpl_paths = ( ) ;

  foreach my $tmpl_path ( @{ $self -> conf -> param ( 'tmpl_path' ) } ) {

    push @tmpl_paths , $self -> param ( 'home' ) . '/' . $tmpl_path ;

  }

  $self -> tmpl_path ( [ @tmpl_paths ] ) ;

}

sub _template_pre_process {

=head3 template_pre_process

Pass a range of values to the template as template parameters as follows:
psgi - The PSGI environment;
conf - The applications own environment configuration (note: not the whole
configuation, only the environment component thereof);
session - The parameters and values stored in the current session;
params - The current CGI application paramaters and their values.

Testing indicates that this callback is only called for the page level
template and not any embedded component templates. Component templates are
therefore compelled to reference their parent template for these paramters.

Component templates however DO have access to the template parameters that are
set via access to the database as it is the components that facilitate this.
Access to these values is not available outside of the components.

During a form_response to error, all templates also have access to the query
parameters and the error object rasied by the validation error that triggered
form_response (see the form_response run mode in Main.pm).

This hook also ensures that the template output is UTF8 encoded.

=cut

  my ( $self , $tmpl ) = @_ ;

  #-----------------------------------------------------------------------------
  # Pass the PSGI environment to the template
	$tmpl -> param ( 'psgi' => $self -> query -> env ) ;

  #-----------------------------------------------------------------------------
  # Pass the CGI application configuration to the template
	my $env = $self -> conf -> param ( 'env' ) ;
	$tmpl -> param ( 'conf' => $env ) ;

  #-----------------------------------------------------------------------------
  # Convert the session to a template parameter called session.
  # Session parameters are then within the session template paramater.
  # For example:
  # session.userid = the session userid;
  # session.roles = an array of session roles.
  my $session = { } ;
  foreach my $param ( $self -> session -> param ) {
    $session -> { $param } = $self -> session -> param ( $param ) ;
  }
  $tmpl -> param ( 'session' => $session ) ;

  #-----------------------------------------------------------------------------
	# Populate the template with all cookies
  my @cookies = $self -> query -> cookie ;
  my $cookies = { } ;
  foreach my $cookie ( @cookies ) {
    $cookies -> { $cookie } = $self -> query -> cookie ( $cookie ) unless
    $cookie eq 'csrftoken' || $cookie eq 'CGISESSID' || $cookie eq 'sessionid' ;
  }
	$tmpl -> param ( 'cookies' , $cookies ) ;

  #-----------------------------------------------------------------------------
  # Populate the template with the current CGI Application parameters
  # This is used typically for parameters passed via the URL, e.g. rowid
  foreach my $param ( $self -> param ) {
    # Ignore other use of param
    unless ( $param eq 'dfv_defaults' || $param eq 'home' ) {
      $tmpl -> param ( $param , $self -> param ( $param ) ) ;
    }
  }

	# Since we're processing a template we must be about to output a web page.
	# Set the appropriate content type header.
	$self -> header_add ( -type => 'text/html; charset=utf-8' ) ;

}

sub import {

   my $caller = scalar caller ;

   $caller -> add_callback (

      'init' , \&_init

   ) ;

   $caller -> add_callback (

      'prerun' , \&_prerun

   ) ;

   $caller -> add_callback (

      'template_pre_process' , \&_template_pre_process

   ) ;

   goto &Exporter::import ;

}

1 ;

__END__