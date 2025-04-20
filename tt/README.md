# DATA - App

## Template Toolkit Templates

The DATA web application makes extensive use of the [Template Toolkit](https://template-toolkit.org/) template processing system. Since there are a significant number of templates used, they are organised into subdirectories as follows:

| Subdirectory | Template Purpose                                                                 |
| ------------ | -------------------------------------------------------------------------------- |
| `emails/`    | Emails sent directly from the website not via Mailchimp.                         |
| `mailchimp/` | Mailchimp campaigns.                                                             |
| `pages/`     | Primary pages (as opposed to response dialogues below) displayed on the website. |
| `partials/`  | Snippets that are used in several places.                                        |
| `print/`     | The print format one-page programme flyer formats.                               |
| `responses/` | Pages displayed as dialogue style responses to actions.                          |

I think that the template snippets in the `partials` subdirectory may only be used by templates in the `pages/` subdirectory, in which is might be better to move the `partials` subdirectory to be within the `pages/` subdirectory.
