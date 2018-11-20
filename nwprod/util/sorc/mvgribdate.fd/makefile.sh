#!/bin/sh
set -x

# IBM: xlf_r; Gaea: ftn; Zeus: ifort
export FCMP=${1:-ifort}

if [ $FCMP = xlf_r ] ; then
 export LIBDIR=/nwprod/lib
 export W3LIB=w3_4
 export BACIOLIB=bacio_4
 export FFLAGS="-qfree=f90  -qsmp=noauto -qmaxmem=-1 "
else
 export LIBDIR=../../../lib
 export W3LIB=w3nco_4
 export BACIOLIB=bacio_4
 export FFLAGS="-O2 -convert big_endian -traceback -mkl -free"
fi
make clean
make -f Makefile
