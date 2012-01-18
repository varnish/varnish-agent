#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use lib qw(./lib ../lib);

use Test::More;
use Data::Dumper;

plan tests => 31;

my $cmdline_1 = "help\r\n";
my $cmdline_2 = "help some_command\r\n";
my $cmdline_3 = "vcl.load some_name << LIMITER\r\n" .
    "first vcl line\r\n" .
    "second vcl line\r\n" .
    "LIMITER\r\n";
my $cmd;

use_ok('Varnish::VACAgent::VACCommand');



# Test methods

$cmd = Varnish::VACAgent::VACCommand->new(data          => $cmdline_1,
                                          authenticated => 1);
$cmd->data($cmdline_3); # Set up new data for testing
my ($line, $rest) = $cmd->peek_line();
is($cmd->pretty_line($cmd->data()), $cmd->pretty_line($cmdline_3),
   "data correct for peek_line test");
is($cmd->pretty_line($line), '"vcl.load some_name << LIMITER"',
   "peek_line, line");
is($cmd->pretty_line($$rest),
   $cmd->pretty_line("first vcl line\r\nsecond vcl line\r\nLIMITER\r\n"),
   "peek_line, rest");



# Test object construction

# cmdline_1

$cmd = Varnish::VACAgent::VACCommand->new(data          => $cmdline_1,
                                          authenticated => 1);

# say("cmd: ", Dumper($cmd));

isnt($cmd, undef, "non-null command line 1");
isa_ok($cmd, 'Varnish::VACAgent::VACCommand');
is($cmd->data(), "", "data");
is($cmd->authenticated(), 1, "authenticated");
is($cmd->command(), "help", "command");
is($cmd->line(), "help", "line");
is($cmd->heredoc(), undef, "heredoc");
is($cmd->has_heredoc, 0, "has_heredoc");
is_deeply($cmd->args, [], "args");



# cmdline_2

$cmd = Varnish::VACAgent::VACCommand->new(data          => $cmdline_2,
                                          authenticated => 0);

# say("cmd: ", Dumper($cmd));

isnt($cmd, undef, "non-null command line 2");
isa_ok($cmd, 'Varnish::VACAgent::VACCommand');
is($cmd->data(), "", "data");
is($cmd->authenticated(), 0, "authenticated");
is($cmd->command(), "help", "command");
is($cmd->line(), "help some_command", "line");
is($cmd->heredoc(), undef, "heredoc");
is($cmd->has_heredoc, 0, "has_heredoc");
is_deeply($cmd->args, ['some_command'], "args");



# cmdline_3

$cmd = Varnish::VACAgent::VACCommand->new(data          => $cmdline_3,
                                          authenticated => 1);

# say("cmd: ", Dumper($cmd));

isnt($cmd, undef, "non-null command line 3");
isa_ok($cmd, 'Varnish::VACAgent::VACCommand');
is($cmd->data(), "", "data");
is($cmd->authenticated(), 1, "authenticated");
is($cmd->command(), "vcl.load", "command");
is($cmd->line(), "vcl.load some_name << LIMITER", "line");
is($cmd->heredoc(), "first vcl line\nsecond vcl line\n", "heredoc");
is($cmd->has_heredoc, 1, "has_heredoc");
is_deeply($cmd->args,
          ['some_name', "first vcl line\nsecond vcl line\n"],
          "args");

