package Varnish::VACAgent::Job::SystemStats;

use Moose;
use 5.010;
use Data::Dumper;



extends 'Varnish::VACAgent::Job';



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



sub run {
    my $self = shift;
    
    $self->debug("SystemStats->run()");
    my $child = Reflex::POE::Wheel::Run->new(
        Program => "vmstat " . $self->all_parameters(),
    );
    $self->child($child);
}

   

1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
