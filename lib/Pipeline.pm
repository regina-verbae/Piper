#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

package Pipeline;

use v5.22;
use warnings;

use List::AllUtils qw(all);
use Moo;
use Pipeline::Instance;
use Pipeline::Process;
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Str);
use Types::Common::Numeric qw(PositiveInt);
use Types::Common::String qw(NonEmptySimpleStr);

has processes => (
    is => 'ro',
    isa => ArrayRef[InstanceOf['Pipeline::Process']],
    required => 1,
);

has next_process => (
    is => 'lazy',
    isa => HashRef[Str],
);

sub _build_next_process {
    my ($self) = @_;
    my %return;
    my @names = map { $_->path } @{$self->processes};
    while (my $name = shift @names) {
        $return{$name} = $names[0] if @names;
    }
    return \%return;
}

has batch_size => (
    is => 'rw',
    isa => PositiveInt,
    default => 50,
);

has debug => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

has verbose => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

has label => (
    is => 'rwp',
    isa => NonEmptySimpleStr,
    lazy => 1,
    builder => 1,
);

sub _build_label {
    my ($self) = @_;
    return $self->pipeID;
}

has pipeID => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    builder => 1,
);

sub _build_pipeID {
    state $PIPENUMBER = 0;
    $PIPENUMBER++;
    return "Pipe$PIPENUMBER";
}

sub init {
    my ($self, @args) = @_;
    
    state $INSTANCEID = {};
    $INSTANCEID->{$self->pipeID}++;

    return Pipeline::Instance->new({
        pipe => $self,
        init_args => \@args,
        instanceID => join('-', $self->pipeID, $INSTANCEID->{$self->pipeID}),
    });
}

around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;

    my $opts;
    if (ref $args[-1] eq 'HASH'
            and ref $args[-2] # Should not be a label before options
            and !exists $args[-1]->{handler}
    ) {
        $opts = pop @args;
    }
    else {
        $opts = {};
    }

    my @real;
    my $LABELNUM = 0;
    while (my $thing = shift @args) {
        $LABELNUM++;
        my $label;
        if (!ref $thing) {
            # Label
            $label = $thing;
            $thing = shift @args;
        }
        
        if (eval { $thing->isa('Pipeline') }) {
            # Overwrite label if given
            $thing->_set_label($label) if $label;
            # TODO: Remove flattening?
            push @real, _flatten($thing, \$LABELNUM);
        }
        elsif (eval { $thing->isa('Pipeline::Process') }) {
            # Overwrite label if given
            $thing->_set_label($label) if $label;
            $thing->path(join('/', 'main', $thing->label));
            push @real, $thing;
        }
        elsif (ref $thing eq 'HASH') {
            my %hash = %$thing;
            $hash{label} //= $label // "Process$LABELNUM";
            $hash{path} = join('/', 'main', $hash{label});
            push @real, Pipeline::Process->new(%hash);
        }
        elsif (ref $thing eq 'CODE') {
            my %hash = ( handler => $thing );
            $hash{label} //= $label // "Process$LABELNUM";
            $hash{path} = join('/', 'main', $hash{label});
            push @real, Pipeline::Process->new(%hash);
        }
        else {
            push @real, Pipeline::Process->new($thing);
        }
    }
    return $self->$orig(processes => \@real, %$opts);
};

sub _flatten {
    my ($pipe, $labelNumRef) = @_;

    my @return;
    for my $proc (@{$pipe->processes}) {
        $$labelNumRef++;
        $proc->path(join('/', 'main', $pipe->label, $proc->label));
        push @return, $proc
    }
    return @return;
}

1;
