package Varnish::VACAgent::DataToVarnish;

use Moose;
use Data::Dumper;
use Carp qw(croak cluck);



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';



has authenticated => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has data => (
    is => 'rw',
    isa => 'Str',
);

has command => (
    is => 'rw',
    isa => 'Str',
    default => "",
);

has line => (
    is => 'rw',
    isa => 'Str',
    default => "",
);

has heredoc => (
    is => 'rw',
    isa => 'Maybe[Str]',
    default => undef,
);

has heredoc_delimiter => (
    is => 'rw',
    isa => 'Maybe[Str]',
    default => undef,
);

has args => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);



# This class can be built from a string containing a varnish command
# or from individual parameters. If the data parameter is provided, we
# will initialize all the other attributes by parsing it.
sub BUILD {
    my $self = shift;
    
    if ($self->data()) {
        $self->_build_from_data();
    }
    else { # No data, verify at least command has been supplied
        die("Neither data nor command was given to DataToVarnish")
            unless $self->command();
        $self->_build_from_params();
    }
}    



sub _build_from_data {
    my $self = shift;
    
    my $line = $self->_pop_line();
    $self->line($line);

    $self->_extract_heredoc();

    $line = $self->_strip_heredoc_markers($line);
    my @args = _unquote($line);
    my $command = shift @args;
    $self->command($command);
    
    my $heredoc = $self->heredoc();
    push @args, $heredoc if defined $heredoc;
    $self->args(\@args);

    $self->debug("DataToVarnish::BUILD, result: ",
                 $self->make_printable(Dumper($self)));
}



sub _build_from_params {
    my $self = shift;
    
    my $heredoc = $self->heredoc();

    if ($heredoc) { # Create heredoc
        if (! $heredoc =~ /\n$/s) {
            $heredoc .= "\n";
            $self->heredoc($heredoc);
        }

        my $token;
        do { # Create a token that does not occur in the heredoc
            $token = randstring(8);
        } while ($heredoc =~ /$token/);
        
        my $line = quote($self->command(), @{$self->args()}) . " << $token";
        $self->line($line);
        $self->debug("DataToVarnish, line: ", $line);
        $self->heredoc_delimiter($token);
        
    } else {
        my $line = quote($self->command(), @{$self->args()});
        $self->debug("DataToVarnish, line: ", $line);
        $self->line($line);
    }
}



# Split $self->data into first line and rest, return first line and
# remove the returned line from $self->data.

sub _pop_line {
    my $self = shift;

    my ($first_line, $rest) = $self->_peek_line();
    
    $self->debug("_pop_line, \$rest: \"", $rest, "\"\n");
    $self->debug("_pop_line, \$\$rest: \"", $$rest, "\"\n");
    $self->data($$rest);
    
    return $first_line;
}



# Split $self->data into first line and rest, return first line and
# ref to rest. Do not change $self->data.

sub _peek_line {
    my $self = shift;

    my $data = $self->data();
    my $first_line = "";
    my $rest = "";
    
    return ($first_line, \$rest) unless $data;
    
    if ($data =~ m/^([^\x0D\x0A]*?) # Catch one whole line, non-greedily
                   (?:\x0D?\x0A)    # Possibly match but don't catch CRLF
                   (.*)             # catch all the rest
                  /msx) {
        $first_line = $1;
        $rest = $2;
        $self->debug("_peek_line, first_line: ",
                     $self->make_printable($first_line),
                     ", rest: ", $self->make_printable($rest));
    } else {
        cluck();
        die "CLI protocol error: Syntax error, data: ",
            $self->make_printable($data);
    }
    
    return ($first_line, \$rest);
}



# Example here-doc:
#
# vcl.load some_vcl_name << LIMITER
# vcl content
# more vcl content
# LIMITER

sub _extract_heredoc {
    my $self = shift;
    
    my $heredoc;
    my $token;
    my $first_line = $self->line(); # First line already loaded into self

    if ($self->authenticated() && $first_line =~ s/\s+<<\s+(\w+)\s*$//) {
	# Here-document
	$token = $1;
	my $line;
	while (1) {
            $self->debug("data: ", $self->make_printable($self->data()));
	    $line = $self->_pop_line or die "CLI protocol error: Syntax error" .
                ", end of heredoc not found";
            $self->debug("_get_heredoc, popped line: ",
                         $self->make_printable($line));
	    last if $line eq $token;
	    $heredoc .= "$line\n";
	}
    }
    
    if (defined $heredoc) {
        $self->heredoc($heredoc);
        $self->heredoc_delimiter($token);
    }
}



sub _strip_heredoc_markers {
    my ($self, $line) = @_;

    $line =~ s/\s+<<\s+(\w+)\s*$//;

    return $line;
}



sub to_string {
    my ($self, $varnish) = @_;
    
    my $string;
    
    if (my $line = $self->line()) {
	$self->debug("A->V: " . $line);
        $string .= $line . "\n";
        my $heredoc = $self->heredoc();
	if ($heredoc) {
	    $string .= $heredoc;
	    $string .= $self->heredoc_delimiter() . "\n";
	}
    } else {
        die "Unexpected state in to_string: No \$self->line";
    }
    
    return $string;
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
