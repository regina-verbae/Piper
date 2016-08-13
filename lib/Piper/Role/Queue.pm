#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Basic queue role
#####################################################################

package Piper::Role::Queue;

use v5.22;
use warnings;

use Moo::Role;

=pod
=head1 REQUIRES

This role requires the following object methods.

=head2 dequeue($num)

Removes and returns $num items from the queue.

=cut

requires 'dequeue';

around dequeue => sub {
    my ($orig, $self, $num) = @_;
    $num //= 1;
    $self->$orig($num);
};

=head2 enqueue(@items)

Adds the @items to the queue.  It should not matter
what the @items contain.

=cut

requires 'enqueue';

=head2 ready

Returns the number of items that are ready to
be dequeued.

=cut

requires 'ready';

1;
