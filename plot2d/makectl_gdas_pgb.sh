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
export cpygb2=${cpygb2:-"$APRUN $NWPROD/util/exec/copygb2"}
export wgrb=${wgrib:-$NWPROD/util/exec/wgrib}
export wgrb2=${wgrib2:-$NWPROD/util/exec/wgrib2}
export grbmap=${gribmap:-$NWPROD/util/exec/gribmap}
#---------------------------------------------------------------------------------

if [ $nlev = 31 ]; then
 levlist="1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 30 20 10 7 5 3 2 1"
 levlistp="100000 97500 95000 92500 90000 85000 80000 75000 70000 65000 60000 55000 50000 45000 40000 35000 30000 25000 20000 15000 10000 7000 5000 3000 2000 1000 700 500 300 200 100"
elif [ $nlev = 41 ]; then
 levlist="1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 40 30 20 15 10 7 5 3 2 1 0.7 0.2 0.2 0.1 0.07 0.04 0.02 0.01"
 levlistp="100000 97500 95000 92500 90000 85000 80000 75000 70000 65000 60000 55000 50000 45000 40000 35000 30000 25000 20000 15000 10000 7000 5000 4000 3000 2000 1500 1000 700 500 300 200 100 70 40 20 10 7 4 2 1"
elif [ $nlev = 37 ]; then
 levlist="1000 975 950 925 900 875 850 825 800 775 750 700 650 600 550 500 450 400 350 300 250 225 200 175 150 125 100 70 50 30 20 10 7 5 3 2 1"
 levlistp="100000 97500 95000 92500 90000 87500 85000 82500 80000 77500 75000 70000 65000 60000 55000 50000 45000 40000 35000 30000 25000 22500 20000 17500 15000 12500 10000 7000 5000 3000 2000 1000 700 500 300 200 100"
elif [ $nlev = 47 ]; then
 levlist="1000 975 950 925 900 875 850 825 800 775 750 725 700 675 650 625 600 575 550 525 500 475 450 425 400 375 350 325 300 275 250 225 200 175 150 125 100 70 50 30 20 10 7 5 3 2 1"
 levlistp="100000 97500 95000 92500 90000 87500 85000 82500 80000 77500 75000 72500 70000 67500 65000 62500 60000 57500 55000 52500 50000 47500 45000 42500 40000 37500 35000 32500 30000 27500 25000 22500 20000 17500 15000 12500 10000 7000 5000 3000 2000 1000 700 500 300 200 100"
else
 nlev=26
 levlist="1000 975 950 925 900 850 800 750 700 650 600 550 500 450 400 350 300 250 200 150 100 70 50 30 20 10"
 levlistp="100000 97500 95000 92500 90000 85000 80000 75000 70000 65000 60000 55000 50000 45000 40000 35000 30000 25000 20000 15000 10000 7000 5000 3000 2000 1000"
fi

##--special case for ECMWF
for exp in $expnlist; do
 if [ $exp = ecm ] ; then
  nlev=14
  levlist="1000 925 850 700 500 400 300 250 200 150 100 50 20 10"
  levlistp="100000 92500 85000 70000 50000 40000 30000 25000 20000 15000 10000 5000 2000 1000"
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
 gridout="0 6 0 0 0 0 0 0 144 73 0 0 90000000 0 48 -90000000 357500000 2500000 2500000 0"
elif [ $grid = G3 ]; then
 nptx=360; npty=181; dxy=1.0; gribtype=3
 gridout="0 6 0 0 0 0 0 0 360 181 0 0 90000000 0 48 -90000000 359000000 1000000 1000000 0"
elif [ $grid = G4 ]; then
 nptx=720; npty=361; dxy=0.5; gribtype=4
 gridout="0 6 0 0 0 0 0 0 720 361 0 0 90000000 0 48 -90000000 359500000 500000 500000 0"
else
 echo " pgb file grid $grid not supported, exit"
 exit
fi
npts=$((nptx*npty))
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

sdate=${DATEST}${cycs}
edate=${DATEND}${cyce}            

#------------------------------
while [ $sdate -le $edate ]; do
testa=${expdir}/${exp}/pgbanl$dump$sdate
testb=${expdir}/${exp}/pgbanl$dump$sdate.grib2
if [ -s $testa -o -s $testb ]; then
#------------------------------

 # determine data grib type and resolution
 gribend=""
 if [ -s $testb ]; then gribend=".grib2"; fi
 if [ $gribend = ".grib2" ]; then
   points=`$wgrb2 -d 1 -V $testb |grep -o 'points=[^\n][^\n][^\n][^\n][^\n]' |cut -c8-`
   docpygb=NO
   if [ $points -ne $npts ]; then docpygb=YES; fi
 else
   gtype=`$wgrb -d 1 -V $testa -o /dev/null | grep -o 'grid=[^\n]' | cut -c6-`
   docpygb=NO
   if [ $gtype -ne $GG ]; then docpygb=YES; fi
 fi

 gdate=`$ndate -$cychour ${sdate}`   ;##first guess 
 inputa=${expdir}/${exp}/pgbanl$dump$sdate$gribend
 outputa=${datadir}/pgbanl$dump$sdate$gribend
 inputg=${expdir}/${exp}/pgbf${guesshr}$dump$gdate$gribend
 outputg=${datadir}/pgbf${guesshr}$dump$gdate$gribend

  if [ -s  $inputa ]; then 
   if [ $docpygb = NO ]; then
    ln -fs $inputa  $outputa          
    ln -fs $inputg  $outputg          
   else
    if [ $gribend = ".grib2" ]; then
      $cpygb2 -g "${gridout}" -x $inputa $outputa
      $cpygb2 -g "${gridout}" -x $inputg $outputg
    else
      ${cpygb} -g$GG -x $inputa $outputa
      ${cpygb} -g$GG -x $inputg $outputg
    fi
   fi
  else
   echo "$input does not exist !"
  fi

#----------------------------------
fi
sdate=`$ndate +$inchr $sdate`
done
#----------------------------------



#----------------------------------
if [ $gribend = ".grib2" ]; then
#----------------------------------

