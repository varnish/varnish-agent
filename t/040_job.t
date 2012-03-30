#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use lib qw(./lib ../lib);

use Test::More;
use Data::Dumper;

use Varnish::VACAgent::JobManager;

plan tests => 5;

use_ok('Varnish::VACAgent::Job');

my $manager = Varnish::VACAgent::JobManager->new();
my $job = Varnish::VACAgent::Job->new(id => 1,
                                      command => 'foo',
                                      parameters => ['bar', 'baz'],
                                      manager => $manager);
isa_ok($job, 'Varnish::VACAgent::Job');

is($job->command(), "foo", "command()");
my @all_params = $job->all_parameters();
is_deeply(\@all_params, ['bar', 'baz'], "all_parameters()");
is($job->to_string(), "1 foo bar baz", "to_string()");
