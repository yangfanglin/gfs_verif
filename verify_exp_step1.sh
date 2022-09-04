#!/bin/ksh -l
set -x

#----------------------------------------------------------------------
#----------------------------------------------------------------------
#     NCEP EMC GLOBAL MODEL VERIFICATION SYSTEM
# Fanglin.Yang@noaa.gov, NOAA/NWS/NCEP/EMC, 301-7638000 x7296
# April 2007
#   1. The script computes partial sums and save as vsdb database
#   2. For verification vtype=anom, anomalies are derived for forecasts
#      from all models/cycles using the same NCEP CDAS 30-year
#      climatology (/nwprod/fix/cmean_1d.x) before computing scores.
#   3. For verification vtype=pres, forecasts are directly verified 
#      aganist each experiment's own analysis or any given analysis. 
# Sep 2008   
#   1. Added the option to use different analyses for verification 
#   2. Added the option to get data from different machines.
# Nov 2010                           
#   1. Added the option to create and use mean analysis for verification.                
# Jul 2011                           
#   1. Added forecasts from different cycles to be verified at the same     
#      verification target time.  Previous version only allows forecasts 
#      from the same cycle be verified at every 24 hours internal.
# December 2012                           
#   1. Added forecasts from the same cycle to be verified at different 
#      verification target time.  This requires analyses to be availiable
#      at all verification hours (00Z 06Z, 12Z, 18Z etc) in a day even if
#      only one cycle of forecast is carried out.
#----------------------------------------------------------------------
#----------------------------------------------------------------------

export machine=${machine:-WCOSS_D}                              ;#WCOSS, WCOSS_C, WCOSS_D, HERA, JET etc

if [ $machine = WCOSS2 ]; then
    module purge                           2>>/dev/null
    module load envvar/1.0                 2>>/dev/null
    module load intel/19.1.3.304           2>>/dev/null
    module load PrgEnv-intel/8.1.0         2>>/dev/null
    module load craype/2.7.10              2>>/dev/null
    module load cray-pals/1.0.17           2>>/dev/null
    module load cray-mpich/8.1.9           2>>/dev/null
    module load libjpeg/9c                 2>>/dev/null
    module load grib_util/1.2.4            2>>/dev/null
fi
#-----------------------------------------------

date
export expnlist=${expnlist:-${1:-"pre13j pre13d"}}             ;#experiment name
export expdlist=${expdlist:-${2:-"/global/hires/glopara/archive /global/hires/glopara/archive"}}    ;#experiment directory
export complist=${complist:-${3:-"cirrus stratus"}}            ;#computers where experiments are run 
export dumplist=${dumplist:-${4:-".gfs. .gfs."}}               ;#file format pgb${asub}${fhr}${dump}${yyyymmdd}${cyc} 
export fcyclist=${fcyclist:-${cyclist:-${5:-"00"}}}            ;#forecast cycles
export DATEST=${DATEST:-${6:-20100901}}                        ;#verification starting date
export DATEND=${DATEND:-${7:-20100910}}                        ;#verification ending date
export vhrlist=${vhrlist:-${cyclist:-${8:-"00"}}}              ;#verification hours for each day
export fhmin=${fhmin:-${9:-0}}                                 ;#verification starting hour
export vlength=${vlength:-${10:-384}}                          ;#verification length in hours
export anl_type=${anl_type:-${11:-gfs}}                        ;#analysis type for verification: gfs, gdas, manl, ecmwf or canl
export sfcvsdb=${sfcvsdb:-${12:-YES}}                          ;#include the group of surface variables 
export iauf00=${iauf00:-${13:-NO}}                             ;#force pgbf00=pgbanl for IAU-type forecasts

#
export asub=${asub:-a}                                          ;#string in pgb anal file after pgb
export fsub=${fsub:-f}                                          ;#string in pgb fcst file after pgb 
export canldir=${canldir:-/global/shared/stat/canl}             ;#consensus analysis directory      
export ecmanldir=${ecmanldir:-/global/shared/stat/ecm}          ;#ecmwf analysis directory      
export vsdbsave=${vsdbsave:-/stmp/$LOGNAME/vsdb_exp/vsdb_data}  ;#place where vsdb database is saved
export vsdbhome=${vsdbhome:-/global/save/$LOGNAME/VRFY/vsdb}    ;#script home
export rundir=${rundir:-/stmp/${LOGNAME}/vsdb_exp}              ;#temporary workplace


