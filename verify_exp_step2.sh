#!/bin/ksh
set -x

#----------------------------------------------------------------------
#----------------------------------------------------------------------
#     NCEP EMC GLOBAL MODEL VERIFICATION SYSTEM
#            Fanglin Yang, April 2007
#
#  The script computes stats using VSDB database from multiple
#  runs and make maps using GrADS.
#----------------------------------------------------------------------
#----------------------------------------------------------------------

export mdlist=${mdlist:-${1:-"gfs prs45h"}}                         ;#experiment names, up to 10
export fcycle=${fcycle:-${cyclist:-${2:-"00"}}}                     ;#forecast cycles
export vhrlist=${vhrlist:-${cyclist:-${3:-"00 06 12 18"}}}          ;#verification hours for each day
export DATEST=${DATEST:-${4:-20071225}}                             ;#forecast starting date
export DATEND=${DATEND:-${5:-20080201}}                             ;#forecast ending date
export vlength=${vlength:-${6:-384}}                                ;#forecast length in hour

export caplist=${caplist:-"$mdlist"}                                         ;#captions of experiments shown in plots
export vsdbhome=${vsdbhome:-/global/save/$LOGNAME/VRFY/vsdb}                 ;#script home, CHANGE TO YOUR SCRIPT HOLDER 
export vsdbsave=${vsdbsave:-/global/noscrub/$LOGNAME/archive/vsdb_data}      ;#vsdb stats archive directory
export vsdblist=${vsdblist:-""}                                              ;#vsdb stats directories for different models
export gfsvsdb=${gfsvsdb:-/climate/save/$LOGNAME/VRFY/vsdb_data}             ;#where operational GFS vsdb stats are saved
export webhost=${webhost:-"emcrzdm.ncep.noaa.gov"}                           ;#login id on webhost         
export webhostid=${webhostid:-"$LOGNAME"}                                    ;#login id on webhost         
export ftpdir=${ftpdir:-/home/people/emc/www/htdocs/gmb/$webhostid/vsdb}     ;#where maps are  displayed
export doftp=${doftp:-"NO"}                                                  ;#whether or not sent maps to ftpdir 
export rundir0=${rundir:-/stmp/${LOGNAME}/vsdb_exp}                          ;#temporary workplace
export mapdir=${mapdir:-${rundir0}/web}                                      ;#place where maps are saved locally
export maptop=${maptop:-10}                                                  ;#set to 10, 50 or 100 hPa
export sfcvsdb=${sfcvsdb:-"NO"}                                              ;#include the group of surface variables
export presvsdb=${presvsdb:-"YES"}                                           ;#include the group of pres variables
export anomvsdb=${anomvsdb:-"YES"}                                           ;#include the group of anom variables
export anomhgt500=${anomhgt500:-"NO"}                                        ;#a special popular case
export maskmiss=${maskmiss:-1}            ;#remove missing data from all models to unify sample size, 0-->NO, 1-->Yes
export makemap=${makemap:-"YES"}                                             ;#whether or not to make maps           
export scorecard=${scorecard:-NO}                                            ;#create scorecard text files
export scoredir=${scoredir:-$rundir/score}                                   ;#place to save scorecard output
export copymap=${copymap:-"YES"}                                             ;#whether or not to copy maps to mapdir
export archmon=${archmon:-"NO"}                                              ;#whether or not to make monthly archive
export machine=${machine:-"IBM"}                                             ;#IBM, ZEUS, JET, GAEA etc
export ACCOUNT=${ACCOUNT:-GFS-T2O}                                           ;#ibm computer ACCOUNT task
export CUE2RUN=${CUE2RUN:-1}                                                 ;#dev or devhigh or 1
export CUE2FTP=${CUE2FTP:-$CUE2RUN}                                          ;#queue for data transfer 
export GROUP=${GROUP:-g01}                                                   ;#account group     
export NWPROD=${NWPROD:-/nwprod}                                             ;#common utilities and libs included in /nwprod
export SUBJOB=${SUBJOB:-$NWPROD/ush/sub}                                     ;#script for submitting batch jobs
export cputime=${cputime:-6:00:00}                                           ;#CPU time hh:mm:ss to run each batch job
export FC=${FC:-xlf90}                                                       ;#compiler
export FFLAG=${FFLAG:-" "}                                                   ;#compiler options
export GRADSBIN=${GRADSBIN:-/usrx/local/grads/bin}                           ;#grads executable
export GADDIR=${GADDIR:-/usrx/local/grads/data}                           ;#grads executable
export IMGCONVERT=${IMGCONVERT:-convert}                                     ;#image magic converter 
export gd=${gd:-G2}                                                          ;#source data resolution G2->2.5deg, G3->1deg, G4->0.5deg
mkdir -p $rundir0 $mapdir $scoredir

