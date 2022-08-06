#!/bin/ksh
set -x

# get operatinal GDAS prepbufr data

NDATE=/apps/ops/prod/nco/core/prod_util.v2.0.5/exec/ndate        
HPSSTAR=/u/fanglin.yang/bin/hpsstar
DMPDIR=/lfs/h2/emc/global/noscrub/emc.global/dump

CDATE=${1:-$(date +%Y%m%d)}
CDATEM1=`$NDATE -24 ${CDATE}00 |cut -c 1-8`
CDATEM2=`$NDATE -48 ${CDATE}00 |cut -c 1-8`
CDATEM3=`$NDATE -240 ${CDATE}00 |cut -c 1-8`


IDAY=$CDATEM1
while [ $IDAY -le $CDATE ]; do

export COMROTNCO=/lfs/h1/ops/prod/com
export GDAS=gdas

comout=/lfs/h2/emc/physics/noscrub/fanglin.yang/data/stat/prepbufr/gdas
remote=/lfs/h2/emc/physics/noscrub/fanglin.yang/data/stat/prepbufr/gdas
cd $comout

errgdas=0
for vcyc in 00 06 12 18; do
  filein=$COMROTNCO/gfs/v16.2/gdas.$IDAY/${vcyc}/atmos/$GDAS.t${vcyc}z.prepbufr
  filein1=$DMPDIR/gdas.$IDAY/$vcyc/atmos/$GDAS.t${vcyc}z.prepbufr
  fileout=prepbufr.gdas.${IDAY}${vcyc}
 if [ ! -s $comout/$fileout ]; then
  cp $filein $fileout
  if [ $? -ne 0 ]; then cp $filein1 $fileout ;fi                  
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
  #scp -p $fileout ${LOGNAME}@${CLIENT}:${remote}/.

 fi
done
IDAY=`$NDATE +24 ${IDAY}00 |cut -c 1-8`
done

exit
