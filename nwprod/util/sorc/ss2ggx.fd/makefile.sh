#!/bin/ksh
set -x
mac=$(hostname | cut -c1-1)
mac2=$(hostname | cut -c1-2)
if [ $mac2 = ga ] ; then
 export machine=gaea
 export FC=ftn
 export FFLAGSM="-O3 -free -convert big_endian -traceback"
 export LDFLAGSM=
 export LIBDIR=../../../lib
 export LIBSM="-L${LIBDIR} -lbacio_4 -lw3_4 -lsp_4 -lsigio_4"

elif [ $mac2 = tf ]; then
 export machine=theia
 export FC=ifort
 export FFLAGSM="-O3 -free -convert big_endian -traceback"
 export LDFLAGSM=-openmp
 export LIBDIR=../../../lib
 export INCMOD=$LIBDIR/incmod/sigio_4
 export LIBSM="-L${LIBDIR} -lbacio_4 -lw3lib-2.0_4 -lw3nco_4 -lsp_4 -lsigio_4"

elif [ $mac2 = fe ]; then
 export machine=jet
 export FC=ifort
 export FFLAGSM="-O3 -free -convert big_endian -traceback"
 export LDFLAGSM=-openmp
 export LIBDIR=../../../lib
 export INCMOD=$LIBDIR/incmod/sigio_4
 export LIBSM="-L${LIBDIR} -lbacio_4 -lw3lib-2.0_4 -lw3nco_4 -lsp_4 -lsigio_4"

elif [ $mac = g -o $mac = t ] ; then
 export machine=wcoss
 export FC=ifort
 export FFLAGSM="-O3 -free -convert big_endian -traceback"
 export LDFLAGSM=-openmp
 export LIBDIR=/nwprod/lib
 export INCMOD=/nwprod/lib/incmod/sigio_4
 export LIBSM="-L${LIBDIR} -lw3emc_4 -lw3nco_4 -lbacio_4 -lsp_4 -lsigio_4"

elif [ $mac = v -o $mac = m ] ; then
 export machine=wcoss_d
 export FC=ifort
 export FFLAGSM="-O3 -free -convert big_endian -traceback"
 export LDFLAGSM=-qopenmp
 export LIBDIR=../../../lib
 export LIBDIR1=/gpfs/dell1/nco/ops/nwprod/lib/w3emc/v2.3.0/ips/18.0.1/impi/18.0.1
 export LIBDIRPROD=/gpfs/dell1/nco/ops/nwprod/lib
 export INCMOD=$LIBDIR/incmod/sigio_4
 export LIBSM="-L${LIBDIR} -lw3nco_4 -lbacio_4 -lsp_4 -lsigio_4 -L${LIBDIR1} -lw3emc_v2.3.0_4"

elif [ $mac2 = ll -o $mac2 = sl ]; then
 export machine=wcoss_c
 export FC=ifort
 export FFLAGSM="-O3 -free -convert big_endian -traceback"
 export LDFLAGSM=-openmp
 export LIBDIR=../../../lib
 export INCMOD=$LIBDIR/incmod/sigio_4
 export LIBSM="-L${LIBDIR} -lbacio_4 -lw3lib-2.0_4 -lw3nco_4 -lsp_4 -lsigio_4"

else
 machine=IBMP6
 export FC=xlf90_r
 export FFLAGSM=" -O -qmaxmem=-1 -qnosave -qsmp=noauto "
 export LIBFLAGSM=
 export LIBDIR=/nwprod/lib
 export INCMOD=/nwprod/lib/incmod
 export LIBSM="-L${LIBDIR} -lw3_4 -lbacio_4 -lsp_4 -lsigio_4"
fi
make -f Makefile_ss2gg
make -f Makefile_ss2ggx
make -f Makefile_ss2lv
make -f Makefile_sigdif

cp -p ss2gg  ../../exec/.
cp -p ss2ggx ../../exec/.
cp -p sigdif ../../exec/.
