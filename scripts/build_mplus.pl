#!/usr/bin/perl
# vim:set ts=8 sts=4 sw=4 tw=0:
#
# Last Change: 23-Jan-2005.
# Maintainer:  MURAOKA Taro <koron@tka.att.ne.jp>

use strict;
use lib "scripts";
use Carp;
use Data::Dumper;
use File::Basename;
use File::Path;
use Codemap;
use EPSCut;
use PESGenerator;

# Parameters
my @today = localtime;
my ($YEAR, $MONTH, $DAY) = ($today[5] + 1900, $today[4] + 1, $today[3]);
my $INDIR = './eps.d';
my $WORKDIR = './work.d';
my (@WEIGHTS, %WEIGHTS);
my $VERBOSE_LEVEL = 0;
$config::FONT_BASENAME = 'mplus';
$config::FONT_SKELETON = 'mplus_skeleton.sfd';
$config::FONT_COPYRIGHT = "Copyright (C) $YEAR M+ Font Project";
# Constants
my %WEIGHT_TABLE = (
    'thin' => 6,
    'light' => 5,
    'regular' => 4,
    'medium' => 3,
    'bold' => 2,
    'heavy' => 1,
    'black' => 0,
);
my $WEIGHT_DEFAULT = 'medium';
my $FILENAME_DATADIRS = 'datadirs';

# Parse ARGV
for (my $i = 0; $i < @ARGV; ++$i) {
    my $arg = $ARGV[$i];
    my $next = $i + 1 < @ARGV;
    if (0) {
    } elsif ($arg eq '-v' or $arg eq '--verbose') {
	if ($next and $ARGV[$i + 1] =~ /^\d+$/) {
	    $VERBOSE_LEVEL = $ARGV[$i + 1] + 0;
	    ++$i;
	} else {
	    ++$VERBOSE_LEVEL;
	}
    } elsif ($next and ($arg eq '-w' or $arg eq '--weight')) {
	my $w = $ARGV[$i + 1];
	for my $w (split /,/, $ARGV[$i + 1]) {
	    if (exists $WEIGHT_TABLE{$w}) {
		$WEIGHTS{$w} = 1;
	    } else {
		croak "Unsupported weight: $w\n";
	    }
	}
	++$i;
    } else {
	croak "Can't recognize argument: $arg\n";
    }
}
# Post parsing check
@WEIGHTS = keys %WEIGHTS;
if (scalar(@WEIGHTS) < 1) {
    push @WEIGHTS, $WEIGHT_DEFAULT;
}
@WEIGHTS = sort { $WEIGHT_TABLE{$b} <=> $WEIGHT_TABLE{$a} } @WEIGHTS;

# Correct codemap files
my $datadirs = &get_datadirs($INDIR, $FILENAME_DATADIRS);
my %codemaps;
for my $datadir (@$datadirs) {
    my $codemap = new Codemap($datadir);
    $codemaps{$datadir} = $codemap;
}

for my $weight (@WEIGHTS) {
    # Generate separated EPS files for each weights.
    &log_writeline(0, "Updating separated EPS for: $weight");
    &log_indent();
    my $mtime_table = &generate_eps_for_weight(\%codemaps, $weight);
    &log_unindent();
    # Generate PfaEdit scirpt to build font.
    &log_writeline(0, "Generate PfaEdit script for: $weight");
    &log_indent();
    my $fontname = sprintf('%s-%s', $config::FONT_BASENAME, $weight);
    my ($input_sfd, $output_sfd) = ($config::FONT_SKELETON, $fontname.'.sfd');
    if (-e $output_sfd) {
	$input_sfd = $output_sfd;
    }
    my $mtime_input_sfd = &get_mtime($input_sfd);
    my $generator = new PESGenerator(
	-basename => $config::FONT_BASENAME,
	-fontname => $fontname,
	-weight => $weight,
	-copyright => $config::FONT_COPYRIGHT,
	-input_sfd => $input_sfd,
	-output_sfd => $output_sfd,
	-offset => [0, -200],
    );
    for my $input_eps (sort keys %$mtime_table) {
	if ($mtime_table->{$input_eps} > $mtime_input_sfd) {
	    $generator->add($input_eps);
	}
    }
    $generator->save($fontname.'.pe');
    &log_unindent();
}
exit 0;

my $_log_indent_level = 0;
my $_log_indent = '';

sub log_writeline
{
    my $level = shift;
    my $message = shift;
    if ($level <= $VERBOSE_LEVEL) {
	print $_log_indent, $message, "\n";
    }
}

sub log_indent
{
    ++$_log_indent_level;
    $_log_indent = '    ' x $_log_indent_level;
}

sub log_unindent
{
    --$_log_indent_level if $_log_indent_level > 0;
    $_log_indent = '    ' x $_log_indent_level;
    return $_log_indent_level;
}

sub ensure_basedir
{
    my $path = shift;
    my $dir = dirname($path);
    if (-d $dir) {
	return 1;
    } else {
	return scalar(mkpath([$dir], 0, 0755)) > 0;
    }
}

sub get_mtime
{
    my $path = shift;
    if (-e $path) {
	return (stat $path)[9];
    } else {
	return 0;
    }
}

sub get_output
{
    my $dir = shift;
    my $weight_name = shift;
    my $code = shift;
    return join('/', $dir, $weight_name, substr($code, 0, 3), $code.'.eps');
}

sub get_datadirs
{
    my $dir = shift;
    my $filename = shift;
    my $path = join('/', $dir, $filename);
    my @datadirs = ();
    open DATADIRS, $path or croak "Can't find datadirs file $path\n";
    while (<DATADIRS>) {
	chomp;
	my $dirpath = join('/', $dir, $_);
	if (-d $dirpath) {
	    push @datadirs, $dirpath;
	}
    }
    close DATADIRS;
    return \@datadirs;
}

sub generate_eps
{
    my $mtime_table = shift;
    my $weight = shift;
    my $src = shift;
    my $src_mtime = shift;
    my $col = shift;
    my $code = shift;
    my $dst = &get_output($WORKDIR, $weight, $code);
    my $dst_mtime = &get_mtime($dst);
    my $row = $WEIGHT_TABLE{$weight};
    if ($dst_mtime < $src_mtime) {
	&ensure_basedir($dst);
	&EPSCut::cut($src, $dst, $row, $col);
	$dst_mtime = &get_mtime($dst);
	&log_writeline(3, "$dst updated");
    } else {
	&log_writeline(3, "$dst skipped");
    }
    $mtime_table->{$dst} = $dst_mtime;
}

sub generate_eps_for_weight
{
    my $codemaps = shift;
    my $weight = shift;
    my %mtime_table;
    for my $datadir (sort keys %$codemaps) {
	my $codemap = $codemaps->{$datadir};
	my $keys = $codemap->keys;
	&log_writeline(1, "$datadir");
	&log_indent();
	for my $src (@$keys) {
	    my $src_mtime = &get_mtime($src);
	    &log_writeline(2, "$src");
	    &log_indent();
	    my $codes = $codemap->get_codes($src);
	    # Output all codes in combined EPS.
	    for (my $col = 0; $col < @$codes; ++$col) {
		my $code = $codes->[$col];
		if (ref($code) eq 'ARRAY') {
		    for my $c (@$code) {
			&generate_eps(\%mtime_table, $weight, $src, $src_mtime, $col, $c);
		    }
		} else {
		    &generate_eps(\%mtime_table, $weight, $src, $src_mtime, $col, $code);
		}
	    }
	    &log_unindent();
	}
	&log_unindent();
    }
    return \%mtime_table;
}

