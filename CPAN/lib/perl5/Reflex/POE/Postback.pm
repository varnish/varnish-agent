package Reflex::POE::Postback;
{
  $Reflex::POE::Postback::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

# TODO - Not Moose, unless Moose allows us to create blessed coderefs.

use warnings;
use strict;
use Scalar::Util qw(weaken);
use Reflex::Event::Postback;

my %owner_session_ids;

sub new {
	my ($class, $object, $method, $context) = @_;

	# TODO - Object owns component, which owns object?
	weaken $object;

	my $self = bless sub {
		$POE::Kernel::poe_kernel->post(
			$object->session_id(), "call_gate_method", $object, $method,
			Reflex::Event::Postback->new(
				_emitters => [ $object ],
				-name     => 'postback',
				context   => $context,
				response  => [ @_ ],
			)
		);
	}, $class;

	$owner_session_ids{$self} = $object->session_id();
	$POE::Kernel::poe_kernel->refcount_increment(
		$object->session_id(), "reflex_postback"
	);

	# Double indirection sucks, but some libraries (like Tk) bless their
	# callbacks.  If we returned our own blessed callback, they would
	# alter the class and thwart DESTROY.
	#
	# TODO - POE::Session only does this when Tk is loaded.  I opted
	# against it here because the set of libraries that bless their
	# callbacks may grow over time.

	return sub { $self->(@_) };
}

sub DESTROY {
	my $self = shift;

	my $session_id = delete $owner_session_ids{$self};
	return unless defined $session_id;
	$POE::Kernel::poe_kernel->refcount_decrement(
		$session_id, "reflex_postback"
	);

	undef;
}

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::POE::Postback - Communicate with POE components expecting postbacks.

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

Not a complete example.  Please see eg-11-poco-postback.pl in the eg
directory for a complete working program.

	my $postback = Reflex::POE::Postback->new(
		$self, "on_component_result", { cookie => 123 }
	);

=head1 DESCRIPTION

Reflex::POE::Postback creates an object that's substitutes for
POE::Session postbacks.  When invoked, however, they sent events back
to the object and method (and with optional continuation data)
provided during construction.

Reflex::POE::Postback was designed to interact with POE modules that
want to respond via caller-provided postbacks.  Authors are encouraged
to encapsulate POE interaction within Reflex objects.  Most users
should therefore not need use Reflex::POE::Postback (or other
Reflex::POE helpers) directly.

=head2 Public Methods

=head3 new

new() constructs a new Reflex::POE::Postback object, which will be a
blessed coderef following POE's postback convention.

It takes three positional parameters: the required object and method
to invoke when the postback is called, and an optional context that
will be passed verbatim to the callback.

=head2 Callback Parameters

=head3 context

The "context" callback parameter contains whatever was supplied to the
Reflex::POE::Postback when it was created.  In the case of the
SYNOPSIS, that would be:

	sub on_component_result {
		my ($self, $event) = @_;

		# Displays: 123
		print $event->context()->{cookie}, "\n";
	}

=head3 response

"response" contains an array reference that holds whatever was passed
to the postback.  If we assume this postback call:

	$postback->(qw(eight six seven five three oh nine));

Then the callback might look something like this:

	sub on_component_result {
		my ($self, $event) = @_;

		# Displays: nine
		print $event->response()->[-1], "\n";
	}

=head1 CAVEATS

Reflex::POE::Postback must produce objects as blessed coderefs.  This
is something I don't know how to do yet with Moose, so Moose isn't
used.  Therefore, Reflex::POE::Postback doesn't do a lot of things one
might expect after working with other Reflex objects.

If Moose can be used later, it may fundamentally change the entire
interface.  The goal is to do this only once, however.

It might be nice to map positional response parameters to named
parameters.  Reflex::POE::Wheel does this, but it remains to be seen
whether that's considered cumbersome.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Moose::Manual::Concepts>

=item *

L<Reflex>

=item *

L<Reflex::POE::Event>

=item *

L<Reflex::POE::Session>

=item *

L<Reflex::POE::Wheel::Run>

=item *

L<Reflex::POE::Wheel>

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

