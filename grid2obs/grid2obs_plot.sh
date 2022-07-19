#!/bin/ksh
set -x

#----------------------------------------------------------------------
#----------------------------------------------------------------------
#----------------------------------------------------------------------
#  Fanglin Yang, November 2011
#  This script make graphics using grid2obs verification statistics saved 
#  in vsdb format. It is aimed to compare 1) surface observations of T2m, 
#  RH2m amd wind at 10m over the Continental United Stats and the Alaska 
#  region, and 2) upper-air observations of T, Q, RH and Wind from rawinsonde, 
#  dropsonde, and profilers over the global and its subregions. 
#----------------------------------------------------------------------
#----------------------------------------------------------------------

export mdlist=${mdlist:-"gfs prexp"}                           ;#experiment names, up to 10
export caplist=${caplist:-$mdlist}                             ;#exp captions on plots
export cyclistx=${cyclist:-"00 06 12 18" }                     ;#forecast cycle to be verified
export DATEST=${DATEST:-20130501}                              ;#forecast starting date
export DATEND=${DATEND:-20130801}                              ;#forecast ending date
export vlength=${vlength:-168}                                 ;#forecast length in hour
export fhoutair=${fhoutair:-${fhout:-6}}                       ;#forecast output frequency in hours for raobs vrfy
export fhoutsfc=${fhoutsfc:-${fhout:-6}}                       ;#forecast output frequency in hours for sfc vrfy
export obairtype=${obairtype:-ADPUPA}                          ;#uppair observation type, ADPUPA or ANYAIR
export plotair=${plotair:-"YES"}                               ;#make upper plots                         
export plotsfc=${plotsfc:-"YES"}                               ;#make sfc plots                         
export batch=${batch:-"YES"}                                   ;#run in batch mode                      
export machine=${machine:-WCOSS_C}                             ;#computer name                                


export vsdbhome=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}             ;#script home
export vsdbsave=${vsdbsave:-/global/save/$LOGNAME/vrfygfs/vsdb_data}         ;#where vsdb stats are saved
export opsvsdb=${opsvsdb:-/global/save/Fanglin.Yang/vrfygfs/vsdb_data}       ;#operational model  vsdb data base        
export webhost=${webhost:-"emcrzdm.ncep.noaa.gov"}                           ;#login id on webhost         
export webhostid=${webhostid:-"wx24fy"}                                      ;#login id on webhost         
export ftpdir=${ftpdir:-/home/people/emc/www/htdocs/gmb/$webhostid/vsdb}     ;#where maps are  displayed
export doftp=${doftp:-"YES"}                                                 ;#whether or not sent maps to ftpdir 
export rundir=${rundir:-/stmpd2/$LOGNAME/g2oplot$$}                            ;#temporary workplace
export locwebdir=${locwebdir:-$rundir/web}                                   ;#local web directory               
export mapdir=$locwebdir/g2o                                                 ;#place where maps are saved locally
export maskmiss=${maskmiss:-1}            ;#remove missing data from all models to unify sample size, 0-->NO, 1-->Yes
export copymap=${copymap:-"YES"}                                             ;#whether or not to copy maps to mapdir
export ACCOUNT=${ACCOUNT:-GFS-T2O}                                           ;#ibm computer ACCOUNT task
export CUE2RUN=${CUE2RUN:-dev_shared}                                        ;#dev or devhigh or 1
export CUE2FTP=${CUE2FTP:-transfer}                                          ;#data transfer queue
export GROUP=${GROUP:-g01}                                                   ;#account group     
export NWPROD=${NWPROD:-/global/save/Fanglin.Yang/VRFY/vsdb/nwprod}          ;#utilities and libs included in /nwprod
export SUBJOB=${SUBJOB:-$vsdbhome/bin/sub_wcoss}                             ;#script for submitting batch jobs
export FC=${FC:-/usrx/local/intel/composer_xe_2011_sp1.11.339/bin/intel64/ifort}  ;#compiler
export FFLAG=${FFLAG:-"-O2 -convert big_endian -FR"}                              ;#compiler options
export cputime=${cputime:-6:00:00}                                           ;#CPU time hh:mm:ss to run each batch job
export memory=${memory:-3072}
export share=${share:-N}
if [ $CUE2RUN = dev_shared ]; then export memory=1024; export share=S; fi
mkdir -p $rundir $locwebdir $mapdir

#--for running MPMD
export MPMD=${MPMD:-YES}     
if [ $machine != WCOSS2 ]; then MPMD=NO; fi
if [ $CUE2RUN = dev_shared ]; then  MPMD=NO; fi
nproc=${nproc:-24}           ;#number of PEs per node


