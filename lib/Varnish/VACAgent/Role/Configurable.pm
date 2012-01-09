package Varnish::VACAgent::Role::Configurable;

use Moose::Role;

use Varnish::VACAgent::Singleton::Config;



=head1 DESCRIPTION

This role provides a pointer to the global Config object. Note that
the Config object must have been initialized somewhere before use of
this role. This is typically done from the executable main program
file.

=cut

has _config => (
    is => 'ro',
    isa => 'Varnish::VACAgent::Singleton::Config',
    builder => '_build__config',
);



sub _build__config {
    return Varnish::VACAgent::Singleton::Config->instance;
}



1;
