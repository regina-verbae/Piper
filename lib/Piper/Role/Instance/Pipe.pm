#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Instance::Pipe;

use v5.22;
use warnings;

use List::AllUtils qw(last_value max sum);
use List::UtilsBy qw(max_by min_by);
use Types::Standard qw(ArrayRef ConsumerOf HashRef InstanceOf Tuple slurpy);

use Moo::Role;

has pipe => (
    is => 'ro',
    isa => InstanceOf['Piper'],
    handles => 'Piper::Role::Segment',
);

has children => (
    is => 'ro',
    # Force to contain at least one child
    isa => Tuple[ConsumerOf['Piper::Role::Instance'],
        slurpy ArrayRef[ConsumerOf['Piper::Role::Instance']]
    ],
    required => 1,
);

sub pressure {
    my ($self) = @_;
    # Return the max among the children
    my $max = max(map { $_->pressure } @{$self->children});
}

sub enqueue {
    my $self = shift;
    $self->children->[0]->enqueue(@_);
}

sub pending {
    my $self = shift;
    return sum(map { $_->pending } @{$self->children});
}

sub process_batch {
    my ($self) = @_;

    my $best;
    # Overflowing process closest to drain
    if ($best = last_value { $_->pressure > 0 } @{$self->children}) {
        $self->DEBUG("Chose batch $best: overflowing process closest to drain");
    }
    # If no overflowing processes, choose the one closest to overflow
    else {
        $best = max_by { $_->pressure } @{$self->children};
        $self->DEBUG("Chose batch $best: closest to overflow");
    }
    
    $best->process_batch;
    
    # Emit results to next segment
    if (my $ready = $best->ready) {
        $self->follower->{$best}->enqueue(
            $best->dequeue($ready)
        );
    }
}

has directory => (
    is => 'lazy',
    isa => HashRef,
);

sub _build_directory {
    my ($self) = @_;
    my %dir;
    for my $child (@{$self->children}) {
        $dir{$child->path->name} = $child;
    }
    return \%dir;
}

has follower => (
    is => 'lazy',
    isa => HashRef,
);

sub _build_follower {
    my ($self) = @_;
    my %follow;
    for my $index (keys @{$self->children}) {
        if (defined $self->children->[$index + 1]) {
            $follow{$self->children->[$index]} =
                $self->children->[$index + 1];
        }
        else {
            $follow{$self->children->[$index]} = $self->drain;
        }
    }
    return \%follow;
}

sub descendant {
    my ($self, $path, $referrer) = @_;

    my @pieces = $path->split;
    my $descend = $self;
    while (defined $descend and @pieces) {
        if (exists $descend->directory->{$pieces[0]}) {
            $descend = $descend->directory->{$pieces[0]};
            shift @pieces;
        }
        else {
            $descend = undef;
        }
    }

    unless (defined $descend) {
        $referrer //= '';

        my @possible = grep {
            defined
        } map {
            $_->descendant($path)
        } grep {
            $_->can('descendant')
        } grep {
            # Don't search the referrer's tree - already done
            $_ ne $referrer
        } @{$self->children};

        return unless @possible;

        $descend = min_by { $_->path->split } @possible;
    }

    return $descend;
}

1;
