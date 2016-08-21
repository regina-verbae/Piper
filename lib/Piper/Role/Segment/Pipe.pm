#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Base role for pipeline segments
#####################################################################

package Piper::Role::Segment::Pipe;

use v5.22;
use warnings;

use Piper::Instance;
use Types::Standard qw(ArrayRef ConsumerOf);

use Moo::Role;

has children => (
    is => 'rwp',
    isa => ArrayRef[ConsumerOf['Piper::Role::Segment']],
    required => 1,
);

=head2 init

=cut

sub init {
    my $self = shift;

    my $instance = Piper::Instance->new(
		pipe => $self,
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
