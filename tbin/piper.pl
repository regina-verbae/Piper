#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: 
#####################################################################

use v5.22;
use warnings;

use Data::Printer;
use Getopt::Long;
use Piper;

my $opts = {};
GetOptions($opts,
    'batch_size=i',
    'debug',
    'verbose',
    'help|h',
    'version',
) or usage();

#####################################################################

my $pipe = Piper->new(
    add_three => sub {
        my ($instance, $batch, @args) = @_;
        return (map { $_ + 3 } @$batch);
    },
    subtract_one => sub {
        my ($instance, $batch, @args) = @_;
        return (map { $_ - 1 } @$batch);
    },
    transform => Piper->new(
        mult_six => sub {
            my ($instance, $batch, @args) = @_;
            return (map { $_ * 6 } @$batch);
        },
        div_two => sub {
            my ($instance, $batch, @args) = @_;
            return (map { int( $_ / 2 ) } @$batch);
        },
    ),
    { %$opts, label => 'main' },
);
#p $pipe;
my $inst = $pipe->init('hello!');

say $inst->is_exhausted ? 'Exhausted!' : 'Not exhausted!';
for my $child (@{$inst->children}) {
    say $child;
    say $child->ready ? "\tready" : "\tnot ready";
    say $child->pending ? "\tpending" : "\tnot pending";
}
say $inst;
say $inst->ready ? "\tready" : "\tnot ready";
say $inst->pending ? "\tpending" : "\tnot pending";
$inst->enqueue(1..5);
#p $inst;
my %dir = map { $_ => {} } keys %{$inst->directory};
for my $child (@{$inst->children}) {
    if ($child->can('directory')) {
        $dir{$child->path->name} = { map { $_ => {} } keys %{$child->directory} };
    }
}
p %dir;

say $inst->is_exhausted ? 'Exhausted!' : 'Not exhausted!';
for my $child (@{$inst->children}) {
    say $child;
    say $child->ready ? "\tready" : "\tnot ready";
    say $child->pending ? "\tpending" : "\tnot pending";
}
say $inst;
say $inst->ready ? "\tready" : "\tnot ready";
say $inst->pending ? "\tpending" : "\tnot pending";
#p $inst;
while ($inst->isnt_exhausted) {
    my $num = $inst->dequeue;
    say $num;
}
#$inst->inject(6..10);
#$inst->injectAt('subtract_one', 1..5);
#$inst->flush;
#my @results = $inst->next(10);
#p @results;

#####################################################################

sub usage {

}
