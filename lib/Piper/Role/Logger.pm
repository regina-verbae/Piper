#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Role for logging/messaging from Piper
#####################################################################

package Piper::Role::Logger;

use v5.10;
use strict;
use warnings;

use Carp;
use Types::Common::Numeric qw(PositiveOrZeroNum);

use Moo::Role;

#TODO: Look into making this Log::Any-compatible

=head1 DESCRIPTION

Role for logging and debugging in the L<Piper> system.

The role exists to support future subclassing and testing of the logging mechanism used by L<Piper>.

=head1 REQUIRES

This role requires the definition of the below methods, each of which will be provided the following arguments:

  $segment  # The pipeline segment calling the method
  $message  # The message sent (a string)
  @items    # Items that provide context to the message

=head2 DEBUG

This method is only called if S<<< C<< $self->debug_level($segment) > 0 >> >>>.

=cut

requires 'DEBUG';

around DEBUG => sub {
    my ($orig, $self, $instance) = splice @_, 0, 3;
    return unless $self->debug_level($instance);
    $self->$orig($instance, @_);
};

=head2 ERROR

This method should cause a C<die> or C<croak>.  It will do so automatically if not done explicitly, though with an extremely generic and unhelpful message.

=cut

requires 'ERROR';

after ERROR => sub {
    croak "ERROR encountered";
};

=head2 INFO

This method is only called if S<<< C<< $self->verbose_level($segment) > 0 >> >>> or S<<< C<< $self->debug_level($segment) > 0 >> >>>.

=cut

requires 'INFO';

around INFO => sub {
    my ($orig, $self, $instance) = splice @_, 0, 3;
    return unless $self->debug_level($instance) or $self->verbose_level($instance);
    $self->$orig($instance, @_);
};

=head2 WARN

This method should issue a warning (such as C<warn> or C<carp>).

=cut

requires 'WARN';

=head1 UTILITY METHODS

=head2 debug_level($segment)

=head2 verbose_level($segment)

These methods should be used to determine the appropriate debug and verbosity levels for the logger.  They honor the following environment variable overrides (if they exist) before falling back to the appropriate levels set by the given C<$segment>:

    PIPER_DEBUG
    PIPER_VERBOSE

=cut

sub debug_level {
    return $ENV{PIPER_DEBUG} // $_[1]->debug;
}

sub verbose_level {
    return $ENV{PIPER_VERBOSE} // $_[1]->verbose;
}

1;

__END__

=head1 SEE ALSO

=over

=item L<Piper::Logger>

=item L<Piper>

=back

=cut
