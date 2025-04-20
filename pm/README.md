# DATA - App

## Web Application Modules

These are the Perl modules that form the core of the DATA web application. They are based on the [CGI::Application](https://metacpan.org/pod/CGI::Application) module. There are four level-one modules within the web application as follows:

| Module          | Description                                                                                                              |
| --------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `DATA::Auth`    | Extends `DATA::Main` for authentication, authorisation and user account management.                                      |
| `DATA::Image`   | Extends `DATA::Main` for the upload of images associated with DATA Diary events.                                         |
| `DATA::Main`    | Core superclass of `CGI::Application`, which is used for the display of all pages and as the base for the other modules. |
| `DATA::WhatsOn` | Extends `DATA::Main` to provide actions, i.e. anything that produces an outcome and not just the display of a page.      |

There are also submodules of the `DATA::Auth`, `DATA::Image` and `DATA::WhatsOn` modules, which are in the `Auth/`, `Image/` and `WhatsOn` subdirectories respectively of this directory.

The `Plugin/` subdirectory contains packages that customise or extend CPAN modules that are based on the `CGI::Application` plugin framework for our purposes.
