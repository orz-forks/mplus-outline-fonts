#!/bin/sh

weight=$1
shift

perl scripts/build_mplus.pl -w $weight
pfaedit -script mplus-$weight.pe 2> mplus-$weight.sfd.log
pfaedit -script scripts/2ttf.pe mplus-$weight 2> mplus-$weight.ttf.log
