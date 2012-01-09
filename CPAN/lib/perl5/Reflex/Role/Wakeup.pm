package Reflex::Role::Wakeup;
{
  $Reflex::Role::Wakeup::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Event::Wakeup;

use Scalar::Util qw(weaken);

attribute_parameter att_when      => "when";
callback_parameter  cb_wakeup     => qw( on att_when wakeup );
method_parameter    method_reset  => qw( reset att_when _ );
method_parameter    method_stop   => qw( stop att_when _ );

role {
	my $p = shift;

	my $att_when      = $p->att_when();
	my $cb_wakeup     = $p->cb_wakeup();

	requires $att_when, $cb_wakeup;

	my $method_reset  = $p->method_reset();
	my $method_stop   = $p->method_stop();

	my $timer_id_name = "${att_when}_timer_id";

	has $timer_id_name => (
		isa => 'Maybe[Str]',
		is  => 'rw',
	);

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $args) = @_;
		$self->$method_reset( { when => $self->$att_when() } );
	};

	method $method_reset => sub {
		my ($self, $args) = @_;

		# Switch to the proper session.
		return unless (
			defined $self->$att_when() and $self->call_gate($method_reset)
		);

		# If the args include "when", then let's reset when().
		$self->$att_when( $args->{when} ) if exists $args->{when};

		# Stop a previous alarm.
		$self->$method_stop() if defined $self->$timer_id_name();

		# Put a weak $self in an envelope that can be passed around
		# without strenghtening the object.

		my $envelope = [ $self, $cb_wakeup, 'Reflex::Event::Wakeup' ];
		weaken $envelope->[0];

		$self->$timer_id_name(
			$POE::Kernel::poe_kernel->alarm_set(
				'timer_due',
				$self->$att_when(),
				$envelope,
			)
		);
	};

	after DEMOLISH => sub {
		my ($self, $args) = @_;
		$self->$method_stop();
	};

	method $method_stop => sub {
		my ($self, $args) = @_;

		# Return if it was a false "alarm" (pun intended).
		return unless defined $self->$timer_id_name() and $self->call_gate("stop");

		$POE::Kernel::poe_kernel->alarm_remove($self->$timer_id_name());
		$self->$timer_id_name(undef);
	};

	after $cb_wakeup => sub {
		shift()->$method_stop();
	};
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role::Wakeup - set a wakeup callback for a particular UNIX time

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	package Reflex::Wakeup;

	use Moose;
	extends 'Reflex::Base';

	has when => ( isa => 'Num', is  => 'rw' );

	with 'Reflex::Role::Wakeup' => {
		when          => "when",
		cb_wakeup     => "on_time",
		method_stop   => "stop",
		method_reset  => "reset",
	};

	1;

=head1 DESCRIPTION

Reflex::Role::Wakeup is a parameterized role.  Each time it's
consumed, it adds another non-blocking wakeup callback to a class.
These callback will be invoked at particular UNIX times, established
by the contents of the "when" attributes named at composition time.

Reflex::Wakeup in the SYNOPSIS consumes a single Reflex::Role::Wakeup.
The parameters define the names of attributes that control the timer's
behavior, the names of callback methods, and the names of methods that
manipulate the timer.

=head2 Required Role Parameters

None.  All role parameters have defaults.

=head2 Optional Role Parameters

=head3 when

C<when> names an attribute in the consumer that must hold the role's
wakeup time.  Wakeup times are specified as seconds since the UNIX
epoch.  Reflex usually supports fractional seconds, but this
ultimately depends on the event loop being used.

Refex::Role::Wakeup uses the attribute name in C<when> to
differentiate between multiple applications of the same role to the
same class.  Reflex roles are building blocks of program behavior, and
it's reasonable to expect a class to need multiple building blocks of
the same type.  For instance, multiple wakeup timers for different
purposes.

=head3 method_stop

Reflex::Role::Wakeup will provide a method to stop the timer.  This
method will become part of the consuming class, per Moose.
C<method_stop> allows the consumer to define the name of that method.
By default, the method will be named:

	$method_stop = "stop_" . $when_name;

where $when_name is the attribute name supplied by the C<when>
parameter.

The stop method neither takes parameters nor returns anything.

=head3 method_reset

C<method_reset> allows the role's consumer to override the default
reset method name.  The default is C<"stop_${when_name}">, where
$when_name is the attribute name provided in the C<when> parameter.

All Reflex methods accept a hashref of named parameters.  Currently
the reset method accepts one named parameter, "when".  The value of
"when" must be the new time to trigger a callback.  If "when" isn't
provided, the wakeup callback will happen at the previous time set by
this module.

	$self->reset_name( { when => time() + 60 } );

One may also set the when() attribute and reset() the timer as two
distinct calls.

	$self->time( time() + 60 );  # 60 seconds from now
	$self->reset_time();

=head3 cb_wakeup

C<cb_wakeup> overrides the default method name that will be called
when the "when" time arrives.  The default is
"on_${when_name}_wakeup".

These callbacks receive no paramaters.

=head1 EXAMPLES

L<Reflex::Wakeup> is one example of using Reflex::Role::Wakeup.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Wakeup>

=item *

L<Reflex::Role>

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

