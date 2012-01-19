package Varnish::VACAgent::VarnishClientConnection;

use Moose;
use Socket;
use Data::Dumper;

use Reflex::Connector;
use Reflex::Stream;

extends 'Reflex::Connector';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';



has proxy_session_id => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has stream => (
    is => 'rw',
    isa => 'Reflex::Stream',
);



sub BUILD {
    my $self = shift;

    my $event = $self->next();
    $self->stream(Reflex::Stream->new(handle => $event->handle(),
                                      on_closed => sub { $self->on_closed }));
}    



sub on_closed {
    my ($self, $event) = @_;
    
    $self->debug("Varnish terminated the connection!");
    $self->_trigger_termination();
}



sub put {
    my ($self, $data) = @_;
    
    $self->debug("A->V: ", $self->make_printable($data));
    $self->stream->put($data);
}



sub _trigger_termination {
    my $self = shift;
    
    my $agent = Varnish::VACAgent::Singleton::Agent->instance();
    $agent->terminate_proxy_session($self->proxy_session_id());
}


    
sub terminate {
    my $self = shift;

    $self->stream->stop();
}



sub response {
    my $self = shift;
    
    my $response_event = $self->stream->next();
    
    if (ref $response_event eq 'Reflex::Event::EOF' ||
            $response_event->_name eq 'stopped') {
        $self->debug("Varnish connection has been closed by remote");
        die "EOF";
    }
    
    my $response = $self->receive_response($response_event);
    return $response;
}



sub receive_response {
    my ($self, $event) = @_;
    
    my $data = $event->octets();
    
    chomp($data);
    $data =~ m/^(\d+)\s+(\d+)\s*$(?:\n)?(^.*)/ms
	or die "CLI protocol error: Syntax error";
    my ($status, $length, $message) = ($1, $2, $3);
    
    return Varnish::VACAgent::VarnishResponse->new(status  => $status,
                                                   length  => $length,
                                                   message => $message);
}

    

sub DEMOLISH {
    my $self = shift; 
   
    $self->debug("VarnishClientConnection demolished");
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
