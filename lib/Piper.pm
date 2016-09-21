#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper;

use v5.10;
use strict;
use warnings;

use Piper::Instance;
use Piper::Process;
use Types::Standard qw(ArrayRef ConsumerOf Tuple slurpy);

use Moo;
use namespace::autoclean;

with qw(Piper::Role::Segment);

use overload (
    q{""} => sub { $_[0]->label },
    fallback => 1,
);

my $CONFIG;

sub import {
    my $class = shift;
    if (@_) {
        require Piper::Config;
        $CONFIG = Piper::Config->new(@_);
    }
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
        elsif (eval { $thing->isa('Piper::Instance') }) {
            $thing = $thing->segment;
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

    $opts{config} = $CONFIG if defined $CONFIG;

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
