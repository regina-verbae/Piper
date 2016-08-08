#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Segment;

use v5.22;
use warnings;

use Types::Standard qw(Bool CodeRef ConsumerOf HashRef Maybe);
use Types::Common::Numeric qw(PositiveInt);
use Types::Common::String qw(NonEmptySimpleStr);

use Moo::Role;

requires '_build_id';

requires 'init';

around init => sub {
    my ($orig, $self, @args) = @_;

    my $instance = $self->$orig();

    # Now we have an instance, which has args
    $instance->_set_args(\@args);

    return $instance;
};

has batch_size => (
    is => 'ro',
    isa => PositiveInt,
    predicate => 1,
);

has filter => (
    is => 'rwp',
    isa => CodeRef,
    predicate => 1,
);

has enabled => (
    is => 'rwp',
    isa => Bool,
    default => 1,
);

has id => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    builder => 1,
);

has label => (
    is => 'rwp',
    isa => NonEmptySimpleStr,
    lazy => 1,
    builder => 1,
);

sub _build_label {
    my $self = shift;
    return $self->id;
}

has extra => (
    is => 'rwp',
    isa => HashRef,
    predicate => 1,
);

1;