##determine forecast output frequency required for verification
export nvhr=`echo $vhrlist |wc -w`                     ;#number of verification hours
export fhout=`expr 24 \/ $nvhr `                       ;#forecast output frequency

penode="1/1/S"                                         ;# one pe, and shared on IBM
##if [ $machine != "IBM" ]; then penode="1/1/N"  ;fi   ;# one pe and non-shared on other machines

#--for running MPMD
export MPMD=${MPMD:-YES}
if [ $machine != WCOSS2 -a $machine != JET ]; then export MPMD=NO; fi
if [ $CUE2RUN = dev_shared ]; then export MPMD=NO; fi
nproc=${nproc:-24}                                     ;#number of PEs per node
if [ $machine = WCOSS2 ]; then nproc=128; fi 

#--------------------------------------
##---gather vsdb stats from different experiments and put in a central location
set -A vsdbdir $vsdblist
vsdball=$rundir0/vsdb_data
mkdir -p $vsdball; cd $vsdball ||exit 8
for vtype in anom pres sfc; do
for vhour in $vhrlist ; do
 mkdir -p ${vtype}/${vhour}Z
 nn=0
 for exp in $mdlist ; do
  vsdbexp=${vsdbdir[$nn]}
  if [ `eval echo ${#vsdbexp}` -le 1 ]; then vsdbexp=$vsdbsave; fi
  if [ $exp = gfs ]; then vsdbexp=$gfsvsdb ; fi
  if [ -s ${vsdball}/${vtype}/${vhour}Z/${exp} ]; then rm ${vsdball}/${vtype}/${vhour}Z/${exp} ;fi
  ln -fs ${vsdbexp}/${vtype}/${vhour}Z/${exp} ${vsdball}/${vtype}/${vhour}Z/.
  nn=`expr $nn + 1 `
 done
done
done
#--------------------------------------

if [ $doftp = "YES" ]; then
ssh -q -l $webhostid ${webhost} " ls -l ${ftpdir}/www/null "
if [ $? -ne 0 ]; then
 ssh -q -l $webhostid ${webhost} " mkdir  -p ${ftpdir} "
 scp -q ${vsdbhome}/vsdb_exp_webpage.tar  ${webhostid}@${webhost}:${ftpdir}/.
 ssh -q -l $webhostid ${webhost} "cd ${ftpdir} ; tar -xvf vsdb_exp_webpage.tar "
 ssh -q -l $webhostid ${webhost} "rm ${ftpdir}/vsdb_exp_webpage.tar "
fi
fi
#--------------------------------------

sdate=$DATEST                                 ;#start of verification date
export edate=$DATEND                          ;#end of verification date
export sorcdir=$vsdbhome/map_util
export vsdb_data=$vsdball

y1=`echo $sdate |cut -c 1-4 `
m1=`echo $sdate |cut -c 5-6 `
d1=`echo $sdate |cut -c 7-8 `
y2=`echo $edate   |cut -c 1-4 `
m2=`echo $edate   |cut -c 5-6 `
d2=`echo $edate   |cut -c 7-8 `
ndays=`${sorcdir}/days.sh -a $y2 $m2 $d2 - $y1 $m1 $d1`
export ndays=`expr $ndays + 1 `
export fdays=`expr $vlength \/ 24 `                  ;#forecast length in days to be verified
export listvar1a=fcycle,mdlist,caplist,vsdb_data,vhrlist,vlength,fhout,webhost,webhostid,ftpdir,doftp,mapdir,maptop,scorecard,scoredir
export listvar1b=sfcvsdb,maskmiss,makemap,copymap,archmon,NWPROD,FC,FFLAG,GRADSBIN,GADDIR,IMGCONVERT,edate,sorcdir,ndays,fdays
export listvar1c=vsdbhome,SUBJOB,ACCOUNT,GROUP,CUE2RUN,CUE2FTP
export listvar1="$listvar1a,$listvar1b,$listvar1c"

#=====================================================
#--for MPMD
nc=0
export poedir=$rundir0/poe_script
if [ -s $poedir ]; then rm -rf $poedir ; fi
mkdir -p $poedir
#=====================================================

