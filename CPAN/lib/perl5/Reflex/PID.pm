package Reflex::PID;
{
  $Reflex::PID::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);

has pid => (
	is        => 'ro',
	isa       => 'Int',
	required  => 1,
);

has active => (
	is      => 'ro',
	isa     => 'Bool',
	default => 1,
);

with 'Reflex::Role::PidCatcher' => {
	att_pid       => 'pid',
	att_active    => 'active',
	cb_exit       => make_emitter(on_exit => "exit"),
	method_start  => 'start',
	method_stop   => 'stop',
	method_pause  => 'pause',
	method_resume => 'resume',
};

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::PID - Watch the exit of a subprocess by its SIGCHLD signal.

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

# Not a complete program.  Please see the source for
# Reflex::POE::Wheel::Run for one example.

	use Reflex::PID;

	watches pid_watcher => (
		isa   => 'Reflex::PID|Undef',
		role  => 'process',
	);

	sub some_method {
		my $self = shift;

		my $pid = fork();
		die $! unless defined $pid;
		exec("some-program.pl") unless $pid;

		# Parent here.
		$self->sigchild_watcher(
			Reflex::PID->new(pid => $pid)
		);
	}

	sub on_process_exit {
		# Handle the event.
	}

=head1 DESCRIPTION

Reflex::PID waits for a particular child process to exit.  It emits a
"signal" event with information about the child process when it has
detected the child has exited.

Since Reflex::PID waits for a particular process ID, it's pretty much
useless afterwards.  Consider pairing it with Reflex::Collection if
you have to maintain several transient processes.

Reflex::PID extends Reflex::Signal to handle a particular kind of
signal---SIGCHLD.

TODO - However, first we need to make Reflex::PID objects stop
themselves and emit "stopped" events when they're done.  Otherwise
Reflex::Collection won't know when to destroy them.

=head2 Public Events

=head3 exit

Reflex::PID's "exit" event includes two named parameters.  "pid"
contains the process ID that exited.  "exit" contains the process'
exit value---a copy of C<$?> at the time the process exited.  Please
see L<perlvar/"$?"> for more information about that special Perl
variable.

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

L<Reflex::Signal>

=item *

L<Reflex::POE::Wheel::Run>

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

