package Varnish::VACAgent::Role::VarnishCLIConstants;

use Moose::Role;



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



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
