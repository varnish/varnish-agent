package Varnish::VACAgent::VACClient;

use Moose;
use Socket;

extends 'Varnish::VACAgent::SocketClient';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



sub on_data {
    my ($self, $event) = @_;

    $self->info("VACClient received data");

    my $response = $self->agent->handle_vac_client_request($event->octets());
    $self->put($response);
}



1;
