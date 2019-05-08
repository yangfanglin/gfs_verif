#!/bin/ksh
set -x

#---------------------------------------------------------------------
#--Processing fits for surface variables using nam or ndas analysis over
#  subregions of the NAM area for all forecast cycles and all verifying hours.
#  Fanglin Yang, November 2011
#---------------------------------------------------------------------

export PLLN=$1      ;#experiment name
export vdate=$2     ;#verification time yyyymmddhh
export vlength=$3   ;#verification length in hours
export cyc=$4       ;#forecast cycle to verify 
export HOLDOUT=$5   ;#temporary running directory        
export DDIR=$6      ;#experiment data directory
 
export grid2obshome=${grid2obshome:-/global/save/wx24fy/VRFY/vsdb/grid2obs}
export PARMDIR=${PARMDIR:-$grid2obshome/parm}
export SCRIPTDIR=${SCRIPTDIR:-$grid2obshome/scripts}
export NWPROD=${NWPROD:-/nwprod}
export COMROTNAM=${COMROTNAM:-/com}
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export cnvgrib=${cnvgrib:-$NWPROD/util/exec/cnvgrib}
export HPSSTAR=${HPSSTAR:-/u/Fanglin.Yang/bin/hpsstar}
export grbindex=${grbindex:-$NWPROD/util/exec/grbindex}
export gdtype=${gdtype:-3}             ;#fcst data resolution, 2-2.5deg, 3-1deg., 4-0.5deg
export batch=${batch:-NO}              ;#run job in batch mode                              
export ACCOUNT=${ACCOUNT:-GFS-T2O}     ;#ibm computer ACCOUNT task
export CUE2RUN=${CUE2RUN:-dev}         ;#dev or devhigh or 1
export CUE2FTP=${CUE2FTP:-transfer}    ;#queue for data transfer
export GROUP=${GROUP:-g01}             ;#account group
export runhpss=${runhpss:-YES}         ;#run hpsstar in batch mode
export APRUN=${APRUN:-""}              ;#special afix for running in batch mode


#--------------------------------------------------
export PLL3=`echo $PLLN |tr "[a-z]" "[A-Z]" `
export pll3=$PLLN

export RUNDIR=$HOLDOUT/prepfitsfc_${PLLN}.${vdate}
mkdir -p $RUNDIR; cd $RUNDIR ||exit 8
rm $RUNDIR/*

#-----------------------------------------------------------------------
# --verification hour 
vhour=$(echo $vdate |cut -c 9-10 )
>prepfits.in${vhour}

fhour1=$((vhour-cyc))                    ;#first forecast hour
fdate1=$(echo $vdate |cut -c 1-8)$cyc    ;#first forecast cycle
if [ $fhour1 -lt 0 ]; then 
  fdate1=$($ndate -24 $fdate1 )
  fhour1=$((24-cyc+vhour))               ;#first forecast hour
fi
if [ $fhour1 -lt 10 ]; then fhour1=0$fhour1; fi

rc=0
fhour=$fhour1; fdate=$fdate1
while [ $fhour -le $vlength ]; do
 fileina=$DDIR/pgbf${fhour}.${PLLN}.${fdate}
 fileinb=$DDIR/pgbf${fhour}.${PLLN}.${fdate}.grib2
 if [ -s $fileina ]; then
   cp $fileina  AWIPD0${fhour}.tm00 
 elif [ -s $fileinb ]; then
   $cnvgrib -g21 $fileinb  AWIPD0${fhour}.tm00 
 fi
 $grbindex AWIPD0${fhour}.tm00 AWIPD0${fhour}i.tm00
 if [ $? -ne 0 ]; then rc=1 ; fi

 if [ -s AWIPD0${fhour}.tm00 ]; then
  echo "${pll3}"              >>prepfits.in${vhour}
  echo "AWIPD0${fhour}.tm00"  >>prepfits.in${vhour}
  echo "AWIPD0${fhour}i.tm00" >>prepfits.in${vhour}
 fi

 fhour=`expr $fhour + 24 `
 fdate=$($ndate -24 $fdate ) 
done
if [ $rc -ne 0 ]; then 
 echo " No forecast data found, exit $0 "
# exit
fi
 


#  -------------------------------
#    obtain prepbufr files
#  -------------------------------
echo " verified againt ndas or nam prepbufr.$vdate "
if [ $vdate -le 2017031923 ]; then
 export getbufrjob=$grid2obshome/scripts/get_ndasprepbufr.sh
else
 export getbufrjob=$grid2obshome/scripts/get_namprepbufr.sh
fi

$getbufrjob $vdate 

if [ ! -s prepda.$vdate -a $runhpss = YES ]; then
  $SUBJOB -e RUNDIR,vdate,NWPROD,COMROTNAM,ndate,HPSSTAR,runhpss -a $ACCOUNT -q $CUE2FTP -p 1/1/S -r 1024/1 -t 2:00:00 -j getbufr \
    -o get_prepbufr.out $getbufrjob                                      
  nsleep=0; tsleep=30; msleep=40     
  while test ! -s prepda.$vdate -a $nsleep -lt $msleep;do
    sleep $tsleep ; nsleep=`expr $nsleep + 1`
  done
fi
if [ ! -s prepda.$vdate ]; then
 echo " prepda.$vdate not found, exit $0 "
 exit
fi

#  ----------------------------------------
#  define a prepbufr file to filter and fit
#  ----------------------------------------
 
bufr=prepda.$vdate    
chmod 700 prepda*

#  -------------------------------------------------------------
#  run editbufr and prepfits on the combined set of observations
#  -------------------------------------------------------------

rm datatmp prepfits.${PLL3}.$vdate       

rm fort.*
ln -sf $bufr         fort.20
ln -sf datatmp       fort.50
sed -e "s/gdtype/$gdtype/g"  $PARMDIR/gridtobs.keeplist.global >gridtobs.keeplist        
$APRUN $NWPROD/exec/verf_gridtobs_editbufr < gridtobs.keeplist
if [ $? -ne 0 ]; then 
 echo " failed verf_gridtobs_editbufr in $0 , exit" 
 exit
fi

chmod 700 data*

rm fort.*
ln -sf $PARMDIR/gridtobs.levcat.global      fort.11
ln -sf datatmp                              fort.20
ln -sf $PARMDIR/verf_gridtobs.prepfits.tab  fort.22
ln -sf prepfits.${PLL3}.${vdate}            fort.50
$APRUN $NWPROD/exec/verf_gridtobs_prepfits < prepfits.in${vhour} > prepfit${vhour}.out.${PLLN}
if [ $? -ne 0 ]; then 
 echo " failed verf_gridtobs_prepfits in $0 , exit" 
 exit
fi

chmod 700 prepfits*

rm fort.*
ln -sf prepfits.${PLL3}.${vdate}           fort.10
ln -sf $PARMDIR/verf_gridtobs.grid104      fort.20
ln -sf $PARMDIR/verf_gridtobs.regions      fort.21
ln -sf ${PLLN}_${vdate}.vdb                fort.50

#-- create grid2obs control file
$SCRIPTDIR/grid2obssfc.ctl.sh $fhour1 $vlength

#-- create grid2obs vsdb file 
$APRUN $NWPROD/exec/verf_gridtobs_gridtobs <grid2obssfc.ctl > gto.${PLLN}${vhour}.out

cp ${PLLN}_${vdate}.vdb ${HOLDOUT}/${PLLN}_sfc_${vdate}.vdb
cd $HOLDOUT
rm -rf $RUNDIR

exit


