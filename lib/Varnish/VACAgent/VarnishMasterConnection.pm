package Varnish::VACAgent::VarnishMasterConnection;

use Moose;

extends 'Varnish::VACAgent::AcceptedIncomingConnection';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



sub on_data {
    my ($self, $event) = @_;

    $self->info("VarnishInstance received data");

    my $response =
        $self->agent->handle_varnish_master_request($event->octets());
    $self->put($response);
}



1;



=head1 AUTHOR

 Sigurd W. Larsen

=cut
