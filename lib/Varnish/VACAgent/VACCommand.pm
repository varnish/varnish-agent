package Varnish::VACAgent::VACCommand;

use Moose;
use Data::Dumper;



with 'Varnish::VACAgent::Role::Configurable';
with 'Varnish::VACAgent::Role::Logging';



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

has heredoc => (
    is => 'rw',
    isa => 'Maybe[Str]',
    default => undef,
);

has has_heredoc => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has args => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);



sub BUILD {
    my $self = shift;

    my $line= $self->pop_line();
    $self->line($line);

    my $heredoc = $self->get_heredoc();
    if (defined $heredoc) {
        $self->heredoc($heredoc);
        $self->has_heredoc(1);
    }
    
    $line = $self->strip_heredoc_markers($line);
    my @args = unquote($line);
    my $command = shift @args;
    $self->command($command);
    
    push @args, $heredoc if defined $heredoc;
    $self->args(\@args);

    $self->debug("VACCommand::BUILD, result: ", $self->pretty_line(Dumper($self)));
}    



# Split $self->data into first line and rest, return first line and
# remove the returned line from $self->data.

sub pop_line {
    my $self = shift;

    my ($first_line, $rest) = $self->peek_line();
    
    print("pop_line, \$rest: \"", $rest, "\"\n");
    print("pop_line, \$\$rest: \"", $$rest, "\"\n");
    $self->data($$rest);
    
    return $first_line;
}



# Split $self->data into first line and rest, return first line and
# ref to rest. Do not change $self->data.

sub peek_line {
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
        $self->debug("peek_line, first_line: ", $self->pretty_line($first_line),
                     ", rest: ", $self->pretty_line($rest));
    } else {
        die "CLI protocol error: Syntax error";
    }
    
    return ($first_line, \$rest);
}



# Example here-doc:
#
# vcl.load some_vcl_name << LIMITER
# vcl_content
# more vcl_content
# LIMITER

sub get_heredoc {
    my $self = shift;
    
    my $heredoc;
    my $first_line = $self->line(); # First line already loaded into self
    if ($self->authenticated() && $first_line =~ s/\s+<<\s+(\w+)\s*$//) {
	# Here-document
	my $token = $1;
	my $line;
	while (1) {
            $self->debug("data: ", $self->pretty_line($self->data()));
	    $line = $self->pop_line or die "CLI protocol error: Syntax error" .
                ", end of heredoc not found";
            $self->debug("get_heredoc, popped line: ",
                         $self->pretty_line($line));
	    last if $line eq $token;
	    $heredoc .= "$line\n";
	}
    }
    return $heredoc;
}



sub strip_heredoc_markers {
    my ($self, $line) = @_;

    $line =~ s/\s+<<\s+(\w+)\s*$//;

    return $line;
}



# Escape special chars in a string
# TODO: Remove duplication (see VarnishResponse)
sub pretty_line {
    my ($self, $line) = @_;
    
    if (length($line) >= 256) {
	$line = substr($line, 0, 253)."...";
    }
    return Data::Dumper->new([$line])->Useqq(1)->Terse(1)->Indent(0)->Dump;
}



sub unquote {
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



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