cat >$ctldir/${exp}_anl.ctl <<EOF
dset ${datadir}/pgbanl${dump}%y4%m2%d2%h2.grib2
index $ctldir/${exp}_anl.grib2.idx           
undef 9.999E+20
dtype grib2 
format template
options pascals
xdef $nptx linear 0.000000 $dxy     
ydef $npty linear -90.000000 $dxy 
tdef $ncase linear ${cyca}Z${daya}${mona}${yeara} ${inchr}hr
zdef $nlev levels ${levlistp}
vars 194
no4LFTXsfc   0,1,0   0,7,193 ** surface Best (4 layer) Lifted Index [K]
no5WAVH500mb   0,100,50000   0,3,193 ** 500 mb 5-Wave Geopotential Height [gpm]
ABSVprs    $nlev,100  0,2,10 ** (1000 975 950 925 900.. 30 20 15 10 40) Absolute Vorticity [1/s]
ACPCPsfc   0,1,0   0,1,10,1 ** surface Convective Precipitation [kg/m^2]
ALBDOsfc   0,1,0   0,19,1,0 ** surface Albedo [%]
APCPsfc   0,1,0   0,1,8,1 ** surface Total Precipitation [kg/m^2]
APTMP2m   0,103,2   0,0,21 ** 2 m above ground Apparent Temperature [K]
CAPEsfc   0,1,0   0,7,6 ** surface Convective Available Potential Energy [J/kg]
CAPE180_0mb  0,108,18000,0   0,7,6 ** 180-0 mb above ground Convective Available Potential Energy [J/kg]
CAPE255_0mb  0,108,25500,0   0,7,6 ** 255-0 mb above ground Convective Available Potential Energy [J/kg]
CFRZRavesfc  0,1,0   0,1,193,0 ** surface Categorical Freezing Rain [-]
CFRZRsfc  0,1,0   0,1,193 ** surface Categorical Freezing Rain [-]
CICEPavesfc  0,1,0   0,1,194,0 ** surface Categorical Ice Pellets [-]
CICEPsfc  0,1,0   0,1,194 ** surface Categorical Ice Pellets [-]
CINsfc   0,1,0   0,7,7 ** surface Convective Inhibition [J/kg]
CIN180_0mb  0,108,18000,0   0,7,7 ** 180-0 mb above ground Convective Inhibition [J/kg]
CIN255_0mb  0,108,25500,0   0,7,7 ** 255-0 mb above ground Convective Inhibition [J/kg]
CLWMRprs    $nlev,100  0,1,22 ** (1000 975 950 925 900.. 250 200 150 100 50) Cloud Mixing Ratio [kg/kg]
CLWMRhy1   0,105,1   0,1,22 ** 1 hybrid level Cloud Mixing Ratio [kg/kg]
CPOFPsfc   0,1,0   0,1,39 ** surface Percent frozen precipitation [%]
CPRATavesfc  0,1,0   0,1,196,0 ** surface Convective Precipitation Rate [kg/m^2/s]
CPRATsfc  0,1,0   0,1,37 ** surface Convective Precipitation Rate [kg/m^2/s]
CRAINavesfc  0,1,0   0,1,192,0 ** surface Categorical Rain [-]
CRAINsfc  0,1,0   0,1,192 ** surface Categorical Rain [-]
CSNOWavesfc  0,1,0   0,1,195,0 ** surface Categorical Snow [-]
CSNOWsfc  0,1,0   0,1,195 ** surface Categorical Snow [-]
CWATclm   0,200,0   0,6,6 ** entire atmosphere (considered as a single layer) Cloud Water [kg/m^2]
CWORKclm   0,200,0   0,6,193,0 ** entire atmosphere (considered as a single layer) Cloud Work Function [J/kg]
DLWRFsfc   0,1,0   0,5,192,0 ** surface Downward Long-Wave Rad. Flux [W/m^2]
DPT2m   0,103,2   0,0,6 ** 2 m above ground Dew Point Temperature [K]
DSWRFsfc   0,1,0   0,4,192,0 ** surface Downward Short-Wave Radiation Flux [W/m^2]
DZDTprs    21,100  0,2,9 ** (1000 975 950 925 900.. 300 250 200 150 100) Vertical Velocity (Geometric) [m/s]
FLDCPsfc   0,1,0   2,3,203 ** surface Field Capacity [Fraction]
GFLUXsfc   0,1,0   2,0,193,0 ** surface Ground Heat Flux [W/m^2]
GRLEprs    $nlev,100  0,1,32 ** (1000 975 950 925 900.. 250 200 150 100 50) Graupel [kg/kg]
GRLEhy1   0,105,1   0,1,32 ** 1 hybrid level Graupel [kg/kg]
GUSTsfc   0,1,0   0,2,22 ** surface Wind Speed (Gust) [m/s]
HGTsfc   0,1,0   0,3,5 ** surface Geopotential Height [gpm]
HGTprs    $nlev,100  0,3,5 ** (1000 975 950 925 900.. 10 7 4 2 1) Geopotential Height [gpm]
HGT2pv   0,109,2e-06   0,3,5 ** PV=2e-06 (Km^2/kg/s) surface Geopotential Height [gpm]
HGTneg2pv   0,109,-2e-06   0,3,5 ** PV=-2e-06 (Km^2/kg/s) surface Geopotential Height [gpm]
HGThtfl   0,204,0   0,3,5 ** highest tropospheric freezing level Geopotential Height [gpm]
HGT0C   0,4,0   0,3,5 ** 0C isotherm Geopotential Height [gpm]
HGTmwl   0,6,0   0,3,5 ** max wind Geopotential Height [gpm]
HGTtrop   0,7,0   0,3,5 ** tropopause Geopotential Height [gpm]
HINDEXsfc   0,1,0   2,4,2 ** surface Haines Index [Numeric]
HLCY3000_0m  0,103,3000,0   0,7,8 ** 3000-0 m above ground Storm Relative Helicity [m^2/s^2]
HPBLsfc   0,1,0   0,3,196 ** surface Planetary Boundary Layer Height [m]
ICAHTmwl   0,6,0   0,3,3 ** max wind ICAO Standard Atmosphere Reference Height [m]
ICAHTtrop   0,7,0   0,3,3 ** tropopause ICAO Standard Atmosphere Reference Height [m]
ICECsfc   0,1,0   10,2,0 ** surface Ice Cover [Proportion]
ICMRprs    $nlev,100  0,1,23 ** (1000 975 950 925 900.. 250 200 150 100 50) Ice Water Mixing Ratio [kg/kg]
ICMRhy1   0,105,1   0,1,23 ** 1 hybrid level Ice Water Mixing Ratio [kg/kg]
ICSEVprs    $nlev,100  0,19,234 ** (1000 950 900 850 800.. 300 250 200 150 100) Icing severity [non-dim]
LANDsfc   0,1,0   2,0,0 ** surface Land Cover (0=sea, 1=land) [Proportion]
LFTXsfc   0,1,0   0,7,192 ** surface Surface Lifted Index [K]
LHTFLsfc   0,1,0   0,0,10,0 ** surface Latent Heat Net Flux [W/m^2]
MSLETmsl   0,101,0   0,3,192 ** mean sea level MSLP (Eta model reduction) [Pa]
O3MRprs    $nlev,100  0,14,192 ** (1000 850 700 500 400.. 5 3 2 1 40) Ozone Mixing Ratio [kg/kg]
PEVPRsfc   0,1,0   0,1,200 ** surface Potential Evaporation Rate [W/m^2]
PLPL255_0mb  0,108,25500,0   0,3,200 ** 255-0 mb above ground Pressure of level from which parcel was lifted [Pa]
POTsig995   0,104,0.995   0,0,2 ** 0.995 sigma level Potential Temperature [K]
PRATEavesfc  0,1,0   0,1,7,0 ** surface Precipitation Rate [kg/m^2/s]
PRATEsfc  0,1,0   0,1,7 ** surface Precipitation Rate [kg/m^2/s]
PRESlclb   0,212,0   0,3,0,0 ** low cloud bottom level Pressure [Pa]
PRESlclt   0,213,0   0,3,0,0 ** low cloud top level Pressure [Pa]
PRESmclb   0,222,0   0,3,0,0 ** middle cloud bottom level Pressure [Pa]
PRESmclt   0,223,0   0,3,0,0 ** middle cloud top level Pressure [Pa]
PREShclb   0,232,0   0,3,0,0 ** high cloud bottom level Pressure [Pa]
PREShclt   0,233,0   0,3,0,0 ** high cloud top level Pressure [Pa]
PRESsfc   0,1,0   0,3,0 ** surface Pressure [Pa]
PRES80m   0,103,80   0,3,0 ** 80 m above ground Pressure [Pa]
PRES2pv   0,109,2e-06   0,3,0 ** PV=2e-06 (Km^2/kg/s) surface Pressure [Pa]
PRESneg2pv   0,109,-2e-06   0,3,0 ** PV=-2e-06 (Km^2/kg/s) surface Pressure [Pa]
PREScclb   0,242,0   0,3,0 ** convective cloud bottom level Pressure [Pa]
PREScclt   0,243,0   0,3,0 ** convective cloud top level Pressure [Pa]
PRESmwl   0,6,0   0,3,0 ** max wind Pressure [Pa]
PREStrop   0,7,0   0,3,0 ** tropopause Pressure [Pa]
PRMSLmsl   0,101,0   0,3,1 ** mean sea level Pressure Reduced to MSL [Pa]
PWATclm   0,200,0   0,1,3 ** entire atmosphere (considered as a single layer) Precipitable Water [kg/m^2]
REFCclm   0,10,0   0,16,196 ** entire atmosphere Composite reflectivity [dB]
RHprs    $nlev,100  0,1,1 ** (1000 975 950 925 900.. 10 7 4 2 1) Relative Humidity [%]
RH2m   0,103,2   0,1,1 ** 2 m above ground Relative Humidity [%]
RHsg330_1000  0,104,0.33,1   0,1,1 ** 0.33-1 sigma layer Relative Humidity [%]
RHsg440_1000  0,104,0.44,1   0,1,1 ** 0.44-1 sigma layer Relative Humidity [%]
RHsg720_940  0,104,0.72,0.94   0,1,1 ** 0.72-0.94 sigma layer Relative Humidity [%]
RHsg440_720  0,104,0.44,0.72   0,1,1 ** 0.44-0.72 sigma layer Relative Humidity [%]
RHsig995   0,104,0.995   0,1,1 ** 0.995 sigma level Relative Humidity [%]
RH30_0mb  0,108,3000,0   0,1,1 ** 30-0 mb above ground Relative Humidity [%]
RHclm   0,200,0   0,1,1 ** entire atmosphere (considered as a single layer) Relative Humidity [%]
RHtop0C   0,204,0   0,1,1 ** highest tropospheric freezing level Relative Humidity [%]
RH0C   0,4,0   0,1,1 ** 0C isotherm Relative Humidity [%]
RWMRprs    $nlev,100  0,1,24 ** (1000 975 950 925 900.. 250 200 150 100 50) Rain Mixing Ratio [kg/kg]
RWMRhy1   0,105,1   0,1,24 ** 1 hybrid level Rain Mixing Ratio [kg/kg]
SHTFLsfc   0,1,0   0,0,11,0 ** surface Sensible Heat Net Flux [W/m^2]
SNMRprs    $nlev,100  0,1,25 ** (1000 975 950 925 900.. 250 200 150 100 50) Snow Mixing Ratio [kg/kg]
SNMRhy1   0,105,1   0,1,25 ** 1 hybrid level Snow Mixing Ratio [kg/kg]
SNODsfc   0,1,0   0,1,11 ** surface Snow Depth [m]
SOILW0_10cm  0,106,0,0.1   2,0,192 ** 0-0.1 m below ground Volumetric Soil Moisture Content [Fraction]
SOILW10_40cm  0,106,0.1,0.4   2,0,192 ** 0.1-0.4 m below ground Volumetric Soil Moisture Content [Fraction]
SOILW40_100cm  0,106,0.4,1   2,0,192 ** 0.4-1 m below ground Volumetric Soil Moisture Content [Fraction]
SOILW100_200cm  0,106,1,2   2,0,192 ** 1-2 m below ground Volumetric Soil Moisture Content [Fraction]
SPFHprs    $nlev,100  0,1,0 ** (1000 975 950 925 900.. 10 7 4 2 1) Specific Humidity [kg/kg]
SPFH2m   0,103,2   0,1,0 ** 2 m above ground Specific Humidity [kg/kg]
SPFH80m   0,103,80   0,1,0 ** 80 m above ground Specific Humidity [kg/kg]
SPFH30_0mb  0,108,3000,0   0,1,0 ** 30-0 mb above ground Specific Humidity [kg/kg]
SUNSDsfc   0,1,0   0,6,201 ** surface Sunshine Duration [s]
TCDCclm   0,10,0   0,6,1,0 ** entire atmosphere Total Cloud Cover [%]
TCDCblcl   0,211,0   0,6,1,0 ** boundary layer cloud layer Total Cloud Cover [%]
TCDClcl   0,214,0   0,6,1,0 ** low cloud layer Total Cloud Cover [%]
TCDCmcl   0,224,0   0,6,1,0 ** middle cloud layer Total Cloud Cover [%]
TCDChcl   0,234,0   0,6,1,0 ** high cloud layer Total Cloud Cover [%]
TCDCprs    $nlev,100  0,6,1 ** (1000 975 950 925 900.. 250 200 150 100 50) Total Cloud Cover [%]
TCDCccl   0,244,0   0,6,1 ** convective cloud layer Total Cloud Cover [%]
TMAX2m   0,103,2   0,0,4,2 ** 2 m above ground Maximum Temperature [K]
TMIN2m   0,103,2   0,0,5,3 ** 2 m above ground Minimum Temperature [K]
TMPlclt   0,213,0   0,0,0,0 ** low cloud top level Temperature [K]
TMPmclt   0,223,0   0,0,0,0 ** middle cloud top level Temperature [K]
TMPhclt   0,233,0   0,0,0,0 ** high cloud top level Temperature [K]
TMPsfc   0,1,0   0,0,0 ** surface Temperature [K]
TMPprs    $nlev,100  0,0,0 ** (1000 975 950 925 900.. 10 7 4 2 1) Temperature [K]
TMP_1829m   0,102,1829   0,0,0 ** 1829 m above mean sea level Temperature [K]
TMP_2743m   0,102,2743   0,0,0 ** 2743 m above mean sea level Temperature [K]
TMP_3658m   0,102,3658   0,0,0 ** 3658 m above mean sea level Temperature [K]
TMP2m   0,103,2   0,0,0 ** 2 m above ground Temperature [K]
TMP80m   0,103,80   0,0,0 ** 80 m above ground Temperature [K]
TMP100m   0,103,100   0,0,0 ** 100 m above ground Temperature [K]
TMPsig995   0,104,0.995   0,0,0 ** 0.995 sigma level Temperature [K]
TMP30_0mb  0,108,3000,0   0,0,0 ** 30-0 mb above ground Temperature [K]
TMP2pv   0,109,2e-06   0,0,0 ** PV=2e-06 (Km^2/kg/s) surface Temperature [K]
TMPneg2pv   0,109,-2e-06   0,0,0 ** PV=-2e-06 (Km^2/kg/s) surface Temperature [K]
TMPmwl   0,6,0   0,0,0 ** max wind Temperature [K]
TMPtrop   0,7,0   0,0,0 ** tropopause Temperature [K]
TOZNEclm   0,200,0   0,14,0 ** entire atmosphere (considered as a single layer) Total Ozone [DU]
TSOIL0_10cm  0,106,0,0.1   2,0,2 ** 0-0.1 m below ground Soil Temperature [K]
TSOIL10_40cm  0,106,0.1,0.4   2,0,2 ** 0.1-0.4 m below ground Soil Temperature [K]
TSOIL40_100cm  0,106,0.4,1   2,0,2 ** 0.4-1 m below ground Soil Temperature [K]
TSOIL100_200cm  0,106,1,2   2,0,2 ** 1-2 m below ground Soil Temperature [K]
UGWDsfc   0,1,0   0,3,194,0 ** surface Zonal Flux of Gravity Wave Stress [N/m^2]
UFLXsfc   0,1,0   0,2,17,0 ** surface Momentum Flux, U-Component [N/m^2]
UGRDprs    $nlev,100  0,2,2 ** (1000 975 950 925 900.. 10 7 4 2 1) U-Component of Wind [m/s]
UGRD_1829m   0,102,1829   0,2,2 ** 1829 m above mean sea level U-Component of Wind [m/s]
UGRD_2743m   0,102,2743   0,2,2 ** 2743 m above mean sea level U-Component of Wind [m/s]
UGRD_3658m   0,102,3658   0,2,2 ** 3658 m above mean sea level U-Component of Wind [m/s]
UGRD10m   0,103,10   0,2,2 ** 10 m above ground U-Component of Wind [m/s]
UGRD20m   0,103,20   0,2,2 ** 20 m above ground U-Component of Wind [m/s]
UGRD30m   0,103,30   0,2,2 ** 30 m above ground U-Component of Wind [m/s]
UGRD40m   0,103,40   0,2,2 ** 40 m above ground U-Component of Wind [m/s]
UGRD50m   0,103,50   0,2,2 ** 50 m above ground U-Component of Wind [m/s]
UGRD80m   0,103,80   0,2,2 ** 80 m above ground U-Component of Wind [m/s]
UGRD100m   0,103,100   0,2,2 ** 100 m above ground U-Component of Wind [m/s]
UGRDsig995   0,104,0.995   0,2,2 ** 0.995 sigma level U-Component of Wind [m/s]
UGRD30_0mb  0,108,3000,0   0,2,2 ** 30-0 mb above ground U-Component of Wind [m/s]
UGRD2pv   0,109,2e-06   0,2,2 ** PV=2e-06 (Km^2/kg/s) surface U-Component of Wind [m/s]
UGRDneg2pv   0,109,-2e-06   0,2,2 ** PV=-2e-06 (Km^2/kg/s) surface U-Component of Wind [m/s]
UGRDpbl   0,220,0   0,2,2 ** planetary boundary layer U-Component of Wind [m/s]
UGRDmwl   0,6,0   0,2,2 ** max wind U-Component of Wind [m/s]
UGRDtrop   0,7,0   0,2,2 ** tropopause U-Component of Wind [m/s]
ULWRFsfc   0,1,0   0,5,193,0 ** surface Upward Long-Wave Rad. Flux [W/m^2]
ULWRFtoa   0,8,0   0,5,193,0 ** top of atmosphere Upward Long-Wave Rad. Flux [W/m^2]
USTM6000_0m  0,103,6000,0   0,2,194 ** 6000-0 m above ground U-Component Storm Motion [m/s]
USWRFsfc   0,1,0   0,4,193,0 ** surface Upward Short-Wave Radiation Flux [W/m^2]
USWRFtoa   0,8,0   0,4,193,0 ** top of atmosphere Upward Short-Wave Radiation Flux [W/m^2]
VGWDsfc   0,1,0   0,3,195,0 ** surface Meridional Flux of Gravity Wave Stress [N/m^2]
VFLXsfc   0,1,0   0,2,18,0 ** surface Momentum Flux, V-Component [N/m^2]
VGRDprs    $nlev,100  0,2,3 ** (1000 975 950 925 900.. 10 7 4 2 1) V-Component of Wind [m/s]
VGRD_1829m   0,102,1829   0,2,3 ** 1829 m above mean sea level V-Component of Wind [m/s]
VGRD_2743m   0,102,2743   0,2,3 ** 2743 m above mean sea level V-Component of Wind [m/s]
VGRD_3658m   0,102,3658   0,2,3 ** 3658 m above mean sea level V-Component of Wind [m/s]
VGRD10m   0,103,10   0,2,3 ** 10 m above ground V-Component of Wind [m/s]
VGRD20m   0,103,20   0,2,3 ** 20 m above ground V-Component of Wind [m/s]
VGRD30m   0,103,30   0,2,3 ** 30 m above ground V-Component of Wind [m/s]
VGRD40m   0,103,40   0,2,3 ** 40 m above ground V-Component of Wind [m/s]
VGRD50m   0,103,50   0,2,3 ** 50 m above ground V-Component of Wind [m/s]
VGRD80m   0,103,80   0,2,3 ** 80 m above ground V-Component of Wind [m/s]
VGRD100m   0,103,100   0,2,3 ** 100 m above ground V-Component of Wind [m/s]
VGRDsig995   0,104,0.995   0,2,3 ** 0.995 sigma level V-Component of Wind [m/s]
VGRD30_0mb  0,108,3000,0   0,2,3 ** 30-0 mb above ground V-Component of Wind [m/s]
VGRD2pv   0,109,2e-06   0,2,3 ** PV=2e-06 (Km^2/kg/s) surface V-Component of Wind [m/s]
VGRDneg2pv   0,109,-2e-06   0,2,3 ** PV=-2e-06 (Km^2/kg/s) surface V-Component of Wind [m/s]
VGRDpbl   0,220,0   0,2,3 ** planetary boundary layer V-Component of Wind [m/s]
VGRDmwl   0,6,0   0,2,3 ** max wind V-Component of Wind [m/s]
VGRDtrop   0,7,0   0,2,3 ** tropopause V-Component of Wind [m/s]
VISsfc   0,1,0   0,19,0 ** surface Visibility [m]
VRATEpbl   0,220,0   0,2,224 ** planetary boundary layer Ventilation Rate [m^2/s]
VSTM6000_0m  0,103,6000,0   0,2,195 ** 6000-0 m above ground V-Component Storm Motion [m/s]
VVELprs    $nlev,100  0,2,8 ** (1000 975 950 925 900.. 300 250 200 150 100) Vertical Velocity (Pressure) [Pa/s]
VVELsig995   0,104,0.995   0,2,8 ** 0.995 sigma level Vertical Velocity (Pressure) [Pa/s]
VWSH2pv   0,109,2e-06   0,2,192 ** PV=2e-06 (Km^2/kg/s) surface Vertical Speed Shear [1/s]
VWSHneg2pv   0,109,-2e-06   0,2,192 ** PV=-2e-06 (Km^2/kg/s) surface Vertical Speed Shear [1/s]
VWSHtrop   0,7,0   0,2,192 ** tropopause Vertical Speed Shear [1/s]
WATRsfc   0,1,0   2,0,5,1 ** surface Water Runoff [kg/m^2]
WEASDsfc   0,1,0   0,1,13 ** surface Water Equivalent of Accumulated Snow Depth [kg/m^2]
WILTsfc   0,1,0   2,0,201 ** surface Wilting Point [Fraction]
ENDVARS
EOF

