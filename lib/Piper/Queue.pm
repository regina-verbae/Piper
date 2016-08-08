#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Queue;

use v5.16;
use warnings;

use MCE::Queue;
use Types::Standard qw(InstanceOf);

use Moo;

with 'Piper::Role::Queue';

BEGIN {
    has queue => (
        is => 'ro',
        isa => InstanceOf['MCE::Queue'],
        builder => sub { MCE::Queue->new() },
        handles => {
            enqueue => 'enqueue',
            pending => 'pending',
            ready => 'pending',
        },
    );
}

sub dequeue {
    my ($self, $num) = @_;
    my @results = grep { defined } $self->queue->dequeue($num);
    return wantarray ? @results : $results[0];
}

1;
