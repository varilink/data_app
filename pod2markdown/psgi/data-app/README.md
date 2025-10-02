# [data-app.psgi](https://github.com/varilink/data_app/blob/main/psgi/data-app.psgi)

PSGI script for the DATA web application. This uses
\-[CGI::Application::Dispatch::PSGI](https://metacpan.org/pod/CGI::Application::Dispatch::PSGI)
to dispatch requests. It builds the dispatch table by combining the contents of
`conf/context.cfg` and `conf/dispatch.yml` from the
\-[DATA - App](https://github.com/varilink/data_app) repository. To do this it
requires that the `conf/` directory be present at the location
`$ENV{'DATA_APP_CONF_DIR'}/app/` in the environment in which it is run.

`conf/context.cfg` contains the mapping between locations within the DATA web
application and the -[CGI::Application](https://metacpan.org/pod/CGI::Application)
modules that combine for the DATA web application. `conf/dispatch.yml` contains
the mapping between those locations and their run mode names.
