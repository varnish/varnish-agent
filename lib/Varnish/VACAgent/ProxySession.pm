package Varnish::VACAgent::ProxySession;

use Moose;
use 5.010;
use Data::Dumper;

use Varnish::VACAgent::VarnishClientConnection;



has id => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has vac => (
    is => 'ro',
    isa => 'Varnish::VACAgent::VACClient',
    required => 1,
);

has varnish => (
    is => 'rw',
    isa => 'Maybe[Varnish::VACAgent::VarnishClientConnection]',
    lazy_build => 1,
);

has id => (
    is => 'rw',
    isa => 'Int',
    required => 1,
);



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



sub BUILD {
    my $self = shift;

    $self->varnish(); # Touch it into existence
}



sub _build_varnish {
    my $self = shift;
    
    $self->debug("Creating varnish client connection");
    $self->debug("ProxySession, _config: ", Dumper($self->_config()));
    my $varnish = $self->_connect_to_varnish();
    $self->debug("1");
    my $response = $varnish->response();
    $self->debug("2");
    $self->debug("_build_varnish, response: ",
                 Dumper($response));
    $self->vac->put($response->{data});
    $self->debug("4");
    
    return $varnish;
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
    my $self = shift;

    my $vac = $self->vac();

    # Varnish produces a "welcome message" upon successful
    # connect. Need to read and handle that when a new varnish
    # connection is created.

    my $varnish = $self->varnish();
    
    my $response;
    eval {
        $varnish->put($vac->data());
        
        $response = $varnish->response();
        $self->debug("handle_vac_request, response: ", Dumper($response));
    };
    if ($@) {
        if ($@ =~ /^EOF/) {
            $self->debug("Caught EOF: \"", $@, '"');
            my $agent = Varnish::VACAgent::Singleton::Agent->instance();
            $agent->terminate_proxy_session($self->id());
        } else {
            $self->debug("Caught unknown exception: \"", $@, '"');
        }
    }

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
    
    my $id = $self->id();
    my $address = $self->_config->varnish_address();
    my $port    = $self->_config->varnish_port();
    my $varnish =
        Varnish::VACAgent::VarnishClientConnection->new(proxy_session_id => $id,
                                                        address => $address,
                                                        port => $port);
    $self->varnish($varnish);
    
    return $varnish;
}



sub receive_command_2 {
    my ($self, $socket, $authenticated) = @_;
    
    $self->debug("authenticated=$authenticated");

    # my $line = <$socket>;
    # $self->debug("C->A: ".pretty_line($line));
    # $line = chomp_line($line);
    # my $tmp = $line;
    # my $heredoc = undef;
    # if ($authenticated && $tmp =~ s/ << (\w+)$//) {
    #     # Here-document
    #     my $token = $1;
    #     my $part;
    #     while (1) {
    #         $part = <$socket>
    #     	or die $!;
    #         last if (chomp_line($part) eq $token);
    #         $heredoc .= $part;
    #     }
    # }
    # my @args = unquote($tmp);
    # my $command = shift @args;
    # push @args, $heredoc if defined $heredoc;
    # return {
    #     line => $line,
    #     command => $command,
    #     args => \@args,
    #     heredoc => defined $heredoc ? 1 : 0,
    # };
}



sub terminate {
    my $self = shift;
    
    $self->debug("ProxySession->terminate");
    $self->vac->terminate();
    $self->varnish->terminate();
}



sub DEMOLISH {
    my $self = shift; 
   
    $self->debug("ProxySession ", $self->id(), " demolished");
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
