#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use lib qw(./lib ../lib);

use Test::More;
use Data::Dumper;

plan tests => 5;

use_ok('Varnish::VACAgent::Job');

my $job = Varnish::VACAgent::Job->new(id => 1,
                                      command => 'foo',
                                      parameters => ['bar', 'baz']);
isa_ok($job, 'Varnish::VACAgent::Job');

is($job->command(), "foo", "command()");
my @all_params = $job->all_parameters();
is_deeply(\@all_params, ['bar', 'baz'], "all_parameters()");
is($job->to_string(), "foo bar baz", "to_string()");
