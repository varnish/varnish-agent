package Varnish::VACAgent::Role::VarnishCLI;

use Moose::Role;

use Data::Dumper;
use Digest::SHA qw(sha256_hex sha1_hex);

use Varnish::VACAgent::DataToVarnish;
use Varnish::VACAgent::DataToClient;

requires 'make_printable';



=head1 DESCRIPTION

Formatting and decoding of varnish CLI messages

=cut



sub decode_data_from_varnish {
    my ($self, $data) = @_;
    
    $self->debug("V->A: " . $self->make_printable($data));
    return $self->_decode_data_from_varnish($data);
}



sub decode_data_from_varnish_master {
    my ($self, $data) = @_;
    
    $self->debug("M: " . $self->make_printable($data));
    return $self->_decode_data_from_varnish($data);
}



sub _decode_data_from_varnish {
    my ($self, $data) = @_;
    
    chomp($data);
    $data =~ m/^(\d+)\s+(\d+)\s*$(?:\n)?(.*)/ms
	or die "CLI protocol error: Syntax error, data: " .
            $self->make_printable($data);
    my ($status, $length, $message) = ($1, $2, $3);
    
    return Varnish::VACAgent::DataToClient->new(status  => $status,
                                                length  => $length,
                                                message => $message);
}



# format_data_to_varnish returns a newly created DataToVarnish object
# based on the supplied command string and boolean authenticated
# value.

sub format_data_to_varnish {
    my ($self, $command, $auth) = @_;
    
    return Varnish::VACAgent::DataToVarnish->new(data => $command . "\n",
                                                 authenticated => $auth);
}

    

sub format_auth_command {
    my ($self, $challenge, $secret) = @_;
    
    my $cmd = "auth " . sha256_hex("$challenge\n" . $secret . "$challenge\n");
    return $self->format_data_to_varnish($cmd, 0);
}



sub make_vcl_name {
    my ($self, $data) = @_;
    
    return sha1_hex($data);
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
