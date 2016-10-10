#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper;

use v5.10;
use strict;
use warnings;

use Carp;
use Piper::Instance;
use Piper::Process;
use Types::Standard qw(ArrayRef ConsumerOf Tuple slurpy);

use Moo;
use namespace::clean;

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

    my $opts;
    my @children;
    my $label;
    for my $i (keys @args) {
        # Label
        if (!ref $args[$i]) {
            croak 'ERROR: Label ('.($label // $args[$i]).') missing a segment'
                if defined $label or !exists $args[$i+1];
            $label = $args[$i];
            next;
        }

        # Options hash
        if (!defined $opts and ref $args[$i] eq 'HASH'
                # Options should not be labeled
                and !defined $label
                # Options shouldn't have a handler
                and !exists $args[$i]->{handler}
        ) {
            $opts = $args[$i];
            next;
        }

        # Segment
        my $thing = $args[$i];
        if (eval { $thing->isa('Piper') }
                or eval { $thing->isa('Piper::Process') }
        ) {
            $thing->_set_label($label) if $label;
            push @children, $thing;
        }
        elsif (eval { $thing->isa('Piper::Instance') }) {
            $thing = $thing->segment;
            $thing->_set_label($label) if $label;
            push @children, $thing;
        }
        elsif ((ref $thing eq 'CODE') or (ref $thing eq 'HASH')) {
            croak 'ERROR: Segment is missing a handler [ '
                    . ($label ? "label => $label" : "position => $i") . ' ]'
                if ref $thing eq 'HASH' and !exists $thing->{handler};

            $thing = Piper::Process->new(
                ($label ? $label : ()),
                $thing
            );
            push @children, $thing;
        }
        else {
            croak 'ERROR: Cannot coerce type ('.(ref $thing).') into a segment [ '
                . ($label ? "label => $label" : "position => $i") . ' ]';
        }

        undef $label;
    }

    croak 'ERROR: No segments provided to constructor' unless @children;

    $opts->{config} = $CONFIG if defined $CONFIG;

    return $self->$orig(
        %$opts,
        children => \@children,
    );
};

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
