# DATA - App

## Web Application Configuration

This directory contains configuration files used by the DATA web application as follows:

| File           | Contents                                                                                                                                                                                                          |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `context.cfg`  | Web path specific configuration used by the [Config::Context](https://metacpan.org/pod/Config::Context) module.                                                                                                   |
| `dispatch.yml` | YAML mapping of relative URL paths to run modes that is used by the web application to produce a dispatch table for the [CGI::Application::Dispatch](https://metacpan.org/pod/CGI::Application::Dispatch) module. |
| `general.cfg`  | Non web path specific configuration (for example used by scripts) used by the [Config::General](https://metacpan.org/pod/Config::General) module.                                                                 |

### How the Dispatch Table is Built

The `psgi/data-app.psgi` script combines the contents of `context.cfg`, which amongst other things contains the mapping of paths to application modules, with the contents of `dispatch.yml`, which as above contains the mapping of paths to run modes, in order to create the web application's dispatch table.

### Other Configuration Sources for the Web Application

The configuration files that are tracked within this repository have these two characteristics in common:
1. Their content is inherent to the structure of the application and does not vary by deployment environment.
2. They do not contain any sensitive information.

The DATA web application is deployed to a container environment for developer testing using the [DATA - Docker](https://github.com/varilink/data_docker) repository and to server hosting environments for customer testing or live use by the [DATA - Ansible](https://github.com/varilink/data_ansible) repository. Those repositories specify configuration that is specific to the environments that they create and `include` the configuration specified by this repository.

The configuration that is used by the DATA web application that contains sensitive information pertains to the integration of that web application with social media. This configuration contains for example API keys. Consequently that configuration is tracked in a private (not published to GitHub) repository that is used as a submodule in both the [DATA - Docker](https://github.com/varilink/data_docker) and [DATA - Ansible](https://github.com/varilink/data_ansible) repositories so that they have access to that sensitive configuration data when deploying environments.
