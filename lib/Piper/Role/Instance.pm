#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Instance;

use v5.22;
use warnings;

use Piper::Logger;
use Piper::Path;
use Types::Standard qw(ArrayRef ConsumerOf InstanceOf Str);
use Types::Common::String qw(NonEmptySimpleStr);

use Moo::Role;

with qw(Piper::Role::Queue);

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

1;
