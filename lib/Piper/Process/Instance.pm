#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Process::Instance;

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
    $self->INFO("Processing batch with max size", $num);

    #TODO: Remove auto-emitting return values?
    $self->drain->enqueue(
        $self->process->handler->(
            $self,
            [ $self->queue->dequeue($num) ],
            @{$self->args}
        )
    );
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
        handles => [qw(enqueue pending)],
    );

    has drain => (
        is => 'lazy',
        isa => InstanceOf['Piper::Queue'],
        builder => sub { Piper::Queue->new() },
        handles => [qw(dequeue ready)],
    );
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
    $self->INFO("Injecting to $location", @_);
}

sub find_segment {
    my ($self, $location) = @_;
    
}

1;
