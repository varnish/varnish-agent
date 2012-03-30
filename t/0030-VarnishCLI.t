#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use lib qw(./lib ../lib);

use Test::More;
use Data::Dumper;

plan tests => 19;



# Use VarnishClientConnection as consuming class for VarnishCLI role
use_ok('Varnish::VACAgent::VarnishClientConnection');



package TestVCC;

use Moose;

with 'Varnish::VACAgent::Role::TextManipulation';
with 'Varnish::VACAgent::Role::VarnishCLI';

sub debug {
    print(join('', @_) . "\n");
}



package main;



my $octets = "";
my $vcc = TestVCC->new();
my $response;



# Test 1
$octets = "200 0       \n\n";
eval {
    $response = $vcc->decode_data_from_varnish($octets);
};
is($@, '', "Response object 1 generated ok");
isa_ok($response, 'Varnish::VACAgent::DataToClient',
       "Correct response class 1");
is($response->length(), 0,   "Response length  correct 1");
is($response->status(), 200, "Response status  correct 1");
is($response->message(), "", "Response message correct 1");
is(bytes::length($response->message()), 0, "Length really is correct 1");



# Test 2
$octets = "107 59      \n" .
    "sirpararbezedpbixyzeytqofsirewqw\n\nAuthentication required.\n\n";
eval {
    $response = $vcc->decode_data_from_varnish($octets);
};
is($@, '', "Response object 2 generated ok");
isa_ok($response, 'Varnish::VACAgent::DataToClient',
       "Correct response class 2");
is($response->length(), 59,  "Response length  correct 2");
is($response->status(), 107, "Response status  correct 2");
is($response->message(),
   "sirpararbezedpbixyzeytqofsirewqw\n\n" .
   "Authentication required.\n", "Response message correct 2");
is(bytes::length($response->message()), 59, "Length really is correct 2");



# Test 3
$octets = "200 245     \n" .
"-----------------------------\n" .
"Varnish Cache CLI 1.0\n" .
"-----------------------------\n" .
"Linux,2.6.38-13-generic,x86_64,-smalloc,-smalloc,-hcritbit\n\n" .
"Type 'help' for command list.\n" .
"Type 'quit' to close CLI session.\n" .
"Type 'start' to launch worker process.\n\n";
eval {
    $response = $vcc->decode_data_from_varnish($octets);
};
is($@, '', "Response object 3 generated ok");
isa_ok($response, 'Varnish::VACAgent::DataToClient',
       "Correct response class 3");
is($response->length(), 245, "Response length  correct 3");
is($response->status(), 200, "Response status  correct 3");
is($response->message(),
   "-----------------------------\n" .
   "Varnish Cache CLI 1.0\n" .
   "-----------------------------\n" .
   "Linux,2.6.38-13-generic,x86_64,-smalloc,-smalloc,-hcritbit\n\n" .
   "Type 'help' for command list.\n" .
   "Type 'quit' to close CLI session.\n" .
   "Type 'start' to launch worker process.\n",
   "Response message correct 3");
is(bytes::length($response->message()), 245, "Length really is correct 3");
