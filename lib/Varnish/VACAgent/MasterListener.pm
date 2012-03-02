package Varnish::VACAgent::MasterListener;

use 5.010;
use Moose;
use Data::Dumper;

use Reflex::Collection;

use Varnish::VACAgent::VarnishMasterConnection;

extends 'Varnish::VACAgent::SocketListener';



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



has_many varnish_instances => ( handles => {
    remember_varnish => 'remember',
    forget_varnish   => 'forget',
});



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
    
    $self->debug("New Varnish master connection accepted");

    my $agent = Varnish::VACAgent::Singleton::Agent->instance();
    my $varnish = Varnish::VACAgent::VarnishMasterConnection->new(
        connection_event => $event,
        listener         => $self,
    );
    $self->remember_varnish($varnish);
    $self->_count_client();
    $self->info(sprintf("M%5d", $self->client_counter));
    $agent->new_varnish_instance($varnish);
    $self->debug("MasterListener::on_accept returning");
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



sub delete_varnish_instance {
    my ($self, $varnish) = @_;
    
    $self->forget_varnish($varnish);
}



1;

=head1 AUTHOR

 Sigurd W. Larsen

=cut
