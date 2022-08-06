#!/bin/ksh -l
set -ux

## set up common directories, utilities and environment variables
## for different platforms, and assign user specific parameters.

machine=${1:-WCOSS2}
machine=$(echo $machine|tr '[a-z]' '[A-Z]')
export rc=0

#==================================
## machine-independent parameters
#==================================
export anl_type=gfs            ;#analysis type: gfs, gdas, ecmwf, manl, canl, or fcst00, fcst120 etc
                                ##gfs/gdas--own anl of each exps, manl--mean in expnlist; canl--mean of GFS,EC and UK.
export iauf00="NO"             ;#for forecasts using IAU method, force pgbf00=pgbanl
export sfcvsdb="YES"           ;#include the group of surface variables       
export gd=G2                   ;#grid resoultion on which vsdb stats are computed, G2->2.5deg, G3->1deg, G4->0.5deg
export doftp="YES"             ;#whether or not to send maps to web server
export scppgb="NO"             ;#copy files between machine? need passwordless ssh
export batch="YES"             ;#run jobs at batch nodes                              
export scorecard="NO"          ;#create scorecard text files and web display plate                          
if [ $machine != WCOSS2 ]; then 
 export doftp="NO"
fi

#==================================
## user-specific parameters
#==================================
if [ $machine = WCOSS2 ]; then
 chost=`echo $(hostname) |cut -c 1-1`
 export vsdbsave=/lfs/h2/emc/physics/noscrub/$LOGNAME/data/archive/vsdb_data  ;#place where vsdb database is saved
 export ACCOUNT=GFS-DEV                                ;#ibm computer ACCOUNT task
 export CUE2RUN=dev                                    ;#dev or dev_shared         
 export CUE2FTP=transfer                               ;#queue for data transfer
 export GROUP=g01                                      ;#group of account, g01 etc
 export nproc=128                                      ;#number of PEs per node   
 export cputime=6:00:00                                ;#CPU time hh:mm:ss to run each batch job
 export MPMD=YES
#----------------------------
elif [ $machine = HERA ]; then
 export vsdbsave=/scratch1/NCEPDEV/global/$LOGNAME/archive/vsdb_data  ;#place where vsdb database is saved
 export ACCOUNT=fv3-cpu                                ;#computer ACCOUNT task
 export CUE2RUN=batch                                  ;#default to batch queue
 export CUE2FTP=batch                                  ;#queue for data transfer
 export GROUP=g01                                      ;#group of account, g01 etc
 export nproc=40                                       ;#number of PEs per node   
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

