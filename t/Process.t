#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper::Process module
#####################################################################

use v5.22;
use warnings;

use Test::Most;

my $APP = "Piper::Process";

use Piper::Process;

#####################################################################

# Number of successfully created objects
my $SUCCESSFUL_NEW;

# Test new
{
    subtest "$APP - new" => sub {
        throws_ok {
            Piper::Process->new(qw(1 2 3))
        } qr/^Too many arguments/, 'too many arguments';

        throws_ok {
            Piper::Process->new(qw(1 2))
        } qr/^Last argument must be a CODE ref or HASH ref/, 'last arg CODE or HASH';

        throws_ok {
            Piper::Process->new([qw(blah)], {})
        } qr/^Labels may not be a reference/, 'bad label';

        my $EXP = Piper::Process->new({
            label => 'process',
            handler => sub {},
        });

        is(ref $EXP, $APP, 'ok - by hashref');
        $SUCCESSFUL_NEW++;

        is_deeply(
            Piper::Process->new(process => { handler => sub {}, }),
            $EXP,
            'ok - by label => hashref'
        );
        $SUCCESSFUL_NEW++;

        is_deeply(
            Piper::Process->new(process => sub {}),
            $EXP,
            'ok - by label => sub'
        );
        $SUCCESSFUL_NEW++;
    };
}

my $PROC = Piper::Process->new(
    process => {
        batch_size => 3,
        filter => sub { $_[0] =~ /^\d+$/ },
        handler => sub{},
    }
);
$SUCCESSFUL_NEW++;

my $DEFAULT = Piper::Process->new(sub{});

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
    [ 'Piper::Process', $PROC, $DEFAULT ],
    [ 'initialized Piper::Process', $INIT, $DEFAULT_INIT ]
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
            is($TEST->label, 'process', 'ok from constructor');

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
                    Piper::Process->new({ handler => sub{}, batch_size => -14 })
                } qr/^Must be a positive integer/, 'positive integer required';
            }
        };

        # Test filter
        subtest "$NAME - filter" => sub {
            ok($TEST->has_filter, 'predicate');

            ok(!$DEFAULT->has_filter, 'predicate default');

            if ($NAME !~ /^initialized/) {
                throws_ok {
                    Piper::Process->new({ handler => sub{}, filter => 'blah' })
                } qr/did not pass type constraint "CodeRef"/, 'bad filter';
            }
        };
    };
}


#####################################################################

done_testing();
