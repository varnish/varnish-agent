package Varnish::VACAgent::VarnishResponse;

use Moose;
use Data::Dumper;



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation'
;


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

# Constants
has CLI_STATUS_SYNTAX  => (is => 'ro', init_arg => undef, default => 100);
has CLI_STATUS_UNKNOWN => (is => 'ro', init_arg => undef, default => 101);
has CLI_STATUS_UNIMPL  => (is => 'ro', init_arg => undef, default => 102);
has CLI_STATUS_TOOFEW  => (is => 'ro', init_arg => undef, default => 104);
has CLI_STATUS_TOOMANY => (is => 'ro', init_arg => undef, default => 105);
has CLI_STATUS_PARAM   => (is => 'ro', init_arg => undef, default => 106);
has CLI_STATUS_AUTH    => (is => 'ro', init_arg => undef, default => 107);
has CLI_STATUS_OK      => (is => 'ro', init_arg => undef, default => 200);
has CLI_STATUS_CANT    => (is => 'ro', init_arg => undef, default => 300);
has CLI_STATUS_COMMS   => (is => 'ro', init_arg => undef, default => 400);
has CLI_STATUS_CLOSE   => (is => 'ro', init_arg => undef, default => 500);
has CLI_HEADERLINE_LEN => (is => 'ro', init_arg => undef, default =>  13);



sub BUILD {
    my $self = shift;

    my $message = $self->message();
    my $received_length = bytes::length($message);
    
    my $length = $self->length();
    if ($received_length != $length) {
        die "CLI communication error. Expected to read $length bytes, " .
            "but read $received_length: $!";
    }
    $self->debug("V->A: " . $self->make_printable($self->to_string()));
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
