#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper::Logger module
#####################################################################

use v5.22;
use warnings;

use Capture::Tiny qw(capture_stderr);
use Test::Most;

my $APP = "Piper::Logger";

use Piper::Logger;

my $SEGMENT = Test::Segment->new();

#####################################################################

# Test debug/verbose
{
    for my $type (qw(debug verbose)) {
        subtest "$APP - $type" => sub {
            my $log = Piper::Logger->new();
            is($log->$type(), 0, 'default');

            $log->$type(1);
            is($log->$type(), 1, 'writable');

            dies_ok { $log->$type(-1) } 'dies on invalid flag';

            local %ENV;
            $ENV{uc("PIPER_$type")} = 2;
            $log = Piper::Logger->new();
            is($log->$type(), 2, "environment as default");
            
            $log->$type(0);
            is($log->$type(), 2, "environment override");
        };
    }
}

my %TEST = (
    default => Piper::Logger->new(),
    'verbose = 1' => Piper::Logger->new(verbose => 1),
    'verbose = 2' => Piper::Logger->new(verbose => 2),
    'debug = 1' => Piper::Logger->new(debug => 1),
    'debug = 2' => Piper::Logger->new(debug => 2),
    'verbose = 1; debug = 1' => Piper::Logger->new(verbose => 1, debug => 1),
    'verbose = 2; debug = 1' => Piper::Logger->new(verbose => 2, debug => 1),
    'verbose = 2; debug = 2' => Piper::Logger->new(verbose => 2, debug => 2),
);
my @ARGS = ($SEGMENT, 'message', qw(item1 item2));

# Test make_message
{
    subtest "$APP - make_message" => sub {
        my %EXP = (
            default => 'label: message',
            'verbose = 1' => 'path: message',
            'verbose = 2' => 'path: message <item1,item2>',
            'debug = 1' => 'label: message',
            'debug = 2' => 'label (id): message',
            'verbose = 1; debug = 1' => 'path: message',
            'verbose = 2; debug = 1' => 'path: message <item1,item2>',
            'verbose = 2; debug = 2' => 'path (id): message <item1,item2>',
        );

        for my $test (keys %TEST) {
            is(
                $TEST{$test}->make_message(@ARGS),
                $EXP{$test},
                $test
            );
        }
    };
}

# Test INFO
{
    subtest "$APP - INFO" => sub {
        my %EXP = map { $_ => $_ eq 'default' ? 0 : 1 } keys %TEST;

        for my $test (keys %TEST) {
            my $capture = capture_stderr {
                $TEST{$test}->INFO(@ARGS)
            };
            chomp $capture;
            is($capture,
                $EXP{$test} ? 'Info: '.$TEST{$test}->make_message(@ARGS) : '',
                $test
            );
        }
    };
}

# Test DEBUG
{
    subtest "$APP - DEBUG" => sub {
        my %EXP = map { $_ => $_ =~ /debug/ ? 1 : 0 } keys %TEST;

        for my $test (keys %TEST) {
            my $capture = capture_stderr {
                $TEST{$test}->DEBUG(@ARGS)
            };
            chomp $capture;
            is($capture,
                $EXP{$test} ? 'Info: '.$TEST{$test}->make_message(@ARGS) : '',
                $test
            );
        }
    };
}

# Test WARN
{
    subtest "$APP - WARN" => sub {
        for my $test (keys %TEST) {
            warning_is {
                $TEST{$test}->WARN(@ARGS)
            } { carped => 'Warning: '.$TEST{$test}->make_message(@ARGS) }, $test;
        }
    };
}

# Test ERROR
{
    subtest "$APP - ERROR" => sub {
        for my $test (keys %TEST) {
            dies_ok {
                $TEST{$test}->ERROR(@ARGS)
            } "$test died";

            my $message = 'Error: '.$TEST{$test}->make_message(@ARGS);
            like($@, qr/^\Q$message\E/, "$test message");
        }
    };
}

#####################################################################

done_testing();

BEGIN {
    package Test::Segment;

    use Moo;

    has path => (
        is => 'ro',
        default => 'path',
    );

    has label => (
        is => 'ro',
        default => 'label',
    );

    has id => (
        is => 'ro',
        default => 'id',
    );
}
