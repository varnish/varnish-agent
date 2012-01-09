package Reflex::Connector;
{
  $Reflex::Connector::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);

has active  => ( is => 'ro', isa => 'Bool', default => 1 );
has address => ( is => 'ro', isa => 'Str', default  => '127.0.0.1' );
has port    => ( is => 'ro', isa => 'Int' );
has socket  => ( is => 'rw', isa => 'FileHandle' );

with 'Reflex::Role::Connecting' => {
	att_connector => 'socket',      # Default!
	att_address   => 'address',     # Default!
	att_port      => 'port',        # Default!
	cb_success    => make_emitter(on_connection => "connection"),
	cb_error      => make_emitter(on_error => "error"),
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Connector - non-blocking client socket connector

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

This is a partial excerpt from eg/eg-38-promise-client.pl

	use Reflex::Connector;
	use Reflex::Stream;

	my $connector = Reflex::Connector->new(port => 12345);

	my $event = $connector->next();
	if ($event->{name} eq "failure") {
		die("error $event->{arg}{errnum}: $event->{arg}{errstr}");
	}

	my $stream = Reflex::Stream->new(
		handle => $event->{arg}{socket},
	);

=head1 DESCRIPTION

Reflex::Connector asynchronously establishes a client connection.  It
is almost entirely implemented in Reflex::Role::Connecting.  That
role's documentation contains important details that won't be covered
here.

=head2 Public Attributes

=head3 address

C<address> defines the remote address to which Reflex::Connector will
attempt a connection.  It defaults to "127.0.0.1".
See Reflex::Role::Connecting for more details.

=head3 port

C<port> defines the remote port to which Reflex::Connector will
attempt a connection.  It has no default.
See Reflex::Role::Connecting for more details.

=head3 socket

Reflex::Connector will provide its own socket by default.  It also
accepts a C<socket> that may be configured in custom ways.

See C<connector> in Reflex::Role::Connecting for more details.

=head2 Public Methods

None.

=head2 Callbacks

=head3 on_connection

C<on_connection> is called when Reflex::Connector establishes a
connection.
Reflex::Role::Connecting explains the data returned with
C<on_connection>.
If necessary, that role will also define a default C<on_connection>
handler that emits "success" event.  (TODO - Does this make sense?)

=head3 on_error

C<on_error> is called whenever a connection fails for some reason.
returns an error.  Reflex::Role::Connecting explains the data returned
with C<on_error>.  If necessary, that role will also define a default
C<on_error> handler that emits an "error" event.

=head2 Public Events

Reflex::Connector emits events related to establishing clinet
connections.  These events are defined by Reflex::Role::Connecting,
and they will be explained there.

=head3 success

If no C<on_connection> handler is set, then Reflex::Connector will
emit a "success" event if the connection is successfuly established.
Reflex::Role::Connecting explains this event in more detail.

=head3 error

If no C<on_error> handler is set, then Reflex::Connector will emit an
"error" event whenever a connection fails to establish.
Reflex::Role::Connecting explains this event in more detail.

=head1 EXAMPLES

The SYNOPSIS is a partial excerpt from eg/eg-38-promise-client.pl

eg/eg-35-tcp-client.pl is a more callbacky client.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Role::Connecting>

=item *

L<Reflex::Role::Accepting>

=item *

L<Reflex::Acceptor>

=item *

L<Reflex/ACKNOWLEDGEMENTS>

=item *

L<Reflex/ASSISTANCE>

=item *

L<Reflex/AUTHORS>

=item *

L<Reflex/BUGS>

=item *

L<Reflex/BUGS>

=item *

L<Reflex/CONTRIBUTORS>

=item *

L<Reflex/COPYRIGHT>

=item *

L<Reflex/LICENSE>

=item *

L<Reflex/TODO>

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Rocco Caputo <rcaputo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rocco Caputo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Reflex/>.

The development version lives at L<http://github.com/rcaputo/reflex>
and may be cloned from L<git://github.com/rcaputo/reflex.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__

