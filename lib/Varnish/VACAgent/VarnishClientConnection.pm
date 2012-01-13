package Varnish::VACAgent::VarnishClientConnection;

use Moose;
use Socket;
use Data::Dumper;

use Reflex::Connector;
use Reflex::Stream;

extends 'Reflex::Connector';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



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
    $self->stream->stop();
}



sub put {
    my ($self, $data) = @_;
    
    $self->debug("in put()");
    $self->stream->put($data);
    $self->debug("in put() after stream->put()");
}



sub response {
    my $self = shift;
    
    $self->debug("in response()");
    my $response_event = $self->stream->next();
    $self->debug("in response() after next()");
    $self->debug("response_event: ", Dumper($response_event));
    
    if (ref $response_event eq 'Reflex::Event::EOF' ||
            $response_event->_name eq 'stopped') {
        $self->debug("Varnish connection has been closed by remote");
        die "EOF";
    }
    
    my $response = $self->receive_response($response_event);
    $self->debug("Response: ", Dumper($response));
    return $response;
}



sub receive_response {
    my ($self, $event) = @_;
    
    my $data = $event->octets();
    chomp($data);
    $self->debug("receive_response, data: ", $data);
    $data =~ m/^(\d+)\s+(\d+)\s*$(?:\n)?(^.*)/ms
	or die "CLI protocol error: Syntax error";
    my ($status, $length, $response) = ($1, $2, $3);
    
    $self->debug("response w/o header: \"", $response, '"');
    my $received_length = bytes::length($response);
    
    if ($received_length != $length) {
        die "CLI communication error. Expected to read $length bytes, " .
            "but read $received_length: $!";
    }
    $self->debug("V->A: " . $self->pretty_line($response));

    return { status => $status, data => $response };
}

    

# Escape special chars in a string
sub pretty_line {
    my ($self, $line) = @_;
    
    $self->debug("pretty_line, line: ", $line);
    if (length($line) >= 256) {
	$line = substr($line, 0, 253)."...";
    }
    return Data::Dumper->new([$line])->Useqq(1)->Terse(1)->Indent(0)->Dump;
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
