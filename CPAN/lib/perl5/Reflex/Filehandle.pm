package Reflex::Filehandle;
{
  $Reflex::Filehandle::VERSION = '0.092';
}
# vim: ts=2 sw=2 noexpandtab

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw(make_emitter);
use Carp qw(croak);

has descriptor => ( is => 'rw', isa => 'Int', default => undef );

has handle => (
  is      => 'rw',
  isa     => 'FileHandle',
  lazy    => 1,
  default => sub {
    my $self = shift();
    my $fd = $self->descriptor();
    croak "Reflex::Filehandle must have a descriptor handle" unless (
      defined $fd
    );

    open my($fh), "+<&=$fd" or croak "can't dup fd $fd: $!";

    return $fh;
  }
);

has rd => ( is => 'ro', isa => 'Bool', default => 0 );
has wr => ( is => 'ro', isa => 'Bool', default => 0 );

with 'Reflex::Role::Readable' => {
  att_handle    => 'handle',
  att_active    => 'rd',
  cb_ready      => make_emitter(on_readable => 'readable'),
  method_pause  => 'pause_rd',
  method_resume => 'resume_rd',
  method_stop   => 'stop_rd',
};

with 'Reflex::Role::Writable' => {
  att_handle    => 'handle',
  att_active    => 'wr',
  cb_ready      => make_emitter(on_writable => 'writable'),
  method_pause  => 'pause_wr',
  method_resume => 'resume_wr',
  method_stop   => 'stop_wr',
};

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

