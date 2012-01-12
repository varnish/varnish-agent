package Varnish::VACAgent::Singleton::Agent;

use 5.010;

use MooseX::Singleton;

use Data::Dumper;

use Varnish::VACAgent::ClientListener;
use Varnish::VACAgent::MasterListener;
use Varnish::VACAgent::VarnishClientConnection;

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

sub BUILD {
    my $self = shift;

    $self->info("Waiting for incoming connections");
}



sub new_varnish_instance {
    my $self = shift;

    $self->info("Newly started varnish instance detected");
}



sub handle_varnish_master_request {
    my ($self, $data) = @_;

    $self->info("Received data: ", $data, " from varnish");
    return $data;
}



sub new_vac_client {
    my ($self, $client) = @_;

    $self->info("Accepted incoming VAC client connection from ",
                $client->remote_ip_address, "/", $client->remote_port);

}



sub handle_vac_request {
    my ($self, $vac) = @_;

        #my $response = "";
    my $varnish = $self->_connect_to_varnish();
    $varnish->put($vac->data());
    
    my $response = $varnish->response();
    $self->debug("Response: ", Dumper($response));
    
    $vac->put($response->{data});
    # Read initial varnish response
    # die "Bad varnish server initial response" unless(defined $response && ($response->{status} == CLIS_OK || $response->{status} == CLIS_AUTH));

    # send_response($client, $response);

    # my $s = IO::Select->new();
    # $s->add($client);
    # $s->add($varnish);

    # # Our connection context
    # my $c = {
    #     client => $client,
    #     varnish => $varnish,
    #     authenticated => 0,
    # };

    # eval {
    #   LOOP: while(1) {
    #       my @ready = $s->can_read;
    #       for my $fh (@ready) {
    #           if($fh == $client) {
    #     	  if($fh->eof()) {
    #     	      INFO "Client closed connection";
    #     	      last LOOP;
    #     	  }
    #     	  my $command = receive_command_2($client, $c->{authenticated});
    #     	  if($command->{line} gt '') {
    #     	      handle_command($c, $command);
    #     	  }
    #           } elsif($fh == $varnish) {
    #     	  if($fh->eof()) {
    #     	      INFO "Varnish closed connection";
    #     	      last LOOP;
    #     	  }
    #     	  # Out of sync varnish message
    #     	  DEBUG "Varnish unexpectedly ready for reading";
    #     	  my $response = receive_response($varnish);
    #     	  send_response($client, $response);
    #           }
    #       }
    #   }
    # };
    # die $@ if $@ && $@ !~ /^sigexit/;

    # INFO "Client handler down connection";
    # close $varnish;
    # close $client;
    # exit 0;
}



sub _connect_to_varnish {
    my $self = shift;
    
    my $address = $self->_config->varnish_address();
    my $port    = $self->_config->varnish_port();
    my $varnish =
        Varnish::VACAgent::VarnishClientConnection->new(address => $address,
                                                        port => $port);
    
    return $varnish;
}






1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
