#!/usr/local/bin/perl

# usage: split-vbearing.pl WEIGHT module_name > set_vert_chars

%names_subst = ( 
    "\"" => "quotedbl",
    "'" =>  "quotesingle",
    "`" =>  "grave",
    "\\" => "backslash",
);

$weight = shift;

@ARGV = grep { -e $_ } map { $_ = "../../../../svg.d/$_/vbearings" } @ARGV;
die "No module specified:" if (scalar @ARGV == 0);

%weight_columns = ( 'black' => 0, 'heavy' => 2, 'bold' => 4, 'medium' => 6, 
		    'regular' => 8, 'light' => 10, 'thin' => 12);
$T = $weight_columns{$weight};
$R = $T+1;

print "Select(\"uni30FB\"); bbox = GlyphInfo(\"BBox\")\n";
print "xcenter = (bbox[0] + bbox[2]) / 2\n";
print "ycenter = (bbox[1] + bbox[3]) / 2\n";
print "AddLookup(\"gsubvert\", \"gsub_single\", 0, [[\"vert\", [[\"kana\", [\"dflt\", \"JAN \"]]]]])\n";
print "AddLookupSubtable(\"gsubvert\", \"j-vert\")\n";
print "\n";

foreach $arg (@ARGV) {
    open(BEARINGS, "<$arg") or die "can't open $arg";
    $cspace = $arg; $cspace =~ s/bearings$/charspaces/;

    while ($_ = <BEARINGS>) {
	next if /^###/ || /^\s*$/;

	my ($ch, $method, @bearings) = split();
	$ch = $names_subst{$ch} if defined $names_subst{$ch};

	print "SetCharCnt(CharCnt() + 1)\n";
	print "Select(\"$ch\"); Copy(); Select(CharCnt() - 1); Paste()\n";
	print "SetGlyphName(\"${ch}.vert\")\n";

	if ($method =~ /R/) {
	    print "Rotate(-90, xcenter, ycenter)\n";
	    if ($method =~ /F/) {
		print "HFlip(); CorrectDirection()\n";
	    }
	}

	if (defined $bearings[$T]) {
	    print "bbox = GlyphInfo(\"BBox\")\n";
	    print ("Move(\$em - bbox[2] + $bearings[$R], \$ascent - bbox[3]+ $bearings[$T])\n");
	    print ("SetWidth(\$em)\n");
	}

	print "Reencode(\"unicode4\")\n";
	print "Select(\"$ch\"); AddPosSub(\"j-vert\", \"${ch}.vert\")\n";
	print "\n";
    }
    close BEARINGS;
}
