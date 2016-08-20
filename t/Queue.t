#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper::Queue module
#####################################################################

use v5.22;
use warnings;

use Test::Most;

my $APP = "Piper::Queue";

use Piper::Queue;

#####################################################################

my $QUEUE = Piper::Queue->new();

# Test enqueue
{
    subtest "$APP - enqueue" => sub {
        $QUEUE->enqueue(1..5);
        is_deeply(
            $QUEUE->queue,
            [ 1..5 ],
            "ok"
        );
    };
}

# Test dequeue
{
    subtest "$APP - dequeue" => sub {
        is_deeply(
           [ $QUEUE->dequeue ],
           [ 1 ],
           "dequeue default number"
       );

       is_deeply(
           [ $QUEUE->dequeue(3) ],
           [ 2..4 ],
           "dequeue multiple"
       );

       is_deeply(
           [ $QUEUE->dequeue(5) ],
           [ 5 ],
           "requested greater than ready"
       );

       is_deeply(
           [ $QUEUE->dequeue ],
           [ ],
           "empty"
       );
   };
}

# Test ready
{
    subtest "$APP - ready" => sub {
        is($QUEUE->ready, 0, "empty");

        $QUEUE->enqueue(1..4);
        is($QUEUE->ready, 4, "non-empty");

        $QUEUE->dequeue(2);
        is($QUEUE->ready, 2, "after dequeue");
    };
}

#####################################################################

done_testing();
