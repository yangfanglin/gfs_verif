#!/bin/ksh
set -x

# get operatinal GFS forecast and analysis data 
# in /com or from HPSS archive          

comout=${1:-/stmp/$LOGNAME/g2o/00Z/gfs}
exp=${2:-gfs}
cdate=${3:-2011050100}                    ;#forecast cycle         
vlength=${4:-120}                        ;#verification end hour of forecast
fhout=${5:-6}                            ;#output frequency
vhlist=${6:-"00 06 12 18"}               ;#prepbufr from gdas analysis cycles

IDAY=`echo $cdate |cut -c 1-8`
yyyy=`echo $cdate |cut -c 1-4 `
mm=`echo $cdate |cut -c 5-6 `
dd=`echo $cdate |cut -c 7-8 `
fcyc=`echo $cdate |cut -c 9-10 `

runhpss=${runhpss:-YES}                   ;#run hpsstar in batch mode
hpsstar=${HPSSTAR:-/u/Fanglin.Yang/bin/hpsstar}
NWPROD=${NWPROD:-/nwprod}
cnvgrib=$NWPROD/util/exec/cnvgrib 
COMROT=${COMROT:-/gpfs/hps/nco/ops/com}
GDAS=${GDAS:-gdas}
chost=`echo $(hostname) |cut -c 1-1`
gdas_prepbufr_arch=${gdas_prepbufr_arch:-/global/noscrub/Fanglin.Yang/prepbufr/gdas}
exp_dir=${exp_dir:-/global/noscrub/emc.glopara/global/$exp}       
if [ ! -s $comout ]; then mkdir -p $comout ;fi
cd $comout  ||exit 8

#--first try to get real-time ops data online at /com or at /exp_dir
errgfs=0
ffcst=00
while [ $ffcst -le $vlength ] ; do
   fileina=$COMROT/gfs/v16.2/gfs.$IDAY/atmos/gfs.t${fcyc}z.pgrbf${ffcst}
   fileinb=$exp_dir/pgbf${ffcst}.$exp.${IDAY}${fcyc}
   fileinc=$exp_dir/pgbf${ffcst}.$exp.${IDAY}${fcyc}.grib2
   fileout=pgbf${ffcst}.${exp}.${IDAY}${fcyc}
   if [ -s $fileina ]; then
    ln -fs $fileina $fileout
   elif [ -s $fileinb ]; then
    ln -fs $fileinb $fileout
   elif [ -s $fileinc ]; then
    $cnvgrib -g21 $fileinc $fileout
   else
    errgfs=1
   fi
   ffcst=`expr $ffcst + $fhout `
   if [ $ffcst -lt 10 ]; then ffcst=0$ffcst ; fi
done

errgdas=0
for vcyc in $vhlist; do
  fileina=$COMROT/gfs/v16.2/gdas.$IDAY/atmos/$GDAS.t${vcyc}z.prepbufr
  fileinb=${gdas_prepbufr_arch}/prepbufr.gdas.${IDAY}${vcyc} 
  fileout=prepbufr.gdas.${IDAY}${vcyc}
  if [ -s $fileina ]; then
    ln -fs $fileina $fileout
  elif [ -s $fileinb ]; then
    ln -fs $fileinb $fileout
  else
   errgdas=1
  fi
done


#--get data from HPSS archive if they do not exist online
newhpssdir=/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyy}${mm}${dd}          ;#2.5-deg, bufr etc
newhpssdir1=/NCEPPROD/1year/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyy}${mm}${dd}   ;#1-deg, 0.5-deg pgb files
newhpssdir2=/NCEPPROD/2year/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyy}${mm}${dd}   ;#sigma, sfc flux etc

if [ $yyyy -le 2014 ]; then
 newhpssdir1=/NCEPPROD/1year/hpssprod/runhistory/rh${yyyy}/save
 newhpssdir=/NCEPPROD/1year/hpssprod/runhistory/rh${yyyy}/save
fi

#------------------------------------------
if [ $errgfs -ne 0 -a $runhpss = YES ]; then
#------------------------------------------
rm pgbflist
>pgbflist
ffcst=00        
while [ $ffcst -le $vlength ] ; do
 echo ./gfs.t${fcyc}z.pgrbf${ffcst} >>pgbflist
 ffcst=`expr $ffcst + $fhout `
 if [ $ffcst -lt 10 ]; then ffcst=0$ffcst ; fi
done
#--extract data and rename files 
$hpsstar get ${newhpssdir1}${COMROT}_gfs_prod_gfs.${cdate}.pgrb.tar `cat pgbflist `

if [ $? -ne 0 ]; then
 rm gethpss.sh
cat > gethpss.sh <<EOF
 cd $comout
 $hpsstar get ${newhpssdir1}${COMROT}_gfs_prod_gfs.${cdate}.pgrb.tar \`cat pgbflist \`
EOF
 chmod a+x gethpss.sh
 $SUBJOB -a $ACCOUNT -q $CUE2FTP -p 1/1/S -r 1024/1 -t 00:30:00 -j gethpss \
   -o gethpss.out $comout/gethpss.sh
 nsleep=0; tsleep=30; msleep=40
 while test ! -s gfs.t${fcyc}z.pgrbf$vlength -a $nsleep -lt $msleep;do
   sleep $tsleep ; nsleep=`expr $nsleep + 1`
 done
fi

ffcst=00
while [ $ffcst -le $vlength ] ; do
 mv gfs.t${fcyc}z.pgrbf${ffcst} pgbf${ffcst}.${exp}.$cdate
 ffcst=`expr $ffcst + $fhout `
 if [ $ffcst -lt 10 ]; then ffcst=0$ffcst ; fi
done
#------------------------------------------
fi
#------------------------------------------


#-get gdas prepbufr files 
#------------------------------------------
if [ $errgdas -ne 0 -a $runhpss = YES ]; then
#------------------------------------------
 for vcyc in $vhlist; do
  if [ ! -s prepbufr.gdas.${yyyy}${mm}${dd}${vcyc} ]; then
   $hpsstar get ${newhpssdir}${COMROT}_gfs_prod_gdas.${yyyy}${mm}${dd}${vcyc}.tar   ./$GDAS.t${vcyc}z.prepbufr
   if [ $? -ne 0 ]; then
    rm gethpssprep.sh
cat > gethpssprep.sh <<EOF
    cd $comout
    $hpsstar get ${newhpssdir}${COMROT}_gfs_prod_gdas.${yyyy}${mm}${dd}${vcyc}.tar   ./$GDAS.t${vcyc}z.prepbufr
EOF
    chmod a+x gethpssprep.sh
    $SUBJOB -a $ACCOUNT -q $CUE2FTP -p 1/1/S -r 1024/1 -t 00:30:00 -j gethpssprep \
      -o gethpssprep.out $comout/gethpssprep.sh
    nsleep=0; tsleep=30; msleep=40
    while test ! -s $GDAS.t${vcyc}z.prepbufr  -a $nsleep -lt $msleep;do
      sleep $tsleep ; nsleep=`expr $nsleep + 1`
    done
   fi
   mv $GDAS.t${vcyc}z.prepbufr prepbufr.gdas.${yyyy}${mm}${dd}${vcyc}
  fi
 done
#------------------------------------------
fi
#------------------------------------------

exit
