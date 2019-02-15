#!/bin/ksh
set -ux

## set up common directories, utilities and environment variables
## for different platforms, and assign user specific parameters.

machine=${1:-WCOSS_C}
machine=$(echo $machine|tr '[a-z]' '[A-Z]')
export rc=0

#==================================
## machine-independent parameters
#==================================
export anl_type=ecmwf          ;#analysis type: gfs, gdas, ecmwf, manl, canl, or fcst00, fcst120 etc
                                ##gfs/gdas--own anl of each exps, manl--mean in expnlist; canl--mean of GFS,EC and UK.
export iauf00="NO"             ;#for forecasts using IAU method, force pgbf00=pgbanl
export sfcvsdb="YES"           ;#include the group of surface variables       
export gd=G2                   ;#grid resoultion on which vsdb stats are computed, G2->2.5deg, G3->1deg, G4->0.5deg
export doftp="YES"             ;#whether or not to send maps to web server
export scppgb="NO"             ;#copy files between machine? need passwordless ssh
export batch="YES"             ;#run jobs at batch nodes                              
export scorecard="NO"          ;#create scorecard text files and web display plate                          
if [ $machine != WCOSS_C -a $machine != WCOSS -a $machine != WCOSS_D ]; then 
 export doftp="NO"
fi

#==================================
## user-specific parameters
#==================================
if [ $machine = WCOSS ]; then
 chost=`echo $(hostname) |cut -c 1-1`
 export vsdbsave=/global/noscrub/$LOGNAME/archive/vsdb_data  ;#place where vsdb database is saved
 export ACCOUNT=GFS-T2O                                ;#ibm computer ACCOUNT task
 export CUE2RUN=dev                                    ;#dev or dev_shared         
 export CUE2FTP=transfer                               ;#queue for data transfer
 export GROUP=g01                                      ;#group of account, g01 etc
 export nproc=24                                       ;#number of PEs per node   
 if [ $CUE2RUN = dev ]; then export nproc=16 ; fi
 export cputime=6:00:00                                ;#CPU time hh:mm:ss to run each batch job
 export MPMD=YES
#----------------------------
elif [ $machine = WCOSS_C ]; then
 chost=`echo $(hostname) |cut -c 1-1`
 export vsdbsave=/gpfs/hps3/emc/global/noscrub/$LOGNAME/archive/vsdb_data  ;#place where vsdb database is saved
 export ACCOUNT=GFS-T2O                                ;#ibm computer ACCOUNT task
 export CUE2RUN=dev                                    ;#dev or dev_shared         
 export CUE2FTP=dev_transfer                           ;#queue for data transfer
 export GROUP=g01                                      ;#group of account, g01 etc
 export nproc=24                                       ;#number of PEs per node   
 export cputime=10:00:00                               ;#CPU time hh:mm:ss to run each batch job
 export MPMD=YES
#----------------------------
elif [ $machine = WCOSS_D ]; then
 chost=`echo $(hostname) |cut -c 1-1`
 export vsdbsave=/gpfs/dell2/emc/modeling/noscrub/$LOGNAME/archive/vsdb_data  ;#place where vsdb database is saved
 export ACCOUNT=GFS-T2O                                ;#ibm computer ACCOUNT task
 export CUE2RUN=dev                                    ;#dev or dev_shared         
 export CUE2FTP=dev_transfer                           ;#queue for data transfer
 export GROUP=g01                                      ;#group of account, g01 etc
 export nproc=28                                       ;#number of PEs per node   
 export cputime=16:00:00                               ;#CPU time hh:mm:ss to run each batch job
 export MPMD=YES
#----------------------------
elif [ $machine = THEIA ]; then
 export vsdbsave=/scratch4/NCEPDEV/global/noscrub/$LOGNAME/archive/vsdb_data  ;#place where vsdb database is saved
 export ACCOUNT=fv3-cpu                                ;#computer ACCOUNT task
 export CUE2RUN=batch                                  ;#default to batch queue
 export CUE2FTP=service                                ;#queue for data transfer
 export GROUP=g01                                      ;#group of account, g01 etc
 export nproc=16                                       ;#number of PEs per node   
 export cputime=6:00:00                                ;#CPU time hh:mm:ss to run each batch job
 export MPMD=NO  
