package Varnish::VACAgent::Singleton::Config;

=head1 NAME

Singleton::Config

=head1 SYNOPSIS

package SomeSingleton;
extends 'Varnish::Singleton::Config';

=head1 DESCRIPTION

The class provides common options for configuration and logging.
Default values for the options are set in code, but and can be
overridden in a yml file or ultimately on the commandline.

The class also provides a help/usage menu for the commandline.

Options (and their default values) are usually
added or overridden by an extending class.

=cut

use MooseX::Singleton;

use Cwd          qw( abs_path );
use FindBin      qw( $RealBin $RealScript );
use Data::Dumper qw( Dumper );

with 'MooseX::Getopt::Dashes';
with 'MooseX::SimpleConfig';

# Sort cmdlineoptions
around _gld_spec => sub {
    my $orig = shift;
    my $self = shift;
    my ( $arrayref, $hashref ) = $self->$orig( @_ );
    my @array = sort { $a->[0] cmp $b->[0] } @$arrayref;
    return( \@array, $hashref );
};

=head1 LOCAL VARIABLES

=head2 B<$cfg_file>

Hard-coded default configuration file

=cut

my $cfg_file = abs_path( $RealBin . '/../config.yml' );



=head1 ATTRIBUTES

=head2 B<--configfile>

Command line option (--configfile). Path to alternative config file in
YAML format.

=cut

has config_file => (
    is       => "rw",
    isa      => "Str",
    default  => $cfg_file,
    traits      => ['Getopt'],
    cmd_aliases => 'c',
    documentation =>
        'Path to YAML format config file' . "\n",
);

has log_config_file => (
    is => "rw",
    isa => "Str",
    default => "",
    documentation =>
        "Path to Log4perl config file\n",
);

has log_format => (
    is => "rw",
    isa => "Str",
    default =>
        '%d{yyyy-MM-dd HH:mm:ss} %5p %-54m at %F{1} line %L pid:%P%n',
    documentation => 'Log line format',
);

has log_file => (
    is => "rw",
    isa => "Str",
    default => "agent.log",
    documentation => 'Path to log file',
);

has log_level => (
    is => "rw",
    isa => "Str",
    default => "debug",
    documentation =>
        'Verbosity, [trace|debug|info|warn|error]',
);

has debug => (
    is => "rw",
    isa => "Bool",
    default => 0,
    traits      => ['Getopt'],
    cmd_aliases => 'd',
    documentation =>
        'TBD' . "\n",
);

has foreground => (
    is => "rw",
    isa => "Bool",
    default => 0,
    traits      => ['Getopt'],
    cmd_aliases => 'F',
    documentation =>
        'TBD' . "\n",
);

has listen_address_spec => (
    is => "rw",
    isa => "Str",
    default => sub { ':6083' },
    traits      => ['Getopt'],
    cmd_aliases => 'T',
    documentation =>
        'TBD' . "\n",
);

has listen_address => (
    is => "ro",
    isa => "Str",
    builder => '_build_listen_address',
    traits      => ['NoGetopt'],
    lazy => 1,
);

has listen_port => (
    is => "ro",
    isa => "Str",
    builder => '_build_listen_port',
    traits      => ['NoGetopt'],
    lazy => 1,
);

has master_address_spec => (
    is => "rw",
    isa => "Str",
    default => 'localhost:6084',
    traits      => ['Getopt'],
    cmd_aliases => 'M',
    documentation =>
        'TBD' . "\n",
);

has master_address => (
    is => "ro",
    isa => "Str",
    builder => '_build_master_address',
    traits      => ['NoGetopt'],
    lazy => 1,
);

has master_port => (
    is => "ro",
    isa => "Str",
    builder => '_build_master_port',
    traits      => ['NoGetopt'],
    lazy => 1,
);

has varnish_address_spec => (
    is => "rw",
    isa => "Str",
    default => 'localhost:6082',
    traits      => ['Getopt'],
    cmd_aliases => 'b',
    documentation =>
        'TBD' . "\n",
);

has varnish_address => (
    is => "ro",
    isa => "Str",
    builder => '_build_varnish_address',
    traits      => ['NoGetopt'],
    lazy => 1,
);

has varnish_port => (
    is => "rw",
    isa => "Str",
    builder => '_build_varnish_port',
    traits      => ['NoGetopt'],
    lazy => 1,
);

has pid_file => (
    is => "rw",
    isa => "Str",
    default => '/var/run/varnish-agent.pid',
    traits      => ['Getopt'],
    cmd_aliases => 'P',
    documentation =>
        'TBD' . "\n",
);

has secret_file => (
    is => "rw",
    isa => "Str",
    default => "",
    traits      => ['Getopt'],
    cmd_aliases => 'S',
    documentation =>
        'TBD' . "\n",
);

has vcl_file => (
    is => "rw",
    isa => "Str",
    default => "/var/lib/varnish-agent/agent.vcl",
    traits      => ['Getopt'],
    cmd_aliases => 'f',
    documentation =>
        'TBD' . "\n",
);

has params_file => (
    is => "rw",
    isa => "Str",
    default => "/var/lib/varnish-agent/agent.param",
    traits      => ['Getopt'],
    cmd_aliases => 'p',
    documentation =>
        'TBD' . "\n",
);

has instance_id => (
    is => "rw",
    isa => "Str",
    default => "",
    traits      => ['Getopt'],
    cmd_aliases => 'n',
    documentation =>
        'TBD' . "\n",
);

has call_home_url => (
    is => "rw",
    isa => "Str",
    default => "",
    traits      => ['Getopt'],
    cmd_aliases => 'u',
    documentation =>
        'TBD' . "\n",
);

has ssl_ca_file => (
    is => "rw",
    isa => "Str",
    default => "",
    traits      => ['Getopt'],
    cmd_aliases => 'C',
    documentation =>
        'TBD' . "\n",
);

has varnish_stat_command => (
    is => "rw",
    isa => "Str",
    default => "varnishstat -1",
    documentation =>
        'TBD' . "\n",
);



sub _build_listen_address {
    return (split /:/, $_[0]->listen_address_spec)[0] || "localhost";
}

sub _build_listen_port {
    return (split /:/, $_[0]->listen_address_spec)[1];
}

sub _build_master_address {
    return (split /:/, $_[0]->master_address_spec)[0] || "localhost";
}

sub _build_master_port {
    return (split /:/, $_[0]->master_address_spec)[1];
}

sub _build_varnish_address {
    return (split /:/, $_[0]->varnish_address_spec)[0] || "localhost";
}

sub _build_varnish_port {
    return (split /:/, $_[0]->varnish_address_spec)[1];
}




1;
