package Reflex::POE::Session;
{
  $Reflex::POE::Session::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';

use Scalar::Util qw(weaken);
use POE::Session; # for ARG0
use Reflex::Event::POE;

my %session_id_to_object;

has sid => (
	isa => 'Str',
	is  => 'ro',
);

sub BUILD {
	my $self = shift;

	$session_id_to_object{$self->sid()}{$self} = $self;
	weaken $session_id_to_object{$self->sid()}{$self};
}

sub DEMOLISH {
	my $self = shift;
	delete $session_id_to_object{$self->sid()}{$self};
	delete $session_id_to_object{$self->sid()} unless (
		keys %{$session_id_to_object{$self->sid()}}
	);
}

sub deliver {
	my ($class, $sender_id, $event_name, $args) = @_;

	# Not a session anyone is interested in.
	return unless exists $session_id_to_object{$sender_id};

	foreach my $self (values %{$session_id_to_object{$sender_id}}) {
		$self->emit(
			-name => $event_name,
			-type => 'Reflex::Event::POE',
			args  => [ @$args ],
		);
	}
}

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::POE::Session - Watch events from a POE::Session object.

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

This sample usage is not a complete program.  The rest of the program
exists in eg-13-irc-bot.pl, in the tarball's eg directory.

	sub BUILD {
		my $self = shift;

		$self->component(
			POE::Component::IRC->spawn(
				nick    => "reflex_$$",
				ircname => "Reflex Test Bot",
				server  => "10.0.0.25",
			) || die "Drat: $!"
		);

		$self->poco_watcher(
			Reflex::POE::Session->new(
				sid => $self->component()->session_id(),
			)
		);

		$self->run_within_session(
			sub {
				$self->component()->yield(register => "all");
				$self->component()->yield(connect  => {});
			}
		)
	}

=head1 DESCRIPTION

Reflex::POE::Session allows a Reflex::Base object to receive events
from a specific POE::Session instance, identified by the session's ID.

Authors are encouraged to encapsulate POE sessions within Reflex
objects.  Most users should not need use Reflex::POE::Session (or
other Reflex::POE helpers) directly.

=head2 Public Attributes

=head3 sid

The "sid" must contain the ID of the POE::Session to be watched.  This
is in fact how Reflex::POE::Session knows which session to watch.  See
L<POE> for more information about session IDs.

=head2 Public Events

Reflex::POE::Session will emit() events on behalf of the watched
POE::Session.  If the session posts "irc_001", then
Reflex::POE::Session will emit "irc_001", and so on.

Reflex::POE::Session's "args" parameter will contain all of the POE
event's paramters, from ARG0 through the end of the parameter list.
They will be mapped to Reflex paramters "0" through the last index.

Assume that this POE post() call invokes this Reflex callback() via
Refex::POE::Session:

	$kernel->post( event => qw(one one two three five) );

	...;

	sub callback {
		my ($self, $event) = @_;
		print "$_\n" foreach $event->args_list();
	}

The callback will print five lines:

	one
	one
	two
	three
	five

=head1 CAVEATS

Reflex::POE::Session will take note of every event sent by the
session, although it won't try to deliver ones that haven't been
registered with the callback object.  However, the act of filtering
these events out is more overhead than simply not registering interest
in the first place.  A later version will be more optimal.

Reflex::POE::Wheel provides a way to map parameters to symbolic names.
Reflex::POE::Session may also provide a similar mechanism in the
future, obsoleting the parameter numbers.

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

L<Reflex::POE::Postback>

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

