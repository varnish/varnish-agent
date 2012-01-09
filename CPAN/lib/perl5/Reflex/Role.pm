package Reflex::Role;
{
  $Reflex::Role::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose::Role;
use MooseX::Role::Parameterized;
use Moose::Exporter;

# TODO - All role-based method definition goes through here, as do
# callback parameters.  We have an opportunity to validate that
# the defined callbacks and methods are sane, if Moose doesn't already
# do this for us!

Moose::Exporter->setup_import_methods(
	with_caller => [ qw(
		attribute_parameter method_parameter callback_parameter
	) ],
	also => 'MooseX::Role::Parameterized',
);

sub attribute_parameter {
	my $caller = shift();

	confess "'attribute_parameter' may not be used inside of the role block"
	if (
		MooseX::Role::Parameterized::current_metaclass() and
		MooseX::Role::Parameterized::current_metaclass()->genitor->name eq $caller
	);

	my $meta = Class::MOP::class_of($caller);

	my ($name, $default) = @_;

	$meta->add_parameter(
		$name, (
			is      => 'rw',
			isa     => 'Str',
			default => $default
		)
	);
}

sub method_parameter {
	my $caller = shift;

	confess "'method_parameter' may not be used inside of the role block"
	if (
		MooseX::Role::Parameterized::current_metaclass() and
		MooseX::Role::Parameterized::current_metaclass()->genitor->name eq $caller
	);

	my $meta = Class::MOP::class_of($caller);

	my ($name, $prefix, $member, $suffix) = @_;

	# TODO - $member must have been declared as an attribute_parameter.

	$meta->add_parameter(
		$name,
		(
			is      => 'rw',
			isa     => 'Str',
			lazy    => 1,
			default => sub {
				join(
					"_",
					grep { defined() and $_ ne "_" }
					$prefix, shift()->$member(), $suffix
				)
			},
		)
	);
}

# Nearly identical to method_parameter() except it also requires the
# callback method.

sub callback_parameter {
	my $caller = shift;

	confess "'method_parameter' may not be used inside of the role block"
	if (
		MooseX::Role::Parameterized::current_metaclass() and
		MooseX::Role::Parameterized::current_metaclass()->genitor->name eq $caller
	);

	my $meta = Class::MOP::class_of($caller);

	my ($name, $prefix, $member, $suffix) = @_;

	# TODO - $member must have been declared as an attribute_parameter.

	$meta->add_parameter(
		$name,
		(
			is      => 'rw',
			isa     => 'Str',
			lazy    => 1,
			default => sub {
				join(
					"_",
					grep { defined() and $_ ne "_" }
					$prefix, shift()->$member(), $suffix
				)
			},
		)
	);
}

BEGIN { *callback_parameter = *method_parameter; }

1;



=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 NAME

Reflex::Role - define a Reflex paramaterized role

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SYNOPSIS

TODO - Changed again;

	package Reflex::Role::Streaming;
	use Reflex::Role;

	use Scalar::Util qw(weaken);

	attribute_parameter handle      => "handle";
	callback_parameter  cb_data     => qw( on handle data );
	callback_parameter  cb_error    => qw( on handle error );
	callback_parameter  cb_closed   => qw( on handle closed );
	method_parameter    method_put  => qw( put handle _ );
	method_parameter    method_stop => qw( stop handle _ );

	role {
		my $p = shift;

		my $h         = $p->handle();
		my $cb_error  = $p->cb_error();

		with 'Reflex::Role::Collectible';

		method-emit_and_stop $cb_error => $p->ev_error();

		with 'Reflex::Role::Reading' => {
			handle      => $h,
			cb_data     => $p->cb_data(),
			cb_error    => $cb_error,
			cb_closed   => $p->cb_closed(),
		};

		with 'Reflex::Role::Readable' => {
			handle      => $h,
			active      => 1,
		};

		with 'Reflex::Role::Writing' => {
			handle      => $h,
			cb_error    => $cb_error,
			method_put  => $p->method_put(),
		};

		with 'Reflex::Role::Writable' => {
			handle      => $h,
		};

		# Multiplex a single stop() to the sub-roles.
		method $p->method_stop() => sub {
			my $self = shift;
			$self->stop_handle_readable();
			$self->stop_handle_writable();
		};
	};

	1;

=head1 DESCRIPTION

Reflex::Role defines a class as a Reflex parameterized role.  It adds
a few Reflex-specific exports to MooseX::Role::Parameterized.

It will be very helpful to understand the MooseX::Role::Parameterized
declarations C<parameter>, C<role> and C<method> before continuing.  A
basic familiarity with Moose::Role is also assumed.

=head2 ROLE PARAMETER DECLARATIONS

Reflex::Role adds a few declarations to MooseX::Role::Parameterized.
The role parameter declarations define new parameters for Reflex
roles.  They're shorthands for MooseX::Role::Parameterized
C<parameter> declarations.

=head3 attribute_parameter

Synopsis:

	attribute_parameter attribute_name => "default_name";

C<attribute_parameter> declares a role parameter that will accept an
attribute name from the consumer.  It also specifies a default
attribute name.

C<attribute_parameter> is a convenience declaration.  The synopsis
declaration is equivalent to this MooseX::Role::Parameterized syntax

	parameter attribute_name => (
		isa => 'Str',
		default => $default,
	);

=head3 callback_parameter

Synopsis:

	callback_parameter callback_name => qw( prefix attribute_param suffix);

C<callback_parameter> declares a role parameter that will accept a
callback method name.  It alsp specifies a default method name, which
is the catenation of a prefix, the value of an attribute parameter,
and a suffix.  A prefix or suffix of "_" will cause that segment of
the default to be ignored.

C<callback_parameter> is a convenience declaration.  The synopsis is
equivalent to this MooseX::Role::Parameterized syntax:

	parameter callback_name => (
		isa     => 'Str',
		lazy    => 1,
		default => sub {
			join(
				"_",
				grep { defined() and $_ ne "_" }
				$prefix, shift()->$attribute_param(), $suffix
			)
		},
	);

=head3 method_parameter

Synopsis:

	method_parameter method_name => qw( prefix attribute_param suffix );

C<method_parameter> declares a role parameter that will accept a
method name from the consumer.  It also specifies a default method
name, which is the catenation of a prefix, the value of an attribute
parameter, and a suffix.  A prefix or suffix of "_" will cause that
segment of the default to be ignored.

C<method_parameter> is a convenience declaration.  The synopsis is
equivalent to this MooseX::Role::Parameterized syntax:

	parameter method_name => (
		isa => 'Str',
		lazy => 1,
		default => sub {
			join(
				"_",
				grep { defined() and $_ ne "_" }
				$prefix, shift()->$attribute_param(), $suffix
			)
		},
	);

=head1 TODO

I'm looking for better names for Reflex::Role's exported declarations.
Please suggest some.

=head1 EXAMPLES

Nearly everything in the Reflex::Role namespace.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

=item *

L<Reflex>

=item *

L<Moose>

=item *

L<MooseX::Role::Parameterized>

=item *

L<All the Reflex roles.|All the Reflex roles.>

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

