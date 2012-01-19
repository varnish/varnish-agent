package Varnish::VACAgent::Role::TextManipulation;

use Moose::Role;

use Data::Dumper;



=head1 DESCRIPTION

Text manipulation routines useful to format and print the
VAC<->Varnish protocol.

=cut



# Escape special chars in a string
sub make_printable {
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
