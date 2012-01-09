# A self-managing collection of objects.  See
# Reflex::Role::Collectible for the other side of the
# Collectible/Collection contract.

package Reflex::Collection;
{
  $Reflex::Collection::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
use Moose::Exporter;
use Reflex::Callbacks qw(cb_method);
use Carp qw(cluck);

# Reflex::Role::Collectible isn't directly used in this module, but
# the role needs to be loaded for the objects() type constraint to
# work below.  Hans Dieter Pearcey recommends the canonical Moose
# practice of declaring types in a separate header-like class:
#
#   package Reflex::Types;
#   use Moose::Util::TypeConstraints;
#   role_type('Reflex::Role::Collectible');
#
# Using Reflex::Types sets up role and type constraints once across
# the entire program.  Problems can occur when the order modules are
# loaded becomes significant.  A Reflex::Types module can avoid them.

use Reflex::Role::Collectible;

extends 'Reflex::Base';

Moose::Exporter->setup_import_methods( with_caller => [ qw( has_many ) ]);

has _objects => (
	is      => 'rw',
	isa     => 'HashRef[Reflex::Role::Collectible]',
	traits  => ['Hash'],
	default => sub { {} },
	handles => {
		_set_object    => 'set',
		_delete_object => 'delete',
		get_objects    => 'values',
	},
);

has _owner => (
	is       => 'ro',
	isa      => 'Object',
	writer   => '_set_owner',
	weak_ref => 1,
);

sub remember {
	my ($self, $object) = @_;

	$self->watch($object, stopped => cb_method($self, "cb_forget"));
	$self->_owner->watch(
		$object,
		result => cb_method($self->_owner, "on_result")
	);

	$self->_set_object($object->get_id(), $object);
}

sub forget {
	my ($self, $object) = @_;
	$self->_delete_object($object->get_id());
}

sub cb_forget {
	my ($self, $event) = @_;
	$self->forget($event->get_last_emitter());
}

sub has_many {
	my ($caller, $name, %etc) = @_;

	my $meta = Class::MOP::class_of($caller);
	foreach (qw(is isa default)) {
		cluck "has_many is ignoring your '$_' parameter" if exists $etc{$_};
	}

	$etc{is}      = 'ro';
	$etc{isa}     = 'Reflex::Collection';
	$etc{lazy}    = 1 unless exists $etc{lazy};
	$etc{default} = sub {
		my $self = shift;
		return Reflex::Collection->new( _owner => $self );
	};

	$meta->add_attribute($name, %etc);
}

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Collection - Autmatically manage a collection of collectible objects

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

	package TcpEchoServer;

	use Moose;
	extends 'Reflex::Listener';
	use Reflex::Collection;
	use EchoStream;

	# From Reflex::Collection.
	has_many clients => (
		handles => { remember_client => "remember" },
	);

	sub on_listener_accepted {
		my ($self, $event) = @_;
		$self->remember_client(
			EchoStream->new(
				handle => $event->socket(),
				rd     => 1,
			)
		);
	}

		sub broadcast {
				my ($self, $message) = @_;

				foreach my $handle ($self->get_objects) {
						$handle->put($message);
				}
		}

	1;

=head1 DESCRIPTION

Some object manage collections of collectible objects---ones that
consume Reflex::Role::Collectible.  For example, network servers must
track objects that represent client connections.  If not, those
objects would go out of scope, destruct, and disconnect their clients.

Reflex::Collection is a generic object collection manager.  It exposes
remember() and forget(), which may be mapped to other methods using
Moose's "handles" aspect.

Reflex::Collection goes beyond this simple hash-like interface.  It
will automatically forget() objects that emit "stopped" events,
triggering their destruction if nothing else refers to them.  This
eliminates a large amount of repetitive work.

Reflex::Role::Collectible provides a stopped() method that emits the
"stopped" event.  Calling C<<$self->stopped()>> in the collectible
class is sufficient to trigger the proper cleanup.

TODO - Reflex::Collection is an excellent place to manage pools of
objects.  Provide a callback interface for pulling new objects as
needed.

=head2 has_many

Reflex::Collection exports the has_many() function, which works like
Moose's has() with "is", "isa", "lazy" and "default" set to common
values.  For example:

	has_many connections => (
		handles => { remember_connection => "remember" },
	);

... is equivalent to:

	has connections => (
		# Defaults provided by has_many.
		is      => 'ro',
		isa     => 'Reflex::Collection',
		lazy    => 1,
		default => sub { Reflex::Collection->new() {,

		# Customization.
		handles => { remember_connection => "remember" },
	);

=head2 new

Create a new Reflex::Collection.  It takes no parameters.

=head2 remember

Remember an object.  Reflex::Collection works best if it contains the
only references to the objects it manages, so you may often see
objects remembered while they're constructed.  See the SYNOPSIS for
one such example.

remember() takes one parameter: the object to remember.

=head2 forget

Forget an object, returning its reference.  You've supplied the
reference, so the returned one is usually redundant.  forget() takes
one parameter: the object to forget.

=head2 get_objects

Get the collected objects in scope. Returns a list.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

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

