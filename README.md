# DATA - App

David Williamson @ Varilink Computing Ltd

------

The Derby Arts and Theatre Association (DATA) web application, the core of which is based on the Perl [CGI::Aplication](https://metacpan.org/pod/CGI::Application) framework.

## Repository Contents

The contents of this repository are summarised in this table.

| Directory     | Content                       |
| ------------- | ----------------------------- |
| conf/         | Web Application Configuration |
| packages/     | Package Dependencies          |
| pl/           | Perl Scripts                  |
| pm/           | Web Application Modules       |
| pod2markdown/ | Perl Code Documentation       |
| psgi/         | PSGI Scripts                  |
| tt/           | Template Toolkit Templates    |

There are README files in each of these directories that further describe the directory contents.

## Using this Repository

### Logging and Debugging

The application has inbuilt logging and debugging facilities. Logging is provided for the server-side, Perl based functionality using the [Log::Dispath](https://metacpan.org/pod/Log::Dispatch) module. As per that CPAN documentation for the module, "The log levels that Log::Dispatch uses are taken directly from the syslog man pages".

The DATA web application is coded (or rather, will be coded) to output specific categories of report at specific log levels or above. This is a work in progress, in reality we are introducing this code to specific areas of the application as and when we need to use this logging and debugging facility to diagnose an issue in a particular area.

The table below shows the types of report that we associated with the *debug*, *info* and *notice* log levels. We don't currently use any of the other syslog logging levels (*warning*, *error*, *critical*, *alert* and *emergency*).

debug:
Custom reports that are specific to the logic in the context that contains them.

info:
Reports of information consumed by or output by the application; for example dumps of the query and configuration in context objects at the start of a run mode.

notice:
Reports that confirm the flow through the application; for example, the names of each run mode as it is entered and the app that contains that run mode.

### Obtaining a New Facebook Page Access Token

The Facebook integration requires a page access token. Currently these are manually obtain via the following process steps. I believe it is possible to automate this, see [Completely automate obtaining page access tokens](https://github.com/varilink/data-app/issues/13).

1. Generate short-tem user access token

Go to Facebook's [Graph API Explorer](https://developers.facebook.com/tools/explorer/) and click on "Generate Access Token" with "DATA Diary" selected for "Facebook App" and "User Token" selected for "User or Page".

2. Run `facebook-get-page-token.pl`

Pass the short-term user access token as a positional, command-line parameter. The script will output a generated page access token and also the datetime that page access token will expire to make a note of in the diary.

3. Set `facebook_page_token` environment variable to generated page token
