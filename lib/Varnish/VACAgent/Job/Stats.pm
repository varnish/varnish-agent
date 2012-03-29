package Varnish::VACAgent::Job::Stats;

use Moose;
use 5.010;
use Data::Dumper;



extends 'Varnish::VACAgent::Job';



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';







1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
