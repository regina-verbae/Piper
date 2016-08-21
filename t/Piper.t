#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper module
#####################################################################

use v5.22;
use warnings;

use Test::Most;

my $APP = "Piper";

use Piper;
use Piper::Process;

#####################################################################

# Number of successfully created objects
my $SUCCESSFUL_NEW;

# Test new
{
    subtest "$APP - new" => sub {
        my %BADARGS = (
            'only a label' => [qw(garbage)],
            'only scalars' => [garbage => 'not a process'],
            'arrayref' => [ [qw(garbage)] ],
            'missing required' => [ garbage => {} ],
        );

        for my $bad (keys %BADARGS) {
            throws_ok {
                Piper->new(@{$BADARGS{$bad}})
            } qr/^Missing required argument/, "Bad args: $bad";
        }

        my %GOODARGS = (
            'hashref' => [{ handler => sub{}, }],
            'coderef' => [ sub{}, ],
            'Piper::Process' => [ Piper::Process->new(sub{}) ],
            'Piper' => [ Piper->new(sub{}) ],
            'Piper::Instance::Process' => [ Piper::Process->new(sub{})->init ],
            'Piper::Instance' => [ Piper->new(sub{})->init ],
        );
        $SUCCESSFUL_NEW += 2;

        for my $good (keys %GOODARGS) {
            warning_is {
                Piper->new(@{$GOODARGS{$good}})
            } undef, "Good args: $good";
            $SUCCESSFUL_NEW++;

            warning_is {
                Piper->new('label', @{$GOODARGS{$good}})
            } undef, "Good args: label => $good";
            $SUCCESSFUL_NEW++;

            warning_is {
                Piper->new(@{$GOODARGS{$good}}, { verbose => 1 })
            } undef, "Good args: $good, \$opts";
            $SUCCESSFUL_NEW++;

            warning_is {
                Piper->new('label', @{$GOODARGS{$good}}, { verbose => 1 })
            } undef, "Good args: label => $good, \$opts";
            $SUCCESSFUL_NEW++;
        }
    };
}

my $PROC = Piper->new(
    child => sub{},
    friend => sub{},
    {
        batch_size => 3,
        filter => sub{},
        label => 'main',
    },
);
$SUCCESSFUL_NEW++;

my $DEFAULT = Piper->new(sub{});

my $INIT;
my $DEFAULT_INIT;
# Test init
{
    subtest "$APP - init" => sub {
        $INIT = $PROC->init();
        ok(ref $INIT, 'ok - normal');
        $DEFAULT_INIT = $DEFAULT->init();
        ok(ref $DEFAULT_INIT, 'ok - default');
    };
}

for my $test (
    [ 'Piper', $PROC, $DEFAULT ],
    [ 'initialized Piper', $INIT, $DEFAULT_INIT ]
) {
    my $NAME = $test->[0];
    my $TEST = $test->[1];
    my $DEFAULT = $test->[2];

    subtest $APP => sub {
        # Test id
        subtest "$NAME - id" => sub {
            is($TEST->id, "$APP$SUCCESSFUL_NEW", 'ok');
        };

        # Test label
        subtest "$NAME - label" => sub {
            is($TEST->label, 'main', 'ok from constructor');

            is($DEFAULT->label, $DEFAULT->id, 'ok default (id)');
        };

        # Test stringification
        subtest "$NAME - stringification" => sub {
            is("$TEST", $TEST->label, 'overloaded stringify');
            is("$DEFAULT", $DEFAULT->id, 'overloaded with default');
        };

        # Test enabled
        subtest "$NAME - enabled" => sub {
            is($TEST->enabled, 1, 'default');

            $TEST->enabled(0);
            is($TEST->enabled, 0, 'writable');

            throws_ok {
                $TEST->enabled(-1)
            } qr/did not pass type constraint "Bool"/, 'must be type Bool';

            $TEST->enabled(1);
        };

        # Test batch_size
        subtest "$NAME - batch_size" => sub {
            is($TEST->batch_size, 3, 'ok from constructor');
            
            ok($TEST->has_batch_size, 'predicate');

            ok(!$DEFAULT->has_batch_size, 'predicate default');

            if ($NAME !~ /^initialized/) {
                throws_ok {
                    Piper->new(sub{}, { batch_size => -14 })
                } qr/^Must be a positive integer/, 'positive integer required';
            }
        };

        # Test filter
        subtest "$NAME - filter" => sub {
            ok($TEST->has_filter, 'predicate');

            ok(!$DEFAULT->has_filter, 'predicate default');

            if ($NAME !~ /^initialized/) {
                throws_ok {
                    Piper->new(sub{}, { filter => 'blah' })
                } qr/did not pass type constraint "CodeRef"/, 'bad filter';
            }
        };

        # Test children
        subtest "$APP - children" => sub {
            ok(@{$TEST->children}, 'has children');
        };
    };
}

#####################################################################

done_testing();
