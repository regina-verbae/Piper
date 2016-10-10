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

=head1 METHODS

=head2 DEBUG($segment, $message, @items)

This method will be a no-op unless $self->debug_level($segment) > 0.

Prints an informational message to STDERR.

Uses the method make_message to format the printed message according to
debug/verbose levels and the arguments.

Labels the message by pre-pending 'Info: ' to the formatted message.

=cut

sub DEBUG {
    my $self = shift;
    $self->INFO(@_);
}

=head2 ERROR($segment, $message, @items)

Prints an error to STDERR and dies via Carp::croak.

Uses the method make_message to format the printed message according to
debug/verbose levels and the arguments.

Labels the message by pre-pending 'Error: ' to the formatted message.

=cut

sub ERROR {
    my $self = shift;
    Carp::croak('Error: '.$self->make_message(@_));
}

=head2 INFO($segment, $message, @items)

This method will be a no-op unless $self->verbose_level($segment) > 0 or
$self->debug_level($segment) > 0.

Prints an informational message to STDERR.

Uses the method make_message to format the printed message according to
debug/verbose levels and the arguments.

Labels the message by pre-pending 'Info: ' to the formatted message.

=cut

sub INFO {
    my $self = shift;
    say STDERR 'Info: '.$self->make_message(@_);
}

=head2 WARN($segment, $message, @items)

Prints a warning to STDERR via Carp::carp.

Uses the method make_message to format the printed message according to
debug/verbose levels and the arguments.

Labels the message by pre-pending 'Warning: ' to the formatted message.

=cut

sub WARN {
    my $self = shift;
    Carp::carp('Warning: '.$self->make_message(@_));
}

=head1 UTILITY METHODS

=head2 make_message($segment, $message, @items)

Formats and returns the message according to debug/verbose levels and the
provided arguments.

There are two/three parts to the message:

    segment_name: message <items>

The message part is simply $message for all debug/verbose levels.

The <items> part is only included when $self->verbose_level($segment) > 1.  It
is a comma-separated join of @items, surrounded by angle brackets (<>).

If the verbosity and debug levels are both 0, segment_name is simply the
segment's label.  If $self->verbose_level($segment) > 0, the full path of the
segment is used instead of the label.  If $self->debug_level($segment) > 1, the
segment's ID is appended to the label/path in parentheses.

=cut

sub make_message {
    my ($self, $segment, $message, @items) = @_;

    $message = ($self->verbose_level($segment) ? $segment->path : $segment->label)
        . ($self->debug_level($segment) > 1 ? ' (' . $segment->id . '): ' : ': ')
        . $message;

    if ($self->verbose_level($segment) > 1 and @items) {
        $message .= ' <'.join(',', @items).'>';
    }

    return $message;
}

=head2 debug_level($segment)

=head2 verbose_level($segment)

These methods determine the appropriate debug and verbosity levels for the
given $segment, while respecting any environment variable overrides.

Available environment variable overrides:

    PIPER_DEBUG
    PIPER_VERBOSE

=cut

1;
