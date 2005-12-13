package SVG;

use strict;
use Carp;

my @weights = qw(black heavy bold medium regular light thin);

$SVG::em = 100;	# em-size in SVG.

sub new {
    my $class = shift;
    my $filename = shift;

    open(SVGFILE, "<$filename") or croak "can't open SVG file $filename";
    my $svg = join("", <SVGFILE>);
    close(SVGFILE);
    $svg = _preprocess_svg($svg);

    my $mapdir = _codemap_dirname($filename);
    my $codemap = new Codemap($mapdir);
    my $keys = $codemap->keys($mapdir);
    my $codes = $codemap->get_codes($filename);
    my $dumpdir = undef;
    my $logfilename = undef;

    my @frames = _get_frames($svg);
    my @cols = _uniq(sort { $a <=> $b } map {$_->[0]} @frames);
    my @rows = _uniq(sort { $b <=> $a } map {$_->[1]} @frames);

    if ($#$codes > $#cols) {
	croak "number of codes exceeds the number of columns: ";
    } elsif ($#rows > 6) {
	croak "too many rows (max = 7: thin, light, ..., black): ";
    }

    my $this = bless {
	codes => $codes,
	filename => $filename,
	svg => $svg,
	frames => \@frames,
	rows => \@rows,
	cols => \@cols,
	dumpdir => $dumpdir,
	logfilename => $logfilename,
    }, $class;
    return $this;
}

sub clone {
    my $this = shift;

    my $clone = bless {
	codes => $this->{codes},
	filename => $this->{filename},
	svg => $this->{svg},
	frames => $this->{frames},
	rows => $this->{rows},
	cols => $this->{cols},
	logfilename => $this->{logfilename},
	dumpdir => $this->{dumpdir},
    };
    return $clone;
}

sub clip {
    my $this = shift;
    my $row = shift;
    my $col = shift;

    my ($weight, $unicode);
    my $region = undef;
    for (my $i = 0; $i <= $#{$this->{frames}}; $i++) {
	my $reg = $this->{frames}->[$i];
	if ($reg->[0] == $this->{cols}->[$col] && 
	    $reg->[1] == $this->{rows}->[$row]) {
	    $region = $reg;
	    last;
	}
    }
    $this->{svg} =~ s/<\s*path\s/<PATH /g;
    while ($this->{svg} =~ s/(<\s*PATH\b[^>]*>)/_select_path($1,$region)/se) {
	;
    }
    $this->{svg} =~ s/<\s*polygon\s/<POLYGON /g;
    while ($this->{svg} =~ s/(<\s*POLYGON\b[^>]*>)/_select_poly($1,$region)/se) {
	;
    }
    $this->{svg} =~ s/<\s*rect\s([^>l]*\/>)/<RECT $1/g; 	# without 'fill="none"'
    while ($this->{svg} =~ s/(<\s*RECT\b[^>]*>)/_select_rect($1,$region)/se) {
	;
    }
    $this->{svg} = _set_region($this->{svg}, $region->[2], $region->[3]);
    $this->{svg} =~ s/<rect\b[^<>]*?fill\s*=\s*\"none\".*?>//sg;

    return $this;
}

sub modtime {
    my $this = shift;
    my @stat = stat($this->{filename});
    return $stat[9];
}

sub splittime {
    my $this = shift;
    my @stat = stat($this->{logfilename});
    if (defined @stat) {
	return $stat[9];
    } else {
	return 0;
    }
}

sub setdumpdir {
    my $this = shift;

    my $topdir = shift;
    mkdir $topdir unless -e $topdir;

    my $dumpdir = "$topdir/splitted";
    mkdir $dumpdir unless -e $dumpdir;
    $this->{dumpdir} = $dumpdir;

    my $logfile = $this->{filename}; $logfile =~ tr/\//_/;
    $logfile = "$dumpdir/log/split_done." . $logfile;
    mkdir "$dumpdir/log" unless -e "$dumpdir/log";
    $this->{logfilename} = $logfile;
}

