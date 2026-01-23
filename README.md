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


### Templates

Contains the [Template Tookit](http://template-toolkit.org/) templates that are used throughout the web app and other Perl scripts.

## Using this Repository

### Obtaining a New Facebook Page Access Token

The Facebook integration requires a page access token. Currently these are manually obtain via the following process steps. I believe it is possible to automate this, see [Completely automate obtaining page access tokens](https://github.com/varilink/data-app/issues/13).

1. Generate short-tem user access token

Go to Facebook's [Graph API Explorer](https://developers.facebook.com/tools/explorer/) and click on "Generate Access Token" with "DATA Diary" selected for "Facebook App" and "User Token" selected for "User or Page".

2. Run `facebook-get-page-token.pl`

Pass the short-term user access token as a positional, command-line parameter. The script will output a generated page access token and also the datetime that page access token will expire to make a note of in the diary.

3. Set `facebook_page_token` environment variable to generated page token
