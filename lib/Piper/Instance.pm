#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Piper::Instance;

use v5.10;
use strict;
use warnings;

use List::AllUtils qw(last_value max part sum);
use List::UtilsBy qw(max_by min_by);
use Piper::Path;
use Scalar::Util qw(weaken);
use Types::Standard qw(ArrayRef ConsumerOf Enum HashRef InstanceOf Tuple slurpy);

use Moo;
use namespace::clean;

with qw(Piper::Role::Queue);

use overload (
    q{""} => sub { $_[0]->path },
    fallback => 1,
);

=head1 ATTRIBUTES

=head2 args

=cut

has args => (
    is => 'rwp',
    isa => ArrayRef,
    lazy => 1,
    builder => sub {
        my ($self) = @_;
        if ($self->has_parent) {
            return $self->main->args;
        }
        else {
            return [];
        }
    },
);

=head2 batch_size

=cut

# Decorated below

=head2 children

=cut

has children => (
    is => 'ro',
    # Must contain at least one child
    isa => Tuple[InstanceOf['Piper::Instance'],
        slurpy ArrayRef[InstanceOf['Piper::Instance']]
    ],
    required => 0,
    predicate => 1,
);

=head2 debug

Debug level for this segment.  When accessing, inherits the debug level of any
existing parent(s) if not explicitly set for this segment.

To clear a previously-set debug level for a segment, simply set it to <undef>:

    $segment->debug(undef);

=cut

# Decorated below

=head2 directory

=cut

has directory => (
    is => 'lazy',
    isa => HashRef,
    builder => sub {
        my ($self) = @_;
        return {} unless $self->has_children;
        my %dir;
        for my $child (@{$self->children}) {
            $dir{$child->path->name} = $child;
        }
        return \%dir;
    },
);

=head2 drain

=cut

BEGIN { # Enables 'with Piper::Role::Queue'
has drain => (
    is => 'lazy',
    handles => [qw(dequeue ready)],
    builder => sub {
        my ($self) = @_;
        if ($self->has_parent) {
            return $self->parent->follower->{$self};
        }
        else {
            return $self->main->config->queue_class->new();
        }
    },
);
}

=head2 enabled

=cut

# Decorated below

=head2 follower

=cut

#TODO: make this a method called by children
has follower => (
    is => 'lazy',
    isa => HashRef,
    builder => sub {
        my ($self) = @_;
        return {} unless $self->has_children;
        my %follow;
        for my $index (0..$#{$self->children}) {
            if (defined $self->children->[$index + 1]) {
                $follow{$self->children->[$index]} =
                    $self->children->[$index + 1];
            }
            else {
                $follow{$self->children->[$index]} = $self->drain;
            }
        }
        return \%follow;
    },
);

=head2 logger

=cut

has logger => (
    is => 'lazy',
    isa => ConsumerOf['Piper::Role::Logger'],
    handles => 'Piper::Role::Logger',
    builder => sub {
        my ($self) = @_;
        
        if ($self->has_parent) {
            return $self->main->logger;
        }
        else {
            return $self->main->config->logger_class->new();
        }
    },
);

# Cute little trick to auto-insert the instance object
# as first argument, since $self will become the logger
# object and lose access to paths/labels/etc.
around [qw(INFO DEBUG WARN ERROR)] => sub {
    my ($orig, $self) = splice @_, 0, 2;
    if (ref $_[0]) {
        $self->$orig(@_);
    }
    else {
        $self->$orig($self, @_);
    }
};

=head2 main

=cut

has main => (
    is => 'lazy',
    isa => InstanceOf['Piper::Instance'],
    weak_ref => 1,
    builder => sub {
        my ($self) = @_;
        my $parent = $self;
        while ($parent->has_parent) {
            $parent = $parent->parent;
        }
        return $parent;
    },
);

=head2 parent

=cut

has parent => (
    is => 'rwp',
    isa => InstanceOf['Piper::Instance'],
    # Setting a parent will introduce a self-reference
    weak_ref => 1,
    required => 0,
    predicate => 1,
);

=head2 path

=cut

has path => (
    is => 'lazy',
    isa => InstanceOf['Piper::Path'],
    builder => sub {
        my ($self) = @_;

        return $self->has_parent
            ? $self->parent->path->child($self->label)
            : Piper::Path->new($self->label);
    },
);

