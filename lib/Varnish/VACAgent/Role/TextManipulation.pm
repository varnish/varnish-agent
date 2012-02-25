package Varnish::VACAgent::Role::TextManipulation;

use Moose::Role;

use Data::Dumper;



=head1 DESCRIPTION

Text manipulation routines useful to format and print the
VAC<->Varnish protocol.

=cut



# Escape special chars in a string
sub make_printable {
    my ($self, $line) = @_;
    
    if (length($line) >= 256) {
	$line = substr($line, 0, 253)."...";
    }
    return Data::Dumper->new([$line])->Useqq(1)->Terse(1)->Indent(0)->Dump;
}



sub quote {
    use bytes;

    my @r;
    for my $str (@_) {
	$str =~ s/\n/\\n/g;
	$str =~ s/\r/\\r/g;
	$str =~ s/\t/\\t/g;
	$str =~ s/"/\\"/g;
	$str =~ s/([[:^print:]])/sprintf("\\%03o", ord($1))/ge;
	if ($str =~ /\s/) {
	    $str = "\"$str\"";
	}
	push @r, $str;
    }
    return join(' ', @r);
}



sub _unquote {
    use bytes;

    my $str = shift;
    my @r;
    while (length($str)) {
	if ($str =~ s/^\s+//) {
	    # Get rid of white space
	    next;
	} elsif ($str =~ s/^"(.*?)(?<!\\)"//) {
	    # Quoted word
	    push @r, $1;
	    next;
	} elsif ($str =~ /^"[^"]*$/) {
	    # Unbalanced quotes
	    die "Unbalanced quotes";
	} elsif ($str =~ s/^([[:graph:]]+)//) {
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



sub randstring {
    my $len = shift;
    my $str;
    my @chars = ('a'..'z');
    for (my $i = 0; $i < $len; $i++) {
	$str .= $chars[rand @chars];
    }
    return $str;
}



1;

__END__



=head1 AUTHOR

 Sigurd W. Larsen

=cut
