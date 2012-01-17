package Varnish::VACAgent::VarnishResponse;

use Moose;
use Data::Dumper;



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



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



sub BUILD {
    my $self = shift;

    my $message = $self->message();
    my $received_length = bytes::length($message);
    
    my $length = $self->length();
    if ($received_length != $length) {
        die "CLI communication error. Expected to read $length bytes, " .
            "but read $received_length: $!";
    }
    $self->debug("V->A: " . $self->pretty_line($message));
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



sub is_ok {
    my $self = shift;
    
    return $self->status() == $self->CLI_STATUS_OK();
}



sub is_auth {
    my $self = shift;

    return $self->status() == $self->CLI_STATUS_AUTH();
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
