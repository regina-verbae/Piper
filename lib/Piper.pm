#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper;

use v5.16;
use warnings;

use Piper::Instance;
use Piper::Process;
use Types::Standard qw(ArrayRef ConsumerOf);

use Moo;

with qw(Piper::Role::Segment);

use overload (
    q{""} => sub { $_[0]->label },
    fallback => 1,
);

has children => (
    is => 'rwp',
    isa => ArrayRef[ConsumerOf['Piper::Role::Segment']],
    required => 1,
);

sub init {
    my $self = shift;
    my $instance = Piper::Instance->new(
        pipe => $self,
        children => [
            map { $_->init(@_) } @{$self->children}
        ],
    );

    # Set parents for children
    for my $child (@{$instance->children}) {
        $child->_set_parent($instance);
    }

    return $instance;
}

sub default_batch_size {
    return 50;
}

sub _build_id {
    state $id = 0;
    $id++;
    return __PACKAGE__.$id;
}

around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;

    my %opts;
    my %hash;
    while (my $thing = shift @args) {
        my $label;
        if (!ref $thing) {
            $label = $thing;
            $thing = shift @args;
        }

        if (eval { $thing->isa('Piper') }
                or eval { $thing->isa('Piper::Process') }
        ) {
            $thing->_set_label($label) if $label;
            push @{$hash{children}}, $thing;
        }
        elsif (eval { $thing->isa('Piper::Process::Instance') }) {
            $thing = $thing->process;
            $thing->_set_label($label) if $label;
            push @{$hash{children}}, $thing;
        }
        elsif (eval { $thing->isa('Piper::Instance') }) {
            $thing = $thing->pipe;
            $thing->_set_label($label) if $label;
            push @{$hash{children}}, $thing;
        }
        elsif ((ref $thing eq 'CODE') or (ref $thing eq 'HASH')) {
            $thing = Piper::Process->new(
                ($label ? $label : ()),
                $thing
            );
            push @{$hash{children}}, $thing;
        }

        if (@args == 1
                and ref $args[-1] eq 'HASH'
                and !exists $args[-1]->{handler}
        ) {
            %opts = %{shift @args};
        }
    }

    return $self->$orig(%opts, %hash);
};

sub BUILD {
    my ($self, $args) = @_;

    my %extra;
    for my $key (keys %$args) {
        $extra{$key} = $args->{$key} unless $self->can($key);
    }
    
    $self->_set_extra(\%extra) if keys %extra;
}

1;