#-----------------------------------------------
#--for running MPMD
export MPMD=NO
if [ $machine = WCOSS2 ]; then
 export MPMD="YES"
 export nproc=${nproc:-128}
 export APRUNCFP="mpiexec -n \$ncmd --ppn \$ncmd --cpu-bind verbose,depth --depth 1 cfp"
elif [ $machine = WCOSS_D -o $machine = WCOSS_DELL_P3 ]; then
 export MPMD="YES"
 export nproc=${nproc:-28}
 export APRUNCFP="mpirun -n \$ncmd cfp"
elif [ $machine = WCOSS_C ]; then
 export MPMD="YES"
 export nproc=${nproc:-24}
 export APRUNCFP="aprun -j 1 -n \$ncmd -N $nproc -d 1 cfp"
elif [ $machine = HERA ]; then
 export MPMD="NO"
 export nproc=${nproc:-40}
 export APRUNCFP="srun --export=ALL -n \$ncmd --multi-prog"
fi

export APRUN=${APRUN:-""}                                       ;#affix for running batch jobs                
if [ ${batch:-NO} != YES ]; then 
 export MPMD=NO 
 export APRUN=""
fi
#-----------------------------------------------



export scppgb=${scppgb:-NO}                                     ;#whether or not to copy pgb files from client
if [ $scppgb = YES ]; then 
 echo "scppgb capability has been removed. set scppgb=NO. exit" 
 exit
fi

mkdir -p $rundir $vsdbsave 
myhost=`echo $(hostname) |cut -c 1-1 `

##determine forecast output frequency required for verification
export nvhr=`echo $vhrlist |wc -w`           ;#number of verification hours
export nfcyc=`echo $fcyclist |wc -w`         ;#number of forecast cycles per day   
       nfout=$nvhr ; if [ $nfcyc -gt $nvhr ]; then nfout=$nfcyc ; fi
export fhout=`expr 24 \/ $nfout `             ;#forecast output frequency
export nfcst=`expr $vlength \/ $fhout ` 
export vlength=`expr $nfcst \* $fhout  `


#--------------------------------------
#  Create VSDB database

export exe=${exe:-$vsdbhome/exe}
export NWPROD=${NWPROD:-/nwprod}
export wgrb=${wgrib:-$NWPROD/util/exec/wgrib}
export wgrib2=${wgrib:-$NWPROD/util/exec/wgrib2}
export gbindex=${gbindex:-$NWPROD/util/exec/grbindex}
export cpygb=${cpygb:-$NWPROD/util/exec/copygb}
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export cnvgrib=${CNVGRIB:-${cnvgrib:-$NWPROD/util/exec/cnvgrib}}

export gd=${gd:-G2}         ### 2.5x2.5 common grid for verification
if [ $gd = "G2" ]; then 
 export gdtype=-g2          ### 2.5x2.5 common grid for verification
 export npts=10512          ### input pgbanl files resolution 144*73 (2.5x2.5)
fi
if [ $gd = "G3" ]; then 
  export gdtype=-g3        ### 1x1 common grid for verification
  export npts=65160        ### input pgbanl files resolution 360*181 
fi

nexp=`echo $expnlist |wc -w`
n=0 ; for runn in $expnlist ; do n=$((n+1)) ; expname[n]=$runn ; done
n=0 ; for rund in $expdlist ; do n=$((n+1)) ; expdir[n]=$rund  ; done
n=0 ; for comp in $complist ; do n=$((n+1)) ; compname[n]=$comp  ; done
n=0 ; for dump in $dumplist ; do n=$((n+1)) ; dumpname[n]=$dump  ; done
echo ${expname[n]} ${expdir[n]} ${compname[n]} ${dumpname[n]}
#


#----------------------------
# -create mean analysis
#----------------------------
export manldir=${manldir:-$rundir/manl}
mkdir -p $manldir $manldir/tmp; cd $manldir/tmp  ||exit 8

