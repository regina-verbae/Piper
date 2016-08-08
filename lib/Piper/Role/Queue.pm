#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Queue;

use v5.22;
use warnings;

use Moo::Role;

requires 'dequeue';
requires 'enqueue';

# Number queued at some level but not ready for dequeue
requires 'pending';

# Number ready for dequeue
requires 'ready';

1;
