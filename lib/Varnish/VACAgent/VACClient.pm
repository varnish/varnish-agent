package Varnish::VACAgent::VACClient;

use Moose;
use Socket;
use Data::Dumper;
use Carp qw(cluck);

use Reflex::Connector;

use Varnish::VACAgent::DataToVarnish;

extends 'Varnish::VACAgent::AcceptedIncomingConnection';

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';
with 'Varnish::VACAgent::Role::VarnishCLI';



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

    my $data = $event->octets();

    $self->info("C->A: ", $data);
    $self->data($data);
    $self->proxy_session->handle_vac_request();
}



sub on_closed {
    my ($self, $event) = @_;
    
    $self->debug("VAC client terminated the connection!");
    $self->_trigger_termination();
}



sub put {
    my ($self, $data) = @_;
    
    $self->debug("A->C: ", $self->make_printable($data));
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



# get_request returns a newly created DataToVarnish object based on
# the data and authenticated attributes. This reads, but does not
# change internal state.

sub get_request {
    my $self = shift;
    
    my $auth = $self->proxy_session->authenticated();
    $self->debug("authenticated: ", $auth);
    
    return $self->format_data_to_varnish($self->data(), $auth);
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
