#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Instance::NotMain;

use v5.22;
use warnings;

use Types::Standard qw(ConsumerOf);

use Moo::Role;

has main => (
    is => 'lazy',
    isa => ConsumerOf['Piper::Role::Instance::Main'],
    weak_ref => 1,
    handles => 'Piper::Role::Instance::Main',
);

sub _build_main {
    my ($self) = @_;
    my $parent = $self;
    while ($parent->has_parent) {
        $parent = $parent->parent;
    }
    return $parent;
}

1;