=head2 queue

=cut

BEGIN { # Enables 'with Piper::Role::Queue'
has queue => (
    is => 'lazy',
    isa => ConsumerOf['Piper::Role::Queue'],
    handles => [qw(enqueue)],
    builder => sub {
        my ($self) = @_;
        if ($self->has_children) {
            return $self->children->[0];
        }
        else {
            return $self->main->config->queue_class->new();
        }
    },
);
}

around enqueue => sub {
    my ($orig, $self, @args) = @_;

    if (!$self->enabled) {
        # Bypass - go straight to drain
        $self->INFO("Skipping disabled process", @args);
        $self->drain->enqueue(@args);
        return;
    }

    my @items;
    if ($self->has_allow) {
        my ($skip, $queue) = part {
            $self->allow->($_) ? 1 : 0
        } @args;

        @items = @$queue if defined $queue;

        if (defined $skip) {
            $self->INFO("Disallowed items emitted to next handler", @$skip);
            $self->drain->enqueue(@$skip);
        }
    }
    else {
        @items = @args;
    }

    return unless @items;

    $self->INFO("Queueing items", @items);
    $self->$orig(@items);
};

=head2 segment

=cut

BEGIN { # So we can 'around' on Piper::Role::Segment methods
has segment => (
    is => 'ro',
    isa => ConsumerOf['Piper::Role::Segment'],
    handles => 'Piper::Role::Segment',
    required => 1,
);
}

=head2 verbose

Verbosity level for this segment.  When accessing, inherits verbosity level of
any existing parent(s) if not explicitly set for this segment.

To clear a previously-set verbosity level for a segment, simply set it to
<undef>:

    $segment->verbose(undef);

=cut

# Decorated below

# Inherit parent settings
for my $attr (qw(batch_size debug enabled verbose)) {
    my $clear = "clear_$attr";
    my $has = "has_$attr";

    around $attr => sub {
        my ($orig, $self) = splice @_, 0, 2;

        state $default = {
            batch_size => $self->main->config->batch_size,
            debug => 0,
            enabled => 1,
            verbose => 0,
        };

        if (@_) {
            return $self->$clear() if !defined $_[0];
            return $self->$orig(@_);
        }
        else {
            return $self->$has()
                ? $self->$orig()
                : $self->has_parent
                    ? $self->parent->$attr()
                    : $default->{$attr};
        }
    };
}

=head1 METHODS

=head2 eject(@items)

=cut

sub eject {
    my $self = shift;
    $self->INFO("Ejecting to drain", @_);
    $self->main->drain->enqueue(@_);
}

=head2 emit(@items)

=cut

sub emit {
    my $self = shift;
    $self->INFO("Emitting", @_);
    # Just collect in the drain
    $self->drain->enqueue(@_);
}

=head2 find_segment($location)

=cut

sub find_segment {
    my ($self, $location) = @_;
    
    state $global_cache = {};
    $global_cache->{$self->main->id}{$self->path} //= {};
    my $cache = $global_cache->{$self->main->id}{$self->path};

    unless (exists $cache->{$location}) {
        $location = Piper::Path->new($location);
        if ($self->has_children or $self->has_parent) {
            my $parent = $self->has_children ? $self : $self->parent;
            my $segment = $parent->descendant($location);
            while (!defined $segment and $parent->has_parent) {
                my $referrer = $parent;
                $parent = $parent->parent;
                $segment = $parent->descendant($location, $referrer);
            }
            $cache->{$location} = $segment;
        }
        else {
            # Lonely Process (no parents or children)
            $cache->{$location} = "$self" eq "$location" ? $self : undef;
        }
        weaken($cache->{$location}) if defined $cache->{$location};
    }

    $self->DEBUG("Found label $location: '$cache->{$location}'") if defined $cache->{$location};
    return $cache->{$location};
}

=head2 inject(@items)

=cut

sub inject {
    my $self = shift;
    $self->INFO('Injecting to '.$self->main, @_);
    $self->main->enqueue(@_);
}

=head2 injectAfter($location, @items)

=cut