#----------------------------
elif [ $machine = JET ]; then
 export vsdbsave=/mnt/lfs3/projects/hfv3gfs/$LOGNAME/noscrub/archive/vsdb_data  ;#place where vsdb database is saved
 export ACCOUNT=hfv3gfs                                ;#computer ACCOUNT task
 export CUE2RUN=batch                                   ;#default to batch queue
 export CUE2FTP=service                                ;#queue for data transfer
 export GROUP=hfv3gfs                                  ;#group of account, g01 etc
 export nproc=24                                       ;#number of PEs per node   
 export cputime=6:00:00                                ;#CPU time hh:mm:ss to run each batch job
 export MPMD=NO  
#----------------------------
else
 echo "machine $machine is not supportted by NCEP/ECM"
 echo "Please first install the verification package. exit" 
 export rc=1
 exit
fi


if [ $doftp = YES ]; then
  export webhost=emcrzdm.ncep.noaa.gov     ;#host for web display
  export webhostid=$LOGNAME                ;#login id on webhost 
  export ftpdir=/home/people/emc/www/htdocs/gmb/$webhostid/vsdb   ;#where maps are displayed on webhost            
fi 

#=====================================
## common machine-dependent parameters
#=====================================
#----------------------------
if [ $machine = WCOSS ]; then
 chost=`echo $(hostname) |cut -c 1-1`
 export vsdbhome=/global/save/Fanglin.Yang/VRFY/vsdb        ;#script home, do not change
 export obdata=/global/save/Fanglin.Yang/obdata             ;#observation data for making 2dmaps
 export gstat=/global/noscrub/Fanglin.Yang/stat             ;#global stats directory              
 export gfsvsdb=$gstat/vsdb_data                            ;#operational gfs vsdb database
 export canldir=$gstat/canl                                 ;#consensus analysis directory
 export ecmanldir=$gstat/ecm                                ;#ecmwf analysis directory
 export OBSPCP=$gstat/OBSPRCP                               ;#observed precip for verification
 export gfswgnedir=$gstat/wgne                              ;#operational gfs precip QPF scores
 export gfsfitdir=/global/save/Suranjana.Saha               ;#Suru operational model fit-to-obs database
 export SUBJOB=$vsdbhome/bin/sub_wcoss                      ;#script for submitting batch jobs
 export NWPROD=$vsdbhome/nwprod                             ;#common utilities and libs included in /nwprod
 export GNOSCRUB=/global/noscrub                            ;#archive directory                          
 export STMP=/stmpd2                                        ;#temporary directory                          
 export PTMP=/ptmpd2                                        ;#temporary directory                          
 export GRADSBIN=/usrx/local/GrADS/2.0.2/bin                ;#GrADS executables       
 export IMGCONVERT=/usrx/local/ImageMagick/6.8.3-3/bin/convert                ;#image magic converter
 export FC=/usrx/local/intel/composer_xe_2011_sp1.11.339/bin/intel64/ifort    ;#intel compiler
 export FFLAG="-O2 -convert big_endian -FR"                 ;#intel compiler options
 export APRUN=""                                            ;#affix to run batch jobs   

