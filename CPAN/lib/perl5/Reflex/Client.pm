# A simple socket client.  Generic enough to be used for INET and UNIX
# sockets, although we may need to specialize for each kind later.

# TODO - This is a simple strawman implementation.  It needs
# refinement.

package Reflex::Client;
{
  $Reflex::Client::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
use Reflex::Stream;

extends 'Reflex::Connector';
with 'Reflex::Role::Collectible';
use Reflex::Trait::Watched qw(watches);

has protocol => (
	is      => 'rw',
	isa     => 'Str',
	default => 'Reflex::Stream',
);

watches connection => (
	isa     => 'Maybe[Reflex::Stream]',
	# Maps $self->put() to $self->connection()->put().
	# TODO - Would be nice to have something like this for outbout
	# events.  See on_connection_data() later in this module for more.
	handles => ['put'],
);

sub on_connection {
	my ($self, $socket) = @_;

	$self->connection(
		$self->protocol()->new(
			handle => $socket->handle(),
			rd     => 1,
		)
	);

	$self->emit( -name => "connected" );
	#$self->re_emit( $socket, -name => "connected" );
}

sub on_error {
	my ($self, $error) = @_;
	# TODO - Emit rather than warn.
	warn $error->formatted(), "\n";
}

sub on_connection_closed {
	my ($self, $eof) = @_;
	$self->connection()->stop();
	# TODO - Emit rather than warn.
	warn "server closed connection.\n";
}

sub on_connection_failure {
	my ($self, $error) = @_;
	$self->connection()->stop();
	# TODO - Emit rather than warn.
	warn $error->formatted(), "\n";
}

# This odd construct lets us rethrow a low-level event as a
# higher-level event.  It's similar to the way Moose "handles" works,
# although in the other (outbound) direction.
#
# TODO - It's rather inefficient to rethrow like this at runtime.
# Some compile- or init-time remapping construct would be better.
#
# TODO - While we're rethrowing, we should consider a generic facility
# for passing -type through.

sub on_connection_data {
	my ($self, $data) = @_;
	$self->re_emit( $data, -name => "data" );
}

sub stop {
	my $self = shift();
	$self->connection(undef);
	$self->stopped();
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Client - A non-blocking socket client.

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

This is a complete working TCP echo client.  It's the version of
eg/eg-35-tcp-client.pl available at the time of this writing.

	use lib qw(../lib);

	{
		package TcpEchoClient;
		use Moose;
		extends 'Reflex::Client';

		sub on_client_connected {
			my ($self, $event) = @_;
			$self->connection()->put("Hello, world!\n");
		};

		sub on_client_data {
			my ($self, $event) = @_;

			# Not chomped.
			warn "got from server: ", $event->data();

			# Disconnect after we receive the echo.
			$self->stop();
		}
	}

	TcpEchoClient->new(
		remote_addr => '127.0.0.1',
		remote_port => 12345,
	)->run_all();

=head1 DESCRIPTION

Reflex::Client is scheduled for substantial changes.  One of its base
classes, Reflex::Handle, will be deprecated in favor of
Reflex::Role::Readable and Reflex::Role::Writable.  Hopefully
Reflex::Client's interfaces won't change much as a result, but
there are no guarantees.
Your ideas and feedback for Reflex::Client's future implementation
are welcome.

Reflex::Client is a high-level base class for non-blocking socket
clients.  As with other Reflex::Base classes, this one may be
subclassed, composed with "has", or driven inline with promises.

=head2 Attributes

Reflex::Client extends (and includes the attributes of)
Reflex::Connector, which extends Reflex::Handle.  It also provides its
own attributes.

=head3 protocol

The "protocol" attribute contains the name of a class that will handle
I/O for the client.  It contains "Reflex::Stream" by default.

Protocol classes should extend Reflex::Stream or at least follow its
interface.

=head2 Public Methods

Reflex::Client extends Reflex::Handle, but it currently provides no
additional methods.

=head2 Events

Reflex::Client emits some of its own high-level events based on its
components' activities.

=head3 connected

Reflex::Client emits "connected" to notify consumers when the client
has connected, and it's safe to begin sending data.

=head3 data

Reflex::Client emits stream data with the "data" event.  This event is
provided by Reflex::Stream.  Please see L<Reflex::Stream/data> for the
most current documentation.

=head1 EXAMPLES

eg/eg-35-tcp-client.pl subclasses Reflex::Client as TcpEchoClient.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Client>

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

