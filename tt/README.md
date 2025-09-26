# DATA - App

## Template Toolkit Templates

The DATA web application makes extensive use of the [Template Toolkit](https://template-toolkit.org/) template processing system. Since there are a significant number of templates used, they are organised into directories as follows:

| Directory                           | Template Purpose                                                                                 |
| ----------------------------------- | ------------------------------------------------------------------------------------------------ |
| `emails/`                           | Emails sent directly from the website not via Mailchimp.                                         |
| `emails/partials/`                  | Snippets that are shared by more than one template in `emails`.                                  |
| `mailchimp/`                        | Mailchimp campaigns.                                                                             |
| `mailchimp/fragments/`              | Snippets that are shared by more than one Mailchimp template file.                               |
| `mailchimp/inserts/`                | A directory that is set aside for one-off inserts for monthly bulletins that aren't Git tracked. |
| `mailchimp/sections/`               | Template files for each of the main sections within the monthly mailchimp bulletins.             |
| `pages/`                            | Primary pages (as opposed to response dialogues below) displayed on the website.                 |
| `pages/account/`                    | Pages in the account management section of the public website.                                   |
| `pages/secure/`                     | Secure pages, requiring authentication and authorisation to access them.                         |
| `pages/secure/admin/`               | Secure pages that require admin level authorisation to access them.                              |
| `pages/secure/rep/`                 | Secure pages that require member society representative level authorisation to access them.      |
| `partials/`                         | Snippets that are used in several places.                                                        |
| `partials/event_formats/`           | Snippets that display event details in various formats.                                          |
| `partials/formfields/`              | Snippets that output form fields.                                                                |
| `partials/formfields/contact/`      | Form fields pertaining to the "contact" object.                                                  |
| `partials/formfields/event/`        | Form fields pertaining to the "event" object.                                                    |
| `partials/formfields/flyer/`        | Form fields that are used to generate one page, printable event programme flyers.                |
| `partials/formfields/organisation/` | Form fields pertaining to the "organisation" object.                                             |
| `partials/formfields/user/`         | Form fields pertaining to the "user" object.                                                     |
| `print/`                            | The print format one-page programme flyer format.                                                |
| `responses/`                        | Pages displayed as dialogue style responses to actions.                                          |
| `responses/error/`                  | Specifically, "error" responses.                                                                 |
| `responses/success/`                | Specifically, "success" responses.                                                               |
| `responses/warning/`                | Specifically, "warning" responses.                                                               |
| `scripts/`                          | Script tags that appear in more than one template file and so are defined here for reuse.        |

I think that the template snippets in the `partials/` directory are only used by templates in the `pages/` directory, in which is might be better to move the `partials/` directory to be a subdirectory within the `pages/` directory. This is the approach taken for the `emails/` directory, which contains a `partials/` subdirectory containing partials files that are only used in emails. However, the structure within the `pages/` directory is more complicated than it is within the `emails/` directory, so I'll leave it like it is for now.

Each file within the directories that are in the `tmpl_path` array for the web application must have a unique name to avoid name clashes when the web application loads them. Each directory in the hierarchy of templates is concatenated into a search path for templates, see the build of the `tmpl_path` array in `conf/general.cfg` in this repository. Note however that the templates in the `tt/mailchimp/` are **not** in the `tmpl_path` array but are instead loaded by the Mailchimp integration scripts, so they can safely clash in name with other template files elsewhere within the `tt/` directory.

A bash script is provided in `tt/duplicates.sh` to facilitate checking for duplicate template file names.