#----------------------------
elif [ $machine = WCOSS_C ]; then
 chost=`echo $(hostname) |cut -c 1-1`
 export vsdbhome=/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/VRFY/vsdb     ;#script home, do not change
 export obdata=/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/obdata          ;#observation data for making 2dmaps
 export gstat=/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/stat             ;#global stats directory              
 export gfsvsdb=$gstat/vsdb_data                            ;#operational gfs vsdb database
 export canldir=$gstat/canl                                 ;#consensus analysis directory
 export ecmanldir=$gstat/ecm                                ;#ecmwf analysis directory
 export OBSPCP=$gstat/OBSPRCP                               ;#observed precip for verification
 export gfswgnedir=$gstat/wgne                              ;#operational gfs precip QPF scores
 export gfsfitdir=/gpfs/hps3/emc/global/noscrub/Fanglin.Yang/stat/fit2obs     ;#Suru operational model fit-to-obs database
 export SUBJOB=$vsdbhome/bin/sub_wcoss_c                    ;#script for submitting batch jobs
 export NWPROD=$vsdbhome/nwprod                             ;#common utilities and libs included in /nwprod
 export GNOSCRUB=/gpfs/hps3/emc/global/noscrub               ;#archive directory                          
 export STMP=/gpfs/hps3/stmp                                 ;#temporary directory                          
 export PTMP=/gpfs/hps3/ptmp                                 ;#temporary directory                          
 export GRADSBIN=/usrx/local/dev/GrADS/2.0.2/bin            ;#GrADS executables       
 export IMGCONVERT=/usr/bin/convert                         ;#image magic converter
 export FC=/opt/intel/composer_xe_2015.3.187/bin/intel64/ifort    ;#intel compiler
 export FFLAG="-O2 -convert big_endian -FR"                 ;#intel compiler options
 export APRUN="aprun -n 1 -N 1 -j 1 -d 1"                   ;#affix to run batch jobs   

#----------------------------
elif [ $machine = WCOSS_D ]; then
 chost=`echo $(hostname) |cut -c 1-1`
 export vsdbhome=/gpfs/dell2/emc/modeling/noscrub/emc.glopara/git/verif/global/tags/vsdb              
 export obdata=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/obdata       ;#observation data for making 2dmaps
 export gstat=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/stat          ;#global stats directory              
 export gfsvsdb=$gstat/vsdb_data                            ;#operational gfs vsdb database
 export canldir=$gstat/canl                                 ;#consensus analysis directory
 export ecmanldir=$gstat/ecm                                ;#ecmwf analysis directory
 export OBSPCP=$gstat/OBSPRCP                               ;#observed precip for verification
 export gfswgnedir=$gstat/wgne                              ;#operational gfs precip QPF scores
 export gfsfitdir=$gstat/fit2obs                            ;#Suru operational model fit-to-obs database
 export SUBJOB=$vsdbhome/bin/sub_wcoss_d                    ;#script for submitting batch jobs
 export NWPROD=$vsdbhome/nwprod                             ;#common utilities and libs included in /nwprod
 export GNOSCRUB=/gpfs/dell2/emc/modeling/noscrub            ;#archive directory                          
 export STMP=/gpfs/dell2/stmp                                ;#temporary directory                          
 export PTMP=/gpfs/dell2/ptmp                                ;#temporary directory                          
 if [ ! -z $MODULESHOME ]; then
    . $MODULESHOME/init/bash              2>>/dev/null
    module load ips/18.0.1.163            2>>/dev/null
    module load impi/18.0.1               2>>/dev/null
    module load EnvVars/1.0.2             2>>/dev/null
    module use -a /usrx/local/dev/modulefiles 2>>/dev/null
    module load GrADS/2.2.0               2>>/dev/null
    module load imagemagick/6.9.9-25      2>>/dev/null
 fi
 export GRADSBIN=/usrx/local/dev/packages/grads/2.2.0/bin   ;#GrADS executables       
 export GADDIR=/gpfs/dell2/emc/modeling/noscrub/Fanglin.Yang/tools/grads/lib
 export IMGCONVERT=/usrx/local/dev/packages/ImageMagick/6.9.9-25/bin/convert       ;#image magic converter
 export FC=/usrx/local/prod/intel/2018UP01/compilers_and_libraries/linux/bin/intel64/ifort 
 export FFLAG="-O2 -convert big_endian -FR"                 ;#intel compiler options
 export APRUN="mpirun "                                     ;#affix to run batch jobs   

