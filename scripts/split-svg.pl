use File::Basename;
use File::Path;

use Codemap;
use SVG;

foreach $orig_svg (@ARGV) {
    my $svg = new SVG($orig_svg);
    $svg->setdumpdir("work.d");
    if ($svg->modtime() > $svg->splittime()) {
	$svg->dump();
	print STDERR "  $svg->{filename} : splitted\n" unless defined $silent;
    } else {
	print STDERR "  $svg->{filename} : SKIP\n" unless defined $silent;
    }
}
