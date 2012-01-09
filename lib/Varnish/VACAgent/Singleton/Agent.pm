package Varnish::VACAgent::Agent;

use 5.010;

use MooseX::Singleton;

use Data::Dumper;

use Varnish::VACAgent::ClientListener;
use Varnish::VACAgent::MasterListener;

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



# has _cluster_manager => (
#     isa => 'Varnish::VACAgent::ClusterManager',
#     is => 'ro',
#     builder => '_build__cluster_manager',
# );
# 
# has _job_manager => (
#     isa => 'Varnish::VACAgent::JobManager',
#     is => 'ro',
#     builder => '_build__job_manager',
#);

has client_listener => (
    is         => 'rw',
    isa        => 'Varnish::VACAgent::ClientListener',
    builder => '_build_client_listener',
);

has master_listener => (
    is         => 'rw',
    isa        => 'Varnish::VACAgent::MasterListener',
    builder => '_build_master_listener',
);



sub _build_client_listener {
    my $self = shift;
    $self->debug("_build_client_listener");
    return Varnish::VACAgent::ClientListener->new();
}



sub _build_master_listener {
    my $self = shift;
    $self->debug("_build_master_listener");
    return Varnish::VACAgent::MasterListener->new();
}



sub new_varnish_instance_started {
    my $self = shift;

    $self->info("Newly started varnish instance detected");
}



sub new_vac_connection {
    my $self = shift;

    $self->info("New VAC instance connected");
}



1;
