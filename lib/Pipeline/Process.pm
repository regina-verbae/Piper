#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Pipeline::Process;

use v5.22;
use warnings;

use Moo;
use Types::Standard qw(Bool CodeRef Maybe Str);
use Types::Common::Numeric qw(PositiveInt);
use Types::Common::String qw(NonEmptySimpleStr);

use overload (
    q{""} => sub { $_[0]->path },
    fallback => 1,
);

has path => (
    is => 'rw',
    isa => Str,
    required => 1,
);

has label => (
    is => 'rwp',
    isa => NonEmptySimpleStr,
    required => 1,
);

has batch_size => (
    is => 'rw',
    isa => Maybe[PositiveInt],
    default => sub { return undef },
);

has handler => (
    is => 'ro',
    isa => CodeRef,
    required => 1,
);

has filter => (
    is => 'ro',
    isa => CodeRef,
    predicate => 1,
);

has enabled => (
    is => 'rw',
    isa => Bool,
    default => 1,
);

1;
