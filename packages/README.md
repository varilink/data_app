# DATA - App

## Package Dependencies

The YAML files in this folder contain lists of packages that are required by the web application defined by this repository. These packages are specified in YAML files within this repository so that they can used by both [DATA - Ansible](https://github.com/varilink/data_ansible) and [DATA - Docker](https://github.com/varilink/data_docker) to build the web application.

There are a list of Debian packages in the file `deb.yml` and two lists of CPAN packages in the files `cpan1.yml` and `cpan2.yml`, the first contains a list of packages that are dependencies of the packages that are listed in the second. Our strategy for implementing Perl packages is to use Debian packages by preference, only falling back on CPAN packages where there is no Debian package available.
