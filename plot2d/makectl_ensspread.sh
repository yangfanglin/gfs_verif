#!/bin/ksh
set -x

##--grads ctl for ensemble mean and ensemble spread
##--Fanglin Yang, June 2015

exp=${exp:-"pr4dev"}                 ;#exp name
expdir=${expdir:-"/global/noscrub/emc.glopara/archive"}
DATEST=${DATEST:-20150311}           ;#starting verifying date
DATEND=${DATEND:-20150312}           ;#ending verifying date
cycs=${cycs:-12}                     ;#starting verifying cycle
ghr=${ghr:-03}                       ;#forecast hours from guess 
ncount=${ncount:-2}                  ;#number of cases
inthour=${inthour:-24}               ;#cycle interval in hours 
JCAP_bin=${JCAP_bin:-254}            ;#binary file res
nlev=${nlev:-64}                     ;#sig file vertical layers, 64-L for GFS

#---------------------------------------------------------------------------------
#linear grid
if [ $JCAP_bin = 574 ]; then
 lonb=1152; latb=576; dx=0.312500  ; dy=0.313043
elif [ $JCAP_bin = 254 ]; then
 lonb=512;  latb=256;  dx=0.703125  ; dy=0.703125    
elif [ $JCAP_bin = 126 ]; then
 lonb=384;  latb=190;  dx=0.937500  ; dy=0.952381
elif [ $JCAP_bin = 62 ]; then
 lonb=192;  latb=94;   dx=1.875000  ; dy=1.935484
else
 echo " JCAP_bin=$JCAP_bin not supported, exit"
 exit 
fi

rundir=${rundir:-/ptmpd2/$LOGNAME/ensspread}
ctldir=${ctldir:-$rundir/ctl}
if [ ! -s $rundir ]; then mkdir -p $rundir ; fi
if [ ! -s $ctldir ]; then mkdir -p $ctldir ; fi
cd ${ctldir} || exit 8

set -A mlist none Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
yeara=`echo $DATEST |cut -c 1-4`
mona=`echo $DATEST |cut -c 5-6`
daya=`echo $DATEST |cut -c 7-8`
mona=${mlist[$mona]}


cat >$ctldir/${exp}_sfg_fhr${ghr}s_ensmean.ctl <<EOF
dset ${expdir}/$exp/sigf${ghr}_%y4%m2%d2%h2_ensmean.bin  
options yrev
format template
undef -9.99E+33
TITLE ensemble mean
xdef  $lonb linear    0.000000    $dx           
ydef  $latb linear  -90.000000    $dy             
zdef  $nlev linear 1 1
tdef $ncount linear ${cycs}Z${daya}${mona}${yeara} ${inthour}hr
VARS     7
PS    1 99 surface pressure (Pa)
U    $nlev 99 zonal wind (m/s)
V    $nlev 99 meridional wind (m/s)
T    $nlev 99 temperature (K)
Q    $nlev 99 specific humidity (kg/kg)
O3   $nlev 99 ozone concentration (kg/kg)
CLW  $nlev 99 cloud water mixing ratio (kg/kg)
ENDVARS
EOF


cat >$ctldir/${exp}_sfg_fhr${ghr}s_ensspread.ctl <<EOF
dset ${expdir}/$exp/sigf${ghr}_%y4%m2%d2%h2_ensspread.bin  
options yrev
format template
undef -9.99E+33
TITLE ensemble mean
xdef  $lonb linear    0.000000    $dx           
ydef  $latb linear  -90.000000    $dy             
zdef  $nlev linear 1 1
tdef $ncount linear ${cycs}Z${daya}${mona}${yeara} ${inthour}hr
VARS     7
PS    1 99 surface pressure (Pa)
U    $nlev 99 zonal wind (m/s)
V    $nlev 99 meridional wind (m/s)
T    $nlev 99 temperature (K)
Q    $nlev 99 specific humidity (kg/kg)
O3   $nlev 99 ozone concentration (kg/kg)
CLW  $nlev 99 cloud water mixing ratio (kg/kg)
ENDVARS
EOF

exit
