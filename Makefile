GROUPS:=	hiragana1 katakana1 miscellaneous1 latin_proportional \
		hiragana2 katakana2 miscellaneous2 # latin_halfwidth
WEIGHTS:=	black heavy bold medium regular light thin
TARGETS:=	mplus-1p mplus-2p # mplus-1m mplus-2m

BASELINE_SHIFT:=	58

all: split-svgs ttf

ttf: work.d/targets/mplus-1p/Makefile work.d/targets/mplus-2p/Makefile
	@(cd work.d/targets/mplus-1p ; make )
	@(cd work.d/targets/mplus-2p ; make )
#	@(cd work.d/targets/mplus-1m ; make )
#	@(cd work.d/targets/mplus-2m ; make )

work.d/targets/mplus-1p/Makefile: scripts/target-Makefile.1.tmpl 
	sed s/^#Mplus-1P#// scripts/target-Makefile.1.tmpl > $@

work.d/targets/mplus-2p/Makefile: scripts/target-Makefile.1.tmpl 
	sed s/^#Mplus-2P#// scripts/target-Makefile.1.tmpl > $@

#work.d/targets/mplus-1M/Makefile: scripts/target-Makefile.1.tmpl 
#	sed s/^#Mplus-1M#// scripts/target-Makefile.1.tmpl > $@
#
#work.d/targets/mplus-2M/Makefile: scripts/target-Makefile.1.tmpl 
#	sed s/^#Mplus-2M#// scripts/target-Makefile.1.tmpl > $@

dirs:
	for w in $(WEIGHTS) ; do \
		for g in $(GROUPS) ; do \
			mkdir -p work.d/splitted/$$w/$$g/ ;\
		done ;\
		for t in $(TARGETS); do \
			mkdir -p work.d/targets/$$t/$$w/ ;\
		done \
	done

split-svgs: dirs
	perl -I scripts scripts/split-svg.pl svg.d/*/*.svg
	for w in $(WEIGHTS) ; do \
		for g in $(GROUPS) ; do \
			expr 0 + `cat svg.d/$$g/baseline` + ${BASELINE_SHIFT} > work.d/splitted/$$w/$$g/baseline ;\
		done \
	done

clean:
	@rm -rf work.d/ *~ 

clean-targets:
	@rm -rf work.d/targets/

rebuild-ttf: clean-targets dirs ttf

