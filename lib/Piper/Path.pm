#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Simple path object for labeling locations in pipelines
#####################################################################

package Piper::Path;

use v5.22;
use warnings;

use Types::Standard qw(ArrayRef Str);

use Moo;
use namespace::clean;

use overload (
    q{""} => sub { $_[0]->stringify },
    fallback => 1,
);

has path => (
    is => 'ro',
    isa => ArrayRef[Str],
);

=head1 CONSTRUCTOR

=head2 new(@segments)

Ex:
    new(qw(grandparent parent child))
    new(qw(grandparent/parent child))
    new($parent_path_object, qw(child))

=cut

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

Returns a new path object representing the appropriate
child of $self.

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
