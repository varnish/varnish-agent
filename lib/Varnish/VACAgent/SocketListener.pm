package Varnish::VACAgent::SocketListener;

use 5.010;
use Moose;
use IO::Socket;
use Data::Dumper;

extends 'Reflex::Acceptor';



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



has listener => (
    is         => 'rw',
    isa        => 'FileHandle',
    required   => 1,
    lazy_build => 1,
);

has address => (
    is => 'rw',
    isa => 'Str',
    lazy_build => 1,
);

has port => (
    is => 'rw',
    isa => 'Str',
    lazy_build => 1,
);

has client_counter => (
    is => 'rw',
    isa => 'Int',
    traits => [ 'Counter' ],
    handles => {
        _count_client => 'inc',
    },
    default => 0,
);



sub _build_listener {
    my $self = shift;

    $self->debug("SocketListener->_build_listener");
    
    $self->debug("SocketListener address/port: ", $self->address, "/",
                 $self->port);
    
    my $listen_socket = IO::Socket::INET->new(
        Type => SOCK_STREAM,
        Proto => 'tcp',
        LocalAddr => $self->address,
        LocalPort => $self->port,
        Listen => 1,
        ReuseAddr => 1,
    ) or die "Can't create listening socket: $@";
    
    return $listen_socket;
}



1;
