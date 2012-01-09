package Reflex::Acceptor;
{
  $Reflex::Acceptor::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter make_terminal_emitter);

has listener => ( is => 'rw', isa => 'FileHandle', required => 1);
has active => ( is => 'ro', isa => 'Bool', default => 1 );

with 'Reflex::Role::Accepting' => {
	att_active    => 'active',
	att_listener  => 'listener',
	cb_accept     => make_emitter(on_accept => "accept"),
	cb_error      => make_terminal_emitter(on_error => "error"),
	method_pause  => 'pause',
	method_resume => 'resume',
	method_stop   => 'stop',
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Acceptor - a non-blocking server (client socket acceptor)

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	package TcpEchoServer;

	use Moose;
	extends 'Reflex::Acceptor';
	use Reflex::Collection;
	use EchoStream;

	has_many clients => ( handles => { remember_client => "remember" } );

	sub on_accept {
		my ($self, $event) = @_;
		$self->remember_client(
			EchoStream->new(
				handle => $event->socket(),
				rd     => 1,
			)
		);
	}

	sub on_error {
		my ($self, $event) = @_;
		warn(
			$event->error_function(),
			" error ", $event->error_number(),
			": ", $event->error_string(),
			"\n"
		);
		$self->stop();
	}

=head1 DESCRIPTION

Reflex::Acceptor takes a listening socket and produces new sockets for
clients that connect to it.  It is almost entirely implemented in
Reflex::Role::Accepting.  That role's documentation contains important
details that won't be covered here.

=head2 Public Attributes

=head3 listener

Reflex::Acceptor defines a single attribute, C<listner>, which should
be set to a listening socket of some kind.  Reflex::Acceptor requires
an externally supplied socket so that the user may specify any and all
applicable socket options.

If necessary, the class may later supply a basic socket by default.

Reflex::Role::Accepting explains C<listener> in more detail.

=head2 Public Methods

=head3 pause

pause() will temporarily stop the server from accepting more clients.
See C<method_pause> in Reflex::Role::Accepting for details.

=head3 resume

resume() will resume a temporarily stopped server so that it may
accept more client connections.  See C<method_resume> in
Reflex::Role::Accepting for details.

=head3 stop

stop() will permanently stop the server from accepting more clients.
See C<method_stop> in Reflex::Role::Accepting for details.

=head2 Callbacks

=head3 on_accept

C<on_accept> is called whenever Perl's built-in accept() function
returns a socket.  Reflex::Role::Accepting explains the data returned
with C<on_accept>.  If necessary, that role will also define a default
C<on_accept> handler that emits an "accept" event.

=head3 on_error

C<on_error> is called whenever Perl's built-in accept() function
returns an error.  Reflex::Role::Accepting explains the data returned
with C<on_error>.  If necessary, that role will also define a default
C<on_error> handler that emits an "error" event.

=head2 Public Events

Reflex::Acceptor emits events related to accepting client connections.
These events are defined by Reflex::Role::Accepting, and they will be
explained there.

=head3 accept

If no C<on_accept> handler is set, then Reflex::Acceptor will emit an
"accept" event for every client connection accepted.
Reflex::Role::Accepting explains this event in more detail.

=head3 error

If no C<on_error> handler is set, then Reflex::Acceptor will emit an
"error" event every time accept() returns an error.
Reflex::Role::Accepting explains this event in more detail.

=head1 EXAMPLES

The SYNOPSIS is an excerpt from eg/eg-34-tcp-server-echo.pl.

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

L<Reflex::Role::Connecting>

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

