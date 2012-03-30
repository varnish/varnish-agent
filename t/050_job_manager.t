#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use lib qw(./lib ../lib);

use Test::More;
use Data::Dumper;

use Varnish::VACAgent::DataToClient;

plan tests => 13;

use_ok('Varnish::VACAgent::JobManager');

{
    no warnings 'redefine';
    local *Varnish::VACAgent::Job::SystemStats::run = sub { };
    use warnings;
    
    my $job_manager = Varnish::VACAgent::JobManager->new();
    isa_ok($job_manager, 'Varnish::VACAgent::JobManager');
    
    my $response;
    $response = $job_manager->start_job(['systemstats', '5']);
    is($response->status(), '200', "job id returned from start_job()");
    is($response->message(), "Job-id: 1\n", "message");
    is($job_manager->list_jobs(), "1 systemstats 5\n", "list_jobs()");
    
    $response = $job_manager->start_job(['systemstats', '10']);
    is($response->status(), '200', "job id returned from start_job()");
    is($response->message(), "Job-id: 2\n", "message");
    is($job_manager->list_jobs(), "1 systemstats 5\n2 systemstats 10\n",
       "list_jobs()");

    $response = $job_manager->stop_job([1]);
    is($response->status(), '200', "status returned from stop_job()");
    is($response->message(), "", "message returned from stop_job()");
    is($job_manager->list_jobs(), "2 systemstats 10\n",
       "list_jobs()");
    
    $response = $job_manager->stop_job([1]);
    is($response->status(), '106',
       "status returned from stop_job(), nonexistent job id");
    is($response->message(), "No such job: 1\n",
       "message returned from stop_job(), nonexistent job id");
}

