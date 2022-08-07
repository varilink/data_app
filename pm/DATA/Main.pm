package DATA::Main ;

=head1 DATA::Main

=cut

use strict ;

use base qw / CGI::Application / ;

# Use CGI::Application plugins
use CGI::Application::Plugin::AnyTemplate ;
use CGI::Application::Plugin::Config::Context ;
use CGI::Application::Plugin::DBH qw /dbh_config dbh/ ;
use CGI::Application::Plugin::Session ;

# Use DATA customisation of CGI::Application::Plugin::Config::Context
use DATA::Plugin::Config ;

# Use other DATA customisations of CGI:Application plugins
use DATA::Plugin::DBH ;
use DATA::Plugin::Session ;
use DATA::Plugin::Template ;

# Embed the components for embedding in pages
use DATA::Auth::Component ;
use DATA::WhatsOn::Component ;

use Carp ;

use CGI::Application::Plugin::Forward ;
use CGI::Application::Plugin::Redirect ;
use CGI::Application::Plugin::ValidateRM ;

use DATA::Plugin::Email ;
use DATA::Plugin::ValidateRM ;

sub cgiapp_init {

  my $self = shift ;

  $self -> run_modes (

    'form_response'  => 'form_response'  ,
    'throw_error'    => 'throw_error'    ,
    'AUTOLOAD'      => \&auto_run_mode

  ) ;

}

sub cgiapp_postrun {

  my $self = shift ;

  # Set the session parameter precursor to the name of this run mode just before
  # exiting. That way the next invoked run mode will know what its precursor
  # run mode was.
  $self -> session -> param ( 'precursor' , $self -> get_current_runmode ) ;
  $self -> session -> flush ;

}

=head2 run modes

This superclass defines the following run modes

=cut

sub throw_error {

=head3 throw_error

A special run mode that can be used to trigger HTTP 500 responses to test that
they are handled correctly. I have lost track of how an environment was
configured to have a URL mapped to this run mode.

=cut

  my $self = shift ;

  $self -> header_props ( -status => '500' ) ;
  return ;

}

sub auto_run_mode {

=head3 auto_run_mode

Provides an automatic run mode for ALL page displays. Only form action run modes
are then required to be explicitly defined in action packages for each DATA
application, e.g. "Auth", "WhatsOn", etc.

=cut

  my ( $self , $run_mode ) = @_ ;

  my $tmpl = $self -> template -> load ;

  if (
    $run_mode ne 'not_found'
    # nginx internal redirects to not_found retain the original request URI,
    # which might be associated with a response run mode. It is the request URI
    # that is used for the context matching in Config::Context so, if we don't
    # have this exclusion we end up thinking that not_found has the precursor.
    &&
    $run_mode ne 'error'
    # Similarly for nginx internal redirects to error.
    &&
    $self -> conf -> param ( 'precursor' )
    # This is a response mode, i.e. it has a mandated precursor run mode set in
    # the application's configuration file. We know that it is genuine and NOT
    # the result of an nginx internal redirect.
  ) {

    if (

      $self -> session -> param ( 'precursor' )
        ne $self -> conf -> param ( 'precursor' )
      # The session parameter that was set by the last run mode that ran is NOT
      # the name of the mandated precursor run mode
      &&
      $self -> session -> param ( 'precursor' )
        ne $self -> get_current_runmode
      # Nor is the session parameter that was set by the last run mode the
      # name of the current run mode (the refresh page scenario)

    ) {

      # This run mode has not been called via a rediret from the mandated
      # precursor run mode nor has it been called by a refresh of itself.
      # Raise a 404 not found and bale out.

      $self -> header_add ( -status => '404' ) ;
      return ;

    }

    # Populate the template with any parameters from the precursor
    $tmpl -> param ( %{ $self -> session -> param ( 'tmpl_params' ) } )
      if $self -> session -> param ( 'tmpl_params' ) ;

  } else {

    # Clear all template parameters passed in the session to response run modes
    # via a redirect. These will be recycled during refreshes of a response run
    # mode but immediately we see a non response display run mode we need to
    # clear the slate.
    $self -> session -> clear ( [ 'tmpl_params' ] ) ;
    $self -> session -> flush ;

  }

  if ( $self -> session -> param ( 'show_warning') ) {

    # An action run mode has set show_warning in the session. Translate this to
    # the show_warning template parameter and clear the show_warning instruction
    # from the session.
    $tmpl -> param (
      'show_warning' => $self -> session -> param ( 'show_warning' )
    ) ;
    $self -> session -> clear ( [ 'show_warning' ] ) ;
    $self -> session -> flush ;

  }

  return $tmpl -> output ;

}

sub error_rm {

=head3 error_rm

At one point I had set the "error_mode" for this superclass to this run mode in
order to benefit from the autmotic forward to an error run mode provided for in
CGI::Application (see the documentation for that module). However, I have not
had this set for some time so I suspect that this run mode has become redundant.

I do notice that sometimes the error page is not invoked and a default 500 page
is returned instead so there may be some value in reinstating this run mode,
possibly to send output to the log rather than the browser.

=cut

  my $inputs = @_ ;

  use Data::Dumper ;
  print Dumper ( @_ ) ;

}

sub form_response {

=head3 form_response

Redisplays the page after a form submission has produced errors and embeds the
error messages in to the relevant form.

=cut

  # This will always be called with errors to display
  my ( $self , $errs ) = @_ ;

  my $query = $self -> query ;

  my $tmpl = $self -> template -> load ( $query -> param ( 'onError' ) ) ;

  my $params = { } ;

  foreach my $param ( $query -> param ) {

    my $value = $query -> param ( $param ) ;
    $params -> { $param } = $value ;

  }

  $tmpl -> param ( $errs ) ;
  $tmpl -> param ( $params ) ;

  return $tmpl -> output ;

}

1 ;

__END__