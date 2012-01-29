#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use lib qw(./lib ../lib);

use Test::More;
use Data::Dumper;

plan tests => 8;



use_ok('Varnish::VACAgent::DataFromVarnish');



my $vr;
my $msg = "Test message";

# Construction failure

eval {
    $vr = Varnish::VACAgent::DataFromVarnish->new(length => 20,
                                                  status => 200,
                                                  message => $msg);
};
like($@, qr(CLI communication error. Expected to read), "Bad length detected");



# Construction OK

eval {
    $vr = Varnish::VACAgent::DataFromVarnish->new(length => 12,
                                                  status => 200,
                                                  message => $msg);
};
is($@, '', "Construction ok");



# to_string

is($vr->to_string(), "200 12      \nTest message\n", "to_string");



# Status
ok($vr->status_is_ok, "Status is OK");
ok(! $vr->status_is_auth, "Status isn't AUTH");

$vr = Varnish::VACAgent::DataFromVarnish->new(length => 12,
                                              status => 107,
                                              message => $msg);
ok($vr->status_is_auth, "Status is AUTH");
ok(! $vr->status_is_ok, "Status isn't OK");
