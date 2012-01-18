package Varnish::VACAgent::VACClient;

use Moose;
use Socket;
use Data::Dumper;

use Reflex::Connector;

use Varnish::VACAgent::VACCommand;

extends 'Varnish::VACAgent::AcceptedIncomingConnection';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



has proxy_session => (
    is => 'rw',
    isa => 'Maybe[Varnish::VACAgent::ProxySession]',
);

has proxy_session_id => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

has data => (
    is => 'rw',
    isa => 'Str',
);

has authenticated => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);



sub on_data {
    my ($self, $event) = @_;

    $self->info("VACClient received data: ", $event->octets());
    
    $self->data($event->octets());
    $self->proxy_session->handle_vac_request();
}



sub on_closed {
    my ($self, $event) = @_;
    
    $self->debug("VAC client terminated the connection!");
    $self->_trigger_termination();
}



sub put {
    my ($self, $data) = @_;
    
    $self->stream->put($data);
}



sub _trigger_termination {
    my $self = shift;
    
    $self->debug("VACClient->_trigger_termination()");
    my $agent = Varnish::VACAgent::Singleton::Agent->instance();
    $agent->terminate_proxy_session($self->proxy_session_id());
}


    
sub terminate {
    my $self = shift;
    
    $self->debug("VACClient->terminate()");
    $self->put("\n");
    $self->stream->stop();
    $self->stream->handle->close();
    $self->proxy_session(undef);
}



sub get_request {
    my $self = shift;
    
    $self->debug("authenticated: ", $self->authenticated());
    
    my $command = Varnish::VACAgent::VACCommand->new(data => $self->data(),
                                                     authenticated => 0);
    $self->debug("VACClient::get_request: ", Dumper($command));
    
    return $command;
}



# Removes (possible an \r) and a \n
sub chomp_crlf {
    my $line = shift;
    $line =~ s/\r?\n$//;
    return $line;
}



sub DEMOLISH {
    my $self = shift; 
   
    $self->debug("VACClient demolished");
}




1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
