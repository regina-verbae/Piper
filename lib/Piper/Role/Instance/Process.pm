#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Instance::Process;

use v5.22;
use warnings;

use Piper::Path;
use Piper::Queue;
use Types::Standard qw(InstanceOf);

use Moo::Role;

has process => (
    is => 'ro',
    isa => InstanceOf['Piper::Process'],
    handles => 'Piper::Role::Segment',
    required => 1,
);

has queue => (
    is => 'lazy',
    isa => InstanceOf['Piper::Queue'],
    builder => sub { Piper::Queue->new() },
    handles => {
        enqueue => 'enqueue',
        pending => 'ready',
    },
);

sub process_batch {
    my ($self) = @_;

    my $num = $self->get_batch_size;
    $self->DEBUG("Processing batch with max size", $num);


    my @batch = $self->queue->dequeue($num);
    $self->INFO("Processing batch", @batch);

    #TODO: Remove auto-emitting return values?
    my @things = $self->process->handler->(
        $self,
        \@batch,
        @{$self->args}
    );
    if (@things) {
        $self->INFO("Auto-emitting", @things);
        $self->drain->enqueue(@things);
    }
}

sub pressure {
    my ($self) = @_;
    return $self->pending ? int(100 * $self->pending / $self->get_batch_size) : 0;
}

1;
