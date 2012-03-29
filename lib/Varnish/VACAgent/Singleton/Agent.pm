package Varnish::VACAgent::Singleton::Agent;

use 5.010;

use MooseX::Singleton;
use Data::Dumper;
use File::Slurp;

use Reflex::Interval;

use Varnish::VACAgent::JobManager;
use Varnish::VACAgent::ClientListener;
use Varnish::VACAgent::MasterListener;
use Varnish::VACAgent::VarnishClientConnection;
use Varnish::VACAgent::ProxySession;

with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';
with 'Varnish::VACAgent::Role::VarnishCLI';



has _job_manager => (
     isa => 'Varnish::VACAgent::JobManager',
     is => 'ro',
     builder => '_build__job_manager',
);

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



sub _build__job_manager {
    my $self = shift;

    return Varnish::VACAgent::JobManager->new();
}



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
        'auth'            => sub { return $self->command_auth(@_) },
        'vcl.use'         => sub { return $self->command_vcl_use(@_) },
        'param.set'       => sub { return $self->command_param_set(@_) },
        'agent.job'       => sub { return $self->command_agent_job(@_) },
        'agent.job_list'  => sub { return $self->command_agent_job_list(@_) },
        'agent.job_stop'  => sub { return $self->command_agent_job_stop(@_) },
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
        interval    => 15,
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



# Called from VarnishMasterConnection the first time varnish sends
# data on an established master connection

sub handle_varnish_master_request {
    my ($self, $varnish_master, $request_data) = @_;
    
    $self->debug("handle_varnish_master_request running");
    
    if (! $varnish_master->authenticated()) {
        $self->_new_varnish_authenticate($varnish_master, $request_data);
    }
    if ($varnish_master->authenticated()) {
        $self->_new_varnish_push_params($varnish_master);
        $self->_new_varnish_push_config($varnish_master);
    }
    $varnish_master->initialization_done();
}



sub _new_varnish_authenticate {
    my ($self, $varnish, $data) = @_;
    
    $self->debug("_new_varnish_authenticate running");
    my $response = $self->decode_data_from_varnish_master($data);
    
    die("Expected authentication request from varnish master, " .
            "got " . $response->status() . " instead")
        unless $response->status_is_auth();
    
    $self->debug("Authentication first state"); 
    
    my $secret = $self->secret() or die "No secret configured";
    my $auth_cmd = $self->format_auth_command($response->challenge(),
                                              $self->secret());
    $varnish->put($auth_cmd->to_string());
    $response = $varnish->response();
    
    if ($response->status_is_ok()) {
        $self->debug("Authentication second state"); 
        $varnish->authenticated(1);
    } else {
        die("Authentication failed");
    }
    
    $self->debug("_new_varnish_authenticate returning");
}



sub _new_varnish_push_params {
    my ($self, $varnish) = @_;
    
    $self->debug("_new_varnish_push_params running");

    my $params_file = $self->_config->params_file();
    if (! -r $params_file) {
        $self->debug("Unable to read params file ", $params_file);
        return;
    }
    
    my $params = $self->_read_params();
    $self->debug("Pushing parameters from $params_file to varnish") if $params;
    $self->debug("params: ", Dumper($params));
    for my $p (@$params) {
        my ($name, $value) = @$p;
        my $response =
            $self->run_varnish_command_string($varnish,
                                              "param.set $name $value");
        
        $self->debug("param.set response: ", $response->to_string());
        if ($response->status_is_ok()) {
            $self->debug("Parameter $name = $value set successfully");
        } else {
            $self->warn("Failed to set parameter $name to $value");
        }
    }
}



sub _read_params {
    my $self = shift;
    
    my $param_file = $self->_config->params_file();
    my $data = [];
    
    if (! $param_file || ! -r $param_file) {
        $self->error("Parameter file not configured!")
            unless $param_file;
        $self->error("Unable to read parameter file $param_file!")
            unless -r $param_file;
        return;
    }

    open(my $fh, "$param_file") or die "Can't read params file $param_file: $!";
    while (my $line = <$fh>) {
	chomp $line;
	if ($line =~ /^(\S+?)\s*=\s*(.*)/) {
	    push(@$data, [$1, $2]);
	}
    }
    close $fh;

    return $data;
}



sub _write_params {
    my ($self, $params) = @_;

    my $param_file = $self->_config->params_file();
    open(my $fh, ">$param_file") or die "Can't open params file $param_file: $!";
    
    for my $param (@$params) {
	print $fh "$param->[0] = $param->[1]\n";
    }
    
    close $fh;
}



sub _add_param {
    my ($self, $data, $param, $value) = @_;

    @$data = grep { $_->[0] ne $param } @$data;
    push @$data, [$param, $value];
}



