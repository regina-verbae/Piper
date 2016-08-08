#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Role::Logger;

use v5.22;
use warnings;

use Carp qw();
use Types::Common::Numeric qw(PositiveOrZeroNum);

use Moo::Role;

has verbose => (
    is => 'rw',
    isa => PositiveOrZeroNum,
    default => 0,
);

has debug => (
    is => 'rw',
    isa => PositiveOrZeroNum,
    default => 0,
);

sub _info {
    my $self = shift;
    warn 'Info: '.$self->_make_message(@_)."\n";
}

sub INFO {
    my $self = shift;
    return unless $self->verbose or $self->debug;
    $self->_info(@_);
}

sub DEBUG {
    my $self = shift;
    return unless $self->debug or $self->verbse > 1;
    $self->_info(@_);
}

sub WARN {
    my $self = shift;
    Carp::carp('Warning: '.$self->_make_message(@_));
}

sub ERROR {
    my $self = shift;
    Carp::croak('Error: '.$self->_make_message(@_));
}

sub _make_message {
    my ($self, $segment, $message, @items) = @_;

    $message = ($self->verbose ? $segment->path : $segment->label)
        . ($self->debug > 1 ? ' (' . $segment->id . '): ' : ': ')
        . $message;

    if (@items) {
        $message .= ' <'.join(',', @items).'>';
    }

    return $message;
}

1;
