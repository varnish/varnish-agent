package Reflex::Interval;
{
  $Reflex::Interval::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);

has interval    => ( isa => 'Num', is  => 'rw' );
has auto_repeat => ( isa => 'Bool', is => 'rw', default => 1 );
has auto_start  => ( isa => 'Bool', is => 'ro', default => 1 );

with 'Reflex::Role::Interval' => {
	att_auto_repeat => "auto_repeat",
	att_auto_start  => "auto_start",
	att_interval    => "interval",
	cb_tick         => make_emitter(on_tick => "tick"),
	method_repeat   => "repeat",
	method_start    => "start",
	method_stop     => "stop",
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Interval - A stand-alone multi-shot periodic callback

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

As with all Reflex objects, Reflex::Interval may be used in many
different ways.

Inherit it and override its on_tick() callback, with or without using
Moose.

	package App;
	use Reflex::Interval;
	use base qw(Reflex::Interval);

	sub on_tick {
		print "tick at ", scalar(localtime), "...\n";
		shift()->repeat();
	}

Run it as a promise that generates periodic events.  All other Reflex
objects will also be running while C<<$pt->next()>> is blocked.

	my $pt = Reflex::Interval->new(
		interval    => 1 + rand(),
		auto_repeat => 1,
	);

	while (my $event = $pt->next()) {
		eg_say("promise timer returned an event ($event->{name})");
	}

Plain old callbacks:

	my $ct = Reflex::Interval->new(
		interval    => 1,
		auto_repeat => 1,
		on_tick     => sub { print "coderef callback triggered\n" },
	);
	Reflex->run_all();

And so on.  See Reflex, Reflex::Base and Reflex::Role::Reactive for
details.

=head1 DESCRIPTION

Reflex::Interval invokes a callback after a specified interval of time
has passed, and then after every subsequent interval of time.
Interval timers may be stopped and started.  Their timers may be
automatically or manually repeated.

=head2 Public Attributes

=head3 interval

Implemented and documented by L<Reflex::Role::Interval/interval>.

=head3 auto_repeat

Implemented and documented by L<Reflex::Role::Interval/auto_repeat>.

=head3 auto_start

Implemented and documented by L<Reflex::Role::Interval/auto_start>.

=head2 Public Callbacks

=head3 on_tick

Implemented and documented by L<Reflex::Role::Interval/cb_tick>.

=head2 Public Methods

=head3 repeat

Implemented and documented by L<Reflex::Role::Interval/method_repeat>.

=head3 start

Implemented and documented by L<Reflex::Role::Interval/method_start>.

=head3 stop

Implemented and documented by L<Reflex::Role::Interval/method_stop>.

=head1 EXAMPLES

TODO - Many.  Link to them.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Role>

=item *

L<Reflex::Role::Interval>

=item *

L<Reflex::Role::Timeout>

=item *

L<Reflex::Role::Wakeup>

=item *

L<Reflex::Timeout>

=item *

L<Reflex::Wakeup>

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

