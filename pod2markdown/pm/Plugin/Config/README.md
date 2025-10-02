# [DATA::Plugin::Config](https://github.com/varilink/data_app/pm/Plugin/Config.pm)

Plugin to load the application configuration in to any
[CGI::Application](https://metacpan.org/pod/CGI::Application)
module within the DATA web application. The DATA web application uses 
[Config::Context](https://metacpan.org/pod/Config::Context)
for its configuration with the underlying driver for
[Config::General](https://metacpan.org/pod/Config::General).

This plugin supports the variable interpolation feature of `Config::General`
for some specific configuration items. For those items a value can be passed to
the DATA web application via an environment variable. If a value isn't passed
then a default value applies instead. The table below gives the details of those
configuration variables for which this approach is supported.

    Env Var              Config Var       Default
    ------------------   --------------   ---------
    DATA_APP_LOG_LEVEL   file_log_level   emergency
