package Varnish::VACAgent::AcceptedIncomingConnection;

use Moose;
use Socket;

extends 'Reflex::Stream';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



has connection_event => (
    is => 'ro',
    isa => 'Reflex::Event::Socket',
    required => 1,
);

has stream => (
    is => 'rw',
    isa => 'Reflex::Stream',
    lazy_build => 1,
);

has agent => (
    is => 'ro',
    isa => 'Varnish::VACAgent::Singleton::Agent',
    lazy_build => 1,
);

has handle => (
    is => 'ro',
    isa => 'FileHandle',
    lazy_build => 1,
);

has peer => (
    is => 'ro',
    isa => 'Str',
    default => sub { $_[0]->connection_event->peer() },
);

has remote_port => (
    is => 'ro',
    isa => 'Int',
    lazy_build => 1,
);

has remote_ip_address => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);

has remote_hostname => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);



sub _build_stream {
    my $self = shift;

    return Reflex::Stream->new(handle => $self->handle());
}

sub _build_agent {
    return Varnish::VACAgent::Singleton::Agent->instance();
}

sub _build_handle {
    return $_[0]->connection_event->handle();
}

sub _build_remote_port {
    my ($port, $iaddr) = sockaddr_in($_[0]->peer());
    
    return $port;
}

sub _build_remote_ip_address {
    my ($port, $iaddr) = sockaddr_in($_[0]->peer());

    return inet_ntoa($iaddr);
}

sub _build_remote_hostname {
    my ($port, $iaddr) = sockaddr_in($_[0]->peer());

    # TODO: gethostbyaddr will block, which is bad. Besides, it's obsolete.
    return gethostbyaddr($iaddr, AF_INET);
}



sub on_error {
    my ($self, $event) = @_;
    warn(
        $event->error_function(),
        " error ", $event->error_number(),
        ": ", $event->error_string(),
    );
    $self->stopped();
}



sub DEMOLISH {
    $_[0]->debug("VACClient demolished as it should.");
}



1;



=head1 AUTHOR

 Sigurd W. Larsen

=cut
