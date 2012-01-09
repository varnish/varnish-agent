package Varnish::VACAgent::ClientListener;

use 5.010;
use Moose;
use Data::Dumper;

use Reflex::Collection;

use Varnish::VACAgent::VACClient;



extends 'Varnish::VACAgent::SocketListener';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



has_many vac_clients => ( handles => { remember_vac => "remember" });



# defined in superclass, builder here
sub _build_address {
    my $self = shift;

    return $self->_config->listen_address;
}



# defined in superclass, builder here
sub _build_port {
    my $self = shift;

    return $self->_config->listen_port;
}



sub on_accept {
    my ($self, $event) = @_;
    $self->debug("Event type: ", ref $event);
    # $self->debug("Event: ", Dumper($event));

    my $agent = Varnish::VACAgent::Singleton::Agent->instance();
    my $client = Varnish::VACAgent::VACClient->new(event => $event);
    $self->debug("on_accept after VACClient->new");
    $self->remember_vac($client);
    $agent->new_vac_client($client);
    $self->debug("on_accept after new_vac_client");
}



sub on_error {
    my ($self, $event) = @_;
    warn(
        $event->error_function(),
        " error ", $event->error_number(),
        ": ", $event->error_string(),
        "\n"
    );
    $self->stop();
}



1;
