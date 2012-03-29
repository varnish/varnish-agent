package Varnish::VACAgent::JobManager;

use Moose;
use 5.010;
use Data::Dumper;

use Varnish::VACAgent::Job::SystemStats;



has _next_job_id => (
    is => 'rw',
    isa => 'Int',
    default => 1,
);

has _job_list => (
    is => 'rw',
    isa => 'HashRef[Varnish::VACAgent::Job]',
    default => sub {{}},
    traits => ['Hash'],
    handles => {
        delete_job   => 'delete',
        _job_ids     => 'keys',
        _add_job     => 'set',
        _get_job     => 'get',
    },
);

has _accepted_commands => (
    is => 'ro',
    isa => 'HashRef[Str]',
    builder => '_build_accepted_commands',
    traits => ['Hash'],
    handles => {
        _command_is_recognized => 'exists',
        _get_command_class     => 'get',
    },
);



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';
with 'Varnish::VACAgent::Role::VarnishCLIConstants';



sub _build_accepted_commands {
    my $self = shift;

    my $commands = {
        # stats        => 'Varnish::VACAgent::Job::Stats',
        systemstats  => 'Varnish::VACAgent::Job::SystemStats',
        # varnishlog   => 'Varnish::VACAgent::Job::VarnishLog',
        # varnishtop   => 'Varnish::VACAgent::Job::VarnishTop',
        # varnishhist  => 'Varnish::VACAgent::Job::VarnishHist',
    };
    
    return $commands;
}



sub list_jobs {
    my $self = shift;

    my $response = "";
    for my $job_number ($self->_job_ids()) {
        $response .= $self->_get_job($job_number)->to_string() . "\n";
    }
    return $response;
}



sub start_job {
    my ($self, $args) = @_;

    my ($command, @params) = @$args;
    
    if (! $self->_command_is_recognized($command)) {
        my $msg = "Unrecognized command: $command\n";
        return Varnish::VACAgent::DataToClient->new(
            message => $msg,
            length  => bytes::length($msg),
            status  => $self->CLI_STATUS_PARAM()
        );
    }
    
    my $job_id = $self->_register_job_id();
    my $handler_class = $self->_get_command_class($command);
    
    $self->debug("Trying to load $handler_class");
    require(join('/', split(/::/, $handler_class)) . '.pm');
    my $job = $handler_class->new(id         => $job_id,
                                  command    => $command,
                                  parameters => \@params,
                                  manager    => $self);
    $self->_add_job($job_id => $job);
    $job->run();
    
    my $msg = "Job-id: $job_id";
    return Varnish::VACAgent::DataToClient->new(
        message => $msg,
        length  => bytes::length($msg),
        status  => $self->CLI_STATUS_OK(),
    );
}



sub stop_job {
    my ($self, $args) = @_;

    my ($id) = @$args;
    my $job = $self->_get_job($id);

    if (! $job) {
        my $msg = "No such job: $id\n";
        return Varnish::VACAgent::DataToClient->new(
            message => $msg,
            length  => bytes::length($msg),
            status  => $self->CLI_STATUS_PARAM()
        );
    }
    
    $self->delete_job($id);

    return Varnish::VACAgent::DataToClient->new(
        message => "",
        length => 0,
        status => $self->CLI_STATUS_OK()
    );
}



sub _register_job_id {
    my ($self) = @_;

    my $job_id = $self->_next_job_id();
    $self->_next_job_id($job_id + 1);
    
    return $job_id;
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
