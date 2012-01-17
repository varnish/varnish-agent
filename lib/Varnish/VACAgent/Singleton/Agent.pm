package Varnish::VACAgent::Singleton::Agent;

use 5.010;

use MooseX::Singleton;
use Data::Dumper;

use Reflex::Interval;

use Varnish::VACAgent::ClientListener;
use Varnish::VACAgent::MasterListener;
use Varnish::VACAgent::VarnishClientConnection;
use Varnish::VACAgent::ProxySession;

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



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

has proxy_sessions => (
    is => 'ro',
    isa => 'HashRef[Varnish::VACAgent::ProxySession]',
    default => sub {{}},
);

has varnish_client_connection => (
    is => 'rw',
    isa => 'Maybe[Varnish::VACAgent::VarnishClientConnection]',
    default => undef,
);

has ticker => ( # Prove that we're non-blocking
    is => 'ro',
    isa => 'Reflex::Interval',
    builder => '_build_ticker',
);

has _session_id => (
    is => 'rw',
    isa => 'Int',
    traits => ['Counter'],
    handles => { _increment_session_id => 'inc' },
    default => 0,
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

sub _build_ticker {
    my $self = shift;
    
    return Reflex::Interval->new(
        interval    => rand(5) + 1,
        auto_repeat => 1,
        on_tick     => sub { $self->debug("Agent: tick\n") },
    );
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



sub new_proxy_session {
    my ($self, $vac) = @_;

    $self->info("Accepted incoming VAC client connection from ",
                $vac->remote_ip_address, "/",
                $vac->remote_port);
    my $session_id = $self->_next_session_id();
    my $session =
        Varnish::VACAgent::ProxySession->new(id => $session_id, vac => $vac);
    $vac->proxy_session($session);
    $vac->proxy_session_id($session_id);
    $self->proxy_sessions()->{$session_id} = $session;
    
    return $session;
}



sub terminate_proxy_session {
    my ($self, $proxy_id) = @_;
    
    $self->debug("Terminating proxy session $proxy_id");
    my $session = $self->proxy_sessions()->{$proxy_id};
    $session->terminate();
    $self->proxy_sessions()->{$proxy_id} = undef;
}


# A VAC request should result in a new connection to Varnish dedicated
# to this VAC session. As long as neither VAC nor Varnish has closed
# their end of the socket, this session should continue.
#
# It would be wrong to create a new connection to varnish every time
# the VAC transmits data.
# 
# Maybe create a VACToVarnishSession to hold pointers to VAC and
# Varnish connections?
#
# I think I can't use promises, I don't know in what order they will
# request and respond - or do I? Humm - maybe I do anyway - results
# from jobs are to be sent to a RESTful url, so nothing on the CLI.
#
# Ok, try with promises first, if it doesn't work, then I will just
# have to use callbacks instead. Either have Agent keep track of which
# VarnishClientConnection belongs to which VACClient, or make a new
# VACVarnishSession or something.


sub handle_vac_request {
    my ($self, $vac) = @_;

    # Varnish produces a "welcome message" upon successful
    # connect. Need to read and handle that when a new varnish
    # connection is created.

    my $varnish = $self->varnish_client_connection();
    $varnish->put($vac->data());
    
    my $response = $varnish->response();
    $self->debug("handle_vac_request, response: ", Dumper($response));
    
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



sub _next_session_id {
    my $self = shift;

    $self->_increment_session_id();
    return $self->_session_id();
}



sub _connect_to_varnish {
    my $self = shift;
    
    my $address = $self->_config->varnish_address();
    my $port    = $self->_config->varnish_port();
    my $varnish =
        Varnish::VACAgent::VarnishClientConnection->new(address => $address,
                                                        port => $port);
    $self->varnish_client_connection($varnish);
    
    return $varnish;
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
