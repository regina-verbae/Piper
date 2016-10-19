#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Configuration object for Piper
#####################################################################

package Piper::Config;

use v5.10;
use strict;
use warnings;

use Carp;
use Types::Common::Numeric qw(PositiveInt);
use Types::LoadableClass qw(ClassDoes);
use Types::Standard qw(ClassName);

use Moo;
use namespace::clean;

=head1 SYNOPSIS

  # Defaults
  use Piper (
      batch_size   => 200,
      logger_class => 'Piper::Logger',
      queue_class  => 'Piper::Queue',
  );

=head1 DESCRIPTION

A configuration object is instantiated during import
of the Piper module according to any supplied import
arguments.

=head1 ATTRIBUTES

=head2 batch_size

The default batch size used by pipeline segments
which do not have a locally defined batch_size and
do not have a parent segment with a defined
batch_size.

The batch_size attribute must be a positive integer.

The default batch_size is 200.

=cut

has batch_size => (
    is => 'lazy',
    isa => PositiveInt,
    default => 200,
);

=head2 logger_class

The logger_class is used for printing debug and
info statements, issuing warnings, and throwing
errors.

The logger_class attribute must be a valid class
that does the role defined by Piper::Role::Logger.

The default logger_class is Piper::Logger.

=cut

has logger_class => (
    is => 'lazy',
    isa => ClassDoes['Piper::Role::Logger'],
    default => 'Piper::Logger',
);

=head2 queue_class

The queue_class handles the queueing of data
for each of the pipeline segments.

The queue_class attribute must be a valid class
that does the role defined by Piper::Role::Queue.

The default queue_class is Piper::Queue.

=cut

has queue_class => (
    is => 'lazy',
    isa => ClassDoes['Piper::Role::Queue'],
    default => 'Piper::Queue',
);

1;
