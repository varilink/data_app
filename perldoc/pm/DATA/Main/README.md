# DATA::Main

Master CGI::Application superclass for the DATA website. This provides a core
set of run modes including the run mode auto\_run\_mode, which is used for the
display of all pages. Action CGI::Application classes that are based on this
superclass then only have to define their specific actions as run modes.

## run modes

This superclass defines the following run modes:

### throw\_error

A special run mode that can be used to trigger HTTP 500 responses to test that
they are handled correctly. I have lost track of how an environment was
configured to have a URL mapped to this run mode.

### auto\_run\_mode

Provides an automatic run mode for ALL page displays. Only form action run modes
are then required to be explicitly defined in action packages for each DATA
application, e.g. "Auth", "WhatsOn", etc.

### error\_rm

At one point I had set the "error\_mode" for this superclass to this run mode in
order to benefit from the autmotic forward to an error run mode provided for in
CGI::Application (see the documentation for that module). However, I have not
had this set for some time so I suspect that this run mode has become redundant.

I do notice that sometimes the error page is not invoked and a default 500 page
is returned instead so there may be some value in reinstating this run mode,
possibly to send output to the log rather than the browser.

### form\_response

Redisplays the page after a form submission has produced errors and embeds the
error messages in to the relevant form.
