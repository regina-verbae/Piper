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
    return $self->pending - $self->get_batch_size;
}

sub emit {
    my $self = shift;
    $self->INFO("Emitting", @_);
    # Just collect in the drain
    $self->drain->enqueue(@_);
}

sub recycle {
    my $self = shift;
    $self->INFO("Recycling", @_);
    $self->enqueue(@_);
}

sub eject {
    my $self = shift;
    $self->INFO("Ejecting to drain", @_);
    $self->main->drain->enqueue(@_);
}

sub inject {
    my $self = shift;
    $self->INFO("Injecting to ".$self->main, @_);
    $self->main->enqueue(@_);
}

sub injectAt {
    my $self = shift;
    my $location = shift;
    my $segment = $self->find_segment($location);
    $self->ERROR("Could not find $location to injectAt", @_)
        if !defined $segment;
    $self->INFO("Injecting to $location", @_);
    $segment->enqueue(@_);
}

1;
