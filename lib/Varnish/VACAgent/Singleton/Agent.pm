package Varnish::VACAgent::Singleton::Agent;

use 5.010;

use MooseX::Singleton;
use Data::Dumper;
use File::Slurp;

use Reflex::Interval;

use Varnish::VACAgent::ClientListener;
use Varnish::VACAgent::MasterListener;
use Varnish::VACAgent::VarnishClientConnection;
use Varnish::VACAgent::ProxySession;

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';
with 'Varnish::VACAgent::Role::VarnishCLI';



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
    traits => ['Hash'],
    is => 'ro',
    isa => 'HashRef[Varnish::VACAgent::ProxySession]',
    default => sub {{}},
    handles => {
        has_proxy_session    => 'exists',
        get_proxy_session    => 'get',
        delete_proxy_session => 'delete',
    },
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

has secret => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1,
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
    
    my $map = {
        'auth'       => sub { return $self->command_auth(@_) },
        'vcl.use'    => sub { return $self->command_vcl_use(@_) },
        'param.set'  => sub { return $self->command_param_set(@_) },
        'agent.stat' => sub { return $self->command_agent_stat(@_) },
    };
    
    return $map;
}



sub _build_secret {
    my $self = shift;

    my $secret = '';
    
    if ((my $secret_file = $self->_config->secret_file()) gt '') {
        die "Can't read secret file" unless -r $secret_file;
        
        $secret = read_file($secret_file);

        die "No secret in secret file" unless $secret gt '';
    }
    
    return $secret;
}



sub _build_ticker {
    my $self = shift;
    
    return Reflex::Interval->new(
        interval    => 3,
        auto_repeat => 1,
        on_tick     => sub { $self->debug("Agent: tick\n") },
    );
}



sub BUILD {
    my $self = shift;

    $self->info("Waiting for incoming connections");
}



# Called from MasterListener when varnish connects to the master port

sub new_varnish_instance {
    my ($self, $varnish_master) = @_;

    $self->info("Newly started varnish instance detected");
}



# Called from VarnishMasterConnection when varnish sends data on an
# established master connection

sub handle_varnish_master_request {
    my ($self, $varnish_master, $request_data) = @_;

    if (! $varnish_master->authenticated()) {
        $self->_new_varnish_authenticate($varnish_master, $request_data);
    }
    if ($varnish_master->authenticated()) {
        $self->_new_varnish_push_params($varnish_master);
        $self->_new_varnish_push_config($varnish_master);
    }
}



# Die unless authentication is ok

sub _new_varnish_authenticate {
    my ($self, $varnish, $data) = @_;
    
    $self->debug("_new_varnish_authenticate running");
    my $response = $self->decode_data_from_varnish_master($data);
    
    # VarnishMasterConnection calls us again each time data arrives
    # until the connection is properly authenticated.

    if ($response->status_is_auth() &&
            ! $varnish->authentication_in_progress()) {
        $self->debug("Authentication first state"); 
        my $secret = $self->secret() or die "No secret configured";
        
        my $auth_cmd = $self->format_auth_command($response->challenge(),
                                                  $self->secret());
        $varnish->authentication_in_progress(1);
        $varnish->put($auth_cmd->to_string());
    }
    elsif ($response->status_is_ok() &&
               $varnish->authentication_in_progress()) {
        $self->debug("Authentication second state"); 
        $varnish->authentication_in_progress(0);
        $varnish->authenticated(1);
    }
    else {
        die("Authentication failed"); 
    }
    $self->debug("_new_varnish_authenticate returning");
}



sub _new_varnish_push_params {
    my ($self, $varnish) = @_;
    
    $self->debug("_new_varnish_push_params running");
    # # Push params
    # if(-r $config{ParamsFile}) {
    #     INFO "Pushing parameters to varnish";
    #     my $params = read_params($config{ParamsFile});

    #     for my $param (@$params) {
    #         send_command_2(
    #     	$varnish, 
    #     	{ command => "param.set",
    #     	  args => [ $param->[0], $param->[1] ]
    #     	} );
    #         my $response = receive_response($varnish);
    #         if($response->{status} == CLIS_OK) {
    #     	INFO "Parameter $param->[0]=$param->[1] set successfully";
    #         } else {
    #     	WARN "Failed to set $param->[0]=$param->[1]";
    #         }
    #     }
    # }
}



