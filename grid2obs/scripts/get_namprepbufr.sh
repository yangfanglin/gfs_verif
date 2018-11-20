#!/bin/ksh
#set -x

#  This script looks for nam prepbufr.
#  Valid on and after 03/20/2017 NAM implementation. The data assimilation was changed 
#  from a 12-h cycle with 3-h analysis updates to a 6-h cycle with hourly analysis updates, 
#  so there are no more "tm12" and "tm09" prepbufr files. NDAS naming convention was also 
#  retied. All files are now in the "nam.YYYYMMDD" com2 directory.  
#  Fanglin Yang, April 2017

DATE=${1:-${vdate:-$(date +%Y%m%d%H)}}

export NWPROD=${NWPROD:-/nwprod}
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export hpsstar=${HPSSTAR:-/u/Fanglin.Yang/bin/hpsstar}    
export COM=${HPSSPROD:-/NCEPPROD/hpssprod/runhistory}
export COMROT=${COMROTNAM:-/com2}
export RUNDIR=${RUNDIR:-/stmpd2/$LOGNAME/g2o}
export nambufr_arch=${nambufr_arch:-/global/noscrub/Fanglin.Yang/prepbufr/nam}
export runhpss=${runhpss:-YES}
cd $RUNDIR || exit 8

#for xh in 00 03 06 09 12 15 18 21; do

HH=`echo $DATE |cut -c 9-10 `
if [ $(((HH/6)*6)) -eq $HH ]; then 
  xdate=$DATE 
  suffix=tm00
else
  xdate=$($ndate +3 $DATE )
  suffix=tm03
fi
eval YYYY=`echo $xdate |cut -c 1-4 `
eval YYYYMM=`echo $xdate |cut -c 1-6 `
eval PDY=`echo $xdate |cut -c 1-8 `
eval CYC=`echo $xdate |cut -c 9-10 `

namcomdir=$COMROT/nam/prod/nam.$PDY
namarcdir=${nambufr_arch}/nam.$PDY
namtar=$COM/rh${YYYY}/${YYYYMM}/${PDY}${COMROT}_nam_prod_nam.${PDY}${CYC}.bufr.tar
bufrfile=nam.t${CYC}z.prepbufr.$suffix

if [ -s $namcomdir/$bufrfile ]; then
  cp $namcomdir/$bufrfile  prepda.$DATE           
elif [ -s $namarcdir/$bufrfile ]; then
  cp $namarcdir/$bufrfile  prepda.$DATE           
elif [ $runhpss = YES ]; then
  $hpsstar get $namtar ./$bufrfile
  mv $bufrfile  prepda.$DATE
fi


if [ -s prepda.$DATE ] ; then
 chmod 700 prepda.$DATE
else
 echo "ndas prepda.$DATE not found in $0"
fi

exit
