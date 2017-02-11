#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Basic queue role used by Piper
#####################################################################

package Piper::Role::Queue;

use v5.10;
use strict;
use warnings;

use Moo::Role;

=pod

=head1 DESCRIPTION

A basic queue role for queues used throughout the L<Piper> system.

The role exists to support future subclassing of L<Piper> (and L<testing|/TESTING> such subclasses) with alternative queueing systems.

=head1 REQUIRES

This role requires the following object methods.

=head2 dequeue($num)

Removes and returns C<$num> items from the queue.

Default C<$num> should be 1.  If wantarray, should return an array of items from the queue.  Otherwise, should return the last of the dequeued items (allows singleton dequeues, behaving similar to splice):

  Ex:
  my @results = $queue->dequeue($num);
  my $single = $queue->dequeue;

If requesting more items than are left in the queue, should only return the items left in the queue (and should not return C<undef>s as placeholders).

=cut

requires 'dequeue';

=head2 enqueue(@items)

Adds the C<@items> to the queue.  It should not matter what the C<@items> contain, within reason.

=cut

requires 'enqueue';

=head2 ready

Returns the number of items that are ready to be dequeued.

=cut

requires 'ready';

=head2 requeue(@items)

Inserts the C<@items> to the top of the queue in an order such that C<dequeue(1)> would subsequently return C<$items[0]> and so forth.

=cut

requires 'requeue';

=head1 TESTING

Verify the functionality of a new queue class by downloading the L<Piper> tests and running the
following:

  PIPER_QUEUE_CLASS=<New queue class> prove t/01_Queue.t

=cut

1;

__END__

=head1 SEE ALSO

=over

=item L<Piper>

=back

=cut
