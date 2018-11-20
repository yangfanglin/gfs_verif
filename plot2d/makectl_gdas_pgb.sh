#!/bin/ksh
set -x

export expnlist=${expnlist:-"gfs prnemsr"}     ;#experiment names
export expdlist=${expdlist:-"/global/noscrub/emc.glopara/global /global/noscrub/emc.glopara/archive"}  
export dumplist=${dumplist:-".gdas. .gdas."}  ;#file format pgbf${fhr}${dump}${yyyymmdd}${cyc}
export complist=${complist:-"tide tide"}      ;#computers where experiments are run

export guesshr=${guesshr:-"06"}               ;#forecast hour from last gdas cycle used as first guess
export cyclist=${cyclist:-"00 06 12 18"}      ;#forecast cycles to verify
export cychour=${cychour:-6}                  ;#hours between cycles, GFS is fixed to 6 hour
export DATEST=${DATEST:-20160620}             ;#starting verifying date for pgbanl
export DATEND=${DATEND:-20160630}             ;#starting verifying date for pgbanl
export ndays=${ndays:-11}                     ;#number of days between DATEST and DATEND
export nlev=${nlev:-31}                       ;#pgb file vertical layers
export grid=${grid:-G3}                       ;#res, G2->2.5deg; G3->1deg; G4->0.5deg, G193->0.25deg

export vsdbhome=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}
export APRUN=${APRUN:-""}   ;#for running jobs on Gaea
export machine=${machine:-WCOSS}     
export NWPROD=${NWPROD:-/nwprod}     
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export cpygb=${cpygb:-"$APRUN $NWPROD/util/exec/copygb"}
export wgrb=${wgrib:-$NWPROD/util/exec/wgrib}
#---------------------------------------------------------------------------------

if [ $nlev = 26 ]; then
 levlist="1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 30 20 10"
elif [ $nlev = 31 ]; then
 levlist="1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 30 20 10 7 5 3 2 1"
elif [ $nlev = 37 ]; then
 levlist="1000 975 950 925 900 875 850 825 800 775 750 700 650 600 550 500 450 400 350 300 250 225 200 175 150 125 100 70 50 30 20 10 7 5 3 2 1"
elif [ $nlev = 47 ]; then
 levlist="1000 975 950 925 900 875 850 825 800 775 750 725 700 675 650 625 600 575 550 525 500 475 450 425 400 375 350 325 300 275 250 225 200 175 150 125 100 70 50 30 20 10 7 5 3 2 1"
else
 nlev=26
 levlist="1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 30 20 10"
# echo " pgb file vertical layers $nlev not supported, exit"
# exit 
fi

##--special case for ESRL FIM and ECMWF 
for exp in $expnlist; do
 if [ $exp = fim ] ; then 
  nlev=24
  levlist="1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 50 20 10 "
 fi 
done
for exp in $expnlist; do
 if [ $exp = ecm ] ; then 
  nlev=14
  levlist="1000 925 850 700 500 400 300 250 200 150 100 50 20 10"
 fi 
done

