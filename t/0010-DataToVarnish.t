#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use lib qw(./lib ../lib);

use Test::More;
use Data::Dumper;

plan tests => 31;

my $cmd;

use_ok('Varnish::VACAgent::DataToVarnish');



# Test _peek_line, data(). Need to test this before object
# construction, because those will fail if _peek_line fails.

my $cmdline_3 = "vcl.load some_name << DELIMITER\r\n" .
    "first vcl line\r\n" .
    "second vcl line\r\n" .
    "DELIMITER\r\n";
$cmd = Varnish::VACAgent::DataToVarnish->new(data          => "help\r\n",
                                             authenticated => 1);

$cmd->data($cmdline_3); # Set up new data for testing
my ($line, $rest) = $cmd->_peek_line();
is($cmd->make_printable($cmd->data()), $cmd->make_printable($cmdline_3),
   "cmd->data() unchanged after peek_line test");
is($cmd->make_printable($line), '"vcl.load some_name << DELIMITER"',
   "peek_line, line");
is($cmd->make_printable($$rest),
   $cmd->make_printable("first vcl line\r\nsecond vcl line\r\nDELIMITER\r\n"),
   "peek_line, rest");



# Test object construction

# cmdline_1

my $cmdline_1 = "help\r\n";
$cmd = Varnish::VACAgent::DataToVarnish->new(data          => $cmdline_1,
                                             authenticated => 1);

# say("cmd: ", Dumper($cmd));

isnt($cmd, undef, "non-null command line 1");
isa_ok($cmd, 'Varnish::VACAgent::DataToVarnish');
is($cmd->data(), "", "data");
is($cmd->authenticated(), 1, "authenticated");
is($cmd->command(), "help", "command");
is($cmd->line(), "help", "line");
is($cmd->heredoc(), undef, "heredoc");
is_deeply($cmd->args, [], "args");
is($cmd->to_string(), "help\n", "to_string()");



# cmdline_2

my $cmdline_2 = "help some_command\r\n";
$cmd = Varnish::VACAgent::DataToVarnish->new(data          => $cmdline_2,
                                             authenticated => 0);

# say("cmd: ", Dumper($cmd));

isnt($cmd, undef, "non-null command line 2");
isa_ok($cmd, 'Varnish::VACAgent::DataToVarnish');
is($cmd->data(), "", "data");
is($cmd->authenticated(), 0, "authenticated");
is($cmd->command(), "help", "command");
is($cmd->line(), "help some_command", "line");
is($cmd->heredoc(), undef, "heredoc");
is_deeply($cmd->args, ['some_command'], "args");
is($cmd->to_string(), "help some_command\n", "to_string()");



# cmdline_3

# my $cmdline_3 = "vcl.load some_name << DELIMITER\r\n" .
#     "first vcl line\r\n" .
#     "second vcl line\r\n" .
#     "DELIMITER\r\n";
$cmd = Varnish::VACAgent::DataToVarnish->new(data          => $cmdline_3,
                                             authenticated => 1);

# say("cmd: ", Dumper($cmd));

isnt($cmd, undef, "non-null command line 3");
isa_ok($cmd, 'Varnish::VACAgent::DataToVarnish');
is($cmd->data(), "", "data");
is($cmd->authenticated(), 1, "authenticated");
is($cmd->command(), "vcl.load", "command");
is($cmd->line(), "vcl.load some_name << DELIMITER", "line");
is($cmd->heredoc(), "first vcl line\nsecond vcl line\n", "heredoc");
is_deeply($cmd->args,
          ['some_name', "first vcl line\nsecond vcl line\n"],
          "args");
is($cmd->to_string(),
   "vcl.load some_name << DELIMITER\n" .
   "first vcl line\n" .
   "second vcl line\n" .
   "DELIMITER\n", "to_string()");
