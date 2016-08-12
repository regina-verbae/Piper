#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Process::Instance;

use List::AllUtils qw(part);
use Piper::Path;
use Piper::Queue;
use Types::Standard qw(InstanceOf);

use Moo;

with qw(Piper::Role::Instance);

use overload (
    q{""} => sub { $_[0]->path },
    fallback => 1,
);

has process => (
    is => 'ro',
    isa => InstanceOf['Piper::Process'],
    handles => 'Piper::Role::Segment',
    required => 1,
);

sub process_batch {
    my ($self) = @_;

    my $num = $self->get_batch_size;
    #my $parent = $self->has_parent ? $self->parent : $self;
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

BEGIN {
    has queue => (
        is => 'lazy',
        isa => InstanceOf['Piper::Queue'],
        builder => sub { Piper::Queue->new() },
        handles => [qw(pending)],
    );

    has drain => (
        is => 'lazy',
        isa => InstanceOf['Piper::Queue'],
        builder => sub { Piper::Queue->new() },
        handles => [qw(dequeue ready)],
    );
}

sub enqueue {
    my $self = shift;
    my @args;
    if ($self->has_filter) {
        my ($skip, $queue) = part {
            $self->filter->($_)
        } @_;
        @args = @$queue if defined $queue;
        if (defined $skip) {
            $self->INFO("Filtered items to next handler", @$skip);
            $self->emit(@$skip);
        }
    }
    else {
        @args = @_;
    }

    return unless @args;

    $self->INFO("Queueing items", @args);
    $self->queue->enqueue(@args);
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
