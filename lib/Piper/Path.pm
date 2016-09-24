#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Simple path object for labeling locations in pipelines
#####################################################################

package Piper::Path;

use v5.10;
use strict;
use warnings;

use Types::Standard qw(ArrayRef Str);

use Moo;
use namespace::clean;

use overload (
    q{""} => sub { $_[0]->stringify },
    fallback => 1,
);

=head1 SYNOPSIS

    use Piper::Path;

    # grandparent/parent/child
    my $path = Piper::Path->new(qw(
        grandparent parent child
    ));

    # grandparent/parent/child/grandchild
    $path->child('grandchild');

    # (qw(grandparent parent child))
    $path->split;

    # child
    $path->name;

    # 'grandparent/parent/child'
    $path->stringify;
    "$path";

=head1 DESCRIPTION

Simple filesystem-like representation of a
pipeline segment's placement in the pipeline,
relative to containing segments.

=head1 CONSTRUCTOR

=head2 new(@path_segments)

Creates a Piper::Path object from the given
path segments.

Segments may be single path elements (similar
to a file name), joined path elements (with '/'),
or Piper::Path objects.

The following create equivalent objects:

    Piper::Path->new(qw(grandparent parent child));
    Piper::Path->new(qw(grandparent/parent child));
    Piper::Path->new(
        Piper::Path->new(qw(grandparent parent)),
        qw(child)
    );

=cut

has path => (
    is => 'ro',
    isa => ArrayRef[Str],
);

around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;
    
    my @pieces;
    for my $part (@args) {
        if (eval { $part->isa('Piper::Path') }) {
            push @pieces, $part->split;
        }
        elsif (ref $part eq 'ARRAY') {
            push @pieces, map { split('/', $_) } @$part;
        }
        else {
            push @pieces, split('/', $part);
        }
    }
    return $self->$orig(
        path => [ @pieces ],
    );
};

=head1 METHODS

=head2 child(@segments)

Returns a new Piper::Path object representing the
appropriate child of $self.

    $path                     # grampa/parent
    $path->child(qw(child))   # grampa/parent/child

=cut

sub child {
    my $self = shift;
    return $self->new($self, @_);
}

=head2 name

Returns the last segment of the path, or the 'basename'.

    $path         # foo/bar/baz
    $path->name   # baz

=cut

sub name {
    my ($self) = @_;
    return $self->path->[-1];
}

=head2 split

Returns an array of the path segments.

    $path          # foo/bar/baz
    $path->split   # qw(foo bar baz)

=cut

sub split {
    my ($self) = @_;
    return @{$self->path};
}

=head2 stringify

Returns a string representation of the path, which is
simply a join of the path segments with '/'.

Note: String context is overloaded to call this method.

    "$path"  is equivalent to $path->stringify

=cut

sub stringify {
    my ($self) = @_;
    return join('/', @{$self->path});
}

1;
