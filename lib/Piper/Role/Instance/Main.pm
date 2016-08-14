#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Instance::Main;

use v5.22;
use warnings;

use Piper::Logger;
use Types::Standard qw(ArrayRef ConsumerOf);

use Moo::Role;

with qw(Piper::Role::Logger);

has args => (
    is => 'rwp',
    isa => ArrayRef,
);

BEGIN {
    has logger => (
        is => 'lazy',
        isa => ConsumerOf['Piper::Role::Logger'],
        handles => 'Piper::Role::Logger',
    );

    sub _build_logger {
        my ($self) = @_;

        return Piper::Logger->new(
            $self->has_extra ? $self->extra : ()
        );
    }
}

1;
