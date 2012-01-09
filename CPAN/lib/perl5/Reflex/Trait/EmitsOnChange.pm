package Reflex::Trait::EmitsOnChange;
{
  $Reflex::Trait::EmitsOnChange::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose::Role;
use Scalar::Util qw(weaken);

use Moose::Exporter;
Moose::Exporter->setup_import_methods( with_caller => [ qw( emits ) ]);

use Reflex::Event::ValueChange;

has setup => (
	isa     => 'CodeRef|HashRef',
	is      => 'ro',
);

has trigger => (
	is => 'ro',
	default => sub {
		my $meta_self = shift;

		# $meta_self->name() is not set yet.
		# Weaken $meta_self so that the closure isn't permanent.

		my $event;
		my $old_value;

		sub {
			my ($self, $new_value) = @_;

			# Edge-detection.  Only emit when a value has changed.
			# TODO - Make this logic optional.  Sometimes an application
			# needs level logic rather than edge logic.

			#return if (
			#	(!defined($value) and !defined($last_value))
			#		or
			#	(defined($value) and defined($last_value) and $value eq $last_value)
			#);

			$self->emit(
				-type => 'Reflex::Event::ValueChange',
				-name => (
					$event ||=
					$self->meta->find_attribute_by_name($meta_self->name())->event()
				),
				old_value => $old_value,
				new_value => $new_value,
			);

			$old_value = $new_value;
			weaken $old_value if defined($old_value) and ref($old_value);
		}
	}
);

has initializer => (
	is => 'ro',
	default => sub {
		my $role;
		return sub {
			my ($self, $value, $callback, $attr) = @_;
			my $event;
			$self->emit(
				-name => (
					$event ||=
					$self->meta->find_attribute_by_name($attr->name())->event()
				),
				value => $value,
			);

			$callback->($value);
		}
	},
);

has event => (
	isa     => 'Str',
	is      => 'ro',
	default => sub {
		my $self = shift;
		return $self->name();
	},
);

### EmitsOnChanged declarative syntax.

sub emits {
	my ($caller, $name, %etc) = @_;
	my $meta = Class::MOP::class_of($caller);
	push @{$etc{traits}}, __PACKAGE__;
	$etc{is} = 'rw' unless exists $etc{is};
	$meta->add_attribute($name, %etc);
}

package Moose::Meta::Attribute::Custom::Trait::Reflex::Trait::EmitsOnChange;
{
  $Moose::Meta::Attribute::Custom::Trait::Reflex::Trait::EmitsOnChange::VERSION = '0.092';
}
sub register_implementation { 'Reflex::Trait::EmitsOnChange' }

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Trait::EmitsOnChange - Emit an event when an attribute's value changes.

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	# Not a complete program.  See examples eg-09-emitter-trait.pl
	# and eg-10-setup.pl for working examples.

	package Counter;
	use Moose;
	extends 'Reflex::Base';
	use Reflex::Trait::EmitsOnChange;

	emits count => (
		isa       => 'Int',
		default   => 0,
	);

An equivalent alternative:

	has count   => (
		traits    => ['Reflex::Trait::EmitsOnChange'],
		isa       => 'Int',
		is        => 'rw',
		default   => 0,
	);

=head1 DESCRIPTION

An attribute with the Reflex::Trait::EmitsOnChange trait emit an event
on behalf of its object whenever its value changes.  The event will be
named after the attribute by default.  It will be accompanied by a
"value" parameter, the value of which is the attribute's new value at
the time of the change.

In the SYNOPSIS example, changes to count() cause its Counter object
to emit "count" events.

=head2 event

The "default" option can be used to override the default event emitted
by the Reflex::Trait::EmitsOnChange trait.  That default, by the way,
is the name of the attribute.

=head2 setup

The "setup" option provides default constructor parameters for the
attribute.  In the above example, clock() will by default contain

	Reflex::Interval->new(interval => 1, auto_repeat => 1);

In other words, it will emit the Reflex::Interval event ("tick") once
per second until destroyed.

=head1 Declarative Syntax

Reflex::Trait::EmitsOnChange exports a declarative emits() function,
which acts almost identically to Moose's has() but with a couple
convenient defaults: The EmitsOnChange trait is added, and the
attribute is "rw" to allow changes.

=head1 CAVEATS

The "setup" option is a work-around for unfortunate default timing.
It will be deprecated if default can be made to work instead.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Reflex::Trait::Watches>

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

