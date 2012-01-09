package Varnish::VACAgent::VACClient;

use Moose;
use Socket;

extends 'Reflex::Stream';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



has event => (
    is => 'ro',
    isa => 'Reflex::Event::Socket',
#    handles => [ 'peer' ],
    required => 1,
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
    default => sub { $_[0]->event->peer() },
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



sub _build_agent {
    return Varnish::VACAgent::Singleton::Agent->instance();
}

sub _build_handle {
    return $_[0]->event->handle;
}


                   # $hersockaddr    = getpeername(SOCK);
                   # ($port, $iaddr) = sockaddr_in($hersockaddr);
                   # $herhostname    = gethostbyaddr($iaddr, AF_INET);
#                   $herstraddr     = inet_ntoa($iaddr);

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

    return gethostbyaddr($iaddr, AF_INET);
}



sub on_data {
    my ($self, $event) = @_;

    $self->info("VACClient received data");

    my $response = $self->agent->handle_vac_client_request($event->octets());
    $self->put($response);
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
