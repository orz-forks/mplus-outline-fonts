# vim:set ts=8 sts=4 sw=4 tw=0:
#
# Last Change: 23-Jan-2005.
# Maintainer:  MURAOKA Taro <koron@tka.att.ne.jp>

package EPSCut;

my $OUT_SQUARE_SIZE = 1000;
my $RXFLT = "-?\\d+(\\.\\d+)?";

# Cut and get partial EPS in square area from eps.
sub cut
{
    my $nunit = 100;
    return &cut_rectangle(@_[0..3], $nunit, $nunit, $OUT_SQUARE_SIZE / $nunit);
}

# Cut and get partial EPS in rectangle area from eps.
sub cut_rectangle
{
    my $infile = shift;
    my $outfile = shift;
    my $row = shift;
    my $col = shift;
    my $unit_width = shift;
    my $unit_height = shift;
    my $unit_scale = shift;
    # Prepare
    my @size = ($unit_scale * $unit_width, $unit_scale * $unit_height);
    my @range = (
	$col * $unit_width, $row * $unit_height,
	($col + 1) * $unit_width, ($row + 1) * $unit_height
    );
    open IN, $infile;
    open OUT, ">$outfile";
    binmode IN;
    binmode OUT;
    # Skip header.  And replace BoundingBox entry.
    while (<IN>) {
	if (m/^%%BoundingBox:/)
	{
	    &print_eps("%%BoundingBox: 0 0 $size[0] $size[1]\n");
	}
	elsif (m/\bsetlinewidth\b/)
	{
	    s//dup 1 le { pop 0 } if setlinewidth/g;
	    &print_eps($_);
	}
	else
	{
	    &print_eps($_);
	}
	last if $_ =~ m/^%%EndSetup/;
    }
    # Clipping
    while (1) {
	last if eof IN;
	my $in = <IN>;
	$in =~ s/\s+$//; # chomp $in;
	if ($in !~ m/^$RXFLT\s+$RXFLT\s+m$/o) {
	    &print_eps("$in\n");
	    next;
	}
	my @draw_packet = ($in);
	while (1) {
	    my $delete = &check_range($in, \@range);
	    last if eof IN;
	    my $in2 = <IN>;
	    chomp $in2;
	    push @draw_packet, $in2;
	    if ($in2 !~ m/^(n|f)$/) {
		$delete = &check_range($in2, \@range) if $delete == 0;
		next;
	    }
	    if ($1 eq "n" or $delete) {
		$#draw_packet = -1;
	    }
	    last;
	}
	for (@draw_packet) {
	    &print_eps(&shift_scale_round(
		    $_, -$range[0], -$range[1], $unit_scale)."\n");
	}
    }
    close OUT;
    close IN;
    return 1;
}

sub print_eps
{
    for (@_) {
	print OUT $_;
    }
}

sub shift_scale_round
{
    my $in = shift;
    my $dx = shift;
    my $dy = shift;
    my $scale = shift;
    my @data = split / /, $in;
    my $cmd = pop @data;
    my $len = scalar(@data);
    for (my $i = 0; $i < $len; $i += 2) {
	my ($x, $y) = ($data[$i], $data[$i + 1]);
	$x = int(($x + $dx) * $scale);
	$y = int(($y + $dy) * $scale);
	($data[$i], $data[$i + 1]) = ($x, $y);
    }
    return join(" ", @data, $cmd);
}

sub check_range
{
    my $in = shift;
    my $range = shift;
    return 0 if $in !~ m/^($RXFLT\s+)+[a-zA-Z]$/o;
    my @data = split / /, $in;
    pop @data;
    my $len = scalar(@data);
    if ($len % 2 == 1) {
	print STDERR "Odd param in $.\n";
	return 0;
    }
    for (my $i = 0; $i < $len; $i += 2) {
	my ($x, $y) = ($data[$i], $data[$i + 1]);
	if ($range->[0] > $x or $range->[1] > $y
		or $range->[2] < $x or $range->[3] < $y) {
	    return 1;
	}
    }
    return 0;
}

1;
