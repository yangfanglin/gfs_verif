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

G2OSTATS=YES       ;#for making verification stats
G2OPLOTS=NO       ;#for making graphics, set to YES after G2OSTAT finishes

export machine=HERA                                      ;#WCOSS, WCOSS_C, WCOSS_D, THEIA

if [ $machine = WCOSS ]; then

export NOSCRUB=/global/noscrub          ;#noscrub directory                 
export vsdbsave=$NOSCRUB/$LOGNAME/archive/vsdb_data         ;#place where vsdb database is saved
export opsvsdb=/global/save/Fanglin.Yang/vrfygfs/vsdb_data  ;#operational model grid-to-obs data base
export vsdbhome=/global/save/Fanglin.Yang/VRFY/vsdb         ;#verify source code and scripts
export gdas_prepbufr_arch=/global/noscrub/Fanglin.Yang/prepbufr/gdas ;#ops gdas prepbufr archive
export ndasbufr_arch=/global/noscrub/Fanglin.Yang/prepbufr/ndas
export nambufr_arch=/global/noscrub/Fanglin.Yang/prepbufr/nam
export NWPROD=$vsdbhome/nwprod                              ;#utilities in nwprod
export ACCOUNT=GFS-T2O                                      ;#ibm computer ACCOUNT task
export CUE2RUN=dev                                          ;#account type (dev, devhigh, or 1) to run 
export CUE2FTP=transfer                                     ;#account for data transfer                 
export GROUP=g01                                            ;#account group
export HPSSTAR=/u/Fanglin.Yang/bin/hpsstar                  ;#hpsstar                              
export SUBJOB=$vsdbhome/bin/sub_wcoss                       ;#script for submitting batch jobs
export rundir=/stmpd2/$LOGNAME/g2o$$                          ;#running directory
export FC=/usrx/local/intel/composer_xe_2011_sp1.11.339/bin/intel64/ifort ;#fortran compiler
export APRUN=""
export COMROTNCO=/gpfs/hps/nco/ops/com                                                                   
export COMROTNAM=/com2                                                                   
export cputime=06:00:00
export nproc=24                                             ;#PEs per node 
if [ $CUE2RUN = dev ]; then export nproc=16; fi  

elif [ $machine = WCOSS_C ]; then

export NOSCRUB=/gpfs/hps3/emc/global/noscrub                 ;#noscrub directory                 
export vsdbsave=$NOSCRUB/$LOGNAME/archive/vsdb_data         ;#place where vsdb database is saved
export opsvsdb=/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/stat/vsdb_data  ;#operational model grid-to-obs data base
export vsdbhome=/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/VRFY/vsdb      ;#verify source code and scripts
export gdas_prepbufr_arch=/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/prepbufr/gdas ;#ops gdas prepbufr archive
export ndasbufr_arch=/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/prepbufr/ndas
export nambufr_arch=/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/prepbufr/nam
export NWPROD=$vsdbhome/nwprod                              ;#utilities in nwprod
export ACCOUNT=GFS-T2O                                      ;#ibm computer ACCOUNT task
export CUE2RUN=dev                                          ;#account type (dev, devhigh, or 1) to run 
export CUE2FTP=dev_transfer                                 ;#account for data transfer                 
export GROUP=g01                                            ;#account group
export HPSSTAR=/u/Fanglin.Yang/bin/hpsstar                  ;#hpsstar                              
export SUBJOB=$vsdbhome/bin/sub_wcoss_c                     ;#script for submitting batch jobs
export rundir=/gpfs/hps3/stmp/$LOGNAME/g2o$$                ;#running directory
export FC=/opt/intel/composer_xe_2015.3.187/bin/intel64/ifort  ;#fortran compiler
export APRUN="aprun -n 1 -N 1 -j 1 -d 1"
. $MODULESHOME/init/sh
module load prod_envir/1.0.2
export COMROTNCO=$COMROOT
export COMROTNAM=$COMROOTp2                                                             
export cputime=10:00:00
export nproc=24