#--------------------------------------
#--------------------------------------
export sdate=$DATEST                                 ;#start of verification date
export edate=$DATEND                                 ;#end of verification date
export sorcdir=$vsdbhome/grid2obs
export vsdb_data=${vsdbsave}/grid2obs

y1=`echo $sdate |cut -c 1-4 `
m1=`echo $sdate |cut -c 5-6 `
d1=`echo $sdate |cut -c 7-8 `
y2=`echo $edate   |cut -c 1-4 `
m2=`echo $edate   |cut -c 5-6 `
d2=`echo $edate   |cut -c 7-8 `
ndays=`$vsdbhome/map_util/days.sh -a $y2 $m2 $d2 - $y1 $m1 $d1`
export ndays=`expr $ndays + 1 `
export vlength=$((vlength/24*24))
set -A cycname none $cyclistx

# ------------------------------------------------------------------------------
cd $locwebdir ||exit
tar xvf ${sorcdir}/g2o_webpage.tar     
if [ $doftp = "YES" ]; then
 if [ $machine = WCOSS_C -o $machine = WCOSS ]; then
  ssh -q -l $webhostid ${webhost} " ls -l ${ftpdir}/g2o "
  if [ $? -ne 0 ]; then
   ssh -q -l $webhostid ${webhost} " mkdir -p ${ftpdir}/g2o "
   scp -q ${sorcdir}/g2o_webpage.tar  ${webhostid}@${webhost}:${ftpdir}/.
   ssh -q -l $webhostid ${webhost} "cd ${ftpdir} ; tar -xvf g2o_webpage.tar "
   ssh -q -l $webhostid ${webhost} "rm ${ftpdir}/g2o_webpage.tar "
  fi
 fi
fi
cd $rundir || exit 8
rm g2oair*.out g2osfc*.out

##make sympoblic link to operational grid2obs vsdb database in case operational scores are used for comparison
if [ $vsdbsave != "$opsvsdb" ]; then
 mkdir -p $vsdb_data/00Z  $vsdb_data/06Z $vsdb_data/12Z $vsdb_data/18Z
 ln -fs $opsvsdb/grid2obs/00Z/gfs $vsdb_data/00Z/gfs
 ln -fs $opsvsdb/grid2obs/06Z/gfs $vsdb_data/06Z/gfs
 ln -fs $opsvsdb/grid2obs/12Z/gfs $vsdb_data/12Z/gfs
 ln -fs $opsvsdb/grid2obs/18Z/gfs $vsdb_data/18Z/gfs
fi

export listvar1=edate,ndays,vsdb_data,sorcdir,ftpdir,doftp,mapdir,copymap,webhost,webhostid,maskmiss,vlength
export listvar2=SUBJOB,ACCOUNT,CUE2RUN,CUE2FTP,GROUP,FC,FFLAG,NWPROD
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
#  make plots of fit2obs surface varibales (T2m, RH2m, 10-m Wind Speed)

if [ $plotsfc = YES ]; then
export vnamlist="T RH VWND DPT TCLD SLP"             
export levlist="SFC"             
bigregion="west east APL NEC SEC MDW LMV GMC NWC SWC GRB NMT SMT SWD NPL SPL NAK SAK"
nreg=`echo $bigregion |wc -w`

iproc=0
nc=0
node=1

#------------------------------
for regname in $bigregion ; do
#------------------------------
  case $regname in
    west)  export reglist="NWC SWC GRB NMT SMT SWD NPL SPL"   
           export regdef="CONUS West"                     ;;
    east)  export reglist="APL NEC SEC MDW LMV GMC"           
           export regdef="CONUS East"                     ;;
     APL)  export reglist="APL"                               
           export regdef="Appalachian Region"             ;;
     NEC)  export reglist="NEC"                               
           export regdef="Northeast Coast"                ;;
     SEC)  export reglist="SEC"                               
           export regdef="Southeast Coast"                ;;
     MDW)  export reglist="MDW"                               
           export regdef="Midwest"                         ;;
     LMV)  export reglist="LMV"                               
           export regdef="Lower Mississippi Valley"       ;;
     GMC)  export reglist="GMC"                               
           export regdef="Gulf American Coast"            ;;
     NWC)  export reglist="NWC"                               
           export regdef="Northwest Coast"                ;;
     SWC)  export reglist="SWC"                               
           export regdef="Southwest Coast"                ;;
     GRB)  export reglist="GRB"                               
           export regdef="GRB  "          ;;
     NMT)  export reglist="NMT"                               
           export regdef="Northen Mountain Region "       ;;
     SMT)  export reglist="SMT"                               
           export regdef="Southen Mountain Region "       ;;
     SWD)  export reglist="SWD"                               
           export regdef="Southwest Dessert"              ;;
     NPL)  export reglist="NPL"                               
           export regdef="Northern Great Plains"          ;;
     SPL)  export reglist="SPL"                               
           export regdef="Southern Great Plains"          ;;
     NAK)  export reglist="NAK"                               
           export regdef="Northern Alaska"                ;;
     SAK)  export reglist="SAK"                               
           export regdef="Southern Alaska"                ;;

