package Varnish::VACAgent::Role::VarnishCLI;

use Moose::Role;

use Data::Dumper;

use Varnish::VACAgent::VarnishMessage;

requires 'make_printable';



=head1 DESCRIPTION

Formatting and decoding of varnish CLI messages

=cut



sub receive_varnish_message {
    my ($self, $data) = @_;
    
    $self->debug("V->A: " . $self->make_printable($data));
    chomp($data);
    $data =~ m/^(\d+)\s+(\d+)\s*$(?:\n)?(.*)/ms
	or die "CLI protocol error: Syntax error, data: " .
            $self->make_printable($data);
    my ($status, $length, $message) = ($1, $2, $3);
    
    return Varnish::VACAgent::VarnishMessage->new(status  => $status,
                                                  length  => $length,
                                                  message => $message);
}

    

1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
