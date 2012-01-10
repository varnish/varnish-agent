package Varnish::VACAgent::MasterListener;

use 5.010;
use Moose;
use Data::Dumper;

use Reflex::Collection;

use Varnish::VACAgent::VarnishInstance;


extends 'Varnish::VACAgent::SocketListener';

has_many varnish_instances => ( handles => { remember_client => "remember" } );

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



has_many varnish_instances => ( handles => { remember_varnish => "remember" });



sub _build_address {
    my $self = shift;

    return $self->_config->master_address;
}



sub _build_port {
    my $self = shift;

    return $self->_config->master_port;
}



sub on_accept {
    my ($self, $event) = @_;
    # $self->debug("Event type: ", ref $event);
    
    my $agent = Varnish::VACAgent::Singleton::Agent->instance();
    my $varnish = Varnish::VACAgent::VarnishInstance->new(event => $event);
    $self->remember_varnish($varnish);
    $agent->new_varnish_instance($varnish);
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
