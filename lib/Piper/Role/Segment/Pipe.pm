#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Base role for pipeline segments
#####################################################################

package Piper::Role::Segment::Pipe;

use v5.22;
use warnings;

use Piper::Instance;
use Piper::Instance::Main;
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

    my $instance;
    if (_is_main()) {
        $instance = Piper::Instance::Main->new(
            pipe => $self,
            children => [
                map { $_->init } @{$self->children}
            ],
        );

        # Set the args in the main instance
        my @args = @_;
        $instance->_set_args(\@args);
    }
    else {
        $instance = Piper::Instance->new(
            pipe => $self,
            children => [
                map { $_->init } @{$self->children}
            ],
        );
    }

    # Set parents for children
    for my $child (@{$instance->children}) {
        $child->_set_parent($instance);
    }

    return $instance;
}

sub _is_main {
    # This + role composition = skip 2
    my $level = 2;
    # For standard Piper, this is 'Piper::init'
    my $current = (caller $level++)[3];
    while (my $caller = (caller $level++)[3]) {
        # If another Piper::init is in the call stack,
        #   this cannot be the main pipeline.
        return 0 if $caller eq $current;
    }
    return 1;
}

1;
