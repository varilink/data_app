# DATA - App

David Williamson @ Varilink Computing Ltd

------

The Derby Arts and Theatre Association web application, the core of which is based on the Perl [CGI::Aplication](https://metacpan.org/pod/CGI::Application) framework.

## Repository Contents

The contents of this repository are summarised in this table.

| Item               | Folder        |
| ------------------ | ------------- |
| Web App            | pm/DATA/      |
| PSGI Scripts       | psgi/         |
| Other Perl Scripts | pl/           |
| Code Documentation | pod2markdown/ |
| Configuration      | conf/         |
| Templates          | tt/           |

There follows further notes about each of the items above.

### Web App

This is the *core* of the web application referred to above.

### PSGI Scripts

Perl Web Server Gateway Interface (PSGI) scripts corresponding to each application service of which there are two:
1. The main DATA application.
2. The image upload handler.

### Other Perl Scripts

Various Perl scripts that sit aside from the core web application to fulfil ancillary functions; for example integration of the website with Facebook, Mailchimp and Twitter.

### Code Documentation

Documentation of the code in the web app, PSGI scripts and other Perl scripts that is generated using the `pod2markdown` command to produce Markdown from the Perl Plain Old Documentation (POD) format that is embedded within the code.

### Configuration

Three configuration files are tracked within this repository. They are tracked within this repository because they have the following characteristics in common:
1. They do not contain any sensitive information.
2. Their content is inherent to the structure of the application, i.e. it does not vary by deployment environment.

Each deployment environment includes these files within its wider configuration.

`context.cfg`

This file contains configuration settings for the web application that have different values according to the context, derived from the path of requests by the `Config::Context` module.

`general.cfg`

Similar to `context.cfg` but contains configuration settings that do **not** have different values according to the context, i.e. they only have one value regardless of the context for web requests or when consumed by scripts, for which there is no web request context.

`dispatch.yml`

This YAML file maps HTTP URL paths to `CGI::Application` run modes. It is read by the `psgi/data-app.psgi` script alongside `conf/data.cfg`, which contains the mapping of HTTP URL paths to `CGI::Application` application modules. This enables `psgi/data-app.psgi` to combine these two sources to build its `CGI::Application::Dispatch` table for web requests.

### Templates

Contains the [Template Tookit](http://template-toolkit.org/) templates that are used throughout the web app and other Perl scripts.

## Using this Repository

### Configuring Application Environments

It was explained above that the configuration files tracked in this repository contain configuration that is inherent to the application and does not contain any sensitive data. The full application configuration for a deployment environment has a wider scope. I use this structure within a configuration folder to complete the configuration of the application within a deployment environment.

| File                     | Config Contents                      | Config Section | Includes                                                                                                                                                                                                                                                                                                                               |
| ------------------------ | ------------------------------------ | -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `app.cfg`                | Includes for all the other cfg files | N/A            | `env.cfg`<br /><br />`app/context.cfg`<br /><br />`app/general.cfg`<br /><br />`int/facebook/live).cfg`<br />or<br />`int/facebook/test.cfg`<br /><br />`int/mailchimp/live.cfg`<br />or<br />`int/mailchimp/test.cfg`<br /><br />`int/recaptcha.cfg` (optional)<br /><br />`int/twitter/live.cfg`<br />or<br />`int/twitter/test.cfg` |
| `env.cfg`                | Environment                          | env            |                                                                                                                                                                                                                                                                                                                                        |
| `app/context.cfg`        | Application (contextual)             | *default*      |                                                                                                                                                                                                                                                                                                                                        |
| `app/dispatch.yml`       | Run modes to HTTP URL paths mapping  | N/A            |                                                                                                                                                                                                                                                                                                                                        |
| `app/general.cfg`        | Application (not contextual)         | *default*      |                                                                                                                                                                                                                                                                                                                                        |
| `int/facebook.cfg`       | Facebook integration (common)        | facebook       |                                                                                                                                                                                                                                                                                                                                        |
| `int/facebook/live.cfg`  | Facebook integration (live)          | facebook       | ../facebook.cfg                                                                                                                                                                                                                                                                                                                        |
| `int/facebook/test.cfg`  | Facebook integration (test)          | facebook       | ../facebook.cfg                                                                                                                                                                                                                                                                                                                        |
| `int/mailchimp.cfg`      | Mailchimp integration (common)       | mailchimp      | .                                                                                                                                                                                                                                                                                                                                      |
| `int/mailchimp/live.cfg` | Mailchimp integration (live)         | mailchimp      | ../mailchimp.cfg                                                                                                                                                                                                                                                                                                                       |
| `int/mailchimp/test.cfg` | Mailchimp integration (test)         | mailchimp      | ../mailchimp.cfg                                                                                                                                                                                                                                                                                                                       |
| `int/recaptcha.cfg`      | reCAPTCHA integration                | recaptcha      |                                                                                                                                                                                                                                                                                                                                        |
| `int/twitter.cfg`        | Twitter integration (common)         | twitter        |                                                                                                                                                                                                                                                                                                                                        |
| `int/twitter/live.cfg`   | Twitter integration (live)           | twitter        | ../data.cfg                                                                                                                                                                                                                                                                                                                            |
| `int/twitter/test.cfg`   | Twitter integration (test)           | twitter        | ../data.cfg                                                                                                                                                                                                                                                                                                                            |

The only two files whose paths are fixed within the application are `app.cfg` and `app/dispatch.yml`. The use of include statements within `app.cfg` means that the other `.cfg` files could have any location, so long as the application can reference `app.cfg` as the master `.cfg` file.

The files apart from those in the `app` folder contain configuration that either varies by environment or contains sensitive content, such as API keys. Thus they are not tracked within this repository but within other repositories that are specific to the deployment environment and possibly private, to mask sensitive content.

The Facebook, Mailchimp and Twitter configurations cater for integration to either test (private) or live Facebook pages, Mailchimp audiences or Twitter accounts. The reCAPTCHA integration is with a single reCAPTCHA account but is not included for environments in which `use_captcha` is set to a false value, e.g. containers on the developer desktop. The use of configuration sections avoids variable name clashes.

### Obtaining a New Facebook Page Access Token

The Facebook integration requires a page access token. Currently these are manually obtain via the following process steps. I believe it is possible to automate this, see [Completely automate obtaining page access tokens](https://github.com/varilink/data-app/issues/13).

1. Generate short-tem user access token

Go to Facebook's [Graph API Explorer](https://developers.facebook.com/tools/explorer/) and click on "Generate Access Token" with "DATA Diary" selected for "Facebook App" and "User Token" selected for "User or Page".

2. Run `facebook-get-page-token.pl`

Pass the short-term user access token as a positional, command-line parameter. The script will output a generated page access token and also the datetime that page access token will expire to make a note of in the diary.

3. Set `facebook_page_token` environment variable to generated page token

## Functionality Provided by this Repository

There follows an itemised listing of the functionality that this repository provides. This can serve as the outline for a testing checklist.

### Website

#### Public Area

- Navigation and display of pages in the website's public area.

- Cookie consent alert handling.

- *Download flyer* from the home page and the *Diary Scheme* page.

- reCAPTCHA integration on the Notify Us page.

- Subscribe link takes you to the Mailchimp sign-in form that's appropriate for the website environment, live or test.

- *Notify Us* form to inform the DATA administrator via email of an upcoming event.

- Prompt to a logged in user to use the Admin area instead if they try to access the *Notify Us* form.

- *Join Us* form for membership enquiries.

- User registration workflow can be initiated from the *Diary Scheme* page.

- Sign in to the application's *Admin Area* via the *Sign-In* link.

- Sign in to the Django admin interface (*Webmin Area*) via the path `/webmin/`.

#### Account Management Functions

- Facilitates the modification of details associated with the user account. Available if signed in to the application's admin area but not accessible if not signed in.

#### Admin Area

- Functionality differs for category of user, which is one of full admin, representative of a single member society or representative of multiple member societies.

- Ability of all those roles to add or update an event, with the representatives of member societies restricted to events for the member society or societies that they represent.

#### Webmin Area

### Integrations

#### Facebook

#### Mailchimp

#### Twitter