##--split the regions to speed up computation
narea=1
for region in "$gd/NHX" "$gd/SHX" "$gd/TRO"  "$gd" "$gd/PNA" ; do
 reg1=`echo $region | sed "s?/??g"`
 export rundir=${rundir0}/${reg1}
 export reglist="$region"
 mkdir -p $rundir
#=====================================================

#------------------------------------
#-- a special and popular case
#------------------------------------
if [ $anomhgt500 = YES ]; then
 export vtype=anom 
 export listvar3=$listvar1,vtype
 export vnamlist="HGT"
 export levlist="P500"
 ${sorcdir}/allcenters_1cyc.sh $edate $ndays $fdays 
fi
#------------------------------------


# ------------------------------------------------------------------------------
if [ $anomvsdb = "YES" ]; then
# ------------------------------------------------------------------------------
#A) anomaly correlation on single pressure layer
    export vtype=anom 
    export listvar3=$listvar1,vtype
# ------------------------------------------------------------------------------

   #----------------------
   if [ $MPMD = NO ]; then
   #----------------------
    export vnamlist="HGT HGT_WV1/0-3 HGT_WV1/4-9 HGT_WV1/10-20"
    export levlist="P1000 P700 P500 P250"
    export listvar=$listvar3,vnamlist,reglist,levlist,rundir 
    $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j HGTanom${narea} -o $rundir/HGT_anom.out \
           ${sorcdir}/allcenters_1cyc.sh $edate $ndays $fdays
    if [ $? -ne 0 ]; then ${sorcdir}/allcenters_1cyc.sh $edate $ndays $fdays  ; fi
    sleep 3

    export vnamlist="WIND U V T"
    export levlist="P850 P500 P250"
    export listvar=$listvar3,vnamlist,reglist,levlist,rundir 
    $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j UVTanom${narea} -o $rundir/UVT_anom.out \
           ${sorcdir}/allcenters_1cyc.sh $edate $ndays $fdays
    if [ $? -ne 0 ]; then ${sorcdir}/allcenters_1cyc.sh $edate $ndays $fdays  ; fi
    sleep 3

    export vnamlist="PMSL"
    export levlist="MSL"
    export listvar=$listvar3,vnamlist,reglist,levlist,rundir
    $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j PMSLanom${narea} -o $rundir/PMSL_anom.out \
            ${sorcdir}/allcenters_1cyc.sh $edate $ndays $fdays
    if [ $? -ne 0 ]; then ${sorcdir}/allcenters_1cyc.sh $edate $ndays $fdays  ; fi
     sleep 3

   #----------------------
   else
   #----------------------
    export vnamlist_all="HGT HGT_WV1/0-3 HGT_WV1/4-9 HGT_WV1/10-20 WIND U V T PMSL"
    for yvar in $vnamlist_all ; do
     export vnamlist="$yvar"
     export levlist="P850 P500 P250"
     word1=$(echo $yvar | cut -c 1)
     if [ $word1 = H ]; then export levlist="P1000 P700 P500 P250" ;fi
     if [ $word1 = P ]; then export levlist="MSL" ;fi
     export listvar=$listvar3,vnamlist,reglist,levlist,rundir 

     nc=$((nc+1))
     xfile=$poedir/poejob${nc}.sh
     if [ -s $xfile ]; then rm -f $xfile ; touch $xfile ;fi
     for xvar in `echo $listvar | sed "s?,? ?g"`; do
      eval export vartmp="\$$(echo $xvar)"
      echo "export $(echo $xvar)=\"$vartmp\""   >>$xfile
     done
     echo "${sorcdir}/allcenters_1cyc.sh $edate $ndays $fdays"    >>$xfile
    done

   #-------------
   fi
   #-------------
# ---------------------------------------------------
fi
# ---------------------------------------------------


# ------------------------------------------------------------------------------
if [ $presvsdb = "YES" ]; then
# ------------------------------------------------------------------------------
#B) rms and bias 
    export vtype=pres 
    export listvar3=$listvar1,vtype
