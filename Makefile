# black, heavy is not designed in monospace fonts, so it's in `ABRIDGED_GROUPS'
UNABRIDGED_GROUPS:=	hiragana1 katakana1 miscellaneous1 \
			hiragana2 katakana2 miscellaneous2 \
			latin_proportional1 latin_proportional2 \
			latin_clear1 latin_clear2 \
			latin_fullwidth1 latin_fullwidth2 \
			latin_full_clear1 latin_full_clear2
ABRIDGED_GROUPS:=	latin_monospace1 latin_monospace2 \
			latin_mono_new1 # latin_mono_new2
OPTIONAL_GROUPS:=	kanji/k1 kanji/k2 kanji/k3 kanji/k4 kanji/k5 kanji/k6 \
			kanji/j1 kanji/j2 kanji/j3 kanji/j4 kanji/j5 \
			kanji/l100 kanji/l101 kanji/l102 kanji/l103 kanji/l104 \
			kanji/l105 kanji/l200 kanji/l201 kanji/l202 kanji/l203 \
			kanji/l204 kanji/l205 kanji/l206 kanji/l207 kanji/l208 \
			kanji/l209 kanji/l210 kanji/l211 kanji/l212 kanji/l213 \
			kanji/l214 kanji/l215 kanji/l216
ifdef MPLUS_FULLSET
UNABRIDGED_GROUPS+=	${OPTIONAL_GROUPS}
endif
GROUPS:=		${UNABRIDGED_GROUPS} ${ABRIDGED_GROUPS}
BLACK_WEIGHTS:=		black heavy
NORMAL_WEIGHTS:=	bold medium regular light thin
WEIGHTS:=		${BLACK_WEIGHTS} ${NORMAL_WEIGHTS}
TARGETS:=		mplus-1p mplus-2p mplus-1m mplus-2m mplus-1c mplus-2c \
			mplus-1mn mplus-2mn

BASELINE_SHIFT:=	58

SPLIT_CONCURRENCY:=	1

all: ttf

ttf: mplus-1p mplus-2p mplus-1m mplus-2m mplus-1c mplus-2c mplus-1mn mplus-2mn

prepare-build: work.d/targets/mplus-1p/Makefile work.d/targets/mplus-2p/Makefile work.d/targets/mplus-1m/Makefile work.d/targets/mplus-2m/Makefile work.d/targets/mplus-1c/Makefile work.d/targets/mplus-2c/Makefile work.d/targets/mplus-1mn/Makefile work.d/targets/mplus-2mn/Makefile split-svgs

mplus-1p: prepare-build
	@(cd work.d/targets/$@ ; $(MAKE))

mplus-2p: prepare-build
	@(cd work.d/targets/$@ ; $(MAKE))

mplus-1m: prepare-build
	@(cd work.d/targets/$@ ; $(MAKE))

mplus-2m: prepare-build
	@(cd work.d/targets/$@ ; $(MAKE))

mplus-1c: prepare-build
	@(cd work.d/targets/$@ ; $(MAKE))

mplus-2c: prepare-build
	@(cd work.d/targets/$@ ; $(MAKE))

mplus-1mn: prepare-build
	@(cd work.d/targets/$@ ; $(MAKE))

mplus-2mn: prepare-build
	@(cd work.d/targets/$@ ; $(MAKE))

work.d/targets/mplus-1p/Makefile: scripts/target-Makefile.1.tmpl dirs
	sed s/^#Mplus-1P#// scripts/target-Makefile.1.tmpl > $@

work.d/targets/mplus-2p/Makefile: scripts/target-Makefile.1.tmpl dirs
	sed s/^#Mplus-2P#// scripts/target-Makefile.1.tmpl > $@

work.d/targets/mplus-1m/Makefile: scripts/target-Makefile.1s.tmpl dirs
	sed s/^#Mplus-1M#// scripts/target-Makefile.1s.tmpl > $@

work.d/targets/mplus-2m/Makefile: scripts/target-Makefile.1s.tmpl dirs
	sed s/^#Mplus-2M#// scripts/target-Makefile.1s.tmpl > $@

work.d/targets/mplus-1c/Makefile: scripts/target-Makefile.1.tmpl dirs
	sed s/^#Mplus-1C#// scripts/target-Makefile.1.tmpl > $@

work.d/targets/mplus-2c/Makefile: scripts/target-Makefile.1.tmpl dirs
	sed s/^#Mplus-2C#// scripts/target-Makefile.1.tmpl > $@

work.d/targets/mplus-1mn/Makefile: scripts/target-Makefile.1s.tmpl dirs
	sed s/^#Mplus-1mN#// scripts/target-Makefile.1s.tmpl > $@

work.d/targets/mplus-2mn/Makefile: scripts/target-Makefile.1s.tmpl dirs
	sed s/^#Mplus-2mN#// scripts/target-Makefile.1s.tmpl > $@

dirs:
	for w in $(NORMAL_WEIGHTS) ; do \
		for g in $(GROUPS) ; do \
			mkdir -p work.d/splitted/$$w/$$g/ ;\
		done ;\
		for t in $(TARGETS); do \
			mkdir -p work.d/targets/$$t/$$w/ ;\
		done \
	done
	for w in $(BLACK_WEIGHTS) ; do \
		for g in $(UNABRIDGED_GROUPS) ; do \
			mkdir -p work.d/splitted/$$w/$$g/ ;\
		done ;\
		for t in $(TARGETS); do \
			mkdir -p work.d/targets/$$t/$$w/ ;\
		done \
	done

ifdef MPLUS_FULLSET
SVGFILES=	svg.d/*/*.svg svg.d/*/*/*.svg
else
SVGFILES=	svg.d/*/*.svg svg.d/*/vert/*.svg
endif

split-svgs: dirs
	perl -I scripts scripts/split-svg.pl $(SPLIT_CONCURRENCY) ${SVGFILES}

clean:
	@rm -rf work.d/ release/mplus-* *~ 

clean-targets:
	@rm -rf work.d/targets/

rebuild-ttf: clean-targets dirs ttf

release: ttf
	@(cd release ; $(MAKE) )
