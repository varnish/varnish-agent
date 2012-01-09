package Reflex::Role::Timeout;
{
  $Reflex::Role::Timeout::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Event::Timeout;

use Scalar::Util qw(weaken);

attribute_parameter att_auto_start => "auto_start";
attribute_parameter att_delay      => "delay";
callback_parameter  cb_timeout     => qw( on att_delay done );
method_parameter    method_reset   => qw( reset att_delay _ );
method_parameter    method_start   => qw( start att_delay _ );
method_parameter    method_stop    => qw( stop att_delay _ );

role {
	my $p = shift;

	my $att_delay      = $p->att_delay();
	my $att_auto_start = $p->att_auto_start();
	my $cb_timeout     = $p->cb_timeout();

	requires $att_delay, $cb_timeout;

	has $att_auto_start  => ( is => 'ro', isa => 'Bool', default => 1 );

	my $method_reset  = $p->method_reset();
	my $method_start  = $p->method_start();
	my $method_stop   = $p->method_stop();

	my $timer_id_name = "${att_delay}_timer_id";

	has $timer_id_name => (
		isa => 'Maybe[Str]',
		is  => 'rw',
	);

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		my ($self, $args) = @_;
		$self->$method_start() if $self->$att_auto_start();
	};

	my $code_start = sub {
		my ($self, $args) = @_;

		# Switch to the proper session.
		return unless $self->call_gate($method_start);

		# If the args include "delay", then let's reset att_delay().
		$self->$att_delay( $args->{delay} ) if exists $args->{delay};

		# Stop a previous alarm.
		$self->$method_stop() if defined $self->$timer_id_name();

		# Put a weak $self in an envelope that can be passed around
		# without strenghtening the object.

		my $envelope = [ $self, $cb_timeout, 'Reflex::Event::Timeout' ];
		weaken $envelope->[0];

		$self->$timer_id_name(
			$POE::Kernel::poe_kernel->delay_set(
				'timer_due',
				$self->$att_delay(),
				$envelope,
			)
		);
	};

	method $method_start => $code_start;
	method $method_reset => $code_start;

	after DEMOLISH => sub {
		my ($self, $args) = @_;
		$self->$method_stop();
	};

	method $method_stop => sub {
		my ($self, $args) = @_;

		# Return if it was a false "alarm" (pun intended).
		return unless (
			defined $self->$timer_id_name() and $self->call_gate($method_stop)
		);

		$POE::Kernel::poe_kernel->alarm_remove($self->$timer_id_name());
		$self->$timer_id_name(undef);
	};
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role::Timeout - set a wakeup callback for a relative delay

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	package Reflex::Timeout;

	use Moose;
	extends 'Reflex::Base';

	has delay       => ( isa => 'Num', is  => 'ro' );
	has auto_start  => ( isa => 'Bool', is => 'ro', default => 1 );

	with 'Reflex::Role::Timeout' => {
		delay          => "delay",
		cb_timeout     => "on_done",
		att_auto_start => "auto_start",
		method_start   => "start",
		method_stop    => "stop",
		method_reset   => "reset",
	};

	1;

=head1 DESCRIPTION

Reflex::Role::Timeout is a parameterized role.  Each time it's
consumed, it adds another non-blocking relative delay callback to a
class.  These callback will be invoked after a particular number of
seconds have elapsed.  The delay is contained in an attribute named by
the role's C<delay> parameter.

Reflex::Timeout in the SYNOPSIS consumes a single
Reflex::Role::Timeout.  The parameters define the names of attributes
that control the timer's behavior, the names of callback methods, and
the names of methods that manipulate the timer.

=head2 Required Role Parameters

None.  All role parameters have defaults.

=head2 Optional Role Parameters

=head3 delay

C<delay> names an attribute in the consumer that must hold the role's
inactivity time, in seconds.  The role will trigger a callback after
that amount of time has elapsed, unless the timeout is stopped or
reset before then.

Reflex usually supports fractional seconds, but this ultimately
depends on the event loop being used.

Refex::Role::Timeout uses the attribute name in C<delay> to
differentiate between multiple applications of the same role to the
same class.  Reflex roles are building blocks of program behavior, and
it's reasonable to expect a class to need multiple building blocks of
the same type.  For instance, a login prompt may have a short timeout
to wait for input and a longer timeout to wait for authentication.

=head3 auto_start

Timeouts will automatically start if the value of the attribute
named in C<auto_start> is true.  Otherwise, the class consuming this
role must call the role's start method, named in C<method_start>.

=head3 method_stop

Reflex::Role::Timeout will provide a method to stop the timer.  This
method will become part of the consuming class, per Moose.
C<method_stop> allows the consumer to define the name of that method.
By default, the method will be named:

	$method_stop = "stop_" . $delay_name;

where $delay_name is the attribute name supplied by the C<delay>
parameter.

The stop method neither takes parameters nor returns anything.

=head3 method_reset

C<method_reset> allows the role's consumer to override the default
reset method name.  The default is C<"reset_${timeout_name}">, where
$timeout_name is the attribute name provided in the C<timeout>
parameter.

All Reflex methods accept a hashref of named parameters.  Currently
the reset method accepts one named parameter, "delay".  The value of
"delay" must be the new timeout to trigger a callback.  If "delay"
isn't provided, the timeout callback will happen at the previous time
set by this module.

	$self->reset_name( { delay => 60 } );

One may also set the delay attribute and reset the timer as two
distinct calls.

	$self->delay( 60 );  # 60 seconds from now
	$self->reset_name();

=head3 method_start

This role provides a method to start timeouts, otherwise timeouts
would never run if C<auto_start> were false.  The C<method_start> can
be used to override the default start method name, which is
"start_${delay_name}".  $delay_name is the name of the attribute
provided in the C<delay> role parameter.

=head3 cb_timeout

C<cb_timeout> overrides the default method name that will be called
when the "when" time arrives.  The default is "on_${when_name}_done".

These callbacks receive no paramaters.

=head1 EXAMPLES

L<Reflex::Timeout> is one example of using Reflex::Role::Timeout.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Timeout>

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

