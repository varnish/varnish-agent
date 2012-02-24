package Varnish::VACAgent::VarnishMasterConnection;

use Moose;

extends 'Varnish::VACAgent::AcceptedIncomingConnection';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';
with 'Varnish::VACAgent::Role::VarnishCLI';



has authentication_in_progress => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has authenticated => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);
    


sub on_data {
    my ($self, $event) = @_;

    my $response =
        $self->agent->handle_varnish_master_request($self, $event->octets());
    
    if (defined $response && $response) {
        $self->put($response);
    }
}



sub on_closed {
    my ($self, $event) = @_;
    
    $self->info("Master shutting down");
}



# TODO: Duplication from VarnishClientConnection! This indicates that
# something is amiss with the connection classes. I think there should
# be a common Connection superclass that should contain
# response(). However, as VarnishClientConnection extends
# Reflex::Connector, that is currently difficult. Maybe
# VarnishClientConnection should consume Reflex::Role::Connecting
# instead.

sub response {
    my $self = shift;
    
    my $response_event = $self->stream->next();
    
    if (ref $response_event eq 'Reflex::Event::EOF' ||
            $response_event->_name eq 'stopped') {
        $self->debug("Varnish master connection has been closed by remote");
        die "Varnish Master EOF";
    }
    
    my $response = $self->_decode_data_from_varnish($response_event->octets());
    return $response;
}



1;



=head1 AUTHOR

 Sigurd W. Larsen

=cut