#     NA)  export reglist="NEC APL"                           
#          export regdef="CONUS Northeast"                 ;;
#     MN)  export reglist="MDW NPL"                           
#          export regdef="N. Plains and Mid-West"  ;;
#   SSSG)  export reglist="SWC SWD SMT GRB"                   
#          export regdef="CONUS Southwest"                 ;;
#    LGS)  export reglist="LMV GMC SEC"                       
#          export regdef="CONUS Southeast"                 ;;
#     NN)  export reglist="NWC NMT"                           
#          export regdef="CONUS Northwest"                 ;;
#    SPL)  export reglist="SPL"                               
#          export regdef="S. Plains"            ;;
#     AK)  export reglist="NAK SAK"                           
#          export regdef="Alaska"                          ;;
       *)  echo " $regname not defined in $0 "; exit ;;
  esac  

  export fhout=$fhoutsfc
  export regname=$regname
  export tmpdir=$rundir/sfc
  export listvar=$listvar1,$listvar2,mdlist,caplist,cyclist,levlist,vnamlist,reglist,regdef,tmpdir,regname,fhout

#---------------------------------------------------------------
#---use MPMD on NCEP IBM/CRAY to distribute jobs to multiple PEs
#---west and east regions are further divided for each cycle.
if [ $MPMD = YES ]; then
#---------------------------------------------------------------

export poedir=$rundir/sfc/poe_script
if [ ! -s $poedir ]; then mkdir -p $poedir; fi

export bigvnamlist="T RH VWND DPT TCLD SLP"
nvar=`echo $bigvnamlist |wc -w`
ncyc=`echo $cyclistx |wc -w`
ncount=$(( (nreg-2)*nvar + 2*ncyc*nvar ))
mcyc=1; if [ $regname = west -o $regname = east ]; then mcyc=$ncyc ; fi

kcyc=1; while [ $kcyc -le $mcyc ]; do
  if [ $mcyc -eq 1 ]; then
   export cyclist="$cyclistx"
  else
   export cyclist="${cycname[$kcyc]}"
  fi
for varname in $bigvnamlist; do
  export vnamlist="$varname"

  if [ $iproc -ge $nproc ]; then iproc=0; node=$((node+1)); fi
  poescript=$poedir/poescript${node}
  jobscript=$poedir/poejob${node}.sh
  if [ $iproc -eq 0 ]; then
    rm -f $poescript; touch $poescript
    rm -f $jobscript; touch $jobscript
  fi
  nc=$((nc+1))
  iproc=$((iproc+1))

  xfile=$poedir/g2o_sfcmap_${nc}.sh
  if [ -s $xfile ]; then rm -f $xfile ; touch $xfile ;fi
  for xvar in `echo $listvar | sed "s?,? ?g"`; do
   eval export vartmp="\$$(echo $xvar)"
   echo "export $(echo $xvar)=\"$vartmp\""   >>$xfile
  done
  echo "${sorcdir}/scripts/g2o_sfcmap.sh"    >>$xfile
  chmod u+x $xfile
  echo "$xfile" >>$poescript

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
   elif [ $machine = WCOSS2 ] ; then
     echo "module load cfp/2.0.4"             >>$jobscript
     echo "launcher='mpiexec -n $iproc -ppn $iproc --cpu-bind verbose,depth --depth 1 cfp' " >>$jobscript
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
  $SUBJOB -a $ACCOUNT  -q $CUE2RUN -p $iproc/1/N -r 1024/1/$iproc -t $cputime -j g2osfcpoe$node -o $rundir/g2osfcpoe$node.out  $jobscript
  #...............................................
  fi
  #...............................................
done ;#varname
 kcyc=$((kcyc+1))
done ;#cyclist

#--------------------------------------------------------------------------
#---for each region, all variables all cycles included in one job. slow!
else
#--------------------------------------------------------------------------

 export cyclist="$cyclistx"
 if [ $batch = YES ]; then
  $SUBJOB -e listvar,$listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/$share -r $memory/1 -t $cputime -j g2osfc$regname -o $rundir/g2osfc${regname}.out  ${sorcdir}/scripts/g2o_sfcmap.sh $regname
  if [ $? -ne 0 ]; then ${sorcdir}/scripts/g2o_sfcmap.sh $regname ; fi
 else
  ${sorcdir}/scripts/g2o_sfcmap.sh $regname  &
 fi
#------------------------------
fi
#------------------------------
#------------------------------
done ;#region
#------------------------------
fi
#------------------------------




# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
#  make plots of fit2obs upper air varibales (T, RH, Vector Wind)

if [ $plotair = YES ]; then
export vnamlist="T Q VWND RH"
export levlist="P1000 P925 P850 P700 P500 P400 P300 P250 P200 P150 P100 P50"             
#export levlist="P1000 P925 P850 P700 P500 P400 P300 P250 P200 P150 P100 P50 P20 P10"             

#regioncode="gglb g236 gnh gsh gtrp geur gasi gafr gsa gna gaus"
regioncode="gglb g236 gnh gsh gtrp"
nreg=`echo $regioncode |wc -w`

iproc=0
nc=0
node=1

#--------------------------------------------
for regname in $regioncode ; do
#--------------------------------------------
  case $regname in
    gglb)  export reglist="GGLB"                              
           export regdef="Globe"      ;;
    g236)  export reglist="G236"                              
           export regdef="CONUS"      ;;
     gnh)  export reglist="GNH"                               
           export regdef="NH"         ;;
     gsh)  export reglist="GSH"                               
           export regdef="SH"         ;;
    gtrp)  export reglist="GTRP"                               
           export regdef="Tropics"    ;;
    geur)  export reglist="GEUR"                               
           export regdef="Europe"     ;;
    gasi)  export reglist="GASI"                               
           export regdef="Asia"     ;;
    gafr)  export reglist="GAFR"                               
           export regdef="Africa"     ;;
     gna)  export reglist="GNA"                                
           export regdef="N. America"  ;;
     gsa)  export reglist="GSA"                                
           export regdef="S. America"  ;;
    gaus)  export reglist="GAUS"                                
           export regdef="Australia"  ;;
       *)  echo " $regname not defined in $0 "; exit ;;
  esac  

  export fhout=$fhoutair
  export regname=$regname
  export tmpdir=$rundir/air
  export listvar=$listvar1,$listvar2,mdlist,caplist,cyclist,levlist,vnamlist,reglist,regdef,tmpdir,regname,fhout,obairtype


#---------------------------------------------------------------
#---use MPMD on NCEP IBM/CRAY to distribute jobs to multiple PEs
if [ $MPMD = YES ]; then
#---------------------------------------------------------------
export poedir=$rundir/air/poe_script
if [ ! -s $poedir ]; then mkdir -p $poedir; fi

export bigvnamlist="T Q VWND RH"
nvar=`echo $bigvnamlist |wc -w`
export bigcyclist="$cyclistx"                    
ncyc=`echo $bigcyclist |wc -w`
ncount=$((nreg*nvar*ncyc))


for cyc in $bigcyclist; do
  export cyclist="$cyc"
for varname in $bigvnamlist; do
  export vnamlist="$varname"

  if [ $iproc -ge $nproc ]; then iproc=0; node=$((node+1)); fi
  poescript=$poedir/poescript${node}
  jobscript=$poedir/poejob${node}.sh
  if [ $iproc -eq 0 ]; then
    rm -f $poescript; touch $poescript
    rm -f $jobscript; touch $jobscript
  fi
  nc=$((nc+1))
  iproc=$((iproc+1))

  xfile=$poedir/g2o_airmap_${nc}.sh
  if [ -s $xfile ]; then rm -f $xfile ; touch $xfile ;fi
  for xvar in `echo $listvar | sed "s?,? ?g"`; do
   eval export vartmp="\$$(echo $xvar)"
   echo "export $(echo $xvar)=\"$vartmp\""   >>$xfile
  done
  echo "${sorcdir}/scripts/g2o_airmap.sh"    >>$xfile
  chmod u+x $xfile
  echo "$xfile" >>$poescript

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
  $SUBJOB -a $ACCOUNT  -q $CUE2RUN -p $iproc/1/N -r 1024/1/$iproc -t $cputime -j g2oairpoe$node -o $rundir/g2oairpoe$node.out  $jobscript
  #...............................................
  fi
  #...............................................
done ;#varname
done ;#cyc

#---------------------------------------------------------------
#---each region and variables as an independemt job
else
#---------------------------------------------------------------

 export cyclist="$cyclistx"
 if [ $batch = YES ]; then
  $SUBJOB -e listvar,$listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/$share -r $memory/1 -t $cputime -j g2oair$regname -o $rundir/g2oair${regname}.out  ${sorcdir}/scripts/g2o_airmap.sh $regname
  if [ $? -ne 0 ]; then ${sorcdir}/scripts/g2o_airmap.sh $regname ; fi
 else
  ${sorcdir}/scripts/g2o_airmap.sh $regname &
 fi

#------------------------------
fi
#------------------------------
done  ;#regname
#------------------------------
fi
#------------------------------

exit




