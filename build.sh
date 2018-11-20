#!/bin/ksh
set -x

#-----------------------------------------------------------------------------------------------
##PLEASE DONOT RUN THIS SCRIPT IF YOU ARE NOT BUILDING THE ENTIRE PACKAGE FROM SCRATCH !!!
#-----------------------------------------------------------------------------------------------

## to install the entire package on a new computer plaform, users need
## to first build the following librairies and utilities, then compile 
## a list of executables. Check each one carefully if it fails to compile.   

machine=JET ;#IBM, JET, GAEA, WCOSS, WCOSS_C, WCOSS_D, THEIA

if [ $machine = IBM ];then
 FCMP=xlf_r
 CCMP=xlc_r
elif [ $machine = WCOSS -o $machine = THEIA ];then
 FCMP=ifort
 CCMP=cc
elif [ $machine = JET ];then
 FCMP=ifort
 CCMP=icc
elif [ $machine = WCOSS_C -o $machine = WCOSS_D ];then
 FCMP=ifort
 CCMP=icc
elif [ $machine = GAEA ];then
 FCMP=ftn
 CCMP=icc
else
 echo " machine=$machine not define. Add yours !"
 exit
fi

curdir=`pwd`


#--first libraries. Better to make use of admin built libraries if they exist.
# also note bufr lib takes a long time to build (~hour)
# These libraries may not be able to compile on IBM CCS. 

setlib=yes

#--please copy the pre-existing libs to $curdir/nwprod/lib
#if [ $machine = IBM -o $machine = JET ]; then setlib=no; fi

if [ $setlib = yes ]; then
for libname in bacio bufr ip sp sigio w3lib-2.0 w3nco_v2.0.6; do
  rm $curdir/nwprod/lib/*${libname}*.a
  rm $curdir/nwprod/lib/incmod/*/*${libname}*.mod
  cd $curdir/nwprod/lib/sorc/$libname
  rm *.o *.mod
  makefile.sh $FCMP $CCMP
  if [ $? -ne 0 ]; then exit ;fi
done
fi



#--then utilities
utilvar="copygb grbindex ndate nhour ss2ggx mvgribdate"
if [ $machine = IBM -o $machine = WCOSS -o $machine = JET ]; then 
 if [ $machine = IBM -o $machine = WCOSS ]; then srcdir=/nwprod/util/exec ;fi
 if [ $machine = JET ]; then srcdir=/lfs3/projects/hwrf-vd/soft/grib_util.v1.0.1/bin ;fi
 cp -p $srcdir/copygb   $curdir/nwprod/util/exec/.
 cp -p $srcdir/grbindex $curdir/nwprod/util/exec/.
 utilvar="ndate nhour ss2ggx mvgribdate"
fi
for utilname in $utilvar ; do
  rm $curdir/nwprod/util/exec/$utilname                 
  cd $curdir/nwprod/util/sorc/${utilname}.fd
  rm *.o *.mod
  makefile.sh $FCMP 
  if [ $? -ne 0 ]; then exit ;fi
done
wgrib=`which wgrib`
cp -p $wgrib $curdir/nwprod/util/exec/.


#export EXTRA_OPTION=" "
#if [ $machine = JET ]; then 
#   export EXTRA_OPTION="-axSSE4.2,AVX,CORE-AVX2  -ip"
#fi


#--lastly program executables
cd $curdir/exe/sorc
   rm *.o *.mod ../grid2grid.x
   makefile.sh $FCMP
   if [ $? -ne 0 ]; then exit ;fi

cd $curdir/fit2obs/sorc
   rm *.o *.mod *.x
   makefile.sh $FCMP
   if [ $? -ne 0 ]; then exit ;fi

cd $curdir/manl
   rm *.o *.mod *.exe
   makefile.sh $FCMP
   if [ $? -ne 0 ]; then exit ;fi

cd $curdir/precip/sorc
   rm *.o *.mod ../exec/*.x
   makefile.sh $FCMP
   if [ $? -ne 0 ]; then exit ;fi

cd $curdir/precip/sorc_qpf
   rm *.o *.mod ../exec/PVRFY*
   makefile.sh $FCMP
   if [ $? -ne 0 ]; then exit ;fi


##--grid-to-obs
 cd $curdir/nwprod/sorc/verf_gridtobs_prepfits.fd
    rm *.o *.mod ../../exec/verf_gridtobs*
    makefile.sh $FCMP
    if [ $? -ne 0 ]; then exit ;fi

 cd $curdir/nwprod/sorc/verf_gridtobs_gridtobs.fd
    rm *.o *.mod
    makefile.sh $FCMP
    if [ $? -ne 0 ]; then exit ;fi

 cd $curdir/nwprod/sorc/verf_gridtobs_editbufr.fd
    rm *.o *.mod
    makefile.sh $FCMP
    if [ $? -ne 0 ]; then exit ;fi