if [ $anl_type = "manl" ]; then
#----------------------------
for vhr in $vhrlist; do
#----------------------------
sdate=$DATEST; while [ $sdate -le $DATEND ]; do
nn=1; while [ $nn -le $nexp ]; do
rm -f input$nn
  export CLIENT=${compname[nn]}
  export cdump=${dumpname[nn]:-".gfs."}
  myclient=`echo $CLIENT |cut -c 1-1 `
  export filename=${expdir[nn]}/${expname[nn]}/pgb${asub}nl${cdump}${sdate}${vhr}
  export filename1=${expdir[nn]}/${expname[nn]}/pgb${asub}nl${cdump}${sdate}${vhr}.grib2
  if [ -s $filename ]; then
   $cpygb $gdtype -x  $filename input$nn
  elif [ -s $filename1 ]; then
   if [ -s ytmp ]; then rm -f ytmp; fi
   $cnvgrib -g21 $filename1 ytmp
   $cpygb $gdtype -x  ytmp input$nn
  else
   echo "$filename does not exist, exit"
   exit 8
  fi
nn=`expr $nn + 1 `
done

output=$manldir/pgbanl.${sdate}${vhr}
rm outtmp*
for var in HGT TMP UGRD VGRD ; do
for lev in 1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 30 20 10; do
  if [ $var = "HGT" ]; then  kpds5=7; kpds6=100; kpds7=$lev ; fi
  if [ $var = "TMP" ]; then  kpds5=11; kpds6=100; kpds7=$lev ; fi
  if [ $var = "UGRD" ]; then  kpds5=33; kpds6=100; kpds7=$lev ; fi
  if [ $var = "VGRD" ]; then  kpds5=34; kpds6=100; kpds7=$lev ; fi
 $vsdbhome/manl/mean_anl.exe $nexp $kpds5 $kpds6 $kpds7 $npts
 mv outtmp outtmp_$var$lev
done
done

rm $output
cat outtmp* >$output
tdate=`$ndate +24 ${sdate}00`
sdate=`echo $tdate |cut -c 1-8`
done   # date
#----------------------------
done    ;#end of vhr 
fi      ;#end of mean analysis
#----------------------------



