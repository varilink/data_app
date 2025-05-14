package DATA::Plugin::LogDispatch;

=head1 DATA::Plugin::LogDispatch

Plugin DATA application integration with Log::Dispatch.

=cut

use strict;
use warnings;

use base qw / Exporter /;

sub _init {

    my $self = shift;

    $self -> log_config(
        APPEND_NEWLINE => 'yes',
        LOG_DISPATCH_OPTIONS => {
            callbacks => sub { my %h = @_; return time().': '.$h{message}; },
        },
        LOG_DISPATCH_MODULES => [
            {
                module    => 'Log::Dispatch::File',
                name      => 'file',
                filename  => '/tmp/data_app.log',
                min_level => $self->conf->param('file_log_level'),
                mode => 'append',
            },
        ]
    );

}

sub import {

    my $caller = scalar caller;
    $caller->add_callback(
        'init', \&_init
    );

}

1;

__END__
