#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use lib qw(./lib ../lib);

use Test::More;
use Data::Dumper;

plan tests => 5;

use_ok('Varnish::VACAgent::JobManager');

my $job_manager = Varnish::VACAgent::JobManager->new();
isa_ok($job_manager, 'Varnish::VACAgent::JobManager');

my $id;
$id = $job_manager->start_job("systemstats 1");
is($id, '1', "correct job id returned from start_job()");
is($job_manager->list_jobs(), "systemstats 1\n", "list_jobs()");

$id = $job_manager->start_job("systemstats 2");
is($id, '2', "correct job id returned from start_job()");
is($job_manager->list_jobs(), "systemstats 1\nsystemstats 2\n", "list_jobs()");