#----------------------------
nn=1  
while [ $nn -le $nexp ] ; do
#----------------------------

  export exp=${expname[nn]}           ;#exp name
  export exp_dir=${expdir[nn]}        ;#exp directory
  export CLIENT=${compname[nn]}       ;#computer used
  export cdump=${dumpname[nn]:-".$exp."} ;#file dump format
  export obtype=$exp                  ;#obs/analysis data type for verification
  myclient=`echo $CLIENT |cut -c 1-1 `
  if [ $myhost = $myclient ]; then
   if [ $myhost = "s" ]; then CLIENT="cirrus" ;fi
   if [ $myhost = "c" ]; then CLIENT="stratus" ;fi
  fi
  
  #-------------------------------------
  for fcyc in $fcyclist; do
  #-------------------------------------
  # copy forecast data to temporary directory following standard name convention 
   loop=$($ndate -$vlength ${DATEST}${fcyc} )
   while [ $loop -le ${DATEND}${fcyc} ] ; do
    IDAY=`echo $loop |cut -c 1-8`
    comout=$rundir/$exp/${exp}.${IDAY}
    mkdir -p $comout; cd $comout

       if [ $MPMD = YES ]; then
         ncmd=0
         rm -f ./cfile; touch ./cfile
         rm -f ./sfile; touch ./sfile
       fi

       ffcst=00
       while [ $ffcst -le $vlength ] ; do
         filein=$exp_dir/$exp/pgb${fsub}${ffcst}${cdump}${IDAY}${fcyc}
         filein1=$exp_dir/$exp/pgb${fsub}${ffcst}${cdump}${IDAY}${fcyc}.grib2
         fileout=${exp}.t${fcyc}z.pgrbf${ffcst}
         if [ -s $fileout ]; then rm $fileout ;fi
         if [ -s $filein ]; then
           ln -fs  $filein $fileout
         elif [ -s $filein1 ]; then
           if [ $MPMD = YES ]; then
             ncmd=$((ncmd+1))
             echo "$cnvgrib -g21 $filein1 $fileout" >> ./cfile
             echo "$ncmd $cnvgrib -g21 $filein1 $fileout" >> ./sfile
           else
             $cnvgrib -g21 $filein1 $fileout
           fi
         fi
         ffcst=$((ffcst+fhout))
         if [ $ffcst -lt 10 ]; then ffcst=0$ffcst ; fi

         if [ $MPMD = YES ]; then
          if [ $ncmd -eq $nproc -o $ffcst -gt $vlength ]; then
            launcher=$(eval echo $APRUNCFP)
            if [ $machine = HERA ]; then
              $launcher ./sfile
            else
              $launcher ./cfile
            fi
            ncmd=0
            rm -f ./cfile; touch ./cfile
            rm -f ./sfile; touch ./sfile
          fi
         fi

       done


       if [ $iauf00 = YES ];  then
        filein=$exp_dir/$exp/pgb${asub}nl${cdump}${IDAY}${fcyc}
        filein1=$exp_dir/$exp/pgb${asub}nl${cdump}${IDAY}${fcyc}.grib2
        fileout=${exp}.t${fcyc}z.pgrbf00           
        if [ -s $fileout ]; then rm -f $fileout ;fi 
        if [ -s $filein ]; then
          ln -fs  $filein $fileout
        elif [ -s $filein1 ]; then
          $cnvgrib -g21 $filein1 $fileout
        fi
       fi 
    loop=$($ndate +24 $loop)
   done
  #--------------------
  done ;#end of fcyclist
  #--------------------
 
  #------------------------
  for vhr in $vhrlist; do
  #------------------------
  # copy analysis and pgbf00 data to a temporary directory following standard name convention 
   loop=${DATEST}${vhr}
   while [ $loop -le ${DATEND}${vhr} ] ; do
    IDAY=`echo $loop |cut -c 1-8`
    comout=$rundir/$exp/${exp}.${IDAY}
    mkdir -p $comout; cd $comout
       fileout=${exp}.t${vhr}z.pgrbanl        
       if [ -s $fileout ]; then rm $fileout ; fi
       if [ $anl_type = "canl" ]; then 
        if [ -s $canldir/pgb${asub}nl.${IDAY}${vhr} ]; then  
          ln -fs $canldir/pgb${asub}nl.${IDAY}${vhr} $fileout
        elif [ -s $canldir/pgb${asub}nl.canl.${IDAY}${vhr} ]; then
          ln -fs $canldir/pgb${asub}nl.canl.${IDAY}${vhr} $fileout
        fi
       elif [ $anl_type = "ecmwf" ]; then 
        if [ -s $ecmanldir/pgb${asub}nl.${IDAY}${vhr} ] ; then
         ln -fs $ecmanldir/pgb${asub}nl.${IDAY}${vhr} $fileout
        elif [ -s $ecmanldir/pgb${asub}nl.ecm.${IDAY}${vhr} ] ; then
         ln -fs $ecmanldir/pgb${asub}nl.ecm.${IDAY}${vhr} $fileout
        fi
       elif [ $anl_type = "manl" ]; then 
         ln -fs $manldir/pgbanl.${IDAY}${vhr} $fileout
       elif [ $(echo $anl_type |cut -c 1-4) = "fcst" ]; then 
         fcfh=$(echo $anl_type |cut -c 5-7)
         fcini=$($ndate -$fcfh ${IDAY}${vhr})
         filein=$exp_dir/$exp/pgbf${fcfh}${cdump}${fcini}
         filein1=$exp_dir/$exp/pgbf${fcfh}${cdump}${fcini}.grib2
         if [ $fcfh = 00 ]; then
          if [ -s $filein ]; then
           cp $filein $fileout
          elif [ -s $filein1 ]; then
           $cnvgrib -g21 $filein1 $fileout
          fi
         else
          if [ -s xtmp ]; then rm -f xtmp ;fi
          if [ -s $filein ]; then
           cp -p $filein xtmp
          elif [ -s $filein1 ]; then
           $cnvgrib -g21 $filein1 xtmp
          fi
          $vsdbhome/nwprod/util/exec/mvgribdate xtmp $fileout ${IDAY}${vhr}
         fi
       else
        if [ $anl_type = "gdas" ]; then 
         filein=${anl_dir:-$exp_dir/$exp}/pgb${asub}nl.gdas.${IDAY}${vhr}
         filein1=${anl_dir:-$exp_dir/$exp}/pgb${asub}nl.gdas.${IDAY}${vhr}.grib2
        else
         filein=${anl_dir:-$exp_dir/$exp}/pgb${asub}nl${cdump}${IDAY}${vhr}
         filein1=${anl_dir:-$exp_dir/$exp}/pgb${asub}nl${cdump}${IDAY}${vhr}.grib2
        fi
        if [ -s $filein ]; then
          ln -fs  $filein $fileout
        elif [ -s $filein1 ]; then
          $cnvgrib -g21 $filein1 $fileout
        fi
        if [ ! -s $fileout ]; then 
          if [ -s ${exp}.t${vhr}z.pgrbf00 ]; then
           echo " WARNING : $fileout not found ;  using ${exp}.t${vhr}z.pgrbf00 instead"
           ln -fs  ${exp}.t${vhr}z.pgrbf00 $fileout
          else
           echo " WARNING : $fileout not found; no analysis for this verification target"
          fi
        fi
       fi

       ## get pgbf00 for sfc verification
      if [ $iauf00 = NO ];  then
       fileout=${exp}.t${vhr}z.pgrbf00        
       if [ -s $fileout ]; then rm $fileout ; fi
       filein=${anl_dir:-$exp_dir/$exp}/pgb${fsub}00${cdump}${IDAY}${vhr}
       filein1=${anl_dir:-$exp_dir/$exp}/pgb${fsub}00${cdump}${IDAY}${vhr}.grib2
       if [ -s $filein ]; then
         ln -fs  $filein $fileout
       elif [ -s $filein1 ]; then
         $cnvgrib -g21 $filein1 $fileout
       fi
      fi

    loop=$($ndate +24 $loop)
   done
  #------------------------
  done  ;# end vhr for analysis
  #------------------------


  #-------------------------------------------------------------------------
  # compute verification stats
   for vhr in $vhrlist; do
  #------------------------
   CDATE=${DATEST}${vhr}
   while [ $CDATE -le ${DATEND}${vhr} ] ; do
    VFDAY=`echo ${CDATE} | cut -c 1-8`
    anlfile=$rundir/$exp/${exp}.${VFDAY}/${exp}.t${vhr}z.pgrbanl
    if [ -s $anlfile ]; then

     #--------------------------------------------------------------
     #  Three groups of verfication on regular grid (G2, G3, or G4)
     #    anom:  anomaly relative to NCEP CDAS Climatology
     #    pres:  total fields on standard pressure levels
     ##   sfc :  total fields on a single/surface layer
     grouplist="anom pres"
     if [ $sfcvsdb = "YES" ]; then grouplist="anom pres sfc"; fi
     #------------------------
     for group in $grouplist ; do
     #------------------------

       export work=${rundir}/${CDATE}/${exp}/${group}
       if [ -s $work ]; then rm -rf $work ;fi
       mkdir -p $work
       cd $work     ||exit 8
       chmod u+rw *; rm -f *

       echo "======== verfication control cntl_"$group".sh ========"
       ${exe}/cntl_${group}.sh $exp ${VFDAY} ${vhr} $fhmin $vlength $fhout ${obtype} ${gd}
                                                                         
       echo "======= start prepg2g.sh for $exp $group ======="
       ${exe}/prepg2g_exp.sh $rundir $exp $gdtype $group < ${group}_${exp}.ctl >output.prepg2g
      
       echo "======= start getclimateTime.sh ======="
       if [ $group = "anom" ]; then $exe/getclimateTime_new.sh $exp $gdtype ; fi
      
       echo "======= start run_g2g_wave.sh   ======="
       export savedir=${vsdbsave}/${group}/${vhr}Z/${exp}
       $exe/run_g2g_wave.sh $exp ${VFDAY}${vhr}
     #------------------------
     done  ;#end of group 
     #------------------------

   fi
   CDATE=$($ndate +24 $CDATE)
   done   
  #------------------------
  done  ;# end vhr for computing stats
  #------------------------

#--------------------
nn=`expr $nn + 1 `
done ;#end of explist
#--------------------

date
exit