if [ $machine = WCOSS2 ]; then
 chost=`echo $(hostname) |cut -c 1-1`
 export vsdbhome=/lfs/h2/emc/physics/noscrub/fanglin.yang/save/VRFY/vsdb                                   
 export obdata=/lfs/h2/emc/physics/noscrub/fanglin.yang/data/obdata                      ;#observation data for making 2dmaps
 export gfsvsdb=/lfs/h2/emc/physics/noscrub/fanglin.yang/data/vrfygfs/vsdb_data          ;#operational gfs vsdb database
 export gstat=/lfs/h2/emc/physics/noscrub/fanglin.yang/data/archive/ops/global           ;#global stats directory              
 export canldir=$gstat/canl                                 ;#consensus analysis directory
 export ecmanldir=$gstat/ecm                                ;#ecmwf analysis directory
 export OBSPCP=$gstat/OBSPRCP                               ;#observed precip for verification
 export gfswgnedir=$gstat/wgne                              ;#operational gfs precip QPF scores
 export gfsfitdir=$gstat/fit2obs                            ;#Suru operational model fit-to-obs database
 export SUBJOB=$vsdbhome/bin/sub_wcoss2                     ;#script for submitting batch jobs
 export NWPROD=$vsdbhome/nwprod                             ;#common utilities and libs included in /nwprod
 export GNOSCRUB=/lfs/h2/emc/physics/noscrub                 ;#archive directory                          
 export STMP=/lfs/h2/emc/stmp                                ;#temporary directory                          
 export PTMP=/lfs/h2/emc/ptmp                                ;#temporary directory                          

    module purge                           2>>/dev/null
    module load envvar/1.0                 2>>/dev/null
    module load intel/19.1.3.304           2>>/dev/null
    module load PrgEnv-intel/8.1.0         2>>/dev/null
    module load craype/2.7.10              2>>/dev/null
    module load cray-pals/1.0.17           2>>/dev/null
    module load cray-mpich/8.1.9           2>>/dev/null

    module load libjpeg/9c                 2>>/dev/null
    module load prod_util/2.0.13           2>>/dev/null
    module load grib_util/1.2.4            2>>/dev/null
    module load prod_envir/2.0.6           2>>/dev/null
    module load wgrib2/2.0.8               2>>/dev/null
    module load imagemagick/7.0.8-7        2>>/dev/null
    module load cfp/2.0.4                  2>>/dev/null
    module use /apps/test/lmodules/core    2>>/dev/null
    module load GrADS/2.2.2                2>>/dev/null

 export GRADSBIN=/apps/test/grads/spack/opt/spack/cray-sles15-zen2/gcc-11.2.0/grads-2.2.2-wckmyzg7qh5smosf6och6ehqtqlxoy4f//bin 
 export GADDIR=/apps/test/grads/spack/opt/spack/cray-sles15-zen2/gcc-11.2.0/grads-2.2.2-wckmyzg7qh5smosf6och6ehqtqlxoy4f/lib
 export IMGCONVERT=/apps/spack/imagemagick/7.0.8-7/cce/11.0.1/fyjvsbwngyzlsiluc4udbnxkhlbwkzc3/bin/convert 
 export FC=/pe/intel/compilers_and_libraries_2020.4.304/linux/bin/intel64/ifort              
 export FFLAG="-O2 -convert big_endian -FR"                 ;#intel compiler options
 export APRUN="mpiexec -l"                                  ;#affix to run batch jobs   

#----------------------------
elif [ $machine = HERA ]; then
 export vsdbhome=/scratch1/NCEPDEV/global/Fanglin.Yang/save/VRFY/vsdb ;#script home, do not change
 export obdata=/scratch1/NCEPDEV/global/Fanglin.Yang/save/obdata      ;#observation data for making 2dmaps
 export gstat=/scratch1/NCEPDEV/global/Fanglin.Yang/stat  ;#global stats directory              
 export gfsvsdb=$gstat/vsdb_data                            ;#operational gfs vsdb database
 export canldir=$gstat/canl                                 ;#consensus analysis directory
 export ecmanldir=$gstat/ecm                                ;#ecmwf analysis directory
 export OBSPCP=$gstat/OBSPRCP                               ;#observed precip for verification
 export gfswgnedir=$gstat/wgne                              ;#operational gfs precip QPF scores
 export gfsfitdir=$gstat/surufits                           ;#Suru operational model fit-to-obs database
 export SUBJOB=$vsdbhome/bin/sub_slurm                      ;#script for submitting batch jobs
 export NWPROD=$vsdbhome/nwprod                             ;#common utilities and libs included in /nwprod
 export GNOSCRUB=/scratch1/NCEPDEV/global                   ;#temporary directory                          
 export STMP=/scratch1/NCEPDEV/stmp2                        ;#temporary directory                          
 export PTMP=/scratch1/NCEPDEV/stmp2                        ;#temporary directory                          
 export GRADSBIN=/apps/grads/2.0.2/bin                      ;#GrADS executables
 export IMGCONVERT=/usr/bin/convert                         ;#image magic converter
 export FC=/apps/intel/parallel_studio_xe_2019.4.070/compilers_and_libraries_2019/linux/bin/intel64/ifort
 export FFLAG="-O2 -convert big_endian -FR"                 ;#intel compiler options
 export APRUN=""

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

