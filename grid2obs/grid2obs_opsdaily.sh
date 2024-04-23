#!/bin/ksh 
set -x

##---------------------------------------------------------------------------------
## grid-to-obs driver for submitting jobs to create g2o 
## stats, to make graphics, and to upload to web servers.
## Fanglin Yang, NCEP/EMC, August 2013
##----------------------------------------------------------------------------------
## notes: 
##  1) creating stats is a slow process and has to be run in batch mode. 
##     it takes 10 to 20 minutes on WCOSS to finish one forecast case. 
##  2) It takes grib files as input.  The files should contain near surface 
##     variables and upper-air variables on isobaric layers. They can be
##     at any given forecast output frequency and on any regular lat-lon gird.
##  3) The verification includes both surface and upper air observations. 
##     It is aimed to compare forecasts against a) ground observations of SLP,
##     T2m, RH2m and wind speed at 10m over CONUS and its subregions and, 
##     b) upper-air observations of T, wind, RH and Q from ADPUPA (rawinsonde, 
##     pibals and profilers) and AIRCAR (ACARS) over the globle, NH, SH and 
##     the tropics.  
##  4) The script uses nam/ndas prepbufr for surafce fits over the NAM(G104)
##     subregions and gdas/gfs prepbufr for upper-air fit over global subregions.
##  5) Perry Shafran provided the operational version of the gridtobs Fortran 
##     code. Helin Wei provided his scripts for producing surface stats. Fanglin 
##     Yang added options to the Fortran code to run verification over larger 
##     global domains, and wrote the shell and GrADS scripts for producing 
##     upper-air stats and for making graphics. This toll is applicable for 
##     processing GFS operational and parallel forecasts for all forecast cycles. 
##---------------------------------------------------------------------------------

G2OSTATS=YES      ;#for making verification stats
G2OPLOTS=NO      ;#for making graphics, set to YES after G2OSTAT finishes

export machine=WCOSS2                                       ;#WCOSS, WCOSS_C, WCOSS_D, THEIA

if [ $machine = WCOSS2 ]; then

export NOSCRUB=/lfs/h2/emc/physics/noscrub                         ;#noscrub directory
export vsdbsave=$NOSCRUB/$LOGNAME/data/vrfygfs/vsdb_data                ;#place where vsdb database is saved
export opsvsdb=/lfs/h2/emc/physics/noscrub/fanglin.yang/data/vrfygfs    ;#operational model grid-to-obs data base
export vsdbhome=/lfs/h2/emc/physics/noscrub/fanglin.yang/save/VRFY/vsdb                    ;#verify source code and scripts
export gdas_prepbufr_arch=/lfs/h2/emc/physics/noscrub/fanglin.yang/data/stat/prepbufr/gdas ;#ops gdas prepbufr archive
export ndasbufr_arch=/lfs/h2/emc/physics/noscrub/fanglin.yang/data/stat/prepbufr/ndas
export nambufr_arch=/lfs/h2/emc/physics/noscrub/fanglin.yang/data/stat/prepbufr/nam
export NWPROD=$vsdbhome/nwprod                              ;#utilities in nwprod
export ACCOUNT=GFS-DEV                                      ;#ibm computer ACCOUNT task
export CUE2RUN=dev                                          ;#account type (dev, devhigh, or 1) to run
export CUE2FTP=dev_transfer                                 ;#account for data transfer
export GROUP=g01                                            ;#account group
export HPSSTAR=/u/fanglin.yang/bin/hpsstar                  ;#hpsstar
export SUBJOB=$vsdbhome/bin/sub_wcoss2                      ;#script for submitting batch jobs
export rundir=/lfs/h2/emc/stmp/$LOGNAME/g2o$$                ;#running directory
export FC=/pe/intel/compilers_and_libraries_2020.4.304/linux/bin/intel64/ifort
export APRUN=""                                     ;#affix to run batch jobs

  module purge
  module load envvar/1.0
  module load intel/19.1.3.304
  module load PrgEnv-intel/8.1.0
  module load craype/2.7.10
  module load cray-pals/1.0.17
  module load cray-mpich/8.1.9

  module load libjpeg/9c
  module load prod_util/2.0.13
  module load grib_util/1.2.4
  module load prod_envir/2.0.6
  module load wgrib2/2.0.8
  module load imagemagick/7.0.8-7
  module load cfp/2.0.4
  module use /apps/test/lmodules/core
  module load GrADS/2.2.2

  export COMROTNCO=$COMROOT
  export COMROTNAM=$COMROOT
  export cputime=10:00:00
  export nproc=128