# ------------------------------------------------------------------------------
    if [ $maptop = "10" ]; then
     export levlist="P1000 P925 P850 P700 P500 P400 P300 P250 P200 P150 P100 P50 P20 P10"
    elif [ $maptop = "50" ]; then
     export levlist="P1000 P925 P850 P700 P500 P400 P300 P250 P200 P150 P100 P50"
    elif [ $maptop = "100" ]; then
     export levlist="P1000 P925 P850 P700 P500 P400 P300 P250 P200 P150 P100"
    fi

   #----------------------
   if [ $MPMD = NO ]; then
   #----------------------
    export vnamlist="HGT"
    export listvar=$listvar3,vnamlist,reglist,levlist,rundir 
    $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j HGTpres${narea} -o $rundir/HGT_pres.out \
           ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays
    if [ $? -ne 0 ]; then ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays  ; fi
    sleep 3

    export vnamlist="WIND"
    export listvar=$listvar3,vnamlist,reglist,levlist,rundir 
    $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j WINDpres${narea} -o $rundir/WIND_pres.out \
           ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays
    if [ $? -ne 0 ]; then ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays  ; fi
    sleep 3

    export vnamlist="U"
    export listvar=$listvar3,vnamlist,reglist,levlist,rundir 
    $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j Upres${narea} -o $rundir/U_pres.out \
           ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays
    if [ $? -ne 0 ]; then ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays  ; fi
    sleep 3

    export vnamlist="V"
    export listvar=$listvar3,vnamlist,reglist,levlist,rundir 
    $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j Vpres${narea} -o $rundir/V_pres.out \
           ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays
    if [ $? -ne 0 ]; then ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays  ; fi
    sleep 3

    export vnamlist="T"
    export listvar=$listvar3,vnamlist,reglist,levlist,rundir 
    $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j Tpres${narea} -o $rundir/T_pres.out \
           ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays
    if [ $? -ne 0 ]; then ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays  ; fi
    sleep 3

    export vnamlist="O3"
    export levlist="P100 P70 P50 P30 P20 P10"
    export listvar=$listvar3,vnamlist,reglist,levlist,rundir 
    $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j O3pres${narea} -o $rundir/O3_pres.out \
           ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays
    if [ $? -ne 0 ]; then ${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays  ; fi
    sleep 3

   #----------------------
   else
   #----------------------
    export vnamlist_all="HGT WIND U V T O3"                                             
    for yvar in $vnamlist_all ; do
     export vnamlist="$yvar"
     if [ $yvar = O3 ]; then export levlist="P100 P70 P50 P30 P20 P10" ;fi
     export listvar=$listvar3,vnamlist,reglist,levlist,rundir 

     nc=$((nc+1))
     xfile=$poedir/poejob${nc}.sh
     if [ -s $xfile ]; then rm -f $xfile ; touch $xfile ;fi
     for xvar in `echo $listvar | sed "s?,? ?g"`; do
      eval export vartmp="\$$(echo $xvar)"
      echo "export $(echo $xvar)=\"$vartmp\""   >>$xfile
     done
     echo "${sorcdir}/allcenters_rmsmap.sh $edate $ndays $fdays"    >>$xfile
    done

   #-------------
   fi
   #-------------
# ---------------------------------------------------
fi
# ---------------------------------------------------
#=====================================================
narea=`expr $narea + 1`
done   ;#end of region
#====================================================


# ------------------------------------------------------------------------------
if [ $sfcvsdb = "YES" ]; then
# ------------------------------------------------------------------------------
#C) surface fields, split the job for different processors
     export rundir=${rundir0}/sfc 
     mkdir -p $rundir
     export vtype=sfc
     export levlist="SL1L2"
     export reglist="$gd $gd/NHX $gd/SHX $gd/TRO $gd/N60 $gd/S60 $gd/NPO $gd/SPO $gd/NAO $gd/SAO $gd/CAM $gd/NSA"
     export listvar2=$listvar1,vtype,levlist,reglist
     sleep 3

   #----------------------
   if [ $MPMD = NO ]; then
   #----------------------
     export vnamlist="CAPE CWAT PWAT HGTTRP"
     export listvar=$listvar2,vnamlist,rundir
     $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j sfc_CAPE -o $rundir/sfc_CAPE.out \
            ${sorcdir}/sfcfcst_1cyc.sh $edate $ndays $fdays
     if [ $? -ne 0 ]; then ${sorcdir}/sfcfcst_1cyc.sh $edate $ndays $fdays;  fi          
     sleep 3
 
     export vnamlist="TMPTRP HPBL PSFC PSL"
     export listvar=$listvar2,vnamlist,rundir
     $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j sfc_PSL -o $rundir/sfc_PSL.out \
            ${sorcdir}/sfcfcst_1cyc.sh $edate $ndays $fdays
     if [ $? -ne 0 ]; then ${sorcdir}/sfcfcst_1cyc.sh $edate $ndays $fdays;  fi          
     sleep 3
 
     export vnamlist="RH2m SPFH2m T2m TOZNE TG"
     export listvar=$listvar2,vnamlist,rundir
     $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j sfc_RH2 -o $rundir/sfc_RH2.out \
            ${sorcdir}/sfcfcst_1cyc.sh $edate $ndays $fdays
     if [ $? -ne 0 ]; then ${sorcdir}/sfcfcst_1cyc.sh $edate $ndays $fdays;  fi          
     sleep 3
 
     export vnamlist="U10m V10m WEASD TSOILT WSOILT"
     export listvar=$listvar2,vnamlist,rundir
     $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p $penode -t $cputime -j sfc_U10m -o $rundir/sfc_U10m.out \
            ${sorcdir}/sfcfcst_1cyc.sh $edate $ndays $fdays
     if [ $? -ne 0 ]; then ${sorcdir}/sfcfcst_1cyc.sh $edate $ndays $fdays;  fi          

   #----------------------
   else
   #----------------------
    export vnamlist_all="CAPE CWAT PWAT HGTTRP TMPTRP HPBL PSFC PSL RH2m SPFH2m T2m TOZNE TG U10m V10m WEASD TSOILT WSOILT"
    for yvar in $vnamlist_all ; do
     export vnamlist="$yvar"
     export listvar=$listvar2,vnamlist,rundir

     nc=$((nc+1))
     xfile=$poedir/poejob${nc}.sh
     if [ -s $xfile ]; then rm -f $xfile ; touch $xfile ;fi
     for xvar in `echo $listvar | sed "s?,? ?g"`; do
      eval export vartmp="\$$(echo $xvar)"
      echo "export $(echo $xvar)=\"$vartmp\""   >>$xfile
     done
     echo "${sorcdir}/sfcfcst_1cyc.sh $edate $ndays $fdays"    >>$xfile
    done
   #-------------
   fi
   #-------------
# ------------------------------------------------------------------------------
fi
# ------------------------------------------------------------------------------


#===============================
# submit MPMD jobs
#===============================
if [ $MPMD = YES ]; then

cd $poedir ||exit 8
chmod u+x poejob*.sh
ncount=$(ls -l poejob*.sh |wc -l)
nc=0; iproc=0; node=1

while [ $nc -lt $ncount ]; do
  if [ $iproc -ge $nproc ]; then iproc=0; node=$((node+1)); fi
  poescript=$poedir/poe_node${node}
  jobscript=$poedir/job_node${node}.sh
  if [ $iproc -eq 0 ]; then
    rm -f $poescript; touch $poescript
    rm -f $jobscript; touch $jobscript
  fi
  nc=$((nc+1))
  iproc=$((iproc+1))
  echo "$poedir/poejob${nc}.sh" >>$poescript

  #...............................................
  if [ $iproc -eq $nproc -o $nc -eq $ncount ]; then
  #...............................................
   chmod u+x $poescript
   echo "export NODES=1"                      >>$jobscript
   echo "chmod 775 $poescript"                >>$jobscript
   echo "export MP_PGMMODEL=mpmd"             >>$jobscript
   echo "export MP_CMDFILE=$poescript"        >>$jobscript
   if [ $machine = WCOSS_C ] ; then
     echo ". /opt/modules/3.2.6.7/init/sh"    >>$jobscript
     echo "module load cfp-intel-sandybridge" >>$jobscript
     echo "launcher='aprun -n $iproc -N $iproc -j 1 -d 1 cfp' " >>$jobscript
     echo "\$launcher \$MP_CMDFILE"           >>$jobscript
   elif [ $machine = WCOSS_D ] ; then
     echo ". $MODULESHOME/init/bash"          >>$jobscript
     echo "module load CFP/2.0.1"             >>$jobscript
     echo "launcher='mpirun ' "               >>$jobscript
     echo "\$launcher -n $iproc cfp \$MP_CMDFILE "           >>$jobscript
   else
     echo "launcher=mpirun.lsf"               >>$jobscript
     echo "\$launcher"                        >>$jobscript
   fi

  chmod u+x $jobscript
  $SUBJOB -a $ACCOUNT  -q $CUE2RUN -p $iproc/1/N -r 1024/1/$iproc -t $cputime -j vsdbpoe$node -o $rundir0/vsdbpoe$node.out  $jobscript
  #...............................................
  fi
  #...............................................
done
#===============================
fi
#===============================

exit




