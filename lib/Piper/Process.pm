#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Process;

use v5.16;
use warnings;

use Moo;

with qw(
    Piper::Role::Segment
    Piper::Role::Segment::Process
);

use overload (
    q{""} => sub { $_[0]->label },
    fallback => 1,
);

sub _build_id {
    state $id = 0;
    $id++;
    return __PACKAGE__.$id;
}

around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;

    die "Too many arguments to constructor of ".__PACKAGE__
        if @args > 2;

    die "Last argument must be a CODE ref or HASH ref"
        unless (ref $args[-1] eq 'CODE') or (ref $args[-1] eq 'HASH');

    my %hash;
    if (ref $args[-1] eq 'CODE') {
        $hash{handler} = pop @args;
    }
    else {
        %hash = %{pop @args};
    }

    if (@args) {
        die "Labels may not be a reference" if ref $args[0];
        $hash{label} = shift @args;
    }

    return $self->$orig(%hash);
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
