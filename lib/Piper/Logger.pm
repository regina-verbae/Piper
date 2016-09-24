#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Log/message handler for Piper
#####################################################################

package Piper::Logger;

use v5.10;
use strict;
use warnings;

use Carp qw();

use Moo;

with qw(Piper::Role::Logger);

=head1 CONSTRUCTOR

=head2 new(%attributes)

=head1 ATTRIBUTES

=head2 debug, verbose

May be a positive integer or zero, though there are
currently only two debug and two verbosity levels,
so 0, 1, or 2 will suffice.

These attributes will be set upon initialization of
a Piper object based on any debug/verbose values
provided via the Piper object's options during
construction.

Alternatively, these can be set manually at any time
after initialization with $self->verbose($val) or
$self->debug($val).

Both attributes have an environment variable override
which can be used to trump the values set by a program.

    $ENV{PIPER_VERBOSE}
    $ENV{PIPER_DEBUG}

=head1 METHODS

=head2 DEBUG($segment, $message, @items)

This method will be a no-op unless debug > 0.

Prints an informational message to STDERR.

Uses the method make_message to format the printed
message according to debug/verbose levels and the
arguments.

Labels the message by pre-pending 'Info: ' to the
formatted message.

=cut

sub DEBUG {
    my $self = shift;
    $self->INFO(@_);
}

=head2 ERROR($segment, $message, @items)

Prints an error to STDERR and dies via Carp::croak.

Uses the method make_message to format the printed
message according to debug/verbose levels and the
arguments.

Labels the message by pre-pending 'Error: ' to the
formatted message.

=cut

sub ERROR {
    my $self = shift;
    Carp::croak('Error: '.$self->make_message(@_));
}

=head2 INFO($segment, $message, @items)

This method will be a no-op unless verbose > 0 or
debug > 0.

Prints an informational message to STDERR.

Uses the method make_message to format the printed
message according to debug/verbose levels and the
arguments.

Labels the message by pre-pending 'Info: ' to the
formatted message.

=cut

sub INFO {
    my $self = shift;
    say STDERR 'Info: '.$self->make_message(@_);
}

=head2 WARN($segment, $message, @items)

Prints a warning to STDERR via Carp::carp.

Uses the method make_message to format the printed
message according to debug/verbose levels and the
arguments.

Labels the message by pre-pending 'Warning: ' to
the formatted message.

=cut

sub WARN {
    my $self = shift;
    Carp::carp('Warning: '.$self->make_message(@_));
}

=head2 make_message($segment, $message, @items)

Formats and returns the message according to
debug/verbose levels and the provided arguments.

There are two/three parts to the message:

    segment_name: message <items>

The message part is simply $message for all debug/verbose
levels.

The items part is only included when verbose > 1.  It is
a comma-separated join of @items, surrounded by angle
brackets (<>).

If verbose and debug are both 0, segment_name is simply
the segment's label.  If verbose > 0, the full path of
the segment is used instead of the label.  If debug > 1,
the segment's ID is appended to the label/path in
parentheses.

=cut

sub make_message {
    my ($self, $segment, $message, @items) = @_;

    $message = ($self->verbose ? $segment->path : $segment->label)
        . ($self->debug > 1 ? ' (' . $segment->id . '): ' : ': ')
        . $message;

    if ($self->verbose > 1 and @items) {
        $message .= ' <'.join(',', @items).'>';
    }

    return $message;
}

1;
