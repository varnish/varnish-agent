package Varnish::VACAgent::VACCommand;

use Moose;
use Data::Dumper;
use Carp qw(croak cluck);



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';
with 'Varnish::VACAgent::Role::TextManipulation';



has data => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has authenticated => (
    is => 'ro',
    isa => 'Str',
    required => 1,
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

has has_heredoc => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
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



sub BUILD {
    my $self = shift;

    my $line= $self->_pop_line();
    $self->line($line);

    $self->_extract_heredoc();

    $line = $self->_strip_heredoc_markers($line);
    my @args = _unquote($line);
    my $command = shift @args;
    $self->command($command);
    
    my $heredoc = $self->heredoc();
    push @args, $heredoc if defined $heredoc;
    $self->args(\@args);

    $self->debug("VACCommand::BUILD, result: ",
                 $self->make_printable(Dumper($self)));
}    



# Split $self->data into first line and rest, return first line and
# remove the returned line from $self->data.

sub _pop_line {
    my $self = shift;

    my ($first_line, $rest) = $self->_peek_line();
    
    print("_pop_line, \$rest: \"", $rest, "\"\n");
    print("_pop_line, \$\$rest: \"", $$rest, "\"\n");
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
# vcl_content
# more vcl_content
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
        $self->has_heredoc(1);
        $self->heredoc_delimiter($token);
    }
}



sub _strip_heredoc_markers {
    my ($self, $line) = @_;

    $line =~ s/\s+<<\s+(\w+)\s*$//;

    return $line;
}



sub _unquote {
    use bytes;

    my $s = shift;
    my @r;
    while (length($s)) {
	if ($s =~ s/^\s+//) {
	    # Get rid of white space
	    next;
	} elsif ($s =~ s/^"(.*?)(?<!\\)"//) {
	    # Quoted word
	    push @r, $1;
	    next;
	} elsif ($s =~ /^"[^"]*$/) {
	    # Unbalanced quotes
	    die "Unbalanced quotes";
	} elsif ($s =~ s/^([[:graph:]]+)//) {
	    # Unquoted word
	    push @r, $1;
	    next;
	}
    }

    for my $r (@r) {
	$r =~ s/\\\\/!"magic#/g;
	$r =~ s/\\n/\n/g;
	$r =~ s/\\r/\r/g;
	$r =~ s/\\t/\t/g;
	$r =~ s/\\"/"/g;
	$r =~ s/\\([0-7]{1,3})/chr(oct($1))/ge;
	$r =~ s/\\x([0-9a-fA-F]{2})/chr(hex($1))/ge;
	$r =~ s/!"magic#/\\/g;
    }

    return @r;
}



sub to_string {
    my ($self, $varnish) = @_;
    
    my $string;
    
    if (my $line = $self->line()) {
	$self->debug("A->V: " . $line);
        $string .= $line . "\n";
	if ($self->has_heredoc()) {
	    $string .= $self->heredoc();
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