elif [ $machine = THEIA ]; then

export NOSCRUB=/scratch4/NCEPDEV/global/noscrub             ;#noscrub directory                 
export vsdbsave=$NOSCRUB/$LOGNAME/archive/vsdb_data         ;#place where vsdb database is saved
export opsvsdb=/scratch4/NCEPDEV/global/noscrub/stat/vsdb_data ;#operational model grid-to-obs data base
export vsdbhome=/scratch4/NCEPDEV/global/save/Fanglin.Yang/VRFY/vsdb             ;#verify source code and scripts
export gdas_prepbufr_arch=/scratch4/NCEPDEV/global/noscrub/stat/prepbufr/gdas ;#ops gdas prepbufr archive
export ndasbufr_arch=/scratch4/NCEPDEV/global/noscrub/stat/prepbufr/ndas
export nambufr_arch=/scratch4/NCEPDEV/global/noscrub/stat/prepbufr/nam
export NWPROD=$vsdbhome/nwprod                              ;#utilities in nwprod
export ACCOUNT=glbss                                        ;#computer ACCOUNT task
export CUE2RUN=batch                                        ;#account type (dev, devhigh, or 1) to run 
export CUE2FTP=service                                      ;#account for data transfer                 
export GROUP=g01                                            ;#account group
export SUBJOB=$vsdbhome/bin/sub_theia                       ;#script for submitting batch jobs
export HPSSTAR=/home/Fanglin.Yang/bin/hpsstar_theia         ;#hpsstar                              
export rundir=/scratch4/NCEPDEV/stmp3/$LOGNAME/g2o$$  ;#running directory
export FC=/apps/intel/composer_xe_2013_sp1.2.144/bin/intel64/ifort  ;#fortran compiler
export APRUN=""
export COMROTNCO=/scratch4/NCEPDEV/rstprod/com                                           
export COMROTNAM=$COMROTNCO                                                             
export nproc=24

elif [ $machine = JET ]; then

export NOSCRUB=/mnt/lfs3/projects/hfv3gfs/$USER/noscrub             ;#noscrub directory                 
export vsdbsave=$NOSCRUB/archive/vsdb_data                          ;#place where vsdb database is saved
export opsvsdb=/mnt/lfs3/projects/hfv3gfs/Fanglin.Yang/VRFY/stat/vsdb_data       ;#operational model grid-to-obs data base
export vsdbhome=/mnt/lfs3/projects/hfv3gfs/Fanglin.Yang/VRFY/vsdb                ;#verify source code and scripts
export gdas_prepbufr_arch=/mnt/lfs3/projects/hfv3gfs/Ratko.Vasic/noscrub/phys_sel/prepbufr/gdas ;#ops gdas prepbufr archive
export ndasbufr_arch=/mnt/lfs3/projects/hfv3gfs/Ratko.Vasic/noscrub/phys_sel/prepbufr/ndas
export nambufr_arch=/mnt/lfs3/projects/hfv3gfs/Ratko.Vasic/noscrub/phys_sel/prepbufr/nam
export NWPROD=$vsdbhome/nwprod                              ;#utilities in nwprod
export ACCOUNT=hfv3gfs                                       ;#computer ACCOUNT task
export CUE2RUN=batch                                        ;#account type (dev, devhigh, or 1) to run 
export CUE2FTP=service                                      ;#account for data transfer                 
export GROUP=hfv3gfs                                        ;#account group
export SUBJOB=$vsdbhome/bin/sub_jet                         ;#script for submitting batch jobs
export HPSSTAR=/lfs3/projects/hwrf-data/emc-utils/bin/hpsstar 
export rundir=/mnt/lfs3/projects/hfv3gfs/$USER/stmp1/g2o$$   ;#running directory
export FC=/apps/intel/composer_xe_2015.3.187/bin/intel64/ifort      ;#fortran compiler
export APRUN=""
export COMROTNCO=/scratch4/NCEPDEV/rstprod/com                                           
export COMROTNAM=$COMROTNCO                                                             
export nproc=24
fi