rundir=${rundir:-/ptmpd2/$LOGNAME/2dmaps_gdas}
ctldir=${ctldir:-$rundir/ctl}
if [ ! -s $rundir ]; then mkdir -p $rundir ; fi
if [ ! -s $ctldir ]; then mkdir -p $ctldir ; fi
rm $ctldir/*
cd ${rundir} || exit 8

guesshr=0$((guesshr+0))
set -A expdname $expdlist
set -A compname $complist
set -A dumpname $dumplist
set -A cycname  non $cyclist
ncyc=`echo $cyclist |wc -w`
if [ $ncyc -lt 4 ]; then 
 echo " ncyc=$ncyc, must be 4 cycles. exit"
 exit
fi
cycs=${cycname[1]}
cyce=${cycname[$ncyc]}
if [ $ncyc = 1 ]; then inchr=24 ; fi
if [ $ncyc = 2 ]; then inchr=12 ; fi
if [ $ncyc = 4 ]; then inchr=6  ; fi
ncase=$(((ndays+1)*ncyc))

set -A mlist none Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
DATESTA=${DATEST}${cycs} 
yeara=`echo $DATESTA |cut -c 1-4`
mona=`echo $DATESTA |cut -c 5-6`
daya=`echo $DATESTA |cut -c 7-8`
cyca=`echo $DATESTA |cut -c 9-10`
mona=${mlist[$mona]}
DATESTG=`$ndate -$cychour ${DATEST}${cycs}`   ;##first first guess 
yearg=`echo $DATESTG |cut -c 1-4`
mong=`echo $DATESTG |cut -c 5-6`
dayg=`echo $DATESTG |cut -c 7-8`
cycg=`echo $DATESTG |cut -c 9-10`
mong=${mlist[$mong]}

if [ $grid = G2 ]; then
 nptx=144; npty=73; dxy=2.5; gribtype=2
elif [ $grid = G3 ]; then
 nptx=360; npty=181; dxy=1.0; gribtype=3
elif [ $grid = G4 ]; then
 nptx=720; npty=361; dxy=0.5; gribtype=4
elif [ $grid = G193 ]; then
 nptx=1440; npty=721; dxy=0.25; gribtype=193
else
 echo " pgb file grid $grid not supported, exit"
 exit 
fi
GG=`echo $grid |cut -c2- `


#------------------------------
n=0
for exp in $expnlist; do
#------------------------------
export dump=${dumpname[n]}
expdir=${expdname[n]}
CLIENT=${compname[n]}
myhost=`echo $(hostname) |cut -c 1-1 `
myclient=`echo $CLIENT |cut -c 1-1 `

export datadir=$rundir/$exp
if [ ! -s $datadir ]; then mkdir -p $datadir ;fi
cd $datadir ||exit 8

GGa=999
sdate=${DATEST}${cycs}
edate=${DATEND}${cyce}            
while [ $sdate -le $edate ]; do
 gdate=`$ndate -$cychour ${sdate}`   ;##first guess 
 inputa=${expdir}/${exp}/pgbanl$dump$sdate
 outputa=${datadir}/pgbanl$dump$sdate
 inputg=${expdir}/${exp}/pgbf${guesshr}$dump$gdate
 outputg=${datadir}/pgbf${guesshr}$dump$gdate

  if [ -s xtmpa ]; then rm -f xtmpa xtmpg; fi

  if [ -s  $inputa ]; then 
   ln -fs $inputa  ${datadir}/xtmpa
   ln -fs $inputg  ${datadir}/xtmpg
  elif [ $machine = WCOSS -o $machine = WCOSS_C ]; then 
   scp -pB ${LOGNAME}@${CLIENT}:$inputa ${datadir}/xtmpa
   scp -pB ${LOGNAME}@${CLIENT}:$inputg ${datadir}/xtmpg
  else
   echo "$input does not exist !"
  fi

  if [ $GGa = 999 ]; then 
   if [ $exp = ecm ]; then
    GGa=`$wgrb -d 1 -V ${datadir}/xtmpa -o /dev/null | grep -o 'grid=[^\n][^\n][^\n]' | cut -c6-`
   else
    GGa=`$wgrb -d 1 -V ${datadir}/xtmpa -o /dev/null | grep -o 'grid=[^\n]' | cut -c6-`
   fi
  fi
  if [ $GGa = $GG ]; then
   mv ${datadir}/xtmpa $outputa                                                              
   mv ${datadir}/xtmpg $outputg                                                              
  else
   ${cpygb} -g$GG -x  xtmpa $outputa                                                              
   ${cpygb} -g$GG -x  xtmpg $outputg                                                              
  fi
 sdate=`$ndate +$inchr $sdate`
done

#---------------------------------------------------------------------------------
cat >$ctldir/${exp}_anl.ctl <<EOF
dset ${datadir}/pgbanl${dump}%y4%m2%d2%h2
index $ctldir/${exp}_anl.idx           
undef 9.999E+20
dtype grib $gribtype
format template
options yrev
xdef $nptx linear 0.000000 $dxy     
ydef $npty linear -90.000000 $dxy 
tdef $ncase linear ${cyca}Z${daya}${mona}${yeara} ${inchr}hr
zdef $nlev levels ${levlist}
vars 84
no4LFTXsfc    0 132,1,0  ** surface Best (4-layer) lifted index [K]
no5WAVH500mb  0 222,100,500 ** 500 mb 5-wave geopotential height [gpm]
ABSVprs       $nlev 41,100,0 ** (profile) Absolute vorticity [/s]
CAPEsfc       0 157,1,0  ** surface Convective Avail. Pot. Energy [J/kg]
CAPE180_0mb   0 157,116,46080 ** 180-0 mb above gnd Convective Avail. Pot. Energy [J/kg]
CINsfc        0 156,1,0  ** surface Convective inhibition [J/kg]
CIN180_0mb    0 156,116,46080 ** 180-0 mb above gnd Convective inhibition [J/kg]
CLWMRprs      $nlev 153,100,0 ** (profile) Cloud water [kg/kg]
CWATclm       0 76,200,0 ** atmos column Cloud water [kg/m^2]
HGTsfc        0 7,1,0  ** surface Geopotential height [gpm]
HGTprs        $nlev 7,100,0 ** (profile) Geopotential height [gpm]
HGTpv2000     0 7,117,2000 ** pot vorticity = 2000 units level Geopotential height [gpm]
HGTpvneg2000  0 7,117,34768 ** pot vorticity = -2000 units level Geopotential height [gpm]
HGThtfl       0 7,204,0 ** highest trop freezing level Geopotential height [gpm]
HGT0deg       0 7,4,0 ** 0C isotherm level Geopotential height [gpm]
HGTmwl        0 7,6,0 ** max wind level Geopotential height [gpm]
HGTtrp        0 7,7,0 ** tropopause Geopotential height [gpm]
ICAHTmwl      0 5,6,0 ** max wind level ICAO Standard Atmosphere Reference Height [M]
ICAHTtrp      0 5,7,0 ** tropopause ICAO Standard Atmosphere Reference Height [M]
LFTXsfc       0 131,1,0  ** surface Surface lifted index [K]
MSLETmsl      0 130,102,0 ** mean-sea level Mean sea level pressure (ETA model) [Pa]
O3MRprs       $nlev 154,100,0 ** (profile) Ozone mixing ratio [kg/kg]
POTsig995     0 13,107,9950 ** sigma=.995  Potential temp. [K]
PRESsfc       0 1,1,0  ** surface Pressure [Pa]
PRESpv2000    0 1,117,2000 ** pot vorticity = 2000 units level Pressure [Pa]
PRESpvneg2000  0 1,117,34768 ** pot vorticity = -2000 units level Pressure [Pa]
PRESmwl       0 1,6,0 ** max wind level Pressure [Pa]
PREStrp       0 1,7,0 ** tropopause Pressure [Pa]
PRMSLmsl      0 2,102,0 ** mean-sea level Pressure reduced to MSL [Pa]
PWATclm       0 54,200,0 ** atmos column Precipitable water [kg/m^2]
RHprs         $nlev 52,100,0 ** (profile) Relative humidity [%]
RHsig995      0 52,107,9950 ** sigma=.995  Relative humidity [%]
RHsg33_100    0 52,108,8548 ** sigma=0.33-1 layer Relative humidity [%]
RHsg44_72     0 52,108,11336 ** sigma=0.44-0.72 layer Relative humidity [%]
RHsg44_100    0 52,108,11364 ** sigma=0.44-1 layer Relative humidity [%]
RHsg72_94     0 52,108,18526 ** sigma=0.72-0.94 layer Relative humidity [%]
RH30_0mb      0 52,116,7680 ** 30-0 mb above gnd Relative humidity [%]
RHclm         0 52,200,0 ** atmos column Relative humidity [%]
RHhtfl        0 52,204,0 ** highest trop freezing level Relative humidity [%]
RH0deg        0 52,4,0 ** 0C isotherm level Relative humidity [%]
SPFH30_0mb    0 51,116,7680 ** 30-0 mb above gnd Specific humidity [kg/kg]
SPFHprs       $nlev 51,100,0 **  Specific Humidity [kg/kg]
TMPprs        $nlev 11,100,0 ** (profile) Temp. [K]
TMP3658m      0 11,103,3658 ** 3658 m above msl Temp. [K]
TMP2743m      0 11,103,2743 ** 2743 m above msl Temp. [K]
TMP1829m      0 11,103,1829 ** 1829 m above msl Temp. [K]
TMP100m       0 11,105,100 ** 100 m above ground Temp. [K]
TMP80m        0 11,105,80 ** 80 m above ground Temp. [K]
TMPsig995     0 11,107,9950 ** sigma=.995  Temp. [K]
TMP30_0mb     0 11,116,7680 ** 30-0 mb above gnd Temp. [K]
TMPpv2000     0 11,117,2000 ** pot vorticity = 2000 units level Temp. [K]
TMPpvneg2000  0 11,117,34768 ** pot vorticity = -2000 units level Temp. [K]
TMPmwl        0 11,6,0 ** max wind level Temp. [K]
TMPtrp        0 11,7,0 ** tropopause Temp. [K]
TOZNEclm      0 10,200,0 ** atmos column Total ozone [Dobson]
UGRDprs       $nlev 33,100,0 ** (profile) u wind [m/s]
UGRD3658m     0 33,103,3658 ** 3658 m above msl u wind [m/s]
UGRD2743m     0 33,103,2743 ** 2743 m above msl u wind [m/s]
UGRD1829m     0 33,103,1829 ** 1829 m above msl u wind [m/s]
UGRD100m      0 33,105,100 ** 100 m above ground u wind [m/s]
UGRD80m       0 33,105,80 ** 80 m above ground u wind [m/s]
UGRDsig995    0 33,107,9950 ** sigma=.995  u wind [m/s]
UGRD30_0mb    0 33,116,7680 ** 30-0 mb above gnd u wind [m/s]
UGRDpv2000    0 33,117,2000 ** pot vorticity = 2000 units level u wind [m/s]
UGRDpvneg2000  0 33,117,34768 ** pot vorticity = -2000 units level u wind [m/s]
UGRDmwl       0 33,6,0 ** max wind level u wind [m/s]
UGRDtrp       0 33,7,0 ** tropopause u wind [m/s]
VGRDprs       $nlev 34,100,0 ** (profile) v wind [m/s]
VGRD3658m     0 34,103,3658 ** 3658 m above msl v wind [m/s]
VGRD2743m     0 34,103,2743 ** 2743 m above msl v wind [m/s]
VGRD1829m     0 34,103,1829 ** 1829 m above msl v wind [m/s]
VGRD100m      0 34,105,100 ** 100 m above ground v wind [m/s]
VGRD80m       0 34,105,80 ** 80 m above ground v wind [m/s]
VGRDsig995    0 34,107,9950 ** sigma=.995  v wind [m/s]
VGRD30_0mb    0 34,116,7680 ** 30-0 mb above gnd v wind [m/s]
VGRDpv2000    0 34,117,2000 ** pot vorticity = 2000 units level v wind [m/s]
VGRDpvneg2000 0 34,117,34768 ** pot vorticity = -2000 units level v wind [m/s]
VGRDmwl       0 34,6,0 ** max wind level v wind [m/s]
VGRDtrp       0 34,7,0 ** tropopause v wind [m/s]
VVELprs       $nlev 39,100,0 ** (profile) Pressure vertical velocity [Pa/s]
VVELsig995    0 39,107,9950 ** sigma=.995  Pressure vertical velocity [Pa/s]
VWSHpv2000    0 136,117,2000 ** pot vorticity = 2000 units level Vertical speed shear [1/s]
VWSHpvneg2000 0 136,117,34768 ** pot vorticity = -2000 units level Vertical speed shear [1/s]
VWSHtrp       0 136,7,0 ** tropopause Vertical speed shear [1/s]
ENDVARS
EOF
#----
gribmap -0 -i $ctldir/${exp}_anl.ctl
#-----------------------------------


#-----------------------------------
cat >$ctldir/${exp}_ges.ctl <<EOF
dset ${datadir}/pgbf${guesshr}${dump}%y4%m2%d2%h2
index $ctldir/${exp}_ges.idx           
undef 9.999E+20
dtype grib $gribtype
format template
options yrev
xdef $nptx linear 0.000000 $dxy     
ydef $npty linear -90.000000 $dxy 
tdef $ncase linear ${cycg}Z${dayg}${mong}${yearg} ${inchr}hr
zdef $nlev levels ${levlist}
vars 84
no4LFTXsfc    0 132,1,0  ** surface Best (4-layer) lifted index [K]
no5WAVH500mb  0 222,100,500 ** 500 mb 5-wave geopotential height [gpm]
ABSVprs       $nlev 41,100,0 ** (profile) Absolute vorticity [/s]
CAPEsfc       0 157,1,0  ** surface Convective Avail. Pot. Energy [J/kg]
CAPE180_0mb   0 157,116,46080 ** 180-0 mb above gnd Convective Avail. Pot. Energy [J/kg]
CINsfc        0 156,1,0  ** surface Convective inhibition [J/kg]
CIN180_0mb    0 156,116,46080 ** 180-0 mb above gnd Convective inhibition [J/kg]
CLWMRprs      $nlev 153,100,0 ** (profile) Cloud water [kg/kg]
CWATclm       0 76,200,0 ** atmos column Cloud water [kg/m^2]
HGTsfc        0 7,1,0  ** surface Geopotential height [gpm]
HGTprs        $nlev 7,100,0 ** (profile) Geopotential height [gpm]
HGTpv2000     0 7,117,2000 ** pot vorticity = 2000 units level Geopotential height [gpm]
HGTpvneg2000  0 7,117,34768 ** pot vorticity = -2000 units level Geopotential height [gpm]
HGThtfl       0 7,204,0 ** highest trop freezing level Geopotential height [gpm]
HGT0deg       0 7,4,0 ** 0C isotherm level Geopotential height [gpm]
HGTmwl        0 7,6,0 ** max wind level Geopotential height [gpm]
HGTtrp        0 7,7,0 ** tropopause Geopotential height [gpm]
ICAHTmwl      0 5,6,0 ** max wind level ICAO Standard Atmosphere Reference Height [M]
ICAHTtrp      0 5,7,0 ** tropopause ICAO Standard Atmosphere Reference Height [M]
LFTXsfc       0 131,1,0  ** surface Surface lifted index [K]
MSLETmsl      0 130,102,0 ** mean-sea level Mean sea level pressure (ETA model) [Pa]
O3MRprs       $nlev 154,100,0 ** (profile) Ozone mixing ratio [kg/kg]
POTsig995     0 13,107,9950 ** sigma=.995  Potential temp. [K]
PRESsfc       0 1,1,0  ** surface Pressure [Pa]
PRESpv2000    0 1,117,2000 ** pot vorticity = 2000 units level Pressure [Pa]
PRESpvneg2000  0 1,117,34768 ** pot vorticity = -2000 units level Pressure [Pa]
PRESmwl       0 1,6,0 ** max wind level Pressure [Pa]
PREStrp       0 1,7,0 ** tropopause Pressure [Pa]
PRMSLmsl      0 2,102,0 ** mean-sea level Pressure reduced to MSL [Pa]
PWATclm       0 54,200,0 ** atmos column Precipitable water [kg/m^2]
RHprs         $nlev 52,100,0 ** (profile) Relative humidity [%]
RHsig995      0 52,107,9950 ** sigma=.995  Relative humidity [%]
RHsg33_100    0 52,108,8548 ** sigma=0.33-1 layer Relative humidity [%]
RHsg44_72     0 52,108,11336 ** sigma=0.44-0.72 layer Relative humidity [%]
RHsg44_100    0 52,108,11364 ** sigma=0.44-1 layer Relative humidity [%]
RHsg72_94     0 52,108,18526 ** sigma=0.72-0.94 layer Relative humidity [%]
RH30_0mb      0 52,116,7680 ** 30-0 mb above gnd Relative humidity [%]
RHclm         0 52,200,0 ** atmos column Relative humidity [%]
RHhtfl        0 52,204,0 ** highest trop freezing level Relative humidity [%]
RH0deg        0 52,4,0 ** 0C isotherm level Relative humidity [%]
SPFH30_0mb    0 51,116,7680 ** 30-0 mb above gnd Specific humidity [kg/kg]
SPFHprs       $nlev 51,100,0 **  Specific Humidity [kg/kg]
TMPprs        $nlev 11,100,0 ** (profile) Temp. [K]
TMP3658m      0 11,103,3658 ** 3658 m above msl Temp. [K]
TMP2743m      0 11,103,2743 ** 2743 m above msl Temp. [K]
TMP1829m      0 11,103,1829 ** 1829 m above msl Temp. [K]
TMP100m       0 11,105,100 ** 100 m above ground Temp. [K]
TMP80m        0 11,105,80 ** 80 m above ground Temp. [K]
TMPsig995     0 11,107,9950 ** sigma=.995  Temp. [K]
TMP30_0mb     0 11,116,7680 ** 30-0 mb above gnd Temp. [K]
TMPpv2000     0 11,117,2000 ** pot vorticity = 2000 units level Temp. [K]
TMPpvneg2000  0 11,117,34768 ** pot vorticity = -2000 units level Temp. [K]
TMPmwl        0 11,6,0 ** max wind level Temp. [K]
TMPtrp        0 11,7,0 ** tropopause Temp. [K]
TOZNEclm      0 10,200,0 ** atmos column Total ozone [Dobson]
UGRDprs       $nlev 33,100,0 ** (profile) u wind [m/s]
UGRD3658m     0 33,103,3658 ** 3658 m above msl u wind [m/s]
UGRD2743m     0 33,103,2743 ** 2743 m above msl u wind [m/s]
UGRD1829m     0 33,103,1829 ** 1829 m above msl u wind [m/s]
UGRD100m      0 33,105,100 ** 100 m above ground u wind [m/s]
UGRD80m       0 33,105,80 ** 80 m above ground u wind [m/s]
UGRDsig995    0 33,107,9950 ** sigma=.995  u wind [m/s]
UGRD30_0mb    0 33,116,7680 ** 30-0 mb above gnd u wind [m/s]
UGRDpv2000    0 33,117,2000 ** pot vorticity = 2000 units level u wind [m/s]
UGRDpvneg2000  0 33,117,34768 ** pot vorticity = -2000 units level u wind [m/s]
UGRDmwl       0 33,6,0 ** max wind level u wind [m/s]
UGRDtrp       0 33,7,0 ** tropopause u wind [m/s]
VGRDprs       $nlev 34,100,0 ** (profile) v wind [m/s]
VGRD3658m     0 34,103,3658 ** 3658 m above msl v wind [m/s]
VGRD2743m     0 34,103,2743 ** 2743 m above msl v wind [m/s]
VGRD1829m     0 34,103,1829 ** 1829 m above msl v wind [m/s]
VGRD100m      0 34,105,100 ** 100 m above ground v wind [m/s]
VGRD80m       0 34,105,80 ** 80 m above ground v wind [m/s]
VGRDsig995    0 34,107,9950 ** sigma=.995  v wind [m/s]
VGRD30_0mb    0 34,116,7680 ** 30-0 mb above gnd v wind [m/s]
VGRDpv2000    0 34,117,2000 ** pot vorticity = 2000 units level v wind [m/s]
VGRDpvneg2000 0 34,117,34768 ** pot vorticity = -2000 units level v wind [m/s]
VGRDmwl       0 34,6,0 ** max wind level v wind [m/s]
VGRDtrp       0 34,7,0 ** tropopause v wind [m/s]
VVELprs       $nlev 39,100,0 ** (profile) Pressure vertical velocity [Pa/s]
VVELsig995    0 39,107,9950 ** sigma=.995  Pressure vertical velocity [Pa/s]
VWSHpv2000    0 136,117,2000 ** pot vorticity = 2000 units level Vertical speed shear [1/s]
VWSHpvneg2000 0 136,117,34768 ** pot vorticity = -2000 units level Vertical speed shear [1/s]
VWSHtrp       0 136,7,0 ** tropopause Vertical speed shear [1/s]
ENDVARS
EOF
#----
gribmap -0 -i $ctldir/${exp}_ges.ctl
#-----------------------------------


#-----------------------------------
n=`expr $n + 1 `
done  ;# exp
#-----------------------------------

exit
