package Reflex::Callback::Method;
{
  $Reflex::Callback::Method::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Callback';

has method_name => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

sub deliver {
	my ($self, $event) = @_;
	my $method_name = $self->method_name();
	$self->object()->$method_name($event);
}

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Callback::Method - Callback adapter for class and object methods

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

Used within Reflex:

	package MethodHandler;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Callbacks qw(cb_method);
	use ExampleHelpers qw(eg_say);

	has ticker => (
		isa     => 'Maybe[Reflex::Interval]',
		is      => 'rw',
	);

	sub BUILD {
		my $self = shift;
		$self->ticker(
			Reflex::Interval->new(
				interval    => 1 + rand(),
				auto_repeat => 1,
				on_tick     => cb_method($self, "callback"),
			)
		);
	}

	sub callback {
		eg_say("method callback triggered");
	}

	MethodHandler->new()->run_all();

Low-level usage:

	{
		package Object;
		use Moose;

		sub callback {
			my ($self, $arg) = @_;
			print "$self says: hello, $arg->{name}\n";
		}
	}

	my $object = Object->new();

	my $cb = Reflex::Callback::Method->new(
		object      => $object,
		method_name => "callback"
	);

	$cb->deliver(greet => { name => "world" });

=head1 DESCRIPTION

Reflex::Callback::Method maps the generic Reflex::Callback interface
to object and class method callbacks.  Reflex::Callbacks' cb_method()
function simplifies callback creation.  cb_object(), also supplied by
Reflex::Callbacks, is shorthand for setting several callbacks at once
on a single object or class.  Other syntactic sweeteners are in
development.

=head2 new

Reflex::Callback::Method's constructor takes two named parameters.
"object" and "method_name" define the object and method that will be
invoked to handle the callback.

Despite its name, "object" may also handle class names.  In these
cases, "method_name" will be invoked as a class method rather than on
a particular instance of the class.

=head2 deliver

Reflex::Callback::Method's deliver() method invokes the object (or
class) and method as defined during the callback's construction.
deliver() takes two positional parameters: an event name (which is not
currently used for method callbacks), and a hashref of named
parameters to be passed to the callback.

deliver() returns whatever the coderef does.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Callback>

=item *

L<Reflex::Callbacks>

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

