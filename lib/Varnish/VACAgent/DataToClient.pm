package Varnish::VACAgent::DataToClient;

use Moose;
use Data::Dumper;



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';
with 'Varnish::VACAgent::Role::VarnishCLIConstants';



has length => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has status => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has message => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has challenge => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
);



sub BUILD {
    my $self = shift;

    my $message = $self->message();
    my $received_length = bytes::length($message);
    
    my $length = $self->length();
    if ($received_length != $length) {
        die "CLI communication error. Expected to read $length bytes, " .
            "but read $received_length: $!";
    }
}



sub _build_challenge {
    my $self = shift;

    if (! $self->status_is_auth()) {
        return "";
    }
    
    my $challenge = "";
    if ($self->message() =~ m/(\w+)/) {
        $challenge = $1;
    }
    
    return $challenge;
}



sub to_string {
    my $self = shift;

    my $header_line = $self->_format_header_line();
    
    return "$header_line\n" . $self->message() . "\n";
}



sub _format_header_line {
    my $self = shift;
    
    my $line = $self->status() . " " . $self->length();
    $line .= " " x ($self->CLI_HEADERLINE_LEN() - 1 - length($line));

    return $line;
}



sub status_is_ok {
    my $self = shift;
    
    return $self->status() == $self->CLI_STATUS_OK();
}



sub status_is_auth {
    my $self = shift;

    return $self->status() == $self->CLI_STATUS_AUTH();
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
