#!/usr/bin/perl

my $OUTDIR = "output.d";
my $WIDTH = 500;
my $HEIGHT = 1000;
my $SCALE = 76;

# Parse arguments
for (my $i = 0; $i < @ARGV; ++$i) {
    my $c = $ARGV[$i];
    if ($c =~ m/^-/) {
	my $next = $i + 1 < @ARGV;
	if ($c eq "-w" and $next) {
	    $WIDTH = $ARGV[++$i] + 0;
	} elsif ($c eq "-h" and $next) {
	    $HEIGHT = $ARGV[++$i] + 0;
	} elsif ($c eq "-sc" and $next) {
	    $SCALE = $ARGV[++$i] + 0;
	} elsif ($c eq "-o" and $next) {
	    $OUTDIR = $ARGV[++$i];
	} else {
	    printf STDERR "  Ignored argument: %s\n", $c;
	}
    } else {
	printf STDERR "  Ignored argument: %s\n", $c;
    }
}

mkdir $OUTDIR, 0755 if not -e $OUTDIR;

my $IN = \*STDIN;
while (<$IN>) {
    chomp;
    if (m/^STARTCHAR\s+0x([[:xdigit:]]{4})/) {
	my $code = sprintf("%04X", hex($1));
	my @data;
	while (<$IN>) {
	    chomp;
	    push @data, $_;
	    last if m/^ENDCHAR/;
	}
	&proc_glyph($code, \@data);
    }
}

sub proc_glyph
{
    my $code = shift;
    my $data = shift;
    my ($w, $h);
    my @hex;
    my $mode = 0;
    for (@$data) {
	if ($mode == 0) {
	    if (m/^BBX\s+(\d+)\s+(\d+)/) {
		($w, $h) = ($1, $2);
	    } elsif (m/^BITMAP$/) {
		$mode = 1;
	    }
	} else {
	    last if m/^ENDCHAR/;
	    for (m/[[:xdigit:]][[:xdigit:]]/g) {
		push @hex, hex($_);
	    }
	}
    }

    my $dir = substr $code, 0, 2;
    my $dirname = join("/", $OUTDIR, $dir);
    my $filename = join("/", $OUTDIR, $dir, $code.".eps");
    mkdir $dirname, 0755 if not -d $dirname;

    open OUT, ">".$filename;
    binmode OUT;
    print OUT <<"END";
%!PS-Adobe-3.0 EPSF-3.0
%%BoundingBox: 0 0 $WIDTH $HEIGHT
/xy_fillbox {
  2 copy translate
  newpath 0 0 moveto 0 1 lineto 1 1 lineto 1 0 lineto closepath fill
  neg exch neg exch translate
} def
$SCALE $SCALE scale
END
    my $y;
    for ($y = 0; $y < $h; ++$y) {
	my $d = shift @hex;
	my $cnt = 0;
	my $x = 0;
	for ($x = 0; $x < $w; ++$x) {
	    if ($cnt >= 8) {
		$d = shift @hex;
		$cnt = 0;
	    }
	    if ($d >= 128) {
		printf OUT "%d %d xy_fillbox\n", $x, ($h - $y - 1);
	    }
	    $d = ($d * 2) % 256;
	    ++$cnt;
	}
    }
    close OUT;
}