export memory=10240; export share=N
if [ $CUE2RUN = dev_shared ]; then export memory=1024; export share=S; fi
if [ $machine = WCOSS2 ]; then export memory=3072MB; export share=S; fi
mkdir -p $rundir


export NDATE=/apps/ops/prod/nco/core/prod_util.v2.0.5/exec/ndate             
CDATE=${1:-$(date +%Y%m%d)}
CDATM1=`$NDATE -24 ${CDATE}00 |cut -c 1-8 `
CDATM2=`$NDATE -48 ${CDATE}00 |cut -c 1-8 `
CDATM3=`$NDATE -72 ${CDATE}00 |cut -c 1-8 `
chost=`echo $(hostname)|cut -c 1-1`

#---prepare prepbufr data
rm $rundir/g2o*.out
$SUBJOB -a $ACCOUNT  -q dev_transfer -g $GROUP -p 1/1/S -r 1024/1 -t 3:00:00 -j getgfsbufr \
        -o $rundir/get_opsgfs_prepbufr.out $vsdbhome/grid2obs/get_opsgfs_prepbufr.sh
$SUBJOB -a $ACCOUNT  -q dev_transfer -g $GROUP -p 1/1/S -r 1024/1 -t 3:00:00 -j getnambufr \
        -o $rundir/get_nam_prepbufr.out $vsdbhome/grid2obs/get_nam_prepbufr.sh


#============================
#---produce g2o vsdb database
if [ $G2OSTATS = YES ]; then
#============================

myarch="/lfs/h2/emc/physics/noscrub/fanglin.yang/data/ops/global"

##-ops GFS
export cyclist="00 06 12 18"                    ;#forecast cycles
export expnlist="gfs"                           ;#experiment names
export expdlist="$myarch" 
export dumplist=".gfs."  
export complist="$(hostname)"
export fhoutair="6"                         ;#forecast output frequency in hours for raobs vrfy
export fhoutsfc="3"                         ;#forecast output frequency in hours for sfc vrfy
export gdtype="3"                           ;#pgb file resolution, 2 for 2.5-deg and 3 for 1-deg
export vsdbsfc="YES"                        ;#run sfc verification
export vsdbair="YES"                        ;#run upper-air verification
export vlength=168                          ;#forecast length in hour
export DATEST=$CDATM3                       ;#verification starting date
export DATEND=$CDATM1                       ;#verification ending date
export batch=YES
export runhpss=NO                           ;#run hpsstar in batch mode to get missing data
listvar1=vsdbhome,vsdbsave,cyclist,expnlist,expdlist,hpssdirlist,dumplist,fhoutair,fhoutsfc,,vsdbsfc,vsdbair,gdtype,APRUN,COMROTNCO,COMROTNAM
listvar2=NWPROD,SUBJOB,ACCOUNT,CUE2RUN,CUE2FTP,GROUP,DATEST,DATEND,rundir,HPSSTAR,gdas_prepbufr_arch,batch,runhpss,ndasbufr_arch,nambufr_arch
export listvar="$listvar1,$listvar2"
JJOB=${vsdbhome}/grid2obs/grid2obs.sh
$SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/$share -r $memory/1 \
        -t 6:00:00 -j g2ogfs -o $rundir/g2ogfs.out $JJOB 


