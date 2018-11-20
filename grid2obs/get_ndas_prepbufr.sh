#!/bin/ksh
set -x

#  this script looks for ndas or nam prepbufr.

savedir=/global/noscrub/Fanglin.Yang/prepbufr/ndas
myhost=`echo $(hostname) |cut -c 1-1 `
if [ $myhost = t ]; then HOST=tide; CLIENT=gyre ; fi
if [ $myhost = g ]; then HOST=gyre; CLIENT=tide ; fi
rhost=`echo $CLIENT |cut -c 1-1 `


today=$(date +%Y%m%d)00
daym1=`/nwprod/util/exec/ndate -24 $today`
daym2=`/nwprod/util/exec/ndate -48 $today`
sdate=${1:-$daym2}
edate=${2:-$daym1}

#sdate=2015010100
#edate=2015050200

#-------------------------------------
vdate=$edate
while [ $vdate -ge $sdate ]; do
#-------------------------------------
DATE=$vdate

export NWPROD=${NWPROD:-/nwprod}
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export hpsstar=${HPSSTAR:-/u/Fanglin.Yang/bin/hpsstar}    
export COM=${HPSSPROD:-/NCEPPROD/hpssprod/runhistory}

export COMROT="/com"
if [ $DATE -ge 2017032100 ]; then export  COMROT="/com2"; fi


YYYY=`echo $DATE |cut -c 1-4 `
YYYYMM=`echo $DATE |cut -c 1-6 `
PDY=`echo $DATE |cut -c 1-8 `
HH=`echo $DATE |cut -c 1-10 `

for xh in 00 03 06 09 12 15 18 21; do
 xdate=$($ndate +$xh $DATE )
 eval YYYY${xh}=`echo $xdate |cut -c 1-4 `
 eval YYYYMM${xh}=`echo $xdate |cut -c 1-6 `
 eval PDY${xh}=`echo $xdate |cut -c 1-8 `
 eval HH${xh}=`echo $xdate |cut -c 9-10 `
done

case $HH00 in
 00) hpss1=$COM/rh${YYYY12}/${YYYYMM12}/${PDY12}/${COMROT}_nam_prod_ndas.${PDY12}${HH12}.bufr.tar
     hpss2=$COM/rh${YYYY06}/${YYYYMM06}/${PDY06}/${COMROT}_nam_prod_ndas.${PDY06}${HH06}.bufr.tar
     hpss3=$COM/rh${YYYY00}/${YYYYMM00}/${PDY00}/${COMROT}_nam_prod_nam.${PDY00}${HH00}.bufr.tar;;
 03) hpss1=$COM/rh${YYYY09}/${YYYYMM09}/${PDY09}/${COMROT}_nam_prod_ndas.${PDY09}${HH09}.bufr.tar
     hpss2=$COM/rh${YYYY03}/${YYYYMM03}/${PDY03}/${COMROT}_nam_prod_ndas.${PDY03}${HH03}.bufr.tar;;
 06) hpss1=$COM/rh${YYYY12}/${YYYYMM12}/${PDY12}/${COMROT}_nam_prod_ndas.${PDY12}${HH12}.bufr.tar
     hpss2=$COM/rh${YYYY06}/${YYYYMM06}/${PDY06}/${COMROT}_nam_prod_ndas.${PDY06}${HH06}.bufr.tar
     hpss3=$COM/rh${YYYY00}/${YYYYMM00}/${PDY00}/${COMROT}_nam_prod_nam.${PDY00}${HH00}.bufr.tar;;
 09) hpss1=$COM/rh${YYYY09}/${YYYYMM09}/${PDY09}/${COMROT}_nam_prod_ndas.${PDY09}${HH09}.bufr.tar
     hpss2=$COM/rh${YYYY03}/${YYYYMM03}/${PDY03}/${COMROT}_nam_prod_ndas.${PDY03}${HH03}.bufr.tar;;
 12) hpss1=$COM/rh${YYYY12}/${YYYYMM12}/${PDY12}/${COMROT}_nam_prod_ndas.${PDY12}${HH12}.bufr.tar
     hpss2=$COM/rh${YYYY06}/${YYYYMM06}/${PDY06}/${COMROT}_nam_prod_ndas.${PDY06}${HH06}.bufr.tar
     hpss3=$COM/rh${YYYY00}/${YYYYMM00}/${PDY00}/${COMROT}_nam_prod_nam.${PDY00}${HH00}.bufr.tar;;
 15) hpss1=$COM/rh${YYYY09}/${YYYYMM09}/${PDY09}/${COMROT}_nam_prod_ndas.${PDY09}${HH09}.bufr.tar
     hpss2=$COM/rh${YYYY03}/${YYYYMM03}/${PDY03}/${COMROT}_nam_prod_ndas.${PDY03}${HH03}.bufr.tar;;
 18) hpss1=$COM/rh${YYYY12}/${YYYYMM12}/${PDY12}/${COMROT}_nam_prod_ndas.${PDY12}${HH12}.bufr.tar
     hpss2=$COM/rh${YYYY06}/${YYYYMM06}/${PDY06}/${COMROT}_nam_prod_ndas.${PDY06}${HH06}.bufr.tar
     hpss3=$COM/rh${YYYY00}/${YYYYMM00}/${PDY00}/${COMROT}_nam_prod_nam.${PDY00}${HH00}.bufr.tar;;
 21) hpss1=$COM/rh${YYYY09}/${YYYYMM09}/${PDY09}/${COMROT}_nam_prod_ndas.${PDY09}${HH09}.bufr.tar
     hpss2=$COM/rh${YYYY03}/${YYYYMM03}/${PDY03}/${COMROT}_nam_prod_ndas.${PDY03}${HH03}.bufr.tar;;