sub _new_varnish_push_config {
    my ($self, $varnish) = @_;

    $self->debug("_new_varnish_push_config running");
    my $vcl_file = $self->_config->vcl_file();
    
    return unless $vcl_file;
    if (! -r $vcl_file) {
        $self->error("Unable to read parameter file $vcl_file!")
            unless -r $vcl_file;
        return;
    }

    eval {
        $self->info("Pushing current vcl to varnish");
        my $vcl_contents = read_file($vcl_file);
        $self->debug("VCL contents: ", Dumper($vcl_contents));
	    
        my $vcl_name = $self->make_vcl_name($vcl_contents);
        my $command = Varnish::VACAgent::DataToVarnish->new(
            command       => "vcl.inline",
            args          => [ $vcl_name ],
            heredoc       => $vcl_contents,
            authenticated => $varnish->authenticated(),
        );
        
        my $response = $self->run_varnish_command($varnish, $command);
        $self->debug("vcl.inline response: ", $response->to_string());
        die("Failed to load VCL") unless $response->status_is_ok();

        $response =
            $self->run_varnish_command_string($varnish, "vcl.use $vcl_name");
        $self->debug("vcl.use response: ", $response->to_string());
        die("Failed to use the VCL") unless $response->status_is_ok();
        
        # $response = $self->run_varnish_command_string($varnish, "start");
        # $self->debug("start response: ", $response->to_string());
        # die("Failed to start varnish") unless $response->status_is_ok();
    };
    if ($@) {
        $self->warn("Agent autoload VCL failed: $@");
    }
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



# Get the VCL with the given name from varnish, return DataToClient

sub _vcl_show {
    my ($self, $session, $vcl_name, $auth) = @_;
    
    my ($vac, $varnish) = ($session->vac(), $session->varnish());
    my $request = $self->format_data_to_varnish("vcl.show $vcl_name", $auth);

    return $self->run_varnish_command($varnish, $request);
}



# Execute given string as a varnish command, return DataToClient
# object. Works only for commands on the form "command arg_1 arg_2 ... arg_n"

sub run_varnish_command_string {
    my ($self, $varnish, $cmdline) = @_;
    
    my ($command, @args) = split('\s+', $cmdline);
    my $cmd = Varnish::VACAgent::DataToVarnish->new(
        command       => $command,
        args          => \@args,
        authenticated => $varnish->authenticated());
    return $self->run_varnish_command($varnish, $cmd);
}



# Execute given command of type DataToVarnish on varnish, return
# DataToClient object

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

    $self->debug("command_param_set called");
    my $response;

    my $session       = $self->get_proxy_session($session_id);
    my $authenticated = $session->authenticated();
    my $varnish       = $session->varnish();
    
    my $params = $self->_read_params();
    my ($param_name, $param_value) = @{$command->args()};
    
    if (! ($param_name && $param_value)) {
        # No comprende. Let Varnish deal with it.
        $response = $self->run_varnish_command($varnish, $command)->to_string();
    } else {
        my $command_string = "param.set $param_name $param_value";
        $response = $self->run_varnish_command_string($varnish, $command_string);
        
        if ($response->status_is_ok()) {
            $self->info("Parameter $param_name = $param_value ",
                        "set successfully");
            $self->_add_param($params, $param_name, $param_value);
            $self->_write_params($params);
        }
    }
    
    return $response;
}



# Example:
# agent.job stats 5
# 200 12
# Job-id: 1

sub command_agent_job {
    my ($self, $command, $session_id) = @_;

    $self->debug("command_agent_job running, command: ", Dumper($command));
    my $response;
    
    $response = $self->_job_manager->start_job($command->args());
    
    return $response;
}




# Lists all the current jobs the agent is running. Each job on one
# line. Each line consists of <job-id><ws><original arguments>
# 
# Example:
# agent.job_list
# 200 <number of bytes>
# 1 stats 5
# 2 something foo

sub command_agent_job_list {
    my ($self, $command, $session_id) = @_;

    $self->debug("command_agent_job_list running, TODO: logic needed");
    
    my $list = $self->_job_manager->list_jobs();
    my $length = bytes::length($list);
    $self->debug("job_list, length: ", $length);
    my $response = Varnish::VACAgent::DataToClient->new(status  => "200",
                                                        length  => $length,
                                                        message => $list);
    return $response;
}



sub command_agent_job_stop {
    my ($self, $command, $session_id) = @_;

    $self->debug("command_agent_job_stop running, TODO: logic needed");
    my $response;
    
    my $response = $self->_job_manager->stop_job($command->args());
    
    return $response;
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
