#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Base role for pipeline segments
#####################################################################

package Piper::Role::Segment::Process;

use v5.22;
use warnings;

use Piper::Instance::Process;
use Types::Standard qw(CodeRef);

use Moo::Role;

has handler => (
    is => 'ro',
    isa => CodeRef,
    required => 1,
);

=head2 init

=cut

sub init {
    my ($self) = @_;

    return Piper::Instance::Process->new(
        process => $self,
    );
}

1;
