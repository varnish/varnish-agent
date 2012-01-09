package Reflex;
{
  $Reflex::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use warnings;
use strict;

use Carp qw(croak);

sub import {
	my $class = shift;
	return unless @_;

	my $caller_package = caller();

	# Use the packages in the caller's package.
	# TODO - Is there a way to place the use in the caller's package
	# without the eval?

	eval join(
		"; ",
		"package $caller_package",
		map { "use $class\::$_" }
		@_
	);

	# Rewrite the error so that it comes from the caller.
	if ($@) {
		my $msg = $@;
		$msg =~ s/(\(\@INC contains.*?\)) at .*/$1/s;
		croak $msg;
	}
}

sub run_all {
	Reflex::Base->run_all();
}

1;



=pod

=for :stopwords Rocco Caputo cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders

=encoding UTF-8

=head1 NAME

Reflex - Class library for flexible, reactive programs.

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

The distribution includes a few different versions of this synopsis.
See eg/eg-18-synopsis-no-moose.pl if you don't like Moose.
See eg/eg-32-promise-tiny.pl if you prefer promises (condvar-like).
See eg/eg-36-coderefs-tiny.pl if you prefer coderefs and/or closures.

	{
		package App;
		use Moose;
		extends 'Reflex::Base';
		use Reflex::Interval;
		use Reflex::Trait::Watched qw(watches);

		watches ticker => (
			isa   => 'Reflex::Interval',
			setup => { interval => 1, auto_repeat => 1 },
		);

		sub on_ticker_tick {
			print "tick at ", scalar(localtime), "...\n";
		}
	}

	exit App->new()->run_all();

=head1 DESCRIPTION

Reflex is a class library that assists with writing reactive (AKA
event-driven) programs.  Reflex uses Moose internally, but it doesn't
enforce programs to use Moose's syntax.

Those who enjoy Moose should find useful Reflex's comprehensive suite
of reactive roles.

Reflex is considered "reactive" because it's an implementation of the
reactor pattern.  http://en.wikipedia.org/wiki/Reactor_pattern

=head2 About Reactive Objects

Reactive objects provide responses to interesting (to them) stimuli.
For example, an object might be waiting for input from a client, a
signal from an administrator, a particular time of day, and so on.
The App object in the SYNOPSIS is waiting for timer tick events.  It
generates console messages in response to those events.

=head2 Example Reactive Objects

Here an Echoer class emits "pong" events in response to ping()
commands.  It uses Moose's extends(), but it could about as easily use
warnings, strict, and base instead.  Reflex::Base gets its emit()
method from Reflex::Role::Reactive.

	package Echoer;
	use Moose;
	extends 'Reflex::Base';

	sub ping {
		my ($self, $args) = @_;
		print "Echoer was pinged!\n";
		$self->emit( -name => "pong" );
	}

The next object uses Echoer.  It creates an Echoer and pings it to get
started.  It also reacts to "pong" events by pinging the Echoer again.
Reflex::Trait::Watched (via its exported watches() declarative syntax)
implicitly watches the object in echoer(), mapping its "pong" event to
the on_echoer_pong() method.

	package Pinger;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Trait::Watched qw(watches);

	watches echoer => (
		isa     => 'Echoer',
		default => sub { Echoer->new() },
	);

	sub BUILD {
		my $self = shift;
		$self->echoer->ping();
	}

	sub on_echoer_pong {
		my $self = shift;
		print "Pinger got echoer's pong!\n";
		$self->echoer->ping();
	}

Then the Pinger would be created and run.

	Pinger->new()->run_all();

A complete, runnable version of this example is in the distribution as
eg/eg-37-ping-pong.pl.

=head2 Coderef Callbacks

Reflex supports any conceivable callback type, even the simple ones:
plain old coderefs.  You don't need to write objects to handle events.

Here we'll start a periodic timer and handle its ticks with a simple
callback.  The program is still reactive.  Every second it prints
"timer ticked" in response Reflex::Interval's events.

	my $t = Reflex::Interval->new(
		interval    => 1,
		auto_repeat => 1,
		on_tick     => sub { say "timer ticked" },
	);

	$t->run_all();

A complete, runnable version of the above example is available as
eg/eg-36-tiny-coderefs.pl in the distribution.

=head2 Promises Instead of Callbacks

Callback haters are not left out.  Reflex objects may also be used as
asynchronous event generators.  The following example is identical in
function to the previous coderef callback example, but it doesn't use
callbacks at all.

It may not be obvious that the same emit() method drives all of
Reflex's forms of callback.  The same Reflex::Interval class can be
used in many different ways.

	use Reflex::Interval;

	my $t = Reflex::Interval->new(
		interval    => 1,
		auto_repeat => 1,
	);

	while (my $event = $t->next()) {
		say "next() returned an event (@$event)";
	}

=head1 PUBLIC METHODS

Reflex itself contains some convenience methods for cleaner semantics.

=head2 run_all

Run all active Reflex objects until they destruct.

	# (Omitted: First you'll need to create some Reflex objects.)

	Reflex->run_all();
	exit;

=head1 BUNDLED MODULES AND DOCUMENTATION INDEX

Reflex bundles a number of helpful base classes to get things started.

=head2 Core Modules

The basic modules upon which most everything else is built.

=head3 Reflex - You're reading it!

=head3 Reflex::Base - A base class for reactive (aka, event driven) objects.

=head3 Reflex::Role - Define a new Reflex parameterized role.

=head3 Reflex::Role::Reactive - Add non-blocking reactive behavior to a class.

=head2 Callback Adapters

Reflex provides adapters for nearly every kind of callback that
exists, including condvar-like promises that allow Reflex objects to
be used inline without callbacks at all.

=head3 Reflex::Callback - A base class for callback adapters.

=head3 Reflex::Callback::CodeRef - Implement plain coderef callbacks.

=head3 Reflex::Callback::Method - Implement class and object method callbacks.

=head3 Reflex::Callback::Promise - Return events procedurally rather than via callbacks.

=head3 Reflex::Callbacks - Convenience functions to creating and use callbacks.

=head2 POE Adapters

POE provides over 400 modules for various useful things.  Reflex can
work with them using these adapters.

=head3 Reflex::POE::Event - Communicate with POE components that expect command events.

=head3 Reflex::POE::Postback - Communicate with POE components that respond via postbacks.

=head3 Reflex::POE::Session - Communicate with POE components that expect to talk to POE sessions.

=head3 Reflex::POE::Wheel - A generic POE::Wheel adapter to use them in Reflex.

=head3 Reflex::POE::Wheel::Run - Adapt POE::Wheel::Run by wrapping it in a Reflex class.

=head2 Object Collections

It's often useful to manage collections of like-typed modules, such as
connections or jobs.

=head3 Reflex::Collection - Automatically manage a collection of collectible objects.

=head3 Reflex::Role::Collectible - Allow objects to be managed by Reflex::Collection.

=head3 Reflex::Sender - API to access the objects an event has passed through.

=head2 I/O

Event driven programs most often react to I/O of some sort.  These
modules provide reactive I/O support.

=head3 Reflex::Acceptor - A non-blocking server (client socket acceptor).

=head3 Reflex::Client - A non-blocking socket client.

=head3 Reflex::Connector - A non-blocking client socket connector.

=head3 Reflex::Role::Accepting - Add non-blocking connection accepting to a role.

=head3 Reflex::Role::Connecting - Add non-blocking client connecting to a class.

=head3 Reflex::Role::InStreaming - Add non-blocking streaming input behavior to a class.

=head3 Reflex::Role::OutStreaming - Add non-blocking streaming output behavior to a class.

=head3 Reflex::Role::Readable - Add non-blocking readable-watching behavior to a class.

=head3 Reflex::Role::Reading - Add standard non-blocking sysread() behavior to a class.

=head3 Reflex::Role::Recving - Add standard non-blocking send/recv behavior to a class.

=head3 Reflex::Role::Streaming - Add non-blocking streaming I/O behavior to a class.

=head3 Reflex::Role::Writable - Add non-blocking writable-watching behavior to a class.

=head3 Reflex::Role::Writing - Add standard non-blocking syswrite() behavior to a class.

=head3 Reflex::Stream - A non-blocking, buffered and translated I/O stream.

=head3 Reflex::UdpPeer - A base class for non-blocking UDP networking peers.

=head2 Signals and Child Processes

Modules that provide signal support, including SIGCHLD for child
process management.

=head3 Reflex::PID - A non-blocking SIGCHLD watcher for a specific process.

=head3 Reflex::Role::PidCatcher - Add non-blocking SIGCHLD watching to a class.

=head3 Reflex::Role::SigCatcher - Add non-blocking signal handling behavior to a class.

=head3 Reflex::Signal - A non-blocking signal watcher.

=head2 Timers

Timer management has been relatively overlooked so far.  We'll get to
it eventually, and you're welcome to help.

=head3 Reflex::Interval - A non-blocking periodic interval timer.

=head3 Reflex::Role::Interval - Add non-blocking periodic callbacks to a class.

=head3 Reflex::Role::Timeout - Add non-blocking timeout timer behavior to a class.

=head3 Reflex::Role::Wakeup - Add non-blocking wakeup alarm behavior to a class.

=head3 Reflex::Timeout - A non-blocking single-shot delayed timer.

=head3 Reflex::Wakeup - A non-blocking single-shot alarm for a specific time.

=head2 Breadboarding Traits

Reflex also implements signal/slot style object interaction, through
emit() and watch() methods.  These traits were inspired by Smalltalk's
watchable object attributes.

=head3 Reflex::Trait::EmitsOnChange - Cause a Moose attribute to emit() an event when it changes.

=head3 Reflex::Trait::Observed - (Deprecated. See Reflex::Trait::Watched.)

=head3 Reflex::Trait::Watched - Automatically watch a Reactive object stored in a Moose attribute.

=head1 ASSISTANCE

Thank you for volunteering to assist with this project.  You can find
like-minded people in a few places, in descending order of preference.
Or, oh, wait, maybe you wanted assistance using it?  We'll help you,
too. :)

