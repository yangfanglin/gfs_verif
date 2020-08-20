#!/bin/ksh
set -x
curdir=`pwd`

export expnlist=${expnlist:-"gfs gfs2016"}     ;#experiment names
export expdlist=${expdlist:-"/global/noscrub/emc.glopara/global /global/noscrub/emc.glopara/archive"}  
export dumplist=${dumplist:-".gfs. .gfs."}    ;#file format pgb${asub}${fhr}${dump}${yyyymmdd}${cyc}
export complist=${complist:-"tide tide"}      ;#computers where experiments are run

export fcst_day=${fcst_day:-2}                ;#forecast day to verify
export cyc=${cyc:-00}                         ;#forecast cycle to verify
export cdate=${cdate:-20161101}               ;#starting verifying date
export ndays=${ndays:-10}                     ;#number of days (cases)
export nlev=${nlev:-26}                       ;#pgb file vertical layers
export grid=${grid:-G2}                       ;#pgb file resolution, G2->2.5deg; G3->1deg; G4->0.5deg; G193->0.25deg

export vsdbhome=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}
export gstat=${gstat:-/global/noscrub/emc.glopara/global}     
export APRUN=${APRUN:-""}   ;#for running jobs on Gaea
export machine=${machine:-WCOSS}     
export NWPROD=${NWPROD:-/nwprod}     
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export cpygb=${cpygb:-"$APRUN $NWPROD/util/exec/copygb"}
export cpygb2=${cpygb2:-"$APRUN $NWPROD/util/exec/copygb2"}
export wgrb=${wgrib:-$NWPROD/util/exec/wgrib}
export wgrb2=${wgrib2:-$NWPROD/util/exec/wgrib2}
#---------------------------------------------------------------------------------
if [ "$fhlist" = '' ] ; then
fhr4=`expr $fcst_day \* 24 `
fhr3=`expr $fhr4 - 6  `
fhr2=`expr $fhr4 - 12  `
fhr1=`expr $fhr4 - 18  `
if [ $fhr1 -lt 10 ]; then fhr1=0$fhr1; fi
export fhlist="f$fhr1 f$fhr2 f$fhr3 f$fhr4"    ;#fcst hours to be analyzed
fi


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

export rundir=${rundir:-/ptmpd2/$LOGNAME/2dmaps} 
export ctldir0=${ctldir:-$rundir/ctl}
mkdir -p $rundir $ctldir0

set -A expdname $expdlist
set -A compname $complist
set -A dumpname $dumplist
cd ${rundir} || exit 8

#------------------------------
n=0
for exp in $expnlist; do
#------------------------------

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


export dump=${dumpname[n]}
expdir=${expdname[n]}
CLIENT=${compname[n]}
myhost=`echo $(hostname) |cut -c 1-1 `
myclient=`echo $CLIENT |cut -c 1-1 `
ncepcmp=`echo $machine |cut -c 1-5`


set -A mlist none Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
year=`echo $cdate |cut -c 1-4`
mon=`echo $cdate |cut -c 5-6`
day=`echo $cdate |cut -c 7-8`
monc=${mlist[$mon]}

export datadir=$rundir/$exp/d${fcst_day}                  
export ctldir=$ctldir0/$exp
mkdir -p $ctldir $datadir

nhours=`expr $ndays \* 24 `
sdate=${cdate}${cyc}
edate=`$ndate +$nhours $sdate`
testfile_type=${testfile_type:-pgbf24}

#------------------------------
while [ $sdate -le $edate ]; do
testa=${expdir}/${exp}/${testfile_type}${dump}${sdate}
testb=${expdir}/${exp}/${testfile_type}${dump}${sdate}.grib2
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


 hrold=f9999
 for hr in $fhlist; do
   if [ $hr != $hrold ]; then
    filein=${expdir}/${exp}/pgb${hr}${dump}${sdate}${gribend}
    fileout=${datadir}/pgb${hr}${dump}${sdate}${gribend}
    if [ -s $filein  ]; then
      if [ $docpygb = NO ]; then
        ln -fs $filein $fileout
      else
        if [ $gribend = ".grib2" ]; then
          $cpygb2 -g "${gridout}" -x $filein $fileout
        else
          ${cpygb} -g$GG -x $filein $fileout
        fi
      fi
    else
      echo "$filetmp does not exist !"
    fi
    hrold=$hr
  fi
 done

#--------------------------
fi
sdate=`$ndate +24 $sdate`
done
#--------------------------


#--------------------------
for hr in $fhlist; do
hrold=f9999
if [ $hr != $hrold ]; then
#--------------------------
rm $ctldir/${exp}_${hr}.ctl $ctldir/${exp}.t${cyc}z.pgrb${hr}.idx

