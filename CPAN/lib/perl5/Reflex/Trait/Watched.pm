package Reflex::Trait::Watched;
{
  $Reflex::Trait::Watched::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose::Role;
use Scalar::Util qw(weaken);
use Reflex::Callbacks qw(cb_role);

use Moose::Exporter;
Moose::Exporter->setup_import_methods( with_caller => [ qw( watches ) ]);

has setup => (
	isa     => 'CodeRef|HashRef',
	is      => 'ro',
);

has trigger => (
	is => 'ro',
	default => sub {
		my $meta_self = shift;

		# $meta_self->name() is not set yet.
		# Weaken $meta_self so that the closure isn't fatal.
		# TODO - If we can get the name out here, then we save a name()
		# method call every trigger.
		weaken $meta_self;
		my $role;

		sub {
			my ($self, $value) = @_;

			# TODO - Ignore the object when we're set to undef.  Probably
			# part of a clearer method.  Currently we rely on the object
			# destructing on clear, which also triggers ignore().

			my $name = $meta_self->name();

			# Previous value?  Stop watching that.
			$self->ignore($self->$name()) if $self->$name();

			# No new value?  We're done.
			return unless $value;

			$self->watch(
				$value,
				cb_role(
					$self,
					$role ||= $self->meta->find_attribute_by_name($name)->role()
				)
			);
			return;
		}
	}
);

# Initializer seems to catch the interest from default.  Nifty!

has initializer => (
	is => 'ro',
	default => sub {
		my $role;
		return sub {
			my ($self, $value, $callback, $attr) = @_;
			if (defined $value) {
				$self->watch(
					$value,
					cb_role(
						$self,
						$role ||=
						$self->meta->find_attribute_by_name($attr->name())->role()
					),
				);
			}
			else {
				# TODO - Ignore the object in the old value, if defined.
			}

			$callback->($value);
		}
	},
);

has role => (
	isa     => 'Str',
	is      => 'ro',
	default => sub {
		my $self = shift;
		return $self->name();
	},
);

has setup => (
	isa     => 'CodeRef|HashRef',
	is      => 'ro',
);

# TODO - Clearers don't invoke triggers, because clearing is different
# from setting.  I would love to support $self->clear_thingy() with
# the side-effect of ignoring the object, but I don't yet know how
# to set an "after" method for a clearer that (a) has a dynamic name,
# and (b) hasn't yet been defined.  I think I can do some meta magic
# for (a), but (b) remains tough.

#has clearer => (
#	isa     => 'Str',
#	is      => 'ro',
#	default => sub {
#		my $self = shift;
#		return "clear_" . $self->name();
#	},
#);

### Watched declarative syntax.

sub watches {
	my ($caller, $name, %etc) = @_;
	my $meta = Class::MOP::class_of($caller);
	push @{$etc{traits}}, __PACKAGE__;
	$etc{is} = 'rw' unless exists $etc{is};
	$meta->add_attribute($name, %etc);
}

package Moose::Meta::Attribute::Custom::Trait::Reflex::Trait::Watched;
{
  $Moose::Meta::Attribute::Custom::Trait::Reflex::Trait::Watched::VERSION = '0.092';
}
sub register_implementation { 'Reflex::Trait::Watched' }

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Trait::Watched - Automatically watch Reflex objects.

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

# Not a complete program.  This example comes from Reflex's main
# L<synopsis|Reflex/SYNOPSIS>.

	has clock => (
		isa     => 'Reflex::Interval',
		is      => 'rw',
		traits  => [ 'Reflex::Trait::Watched' ],
		setup   => { interval => 1, auto_repeat => 1 },
	);

=head1 DESCRIPTION

Reflex::Trait::Watched modifies a member to automatically watch() any
Reflex::Base object stored within it.  In the SYNOPSIS, storing a
Reflex::Interval in the clock() attribute allows the owner to watch the
timer's events.

This trait is a bit of Moose-based syntactic sugar for Reflex::Base's
more explict watch() and watch_role() methods.

=head2 setup

The "setup" option provides default constructor parameters for the
attribute.  In the above example, clock() will by default contain

	Reflex::Interval->new(interval => 1, auto_repeat => 1);

In other words, it will emit the Reflex::Interval event ("tick") once
per second until destroyed.

=head2 role

Attribute events are mapped to the owner's methods using Reflex's
role-based callback convention.  For example, Reflex will look for an
on_clock_tick() method to handle "tick" events from an object with the
'clock" role.

The "role" option allows roles to be set or overridden.  A watcher
attribute's name is its default role.

=head1 Declarative Syntax

Reflex::Trait::Watched exports a declarative watches() function,
which acts almost identically to Moose's has() but with a couple
convenient defaults: The Watched trait is added, and the attribute is
given "rw" access by default.

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

L<Reflex::Trait::EmitsOnChange>

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

