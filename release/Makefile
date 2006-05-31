TESTFLIGHT_VER= 012a

RELEASE=	mplus-TESTFLIGHT-${TESTFLIGHT_VER}

FILES=	LICENSE_E LICENSE_J README_J m++ipa.pe

FONTS=	../work.d/targets/mplus-1p/black/mplus-1p-black.ttf \
	../work.d/targets/mplus-1p/heavy/mplus-1p-heavy.ttf \
	../work.d/targets/mplus-1p/bold/mplus-1p-bold.ttf \
	../work.d/targets/mplus-1p/medium/mplus-1p-medium.ttf \
	../work.d/targets/mplus-1p/regular/mplus-1p-regular.ttf \
	../work.d/targets/mplus-1p/light/mplus-1p-light.ttf \
	../work.d/targets/mplus-1p/thin/mplus-1p-thin.ttf \
	../work.d/targets/mplus-2p/black/mplus-2p-black.ttf \
	../work.d/targets/mplus-2p/heavy/mplus-2p-heavy.ttf \
	../work.d/targets/mplus-2p/bold/mplus-2p-bold.ttf \
	../work.d/targets/mplus-2p/medium/mplus-2p-medium.ttf \
	../work.d/targets/mplus-2p/regular/mplus-2p-regular.ttf \
	../work.d/targets/mplus-2p/light/mplus-2p-light.ttf \
	../work.d/targets/mplus-2p/thin/mplus-2p-thin.ttf \
	../work.d/targets/mplus-1c/black/mplus-1c-black.ttf \
	../work.d/targets/mplus-1c/heavy/mplus-1c-heavy.ttf \
	../work.d/targets/mplus-1c/bold/mplus-1c-bold.ttf \
	../work.d/targets/mplus-1c/medium/mplus-1c-medium.ttf \
	../work.d/targets/mplus-1c/regular/mplus-1c-regular.ttf \
	../work.d/targets/mplus-1c/light/mplus-1c-light.ttf \
	../work.d/targets/mplus-1c/thin/mplus-1c-thin.ttf

release: 
	mkdir -p ${RELEASE}
	cp -p $(FILES) ${RELEASE}
	cp -p $(FONTS) ${RELEASE}
	tar cvfz ${RELEASE}.tar.gz ${RELEASE}/
	rm -rf ${RELEASE}
