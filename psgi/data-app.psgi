=head1 L<data-app.psgi|https://github.com/varilink/data_app/blob/main/psgi/data-app.psgi>

PSGI script for the DATA web application. This uses
-L<CGI::Application::Dispatch::PSGI|https://metacpan.org/pod/CGI::Application::Dispatch::PSGI>
to dispatch requests. It builds the dispatch table by combining the contents of
C<conf/context.cfg> and C<conf/dispatch.yml> from the
-L<DATA - App|https://github.com/varilink/data_app> repository. To do this it
requires that the C<conf/> directory be present at the location
C<$ENV{'DATA_APP_CONF_DIR'}/app/> in the environment in which it is run.

C<conf/context.cfg> contains the mapping between locations within the DATA web
application and the -L<CGI::Application|https://metacpan.org/pod/CGI::Application>
modules that combine for the DATA web application. C<conf/dispatch.yml> contains
the mapping between those locations and their run mode names.

=cut

use strict ;
use warnings ;

use CGI::Application::Dispatch::PSGI ;
use Config::Context ;
use YAML qw / LoadFile / ;

sub {

  my $env = shift ;

  my $conf = Config::Context -> new (

    file => "$ENV{'DATA_APP_CONF_DIR'}/$ENV{'DATA_APP_CONF_FILE'}" ,

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

  my $rules = LoadFile "$ENV{'DATA_APP_CONF_DIR'}/app/dispatch.yml" ;

  my $table = [ ] ;

  foreach my $rule ( @{ $rules } ) {

    my @keys = keys %{ $rule } ;

    my $path = $keys[0] ;
    my $app = $conf -> context ( $path ) -> { app } ;

    my $rm = $rule -> { $path } ;

    push @{ $table } , $path => { app => $app , rm => $rm } ;

  }

  # Dispatch the request
  my $app = CGI::Application::Dispatch::PSGI -> as_psgi (

    prefix => 'DATA' ,

    args_to_new => {

      PARAMS => {
        home => "$ENV{'DATA_APP_CONF_DIR'}"
      } ,

    } ,

    table => $table ,

  ) ;

  return $app -> ( $env ) ;

}
