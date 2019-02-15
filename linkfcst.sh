#!/bin/ksh
set -x

#--rename forecast files to be used for vsdb

indir=${1:-/mnt/lfs3/projects/hfv3gfs/Ratko.Vasic/ptmp/POST}
exp=${2:-suite4}
outdir=${3:-/mnt/lfs3/projects/hfv3gfs/$LOGNAME/stmp}
sdate=${4:-2017060400}
edate=${5:-2017060400}
fhend=${6:-240}
fhout=${7:-3}

export LN=${LN:-"ln -fs"}
export PGBQ=${PGBQ:-"YES"}

[[ ! -s $outdir/$exp ]] && mkdir -p $outdir/$exp
cd $outdir/$exp ||exit 8
cdate=$sdate

while [ $cdate -le $edate ]; do

cyc=`echo $cdate |cut -c 9-10`
filein=$indir/$exp/$cdate/gfs.t${cyc}z.pgrb.1p00.anl
fileout=pgbanl.gfs.$cdate
[[ -s $filein ]] && $LN $filein $fileout

fha=000
fhb=00
while [ $fha -le $fhend ]; do

  filein=$indir/$exp/$cdate/gfs.t${cyc}z.pgrb.1p00.f$fha
  fileout=pgbf$fhb.gfs.$cdate
  [[ -s $filein ]] && $LN $filein $fileout

  if [ $PGBQ = YES ]; then
    filein=$indir/$exp/$cdate/gfs.t${cyc}z.pgrb2.0p25.f$fha  
    fileout=pgbq$fhb.gfs.$cdate
    if [ -s $filein -a ! -s $fileout ]; then  
      rm -f outtmp1 outtmp2 fileout
      $WGRIB2 $filein -match "(:PRATE:surface)" -grib outtmp1
      $WGRIB2 outtmp1 -match "(ave)" -grib outtmp2       
      $CNVGRIB -g21 outtmp2 $fileout
    fi
  fi


  fha=$((fha+fhout))
  [[ $fha -lt 100 ]] && fha=0$fha
  [[ $fha -lt 10 ]] && fha=0$fha
  fhb=$((fhb+fhout))
  [[ $fhb -lt 10 ]] && fhb=0$fhb
done
  
  cdate=`$NDATE +06 $cdate`
done



