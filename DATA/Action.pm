package SiteFunk::Action ;

=head1 SiteFunk::Action

=cut

use strict ;

use base qw / SiteFunk::Main / ;

use Carp ;

use CGI::Application::Plugin::Forward ;
use CGI::Application::Plugin::Redirect ;
use CGI::Application::Plugin::ValidateRM ;

use SiteFunk::Plugin::Email ;
use SiteFunk::Plugin::ValidateRM ;

sub cgiapp_init {

   my $self = shift ;

   $self -> run_modes ( { 

      'form_response' => 'form_response'

   } ) ;

}

sub form_response {

=head3 form_response

Redisplays the page after a form submission has produced errors and embeds the
error messages in to the relevant form.

=cut

   # This will always be called with errors to display
   my ( $self , $errs ) = @_ ;

   my $query = $self -> query ;

   use Config::Context ;

   my $raw = $self -> conf -> raw ;

   my $config = Config::Context -> new (

      config => $raw ,

      driver => 'ConfigGeneral' ,

      match_sections => [

         {
            name                => 'Site', # overridden by 'site_section_name'
            match_type          => 'exact',
            merge_priority      => 0,
            section_type        => 'env',
         },

         {
            name                => 'AppMatch',
            match_type          => 'regex',
            section_type        => 'module',
            merge_priority      => 1,
         },

         {
            name                => 'App',
            match_type          => 'path',
            path_separator      => '::',
            section_type        => 'module',
            merge_priority      => 1,
         },

         {
            name                => 'LocationMatch',
            match_type          => 'regex',
            section_type        => 'path',
            merge_priority      => 3,
         },

         {
            name                => 'Location',
            match_type          => 'path',
            section_type        => 'path',
            merge_priority      => 3,
         },

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

   #my $context = $config -> context ( $query -> param ( 'onError' ) ) ;

	#print 'On error=' . $query -> param ( 'onError' ) . "\n" ;

   #$self -> param ( page_run_mode => $context -> { rm } ) ;

	#my @tmpl_paths = ( ) ;

   #foreach my $tmpl_path ( @{ $context -> { tmpl_path } } ) {

   #   push @tmpl_paths , $self -> param ( 'home' ) . '/' . $tmpl_path ;

   #}

   #$self -> tmpl_path ( [ @tmpl_paths ] ) ;

   #my $tmpl = $self -> template -> load ( $context -> { rm } ) ;

   my $tmpl = $self -> template -> load ( $query -> param ( 'onError' ) ) ;

   $tmpl -> param ( $errs ) ;

   return $tmpl -> output ;

}

1 ;

__END__
