#!/usr/bin/perl
# vim:set ts=8 sts=4 sw=4 tw=0:
#
# Last Change: 19-Jan-2005.
# Maintainer:  MURAOKA Taro <koron@tka.att.ne.jp>

use EPSCut;

# Option default values.
my $UNIT_WIDTH = 100;
my $UNIT_HEIGHT = 100;

# Read options.
my @NON_OPTION = @ARGV;
for (my $i = 0; $i < scalar(@ARGV); ++$i)
{
    my $arg = $ARGV[$i];
    my $has_next = $i + 1 < scalar(@ARGV);
    if ($arg =~ m/^-/)
    {
	if ($arg eq '-w' and $has_next)
	{
	    $UNIT_WIDTH = $ARGV[++$i] + 0;
	}
	elsif ($arg eq '-h' and $has_next)
	{
	    $UNIT_HEIGHT = $ARGV[++$i] + 0;
	}
	else
	{
	    &usage("Unknown option: $arg");
	}
    }
    else
    {
	push @NON_OPTION, $arg;
    }
}

# Parse arguments.
if (@NON_OPTION < 4)
{
    &usage("Too less arguments");
}
$INFILE = shift @NON_OPTION;
$OUTFILE = shift @NON_OPTION;
$NROW = ((shift @NON_OPTION) + 0);
$NCOL = ((shift @NON_OPTION) + 0);

# Check input file's existence.
if (not -r $INFILE)
{
    print STDERR "ERROR: Can't read a file $INFILE\n";
    exit 1;
}

&EPSCut::cut($INFILE, $OUTFILE, $NROW, $NCOL);
exit;

sub usage
{
    my $err = shift;
    if ($err ne '')
    {
	print STDOUT "ERROR: $err\n\n";
    }
    print STDOUT <<"__HERE__";
Usage: $0 [OPTIONS] {INFILE} {OUTFILE} {NROW} {NCOL}

Option:
  -w {N}    A block (unit) width. (default 100)
  -h {N}    A block (unit) height. (default 100)
__HERE__
    exit 1;
}