elif [ $machine = WCOSS_D ]; then

export NOSCRUB=/gpfs/dell2/emc/modeling/noscrub                    ;#noscrub directory                 
export vsdbsave=$NOSCRUB/$LOGNAME/archive/vsdb_data                ;#place where vsdb database is saved
export opsvsdb=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/stat  ;#operational model grid-to-obs data base
export vsdbhome=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/VRFY/vsdb      ;#verify source code and scripts
export gdas_prepbufr_arch=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/stat/prepbufr/gdas ;#ops gdas prepbufr archive
export ndasbufr_arch=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/stat/prepbufr/ndas
export nambufr_arch=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/stat/prepbufr/nam
export NWPROD=$vsdbhome/nwprod                              ;#utilities in nwprod
export ACCOUNT=GFS-T2O                                      ;#ibm computer ACCOUNT task
export CUE2RUN=dev                                          ;#account type (dev, devhigh, or 1) to run 
export CUE2FTP=dev_transfer                                 ;#account for data transfer                 
export GROUP=g01                                            ;#account group
export HPSSTAR=/u/Fanglin.Yang/bin/hpsstar                  ;#hpsstar                              
export SUBJOB=$vsdbhome/bin/sub_wcoss_d                     ;#script for submitting batch jobs
export rundir=/gpfs/dell3/stmp/$LOGNAME/g2o$$                ;#running directory
export FC=/usrx/local/prod/intel/2018UP01/compilers_and_libraries/linux/bin/intel64/ifort
export APRUN=""                                     ;#affix to run batch jobs
if [ ! -z $MODULESHOME ]; then
    . $MODULESHOME/init/bash              2>>/dev/null
    module load prod_envir/1.0.2          2>>/dev/null
    module load ips/18.0.1.163            2>>/dev/null
    module load impi/18.0.1               2>>/dev/null
    module load EnvVars/1.0.2             2>>/dev/null
    module use -a /usrx/local/dev/modulefiles 2>>/dev/null
    module load GrADS/2.2.0               2>>/dev/null
    module load imagemagick/6.9.9-25      2>>/dev/null
fi
export COMROTNCO=$COMROOT
export COMROTNAM=$COMROOTp2                                                             
export cputime=10:00:00
export nproc=28

elif [ $machine = HERA ]; then

export NOSCRUB=/scratch1/NCEPDEV/global                    
export vsdbsave=$NOSCRUB/$LOGNAME/archive/vsdb_data       
export opsvsdb=/scratch1/NCEPDEV/global/Fanglin.Yang/stat/vsdb_data 
export vsdbhome=/scratch1/NCEPDEV/global/Fanglin.Yang/save/VRFY/vsdb      
export gdas_prepbufr_arch=/scratch1/NCEPDEV/global/Fanglin.Yang/stat/prepbufr/gdas                          
export ndasbufr_arch=/scratch1/NCEPDEV/global/Fanglin.Yang/stat/prepbufr/ndas
export nambufr_arch=/scratch1/NCEPDEV/global/Fanglin.Yang/stat/prepbufr/nam
export NWPROD=$vsdbhome/nwprod                              ;#utilities in nwprod
export ACCOUNT=fv3-cpu                                       ;#computer ACCOUNT task
export CUE2RUN=batch                                        ;#account type (dev, devhigh, or 1) to run 
export CUE2FTP=batch                                        ;#account for data transfer                 
export GROUP=g01                                            ;#account group
export SUBJOB=$vsdbhome/bin/sub_slurm                       ;#script for submitting batch jobs
export HPSSTAR=/home/Fanglin.Yang/bin/hpsstar_theia         ;#hpsstar                              
export rundir=/scratch1/NCEPDEV/stmp2/$LOGNAME/g2o$$        ;#running directory
export FC=/apps/intel/parallel_studio_xe_2019.4.070/compilers_and_libraries_2019/linux/bin/intel64/ifort  
export APRUN=""
export COMROTNCO=/scratch1/NCEPDEV/rstprod/com                                           
export COMROTNAM=$COMROTNCO                                                             
export nproc=40

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


