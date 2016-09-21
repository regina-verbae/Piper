#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Process;

use v5.10;
use strict;
use warnings;

use Piper::Instance;
use Types::Standard qw(CodeRef);

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

    $hash{config} = $CONFIG if defined $CONFIG;

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

=head1 ATTRIBUTES

=head2 handler

The data-processing subroutine for this segment.

The arguments provided to the handler are as follows:

    $instance - the instance corresponding to the segment
    $batch    - an arrayref of items to process
    @args     - the init arguments (if any) provided
                at the initialization of the pipeline

Via the provided $instance object, the handler
has several options for sending data to other
pipes or processes in the pipeline:

    $instance->eject(@data)
    $instance->emit(@data)
    $instance->inject(@data)
    $instance->injectAfter($location, @data)
    $instance->injectAt($location, @data)
    $instance->recycle(@data)

See Piper::Role::Instance for an explantion
of these methods.

=cut

has handler => (
    is => 'ro',
    isa => CodeRef,
    required => 1,
);

=head1 METHODS

=head2 init

Returns a Piper::Instance object for this
segment.

=cut

sub init {
    my ($self) = @_;

    return Piper::Instance->new(
        segment => $self,
    );
}

1;
