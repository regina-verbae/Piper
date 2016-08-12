#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Path;

use v5.22;
use warnings;

use Types::Standard qw(ArrayRef Str);

use Moo;

use overload (
    q{""} => sub { $_[0]->stringify },
    fallback => 1,
);

has path => (
    is => 'ro',
    isa => ArrayRef[Str],
);

sub stringify {
    my ($self) = @_;
    return join('/', @{$self->path});
}

sub name {
    my ($self) = @_;
    return $self->path->[-1];
}

sub child {
    my $self = shift;
    return $self->new($self, @_);
}

sub sibling {
    my $self = shift;
    my @pieces = @{$self->path};
    splice @pieces, -1, 1, @_;
    return $self->new(@pieces);
}

sub parent {
    my ($self, $num) = @_;
    $num //= 1;
    my @pieces = @{$self->path};
    splice @pieces, -$num;
    return $self->new(@pieces);
}

around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;
    
    my @pieces;
    for my $part (@args) {
        if (eval { $part->isa('Piper::Path') }) {
            push @pieces, @{$part->path};
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

1;
