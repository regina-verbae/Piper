#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Instance;

use v5.10;
use strict;
use warnings;

use List::AllUtils qw(last_value);
use List::UtilsBy qw(max_by);

use Moo;
use namespace::clean;

with qw(
    Piper::Role::Instance
);

use overload (
    q{""} => sub { $_[0]->path },
    fallback => 1,
);

sub isnt_exhausted {
    my ($self) = @_;
    
    # Try to get something ready
    while(!$self->ready and $self->pending) {
        $self->process_batch;
    }

    return $self->ready ? 1 : 0;
}

sub process_batch {
    my ($self) = @_;
    if ($self->has_children) {
        my $best;
        # Full-batch process closest to drain
        if ($best = last_value { $_->pressure >= 100 } @{$self->children}) {
            $self->DEBUG("Chose batch $best: full-batch process closest to drain");
        }
        # If no full batch, choose the one closest to full
        else {
            $best = max_by { $_->pressure } @{$self->children};
            $self->DEBUG("Chose batch $best: closest to full-batch");
        }
        $best->process_batch;
    }
    else {
        my $num = $self->get_batch_size;
        $self->DEBUG("Processing batch with max size", $num);

        my @batch = $self->queue->dequeue($num);
        $self->INFO("Processing batch", @batch);

        #TODO: Remove auto-emitting return values?
        my @things = $self->segment->handler->(
            $self,
            \@batch,
            @{$self->args}
        );

        if (@things) {
            $self->INFO("Auto-emitting", @things);
            $self->drain->enqueue(@things);
        }
    }
}

1;
