#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Instance;

use v5.22;
use warnings;

use List::AllUtils qw(part);
use Piper::Logger;
use Piper::Path;
use Types::Standard qw(ArrayRef ConsumerOf InstanceOf Str);
use Types::Common::String qw(NonEmptySimpleStr);

use Moo::Role;

with qw(Piper::Role::Queue);

requires 'pending';

requires 'process_batch';

# Metric for "how full" the pending queue is
requires 'pressure';

has args => (
    is => 'rwp',
    isa => ArrayRef,
);

has location => (
    is => 'rw',
    isa => Str,
);

has parent => (
    is => 'rwp',
    isa => ConsumerOf['Piper::Role::Instance'],
    # Setting a parent will introduce a self-reference
    weak_ref => 1,
    required => 0,
    predicate => 1,
);

sub is_enabled {
    my ($self) = @_;

    return 0 if !$self->enabled;
    # Check all the parents...
    my $par = $self;
    while ($par->has_parent) {
        $par = $par->parent;
        return 0 if !$par->enabled;
    }
    return 1;
}

has main => (
    is => 'lazy',
    isa => ConsumerOf['Piper::Role::Instance'],
    weak_ref => 1,
);

sub _build_main {
    my ($self) = @_;
    my $parent = $self;
    while ($parent->has_parent) {
        $parent = $parent->parent;
    }
    return $parent;
}

has path => (
    is => 'lazy',
    isa => InstanceOf['Piper::Path'],
);

sub _build_path {
    my ($self) = @_;

    return $self->has_parent
        ? $self->parent->path->child($self->label)
        : Piper::Path->new($self->label);
}

has logger => (
    is => 'lazy',
    isa => ConsumerOf['Piper::Role::Logger'],
    handles => 'Piper::Role::Logger',
);

sub _build_logger {
    my ($self) = @_;

    return $self->has_parent
        ? $self->parent->logger
        : Piper::Logger->new($self->has_extra ? $self->extra : ());
}

around [qw(INFO DEBUG WARN ERROR)] => sub {
    my ($orig, $self) = splice @_, 0, 2;
    $self->$orig($self, @_);
};

sub get_batch_size {
    my ($self) = @_;
    my $size = $self->has_batch_size
        ? $self->batch_size
        : $self->has_parent
            ? $self->parent->get_batch_size
            : 50;
    return $size;
}

sub is_exhausted {
    my ($self) = @_;
    return !$self->isnt_exhausted;
}

sub isnt_exhausted {
    my ($self) = @_;
    
    # Try to get something ready
    while(!$self->ready and $self->pending) {
        $self->process_batch;
    }

    return $self->ready ? 1 : 0;
}

sub find_segment {
    my ($self, $location) = @_;
    
    $location = Piper::Path->new($location);
    my $parent = $self;
    my $segment = $parent->descendant($location);
    while (!defined $segment and $parent->has_parent) {
        $parent = $parent->parent;
        $segment = $parent->descendant($location);
    }

    return $segment;
}

sub descendant {
    my ($self, $path) = @_;

    my @pieces = @{$path->path};
    while (@pieces) {
        if ($self->can('directory')
                and exists $self->directory->{$pieces[0]}
        ) {
            $self = $self->directory->{$pieces[0]};
            shift @pieces;
        }
        else {
            return;
        }
    }
    return $self;
}

around enqueue => sub {
    my ($orig, $self, @args) = @_;

    if (!$self->is_enabled) {
        # Bypass - go straight to drain
        $self->INFO("Skipping disabled process", @args);
        $self->drain->enqueue(@args);
        return;
    }

    my @items;
    if ($self->has_filter) {
        my ($skip, $queue) = part {
            $self->filter->($_)
        } @args;

        @items = @$queue if defined $queue;

        if (defined $skip) {
            $self->INFO("Filtered items to next handler", @$skip);
            $self->drain->enqueue(@$skip);
        }
    }
    else {
        @items = @args;
    }

    return unless @items;

    $self->INFO("Queueing items", @items);
    $self->$orig(@items);
};

1;
