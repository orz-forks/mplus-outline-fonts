#!/usr/bin/perl

use EPSCut;

if (@ARGV < 4) {
    print STDOUT <<"__HERE__";
ERROR: Too less arguments
Usage: $0 {INFILE} {OUTFILE} {NROW} {NCOL}
__HERE__
    exit 1;
}
$INFILE = shift;
$OUTFILE = shift;
$NROW = ((shift) + 0);
$NCOL = ((shift) + 0);

if (not -r $INFILE) {
    print STDERR "ERROR: Can't read a file $INFILE\n";
    exit 1;
}

&EPSCut::cut($INFILE, $OUTFILE, $NROW, $NCOL);
exit;
