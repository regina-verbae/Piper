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

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new(@segments)

Create a container pipeline segment (parent) from the provided child @segments.

Additionally, a single hashref of options for the container/parent segment may
be included as an argument to the constructor (anywhere in the argument list).
See the OPTIONS section for a description of options available for both parent
and child segments.

Accepted segment types are as follows:

=head3 Piper object

Which creates a sub-container of pipeline segments.  There is no limit to the
number of nested containers a pipeline may contain.

=head3 Piper::Process object

See the PROCESS HANDLER section for a description of Piper::Process objects.

=head3 A coderef (which will be coerced into a Piper::Process object).

=head3 A hashref that can be coerced into a Piper::Process object.

In order to be considered a candidate for coercion, the hashref must contain
(at a minimum) the 'handler' key.

=head3 Piper::Instance object

In this case, the associated Piper or Piper::Process object is extracted from
the Piper::Instance object for use in the new pipeline segment.

See INITIALIZATION for description of Piper::Instance objects.

=head3 A ($label => $segment) pair

For such pairs, the $segment can be any of the above segment types, and $label
is a simple scalar which will be used as $segment's label.

=head2 Constructor Example

    my $pipe = Piper->new(
        \%main_opts,
        subpipe_label => Piper->new(
            first_handler => Piper::Process->new(sub { ... }),
            second_handler => sub { ... },
            third_handler => {
                handler => sub { ... },
            },
            another_subpipe => Piper->new(...),
            \%subpipe_opts,
        ),
        Piper::Process->new({
            label => 'another_handler',
            handler => sub { ... },
        }),
        sub {
            # An un-labeled handler
            ...
        },
        {
            label => 'final_handler',
            handler => sub { ... },
        },
    );

=head1 INITIALIZATION

Piper segments were designed to be easily reusable.  Prior to initialization,
Piper and Piper::Process objects do not process data; they simply contain the
blueprint for creating the pipeline.  As such, blueprints for commonly-used
pipeline segments can be stored in package libraries and imported wherever
needed.

To create a functioning pipeline from one such blueprint, simply call the
'init' method on the outermost segment.  The init method returns a
Piper::Instance object, which is the realization of the pipeline design.

Initialization fuses the pipeline segments together, establishes the
relationships between the segments, and initializes the dataflow
infrastructure.

The init method may be chained from the constructor if the blueprint object is
not needed:

    my $instance = Piper->new(...)->init;

Any arguments passed to the init method will be cached and made available to
each handler in the pipeline (see the PROCESS HANDLER section for full
description of handlers).  This is a great way to share a resource (such as a
database handle) among process handlers.

    my $pipe = Piper->new(
        query => sub {
            my ($instance, $batch, $dbh) = @_;
            $instance->emit(
                $dbh->do_query(@$batch)
            );
        },
        ...
    );
    my $instance = $pipe->init($dbh);

Instances are ready to accept data for processing:

    $instance->enqueue(@data);
    while ($instance->isnt_exhausted) {
        my $result = $instance->dequeue;
    }


=head1 OPTIONS

All of these options are available for both container (Piper) and processor
(Piper::Process) segment types.

Each of the following options is equipped with an accessor of the same name.

A star (*) indicates that the option is writable, and can be modified at
runtime by passing a value as an argument to the method of the same name.

All options (except 'label') have an associated predicate method called
"has_$option" which returns a boolean indicating whether the option has
been set for the segment.

All writable options (indicated by *) can be cleared by passing an explicit
'undef' to the writer method or by calling the appropriate clearer method
called "clear_$option".

All accessors, writers, predicates, and clearers are still available for each
segment after INITIALIZATION.

=head2 allow

A coderef which can be used to subset the items which are "allowed" to be
processed by the segment.

The coderef executes on each item attempting to queue to the segment.  If it
returns true, the item is queued.  Otherwise, the item skips the segment and
proceeds to the next adjacent segment.

Each item is localized to $_, and is also passed in as the first argument.

These example 'allow' subroutines are equivalent:

    # This segment only accept digit inputs
    allow => sub { /^\d+$/ }
    allow => sub { $_ =~ /^\d+$/ }
    allow => sub { $_[0] =~ /^\d+$/ }

=head2 batch_size*

The number of items to process at a time for the segment.

Once initialized (see INITIALIZATION), a segment inherits the batch_size
of any existing parent(s) if not provided.  If the segment has no parents, or
if none of the parents have a batch_size defined, the default batch_size will
be used.  The default batch_size is 200, but can be configured in the import
statement (see the GLOBAL CONFIGURATION section).

=head2 debug*

The debug level for the segment.

Once initialized (see INITIALIZATION), a segment inherits the debug level of
any existing parent(s) if not specified.  The default level is 0, but can be
globally overridden by the environment variable 'PIPER_DEBUG'.

See the LOGGING AND DEBUGGING section for specifics about debug and verbosity
levels.

=head2 enabled*

A boolean indicating that the segment is enabled and can accept items for
processing.

Once initialized (see INITIALIZATION), a segment inherits this option from any
existing parent(s).  The default is true.

If a segment is disabled, all items attempting to queue to the segment are
forwarded to the next adjacent segment.

=head2 label

A label for the segment.  If no label is provided, a globally unique (to the
process) ID will be used.

Labels are necessary for certain types of FLOW CONTROL (for example, injectAt
or injectAfter).  For pipelines that do not utilize FLOW CONTROL features,
labels are primarily useful for logging and/or debugging (see the LOGGING AND
DEBUGGING section).

=head2 verbose*

The verbosity level for the segment.

Once initialized (see INITIALIZATION), a segment inherits the verbosity level
of any existing parent(s) if not specified.  The default level is 0, but can be
globally overridden by the environment variable 'PIPER_VERBOSE'.

See the LOGGING AND DEBUGGING section for specifics about debug and verbosity
levels.

=head1 GLOBAL CONFIGURATION

The following global (per process) options are configurable from the Piper
import statement.

    Ex:
    # Change the default batch_size to 50
    use Piper batch_size => 50;

=head2 batch_size

The default batch size used by pipeline segments which do not have a locally
defined batch_size and do not have a parent segment with a defined batch_size.

The batch_size attribute must be a positive integer.

The default batch_size is 200.

=head2 logger_class

The logger_class is used for printing debug and info statements, issuing
warnings, and throwing errors (see the DEBUGGING section).

The logger_class attribute must be a valid class that does the role defined
by Piper::Role::Logger.

The default logger_class is Piper::Logger.

=head2 queue_class

The queue_class handles the queueing of data for each of the pipeline segments.

The queue_class attribute must be a valid class that does the role defined by
Piper::Role::Queue.

The default queue_class is Piper::Queue.

=head1 LOGGING AND DEBUGGING

=cut

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
