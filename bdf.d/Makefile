# vim:set ts=8 sts=8 sw=8 tw=0:
#
# Last Change: 09-Jun-2004.
# Maintainer:  MURAOKA Taro <koron@tka.att.ne.jp>

default: mplus_j12b.bdf mplus_j10b.bdf

mplus_j12b.bdf: mplus_j12r.bdf
	perl ../scripts/mkbold.pl mplus_j12r.bdf > $@

mplus_j10b.bdf: mplus_j10r.bdf
	perl ../scripts/mkbold.pl mplus_j10r.bdf > $@

distclean:
	rm -f mplus_j12b.bdf
	rm -f mplus_j10b.bdf

