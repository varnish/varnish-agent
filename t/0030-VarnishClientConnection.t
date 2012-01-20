#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use lib qw(./lib ../lib);

use Test::More;
use Data::Dumper;

plan tests => 4;



use_ok('Varnish::VACAgent::VarnishClientConnection');



# Set up bogus test class TestVCC.
# Fake this as $self in methods to avoid mocking a Reflex object.
package TestVCC;
use Moose;
with 'Varnish::VACAgent::Role::TextManipulation';
sub debug {
    print(join('', @_) . "\n");
}



# Set up bogus test class TestEvent.
# Fake this as event in methods to avoid mocking a Reflex object.
package TestEvent;
sub new {
    return bless({}, 'TestEvent');
}
sub octets {
    return "200 0       \n\n";
}



package main;



my $test_event = TestEvent->new();
my $vcc = TestVCC->new();
my $response;


# Test receive_response

my $method = \&Varnish::VACAgent::VarnishClientConnection::receive_response;



# Test 1
eval {
    $response = $method->($vcc, $test_event);
};
is($@, '', "Response object 1 generated ok");




# Test 2
{
    no warnings "redefine";
    local *TestEvent::octets = sub {
        return "107 59      \n" .
            "sirpararbezedpbixyzeytqofsirewqw\n\nAuthentication required.\n\n";
    };
    eval {
        $response = $method->($vcc, $test_event);
    };
    is($@, '', "Response object 2 generated ok");
}



# Test 3
{
    no warnings "redefine";
    local *TestEvent::octets = sub {
        return
"200 245     \n" .
"-----------------------------\n" .
"Varnish Cache CLI 1.0\n" .
"-----------------------------\n" .
"Linux,2.6.38-13-generic,x86_64,-smalloc,-smalloc,-hcritbit\n\n" .
"Type 'help' for command list.\n" .
"Type 'quit' to close CLI session.\n" .
"Type 'start' to launch worker process.\n\n";
    };
    eval {
        $response = $method->($vcc, $test_event);
    };
    is($@, '', "Response object 3 generated ok");
}
