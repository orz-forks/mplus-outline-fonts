#!/bin/sh
# vim:set ts=8 sts=2 sw=2 tw=0:
#
# Last Change: 23-Jan-2005.
# Maintainer:  MURAOKA Taro <koron@tka.att.ne.jp>

weight=$1
shift

perl scripts/build_mplus.pl -w $weight
fontforge -script mplus-$weight.pe 2> mplus-$weight.sfd.log
if [ ! mplus-$weight.ttf -nt mplus-$weight.sfd ] ; then
  fontforge -script scripts/2ttf.pe mplus-$weight 2> mplus-$weight.ttf.log
fi