sub _new_varnish_push_config {
    my ($self, $varnish) = @_;
    
    $self->debug("_new_varnish_push_config running");

    # # Push config
    # if(-r $config{VCLFile}) {
    #     eval {
    #         INFO "Pushing current vcl to varnish";
    #         my $data = read_file($config{VCLFile});
	    
    #         # Create a name for the VCL
    #         # We are using the sha1 of the content of the file
    #         my $vcl_name = sha1_hex($data);
	    
    #         # Load the VCL
    #         send_command_2(
    #     	$varnish,
    #     	{ command => "vcl.inline",
    #     	  args => [ $vcl_name, $data ],
    #     	  heredoc => $authenticated,
    #     	} );
    #         my $response = receive_response($varnish);
    #         DEBUG "vcl.inline status=$response->{status}";
    #         die "Failed to load VCL" unless $$response{status} == CLIS_OK;
	    
    #         # Use the VCL
    #         send_command($varnish, "vcl.use $vcl_name");
    #         $response = receive_response($varnish);
    #         DEBUG "vcl.use status=$response->{status}";
    #         die "Failed to use the VCL" unless $$response{status} == CLIS_OK;
	    
    #         # Start varnish
    #         send_command($varnish, "start");
    #         $response = receive_response($varnish);
    #         DEBUG "start status=$response->{status}";
    #         die "Failed to start varnish" unless $$response{status} == CLIS_OK;
    #     };
    #     if ($@) {
    #         WARN "Agent autoload VCL failed: $@";
    #     }
    # }
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
    my $session = $self->get_proxy_session($proxy_id);
    $session->terminate();
    $self->delete_proxy_session($proxy_id);
}



sub handle_command {
    my ($self, $command, $session_id) = @_;
    
    my $handler = $self->get_command_handler($command->command());
    return $handler->($command, $session_id);
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
    my ($self, $command, $session_id) = @_;
    
    $self->debug("command_auth running");
    my $session = $self->get_proxy_session($session_id);
    my $varnish = $session->varnish();
    my $vac     = $session->vac();
    
    
    $varnish->put($command->to_string());
    
    my $response = $varnish->response();
    if ($response->status_is_ok()) {
        $session->authenticated(1);
    }
    
    return $response;
}



sub command_vcl_use {
    my ($self, $vcl_use_request, $session_id) = @_;
    
    my $session       = $self->get_proxy_session($session_id);
    my $authenticated = $session->authenticated();
    my $varnish       = $session->varnish();
    my $vac           = $session->vac();
    my $final_response;
    
    my $vcl_name = $vcl_use_request->args->[0];
    $self->debug("command_vcl_use called, vcl_name = \"$vcl_name\"");

    if (! $vcl_name) {
	# Bad command line, let varnish create a helpful error message
        return $self->run_varnish_command($varnish, $vcl_use_request);
    }

    $self->debug("vcl_name = $vcl_name");
    my $vcl_show_response =
        $self->_vcl_show($session, $vcl_name, $authenticated);
    $self->debug("V->A: ", $vcl_show_response->to_string());
        
    # Send the command to use this config to varnish
    my $vcl_use_response =
        $self->run_varnish_command($varnish, $vcl_use_request);
        
    if ($vcl_show_response->status_is_ok() &&
            $vcl_use_response->status_is_ok()) {
        # If the response from varnish to vcl.use is CLIS_OK
        # store the config as the last one

        # TODO: what if the vcl.show returns not CLIS_OK, but vcl.use does?

        $self->_write_vcl_file($vcl_show_response->message());
        $self->info("New varnish configuration stored");
    }
    
    return $vcl_use_response;
}



# Get the VCL with the given name from varnish, return DataFromVarnish

sub _vcl_show {
    my ($self, $session, $vcl_name, $auth) = @_;
    
    my ($vac, $varnish) = ($session->vac(), $session->varnish());
    my $request = $vac->get_request_from_string("vcl.show $vcl_name", $auth);

    return $self->run_varnish_command($varnish, $request);
}



# Execute given command of type datatovarnish on varnish, return
# DataFromVarnish object

sub run_varnish_command {
    my ($self, $varnish, $command) = @_;

    $varnish->put($command->to_string());
    return $varnish->response();
}



sub _write_vcl_file {
    my ($self, $vcl) = @_;
    
    my $filename = $self->_config()->vcl_file();
    open(my $file, ">$filename")
        or die "Failed to open output file $filename: " . $!;
    print $file $vcl;
    close $file;
}



sub command_param_set {
    my ($self, $command, $session_id) = @_;

    $self->debug("command_param_set running, TODO: logic needed");
    my $response;
    return $response;
}



sub command_agent_stat {
    my ($self, $command, $session_id) = @_;

    $self->debug("command_agent_stat running, TODO: logic needed");
    my $response;
    return $response;
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
