#!/usr/bin/perl

use UCSTable;
use File::Copy;

my @INDIR;
my $OUTDIR = "bdf_iso10646-1";
my $ENCODE;
my $BASEDIR;

for (my $i = 0; $i < @ARGV; ++$i) {
    if ($ARGV[$i] =~ m/^-/ and $i + 1 < @ARGV) {
	if ($ARGV[$i] = "-e") {
	    $ENCODE = $ARGV[++$i];
	}
    } elsif (-d $ARGV[$i]) {
	$BASEDIR = $ARGV[$i];
	opendir LS, $ARGV[$i];
	while (my $dir = readdir LS) {
	    push @INDIR, $dir if $dir =~ /^[[:xdigit:]]{2}$/;
	}
	closedir LS;
	last;
    }
}
if (@INDIR == 0) {
    exit 1;
}
$ENCODE ||= "8859-1";
if (not -e $OUTDIR) {
    mkdir $OUTDIR, 0755;
}

printf "Proc %s ...\n", $BASEDIR;
my $cnt = 0;
for my $dir (@INDIR) {
    printf "  %s/%s\n", ++$cnt, scalar(@INDIR);
    my $ut = new UCSTable($ENCODE);
    $dir = join("/", $BASEDIR, $dir);
    opendir LS, $dir;
    my @ls = grep { m/^[[:xdigit:]]{4}\.eps$/; } readdir LS;
    closedir LS;
    for my $name (@ls) {
	next if $name !~ m/^([[:xdigit:]]{4}).eps$/;
	my $f_code = $1;
	my $f_name = join("/", $dir, $name);
	my $t_code = $ut->get($f_code);
	if (not defined $t_code) {
	    print "Can't map $f_name\n";
	    next;
	}
	my $t_dir = substr(sprintf("%04X", $t_code), 0, 2);
	my $t_name = join("/", $OUTDIR, $t_dir, sprintf("u%04X.eps", $t_code));
	my $t_dir = join("/", $OUTDIR, $t_dir);
	mkdir $t_dir, 0755 if not -d $t_dir;
	if (-e $t_name) {
	    printf "Overwrite %s by %s\n", $t_name, $f_name;
	}
	copy($f_name, $t_name, 1);
    }
}