#----------------
else
#----------------

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

#----------------
fi
#----------------
$grbmap -0 -i $ctldir/${exp}_anl.ctl


#----------------------------------
if [ $gribend = ".grib2" ]; then
#----------------------------------

cat >$ctldir/${exp}_ges.ctl <<EOF
dset ${datadir}/pgbf${guesshr}${dump}%y4%m2%d2%h2.grib2
index $ctldir/${exp}_ges.grib2.idx           
undef 9.999E+20
dtype grib2 
format template
options pascals
xdef $nptx linear 0.000000 $dxy     
ydef $npty linear -90.000000 $dxy 
tdef $ncase linear ${cycg}Z${dayg}${mong}${yearg} ${inchr}hr
zdef $nlev levels ${levlistp}
vars 194
no4LFTXsfc   0,1,0   0,7,193 ** surface Best (4 layer) Lifted Index [K]
no5WAVH500mb   0,100,50000   0,3,193 ** 500 mb 5-Wave Geopotential Height [gpm]
ABSVprs    $nlev,100  0,2,10 ** (1000 975 950 925 900.. 30 20 15 10 40) Absolute Vorticity [1/s]
ACPCPsfc   0,1,0   0,1,10,1 ** surface Convective Precipitation [kg/m^2]
ALBDOsfc   0,1,0   0,19,1,0 ** surface Albedo [%]
APCPsfc   0,1,0   0,1,8,1 ** surface Total Precipitation [kg/m^2]
APTMP2m   0,103,2   0,0,21 ** 2 m above ground Apparent Temperature [K]
CAPEsfc   0,1,0   0,7,6 ** surface Convective Available Potential Energy [J/kg]
CAPE180_0mb  0,108,18000,0   0,7,6 ** 180-0 mb above ground Convective Available Potential Energy [J/kg]
CAPE255_0mb  0,108,25500,0   0,7,6 ** 255-0 mb above ground Convective Available Potential Energy [J/kg]
CFRZRavesfc  0,1,0   0,1,193,0 ** surface Categorical Freezing Rain [-]
CFRZRsfc  0,1,0   0,1,193 ** surface Categorical Freezing Rain [-]
CICEPavesfc  0,1,0   0,1,194,0 ** surface Categorical Ice Pellets [-]
CICEPsfc  0,1,0   0,1,194 ** surface Categorical Ice Pellets [-]
CINsfc   0,1,0   0,7,7 ** surface Convective Inhibition [J/kg]
CIN180_0mb  0,108,18000,0   0,7,7 ** 180-0 mb above ground Convective Inhibition [J/kg]
CIN255_0mb  0,108,25500,0   0,7,7 ** 255-0 mb above ground Convective Inhibition [J/kg]
CLWMRprs    $nlev,100  0,1,22 ** (1000 975 950 925 900.. 250 200 150 100 50) Cloud Mixing Ratio [kg/kg]
CLWMRhy1   0,105,1   0,1,22 ** 1 hybrid level Cloud Mixing Ratio [kg/kg]
CPOFPsfc   0,1,0   0,1,39 ** surface Percent frozen precipitation [%]
CPRATavesfc  0,1,0   0,1,196,0 ** surface Convective Precipitation Rate [kg/m^2/s]
CPRATsfc  0,1,0   0,1,37 ** surface Convective Precipitation Rate [kg/m^2/s]
CRAINavesfc  0,1,0   0,1,192,0 ** surface Categorical Rain [-]
CRAINsfc  0,1,0   0,1,192 ** surface Categorical Rain [-]
CSNOWavesfc  0,1,0   0,1,195,0 ** surface Categorical Snow [-]
CSNOWsfc  0,1,0   0,1,195 ** surface Categorical Snow [-]
CWATclm   0,200,0   0,6,6 ** entire atmosphere (considered as a single layer) Cloud Water [kg/m^2]
CWORKclm   0,200,0   0,6,193,0 ** entire atmosphere (considered as a single layer) Cloud Work Function [J/kg]
DLWRFsfc   0,1,0   0,5,192,0 ** surface Downward Long-Wave Rad. Flux [W/m^2]
DPT2m   0,103,2   0,0,6 ** 2 m above ground Dew Point Temperature [K]
DSWRFsfc   0,1,0   0,4,192,0 ** surface Downward Short-Wave Radiation Flux [W/m^2]
DZDTprs    21,100  0,2,9 ** (1000 975 950 925 900.. 300 250 200 150 100) Vertical Velocity (Geometric) [m/s]
FLDCPsfc   0,1,0   2,3,203 ** surface Field Capacity [Fraction]
GFLUXsfc   0,1,0   2,0,193,0 ** surface Ground Heat Flux [W/m^2]
GRLEprs    $nlev,100  0,1,32 ** (1000 975 950 925 900.. 250 200 150 100 50) Graupel [kg/kg]
GRLEhy1   0,105,1   0,1,32 ** 1 hybrid level Graupel [kg/kg]
GUSTsfc   0,1,0   0,2,22 ** surface Wind Speed (Gust) [m/s]
HGTsfc   0,1,0   0,3,5 ** surface Geopotential Height [gpm]
HGTprs    $nlev,100  0,3,5 ** (1000 975 950 925 900.. 10 7 4 2 1) Geopotential Height [gpm]
HGT2pv   0,109,2e-06   0,3,5 ** PV=2e-06 (Km^2/kg/s) surface Geopotential Height [gpm]
HGTneg2pv   0,109,-2e-06   0,3,5 ** PV=-2e-06 (Km^2/kg/s) surface Geopotential Height [gpm]
HGThtfl   0,204,0   0,3,5 ** highest tropospheric freezing level Geopotential Height [gpm]
HGT0C   0,4,0   0,3,5 ** 0C isotherm Geopotential Height [gpm]
HGTmwl   0,6,0   0,3,5 ** max wind Geopotential Height [gpm]
HGTtrop   0,7,0   0,3,5 ** tropopause Geopotential Height [gpm]
HINDEXsfc   0,1,0   2,4,2 ** surface Haines Index [Numeric]
HLCY3000_0m  0,103,3000,0   0,7,8 ** 3000-0 m above ground Storm Relative Helicity [m^2/s^2]
HPBLsfc   0,1,0   0,3,196 ** surface Planetary Boundary Layer Height [m]
ICAHTmwl   0,6,0   0,3,3 ** max wind ICAO Standard Atmosphere Reference Height [m]
ICAHTtrop   0,7,0   0,3,3 ** tropopause ICAO Standard Atmosphere Reference Height [m]
ICECsfc   0,1,0   10,2,0 ** surface Ice Cover [Proportion]
ICMRprs    $nlev,100  0,1,23 ** (1000 975 950 925 900.. 250 200 150 100 50) Ice Water Mixing Ratio [kg/kg]
ICMRhy1   0,105,1   0,1,23 ** 1 hybrid level Ice Water Mixing Ratio [kg/kg]
ICSEVprs    $nlev,100  0,19,234 ** (1000 950 900 850 800.. 300 250 200 150 100) Icing severity [non-dim]
LANDsfc   0,1,0   2,0,0 ** surface Land Cover (0=sea, 1=land) [Proportion]
LFTXsfc   0,1,0   0,7,192 ** surface Surface Lifted Index [K]
LHTFLsfc   0,1,0   0,0,10,0 ** surface Latent Heat Net Flux [W/m^2]
MSLETmsl   0,101,0   0,3,192 ** mean sea level MSLP (Eta model reduction) [Pa]
O3MRprs    $nlev,100  0,14,192 ** (1000 850 700 500 400.. 5 3 2 1 40) Ozone Mixing Ratio [kg/kg]
PEVPRsfc   0,1,0   0,1,200 ** surface Potential Evaporation Rate [W/m^2]
PLPL255_0mb  0,108,25500,0   0,3,200 ** 255-0 mb above ground Pressure of level from which parcel was lifted [Pa]
POTsig995   0,104,0.995   0,0,2 ** 0.995 sigma level Potential Temperature [K]
PRATEavesfc  0,1,0   0,1,7,0 ** surface Precipitation Rate [kg/m^2/s]
PRATEsfc  0,1,0   0,1,7 ** surface Precipitation Rate [kg/m^2/s]
PRESlclb   0,212,0   0,3,0,0 ** low cloud bottom level Pressure [Pa]
PRESlclt   0,213,0   0,3,0,0 ** low cloud top level Pressure [Pa]
PRESmclb   0,222,0   0,3,0,0 ** middle cloud bottom level Pressure [Pa]
PRESmclt   0,223,0   0,3,0,0 ** middle cloud top level Pressure [Pa]
PREShclb   0,232,0   0,3,0,0 ** high cloud bottom level Pressure [Pa]
PREShclt   0,233,0   0,3,0,0 ** high cloud top level Pressure [Pa]
PRESsfc   0,1,0   0,3,0 ** surface Pressure [Pa]
PRES80m   0,103,80   0,3,0 ** 80 m above ground Pressure [Pa]
PRES2pv   0,109,2e-06   0,3,0 ** PV=2e-06 (Km^2/kg/s) surface Pressure [Pa]
PRESneg2pv   0,109,-2e-06   0,3,0 ** PV=-2e-06 (Km^2/kg/s) surface Pressure [Pa]
PREScclb   0,242,0   0,3,0 ** convective cloud bottom level Pressure [Pa]
PREScclt   0,243,0   0,3,0 ** convective cloud top level Pressure [Pa]
PRESmwl   0,6,0   0,3,0 ** max wind Pressure [Pa]
PREStrop   0,7,0   0,3,0 ** tropopause Pressure [Pa]
PRMSLmsl   0,101,0   0,3,1 ** mean sea level Pressure Reduced to MSL [Pa]
PWATclm   0,200,0   0,1,3 ** entire atmosphere (considered as a single layer) Precipitable Water [kg/m^2]
REFCclm   0,10,0   0,16,196 ** entire atmosphere Composite reflectivity [dB]
RHprs    $nlev,100  0,1,1 ** (1000 975 950 925 900.. 10 7 4 2 1) Relative Humidity [%]
RH2m   0,103,2   0,1,1 ** 2 m above ground Relative Humidity [%]
RHsg330_1000  0,104,0.33,1   0,1,1 ** 0.33-1 sigma layer Relative Humidity [%]
RHsg440_1000  0,104,0.44,1   0,1,1 ** 0.44-1 sigma layer Relative Humidity [%]
RHsg720_940  0,104,0.72,0.94   0,1,1 ** 0.72-0.94 sigma layer Relative Humidity [%]
RHsg440_720  0,104,0.44,0.72   0,1,1 ** 0.44-0.72 sigma layer Relative Humidity [%]
RHsig995   0,104,0.995   0,1,1 ** 0.995 sigma level Relative Humidity [%]
RH30_0mb  0,108,3000,0   0,1,1 ** 30-0 mb above ground Relative Humidity [%]
RHclm   0,200,0   0,1,1 ** entire atmosphere (considered as a single layer) Relative Humidity [%]
RHtop0C   0,204,0   0,1,1 ** highest tropospheric freezing level Relative Humidity [%]
RH0C   0,4,0   0,1,1 ** 0C isotherm Relative Humidity [%]
RWMRprs    $nlev,100  0,1,24 ** (1000 975 950 925 900.. 250 200 150 100 50) Rain Mixing Ratio [kg/kg]
RWMRhy1   0,105,1   0,1,24 ** 1 hybrid level Rain Mixing Ratio [kg/kg]
SHTFLsfc   0,1,0   0,0,11,0 ** surface Sensible Heat Net Flux [W/m^2]
SNMRprs    $nlev,100  0,1,25 ** (1000 975 950 925 900.. 250 200 150 100 50) Snow Mixing Ratio [kg/kg]
SNMRhy1   0,105,1   0,1,25 ** 1 hybrid level Snow Mixing Ratio [kg/kg]
SNODsfc   0,1,0   0,1,11 ** surface Snow Depth [m]
SOILW0_10cm  0,106,0,0.1   2,0,192 ** 0-0.1 m below ground Volumetric Soil Moisture Content [Fraction]
SOILW10_40cm  0,106,0.1,0.4   2,0,192 ** 0.1-0.4 m below ground Volumetric Soil Moisture Content [Fraction]
SOILW40_100cm  0,106,0.4,1   2,0,192 ** 0.4-1 m below ground Volumetric Soil Moisture Content [Fraction]
SOILW100_200cm  0,106,1,2   2,0,192 ** 1-2 m below ground Volumetric Soil Moisture Content [Fraction]
SPFHprs    $nlev,100  0,1,0 ** (1000 975 950 925 900.. 10 7 4 2 1) Specific Humidity [kg/kg]
SPFH2m   0,103,2   0,1,0 ** 2 m above ground Specific Humidity [kg/kg]
SPFH80m   0,103,80   0,1,0 ** 80 m above ground Specific Humidity [kg/kg]
SPFH30_0mb  0,108,3000,0   0,1,0 ** 30-0 mb above ground Specific Humidity [kg/kg]
SUNSDsfc   0,1,0   0,6,201 ** surface Sunshine Duration [s]
TCDCclm   0,10,0   0,6,1,0 ** entire atmosphere Total Cloud Cover [%]
TCDCblcl   0,211,0   0,6,1,0 ** boundary layer cloud layer Total Cloud Cover [%]
TCDClcl   0,214,0   0,6,1,0 ** low cloud layer Total Cloud Cover [%]
TCDCmcl   0,224,0   0,6,1,0 ** middle cloud layer Total Cloud Cover [%]
TCDChcl   0,234,0   0,6,1,0 ** high cloud layer Total Cloud Cover [%]
TCDCprs    $nlev,100  0,6,1 ** (1000 975 950 925 900.. 250 200 150 100 50) Total Cloud Cover [%]
TCDCccl   0,244,0   0,6,1 ** convective cloud layer Total Cloud Cover [%]
TMAX2m   0,103,2   0,0,4,2 ** 2 m above ground Maximum Temperature [K]
TMIN2m   0,103,2   0,0,5,3 ** 2 m above ground Minimum Temperature [K]
TMPlclt   0,213,0   0,0,0,0 ** low cloud top level Temperature [K]
TMPmclt   0,223,0   0,0,0,0 ** middle cloud top level Temperature [K]
TMPhclt   0,233,0   0,0,0,0 ** high cloud top level Temperature [K]
TMPsfc   0,1,0   0,0,0 ** surface Temperature [K]
TMPprs    $nlev,100  0,0,0 ** (1000 975 950 925 900.. 10 7 4 2 1) Temperature [K]
TMP_1829m   0,102,1829   0,0,0 ** 1829 m above mean sea level Temperature [K]
TMP_2743m   0,102,2743   0,0,0 ** 2743 m above mean sea level Temperature [K]
TMP_3658m   0,102,3658   0,0,0 ** 3658 m above mean sea level Temperature [K]
TMP2m   0,103,2   0,0,0 ** 2 m above ground Temperature [K]
TMP80m   0,103,80   0,0,0 ** 80 m above ground Temperature [K]
TMP100m   0,103,100   0,0,0 ** 100 m above ground Temperature [K]
TMPsig995   0,104,0.995   0,0,0 ** 0.995 sigma level Temperature [K]
TMP30_0mb  0,108,3000,0   0,0,0 ** 30-0 mb above ground Temperature [K]
TMP2pv   0,109,2e-06   0,0,0 ** PV=2e-06 (Km^2/kg/s) surface Temperature [K]
TMPneg2pv   0,109,-2e-06   0,0,0 ** PV=-2e-06 (Km^2/kg/s) surface Temperature [K]
TMPmwl   0,6,0   0,0,0 ** max wind Temperature [K]
TMPtrop   0,7,0   0,0,0 ** tropopause Temperature [K]
TOZNEclm   0,200,0   0,14,0 ** entire atmosphere (considered as a single layer) Total Ozone [DU]
TSOIL0_10cm  0,106,0,0.1   2,0,2 ** 0-0.1 m below ground Soil Temperature [K]
TSOIL10_40cm  0,106,0.1,0.4   2,0,2 ** 0.1-0.4 m below ground Soil Temperature [K]
TSOIL40_100cm  0,106,0.4,1   2,0,2 ** 0.4-1 m below ground Soil Temperature [K]
TSOIL100_200cm  0,106,1,2   2,0,2 ** 1-2 m below ground Soil Temperature [K]
UGWDsfc   0,1,0   0,3,194,0 ** surface Zonal Flux of Gravity Wave Stress [N/m^2]
UFLXsfc   0,1,0   0,2,17,0 ** surface Momentum Flux, U-Component [N/m^2]
UGRDprs    $nlev,100  0,2,2 ** (1000 975 950 925 900.. 10 7 4 2 1) U-Component of Wind [m/s]
UGRD_1829m   0,102,1829   0,2,2 ** 1829 m above mean sea level U-Component of Wind [m/s]
UGRD_2743m   0,102,2743   0,2,2 ** 2743 m above mean sea level U-Component of Wind [m/s]
UGRD_3658m   0,102,3658   0,2,2 ** 3658 m above mean sea level U-Component of Wind [m/s]
UGRD10m   0,103,10   0,2,2 ** 10 m above ground U-Component of Wind [m/s]
UGRD20m   0,103,20   0,2,2 ** 20 m above ground U-Component of Wind [m/s]
UGRD30m   0,103,30   0,2,2 ** 30 m above ground U-Component of Wind [m/s]
UGRD40m   0,103,40   0,2,2 ** 40 m above ground U-Component of Wind [m/s]
UGRD50m   0,103,50   0,2,2 ** 50 m above ground U-Component of Wind [m/s]
UGRD80m   0,103,80   0,2,2 ** 80 m above ground U-Component of Wind [m/s]
UGRD100m   0,103,100   0,2,2 ** 100 m above ground U-Component of Wind [m/s]
UGRDsig995   0,104,0.995   0,2,2 ** 0.995 sigma level U-Component of Wind [m/s]
UGRD30_0mb  0,108,3000,0   0,2,2 ** 30-0 mb above ground U-Component of Wind [m/s]
UGRD2pv   0,109,2e-06   0,2,2 ** PV=2e-06 (Km^2/kg/s) surface U-Component of Wind [m/s]
UGRDneg2pv   0,109,-2e-06   0,2,2 ** PV=-2e-06 (Km^2/kg/s) surface U-Component of Wind [m/s]
UGRDpbl   0,220,0   0,2,2 ** planetary boundary layer U-Component of Wind [m/s]
UGRDmwl   0,6,0   0,2,2 ** max wind U-Component of Wind [m/s]
UGRDtrop   0,7,0   0,2,2 ** tropopause U-Component of Wind [m/s]
ULWRFsfc   0,1,0   0,5,193,0 ** surface Upward Long-Wave Rad. Flux [W/m^2]
ULWRFtoa   0,8,0   0,5,193,0 ** top of atmosphere Upward Long-Wave Rad. Flux [W/m^2]
USTM6000_0m  0,103,6000,0   0,2,194 ** 6000-0 m above ground U-Component Storm Motion [m/s]
USWRFsfc   0,1,0   0,4,193,0 ** surface Upward Short-Wave Radiation Flux [W/m^2]
USWRFtoa   0,8,0   0,4,193,0 ** top of atmosphere Upward Short-Wave Radiation Flux [W/m^2]
VGWDsfc   0,1,0   0,3,195,0 ** surface Meridional Flux of Gravity Wave Stress [N/m^2]
VFLXsfc   0,1,0   0,2,18,0 ** surface Momentum Flux, V-Component [N/m^2]
VGRDprs    $nlev,100  0,2,3 ** (1000 975 950 925 900.. 10 7 4 2 1) V-Component of Wind [m/s]
VGRD_1829m   0,102,1829   0,2,3 ** 1829 m above mean sea level V-Component of Wind [m/s]
VGRD_2743m   0,102,2743   0,2,3 ** 2743 m above mean sea level V-Component of Wind [m/s]
VGRD_3658m   0,102,3658   0,2,3 ** 3658 m above mean sea level V-Component of Wind [m/s]
VGRD10m   0,103,10   0,2,3 ** 10 m above ground V-Component of Wind [m/s]
VGRD20m   0,103,20   0,2,3 ** 20 m above ground V-Component of Wind [m/s]
VGRD30m   0,103,30   0,2,3 ** 30 m above ground V-Component of Wind [m/s]
VGRD40m   0,103,40   0,2,3 ** 40 m above ground V-Component of Wind [m/s]
VGRD50m   0,103,50   0,2,3 ** 50 m above ground V-Component of Wind [m/s]
VGRD80m   0,103,80   0,2,3 ** 80 m above ground V-Component of Wind [m/s]
VGRD100m   0,103,100   0,2,3 ** 100 m above ground V-Component of Wind [m/s]
VGRDsig995   0,104,0.995   0,2,3 ** 0.995 sigma level V-Component of Wind [m/s]
VGRD30_0mb  0,108,3000,0   0,2,3 ** 30-0 mb above ground V-Component of Wind [m/s]
VGRD2pv   0,109,2e-06   0,2,3 ** PV=2e-06 (Km^2/kg/s) surface V-Component of Wind [m/s]
VGRDneg2pv   0,109,-2e-06   0,2,3 ** PV=-2e-06 (Km^2/kg/s) surface V-Component of Wind [m/s]
VGRDpbl   0,220,0   0,2,3 ** planetary boundary layer V-Component of Wind [m/s]
VGRDmwl   0,6,0   0,2,3 ** max wind V-Component of Wind [m/s]
VGRDtrop   0,7,0   0,2,3 ** tropopause V-Component of Wind [m/s]
VISsfc   0,1,0   0,19,0 ** surface Visibility [m]
VRATEpbl   0,220,0   0,2,224 ** planetary boundary layer Ventilation Rate [m^2/s]
VSTM6000_0m  0,103,6000,0   0,2,195 ** 6000-0 m above ground V-Component Storm Motion [m/s]
VVELprs    $nlev,100  0,2,8 ** (1000 975 950 925 900.. 300 250 200 150 100) Vertical Velocity (Pressure) [Pa/s]
VVELsig995   0,104,0.995   0,2,8 ** 0.995 sigma level Vertical Velocity (Pressure) [Pa/s]
VWSH2pv   0,109,2e-06   0,2,192 ** PV=2e-06 (Km^2/kg/s) surface Vertical Speed Shear [1/s]
VWSHneg2pv   0,109,-2e-06   0,2,192 ** PV=-2e-06 (Km^2/kg/s) surface Vertical Speed Shear [1/s]
VWSHtrop   0,7,0   0,2,192 ** tropopause Vertical Speed Shear [1/s]
WATRsfc   0,1,0   2,0,5,1 ** surface Water Runoff [kg/m^2]
WEASDsfc   0,1,0   0,1,13 ** surface Water Equivalent of Accumulated Snow Depth [kg/m^2]
WILTsfc   0,1,0   2,0,201 ** surface Wilting Point [Fraction]
ENDVARS
EOF

#------------
else
#------------


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
#---------------
fi
#---------------

$grbmap -0 -i $ctldir/${exp}_ges.ctl   

#-----------------------------------
n=`expr $n + 1 `
done  ;# exp
#-----------------------------------

exit