sub injectAfter {
    my $self = shift;
    my $location = shift;
    my $segment = $self->find_segment($location);
    $self->ERROR("Could not find $location to injectAfter", @_)
        if !defined $segment;
    $self->INFO("Injecting to $location", @_);
    $segment->drain->enqueue(@_);
}

=head2 injectAt($location, @items)

=cut

sub injectAt {
    my $self = shift;
    my $location = shift;
    my $segment = $self->find_segment($location);
    $self->ERROR("Could not find $location to injectAt", @_)
        if !defined $segment;
    $self->INFO("Injecting to $location", @_);
    $segment->enqueue(@_);
}

=head2 is_exhausted

=cut

sub is_exhausted {
    my ($self) = @_;
    
    # Attempt to get some data ready
    while (!$self->ready and $self->pending) {
        $self->process_batch;
    }

    return $self->ready ? 0 : 1;
}

=head2 isnt_exhausted

=cut

sub isnt_exhausted {
    my ($self) = @_;
    return !$self->is_exhausted;
}

=head2 pending

=cut

sub pending {
    my ($self) = @_;
    if ($self->has_children) {
        return sum(map { $_->pending } @{$self->children});
    }
    else {
        return $self->queue->ready;
    }
}

=head2 recycle(@items)

=cut

sub recycle {
    my $self = shift;
    $self->INFO("Recycling", @_);
    $self->enqueue(@_);
}

=head1 PRIVATE METHODS

=head2 descendant($path, $referrer)

=cut

sub descendant {
    my ($self, $path, $referrer) = @_;
    return unless $self->has_children;
    $referrer //= '';

    $self->DEBUG("Searching for location '$path'");
    $self->DEBUG("Referrer", $referrer) if $referrer;

    # Search immediate children
    $path = Piper::Path->new($path) if $path and not ref $path;
    my @pieces = $path ? $path->split : ();
    my $descend = $self;
    while (defined $descend and @pieces) {
        if (!$descend->has_children) {
            $descend = undef;
        }
        elsif (exists $descend->directory->{$pieces[0]}) {
            $descend = $descend->directory->{$pieces[0]};
            shift @pieces;
        }
        else {
            $descend = undef;
        }
    }

    # Search grandchildren,
    #   but not when checking whether requested location starts at $self (referrer = $self)
    if (!defined $descend and $referrer ne $self) {
        my @possible;
        for my $child (@{$self->children}) {
            if ($child eq $referrer) {
                $self->DEBUG("Skipping search of '$child' referrer");
                next;
            }
            if ($child->has_children) {
                my $potential = $child->descendant($path);
                push @possible, $potential if defined $potential;
            }
        }

        if (@possible) {
            $descend = min_by { $_->path->split } @possible;
        }
    }

    # If location begins with $self->label, see if requested location starts at $self
    #   but not if already checking that (referrer = $self)
    if (!defined $descend and $referrer ne $self) {
        my $overlap = $self->label;
        if ($path =~ m{^\Q$overlap\E(?:$|/(?<path>.*))}) {
            $path = $+{path} // '';
            $self->DEBUG("Overlapping descendant search", $path ? $path : ());
            $descend = $path ? $self->descendant($path, $self) : $self;
        }
    }

    return $descend;
}

=head2 pressure

=cut

# Metric for "how full" the pending queue is
sub pressure {
    my ($self) = @_;
    if ($self->has_children) {
        return max(map { $_->pressure } @{$self->children});
    }
    else {
        return $self->pending ? int(100 * $self->pending / $self->batch_size) : 0;
    }
}

=head2 process_batch

=cut

sub process_batch {
    my ($self) = @_;
    if ($self->has_children) {
        my $best;
        # Full-batch process closest to drain
        if ($best = last_value { $_->pressure >= 100 } @{$self->children}) {
            $self->DEBUG("Chose batch $best: full-batch process closest to drain");
        }
        # If no full batch, choose the one closest to full
        else {
            $best = max_by { $_->pressure } @{$self->children};
            $self->DEBUG("Chose batch $best: closest to full-batch");
        }
        $best->process_batch;
    }
    else {
        my $num = $self->batch_size;
        $self->DEBUG("Processing batch with max size", $num);

        my @batch = $self->queue->dequeue($num);
        $self->INFO("Processing batch", @batch);

        $self->segment->handler->(
            $self,
            \@batch,
            @{$self->args}
        );
    }
}

1;