export memory=20480; export share=N
if [ $CUE2RUN = dev_shared ]; then export memory=1024; export share=S; fi
mkdir -p $rundir


#============================
#---produce g2o vsdb database
if [ ${G2OSTATS:-NO} = YES ]; then
#============================
export cyclist="00"                        ;#forecast cycles
export expnlist="ccppc384"                 ;#experiment names
export expdlist="$NOSCRUB/$LOGNAME/archive $NOSCRUB/$LOGNAME/archive"
export hpssdirlist="/NCEPDEV/hpssuser/g01/wx20rt/WCOSS /NCEPDEV/1year/hpsspara/runhistory/glopara"
export dumplist=".gfs. .gfs."  
export fhoutair="6"                         ;#forecast output frequency in hours for raobs vrfy
export fhoutsfc="3"                         ;#forecast output frequency in hours for sfc vrfy
export gdtype="3"                           ;#pgb file resolution, 2 for 2.5-deg and 3 for 1-deg
export vsdbsfc="YES"                        ;#run sfc verification
export vsdbair="YES"                        ;#run upper-air verification
export vlength=168                          ;#forecast length in hour
export DATEST=20190701                      ;#verification starting date
export DATEND=20190707                      ;#verification ending date
export batch=NO                            ;#to run jobs in batch mode
export runhpss=NO                           ;#run hpsstar in batch mode to get missing data

listvar1=vsdbhome,vsdbsave,cyclist,expnlist,expdlist,hpssdirlist,dumplist,fhoutair,fhoutsfc,,vsdbsfc,vsdbair,gdtype,APRUN,COMROTNCO,COMROTNAM
listvar2=NWPROD,SUBJOB,ACCOUNT,CUE2RUN,CUE2FTP,GROUP,vlength,DATEST,DATEND,rundir,HPSSTAR,gdas_prepbufr_arch,batch,runhpss,ndasbufr_arch,nambufr_arch
export listvar=$listvar1,$listvar2
JJOB=${vsdbhome}/grid2obs/grid2obs.sh
if [ $batch = YES ]; then
 $SUBJOB -e listvar,$listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/$share -r $memory/1 \
        -t 6:00:00 -j g2ogfs -o $rundir/g2ogfs.out $JJOB 
else
 $JJOB 1> $rundir/g2ogfs.out 2>&1 
fi
#-------
fi
#-------

#============================
# make g2o maps
if [ ${G2OPLOTS:-NO} = YES ]; then
#===========================

export mdlist="gfs ccppc384 "          ;#experiment names, up to 10
export caplist="gfs ccppc384 "         ;#experiment names to show on maps
export cyclist="00"                    ;#forecast cycles to verify
export vlength=168                         ;#forecast length in hour
export fhoutair="6"                        ;#forecast output frequency in hours for raobs vrfy
export fhoutsfc="3"                        ;#forecast output frequency in hours for sfc vrfy
export DATEST=20190701                     ;#verification starting date
export DATEND=20190707                     ;#verification ending date
export maskmiss=1                          ;#remove missing data from all runs, 0-->NO, 1-->Yes
export obairtype=ADPUPA                    ;#uppair observation type, ADPUPA or ANYAIR
export plotair="YES"                        ;#make upper plots
export plotsfc="YES"                       ;#make sfc plots
export MPMD="YES"                          ;#use MPMD to submit multiple jobs in one node


export webhost=emcrzdm.ncep.noaa.gov       ;#host for web display
export webhostid=$LOGNAME                  ;#login id on webhost
export ftpdir=/home/people/emc/www/htdocs/gmb/$webhostid/vsdb/g2o ;#where maps are displayed on webhost
export doftp="YES"                                            ;#whether or not sent maps to ftpdir

${vsdbhome}/grid2obs/grid2obs_plot.sh

#-------
fi
#-------

exit


