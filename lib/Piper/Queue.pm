#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Simple FIFO queue used by Piper
#####################################################################

package Piper::Queue;

use v5.10;
use strict;
use warnings;

use Types::Standard qw(ArrayRef);

use Moo;
use namespace::clean;

with 'Piper::Role::Queue';

our $VERSION = '0.02';

=head1 SYNOPSIS

  use Piper::Queue;

  my $queue = Piper::Queue->new();
  $queue->enqueue(qw(x y));
  $queue->ready;         # 2
  $queue->dequeue;       # 'x'
  $queue->requeue('x');
  $queue->dequeue;       # 'x'

=head1 DESCRIPTION

A simple queue.

=head1 CONSTRUCTOR

=head2 new

=cut

has queue => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
);

=head1 METHODS

=head2 dequeue($num)

Remove and return at most C<$num> items from the queue.  The default S<C<$num> is 1>.

If C<$num> is greater than the number of items remaining in the queue, only the number remaining will be dequeued.

Returns an array of items if wantarray, otherwise returns the last of the dequeued items, which allows singleton dequeues:

    my @results = $queue->dequeue($num);
    my $single  = $queue->dequeue;

=cut

sub dequeue {
    my ($self, $num) = @_;
    $num //= 1;
    splice @{$self->queue}, 0, $num;
}

=head2 enqueue(@items)

Add C<@items> to the queue.

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

=head2 requeue(@items)

Inserts C<@items> to the top of the queue in an order such that C<dequeue(1)> would subsequently return C<$items[0]> and so forth.

=cut

sub requeue {
    my $self = shift;
    unshift @{$self->queue}, @_;
}

1;

__END__

=head1 SEE ALSO

=over

=item L<Piper::Role::Queue>

=item L<Piper>

=back

=cut
