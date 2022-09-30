#!/bin/ksh
set -x

#--------------------------------------------------------------------------
#--Fanglin Yang, September 2011
#  compute CONUS precipitation skill scores and save scores in $ARCDIR.
#  works for 00Z and 12Z cycles of forecasts.
#--Fanglin Yang, June 2014
#  expand verification length beyond 84 hours to any given length
#--Fanglin Yang, March 2017
#  add option to use data from NCO-like names and directories
#--------------------------------------------------------------------------


export scrdir=${scrdir:-/global/save/Fanglin.Yang/VRFY/vsdb/precip}
export expnlist=${expnlist:-"prhw14 prtest"}             ;#experiment names
export expdlist=${expdlist:-"/global/noscrub/$LOGNAME/archive /global/noscrub/$LOGNAME/archive"}
export hpsslist=${hpsslist:-"/NCEPDEV/hpssuser/g01/wx24fy/WCOSS /NCEPDEV/hpssuser/g01/wx24fy/WCOSS"}
export complist=${complist:-"gyre  tide "}               ;#computers where experiments are run
export ftyplist=${ftyplist:-"flxf flxf"}                 ;#file types: pgbq or flxf
export dumplist=${dumplist:-".gfs. .gfs."}               ;#file format ${file_type}${fhr}${dump}${yyyymmdd}${cyc}
export ptyplist=${ptyplist:-"PRATE PRATE"}               ;#precip types in GRIB: PRATE or APCP
export vhour=${vhour:-84}                                ;#verification length in hours       

export cyc=${cycle:-"00"}                                ;#forecast cycle          
export DATEST=${DATEST:-20140106}                        ;#forecast starting date
export DATEND=${DATEND:-20140206}                        ;#forecast ending date
export ARCDIR0=${ARCDIR:-/stmpd2/$LOGNAME/pvrfy}

export NWPROD=${NWPROD:-/nwprod}
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export cnvgrib=${cnvgrib:-$NWPROD/util/exec/cnvgrib}
export cpygb=${cpygb:-$NWPROD/util/exec/copygb}

## default to GFS settings. May vary for different models
export fhout=${fhout:-6}       ;#forecast output frequency in hours
export bucket=${bucket:-6}     ;#accumulation bucket in hours. bucket=0 -- continuous accumulation       

case $cyc in
 00)  export fhend=$((vhour/24*24+12))  ;;
 12)  export fhend=$((vhour/24*24))  ;;
 *)   echo "cyc=${cyc}Z not supported"; exit ;;
esac

myhost=`echo $(hostname) |cut -c 1-1 `
nexp=`echo $expnlist |wc -w`
set -A expname none $expnlist
set -A expdir none $expdlist
set -A hpssname none $hpsslist
set -A compname none $complist
set -A dumpname none $dumplist
set -A ftypname none $ftyplist
set -A ptypname none $ptyplist

#--------------------------------
nn=1; while [ $nn -le $nexp ]; do
#--------------------------------

export expn=${expname[nn]}
export expd=${expdir[nn]}
export hpssdir=${hpssname[nn]}
export cdump=${dumpname[nn]}
export file_type=${ftypname[nn]}
export precip_type=${ptypname[nn]}        ;#PRATE -> precip rate; APCP -> accumulated precip

export rundir=${rundir:-/ptmp/$LOGNAME/mkup_precip}
export ARCDIR=$ARCDIR0/$expn
export DATDIR=${rundir}/${expn}
if [ -s $DATDIR ];  then rm -r ${DATDIR}; fi
mkdir -p ${DATDIR} ${ARCDIR}
cd $DATDIR || exit 8


SDATE=`echo $DATEST | cut -c1-8`
EDATE=`echo $DATEND | cut -c1-8`
YMDM=` $ndate -$fhend ${SDATE}${cyc} | cut -c1-8`

CDATE=$YMDM
#----------------
while [ $CDATE -le $EDATE ]; do
 if [ ! -s ${file_type}${fhend}${cdump}${CDATE}${cyc} ]; then 
#----------------

rm ${file_type}list
>${file_type}list
hr=0 
while [ $hr -le $fhend ]; do
 if [ $hr -le 10 ]; then hr=0$hr; fi

  filename=${file_type}${hr}${cdump}${CDATE}${cyc}
  fileina=${expd}/${expn}/${filename}
  fileinb=${expd}/${expn}/${filename}.grib2
  fileinc=${expd}/../vrfyarch/${filename}
  fileind=${expd}/../vrfyarch/${filename}.grib2

  echo $filename >>${file_type}list
  if [ -s $fileina ]; then
   ln -fs  $fileina $filename
  elif [ -s $fileinb ]; then
   $cnvgrib -g21 $fileinb $filename
  elif [ -s $fileinc ]; then
   ln -fs  $fileinc $filename
  elif [ -s $fileind ]; then
   $cnvgrib -g21 $fileind $filename
  else
   echo "$filename does not exist"
  fi
  hr=`expr $hr + $fhout `
done

 ## interpolate all flux file to the operational flx 1152x576 grid
 #for file in `cat ${file_type}list `; do
 # $cpygb -g4 -i0 -k"4*-1,59,1" -x  $file ${file}_tmp
 # mv ${file}_tmp $file
 #done

#----------------
 fi
 CDATE=` $ndate +24 ${CDATE}${cyc} | cut -c1-8`
done
#----------------

export OBSPCP=${OBSPCP:-/global/noscrub/emc.glopara/global/OBSPRCP}
$scrdir/Run_rain_stat.sh $expn ${SDATE}${cyc} ${EDATE}${cyc} ${file_type} ${precip_type} ${fhout} ${bucket}

#--------------------------------
nn=`expr $nn + 1 `
done          ;#end of model loop
#--------------------------------

exit
