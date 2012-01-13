package Varnish::VACAgent::VACClient;

use Moose;
use Socket;
use Data::Dumper;

use Reflex::Connector;

extends 'Varnish::VACAgent::AcceptedIncomingConnection';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';


has session => (
    is => 'rw',
    isa => 'Varnish::VACAgent::ProxySession',
);

has data => (
    is => 'rw',
    isa => 'Str',
);



sub on_data {
    my ($self, $event) = @_;

    $self->info("VACClient received data: ", $event->octets());
    
    $self->data($event->octets());
    $self->session->handle_vac_request();
}



sub put {
    my ($self, $data) = @_;
    
    $self->stream->put($data);
}






1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
