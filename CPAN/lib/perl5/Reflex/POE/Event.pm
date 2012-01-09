package Reflex::POE::Event;
{
  $Reflex::POE::Event::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
use Carp qw(croak);

has object => (
	is        => 'ro',
	isa       => 'Reflex::Base',
	required  => 1,
);

has method => (
	is        => 'rw',
	isa       => 'Str',
	required  => 1,
);

has context => (
	is      => 'rw',
	isa     => 'HashRef',
	default => sub { {} },
);

sub BUILD {
	my $self = shift;

	if (
		$POE::Kernel::poe_kernel->get_active_session()->ID()
		ne
		$self->object()->session_id()
	) {
		croak(
			"When interfacing with POE at large, ", __PACKAGE__, " must\n",
			"be created within a Reflex::Base's session.  Perhaps invoke it\n",
			"within the object's run_within_session() method",
		);
	}
}

sub deliver {
	my ($self, $event) = @_;

	$POE::Kernel::poe_kernel->post(
		$self->object()->session_id(), "call_gate_method",
		$self->object(), $self->method(), {
			context   => $self->context(),
			response  => $event,
		}
	);
}

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::POE::Event - Communicate with POE components expecting events.

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

This BUILD method is from eg-12-poco-event.pl in Reflex's eg
directory.  It's for an App (application) class that must request
service from a POE component by posting an event.

	sub BUILD {
		my $self = shift;
		$self->component( PoCoEvent->new() );

		# Make sure it runs within the object's POE::Session.
		$self->run_within_session(
			sub {
				$self->component->request(
					Reflex::POE::Event->new(
						object  => $self,
						method  => "on_component_result",
						context => { cookie => 123 },
					),
				);
			}
		);
	}

App's constructor runs within its creator's session, which may not be
the correct one to be sending the event.  run_within_session()
guarantees that Reflex::POE::Event is sent from the App, so that
responses will reach the App later.

An optional context (or continuation) may be stored with the event.
It will be returned to the callback as its "context" parameter.

=head1 DESCRIPTION

Reflex::POE::Event is a helper object for interacting with POE modules
that expect event names for callbacks.  It creates an object that may
be used as a POE event name.  Reflex routes these events to their
proper callbacks when POE sends them back.

Authors are encouraged to encapsulate POE interaction within Reflex
objects.  Most users should not need use Reflex::POE::Event (or other
Reflex::POE helpers) directly.

=head2 Public Attributes

=head3 object

"object" contains a reference to the object that will handle this
POE event.

=head3 method

"method" contains the name of the method that will handle this event.

=head3 context

Context optionally contains a hash reference of named values.  This
hash reference will be passed to the event's "context" callback
parameter.

=head2 Callback Parameters

Reflex::POE::Event provides some callback parameters for your
convenience.

=head3 context

The "context" parameter includes whatever was supplied to the event's
constructor.  Consider this event and its callback:

	my $event = Reflex::POE::Event->new(
		object => $self,
		method => "callback",
		context => { abc => 123 },
	);

	sub callback {
		my ($self, $event) = @_;
		print(
			"Our context: ", $event->context()->{abc}, "\n",
			"POE args: @{$event->response()}\n"
		);
	}

=head3 response

POE events often include additional positional parameters in POE's
C<ARG0..$#_> offsets.  These are provided as an array reference in the
callback's "response" parameter.  An example is shown in the
documentation for the "context" callback parameter.

=head1 CAVEATS

Reflex::POE::Event objects must pass through POE unscathed.  POE's
basic Kernel and Session do this, but rare third-party modules may
stringify or otherwise modify event names.  If you encounter one,
please let the author know.

Reflex::POE::Event's implementation may change.  For example, it may
generate strings at a later date, if such strings can fulfill all the
needs of the current object-based implementation.

Reflex::POE::Event's interface may change significantly now that we
have Reflex::Callbacks.  The main change would be to support generic
callbacks rather than hardcode for method dispatch.

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

L<Reflex::POE::Postback>

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

