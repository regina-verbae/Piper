#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Pipeline::Instance;

use v5.22;
use warnings;

use Moo;
use MCE::Queue;

#TODO: Why can't I get max_by from List::AllUtils?
use Carp;
use List::AllUtils qw(any last_value);
use List::UtilsBy qw(max_by);
use Types::Standard qw(ArrayRef HashRef InstanceOf Int Maybe Str);
use Types::Common::Numeric qw(PositiveInt);

has pipe => (
    is => 'ro',
    isa => InstanceOf['Pipeline'],
    handles => [qw(debug verbose processes next_process pipeID)],
    required => 1,
);

has instanceID => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has drain => (
    is => 'lazy',
    isa => InstanceOf['MCE::Queue'],
);

sub _build_drain {
    return MCE::Queue->new();
}

has init_args => (
    is => 'ro',
    isa => ArrayRef,
    required => 1,
);

has queue => (
    is => 'lazy',
    isa => HashRef[InstanceOf['MCE::Queue']],
);

sub _build_queue {
    my ($self) = @_;
    my %return;
    for my $proc (@{$self->processes}) {
        $return{$proc} = MCE::Queue->new();
    }
    $return{drain} = $self->drain;
    return \%return;
}

has batch_size => (
    is => 'rw',
    isa => Maybe[PositiveInt],
    default => sub { return undef },
);

has location => (
    is => 'rw',
    isa => Str,
);

### Methods

sub isnt_exhausted {
    my ($self) = @_;

    # Try to get at least one thing in the drain
    $self->_fill_drain(1);

    return $self->drain->pending
        ? 1
        : 0;
}

sub is_exhausted {
    my ($self) = @_;
    return !$self->isnt_exhausted;
}

sub inject {
    my $self = shift;
    my $location = $self->processes->[0]->path;
    $self->injectAt($location, @_);
}

sub injectAt {
    my $self = shift;
    my $location = shift;
    $location = $self->_resolve($location);
    $self->_log("Injecting into $location", @_);
    $self->queue->{$location}->enqueue(@_);
}

sub recycle {
    my $self = shift;
    my $location = $self->location;
    $self->_log("Recycling into $location", @_);
    $self->queue->{$location}->enqueue(@_);
}

sub eject {
    my $self = shift;
    $self->_log('Ejecting data to the drain', @_);
    $self->drain->enqueue(@_);
}

sub emit {
    my $self = shift;
    my $location = $self->location;
    my $next = $self->next_process->{$location} // 'drain';
    $self->_log("Emitting to $next", @_);
    $self->queue->{$next}->enqueue(@_);
}

sub next {
    my ($self, $num) = @_;
    return unless $self->isnt_exhausted;

    $num //= 1;
    $self->_fill_drain($num);

    my @return = grep { defined } $self->drain->dequeue($num);
    return wantarray ? @return : $return[0];
}

sub flush {
    my ($self) = @_;
    
    $self->_log("Flushing pipeline");
    while ($self->_more_to_process) {
        $self->_do_best_process;
    }
}

### Utility methods

sub _log {
    my $self = shift;
    return unless $self->debug;
    my $message = join(': ', $self->instanceID, shift);
    if (@_) {
        $message .= ': '.join(',', @_);
    }
    if ($self->verbose) {
        carp $message;
    }
    else {
        warn "$message\n";
    }
}

sub _more_to_process {
    my ($self) = @_;
    return (any { $self->queue->{$_}->pending } @{$self->processes})
        ? 1
        : 0;
}

sub _do_batch {
    my ($self, $proc) = @_;
    $self->_log("Processing a batch for $proc");
    # Set location
    $self->location("$proc");
    # Send data to handler
    $proc->handler->(
        $self,
        [ grep {
                defined
            } $self->queue->{$proc}->dequeue($self->_batch_size($proc))
        ],
        @{$self->init_args}
    );
}

sub _batch_size {
    my ($self, $proc) = @_;
    return $proc->batch_size
        // $self->batch_size
        // $self->pipe->batch_size;
}

sub _batch_overflow {
    my ($self, $proc) = @_;
    return $self->queue->{$proc}->pending - $self->_batch_size($proc);
}

sub _do_best_process {
    my ($self) = @_;

    my $best;
    my %overflow = map {
        $_ => $self->_batch_overflow($_)
    } @{$self->processes};
    
    # Try the overflowing process closest to drain
    if ($best = last_value { $overflow{$_} >= 0 } @{$self->processes}) {
        $self->_log(
            "Best process $best overflowing batch by $overflow{$best}"
        );
    }
    # If there are no overflowing processes, choose the one closest
    #   to overflow
    else {
        $best = max_by { $overflow{$_} } @{$self->processes};
        $self->_log(
            "Best process $best underflowing batch by $overflow{$best}"
        );
    }

    $self->_do_batch($best);
}

sub _fill_drain {
    my ($self, $num) = @_;

    while ($self->drain->pending < $num and $self->_more_to_process) {
        $self->_do_best_process;
    }
}

sub _resolve {
    my ($self, $label) = @_;

    return $label if $label =~ m{^main/} and exists $self->queue->{$label};

    my $location = $self->location;
    if ($location) {
        my $parent;
        while ($parent = _parentPath($parent // $location)) {
            my $path = join('/', $parent, $label);
            return $path if exists $self->queue->{$path};
        }
    }
    else {
        my $path = join('/', 'main', $label);
        return $path if exists $self->queue->{$path};
    }

    die "Cannot resolve label $label!";
}

sub _parentPath {
    my ($path) = @_;
    my @parts = split('/', $path);
    pop @parts;
    return join('/', @parts);
}

1;