sub dump {
    my $this = shift;
    my $dumpdir = $this->{dumpdir};
    croak "destinaton dir not specified" if ($dumpdir eq '');

    my $subdir = _codemap_dirname($this->{filename});
    $subdir =~ s/^[^\/]*\///g;

    for (my $col = 0; $col <= $#{$this->{cols}}; $col++) {
	my $dir = "$dumpdir/$weights[$col]";
	mkdir $dir unless -e $dir;
	for (my $row = 0; $row <= $#{$this->{rows}}; $row++) {
	    $dir = "$dumpdir/$weights[$row]";
	    mkdir $dir unless -e $dir;
	    my $outdir = "$dumpdir/$weights[$row]/$subdir";
	    mkdir $outdir unless -e $outdir;
	    my $tmp = clip(clone($this), $row, $col);

	    my @outfiles = ();
	    unless (ref $this->{codes}->[$col]) {
		@outfiles = ("$outdir/$this->{codes}->[$col].svg");
	    } else {
		@outfiles = map { "$outdir/$_.svg"} @{$this->{codes}->[$col]};
	    }
	    foreach my $out (@outfiles) {
		_dump_svg_file($out, $tmp->{svg});
	    }
	}
    }

    my $logfile = $this->{logfilename};
    open(LOG, ">$logfile") or croak "can't create log file $logfile";
    print LOG "@{$this->{codes}}\n";
    close LOG;
}

#------------------------------------------------------------------------

sub _dump_svg_file {
    my $filename = shift;
    my $contents = shift;

    open(OUT, ">$filename") or die "can't create splitted SVG file $filename";
    print OUT $contents;
    close OUT;
}

sub _codemap_dirname {
    my $name = $_[0];
    $name =~ s/\/?[^\/]*$//;
    $name =~ s/u[[:xdigit:]]{2}\/?$//;
    $name = "." if $name eq "";
    return $name;
}

sub _preprocess_svg {
    my $svg = shift;
    # shut up libxml2
    $svg =~ s#xmlns="\&ns_svg;\"#xmlns=\"http://www.w3.org/2000/svg\"#gs;
    $svg =~ s#<rdf:RDF.*?</rdf:RDF>##gs;
    return $svg;
}

