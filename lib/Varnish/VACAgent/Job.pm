package Varnish::VACAgent::Job;

use Moose;
use 5.010;
use Data::Dumper;

use Reflex::POE::Wheel::Run;
use Reflex::Trait::Watched qw(watches);



extends 'Reflex::Base';



has id => (
    is => 'rw',
    isa => 'Int',
    required => 1,
);

has command => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has parameters => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    required => 1,
    traits => ['Array'],
    handles => {
        all_parameters => 'elements',
    },
);

has manager => (
    is => 'ro',
    isa => 'Varnish::VACAgent::JobManager',
    required => 1,
);

watches child => (
    isa => 'Reflex::POE::Wheel::Run|Undef',
);



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



sub on_child_stdout {
    my ($self, $event) = @_;
    $self->debug("STDOUT: ", $event->octets());
}



sub on_child_close {
    my ($self, $event) = @_;
    
    $self->debug("child closed all output, deleting job ", $self->id());
    $self->manager->delete_job($self->id());
}



sub on_child_signal {
    my ($self, $event) = @_;

    $self->debug("child ", $event->pid(), " exited: ", $event->exit());
    $self->child(undef);
    $self->manager->delete_job($self->id());
}



sub to_string {
    my $self = shift;

    return sprintf("%s %s %s",
                   $self->id(),
                   $self->command(),
                   join(" ", $self->all_parameters()));
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
