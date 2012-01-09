package Reflex::Callback::CodeRef;
{
  $Reflex::Callback::CodeRef::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Callback';

has code_ref => (
	is => 'ro',
	isa => 'CodeRef',
	required => 1,
);

sub deliver {
	my ($self, $event) = @_;
	$self->code_ref()->($self->object(), $event);
}

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Callback::CodeRef - Callback adapter for plain code references

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

Used within Reflex:

	use Reflex::Callbacks qw(cb_coderef);

	my $ct = Reflex::Interval->new(
		interval    => 1 + rand(),
		auto_repeat => 1,
		on_tick     => cb_coderef {
			print "coderef callback triggered\n";
		},
	);

	$ct->run_all();

Low-level usage:

	sub callback {
		my $arg = shift;
		print "hello, $arg->{name}\n";
	}

	use Reflex::Callback;
	my $cb = Reflex::Callback::CodeRef->new( code_ref => \&code );
	$cb->deliver(greet => { name => "world" });

=head1 DESCRIPTION

Reflex::Callback::CodeRef maps the generic Reflex::Callback interface
to plain coderef callbacks.  Reflex::Callbacks' cb_coderef() function
and other syntactic sweeteners hide the specifics.

=head2 new

Reflex::Callback::CodeRef's constructor takes a single named
parameter, "code_ref", which should contain the coderef to be called
by deliver().

=head2 deliver

Reflex::Callback::CodeRef's deliver() method invokes the coderef
supplied during the callback's construction.  deliver() takes two
positional parameters: an event name (which is not currently used for
coderef callbacks), and a hashref of named parameters to be passed to
the callback.

deliver() returns whatever the coderef does.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<L<Reflex::Callback> documents the base class' generic interface.|L<Reflex::Callback> documents the base class' generic interface.>

=item *

L<L<Reflex::Callbacks> documents callback convenience functions.|L<Reflex::Callbacks> documents callback convenience functions.>

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

