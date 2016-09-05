#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Base role for pipeline segments
#####################################################################

package Piper::Role::Segment::Process;

use v5.10;
use strict;
use warnings;

use Piper::Instance;
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

    return Piper::Instance->new(
        segment => $self,
    );
}

1;