See irc.perl.org #reflex for help with Reflex.

See irc.perl.org #poe for help with POE and Reflex.

See irc.perl.org #moose for help with Moose.

Support is officially available from POE's mailing list as well.  Send
a blank message to
L<poe-subscribe@perl.org|mailto:poe-subscribe@perl.org>
to join.

The Reflex package also has helpful examples which may serve as a
tutorial until Reflex is documented more.

=head1 BUGS

We appreciate your feedback, bug reports, feature requests, patches
and kudos.  You may enter them into our request tracker by following
the instructions at
L<https://rt.cpan.org/Dist/Display.html?&Queue=Reflex>.

We also accept e-mail at
L<bug-Reflex@rt.cpan.org|mailto:bug-Reflex@rt.cpan.org>.

=head1 AUTHORS

Rocco Caputo, RCAPUTO on CPAN.

=head2 CONTRIBUTORS

Reflex is open source, and we welcome involvement.

Chris Fedde, CFEDDE on CPAN

=over 2

=item * L<https://github.com/rcaputo/reflex>

=item * L<http://gitorious.org/reflex>

=back

=head1 TODO

Please browse the source for the TODO marker.  Some are visible in the
documentation, and others are sprinlked around in the code's comments.

Also see L<docs/TODO.otl> in the distribution.
This is a Vim Outliner file with the current roadmap and progress.

