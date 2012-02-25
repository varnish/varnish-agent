package Varnish::VACAgent::VarnishMasterConnection;

use Moose;

use Data::Dumper;

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

has first_request_is_dispatched => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);
    
has initialized => (
    traits => ['Bool'],
    is => 'rw',
    isa => 'Bool',
    default => 0,
    handles => {
        initialization_done => 'set',
        uninitialized       => 'not',
    },
);



# After connecting, varnish will send some data. Get the first
# event and pass the data to Agent.
# 
# After the first event, just re-emit the event so they can be
# caught with next() by whoever is calling response().

sub on_data {
     my ($self, $event) = @_;
 
     # $self->debug("VarnishMasterConnection::on_data, event: ",
     # Dumper($event));

     if (! $self->first_request_is_dispatched) {
         $self->debug("VarnishMasterConnection entering second state");
         $self->first_request_is_dispatched(1);
         $self->agent->handle_varnish_master_request($self, $event->octets());
     } elsif ($self->uninitialized) {
         $self->debug("VarnishMasterConnection in second state");
         $self->re_emit($event);
     } else {
         $self->info("Unexpected data from varnish master: ",
                     $event->octets());
     }
 }



sub on_closed {
    my ($self, $event) = @_;
    
    $self->info("Master shutting down");
}



# TODO: Some, but not complete duplication from
# VarnishClientConnection::response. This indicates that something is
# amiss with the connection classes. I think there should be a common
# Connection superclass that should contain response(). However, as
# VarnishClientConnection extends Reflex::Connector, that is currently
# difficult. Maybe VarnishClientConnection should consume
# Reflex::Role::Connecting instead.

sub response {
    my $self = shift;
    
    my $response_event = $self->next();
    
    # $self->debug("VarnishMasterConnection, response event: ",
    #              Dumper($response_event));
    
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
