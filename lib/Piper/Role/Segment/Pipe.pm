#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Role for a pipeline of segments
#####################################################################

package Piper::Role::Segment::Pipe;

use v5.10;
use strict;
use warnings;

use Piper::Instance;
use Types::Standard qw(ArrayRef ConsumerOf Tuple slurpy);

use Moo::Role;

=head1 ATTRIBUTES

=head2 children

An arrayref of segments that together make up this
pipeline.  Child segments can be processes or
pipes.

This attribute is required.

=cut

has children => (
    is => 'rwp',
    # Force to contain at least one child
    isa => Tuple[ConsumerOf['Piper::Role::Segment'],
        slurpy ArrayRef[ConsumerOf['Piper::Role::Segment']]
    ],
    required => 1,
);

=head1 METHODS

=head2 init

Returns a Piper::Instance object for this pipeline.
It also initializes all the child segments and sets
itself as the parent for each child instance.

=cut

sub init {
    my $self = shift;

    my $instance = Piper::Instance->new(
		segment => $self,
		children => [
			map { $_->init } @{$self->children}
		],
	);

    # Set parents for children
    for my $child (@{$instance->children}) {
        $child->_set_parent($instance);
    }

    return $instance;
}

1;
