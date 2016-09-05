#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Base role for pipeline segments
#####################################################################

package Piper::Role::Segment;

use v5.10;
use strict;
use warnings;

use Types::Standard qw(Bool CodeRef HashRef InstanceOf);
use Types::Common::Numeric qw(PositiveInt);
use Types::Common::String qw(NonEmptySimpleStr);

use Moo::Role;

=head1 DESCRIPTION

This role contains attributes and methods that apply
to each pipeline segment, both individual handlers
and sub-pipes.

=head1 ATTRIBUTES

=head2 batch_size

The number of items to process at a time for
the segment.  Will inherit from a parent if
not provided.

=cut

has batch_size => (
    is => 'ro',
    isa => PositiveInt,
    predicate => 1,
);

=head2 config

A Piper::Config object defining component classes.

=cut

has config => (
    is => 'lazy',
    isa => InstanceOf['Piper::Config'],
    builder => sub { require Piper::Config; return Piper::Config->new() },
);

=head2 filter

A coderef used to filter items sent to this
segment.

It will be run on each item attempting to queue
to this segment.  If the filter returns true, the
item will be queued.  Otherwise, the item will
skip this segment and continue to the next adjacent
segment.

The item will be localized to $_, as well as
passed in as the first argument.  These example
filters are equivalent.

    # This handler only accepts digit inputs
    sub { /^\d+$/ }
    sub { $_ =~ /^\d+$/ }
    sub { $_[0] =~ /^\d+$/ }

=cut

has filter => (
    is => 'ro',
    isa => CodeRef,
    # Closure to enable sub to use $_ instead of $_[0],
    #   though $_[0] will also work
    coerce => sub {
        my $orig = shift;
        CodeRef->assert_valid($orig);
        return sub {
            my $item = shift;
            local $_ = $item;
            $orig->($item);
        };
    },
    predicate => 1,
);

=head2 enabled

Set this to false to disable the segment for all
items.  Defaults to true.

=cut

has enabled => (
    is => 'rw',
    isa => Bool,
    default => 1,
);

#TODO explain

has extra => (
    is => 'rwp',
    isa => HashRef,
    predicate => 1,
);

=head2 id

A globally uniq ID for the segment.  This is primarily
useful for debugging only.

=cut

has id => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    builder => sub {
        my ($self) = @_;
        state $id = {};
        my $base = ref $self;
        $id->{$base}++;
        return "$base$id->{$base}";
    },
);

requires 'init';

around init => sub {
    my ($orig, $self, @args) = @_;
    state $call = 0;
    $call++;
    my $main = $call == 1 ? 1 : 0;

    my $instance = $self->$orig();

    if ($main) {
        # Set the args in the main instance
        $instance->_set_args(\@args);

        # Reset $call (global) for other objects
        $call = 0;
    }

    return $instance;
};

=head2 label

A label for this segment.  If no label is provided, the
segment's id will be used.

Labels are particularly needed if handlers wish to use
the injectAt method.  Otherwise, labels are still very
useful for debugging.

=cut

has label => (
    is => 'rwp',
    isa => NonEmptySimpleStr,
    lazy => 1,
    builder => sub {
        my $self = shift;
        return $self->id;
    },
);

1;