#----------------------------
elif [ $machine = THEIA ]; then
 export vsdbhome=/scratch4/NCEPDEV/global/save/Fanglin.Yang/VRFY/vsdb ;#script home, do not change
 export obdata=/scratch4/NCEPDEV/global/save/Fanglin.Yang/obdata      ;#observation data for making 2dmaps
 export gstat=/scratch4/NCEPDEV/global/noscrub/stat  ;#global stats directory              
 export gfsvsdb=$gstat/vsdb_data                            ;#operational gfs vsdb database
 export canldir=$gstat/canl                                 ;#consensus analysis directory
 export ecmanldir=$gstat/ecm                                ;#ecmwf analysis directory
 export OBSPCP=$gstat/OBSPRCP                               ;#observed precip for verification
 export gfswgnedir=$gstat/wgne                              ;#operational gfs precip QPF scores
 export gfsfitdir=$gstat/surufits                           ;#Suru operational model fit-to-obs database
 export SUBJOB=$vsdbhome/bin/sub_theia                      ;#script for submitting batch jobs
 export NWPROD=$vsdbhome/nwprod                             ;#common utilities and libs included in /nwprod
 export GNOSCRUB=/scratch4/NCEPDEV/global/noscrub           ;#temporary directory                          
 export STMP=/scratch4/NCEPDEV/stmp3                        ;#temporary directory                          
 export PTMP=/scratch4/NCEPDEV/stmp3                        ;#temporary directory                          
 export GRADSBIN=/apps/grads/2.0.1a/bin                     ;#GrADS executables       
 export IMGCONVERT=/apps/ImageMagick/6.9.0/bin/convert      ;#image magic converter
 export FC=/apps/intel/composer_xe_2013_sp1.2.144/bin/intel64/ifort              ;#intel compiler
 export FFLAG="-O2 -convert big_endian -FR"                 ;#intel compiler options
 export APRUN=""                                            ;#affix to run batch jobs   

#----------------------------
elif [ $machine = JET ]; then
 export vsdbhome=/mnt/lfs3/projects/hfv3gfs/Fanglin.Yang/VRFY/vsdb    ;#script home, do not change
 export obdata=/mnt/lfs3/projects/hfv3gfs/Fanglin.Yang/VRFY/obdata    ;#observation data for making 2dmaps
 export gstat=/mnt/lfs3/projects/hfv3gfs/Fanglin.Yang/VRFY/stat       ;#global stats directory              
 export gfsvsdb=$gstat/vsdb_data                            ;#operational gfs vsdb database
 export canldir=$gstat/canl                                 ;#consensus analysis directory
 export ecmanldir=$gstat/ecm                                ;#ecmwf analysis directory
 export OBSPCP=$gstat/OBSPRCP                               ;#observed precip for verification
 export gfswgnedir=$gstat/wgne                              ;#operational gfs precip QPF scores
 export gfsfitdir=$gstat/surufits                           ;#Suru operational model fit-to-obs database
 export SUBJOB=$vsdbhome/bin/sub_jet                        ;#script for submitting batch jobs
 export NWPROD=$vsdbhome/nwprod                             ;#common utilities and libs included in /nwprod
 export GNOSCRUB=/mnt/lfs3/projects/hfv3gfs/$LOGNAME/noscrub      ;#temporary directory                          
 export STMP=/mnt/lfs3/projects/hfv3gfs/$LOGNAME/stmp       ;#temporary directory                          
 export PTMP=/mnt/lfs3/projects/hfv3gfs/$LOGNAME/ptmp       ;#temporary directory                          
 export GRADSBIN=/apps/grads/2.0.2/bin                      ;#GrADS executables       
 export IMGCONVERT=/apps/ImageMagick/6.2.8/bin/convert      ;#image magic converter
 export FC=/apps/intel/composer_xe_2015.3.187/bin/intel64/ifort              
 export FFLAG="-O2 -convert big_endian -FR"                 ;#intel compiler options
 export APRUN=""                                            ;#affix to run batch jobs   

fi