esac

case $HH00 in
 00) date1=${PDY12}
     date2=${PDY06}
     date3=${PDY00};;
 03) date1=${PDY09}
     date2=${PDY03};;
 06) date1=${PDY12}
     date2=${PDY06}
     date3=${PDY00};;
 09) date1=${PDY09}
     date2=${PDY03};;
 12) date1=${PDY12}
     date2=${PDY06}
     date3=${PDY00};;
 15) date1=${PDY09}
     date2=${PDY03};;
 18) date1=${PDY12}
     date2=${PDY06}
     date3=${PDY00};;
 21) date1=${PDY09}
     date2=${PDY03};;
esac


case $HH00 in
 00) ndas1=ndas.t${HH12}z.prepbufr.tm12
     ndas2=ndas.t${HH06}z.prepbufr.tm06
     ndas3=nam.t${HH00}z.prepbufr.tm00;;
 03) ndas1=ndas.t${HH09}z.prepbufr.tm09
     ndas2=ndas.t${HH03}z.prepbufr.tm03;;
 06) ndas1=ndas.t${HH12}z.prepbufr.tm12
     ndas2=ndas.t${HH06}z.prepbufr.tm06
     ndas3=nam.t${HH00}z.prepbufr.tm00;;
 09) ndas1=ndas.t${HH09}z.prepbufr.tm09
     ndas2=ndas.t${HH03}z.prepbufr.tm03;;
 12) ndas1=ndas.t${HH12}z.prepbufr.tm12
     ndas2=ndas.t${HH06}z.prepbufr.tm06
     ndas3=nam.t${HH00}z.prepbufr.tm00;;
 15) ndas1=ndas.t${HH09}z.prepbufr.tm09
     ndas2=ndas.t${HH03}z.prepbufr.tm03;;
 18) ndas1=ndas.t${HH12}z.prepbufr.tm12
     ndas2=ndas.t${HH06}z.prepbufr.tm06
     ndas3=nam.t${HH00}z.prepbufr.tm00;;
 21) ndas1=ndas.t${HH09}z.prepbufr.tm09
     ndas2=ndas.t${HH03}z.prepbufr.tm03;;
esac


mkdir -p $savedir/ndas.${date1}
cd $savedir/ndas.${date1}
if [ -s /${COMROT}/nam/prod/ndas.${date1}/$ndas1 ]; then
  cp -p /${COMROT}/nam/prod/ndas.${date1}/$ndas1 .
else
  $hpsstar get $hpss1 ./$ndas1
fi

mkdir -p $savedir/ndas.${date2}
cd $savedir/ndas.${date2}
if [ -s /${COMROT}/nam/prod/ndas.${date2}/$ndas2 ]; then
  cp /${COMROT}/nam/prod/ndas.${date2}/$ndas2 .
else
  $hpsstar get $hpss2 ./$ndas2
fi

if [ $((date3+1)) -gt 1 ] ; then 
mkdir -p $savedir/ndas.${date3} 
cd $savedir/ndas.${date3}
if [ -s /${COMROT}/nam/prod/ndas.${date3}/$ndas3 ]; then
  cp /${COMROT}/nam/prod/ndas.${date3}/$ndas3 .
else
  $hpsstar get $hpss3 ./$ndas3
fi
fi


chmod a+r $savedir/ndas.${date1}/$ndas1/*
chmod a+r $savedir/ndas.${date1}/$ndas2/*
chmod a+r $savedir/ndas.${date1}/$ndas3/*

ssh -q -l $LOGNAME ${CLIENT} "mkdir -p $savedir/ndas.${date1} "
ssh -q -l $LOGNAME ${CLIENT} "mkdir -p $savedir/ndas.${date2} "
ssh -q -l $LOGNAME ${CLIENT} "mkdir -p $savedir/ndas.${date3} "
scp -rp $savedir/ndas.${date1}/$ndas1 ${LOGNAME}@${CLIENT}:${savedir}/ndas.${date1}/.
scp -rp $savedir/ndas.${date2}/$ndas2 ${LOGNAME}@${CLIENT}:${savedir}/ndas.${date2}/.
scp -rp $savedir/ndas.${date3}/$ndas3 ${LOGNAME}@${CLIENT}:${savedir}/ndas.${date3}/.

#ssh -q -l $LOGNAME ${CLIENT} "chmod a+r $savedir/ndas.${date1}/* "
#ssh -q -l $LOGNAME ${CLIENT} "chmod a+r $savedir/ndas.${date2}/* "
#ssh -q -l $LOGNAME ${CLIENT} "chmod a+r $savedir/ndas.${date3}/* "

#----------------------------------------
vdate=`$ndate -3 $vdate`
#----------------------------------------
done
exit
