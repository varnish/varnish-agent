package Reflex::Role::Connecting;
{
  $Reflex::Role::Connecting::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;

use Errno qw(EWOULDBLOCK EINPROGRESS);
use Socket qw(SOL_SOCKET SO_ERROR inet_aton pack_sockaddr_in);

use Reflex::Event::Error;
use Reflex::Event::Socket;

attribute_parameter att_address => "address";
attribute_parameter att_port    => "port";
attribute_parameter att_socket  => "socket";
callback_parameter  cb_error    => qw( on att_socket error );
callback_parameter  cb_success  => qw( on att_socket success );

role {
	my $p = shift;

	my $att_address = $p->att_address();
	my $att_port    = $p->att_port();
	my $att_socket  = $p->att_socket();

	my $cb_error    = $p->cb_error();
	my $cb_success  = $p->cb_success();

	requires $att_address, $att_port, $att_socket, $cb_error, $cb_success;

	my $internal_writable = "on_${att_socket}_writable";
	my $internal_stop     = "stop_${att_socket}_writable";

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $args) = @_;

		# TODO - Needs to be a lot more robust.  See
		# POE::Wheel::SocketFactory for platform issues.
		#
		# TODO - Verify this makes the connect() non-blocking.  Need to
		# make the socket non-blocking if we connect() first.

		# Create a handle if we need to.
		unless ($self->$att_socket()) {
			$self->$att_socket(IO::Socket::INET->new(Proto => 'tcp'));
		}

		my $att_handle = $self->$att_socket();

		my $packed_address;
		if ($att_handle->isa("IO::Socket::INET")) {
			# TODO - Need a non-bollocking resolver.
			my $inet_address = inet_aton($self->$att_address());
			$packed_address = pack_sockaddr_in(
				$self->$att_port(), $inet_address
			);
		}
		else {
			die "unknown socket class: ", ref($att_handle);
		}

		# TODO - Make sure we're in the right session.
		my $method_start = "start_${att_socket}_writable";
		$self->$method_start();

		# Begin connecting.
		unless (connect($att_handle, $packed_address)) {
			if ($! and ($! != EINPROGRESS) and ($! != EWOULDBLOCK)) {
				$self->$cb_error(
					Reflex::Event::Error->new(
						_emitters => [ $self ],
						number    => ($!+0),
						string    => "$!",
						function  => "connect",
					)
				);

				$self->$internal_stop();
				return;
			}
		}
	};

	method $internal_writable => sub {
		my ($self, $socket) = @_;

		# Not watching anymore.
		$self->$internal_stop();

		# Throw a failure if the connection failed.
		$! = unpack('i', getsockopt($socket->handle(), SOL_SOCKET, SO_ERROR));
		if ($!) {
			$self->$cb_error(
				Reflex::Event::Error->(
					_emitters => [ $self ],
					number    => ($!+0),
					string    => "$!",
					function  => "connect",
				)
			);
			return;
		}

		$self->$cb_success(
			Reflex::Event::Socket->new(
				_emitters => [ $self ],
				handle    => $socket->handle(),
			)
		);
		return;
	};

	with 'Reflex::Role::Writable' => {
		att_handle => $att_socket,
	};
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role::Connecting - add non-blocking client connecting to a class

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	package Reflex::Connector;

	use Moose;
	extends 'Reflex::Base';

	has socket => (
		is        => 'rw',
		isa       => 'FileHandle',
	);

	has port => (
		is => 'ro',
		isa => 'Int',
	);

	has address => (
		is      => 'ro',
		isa     => 'Str',
		default => '127.0.0.1',
	);
TODO - Changed.
	with 'Reflex::Role::Connecting' => {
		connector   => 'socket',      # Default!
		address     => 'address',     # Default!
		port        => 'port',        # Default!
		cb_success  => 'on_connection',
		cb_error    => 'on_error',
	};

	1;

=head1 DESCRIPTION

Reflex::Role::Connecting is a Moose parameterized role that adds
non-blocking connect() behaviors to classes.

See Reflex::Connector if you prefer runtime composition with objects,
or if Moose syntax just gives you the willies.

=head2 Required Role Parameters

None.

=head2 Optional Parameters

=head3 address

C<address> defines the attribute that will contain the address to
which the class will connect.  The address() attribute will be used if
the class doesn't override the name.  The default address will be the
IPv4 localhost, "127.0.0.1".

=head3 port

C<port> defines the attribute that will contain the port to which this
role will connect.  By default, the role will use the port()
attribute.  There is no default port() value.

=head3 socket

The C<socket> parameter must contain the name of an attribute that
contains the connecting socket handle.  "socket" will be used if a
name isn't provided.  A C<socket> must be provided if two or more
client connections will be created from the same class, otherwise they
will both attempt to use the same "socket".

Reflex::Role::Connecting will create a plain TCP socket if C<socket>'s
attribute is empty at connecting time.  A class may build its own
socket, if it needs to set special options.

The role will generate additional methods and callbacks that are named
after C<socket>.  For example, if C<socket> contains XYZ, then the
default error callback will be on_XYZ_error().

=head3 cb_success

C<cb_success> overrides the default name for the class's successful
connection handler method.  This handler will be called whenever a
client connection is successfully connected.

The default method name is "on_${socket}_success", where $socket is
the name of the socket attribute.

The role defines a default "on_${socket}_success" callback that emits
an event with the callback's parameters.  The default event is the
C<socket> name followed by "_success", as in "XYZ_success".

The role's C<ev_success> parameter changes the name of the success
event to be emitted.

All callback methods receive two parameters: $self and an anonymous
hash containing information specific to the callback.  In
C<cb_success>'s case, the anonymous hash contains one value: the
socket that has just established a connection.

=head3 cb_error

C<cb_error> names the $self method that will be called whenever
connect() encounters an error.  By default, this method will be the
catenation of "on_", the C<socket> name, and "_error".  As in
on_XYZ_error(), if the socket attribute is named "XYZ".

The role defines a default callback that will emit an event with
cb_error()'s parameters.  The default event is the C<socket> name
followed by "_error".  For example, "XYZ_error".  The role's
C<ev_error> parameter changes the event to be emitted.

C<cb_error> callbacks receive two parameters, $self and an anonymous
hashref of named values specific to the callback.  Reflex error
callbacks include three standard values.  C<errfun> contains a
single word description of the function that failed.  C<errnum>
contains the numeric value of C<$!> at the time of failure.  C<errstr>
holds the stringified version of C<$!>.

Values of C<$!> are passed as parameters since the global variable may
change before the callback can be invoked.

When overriding this callback, please be sure to call stopped(), which
is provided by Reflex::Role::Collectible.  Calling stopped() is vital
for collectible objects to be released from memory when managed by
Reflex::Collection.

=head1 EXAMPLES

TODO - I'm sure there are some.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Role::Accepting>

=item *

L<Reflex::Acceptor>

=item *

L<Reflex::Connector>

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

