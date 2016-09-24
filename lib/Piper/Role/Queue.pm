#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Basic queue role
#####################################################################

package Piper::Role::Queue;

use v5.10;
use strict;
use warnings;

use Moo::Role;

=pod

=head1 REQUIRES

This role requires the following object methods.

=head2 dequeue($num)

Removes and returns $num items from the queue.

Default $num should be 1.  If wantarray, should
return an array of items from the queue.  Otherwise,
should return the last of the dequeued items (allows
singleton dequeues, behaving similar to splice):

  Ex:
  my @results = $queue->dequeue($num);
  my $single = $queue->dequeue;

If requesting more items than are left in the queue,
should only return the items left in the queue (and
should not return undefs).

=cut

requires 'dequeue';

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

=head1 TESTING

Verify the functionality of a new queue class by
downloading the Piper tests and running the
following:

  PIPER_QUEUE_CLASS=<New queue class> prove t/01_Queue.t

=cut

1;
