#!/bin/ksh
set -x

# get operatinal GDAS prepbufr data
# in /com2 or from HPSS archive          

myhost=`echo $(hostname) |cut -c 1-1 `
if [ $myhost = t ]; then HOST=tide; CLIENT=gyre ; fi
if [ $myhost = g ]; then HOST=gyre; CLIENT=tide ; fi
rhost=`echo $CLIENT |cut -c 1-1 `


CDATE=${1:-$(date +%Y%m%d)}            
CDATEM1=`/nwprod/util/exec/ndate -24 ${CDATE}00 |cut -c 1-8`
CDATEM2=`/nwprod/util/exec/ndate -48 ${CDATE}00 |cut -c 1-8`
CDATEM3=`/nwprod/util/exec/ndate -240 ${CDATE}00 |cut -c 1-8`

IDAY=$CDATEM1
while [ $IDAY -le $CDATE ]; do

export COMROTNCO=/com
if [ $IDAY -ge 20160510 ]; then export COMROTNCO=/com2; export GDAS=gdas1 ;fi
if [ $IDAY -ge 20170720 ]; then export COMROTNCO=/gpfs/hps/nco/ops/com; export GDAS=gdas ;fi
if [ $IDAY -ge 20190612 ]; then export COMROTNCO=/gpfs/dell1/nco/ops/com; export GDAS=gdas ;fi

comout=/global/noscrub/Fanglin.Yang/prepbufr/gdas
remote=/global/noscrub/Fanglin.Yang/prepbufr/gdas
cd $comout

errgdas=0
for vcyc in 00 06 12 18; do
  filein=$COMROTNCO/gfs/prod/gdas.$IDAY/$GDAS.t${vcyc}z.prepbufr
  if [ $IDAY -ge 20190612 ]; then filein=$COMROTNCO/gfs/prod/gdas.$IDAY/${vcyc}/$GDAS.t${vcyc}z.prepbufr ;fi
  fileout=prepbufr.gdas.${IDAY}${vcyc}
 if [ ! -s $comout/$fileout ]; then
  cp $filein $fileout
  if [ $? -ne 0 ]; then scp ${CLIENT}:$filein $fileout ;fi
  if [ $? -ne 0 ]; then 
    yyyy=`echo $IDAY |cut -c 1-4 `
    mm=`echo $IDAY |cut -c 5-6 `
    dd=`echo $IDAY |cut -c 7-8 `

    hpssdir=/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyy}${mm}${dd}
    if [ $IDAY -ge 20190612 ]; then
     if [ $IDAY -ge 20190612 ]; then tarfile=gpfs_dell1_nco_ops_com_gfs_prod_gdas.${yyyy}${mm}${dd}_${vcyc}.gdas.tar ; fi
     /nwprod/util/ush/hpsstar  get ${hpssdir}/$tarfile   ./gdas.${IDAY}/${vcyc}/${GDAS}.t${vcyc}z.prepbufr  
     mv gdas.${IDAY}/${vcyc}/$GDAS.t${vcyc}z.prepbufr $fileout
     rm -rf gdas.${IDAY}
    else
     tarfile=gpfs_hps_nco_ops_com_gfs_prod_gdas.${yyyy}${mm}${dd}${vcyc}.tar
     /nwprod/util/ush/hpsstar  get ${hpssdir}/$tarfile   ./$GDAS.t${vcyc}z.prepbufr
     mv $GDAS.t${vcyc}z.prepbufr $fileout
    fi

  fi
  chmod a+r $fileout
  scp -p $fileout ${LOGNAME}@${CLIENT}:${remote}/.

#--copy unrestricted prepbufr file to emc ftp site
  #filein2=$COMROTNCO/gfs/prod/gdas.$IDAY/$GDAS.t${vcyc}z.prepbufr.nr
  #fileout2=prepbufr.gdas.${IDAY}${vcyc}
  #scp -p $filein2 wx24fy@emcrzdm.ncep.noaa.gov:/home/people/emc/ftp/gc_wmb/wx24fy/GFS/bufr/${fileout2}
 fi
done
IDAY=`/nwprod/util/exec/ndate +24 ${IDAY}00 |cut -c 1-8`
done

#ssh -q -l wx24fy emcrzdm.ncep.noaa.gov "chmod a+r /home/people/emc/ftp/gc_wmb/wx24fy/GFS/bufr/prepbufr.gdas.* "
#ssh -q -l wx24fy emcrzdm.ncep.noaa.gov "rm /home/people/emc/ftp/gc_wmb/wx24fy/GFS/bufr/prepbufr.gdas.${CDATEM3}* "
exit
