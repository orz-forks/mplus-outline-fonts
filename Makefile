# vim:set ts=8 sts=8 sw=8 tw=0:

default: medium

all: light regular medium bold heavy

light: mplus_skeleton.sfd
	sh scripts/build_ttf.sh light

regular: mplus_skeleton.sfd
	sh scripts/build_ttf.sh regular

medium: mplus_skeleton.sfd
	sh scripts/build_ttf.sh medium

bold: mplus_skeleton.sfd
	sh scripts/build_ttf.sh bold

heavy: mplus_skeleton.sfd
	sh scripts/build_ttf.sh heavy

mplus_skeleton.sfd: mplus_skeleton.tar.bz2
	bzip2 -d -k -c mplus_skeleton.tar.bz2 | tar xf -
	touch mplus_skeleton.sfd

tags:
	ctags scripts/*.pl scripts/*.pm

clean:
	rm -f *.pe
	rm -f *.log
	rm -f mplus-*.sfd
	rm -f *.ttf

distclean: clean
	rm -f mplus_skeleton.sfd
	rm -rf work.d

