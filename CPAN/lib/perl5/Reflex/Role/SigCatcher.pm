package Reflex::Role::SigCatcher;
{
  $Reflex::Role::SigCatcher::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Reflex::Role;
use Reflex::Event::Signal;

use Scalar::Util qw(weaken);

attribute_parameter att_active    => "active";
attribute_parameter att_signal    => "signal";
callback_parameter  cb_signal     => qw( on att_signal caught );
method_parameter    method_pause  => qw( pause att_signal _ );
method_parameter    method_resume => qw( resume att_signal _ );
method_parameter    method_start  => qw( start att_signal _ );
method_parameter    method_stop   => qw( stop att_signal _ );

# A session may only watch a distinct signal once.
# So we must map each distinct signal to all the interested objects.
# This is class scoped data.
#
# TODO - We could put this closer to the POE::Session and obviate the
# need for the deliver() redirector.

my %callbacks;
my %signal_param_names;

sub deliver {
	my ($class, $signal_name) = @_;

	# If nobody's watching us, then why did we do it in the road?
	# TODO - Diagnostic warning/error?
	return unless exists $callbacks{$signal_name};

	# Deliver the signal.
	# TODO - map() magic to speed this up?

	foreach my $callback_recs (values %{$callbacks{$signal_name}}) {
		foreach my $callback_rec (values %$callback_recs) {
			my ($object, $method) = @$callback_rec;
			$object->$method(
				Reflex::Event::Signal->new(
					_emitters => [ $object ],
					signal    => $signal_name,
				)
			);
		}
	}
}

# The role itself.

role {
	my $p = shift;

	my $att_signal    = $p->att_signal();
	my $att_active    = $p->att_active();
	my $cb_signal     = $p->cb_signal();

	requires $att_signal, $att_active, $cb_signal;

	my $method_start  = $p->method_start();
	my $method_stop   = $p->method_stop();
	my $method_pause  = $p->method_pause();
	my $method_resume = $p->method_resume();

	# Work around a Moose edge case.
	sub BUILD {}

	after BUILD => sub {
		return unless $att_active;
		shift()->$method_start();
		return;
	};

	# Work around a Moose edge case.
	sub DEMOLISH {}

	after DEMOLISH => sub {
		shift()->$method_stop();
	};

	method $method_start => sub {
		my $self = shift;

		my $sig_name = $self->$att_signal();

		# Register this object with that signal.
		$callbacks{$sig_name}->{$self->session_id()}->{$self} = [
			$self, $cb_signal
		];
		weaken $callbacks{$sig_name}->{$self->session_id()}->{$self}->[0];

		# First time this object is watching that signal?  Start the
		# watcher.  Otherwise, a watcher should already be going.

		return if (
			(scalar keys %{$callbacks{$sig_name}->{$self->session_id()}}) > 1
		);

		$self->$method_resume();
	};

	method $method_pause => sub {
		my $self = shift;

		# Be in the session associated with this object.
		return unless $self->call_gate($method_pause);

		$POE::Kernel::poe_kernel->refcount_decrement(
			$self->session_id(),
			"signals_keep_alive"
		);

		$POE::Kernel::poe_kernel->sig($self->$att_signal(), undef);
	};

	method $method_resume => sub {
		my $self = shift;

		# Be in the session associated with this object.
		return unless $self->call_gate($method_resume);

		$POE::Kernel::poe_kernel->refcount_increment(
			$self->session_id(),
			"signals_keep_alive"
		);

		$POE::Kernel::poe_kernel->sig(
			$self->$att_signal(), "signal_happened", ref($self)
		);
	};

	method $method_stop => sub {
		my $self = shift;

		my $sig_name = $self->$att_signal();

		# Nothing to do?
		return unless exists $callbacks{$sig_name}->{$self->session_id()};

		# Unregister this object with that signal.
		my $sw = $callbacks{$sig_name}->{$self->session_id()};
		return unless delete $sw->{$self};

		# Deactivate the signal watcher if this was the last object.
		unless (scalar keys %$sw) {
			delete $callbacks{$sig_name}->{$self->session_id()};
			delete $callbacks{$sig_name} unless scalar keys %{$callbacks{$sig_name}};
			$self->$method_pause();
		}
	};
};



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role::SigCatcher - add signal catching behavior to a class

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	package Reflex::Signal;

	use Moose;
	extends 'Reflex::Base';

	has signal => (
		is        => 'ro',
		isa       => 'Str',
		required  => 1,
	);

	has active => (
		is      => 'ro',
		isa     => 'Bool',
		default => 1,
	);
TODO - Changed.
	with 'Reflex::Role::SigCatcher' => {
		signal        => 'signal',
		active        => 'active',
		cb_signal     => 'on_signal',
		method_start  => 'start',
		method_stop   => 'stop',
		method_pause  => 'pause',
		method_resume => 'resume',
	};

	1;

=head1 DESCRIPTION

Reflex::Role::SigCatcher is a Moose parameterized role that adds
signal-catching behavior to Reflex based classes.  The SYNOPSIS is the
entire implementation of Reflex::SigCatcher, a simple class that
allows Reflex::Role::SigCatcher to be used as an object.

Reflex::Role::SigCatcher is not suitable for SIGCHLD use.  The
specialized Reflex::Role::PidCatcher class is used for that, and it
will automatically wait() for processes and return their exit
statuses.

=head2 Required Role Parameters

None.  All role parameters as of this writing have what we hope are
sensible defaults.  Please let us know if they don't seem all that
sensible.

=head2 Optional Role Parameters

=head3 signal

C<signal> sets the name of an attribute that will contain the signal
name to catch.  Signal names are as those found in %SIG.

TODO - However, it may also be convenient to specify the signal name
in the role's parameters.  General use cases don't usually require
signals names to change.  The indirection through C<signal> is
currently useful for Reflex::Signal, however, so we probably need
both modes.  It might be better to provide two roles, one for each
behavior, rather than one role that does both.

=head3 active

C<active> specifies whether Reflex::Role::SigCatcher should be created
in the active, signal-watching state.  All Reflex watchers are enabled
by default.  Set it to a false value, preferably 0, to initialize the
catcher in an inactive or paused mode.

Signal watchers may be paused and resumed.  See C<method_pause> and
C<method_resume> for ways to override the default method names.

=head3 cb_signal

C<cb_signal> names the $self method that will be called whenever the
signal named in C<<$self->$signal()>> is caught.  It defaults to
"on_%s_caught", where %s is the name of the signal.  So if the INT
signal is being watched, C<cb_signal> will default to "on_INT_caught".

=head3 method_start

C<method_start> sets the name of the method that may be used to
initially start catching signals.  It's "start_%s" by default, where
%s is the signal name being caught.

Reflex::Role::SigCatcher will automatically start watching for signals
if the value of C<active>'s attribute is true.

=head3 method_stop

C<method_stop> may be used to permanently stop signal catchers.
Stopped catchers cannot be restarted, so use C<method_pause> if you
need to temporarily disable signal watchers.  C<method_resume> may be
used to resume them again.

Signal catchers will automatically stop watching for signals upon
DEMOLISH.

=head3 method_pause

C<method_pause> sets the name of the method that may be used to pause
signal catching.  It is "pause_%s" by default, where %s is the signal
name being caught.

=head3 method_resume

C<method_resume> sets the name of the method that may be used to
resume signal catching.  It is "resume_%s" by default, where %s is the
signal name being caught.

=head1 EXAMPLES

eg/eg-39-signals.pl shows how Reflex::Signal may be used with
callbacks or promises.

L<Reflex::Signal> is a simple class that watches for signals with
Reflex::Role::SigCatcher.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Signal>

=item *

L<Reflex::Role::PidCatcher>

=item *

L<Reflex::PID>

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

