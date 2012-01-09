package Reflex::Event;
{
  $Reflex::Event::VERSION = '0.092';
}

use Moose;
use Scalar::Util qw(weaken);

has _name => (
	is      => 'ro',
	isa     => 'Str',
	default => 'generic',
);

has _emitters => (
	is       => 'ro',
	isa      => 'ArrayRef[Any]',
	traits   => ['Array'],
	required => 1,
	handles  => {
		get_first_emitter => [ 'get', 0  ],
		get_last_emitter  => [ 'get', -1 ],
		get_all_emitters  => 'elements',
	}
);

sub BUILD {
	my $self = shift();

	# After build, weaken any emitters passed in.
	#my $emitters = $self->_emitters();
	#weaken($_) foreach @$emitters;
}

sub push_emitter {
	my ($self, $item) = @_;

	use Carp qw(confess); confess "wtf" unless defined $item;

	my $emitters = $self->_emitters();
	push @$emitters, $item;
	#weaken($emitters->[-1]);
}

sub _headers {
	my $self = shift();
	return (
		map  { "-" . substr($_,1), $self->$_() }
		grep { /^_/            }
		map  { $_->name()      }
		Class::MOP::Class->initialize(ref($self))->get_all_attributes()
	);
}

sub _body {
	my $self = shift();
	return (
		map  { $_, $self->$_() }
		grep { !/^_/           }
		map  { $_->name()      }
		Class::MOP::Class->initialize(ref($self))->get_all_attributes()
	);
}

sub _clone {
	my ($self, %override_args) = @_;

	my %clone_args;

	my @attribute_names = (
		map { $_->name() }
		Class::MOP::Class->initialize(ref($self))->get_all_attributes()
	);

	@clone_args{@attribute_names} = map { $self->$_() } @attribute_names;

	my @override_keys = keys %override_args;
	@clone_args{ map { s/^-/_/; $_ } @override_keys } = values %override_args;

	my $new_type = delete($clone_args{_type}) // ref($self);
	my $emitters = delete($clone_args{_emitters}) // confess "no -emitters";

	my $new_event = $new_type->new(%clone_args, _emitters => [ @$emitters ]);

	return $new_event;
}

# Override Moose's dump().
sub dump {
	my $self = shift;

	my $dump = "=== $self ===\n";
	my %clone = ($self->_headers(), $self->_body());
	foreach my $k (sort keys %clone) {
		$dump .= "$k: $clone{$k}\n";
		if ($k eq '-emitters') {
			my @emitters = $self->get_all_emitters();
			for my $i (0..$#emitters) {
				$dump .= "    emitter $i: $emitters[$i]\n";
			}
		}
	}

	# No newline so we get line numbers.
	$dump .= "===";

	return $dump;
}

1;

__END__
=pod

=for :stopwords Rocco Caputo

=encoding UTF-8

=head1 VERSION

This document describes version 0.092, released on November 29, 2011.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Reflex|Reflex>

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

