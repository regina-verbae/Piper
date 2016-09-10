#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Simple FIFO queue
#####################################################################

package Piper::Queue;

use v5.10;
use strict;
use warnings;

use Types::Standard qw(ArrayRef);

use Moo;
use namespace::clean;

with 'Piper::Role::Queue';

=head1 CONSTRUCTOR

=head2 new

=cut

=head1 ATTRIBUTES

=head2 queue

=cut

has queue => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
);

=head1 METHODS

=head2 dequeue($num)

Remove and return $num items from the queue.

=cut

sub dequeue {
    my ($self, $num) = @_;
    $num //= 1;
    splice @{$self->queue}, 0, $num;
}

=head2 enqueue(@items)

Insert @items onto the queue.

=cut

sub enqueue {
    my $self = shift;
    push @{$self->queue}, @_;
}

=head2 ready

Returns the number of elements in the queue.

=cut

sub ready {
    my ($self) = @_;
    return scalar @{$self->queue};
}

1;
