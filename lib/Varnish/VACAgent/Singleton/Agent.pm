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

has handled_commands => (
    traits => ['Hash'],
    is => 'ro',
    isa => 'HashRef[CodeRef]',
    builder => '_build_handled_commands',
    handles => {
        get_command_handler => 'get',
        is_handled_command => 'exists',
    },
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

sub _build_handled_commands {
    my $self = shift;
    $self->debug("_build_handled_commands entered");
    my $map = {
        'auth'       => sub { $self->command_auth(@_) },
        'vcl.use'    => sub { $self->command_vcl_use(@_) },
        'param.set'  => sub { $self->command_param_set(@_) },
        'agent.stat' => sub { $self->command_agent_stat(@_) },
    };
    $self->debug("_build_handled_commands returning");
    
    return $map;
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



sub handle_vac_request {
    my ($self, $vac) = @_;

    my $varnish = $self->varnish_client_connection();
    $varnish->put($vac->data());
    
    my $response = $varnish->response();
    $self->debug("handle_vac_request, response: ", Dumper($response));
    
    $vac->put($response->{data});
}



sub handle_command {
    my ($self, $command) = @_;
    
    my $handler = $self->get_command_handler($command->command());
    $handler->();
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



sub command_auth {
    my $self = shift;

    $self->debug("command_auth running");
}



sub command_vcl_use {
    my $self = shift;

    $self->debug("command_vcl_use running");
}



sub command_param_set {
    my $self = shift;

    $self->debug("command_param_set running");
}



sub command_agent_stat {
    my $self = shift;

    $self->debug("command_agent_stat running");
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
