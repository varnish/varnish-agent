package Reflex::Role::Writable;
{
  $Reflex::Role::Writable::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Event::FileHandle;

# TODO - Reflex::Role::Readable and Writable are nearly identical.
# Can they be abstracted further?  Possibly composed as parameterized
# instances of a common base role?

use Scalar::Util qw(weaken);

attribute_parameter att_active    => "active";
attribute_parameter att_handle    => "handle";
callback_parameter  cb_ready      => qw( on att_handle writable );
method_parameter    method_pause  => qw( pause att_handle writable );
method_parameter    method_resume => qw( resume att_handle writable );
method_parameter    method_start  => qw( start att_handle writable );
method_parameter    method_stop   => qw( stop att_handle writable );

role {
	my $p = shift;

	my $att_active    = $p->att_active();
	my $att_handle    = $p->att_handle();
	my $cb_name       = $p->cb_ready();

	requires $att_active, $att_handle, $cb_name;

	my $method_pause  = $p->method_pause();
	my $method_resume = $p->method_resume();
	my $method_start  = $p->method_start();
	my $method_stop   = $p->method_stop();

	method $method_start => sub {
		my ($self, $arg) = @_;

		# Must be run in the right POE session.
		return unless $self->call_gate($method_start, $arg);

		my $envelope = [ $self, $cb_name, 'Reflex::Event::FileHandle' ];
		weaken $envelope->[0];

		$POE::Kernel::poe_kernel->select_write(
			$self->$att_handle(), 'select_ready', $envelope,
		);
	};

	method $method_pause => sub {
		my ($self, $arg) = @_;
		return unless $self->call_gate($method_pause, $arg);
		$POE::Kernel::poe_kernel->select_pause_write($self->$att_handle());
	};

	method $method_resume => sub {
		my ($self, $arg) = @_;
		return unless $self->call_gate($method_resume, $arg);
		$POE::Kernel::poe_kernel->select_resume_write($self->$att_handle());
	};

	method $method_stop => sub {
		my ($self, $arg) = @_;
		return unless $self->call_gate($method_stop, $arg);
		$POE::Kernel::poe_kernel->select_write($self->$att_handle(), undef);
	};

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $arg) = @_;
		$self->$method_start() if $self->$att_active();
	};

	# Work around a Moose edge case.
	sub DEMOLISH {}

	# Turn off watcher during destruction.
	after DEMOLISH => sub {
		my $self = shift;
		$self->$method_stop();
	};
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role::Writable - add writable-watching behavior to a class

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	use Moose;

	has socket => ( is => 'rw', isa => 'FileHandle', required => 1 );

	with 'Reflex::Role::Writable' => {
		handle   => 'socket',
		cb_ready => 'on_socket_writable',
		active   => 1,
	};

	sub on_socket_writable {
		my ($self, $arg) = @_;
		print "Socket $arg->{handle} is ready for data.\n";
		$self->pause_socket_writabe();
	}

=head1 DESCRIPTION

Reflex::Role::Writable is a Moose parameterized role that adds
writable-watching behavior to Reflex-based classes.  In the SYNOPSIS,
a filehandle named "socket" is watched for writability.  The method
on_socket_writable() is called when data becomes available.

TODO - Explain the difference between role-based and object-based
composition.

=head2 Required Role Parameters

=head3 handle

The C<handle> parameter must contain the name of the attribute that
holds the handle to watch.  The name indirection allows the role to
generate methods that are unique to the handle.  For example, a handle
named "XYZ" would generates these methods by default:

	cb_ready      => "on_XYZ_writable",
	method_pause  => "pause_XYZ_writable",
	method_resume => "resume_XYZ_writable",
	method_stop   => "stop_XYZ_writable",

This naming convention allows the role to be used for more than one
handle in the same class.  Each handle will have its own name, and the
mixed in methods associated with them will also be unique.

=head2 Optional Role Parameters

=head3 active

C<active> specifies whether the Reflex::Role::Writable watcher should
be enabled when it's initialized.  All Reflex watchers are enabled by
default.  Set it to a false value, preferably 0, to initialize the
watcher in an inactive or paused mode.

Writability watchers may be paused and resumed.  See C<method_pause>
and C<method_resume> for ways to override the default method names.

=head3 cb_ready

C<cb_ready> names the $self method that will be called whenever
C<handle> has space for more data to be written.  By default, it's the
catenation of "on_", the C<handle> name, and "_writable".  A handle
named "XYZ" will by default trigger on_XYZ_writable() callbacks.

	handle => "socket",  # on_socket_writable()
	handle => "XYZ",     # on_XYZ_writable()

All Reflex parameterized role callbacks are invoked with two
parameters: $self and an anonymous hashref of named values specific to
the callback.  C<cb_ready> callbacks include a single named value,
C<handle>, that contains the filehandle from which has become ready
for writing.

C<handle> is the handle itself, not the handle attribute's name.

=head3 method_pause

C<method_pause> sets the name of the method that may be used to pause
the watcher.  It is "pause_${handle}_writable" by default.

=head3 method_resume

C<method_resume> may be used to resume paused writability watchers, or
to activate them if they are started in an inactive state.

=head3 method_stop

C<method_stop> may be used to stop readability watchers.  These
watchers may not be restarted once they've been stopped.  If you want
to pause and resume watching, see C<method_pause> and
C<method_resume>.

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

L<Reflex::Role::Readable>

=item *

L<Reflex::Role::Streaming>

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

