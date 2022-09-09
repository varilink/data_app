# DATA::Plugin::Template

Template plugin for DATA applications. Implements template configuration and
actions that are required for all DATA applications.

## Hooks

This plugin installs the following hooks in to a DATA application

### prerun

Load the template paths from the configuration file. Note that since this plugin
has a dependency on the configuration we're using the prerun hoook rather than
the init hook to ensure that the configuration is loaded first.

### template\_pre\_process

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

During a form\_response to error, all templates also have access to the query
parameters and the error object rasied by the validation error that triggered
form\_response (see the form\_response run mode in Main.pm).

This hook also ensures that the template output is UTF8 encoded.
