#!/bin/ksh
set -x

#  This script looks for nam prepbufr.
#  Valid on and after 03/20/2017 NAM implementation. The data assimilation was changed
#  from a 12-h cycle with 3-h analysis updates to a 6-h cycle with hourly analysis updates,
#  so there are no more "tm12" and "tm09" prepbufr files. NDAS naming convention was also
#  retied. All files are now in the "nam.YYYYMMDD" com2 directory.
#  Fanglin Yang, April 2017

nambufr_arch=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/stat/prepbufr/nam
NDATE=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.0/exec/ips/ndate
HPSSTAR=/u/Fanglin.Yang/bin/hpsstar

myhost=`echo $(hostname) |cut -c 1-1 `
if [ $myhost = m ]; then HOST=mars; CLIENT=venus ; fi
if [ $myhost = v ]; then HOST=venus; CLIENT=mars ; fi
rhost=`echo $CLIENT |cut -c 1-1 `

#----------------------------------------------

today=$(date +%Y%m%d)00
daym1=`$NDATE -24 $today`
daym2=`$NDATE -48 $today`
sdate=${1:-$daym2}
edate=${2:-$daym1}

#sdate=2017032000
#edate=2017041700



#-------------------------------------
vdate=$edate
while [ $vdate -ge $sdate ]; do
#-------------------------------------

DATE=$vdate
HH=`echo $DATE |cut -c 9-10`

if [ $(((HH/6)*6)) -eq $HH ]; then
  xdate=$DATE
  suffix=tm00
else
  xdate=$($NDATE +3 $DATE )
  suffix=tm03
fi
eval YYYY=`echo $xdate |cut -c 1-4 `
eval YYYYMM=`echo $xdate |cut -c 1-6 `
eval PDY=`echo $xdate |cut -c 1-8 `
eval CYC=`echo $xdate |cut -c 9-10 `

ARCH=/NCEPPROD/hpssprod/runhistory
COMROT="/gpfs/dell1/nco/ops/com"
ARCHNAM="/gpfs_dell1_nco_ops_com"
if [ $PDY -le 20200228 ]; then ARCHNAM="/com" ;fi
if [ $PDY -le 20190820 ]; then COMROT="/com2" ;fi
namcomdir=$COMROT/nam/prod/nam.$PDY
namarcdir=${nambufr_arch}/nam.$PDY
namtar=$ARCH/rh${YYYY}/${YYYYMM}/${PDY}${ARCHNAM}_nam_prod_nam.${PDY}${CYC}.bufr.tar
bufrfile=nam.t${CYC}z.prepbufr.$suffix

#........................................
if [ ! -s $namarcdir/$bufrfile ]; then
#........................................

if [ ! -s $namarcdir ]; then mkdir -p $namarcdir; fi
cd $namarcdir ||exit 8
if [ -s $namcomdir/$bufrfile ]; then
  cp -p $namcomdir/$bufrfile  .               
else 
  $HPSSTAR get $namtar ./$bufrfile
fi

chmod a+r $namarcdir/$bufrfile                   
#ssh -q -l $LOGNAME ${CLIENT} "mkdir -p $namarcdir "
scp -rp $namarcdir/$bufrfile ${LOGNAME}@${CLIENT}:$namarcdir/.                  

#........................................
fi
#........................................

#----------------------------------------
vdate=`$NDATE -3 $vdate`
#----------------------------------------
done
exit
