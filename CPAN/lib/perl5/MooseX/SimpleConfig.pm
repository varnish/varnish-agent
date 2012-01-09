package MooseX::SimpleConfig;

use Moose::Role;
with 'MooseX::ConfigFromFile';

our $VERSION   = '0.09';

use Config::Any ();

sub get_config_from_file {
    my ($class, $file) = @_;

    $file = $file->() if ref $file eq 'CODE';
    my $files_ref = ref $file eq 'ARRAY' ? $file : [$file];

    my $can_config_any_args = $class->can('config_any_args');
    my $extra_args = $can_config_any_args ?
        $can_config_any_args->($class, $file) : {};
    ;
    my $raw_cfany = Config::Any->load_files({
        %$extra_args,
        use_ext         => 1,
        files           => $files_ref,
        flatten_to_hash => 1,
    } );

    my %raw_config;
    foreach my $file_tested ( reverse @{$files_ref} ) {
        if ( ! exists $raw_cfany->{$file_tested} ) {
            warn qq{Specified configfile '$file_tested' does not exist, } .
                qq{is empty, or is not readable\n};
                next;
        }

        my $cfany_hash = $raw_cfany->{$file_tested};
        die "configfile must represent a hash structure in file: $file_tested"
            unless $cfany_hash && ref $cfany_hash && ref $cfany_hash eq 'HASH';

        %raw_config = ( %raw_config, %{$cfany_hash} );
    }

    \%raw_config;
}

no Moose::Role; 1;

__END__

=pod

=head1 NAME

MooseX::SimpleConfig - A Moose role for setting attributes from a simple configfile

=head1 SYNOPSIS

  ## A YAML configfile named /etc/my_app.yaml:
  foo: bar
  baz: 123

  ## In your class
  package My::App;
  use Moose;

  with 'MooseX::SimpleConfig';

  has 'foo' => (is => 'ro', isa => 'Str', required => 1);
  has 'baz'  => (is => 'rw', isa => 'Int', required => 1);

  # ... rest of the class here

  ## in your script
  #!/usr/bin/perl

  use My::App;

  my $app = My::App->new_with_config(configfile => '/etc/my_app.yaml');
  # ... rest of the script here

  ####################
  ###### combined with MooseX::Getopt:

  ## In your class
  package My::App;
  use Moose;

  with 'MooseX::SimpleConfig';
  with 'MooseX::Getopt';

  has 'foo' => (is => 'ro', isa => 'Str', required => 1);
  has 'baz'  => (is => 'rw', isa => 'Int', required => 1);

  # ... rest of the class here

  ## in your script
  #!/usr/bin/perl

  use My::App;

  my $app = My::App->new_with_options();
  # ... rest of the script here

  ## on the command line
  % perl my_app_script.pl -configfile /etc/my_app.yaml -otherthing 123

=head1 DESCRIPTION

This role loads simple configfiles to set object attributes.  It
is based on the abstract role L<MooseX::ConfigFromFile>, and uses
L<Config::Any> to load your configfile.  L<Config::Any> will in
turn support any of a variety of different config formats, detected
by the file extension.  See L<Config::Any> for more details about
supported formats.

Like all L<MooseX::ConfigFromFile> -derived configfile loaders, this
module is automatically supported by the L<MooseX::Getopt> role as
well, which allows specifying C<-configfile> on the commandline.

=head1 ATTRIBUTES

=head2 configfile

Provided by the base role L<MooseX::ConfigFromFile>.  You can
provide a default configfile pathname like so:

  has '+configfile' => ( default => '/etc/myapp.yaml' );

You can pass an array of filenames if you want, but as usual the array
has to be wrapped in a sub ref.

  has '+configfile' => ( default => sub { [ '/etc/myapp.yaml', '/etc/myapp_local.yml' ] } );

Config files are trivially merged at the top level, with the right-hand files taking precedence.

=head1 CLASS METHODS

=head2 new_with_config

Provided by the base role L<MooseX::ConfigFromFile>.  Acts just like
regular C<new()>, but also accepts an argument C<configfile> to specify
the configfile from which to load other attributes.  Explicit arguments
to C<new_with_config> will override anything loaded from the configfile.

=head2 get_config_from_file

Called internally by either C<new_with_config> or L<MooseX::Getopt>'s
C<new_with_options>.  Invokes L<Config::Any> to parse C<configfile>.

=head1 AUTHOR

Brandon L. Black, E<lt>blblack@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