##-ops ECMWF
export cyclist="00 12"                      ;#forecast cycles
export expnlist="ecm"                       ;#experiment names
export expdlist="$myarch" 
export dumplist=".ecm."  
export complist="$(hostname)"
export fhoutair="6"                         ;#forecast output frequency in hours for raobs vrfy
export fhoutsfc="6"                         ;#forecast output frequency in hours for sfc vrfy
export gdtype="3"                           ;#pgb file resolution, 2 for 2.5-deg and 3 for 1-deg
export vsdbsfc="YES"                        ;#run sfc verification
export vsdbair="YES"                        ;#run upper-air verification
export vlength=168                          ;#forecast length in hour
export DATEST=$CDATM2                       ;#verification starting date
export DATEND=$CDATM1                       ;#verification ending date
export batch=YES
export runhpss=NO                           ;#run hpsstar in batch mode to get missing data
listvar1=vsdbhome,vsdbsave,cyclist,expnlist,expdlist,hpssdirlist,dumplist,fhoutair,fhoutsfc,,vsdbsfc,vsdbair,gdtype,APRUN,COMROTNCO,COMROTNAM
listvar2=NWPROD,SUBJOB,ACCOUNT,CUE2RUN,CUE2FTP,GROUP,DATEST,DATEND,rundir,HPSSTAR,gdas_prepbufr_arch,batch,runhpss,ndasbufr_arch,nambufr_arch
export listvar=$listvar1,$listvar2
JJOB=${vsdbhome}/grid2obs/grid2obs.sh
$SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/$share -r $memory/1 \
        -t 6:00:00 -j g2oecm -o $rundir/g2oecm.out $JJOB 


#-------
fi
#-------

#============================
# make g2o maps
if [ $G2OPLOTS = YES ]; then
#===========================
today=`echo $(date +%Y%m%d) |cut -c 1-8`
dd=`echo $today |cut -c 8-8`
if [ $dd -eq 2 -o $dd -eq 7 ]; then

#--ops GFS
ndays=1110
nhours=`expr $ndays \* 24 `
export rundir=$rundir/gfs                     ;#running directory
export DATEND=`$NDATE -48 $(date +%Y%m%d)00 |cut -c 1-8`     ;#forecast ending date
export DATEST=`$NDATE -$nhours ${DATEND}00 |cut -c 1-8 `     ;#forecast starting date
#export mdlist="gfs pr4devb"                ;#experiment names, up to 10
#export caplist="gfs gfsx"                  ;#experiment names, up to 10
export mdlist="gfs "                ;#experiment names, up to 10
export caplist="gfs "                  ;#experiment names, up to 10
export cyclist="00 06 12 18"               ;#forecast cycles to verify
export vlength=168                         ;#forecast length in hour
export fhoutair="6"                        ;#forecast output frequency in hours for raobs vrfy
export fhoutsfc="3"                        ;#forecast output frequency in hours for sfc vrfy
export maskmiss=1                          ;#remove missing data from all runs, 0-->NO, 1-->Yes
export obairtype=ADPUPA                    ;#uppair observation type, ADPUPA or ANYAIR
export plotair="YES"                        ;#make upper plots
export plotsfc="YES"                       ;#make sfc plots
export MPMD="NO"                          ;#use MPMD to submit multiple jobs in one node

export webhost=emcrzdm.ncep.noaa.gov       ;#host for web display
export webhostid=wx24fy                    ;#login id on webhost
export ftpdir=/home/people/emc/www/htdocs/gmb/wx24fy/STATS_vsdb      ;#where maps are displayed on webhost
export doftp="YES"                                            ;#whether or not sent maps to ftpdir
${vsdbhome}/grid2obs/grid2obs_plot.sh


#-------
fi
fi
#-------

exit


