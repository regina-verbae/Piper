#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Role for process handlers
#####################################################################

package Piper::Role::Segment::Process;

use v5.10;
use strict;
use warnings;

use Piper::Instance;
use Types::Standard qw(CodeRef);

use Moo::Role;

=head1 ATTRIBUTES

=head2 handler

The data-processing subroutine for this segment.

The arguments provided to the handler are as follows:

    $instance - the instance corresponding to the segment
    $batch    - an arrayref of items to process
    @args     - the init arguments (if any) provided
                at the initialization of the pipeline

Via the provided $instance object, the handler
has several options for sending data to other
pipes or processes in the pipeline:

    $instance->eject(@data)
    $instance->emit(@data)
    $instance->inject(@data)
    $instance->injectAfter($location, @data)
    $instance->injectAt($location, @data)
    $instance->recycle(@data)

See Piper::Role::Instance for an explantion
of these methods.

=cut

has handler => (
    is => 'ro',
    isa => CodeRef,
    required => 1,
);

=head1 METHODS

=head2 init

Returns a Piper::Instance object for this
segment.

=cut

sub init {
    my ($self) = @_;

    return Piper::Instance->new(
        segment => $self,
    );
}

1;