Set up Dist::Zilla to reduce technical debt and make releasing code
fun again.

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2011 by Rocco Caputo.

Reflex is free software.  You may redistribute and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<L<Moose>, L<POE>, the Reflex and Reflexive namespaces on CPAN.|L<Moose>, L<POE>, the Reflex and Reflexive namespaces on CPAN.>

=item *

L<Ohlo - https://www.ohloh.net/p/reflex-perl|Ohlo - https://www.ohloh.net/p/reflex-perl>

=item *

L<CIA - http://cia.vc/stats/project/reflex|CIA - http://cia.vc/stats/project/reflex>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Reflex

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Reflex>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Reflex>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annonations of Perl module documentation.

L<http://annocpan.org/dist/Reflex>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Reflex>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Reflex>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Reflex>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/R/Reflex>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

L<http://matrix.cpantesters.org/?dist=Reflex>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Reflex>

=back

=head2 Email

You can email the author of this module at C<poe-subscribe@perl.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #reflex to get help.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-reflex at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Reflex>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<http://github.com/rcaputo/reflex>

  git clone git://github.com/rcaputo/reflex.git

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Rocco Caputo <rcaputo@cpan.org>

=head1 ACKNOWLEDGEMENTS

irc.perl.org channel
L<#moose|irc://irc.perl.org/moose>
and
L<#poe|irc://irc.perl.org/poe>.
The former for assisting in learning their fine libraries, sometimes
against everyone's better judgement.  The latter for putting up with
lengthy and sometimes irrelevant design discussion for oh so long.

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

