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


sub put {
    my ($self, $data) = @_;
    
    $self->debug("in put()");
    my $event = $self->next();
    $self->debug("in put() after next()");
    $self->stream(Reflex::Stream->new(handle => $event->handle()));
    $self->debug("in put() after Reflex::Stream->new()");
    $self->stream->put($data);
    $self->debug("in put() after stream->put()");
}



sub response {
    my $self = shift;
    
    $self->debug("in response()");
    my $response_event = $self->stream->next();
    $self->debug("in response() after next()");
    $self->debug("response_event: ", Dumper($response_event));
    
    if (ref $response_event eq 'Reflex::Event::EOF') {
        $self->debug("Varnish connection has been closed by remote");
        return "";
    }

    my $response = $self->receive_response($response_event);
    $self->debug("Response: ", Dumper($response));
    return $response;
}



sub receive_response {
    my ($self, $event) = @_;
    
    my $data = $event->octets();
    $self->debug("receive_response, data: ", $data);
    my @lines = split("\n", $data);
    my $line;
    
    $self->debug("receive_response, lines: ", Dumper(\@lines));
    
    do {
        $line = shift @lines;
	$self->debug("V->A: " . $self->pretty_line($line));
	chomp $line;
    } while $line eq "";
    $line =~ /^(\d+)\s+(\d+)\s*$/
	or die "CLI protocol error: Syntax error";
    my $status = $1;
    my $length = $2;
#    my $data;
#    my $bytes_read = $handle->read($data, $length);
#    $length==$bytes_read
#	or die "CLI communication error. Expected to read $length bytes, but read $bytes_read: $!";
#    $self->debug("V->A: ".pretty_line($data));

    # Read the empty line
#    $line = <$handle>;

    return { status => $status, data => $data };
}



# Escape special chars in a string
sub pretty_line {
    my ($self, $line) = @_;
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
