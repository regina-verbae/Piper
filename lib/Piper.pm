#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper;

use v5.16;
use warnings;

use Piper::Process;

use Moo;

with qw(
    Piper::Role::Segment
    Piper::Role::Segment::Pipe
);

use overload (
    q{""} => sub { $_[0]->label },
    fallback => 1,
);

sub default_batch_size {
    return 50;
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
        elsif (eval { $thing->isa('Piper::Instance::Process') }) {
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