sub _uniq {
    my @ret = shift @_;

    foreach my $n (@_) {
	push(@ret, $n) unless ($ret[$#ret] == $n);
    }
    return @ret;
}

sub _get_property {
    my ($tag, $property_name) = @_;

    if ($tag =~ m/\s${property_name}\s*=\s*\"([^\"]+)\"/) { 
        return $1;
    } else {
	return undef;
    }
}

# frame (塗りつぶしのない rect) の一覧を獲得
sub _get_frames {
    my @rectangles;
    my $svg = $_[0];

    while ($svg =~ s/<\s*rect\b[^>]*fill\s*=\s*\"none\"[^>]*>//s) {
	my $rect = $&;
	my @array = (_get_property($rect, "x"),
		     _get_property($rect, "y"),
		     _get_property($rect, "width"),
		     _get_property($rect, "height"));
	push(@rectangles, \@array);
    }
    # 横書き順にソート
    return sort { $a->[0] <=> $b->[0] || $b->[1] <=> $a->[1] } @rectangles;
}

sub _select_path {
    my ($path, $region) = @_;
    my ($minx, $miny, $maxx, $maxy) = ($region->[0], $region->[1],
				       $region->[0] + $region->[2],
				       $region->[1] + $region->[3]);
    my ($x, $y);
    if ($path =~ m/\sd\s*=\s*\"[Mm]\s*([-+\d.]*)[,\s]+([-+\d.]*)/) {
	($x, $y) = ($1, $2);
        if ($minx <= $x && $x <= $maxx &&
	    $miny <= $y && $y <= $maxy) {
	    $path =~ s/PATH/path/s;
	    return _move_path($path, -$minx, -$miny);
	} else {
	    return "<!-- out of boundary -->";
	}
    }
    return "<!-- no match -->";
}

sub _select_poly {
    my ($poly, $region) = @_;
    my ($minx, $miny, $maxx, $maxy) = ($region->[0], $region->[1],
				       $region->[0] + $region->[2],
				       $region->[1] + $region->[3]);
    if ($poly =~ m/\spoints\s*=\s*\"\s*(.*?)\s*\"/s) {
	my @points = split /\s*,\s*|\s+/, $1;
	if ($minx <= $points[0] && $points[0] <= $maxx &&
	    $miny <= $points[1] && $points[1] <= $maxy) {
	    my $i;
	    for ($i = 0; $i <= $#points; $i++) {
		$points[$i] -= ($i % 2 == 0) ? $minx : $miny;
	    }
	    my $tmp = join(' ', @points);	 # ff-20051012 require that
	    $tmp =~ s/(\S+)\s+(\S+)/$1,$2/sg;    # x,y are separated by comma
	    return "<polygon points=\"$tmp\"/>"; # and points by spaces.
	} else {
	    return "<!-- out of boundary -->";
	}
    }
    return "<!-- no match -->";
}

sub _transform {
    my ($x, $y, @trans) = @_;

    return ($trans[0]*$x+$trans[2]*$y+$trans[4],
	    $trans[1]*$x+$trans[3]*$y+$trans[5]);
}

sub _select_rect {
    my ($rect, $region) = @_;
    my ($minx, $miny, $maxx, $maxy) = ($region->[0], $region->[1],
				       $region->[0] + $region->[2],
				       $region->[1] + $region->[3]);
    if ($rect =~ m/<\s*RECT\b[^>]*>/s) {
	my $x = _get_property($rect, "x");
	my $y = _get_property($rect, "y");
	my ($X, $Y) = ($x, $y);
	my $trans = _get_property($rect, "transform");
	my @tmat;
	if (defined $trans) {
	    $trans =~ s/matrix\((.*)\)/$1/;
	    @tmat = split / /, $trans;
	    ($X, $Y) = _transform($x, $y, @tmat);
	}
	if ($minx <= $X && $X <= $maxx && $miny <= $Y && $Y <= $maxy) {
	    my $w = _get_property($rect, "width");
	    my $h = _get_property($rect, "height");
	    if (!defined $trans) {
		$x -= $minx;
		$y -= $miny;
		return "<rect x=\"$x\" y=\"$y\" width=\"$w\" height=\"$h\"/>";
	    } else {
		$tmat[4] -= $minx;
		$tmat[5] -= $miny;
		return "<rect x=\"$x\" y=\"$y\" width=\"$w\" height=\"$h\" transform=\"matrix(@tmat)\"/>";
	    }
	} else {
	    return "<!-- out of boundary -->";
	}
    }
    return "<!-- no match -->";
}

sub _move_path {
    my ($path, $xshift, $yshift) = @_;
    return $path unless ($path =~ m/\sd\s*=\s*\"([^\"]+)\"/s);
    my ($pre, $d, $post) = ($`, $1, $');
    my $shifted = '';
    my $absolute = 0;
    my ($lastcmd, $pnum);

    $d =~ s/[a-zA-Z]/ $& /sg;
    $d =~ s/(?![eE])([+-])/ $1/sg;
    $d =~ s/^\s*(.*?)\s*$/$1/sg;
    my @d = split /\s*,\s*|\s+/, $d;

    foreach my $p (@d) {
	if ($p =~ /^[A-Z]/) { $absolute = 1; $lastcmd = $p; $pnum = 0;}
	elsif ($p =~ /^[a-z]/) { $absolute = 0; $lastcmd = $p; $pnum = 0;}
	elsif ($absolute) {
	    if ($lastcmd eq 'H') {
		$p += $xshift;
	    } elsif ($lastcmd eq 'V') {
		$p += $yshift;
	    } elsif ($pnum % 2 == 1) {
		$p += $yshift;
	    } else {
		$p += $xshift;
	    }
	    $pnum++;
	}
	$shifted .= $p;
	$shifted .= ' ' unless $shifted =~ /^[Zz]/;
    }
    return "$pre d=\"$shifted\" $post";
}

sub _set_region {
    my ($svg, $w, $h) = @_;
    $svg =~ m/<svg\s[^>]*>/s;
    my ($pre, $tag, $post) =  ($`, $&, $');
    my $em = $SVG::em;

#    $tag =~ s/\sviewBox\s*=\s*\"[^"]*\"/" viewBox=\"0 0 $w $w\""/es;
    $tag =~ s/\sviewBox\s*=\s*\"[^"]*\"/" viewBox=\"0 0 $em $em\""/es;
    $tag =~ s/\si:viewOrigin\s*=\s*\"[^"]*\"/" i:viewOrigin=\"0 0\""/es;
    $tag =~ s/\swidth\s*=\s*\"[^"]*\"/" width=\"$w\""/es;
    $tag =~ s/\sheight\s*=\s*\"[^"]*\"/" height=\"$w\""/es; # width justified

    return $pre . $tag . $post;
}

1;
