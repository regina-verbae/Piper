#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Role for logging/messaging from Piper
#####################################################################

package Piper::Role::Logger;

use v5.22;
use warnings;

use Carp qw();
use Types::Common::Numeric qw(PositiveOrZeroNum);

use Moo::Role;

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

=cut

has verbose => (
    is => 'rw',
    isa => PositiveOrZeroNum,
    coerce => sub {
        # Environment variable always wins
        my $value = shift;
        return $ENV{PIPER_VERBOSE} // $value;
    },
    default => 0,
);

has debug => (
    is => 'rw',
    isa => PositiveOrZeroNum,
    coerce => sub {
        # Environment variable always wins
        my $value = shift;
        return $ENV{PIPER_DEBUG} // $value;
    },
    default => 0,
);

=head1 REQUIRES

This role requires the definition of the following
methods.

Each method will be provided the following arguments:

  $segment  # The pipeline segment calling the method
  $message  # The (string) message sent
  @items    # Any specific items the message is about

=head2 INFO

This method is only called if verbose > 0 or debug > 0.

=cut

requires 'INFO';

around INFO => sub {
    my ($orig, $self) = splice @_, 0, 2;
    return unless $self->verbose or $self->debug;
    $self->$orig(@_);
};

=head2 DEBUG

This method is only called if debug > 0.

=cut

requires 'DEBUG';

around DEBUG => sub {
    my ($orig, $self) = splice @_, 0, 2;
    return unless $self->debug;
    $self->$orig(@_);
};

=head2 WARN

=cut

requires 'WARN';

=head2 ERROR

The method should cause a die.  It will do so
automatically if not done explicitly, though with
an extremely generic and unhelpful message.

=cut

requires 'ERROR';

after ERROR => sub {
    die "ERROR encountered";
};

1;
