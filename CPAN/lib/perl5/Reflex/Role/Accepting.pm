package Reflex::Role::Accepting;
{
  $Reflex::Role::Accepting::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Event::Socket;
use Reflex::Event::Error;

attribute_parameter att_active    => "active";
attribute_parameter att_listener  => "listener";
callback_parameter  cb_accept     => qw( on att_listener accept );
callback_parameter  cb_error      => qw( on att_listener error  );
method_parameter    method_pause  => qw( pause att_listener _ );
method_parameter    method_resume => qw( resume att_listener _ );
method_parameter    method_stop   => qw( stop att_listener _ );

role {
	my $p = shift;

	my $att_listener = $p->att_listener();
	my $cb_accept    = $p->cb_accept();
	my $cb_error     = $p->cb_error();

	requires $att_listener, $cb_accept, $cb_error;

	method "on_${att_listener}_readable" => sub {
		my ($self, $event) = @_;

		my $peer = accept(my ($socket), $event->handle());

		if ($peer) {
			$self->$cb_accept(
				Reflex::Event::Socket->new(
					_emitters => [ $self ],
					handle    => $socket,
					peer      => $peer,
				)
			);
			return;
		}

		$self->$cb_error(
			Reflex::Event::Error->new(
				_emitters => [ $self ],
				number    => ($! + 0),
				string    => "$!",
				operation => "accept",
			)
		);

		# TODO - Stop accepting connections?

		return;
	};

	with 'Reflex::Role::Readable' => {
		att_handle    => $att_listener,
		att_active    => $p->att_active(),
		method_pause  => $p->method_pause(),
		method_resume => $p->method_resume(),
		method_stop   => $p->method_stop(),
	};

};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role::Accepting - add connection accepting to a class

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	package Reflex::Acceptor;

	use Moose;
	extends 'Reflex::Base';

	has listener => (
		is        => 'rw',
		isa       => 'FileHandle',
		required  => 1
	);

	with 'Reflex::Role::Accepting' => {
		listener      => 'listener',
		cb_accept     => make_emitter(on_accept => "accept"),
		cb_error      => make_emitter(on_error => "error"),
		method_pause  => 'pause',
		method_resume => 'resume',
		method_stop   => 'stop',
	};

	1;

=head1 DESCRIPTION

Reflex::Role::Accepting is a parameterized Moose role that accepts
client connections from a listening socket.  The role's parameters
allow the consumer to customize the role's behavior.

	listener      key - name of attribute with the listening socket

	cb_accept     method to call with accepted sockets (on_${listner}_accept)
	cb_error      method to call with errors (on_${listener}_error)

	method_pause  method to pause accepting
	method_resume method to resume accepting
	method_stop   method to stop accepting and release resources

accept() reactions to classes that contain listening sockets.  Because
it's a role, the class composition happens before runtime, as opposed
to runtime composition that occurs in other reactive libraries.

See Reflex::Acceptor if you prefer runtime composition with objects,
or if Moose syntax just gives you the heebie-jeebies.

=head2 Required Role Parameters

=head3 listener

The C<listener> parameter must contain the name of an attribute that
contains the listening socket handle.  The name indirection allows the
role to generate methods that are unique to the listening socket.
This becomes important when a class wants to listen on more than one
socket---each socket gets its own name, and distinct methods to tell
them apart.

For example, a listener named "XYZ" would generate these methods by
default:

	cb_accept     => "on_XYZ_accept",
	cb_error      => "on_XYZ_error",
	method_pause  => "pause_XYZ",
	# ... and so on.

=head2 Optional Role Parameters

=head3 cb_accept

C<cb_accept> overrides the default name for the class's accept handler
method.  This handler will be called whenever a client connection is
successfully accepted.

The default method name is "on_${listener}_accept", where $listener is
the name of the listening socket attribute.  This role defines a
default callback that emits an "accept" event, which may be overridden
with the C<ev_accept> role parameter.

All callback methods receive two parameters: $self and an anonymous
hash containing information specific to the callback.  In
C<cb_accept>'s case, the anonymous hash contains two values:
accept()'s return value is named "peer", and the accepted client
socket is named "socket".

See perldoc -f accept() for more information about "peer" and
"socket".

=head3 cb_error

C<cb_error> names the $self method that will be called whenever
accept() encounters an error.  By default, this method will be the
catenation of "on_", the C<listener> name, and "_error".  As in
on_XYZ_error(), if the listener is named "XYZ".  The role defines a
default callback that will emit an "error" event by default, with
cb_error()'s parameters.  The default "error" event may be overridden
using the role's C<ev_error> parameter.

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

=head3 ev_accept

The C<ev_accept> role parameter overrides the default event emitted by
the C<cb_accept> callback.  It's moot if C<cb_accept> is overridden.

=head3 ev_error

The C<ev_error> role parameter overrides the default event emitted by
the C<cb_error> callback.  It's moot if C<cb_error> is overridden.

=head3 method_pause

C<method_pause> defines the name of a method that will temporarily
pause the class from accepting new clients.  The role will define this
method for you.  The default method name is "pause_${listener}", where
$listener is the name of the listening socket attribute.

=head3 method_resume

C<method_resume> defines the name of a method that will allow the class
to resume accepting new client connections.  The role will define this
method for you.  The default method name is "resume_${listener}", where
$listener is the name of the listening socket attribute.

=head3 method_stop

C<method_stop> defines the name of a method that will permanently stop
the class from accepting new clients.  The role will define this
method for you.  The default method name is "stop_${listener}", where
$listener is the name of the listening socket attribute.

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

L<Reflex::Role::Connecting>

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

