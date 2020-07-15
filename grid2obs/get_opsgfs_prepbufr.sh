#!/bin/ksh
set -x

# get operatinal GDAS prepbufr data

myhost=`echo $(hostname) |cut -c 1-1 `
if [ $myhost = m ]; then HOST=mars; CLIENT=venus ; fi
if [ $myhost = v ]; then HOST=venus; CLIENT=mars ; fi
rhost=`echo $CLIENT |cut -c 1-1 `


NDATE=/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.0/exec/ips/ndate
HPSSTAR=/u/Fanglin.Yang/bin/hpsstar
DMPDIR=/gpfs/dell3/emc/global/dump

CDATE=${1:-$(date +%Y%m%d)}
CDATEM1=`$NDATE -24 ${CDATE}00 |cut -c 1-8`
CDATEM2=`$NDATE -48 ${CDATE}00 |cut -c 1-8`
CDATEM3=`$NDATE -240 ${CDATE}00 |cut -c 1-8`


IDAY=$CDATEM1
while [ $IDAY -le $CDATE ]; do

export COMROTNCO=/com
if [ $IDAY -ge 20160510 ]; then export COMROTNCO=/com2; export GDAS=gdas1 ;fi
if [ $IDAY -ge 20170720 ]; then export COMROTNCO=/gpfs/hps/nco/ops/com; export GDAS=gdas ;fi
if [ $IDAY -ge 20190612 ]; then export COMROTNCO=/gpfs/dell1/nco/ops/com; export GDAS=gdas ;fi

comout=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/stat/prepbufr/gdas
remote=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/stat/prepbufr/gdas
cd $comout

errgdas=0
for vcyc in 00 06 12 18; do
  filein=$COMROTNCO/gfs/prod/gdas.$IDAY/$GDAS.t${vcyc}z.prepbufr
  if [ $IDAY -ge 20190612 ]; then filein=$COMROTNCO/gfs/prod/gdas.$IDAY/${vcyc}/$GDAS.t${vcyc}z.prepbufr ;fi
  filein1=$DMPDIR/gdas.$IDAY/$vcyc/$GDAS.t${vcyc}z.prepbufr
  fileout=prepbufr.gdas.${IDAY}${vcyc}
 if [ ! -s $comout/$fileout ]; then
  cp $filein $fileout
  if [ $? -ne 0 ]; then cp $filein1 $fileout ;fi                  
  if [ $? -ne 0 ]; then scp ${CLIENT}:$filein $fileout ;fi
  if [ $? -ne 0 ]; then scp ${CLIENT}:$filein1 $fileout ;fi
  if [ $? -ne 0 ]; then 
    yyyy=`echo $IDAY |cut -c 1-4 `
    mm=`echo $IDAY |cut -c 5-6 `
    dd=`echo $IDAY |cut -c 7-8 `

    hpssdir=/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyy}${mm}${dd}
    if [ $IDAY -ge 20190612 ]; then
     if [ $IDAY -ge 20190612 ]; then tarfile=gpfs_dell1_nco_ops_com_gfs_prod_gdas.${yyyy}${mm}${dd}_${vcyc}.gdas.tar ; fi
     $HPSSTAR  get ${hpssdir}/$tarfile   ./gdas.${IDAY}/${vcyc}/${GDAS}.t${vcyc}z.prepbufr  
     mv gdas.${IDAY}/${vcyc}/$GDAS.t${vcyc}z.prepbufr $fileout
     rm -rf gdas.${IDAY}
    else
     tarfile=gpfs_hps_nco_ops_com_gfs_prod_gdas.${yyyy}${mm}${dd}${vcyc}.tar
     $HPSSTAR  get ${hpssdir}/$tarfile   ./$GDAS.t${vcyc}z.prepbufr
     mv $GDAS.t${vcyc}z.prepbufr $fileout
    fi

  fi
  chmod a+r $fileout
  scp -p $fileout ${LOGNAME}@${CLIENT}:${remote}/.

 fi
done
IDAY=`$NDATE +24 ${IDAY}00 |cut -c 1-8`
done

exit
