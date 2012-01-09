package Reflex::Timeout;
{
  $Reflex::Timeout::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);

has delay       => ( isa => 'Num', is  => 'ro' );
has auto_start  => ( isa => 'Bool', is => 'ro', default => 1 );

with 'Reflex::Role::Timeout' => {
	att_auto_start => "auto_start",
	att_delay      => "delay",
	cb_timeout     => make_emitter(on_done => "done"),
	method_reset   => "reset",
	method_start   => "start",
	method_stop    => "stop",
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Timeout - A stand-alone single-shot delayed callback

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	#!/usr/bin/env perl

	use warnings;
	use strict;

	use Reflex::Timeout;

	my $to = Reflex::Timeout->new(
		delay   => 1,
		on_done => \&handle_timeout,
	);

	Reflex->run_all();
	exit;

	sub handle_timeout {
		print "got timeout\n";
		$to->reset();
	}

=head1 DESCRIPTION

Reflex::Timeout invokes a callback after a specified amount of time
has elapsed.  Timeouts may be stopped, restarted, or reset so they
must again wait the full delay period.  Resetting is especially
useful, for example whenever input arrives.

=head2 Public Attributes

=head3 delay

Implemented and documented by L<Reflex::Role::Timeout/delay>.

=head2 Public Callbacks

=head3 on_done

Implemented and documented by L<Reflex::Role::Timeout/cb_timeout>.

=head2 Public Methods

=head3 reset

Implemented and documented by L<Reflex::Role::Timeout/method_reset>.

=head3 start

Implemented and documented by L<Reflex::Role::Timeout/method_start>.

=head3 stop

Implemented and documented by L<Reflex::Role::Timeout/method_stop>.

=head1 EXAMPLES

TODO - Link to them.

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

L<Reflex::Interval>

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