#----------------------------------
if [ $gribend = ".grib2" ]; then
#----------------------------------
cat >$ctldir/${exp}_$hr.ctl <<EOF
dset ${datadir}/pgb${hr}${dump}%y4%m2%d2${cyc}.grib2
index $ctldir/${exp}.t${cyc}z.pgrb${hr}.grib2.idx
undef 9.999E+20
title ${exp}.t${cyc}z.pgrb${hr}.grib2
dtype grib2
format template
options pascals
xdef $nptx linear 0.000000 $dxy     
ydef $npty linear -90.000000 $dxy 
tdef $ndays linear ${cyc}Z${day}${monc}${year} 1dy
zdef $nlev levels ${levlistp}
vars 203
no4LFTXsfc   0,1,0   0,7,193 ** surface Best (4 layer) Lifted Index [K]
ABSVprs    $nlev ,100  0,2,10 ** (1000 975 950 925 900.. 30 20 15 10 40) Absolute Vorticity [1/s]
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
CLWMRprs    $nlev ,100  0,1,22 ** (1000 975 950 925 900.. 250 200 150 100 50) Cloud Mixing Ratio [kg/kg]
CLWMRhy1   0,105,1   0,1,22 ** 1 hybrid level Cloud Mixing Ratio [kg/kg]
CNWATsfc   0,1,0   2,0,196 ** surface Plant Canopy Surface Water [kg/m^2]
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
DZDTprs    $nlev ,100  0,2,9 ** (1000 975 950 925 900.. 10 7 4 2 1) Vertical Velocity (Geometric) [m/s]
FLDCPsfc   0,1,0   2,3,203 ** surface Field Capacity [Fraction]
FRICVsfc   0,1,0   0,2,197 ** surface Frictional Velocity [m/s]
GFLUXsfc   0,1,0   2,0,193,0 ** surface Ground Heat Flux [W/m^2]
GRLEprs    $nlev ,100  0,1,32 ** (1000 975 950 925 900.. 250 200 150 100 50) Graupel [kg/kg]
GRLEhy1   0,105,1   0,1,32 ** 1 hybrid level Graupel [kg/kg]
GUSTsfc   0,1,0   0,2,22 ** surface Wind Speed (Gust) [m/s]
HGTsfc   0,1,0   0,3,5 ** surface Geopotential Height [gpm]
HGTprs    $nlev ,100  0,3,5 ** (1000 975 950 925 900.. 10 7 4 2 1) Geopotential Height [gpm]
HGT2pv   0,109,2e-06   0,3,5 ** PV=2e-06 (Km^2/kg/s) surface Geopotential Height [gpm]
HGTneg2pv   0,109,-2e-06   0,3,5 ** PV=-2e-06 (Km^2/kg/s) surface Geopotential Height [gpm]
HGTtop0deg   0,204,0   0,3,5 ** highest tropospheric freezing level Geopotential Height [gpm]
HGT0deg   0,4,0   0,3,5 ** 0C isotherm Geopotential Height [gpm]
HGTmwl   0,6,0   0,3,5 ** max wind Geopotential Height [gpm]
HGTtrp   0,7,0   0,3,5 ** tropopause Geopotential Height [gpm]
HINDEXsfc   0,1,0   2,4,2 ** surface Haines Index [Numeric]
HLCY0_3000m  0,103,3000,0   0,7,8 ** 3000-0 m above ground Storm Relative Helicity [m^2/s^2]
HPBLsfc   0,1,0   0,3,196 ** surface Planetary Boundary Layer Height [m]
ICAHTmwl   0,6,0   0,3,3 ** max wind ICAO Standard Atmosphere Reference Height [m]
ICAHTtrp   0,7,0   0,3,3 ** tropopause ICAO Standard Atmosphere Reference Height [m]
ICECsfc   0,1,0   10,2,0 ** surface Ice Cover [Proportion]
ICEG_10m   0,102,10   10,2,6 ** 10 m above mean sea level Ice Growth Rate [m/s]
ICETKsfc   0,1,0   10,2,1 ** surface Ice Thickness [m]
ICETMPsfc   0,1,0   10,2,8 ** surface Ice Temperature [K]
ICMRprs    $nlev ,100  0,1,23 ** (1000 975 950 925 900.. 250 200 150 100 50) Ice Water Mixing Ratio [kg/kg]
ICMRhy1   0,105,1   0,1,23 ** 1 hybrid level Ice Water Mixing Ratio [kg/kg]
LANDsfc   0,1,0   2,0,0 ** surface Land Cover (0=sea, 1=land) [Proportion]
LFTXsfc   0,1,0   0,7,192 ** surface Surface Lifted Index [K]
LHTFLsfc   0,1,0   0,0,10,0 ** surface Latent Heat Net Flux [W/m^2]
MSLETmsl   0,101,0   0,3,192 ** mean sea level MSLP (Eta model reduction) [Pa]
O3MRprs    $nlev ,100  0,14,192 ** (1000 850 700 500 400.. 10 7 4 2 1) Ozone Mixing Ratio [kg/kg]
PEVPRsfc   0,1,0   0,1,200 ** surface Potential Evaporation Rate [W/m^2]
PLPL255_0mb  0,108,25500,0   0,3,200 ** 255-0 mb above ground Pressure of level from which parcel was lifted [Pa]
POTsig995   0,104,0.995   0,0,2 ** 0.995 sigma level Potential Temperature [K]
PRATEavesfc  0,1,0   0,1,7,0 ** surface Precipitation Rate [kg/m^2/s]
PRATEsfc  0,1,0   0,1,7 ** surface Precipitation Rate [kg/m^2/s]
PRESlcb   0,212,0   0,3,0,0 ** low cloud bottom level Pressure [Pa]
PRESlct   0,213,0   0,3,0,0 ** low cloud top level Pressure [Pa]
PRESmcb   0,222,0   0,3,0,0 ** middle cloud bottom level Pressure [Pa]
PRESmct   0,223,0   0,3,0,0 ** middle cloud top level Pressure [Pa]
PREShcb   0,232,0   0,3,0,0 ** high cloud bottom level Pressure [Pa]
PREShct   0,233,0   0,3,0,0 ** high cloud top level Pressure [Pa]
PRESsfc   0,1,0   0,3,0 ** surface Pressure [Pa]
PRES80m   0,103,80   0,3,0 ** 80 m above ground Pressure [Pa]
PRES2pv   0,109,2e-06   0,3,0 ** PV=2e-06 (Km^2/kg/s) surface Pressure [Pa]
PRESneg2pv   0,109,-2e-06   0,3,0 ** PV=-2e-06 (Km^2/kg/s) surface Pressure [Pa]
PREScvb   0,242,0   0,3,0 ** convective cloud bottom level Pressure [Pa]
PREScvt   0,243,0   0,3,0 ** convective cloud top level Pressure [Pa]
PRESmwl   0,6,0   0,3,0 ** max wind Pressure [Pa]
PREStrp   0,7,0   0,3,0 ** tropopause Pressure [Pa]
PRMSLmsl   0,101,0   0,3,1 ** mean sea level Pressure Reduced to MSL [Pa]
PWATclm   0,200,0   0,1,3 ** entire atmosphere (considered as a single layer) Precipitable Water [kg/m^2]
REFCclm   0,10,0   0,16,196 ** entire atmosphere Composite reflectivity [dB]
RHprs    $nlev ,100  0,1,1 ** (1000 975 950 925 900.. 10 7 4 2 1) Relative Humidity [%]
RH2m   0,103,2   0,1,1 ** 2 m above ground Relative Humidity [%]
RHsg330_1000  0,104,0.33,1   0,1,1 ** 0.33-1 sigma layer Relative Humidity [%]
RHsg440_1000  0,104,0.44,1   0,1,1 ** 0.44-1 sigma layer Relative Humidity [%]
RHsg720_940  0,104,0.72,0.94   0,1,1 ** 0.72-0.94 sigma layer Relative Humidity [%]
RHsg440_720  0,104,0.44,0.72   0,1,1 ** 0.44-0.72 sigma layer Relative Humidity [%]
RHsig995   0,104,0.995   0,1,1 ** 0.995 sigma level Relative Humidity [%]
RH30_0mb  0,108,3000,0   0,1,1 ** 30-0 mb above ground Relative Humidity [%]
RHclm   0,200,0   0,1,1 ** entire atmosphere (considered as a single layer) Relative Humidity [%]
RHtop0deg   0,204,0   0,1,1 ** highest tropospheric freezing level Relative Humidity [%]
RH0deg   0,4,0   0,1,1 ** 0C isotherm Relative Humidity [%]
RWMRprs    $nlev ,100  0,1,24 ** (1000 975 950 925 900.. 250 200 150 100 50) Rain Mixing Ratio [kg/kg]
RWMRhy1   0,105,1   0,1,24 ** 1 hybrid level Rain Mixing Ratio [kg/kg]
SFCRsfc   0,1,0   2,0,1 ** surface Surface Roughness [m]
SHTFLsfc   0,1,0   0,0,11,0 ** surface Sensible Heat Net Flux [W/m^2]
SNMRprs    $nlev ,100  0,1,25 ** (1000 975 950 925 900.. 250 200 150 100 50) Snow Mixing Ratio [kg/kg]
SNMRhy1   0,105,1   0,1,25 ** 1 hybrid level Snow Mixing Ratio [kg/kg]
SNODsfc   0,1,0   0,1,11 ** surface Snow Depth [m]
SOILL0_10cm  0,106,0,0.1   2,3,192 ** 0-0.1 m below ground Liquid Volumetric Soil Moisture (non Frozen) [Proportion]
SOILL10_40cm  0,106,0.1,0.4   2,3,192 ** 0.1-0.4 m below ground Liquid Volumetric Soil Moisture (non Frozen) [Proportion]
SOILL40_100cm  0,106,0.4,1   2,3,192 ** 0.4-1 m below ground Liquid Volumetric Soil Moisture (non Frozen) [Proportion]
SOILL100_200cm  0,106,1,2   2,3,192 ** 1-2 m below ground Liquid Volumetric Soil Moisture (non Frozen) [Proportion]
SOILW0_10cm  0,106,0,0.1   2,0,192 ** 0-0.1 m below ground Volumetric Soil Moisture Content [Fraction]
SOILW10_40cm  0,106,0.1,0.4   2,0,192 ** 0.1-0.4 m below ground Volumetric Soil Moisture Content [Fraction]
SOILW40_100cm  0,106,0.4,1   2,0,192 ** 0.4-1 m below ground Volumetric Soil Moisture Content [Fraction]
SOILW100_200cm  0,106,1,2   2,0,192 ** 1-2 m below ground Volumetric Soil Moisture Content [Fraction]
SOTYPsfc   0,1,0   2,3,0 ** surface Soil Type [-]
SPFH2m   0,103,2   0,1,0 ** 2 m above ground Specific Humidity [kg/kg]
SPFH80m   0,103,80   0,1,0 ** 80 m above ground Specific Humidity [kg/kg]
SPFH30_0mb  0,108,3000,0   0,1,0 ** 30-0 mb above ground Specific Humidity [kg/kg]
SUNSDsfc   0,1,0   0,6,201 ** surface Sunshine Duration [s]
TCDCclm   0,10,0   0,6,1,0 ** entire atmosphere Total Cloud Cover [%]
TCDCblcl   0,211,0   0,6,1,0 ** boundary layer cloud layer Total Cloud Cover [%]
TCDClcl   0,214,0   0,6,1,0 ** low cloud layer Total Cloud Cover [%]
TCDCmcl   0,224,0   0,6,1,0 ** middle cloud layer Total Cloud Cover [%]
TCDChcl   0,234,0   0,6,1,0 ** high cloud layer Total Cloud Cover [%]
TCDCprs    $nlev ,100  0,6,1 ** (1000 975 950 925 900.. 250 200 150 100 50) Total Cloud Cover [%]
TCDCcvl   0,244,0   0,6,1 ** convective cloud layer Total Cloud Cover [%]
TMAX2m   0,103,2   0,0,4,2 ** 2 m above ground Maximum Temperature [K]
TMIN2m   0,103,2   0,0,5,3 ** 2 m above ground Minimum Temperature [K]
TMPlct   0,213,0   0,0,0,0 ** low cloud top level Temperature [K]
TMPmct   0,223,0   0,0,0,0 ** middle cloud top level Temperature [K]
TMPhct   0,233,0   0,0,0,0 ** high cloud top level Temperature [K]
TMPsfc   0,1,0   0,0,0 ** surface Temperature [K]
TMPprs    $nlev ,100  0,0,0 ** (1000 975 950 925 900.. 10 7 4 2 1) Temperature [K]
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
TMPtrp   0,7,0   0,0,0 ** tropopause Temperature [K]
TOZNEclm   0,200,0   0,14,0 ** entire atmosphere (considered as a single layer) Total Ozone [DU]
TSOIL0_10cm  0,106,0,0.1   2,0,2 ** 0-0.1 m below ground Soil Temperature [K]
TSOIL10_40cm  0,106,0.1,0.4   2,0,2 ** 0.1-0.4 m below ground Soil Temperature [K]
TSOIL40_100cm  0,106,0.4,1   2,0,2 ** 0.4-1 m below ground Soil Temperature [K]
TSOIL100_200cm  0,106,1,2   2,0,2 ** 1-2 m below ground Soil Temperature [K]
UGWDsfc   0,1,0   0,3,194,0 ** surface Zonal Flux of Gravity Wave Stress [N/m^2]
UFLXsfc   0,1,0   0,2,17,0 ** surface Momentum Flux, U-Component [N/m^2]
UGRDprs    $nlev ,100  0,2,2 ** (1000 975 950 925 900.. 10 7 4 2 1) U-Component of Wind [m/s]
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
UGRDtrp   0,7,0   0,2,2 ** tropopause U-Component of Wind [m/s]
ULWRFsfc   0,1,0   0,5,193,0 ** surface Upward Long-Wave Rad. Flux [W/m^2]
ULWRFtoa   0,8,0   0,5,193,0 ** top of atmosphere Upward Long-Wave Rad. Flux [W/m^2]
USTM0_6000m  0,103,6000,0   0,2,194 ** 6000-0 m above ground U-Component Storm Motion [m/s]
USWRFsfc   0,1,0   0,4,193,0 ** surface Upward Short-Wave Radiation Flux [W/m^2]
USWRFtoa   0,8,0   0,4,193,0 ** top of atmosphere Upward Short-Wave Radiation Flux [W/m^2]
VGWDsfc   0,1,0   0,3,195,0 ** surface Meridional Flux of Gravity Wave Stress [N/m^2]
VEGsfc   0,1,0   2,0,4 ** surface Vegetation [%]
VFLXsfc   0,1,0   0,2,18,0 ** surface Momentum Flux, V-Component [N/m^2]
VGRDprs    $nlev ,100  0,2,3 ** (1000 975 950 925 900.. 10 7 4 2 1) V-Component of Wind [m/s]
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
VGRDtrp   0,7,0   0,2,3 ** tropopause V-Component of Wind [m/s]
VISsfc   0,1,0   0,19,0 ** surface Visibility [m]
VRATEpbl   0,220,0   0,2,224 ** planetary boundary layer Ventilation Rate [m^2/s]
VSTM0_6000m  0,103,6000,0   0,2,195 ** 6000-0 m above ground V-Component Storm Motion [m/s]
VVELprs    $nlev ,100  0,2,8 ** (1000 975 950 925 900.. 10 7 4 2 1) Vertical Velocity (Pressure) [Pa/s]
VVELsig995   0,104,0.995   0,2,8 ** 0.995 sigma level Vertical Velocity (Pressure) [Pa/s]
VWSH2pv   0,109,2e-06   0,2,192 ** PV=2e-06 (Km^2/kg/s) surface Vertical Speed Shear [1/s]
VWSHneg2pv   0,109,-2e-06   0,2,192 ** PV=-2e-06 (Km^2/kg/s) surface Vertical Speed Shear [1/s]
VWSHtrp   0,7,0   0,2,192 ** tropopause Vertical Speed Shear [1/s]
WATRsfc   0,1,0   2,0,5,1 ** surface Water Runoff [kg/m^2]
WEASDsfc   0,1,0   0,1,13 ** surface Water Equivalent of Accumulated Snow Depth [kg/m^2]
WILTsfc   0,1,0   2,0,201 ** surface Wilting Point [Fraction]
ENDVARS
EOF

 
#----------------------------------
else ;#grib1
#----------------------------------
cat >$ctldir/${exp}_$hr.ctl <<EOF
dset ${datadir}/pgb${hr}${dump}%y4%m2%d2${cyc}
index $ctldir/${exp}.t${cyc}z.pgrb${hr}.idx
undef 9.999E+20
title ${exp}.t${cyc}z.pgrb${hr}
*  produced by grib2ctl v0.9.12.5p39a
dtype grib $gribtype
format template
options yrev
xdef $nptx linear 0.000000 $dxy     
ydef $npty linear -90.000000 $dxy 
tdef $ndays linear ${cyc}Z${day}${monc}${year} 1dy
zdef $nlev levels ${levlist}
vars 263
no4LFTXsfc    0 132,1,0  ** surface Best (4-layer) lifted index [K]
no5WAVH500mb  0 222,100,500 ** 500 mb 5-wave geopotential height [gpm]
ABSVprs       $nlev 41,100,0 ** (profile) Absolute vorticity [/s]
ACPCPsfc      0 63,1,0  ** surface Convective precipitation [kg/m^2]
ALBDOsfc      0 84,1,0  ** surface Albedo [%]
APCPsfc       0 61,1,0  ** surface Total precipitation [kg/m^2]
BRTMPtoa      0 118,8,0 ** top of atmos Brightness temperature [K]
CAPEsfc       0 157,1,0  ** surface Convective Avail. Pot. Energy [J/kg]
CAPE180_0mb   0 157,116,46080 ** 180-0 mb above gnd Convective Avail. Pot. Energy [J/kg]
CAPE255_0mb   0 157,116,65280 ** 255-0 mb above gnd Convective Avail. Pot. Energy [J/kg]
CDUVBsfc      0 201,1,0  ** surface Clear Sky UV-B Downward Solar Flux [W/m^2]
CFRZRsfc      0 141,1,0  ** surface Categorical freezing rain [yes=1;no=0]
CICEPsfc      0 142,1,0  ** surface Categorical ice pellets [yes=1;no=0]
CINsfc        0 156,1,0  ** surface Convective inhibition [J/kg]
CIN180_0mb    0 156,116,46080 ** 180-0 mb above gnd Convective inhibition [J/kg]
CIN255_0mb    0 156,116,65280 ** 255-0 mb above gnd Convective inhibition [J/kg]
CLWMRprs      $nlev 153,100,0 ** (profile) Cloud water [kg/kg]
CNWATsfc      0 223,1,0  ** surface Plant canopy surface water [kg/m^2]
CPRATsfc      0 214,1,0  ** surface Convective precip. rate [kg/m^2/s]
CRAINsfc      0 140,1,0  ** surface Categorical rain [yes=1;no=0]
CSNOWsfc      0 143,1,0  ** surface Categorical snow [yes=1;no=0]
CWATclm       0 76,200,0 ** atmos column Cloud water [kg/m^2]
CWORKclm      0 146,200,0 ** atmos column Cloud work function [J/kg]
DLWRFsfc      0 205,1,0  ** surface Downward long wave flux [W/m^2]
DPT2m         0 17,105,2 ** 2 m above ground Dew point temp. [K]
DPT30_0mb     0 17,116,7680 ** 30-0 mb above gnd Dew point temp. [K]
DSWRFsfc      0 204,1,0  ** surface Downward short wave flux [W/m^2]
DUVBsfc       0 200,1,0  ** surface UV-B Downward Solar Flux [W/m^2]
FLDCPsfc      0 220,1,0  ** surface Field Capacity [fraction]
FRICVsfc      0 253,1,0  ** surface Friction velocity [m/s]
GFLUXsfc      0 155,1,0  ** surface Ground heat flux [W/m^2]
GUSTsfc       0 180,1,0  ** surface Surface wind gust [m/s]
HGTsfc        0 7,1,0  ** surface Geopotential height [gpm]
HGTprs        $nlev 7,100,0 ** (profile) Geopotential height [gpm]
HGTpv500      0 7,117,500 ** pot vorticity = 500 units level Geopotential height [gpm]
HGTpv1000     0 7,117,1000 ** pot vorticity = 1000 units level Geopotential height [gpm]
HGTpv1500     0 7,117,1500 ** pot vorticity = 1500 units level Geopotential height [gpm]
HGTpv2000     0 7,117,2000 ** pot vorticity = 2000 units level Geopotential height [gpm]
HGTpvneg500   0 7,117,33268 ** pot vorticity = -500 units level Geopotential height [gpm]
HGTpvneg1000  0 7,117,33768 ** pot vorticity = -1000 units level Geopotential height [gpm]
HGTpvneg1500  0 7,117,34268 ** pot vorticity = -1500 units level Geopotential height [gpm]
HGTpvneg2000  0 7,117,34768 ** pot vorticity = -2000 units level Geopotential height [gpm]
HGThtfl       0 7,204,0 ** highest trop freezing level Geopotential height [gpm]
HGT0deg       0 7,4,0 ** 0C isotherm level Geopotential height [gpm]
HGTmwl        0 7,6,0 ** max wind level Geopotential height [gpm]
HGTtrp        0 7,7,0 ** tropopause Geopotential height [gpm]
HINDEXsfc     0 250,1,0  ** surface Haines index []
HLCY0_3000m   0 190,106,7680 ** 0-3000 m above ground Storm relative helicity [m^2/s^2]
HPBLsfc       0 221,1,0  ** surface Planetary boundary layer height [m]
ICAHTmwl      0 5,6,0 ** max wind level ICAO Standard Atmosphere Reference Height [M]
ICAHTtrp      0 5,7,0 ** tropopause ICAO Standard Atmosphere Reference Height [M]
ICECsfc       0 91,1,0  ** surface Ice concentration (ice=1;no ice=0) [fraction]
ICETKsfc      0 92,1,0  ** surface Ice thickness [m]
LANDsfc       0 81,1,0  ** surface Land cover (land=1;sea=0) [fraction]
LFTXsfc       0 131,1,0  ** surface Surface lifted index [K]
LHTFLsfc      0 121,1,0  ** surface Latent heat flux [W/m^2]
MNTSF320K     0 37,113,320 ** 320K level Montgomery stream function [m^2/s^2]
MSLETmsl      0 130,102,0 ** mean-sea level Mean sea level pressure (ETA model) [Pa]
NCPCPsfc      0 62,1,0  ** surface Large scale precipitation [kg/m^2]
O3MRprs       $nlev 154,100,0 ** (profile) Ozone mixing ratio [kg/kg]
PEVPRsfc      0 145,1,0  ** surface Potential evaporation rate [W/m^2]
PLI30_0mb     0 24,116,7680 ** 30-0 mb above gnd Parcel lifted index (to 500 hPa) [K]
PLPL255_0mb   0 141,116,65280 ** 255-0 mb above gnd Pressure of level from which parcel was lifted [Pa]
POTsig995     0 13,107,9950 ** sigma=.995  Potential temp. [K]
PRATEsfc      0 59,1,0  ** surface Precipitation rate [kg/m^2/s]
PRESsfc       0 1,1,0  ** surface Pressure [Pa]
PRESmsl       0 1,102,0 ** mean-sea level Pressure [Pa]
PRES80m       0 1,105,80 ** 80 m above ground Pressure [Pa]
PRESpv500     0 1,117,500 ** pot vorticity = 500 units level Pressure [Pa]
PRESpv1000    0 1,117,1000 ** pot vorticity = 1000 units level Pressure [Pa]
PRESpv1500    0 1,117,1500 ** pot vorticity = 1500 units level Pressure [Pa]
PRESpv2000    0 1,117,2000 ** pot vorticity = 2000 units level Pressure [Pa]
PRESpvneg500  0 1,117,33268 ** pot vorticity = -500 units level Pressure [Pa]
PRESpvneg1000 0 1,117,33768 ** pot vorticity = -1000 units level Pressure [Pa]
PRESpvneg1500 0 1,117,34268 ** pot vorticity = -1500 units level Pressure [Pa]
PRESpvneg2000 0 1,117,34768 ** pot vorticity = -2000 units level Pressure [Pa]
PRESlcb       0 1,212,0 ** low cloud base Pressure [Pa]
PRESlct       0 1,213,0 ** low cloud top Pressure [Pa]
PRESmcb       0 1,222,0 ** mid-cloud base Pressure [Pa]
PRESmct       0 1,223,0 ** mid-cloud top Pressure [Pa]
PREShcb       0 1,232,0 ** high cloud base Pressure [Pa]
PREShct       0 1,233,0 ** high cloud top Pressure [Pa]
PREScvb       0 1,242,0 ** convective cld base Pressure [Pa]
PREScvt       0 1,243,0 ** convective cld top Pressure [Pa]
PRESmwl       0 1,6,0 ** max wind level Pressure [Pa]
PREStrp       0 1,7,0 ** tropopause Pressure [Pa]
PRMSLmsl      0 2,102,0 ** mean-sea level Pressure reduced to MSL [Pa]
PVORT320K     0 4,113,320 ** 320K level Pot. vorticity [km^2/kg/s]
PWAT30_0mb    0 54,116,7680 ** 30-0 mb above gnd Precipitable water [kg/m^2]
PWATclm       0 54,200,0 ** atmos column Precipitable water [kg/m^2]
RHprs         $nlev 52,100,0 ** (profile) Relative humidity [%]
RH2m          0 52,105,2 ** 2 m above ground Relative humidity [%]
RHsig995      0 52,107,9950 ** sigma=.995  Relative humidity [%]
RHsg33_100    0 52,108,8548 ** sigma=0.33-1 layer Relative humidity [%]
RHsg44_72     0 52,108,11336 ** sigma=0.44-0.72 layer Relative humidity [%]
RHsg44_100    0 52,108,11364 ** sigma=0.44-1 layer Relative humidity [%]
RHsg72_94     0 52,108,18526 ** sigma=0.72-0.94 layer Relative humidity [%]
RH30_0mb      0 52,116,7680 ** 30-0 mb above gnd Relative humidity [%]
RH60_30mb     0 52,116,15390 ** 60-30 mb above gnd Relative humidity [%]
RH90_60mb     0 52,116,23100 ** 90-60 mb above gnd Relative humidity [%]
RH120_90mb    0 52,116,30810 ** 120-90 mb above gnd Relative humidity [%]
RH150_120mb   0 52,116,38520 ** 150-120 mb above gnd Relative humidity [%]
RH180_150mb   0 52,116,46230 ** 180-150 mb above gnd Relative humidity [%]
RHclm         0 52,200,0 ** atmos column Relative humidity [%]
RHhtfl        0 52,204,0 ** highest trop freezing level Relative humidity [%]
RH0deg        0 52,4,0 ** 0C isotherm level Relative humidity [%]
SFCRsfc       0 83,1,0  ** surface Surface roughness [m]
SHTFLsfc      0 122,1,0  ** surface Sensible heat flux [W/m^2]
SNODsfc       0 66,1,0  ** surface Snow depth [m]
SOILL0_10cm   0 160,112,10 ** 0-10 cm underground Liquid volumetric soil moisture (non-frozen) [fraction]
SOILL10_40cm  0 160,112,2600 ** 10-40 cm underground Liquid volumetric soil moisture (non-frozen) [fraction]
SOILL40_100cm 0 160,112,10340 ** 40-100 cm underground Liquid volumetric soil moisture (non-frozen) [fraction]
SOILL100_200cm 0 160,112,25800 ** 100-200 cm underground Liquid volumetric soil moisture (non-frozen) [fraction]
SOILW0_10cm   0 144,112,10 ** 0-10 cm underground Volumetric soil moisture [fraction]
SOILW10_40cm  0 144,112,2600 ** 10-40 cm underground Volumetric soil moisture [fraction]
SOILW40_100cm 0 144,112,10340 ** 40-100 cm underground Volumetric soil moisture [fraction]
SOILW100_200cm  0 144,112,25800 ** 100-200 cm underground Volumetric soil moisture [fraction]
SPFHprs       $nlev 51,100,0 ** (profile) Specific humidity [kg/kg]
SPFH80m       0 51,105,80 ** 80 m above ground Specific humidity [kg/kg]
SPFH2m        0 51,105,2 ** 2 m above ground Specific humidity [kg/kg]
SPFH30_0mb    0 51,116,7680 ** 30-0 mb above gnd Specific humidity [kg/kg]
SPFH60_30mb   0 51,116,15390 ** 60-30 mb above gnd Specific humidity [kg/kg]
SPFH90_60mb   0 51,116,23100 ** 90-60 mb above gnd Specific humidity [kg/kg]
SPFH120_90mb  0 51,116,30810 ** 120-90 mb above gnd Specific humidity [kg/kg]
SPFH150_120mb 0 51,116,38520 ** 150-120 mb above gnd Specific humidity [kg/kg]
SPFH180_150mb 0 51,116,46230 ** 180-150 mb above gnd Specific humidity [kg/kg]
SUNSDsfc      0 191,1,0  ** surface Sunshine duration [s]
TCDC475mb     0 71,100,475 ** 475 mb Total cloud cover [%]
TCDCclm       0 71,200,0 ** atmos column Total cloud cover [%]
TCDCbcl       0 71,211,0 ** boundary cld layer Total cloud cover [%]
TCDClcl       0 71,214,0 ** low cloud level Total cloud cover [%]
TCDCmcl       0 71,224,0 ** mid-cloud level Total cloud cover [%]
TCDChcl       0 71,234,0 ** high cloud level Total cloud cover [%]
TCDCcvl       0 71,244,0 ** convective cld layer Total cloud cover [%]
TMAX2m        0 15,105,2 ** 2 m above ground Max. temp. [K]
TMIN2m        0 16,105,2 ** 2 m above ground Min. temp. [K]
TMPsfc        0 11,1,0  ** surface Temp. [K]
TMPprs        $nlev 11,100,0 ** (profile) Temp. [K]
TMP4572m      0 11,103,4572 ** 4572 m above msl Temp. [K]
TMP3658m      0 11,103,3658 ** 3658 m above msl Temp. [K]
TMP2743m      0 11,103,2743 ** 2743 m above msl Temp. [K]
TMP1829m      0 11,103,1829 ** 1829 m above msl Temp. [K]
TMP914m       0 11,103,914 ** 914 m above msl Temp. [K]
TMP610m       0 11,103,610 ** 610 m above msl Temp. [K]
TMP457m       0 11,103,457 ** 457 m above msl Temp. [K]
TMP305m       0 11,103,305 ** 305 m above msl Temp. [K]
TMP100m       0 11,105,100 ** 100 m above ground Temp. [K]
TMP80m        0 11,105,80 ** 80 m above ground Temp. [K]
TMP2m         0 11,105,2 ** 2 m above ground Temp. [K]
TMPsig995     0 11,107,9950 ** sigma=.995  Temp. [K]
TMP320K       0 11,113,320 ** 320K level Temp. [K]
TMP30_0mb     0 11,116,7680 ** 30-0 mb above gnd Temp. [K]
TMP60_30mb    0 11,116,15390 ** 60-30 mb above gnd Temp. [K]
TMP90_60mb    0 11,116,23100 ** 90-60 mb above gnd Temp. [K]
TMP120_90mb   0 11,116,30810 ** 120-90 mb above gnd Temp. [K]
TMP150_120mb  0 11,116,38520 ** 150-120 mb above gnd Temp. [K]
TMP180_150mb  0 11,116,46230 ** 180-150 mb above gnd Temp. [K]
TMPpv500      0 11,117,500 ** pot vorticity = 500 units level Temp. [K]
TMPpv1000     0 11,117,1000 ** pot vorticity = 1000 units level Temp. [K]
TMPpv1500     0 11,117,1500 ** pot vorticity = 1500 units level Temp. [K]
TMPpv2000     0 11,117,2000 ** pot vorticity = 2000 units level Temp. [K]
TMPpvneg500   0 11,117,33268 ** pot vorticity = -500 units level Temp. [K]
TMPpvneg1000  0 11,117,33768 ** pot vorticity = -1000 units level Temp. [K]
TMPpvneg1500  0 11,117,34268 ** pot vorticity = -1500 units level Temp. [K]
TMPpvneg2000  0 11,117,34768 ** pot vorticity = -2000 units level Temp. [K]
TMPlct        0 11,213,0 ** low cloud top Temp. [K]
TMPmct        0 11,223,0 ** mid-cloud top Temp. [K]
TMPhct        0 11,233,0 ** high cloud top Temp. [K]
TMPmwl        0 11,6,0 ** max wind level Temp. [K]
TMPtrp        0 11,7,0 ** tropopause Temp. [K]
TOZNEclm      0 10,200,0 ** atmos column Total ozone [Dobson]
TSOIL0_10cm   0 85,112,10 ** 0-10 cm underground Soil temp. [K]
TSOIL10_40cm  0 85,112,2600 ** 10-40 cm underground Soil temp. [K]
TSOIL40_100cm  0 85,112,10340 ** 40-100 cm underground Soil temp. [K]
TSOIL100_200cm 0 85,112,25800 ** 100-200 cm underground Soil temp. [K]
UGWDsfc       0 147,1,0  ** surface Zonal gravity wave stress [N/m^2]
UFLXsfc       0 124,1,0  ** surface Zonal momentum flux [N/m^2]
UGRDprs       $nlev 33,100,0 ** (profile) u wind [m/s]
UGRD4572m     0 33,103,4572 ** 4572 m above msl u wind [m/s]
UGRD3658m     0 33,103,3658 ** 3658 m above msl u wind [m/s]
UGRD2743m     0 33,103,2743 ** 2743 m above msl u wind [m/s]
UGRD1829m     0 33,103,1829 ** 1829 m above msl u wind [m/s]
UGRD914m      0 33,103,914 ** 914 m above msl u wind [m/s]
UGRD610m      0 33,103,610 ** 610 m above msl u wind [m/s]
UGRD457m      0 33,103,457 ** 457 m above msl u wind [m/s]
UGRD305m      0 33,103,305 ** 305 m above msl u wind [m/s]
UGRD100m      0 33,105,100 ** 100 m above ground u wind [m/s]
UGRD80m       0 33,105,80 ** 80 m above ground u wind [m/s]
UGRD10m       0 33,105,10 ** 10 m above ground u wind [m/s]
UGRDsig995    0 33,107,9950 ** sigma=.995  u wind [m/s]
UGRD320K      0 33,113,320 ** 320K level u wind [m/s]
UGRD30_0mb    0 33,116,7680 ** 30-0 mb above gnd u wind [m/s]
UGRD60_30mb   0 33,116,15390 ** 60-30 mb above gnd u wind [m/s]
UGRD90_60mb   0 33,116,23100 ** 90-60 mb above gnd u wind [m/s]
UGRD120_90mb  0 33,116,30810 ** 120-90 mb above gnd u wind [m/s]
UGRD150_120mb 0 33,116,38520 ** 150-120 mb above gnd u wind [m/s]
UGRD180_150mb 0 33,116,46230 ** 180-150 mb above gnd u wind [m/s]
UGRDpv500     0 33,117,500 ** pot vorticity = 500 units level u wind [m/s]
UGRDpv1000    0 33,117,1000 ** pot vorticity = 1000 units level u wind [m/s]
UGRDpv1500    0 33,117,1500 ** pot vorticity = 1500 units level u wind [m/s]
UGRDpv2000    0 33,117,2000 ** pot vorticity = 2000 units level u wind [m/s]
UGRDpvneg500  0 33,117,33268 ** pot vorticity = -500 units level u wind [m/s]
UGRDpvneg1000 0 33,117,33768 ** pot vorticity = -1000 units level u wind [m/s]
UGRDpvneg1500 0 33,117,34268 ** pot vorticity = -1500 units level u wind [m/s]
UGRDpvneg2000 0 33,117,34768 ** pot vorticity = -2000 units level u wind [m/s]
UGRDpbl       0 33,220,0  ** unknown level u wind [m/s]
UGRDmwl       0 33,6,0 ** max wind level u wind [m/s]
UGRDtrp       0 33,7,0 ** tropopause u wind [m/s]
ULWRFsfc      0 212,1,0  ** surface Upward long wave flux [W/m^2]
ULWRFtoa      0 212,8,0 ** top of atmos Upward long wave flux [W/m^2]
USTM0_6000m   0 196,106,15360 ** 0-6000 m above ground u-component of storm motion [m/s]
USWRFsfc      0 211,1,0  ** surface Upward short wave flux [W/m^2]
USWRFtoa      0 211,8,0 ** top of atmos Upward short wave flux [W/m^2]
VGWDsfc       0 148,1,0  ** surface Meridional gravity wave stress [N/m^2]
VFLXsfc       0 125,1,0  ** surface Meridional momentum flux [N/m^2]
VGRDprs       $nlev 34,100,0 ** (profile) v wind [m/s]
VGRD4572m     0 34,103,4572 ** 4572 m above msl v wind [m/s]
VGRD3658m     0 34,103,3658 ** 3658 m above msl v wind [m/s]
VGRD2743m     0 34,103,2743 ** 2743 m above msl v wind [m/s]
VGRD1829m     0 34,103,1829 ** 1829 m above msl v wind [m/s]
VGRD914m      0 34,103,914 ** 914 m above msl v wind [m/s]
VGRD610m      0 34,103,610 ** 610 m above msl v wind [m/s]
VGRD457m      0 34,103,457 ** 457 m above msl v wind [m/s]
VGRD305m      0 34,103,305 ** 305 m above msl v wind [m/s]
VGRD100m      0 34,105,100 ** 100 m above ground v wind [m/s]
VGRD80m       0 34,105,80 ** 80 m above ground v wind [m/s]
VGRD10m       0 34,105,10 ** 10 m above ground v wind [m/s]
VGRDsig995    0 34,107,9950 ** sigma=.995  v wind [m/s]
VGRD320K      0 34,113,320 ** 320K level v wind [m/s]
VGRD30_0mb    0 34,116,7680 ** 30-0 mb above gnd v wind [m/s]
VGRD60_30mb   0 34,116,15390 ** 60-30 mb above gnd v wind [m/s]
VGRD90_60mb   0 34,116,23100 ** 90-60 mb above gnd v wind [m/s]
VGRD120_90mb  0 34,116,30810 ** 120-90 mb above gnd v wind [m/s]
VGRD150_120mb 0 34,116,38520 ** 150-120 mb above gnd v wind [m/s]
VGRD180_150mb 0 34,116,46230 ** 180-150 mb above gnd v wind [m/s]
VGRDpv500     0 34,117,500 ** pot vorticity = 500 units level v wind [m/s]
VGRDpv1000    0 34,117,1000 ** pot vorticity = 1000 units level v wind [m/s]
VGRDpv1500    0 34,117,1500 ** pot vorticity = 1500 units level v wind [m/s]
VGRDpv2000    0 34,117,2000 ** pot vorticity = 2000 units level v wind [m/s]
VGRDpvneg500  0 34,117,33268 ** pot vorticity = -500 units level v wind [m/s]
VGRDpvneg1000 0 34,117,33768 ** pot vorticity = -1000 units level v wind [m/s]
VGRDpvneg1500 0 34,117,34268 ** pot vorticity = -1500 units level v wind [m/s]
VGRDpvneg2000 0 34,117,34768 ** pot vorticity = -2000 units level v wind [m/s]
VGRDpbl       0 34,220,0  ** unknown level v wind [m/s]
VGRDmwl       0 34,6,0 ** max wind level v wind [m/s]
VGRDtrp       0 34,7,0 ** tropopause v wind [m/s]
VISsfc        0 20,1,0  ** surface Visibility [m]
VRATEpbl      0 241,220,0  ** unknown level Ventilation rate [m^2/s]
VSTM0_6000m   0 197,106,15360 ** 0-6000 m above ground v-component of storm motion [m/s]
VVELprs       $nlev 39,100,0 ** (profile) Pressure vertical velocity [Pa/s]
VVELsig995    0 39,107,9950 ** sigma=.995  Pressure vertical velocity [Pa/s]
VWSHpv500     0 136,117,500 ** pot vorticity = 500 units level Vertical speed shear [1/s]
VWSHpv1000    0 136,117,1000 ** pot vorticity = 1000 units level Vertical speed shear [1/s]
VWSHpv1500    0 136,117,1500 ** pot vorticity = 1500 units level Vertical speed shear [1/s]
VWSHpv2000    0 136,117,2000 ** pot vorticity = 2000 units level Vertical speed shear [1/s]
VWSHpvneg500  0 136,117,33268 ** pot vorticity = -500 units level Vertical speed shear [1/s]
VWSHpvneg1000 0 136,117,33768 ** pot vorticity = -1000 units level Vertical speed shear [1/s]
VWSHpvneg1500 0 136,117,34268 ** pot vorticity = -1500 units level Vertical speed shear [1/s]
VWSHpvneg2000 0 136,117,34768 ** pot vorticity = -2000 units level Vertical speed shear [1/s]
VWSHtrp       0 136,7,0 ** tropopause Vertical speed shear [1/s]
WATRsfc       0 90,1,0  ** surface Water runoff [kg/m^2]
WEASDsfc      0 65,1,0  ** surface Accum. snow [kg/m^2]
WILTsfc       0 219,1,0  ** surface Wilting point [fraction]
ENDVARS
EOF
#-------------
fi
#-------------

gribmap -0 -i $ctldir/${exp}_${hr}.ctl

hrold=$hr
fi
done
#-----------------------------------
n=`expr $n + 1 `               
done

exit
