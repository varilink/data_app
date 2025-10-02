# DATA::Auth::Request

CGI application modules that handles requests for secure resources. It tests
whether the request comes from an authenticated user. If access to the
resource is restricted to specific roles, whether that user is authorised, i.e.
is allocated to a role that gives them access.

## run modes

### request

This run mode tests if the user is permitted to access a secure resource.
