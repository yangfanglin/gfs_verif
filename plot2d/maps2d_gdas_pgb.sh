#!/bin/ksh
set -x

#### ------------------------------------------------------------------- 
###  Make lat-lon maps and zonal-mean vertical distributions of analysis 
###  increment and rms between GDAS analysis and first guess (6-hr forecast 
###  from last GDAS cycle). Inputs are pgbanl and pgbf06 from last cycle.
###  Graphic types include time averaged increments and RMS of increments.
###  Fanglin Yang, EMC/NCEP/NOAA,  July 2016     
###  fanglin.yang@noaa.gov; 301-6833722            
#### ---------------------------------------------------------- 

export expnlist=${expnlist:-"gfs prnemsr"}     ;#experiments, up to 8; gfs will point to ops data
export expdlist=${expdlist:-"/global/noscrub/emc.glopara/global /global/noscrub/emc.glopara/archive"}    ;#data archive
export hpsslist=${hpsslist:-"/NCEPPROD/hpssprod/runhistory /5year/NCEPDEV/emc-global/emc.glopara/WCOSS"} ;#hpss arch
export dumplist=${dumplist:-".gdas. .gdas."}  ;#file format siganl${dum}${cdate} and sigges${dump}$cdate
export complist=${complist:-"tide tide"}      ;#computers where experiments are run
export cyclist=${cyclist:-"00 06 12 18"}      ;#forecast cycles to verify
export guesshr=${guesshr:-"06"}               ;#forecast hour from last gdas cycle used as first guess
export cychour=${cychour:-6}                  ;#hours between cycles, GFS is fixed to 6 hour
export levpgb=${levpgb:-"1000 925 800 700 500 200 100 70 50 30 10 7 5 1"} ;#pressure layers for lat-lon maps,up to 14
export DATEST=${DATEST:-20160620}             ;#starting verifying date per pgbanl
export DATEND=${DATEND:-20160630}             ;#ending verifying date per pgbanl

export grid=${grid:-G3}                       ;#pgb file resolution, G2->2.5deg; G3->1deg; G4->0.5deg
export nlev=${nlev:-31}                       ;#pgb file vertical layers
export pbtm=${pbtm:-1000}                     ;#bottom layer pressure                   
export ptop=${ptop:-1}                        ;#top layer pressure                       
export webhost=${webhost:-emcrzdm.ncep.noaa.gov}
export webhostid=${webhostid:-wx24fy}
export ftpdir=${ftpdir:-/home/people/emc/www/htdocs/gmb/$webhostid/vsdb/test}
export doftp=${doftp:-NO}

export rundir=${rundir:-/ptmpd2/$LOGNAME/gdasmaps}
if [ ! -s $rundir ]; then mkdir -p $rundir ; fi
cd $rundir || exit 8
rm -rf *
export mapdir=${mapdir:-$rundir/web}        ;#place where maps are saved locally
mkdir -p $mapdir

export batch=${batch:-NO}
export APRUN=${APRUN:-""}                   ;#affix for running batch jobs 
if [ $batch != YES ]; then export APRUN="" ; fi
export machine=${machine:-WCOSS}
export NWPROD=${NWPROD:-/nwprod}
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export cpygb=${cpygb:-"$APRUN $NWPROD/util/exec/copygb"}
export wgrb=${wgrib:-$NWPROD/util/exec/wgrib}
export vsdbhome=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}
export SUBJOB=${SUBJOB:-$vsdbhome/bin/sub_wcoss}
export ACCOUNT=${ACCOUNT:-GFS-MTN}
export CUE2RUN=${CUE2RUN:-dev}
export CUE2FTP=${CUE2FTP:-transfer}
export GROUP=${GROUP:-g01}

#------------------------------------------------------------------
#------------------------------------------------------------------
srcdir=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}/plot2d
gradsutil=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}/map_util/grads
export GRADSBIN=${GRADSBIN:-/usrx/local/GrADS/2.0.2/bin}

if [ $doftp = YES -a $batch = NO ]; then
ssh -q -l $webhostid ${webhost} " ls -l ${ftpdir}/2D/gdas "
if [ $? -ne 0 ]; then
 ssh -l $webhostid ${webhost} " mkdir -p $ftpdir "
 scp -rp $srcdir/html/* ${webhostid}@${webhost}:$ftpdir/.
fi
fi
if [ ! -s $mapdir/index.html ]; then
 cp -rp $srcdir/html/* $mapdir/.
fi
 
#------------------------------
y1=`echo $DATEST |cut -c 1-4 `
m1=`echo $DATEST |cut -c 5-6 `
d1=`echo $DATEST |cut -c 7-8 `
y2=`echo $DATEND   |cut -c 1-4 `
m2=`echo $DATEND   |cut -c 5-6 `
d2=`echo $DATEND   |cut -c 7-8 `
ndays=`${srcdir}/days.sh -a $y2 $m2 $d2 - $y1 $m1 $d1`
export ndays=`expr $ndays + 1`                                     

#==================================================================
#-- create GrADS control files
export ctldir=${rundir}/ctl                                   
$srcdir/makectl_gdas_pgb.sh

nexp=`echo $expnlist |wc -w`                
ncyc=`echo $cyclist |wc -w`                
if [ $ncyc -lt 4 ]; then 
 echo " ncyc=$ncyc , must be 4 cycle. exit"
 exit 
fi


#==================================================================
set -A sname  none $expnlist
set -A expdname none $expdlist
set -A compname none $complist
set -A dumpname none $dumplist
set -A cycname  non $cyclist
cycs=${cycname[1]}
cyce=${cycname[$ncyc]}

set -A mlist none Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
DATESTA=${DATEST}${cycs}
yeara=`echo $DATESTA |cut -c 1-4`
mona=`echo $DATESTA |cut -c 5-6`
daya=`echo $DATESTA |cut -c 7-8`
cyca=`echo $DATESTA |cut -c 9-10`
sata=${cyca}Z${daya}${mlist[$mona]}${yeara}

DATESTG=`$ndate -$cychour ${DATEST}${cycs}`   ;##first first guess
yearg=`echo $DATESTG |cut -c 1-4`
mong=`echo $DATESTG |cut -c 5-6`
dayg=`echo $DATESTG |cut -c 7-8`
cycg=`echo $DATESTG |cut -c 9-10`
satg=${cycg}Z${dayg}${mlist[$mong]}${yearg}

DATENDA=${DATEND}${cyce}
yeara=`echo $DATENDA |cut -c 1-4`
mona=`echo $DATENDA |cut -c 5-6`
daya=`echo $DATENDA |cut -c 7-8`
cyca=`echo $DATENDA |cut -c 9-10`
enda=${cyca}Z${daya}${mlist[$mona]}${yeara}

DATENDG=`$ndate -$cychour ${DATEND}${cyce}`   ;##last first guess
yearg=`echo $DATENDG |cut -c 1-4`
mong=`echo $DATENDG |cut -c 5-6`
dayg=`echo $DATENDG |cut -c 7-8`
cycg=`echo $DATENDG |cut -c 9-10`
endg=${cycg}Z${dayg}${mlist[$mong]}${yearg}

n=1; while [ $n -le $nexp ]; do
 exp=${sname[$n]}
 export ctl${n}a=${rundir}/ctl/${exp}_anl.ctl
 export ctl${n}g=${rundir}/ctl/${exp}_ges.ctl
n=$((n+1))
done
#------------------------------
#==================================================================
#-- make maps
#==================================================================
tmpdir=$rundir/plot        
mkdir $tmpdir ; cd $tmpdir || exit 8

#--define map range
area=${area:-gb}
latlon=${latlon:-"-90 90 0 360"}        ;#map area lat1, lat2, lon1 and lon2
set -A latlonc none $latlon
lat1=${latlonc[1]}; lat2=${latlonc[2]}
lon1=${latlonc[3]}; lon2=${latlonc[4]}


#### -------------------------------------------------
###  generate 2D maps on selected sigma surface layers.
###  choose up to 14 layers to display, including time
###  averaged increments and RMS of increments.
#### -------------------------------------------------
xdump=GDAS; if [ ${dumpname[1]} = .gfs. ]; then xdump=GFS; fi
nplot=$((nexp+1))


vlist="TMPprs SPFHprs RHprs UGRDprs VGRDprs O3MRprs CLWMRprs MSLETmsl"
nvar=`echo $vlist |wc -w`
#--------------------------------
for var in  $vlist; do                                                         
#--------------------------------
levlist="$levpgb"
if [ $var = MSLETmsl ]; then levlist=1000; fi
levn=1
#--------------------------------
for levp in $levlist ; do                                    
#--------------------------------
 if [ $var = "TMPprs"                    ];   then varname="Temp (K)"           scal=1            ; fi
 if [ $var = "SPFHprs"                   ];   then varname="Q (1E-6 kg/kg)"     scal=1000000      ; fi
 if [ $var = "SPFHprs"  -a $levp -ge 250 ];   then varname="Q (g/kg)"           scal=1000         ; fi
 if [ $var = "RHprs"                     ];   then varname="RH (%)"             scal=1            ; fi
 if [ $var = "UGRDprs"                   ];   then varname="U (m/s)"            scal=1            ; fi
 if [ $var = "VGRDprs"                   ];   then varname="V (m/s)"            scal=1            ; fi
 if [ $var = "O3MRprs"                   ];   then varname="O3 (1E-6 kg/kg)"    scal=1000000      ; fi
 if [ $var = "O3MRprs" -a $levp -ge 200  ];   then varname="O3 (1E-9 kg/kg)"    scal=1000000000   ; fi
 if [ $var = "CLWMRprs"                  ];   then varname="Cld Water (1E-6 kg/kg)"  scal=1000000    ; fi
 if [ $var = "CLWMRprs" -a $levp -le 200 ];  then varname="Cld Water (1E-9 kg/kg)"  scal=1000000000 ; fi
 if [ $var = "MSLETmsl"                  ];   then varname="Surface Pressure (hPa)"  scal=0.01    ; fi

#.........................
# time averaged increments
#.........................
cat >${var}${levn}_bias.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1a'
  'open $ctl1g'
   mdc.1=${sname[1]}
if  ($nexp >1)
  'open $ctl2a'
  'open $ctl2g'
   mdc.2=${sname[2]}
endif     
if  ($nexp >2)
  'open $ctl3a'
  'open $ctl3g'
   mdc.3=${sname[3]}
endif     
if  ($nexp >3)
  'open $ctl4a'
  'open $ctl4g'
   mdc.4=${sname[4]}
endif     
if  ($nexp >4)
  'open $ctl5a'
  'open $ctl5g'
   mdc.5=${sname[5]}
endif     
if  ($nexp >5)
  'open $ctl6a'
  'open $ctl6g'
   mdc.6=${sname[6]}
endif     
if  ($nexp >6)
  'open $ctl7a'
  'open $ctl7g'
   mdc.7=${sname[7]}
endif     
if  ($nexp >7)
  'open $ctl8a'
  'open $ctl8g'
   mdc.8=${sname[8]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2'
  'set lev $levp'
  'set t 1  '

*--analysis itself from control run
  'define sn1=${scal}*ave(${var}.1, time=${sata},time=${enda})'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

*--increments 
n=1
while ( n <= ${nexp} )
  f1=(n-1)*2+1
  f2=(n-1)*2+2
  m=n+1

  'define sn'%m'=${scal}*(ave(${var}.'%f1',time=${sata},time=${enda})-ave(${var}.'%f2',time=${satg},time=${endg}))'
  'define yn'%m'=aave(sn'%m',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile

*------------------------
*--find maximum and minmum values of control analysis itself
   cmax=-10000000.0; cmin=10000000.0
    'set gxout stat'
    'd sn1'
    range=sublin(result,9); zmin=subwrd(range,5); zmax=subwrd(range,6)
    ln=sublin(result,7); wd=subwrd(ln,8); b=substr(wd,1,3)
    if( b>0 )
      if(zmax > cmax); cmax=zmax; endif
      if(zmin < cmin); cmin=zmin; endif
    endif
   dist=cmax-cmin; cmin=cmin+0.1*dist; cmax=cmax-0.1*dist
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6); cint=10*substr((cmax-cmin)/100,1,4)
   if (cint = 0); cint=substr((cmax-cmin)/10,1,4); endif
   if (cint = 0); cint=0.1*substr((cmax-cmin),1,4); endif
   if (cint = 0); cint=0.01*substr((cmax-cmin)*10,1,4); endif
   say 'cmin cmax cint 'cmin' 'cmax' 'cint
    aa1=cmin; aa2=cmin+cint; aa3=aa2+cint; aa4=aa3+cint; aa5=aa4+cint; aa6=aa5+cint
    aa7=aa6+cint; aa8=aa7+cint; aa9=aa8+cint; aa10=aa9+cint; aa11=aa10+cint


*--find maximum and minmum values for analysis increment and difference map
   cmax=-10000000.0; cmin=10000000.0
   i=2
   while (i <= $nplot)
    'set gxout stat'
    'd sn'%i
    range=sublin(result,9); zmin=subwrd(range,5); zmax=subwrd(range,6)
    if(zmax > cmax); cmax=zmax; endif
    if(zmin < cmin); cmin=zmin; endif
   i=i+1
   endwhile
   dist=cmax-cmin; cmin=cmin+0.05*dist; cmax=cmax-0.05*dist
   if(cmin >=0); cmin=-0.05*dist;endif
   if(cmax <=0); cmax=0.05*dist; endif
     if(cmax > -cmin); cmin=-cmax ; endif
     if(-cmin > cmax); cmax=-cmin ; endif
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6);
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
     cp0=0.25*cintp; cps=0.5*cintp; cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
     cm0=-cp0; cms=-cps; cm1=-cp1; cm2=-cp2; cm3=-cp3; cm4=-cp4; cm5=-cp5                                    
   say 'cmin cmax cintm cintp 'cmin' 'cmax' 'cintm' 'cintp
*------------------------

  nframe=$nplot
  nframe2=2; nframe3=4;
  ymax0=9.7;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nplot =2);  ylen=-4.0; ygap=-0.7; endif
  if($nplot >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nplot >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nplot >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

  i=1
  while ( i <= nframe )
  'set gxout stat'  ;*compute mean over area and good points
  'd sn'%i
    icx=1; if (i > nframe2); icx=2; endif
    if (i > nframe3); icx=3; endif
    if (i > nframe4); icx=4; endif
    xmin=xmin0+(icx-1)*(xlen+xgap)
    xmax=xmin+xlen
    icy=i; if (i > nframe2); icy=i-nframe2; endif
    if (i > nframe3); icy=i-nframe3; endif
    if (i > nframe4); icy=i-nframe4; endif
    ymax=ymax0+(icy-1)*(ylen+ygap)
    ymin=ymax+ylen
    titlx=xmin+0.05
    titly=ymax+0.08
    'set parea 'xmin' 'xmax' 'ymin' 'ymax

    'run $gradsutil/rgbset.gs'
    'set xlopts 1 4 0.0'
    'set ylopts 1 4 0.0'
      if($nplot <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nplot >2 & $nplot <=4)
        if(i=2|i=$nplot);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nplot >4 & $nplot <=6)
        if(i=3|i=$nplot);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nplot >=7)
        if(i=4|i=$nplot);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
    'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cm0' 0 'cp0' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols 49    46    42   39    37    34     32   0  0   22    24    26    29   73     76   79'
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1); 'set rbcols 31    33   35    37    39    43    45   47     49    21     23    25   27  ';endif
    'd smth9(sn'%i')'
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cm0' 0 'cp0' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1);'d smth9(sn'%i')' ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly '   A, 'mdc.1'  'a; endif
    if(i=2); 'draw string 'titlx' 'titly ' A-B, 'mdc.1'  'a; endif
    k=i-1
*   if(i>2); 'draw string 'titlx' 'titly ' A-B, 'mdc.k'-'mdc.1' 'a; endif
    if(i>2); 'draw string 'titlx' 'titly ' A-B, 'mdc.k' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.45 $xdump Analysis Increments, ${varname}'
  'set strsiz 0.13 0.13'
  if ( $var = MSLETmsl )
   'draw string 4.3 10.21 [${cyclist}] Cyc, ${DATEST} ~ ${DATEND}'
  else
   'draw string 4.3 10.21 $levp hPa, [${cyclist}] Cyc, ${DATEST} ~ ${DATEND}'
  endif
  'set string 1 bc 5'
  'set strsiz 0.13 0.13'
  if($nplot >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.60'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.4'
  endif

  'printim ${var}${levn}_bias.png png x700 y680'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}${levn}_bias.gs"  & 
sleep 10


#.........................
# RMS of increments
#.........................
cat >${var}${levn}_rms.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1a'
  'open $ctl1g'
   mdc.1=${sname[1]}
if  ($nexp >1)
  'open $ctl2a'
  'open $ctl2g'
   mdc.2=${sname[2]}
endif     
if  ($nexp >2)
  'open $ctl3a'
  'open $ctl3g'
   mdc.3=${sname[3]}
endif     
if  ($nexp >3)
  'open $ctl4a'
  'open $ctl4g'
   mdc.4=${sname[4]}
endif     
if  ($nexp >4)
  'open $ctl5a'
  'open $ctl5g'
   mdc.5=${sname[5]}
endif     
if  ($nexp >5)
  'open $ctl6a'
  'open $ctl6g'
   mdc.6=${sname[6]}
endif     
if  ($nexp >6)
  'open $ctl7a'
  'open $ctl7g'
   mdc.7=${sname[7]}
endif     
if  ($nexp >7)
  'open $ctl8a'
  'open $ctl8g'
   mdc.8=${sname[8]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2'
  'set lev $levp'
  'set t 1  '

*--analysis itself from control run
  'define sn1=${scal}*ave(${var}.1, time=${sata},time=${enda})'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

*--RMS of increments 
n=1
while ( n <= ${nexp} )
  f1=(n-1)*2+1
  f2=(n-1)*2+2
  m=n+1

  if(n=1) 
   'define sn'%m'=${scal}*sqrt(ave((${var}.'%f1'-${var}.'%f2'(t-1))*(${var}.'%f1'-${var}.'%f2'(t-1)), time=${sata},time=${enda}))'
  endif
  if(n>1) 
   'define sn'%m'=${scal}*sqrt(ave((${var}.'%f1'-${var}.'%f2'(t-1))*(${var}.'%f1'-${var}.'%f2'(t-1)), time=${sata},time=${enda}))-sn2'
  endif
  'define yn'%m'=aave(sn'%m',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile

*------------------------
*--find maximum and minmum values of control analysis itself
   cmax=-10000000.0; cmin=10000000.0
    'set gxout stat'
    'd sn1'
    range=sublin(result,9); zmin=subwrd(range,5); zmax=subwrd(range,6)
    ln=sublin(result,7); wd=subwrd(ln,8); b=substr(wd,1,3)
    if( b>0 )
      if(zmax > cmax); cmax=zmax; endif
      if(zmin < cmin); cmin=zmin; endif
    endif
   dist=cmax-cmin; cmin=cmin+0.1*dist; cmax=cmax-0.1*dist
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6); cint=10*substr((cmax-cmin)/100,1,4)
   if (cint = 0); cint=substr((cmax-cmin)/10,1,4); endif
   if (cint = 0); cint=0.1*substr((cmax-cmin),1,4); endif
   if (cint = 0); cint=0.01*substr((cmax-cmin)*10,1,4); endif
   say 'cmin cmax cint 'cmin' 'cmax' 'cint
    aa1=cmin; aa2=cmin+cint; aa3=aa2+cint; aa4=aa3+cint; aa5=aa4+cint; aa6=aa5+cint
    aa7=aa6+cint; aa8=aa7+cint; aa9=aa8+cint; aa10=aa9+cint; aa11=aa10+cint


*--find maximum and minmum values of RMS differences between exp and control run               
   cmax=-10000000.0; cmin=10000000.0
   i=2
   while (i <= $nplot)
    'set gxout stat'
    'd sn'%i
    range=sublin(result,9); zmin=subwrd(range,5); zmax=subwrd(range,6)
    if(zmax > cmax); cmax=zmax; endif
    if(zmin < cmin); cmin=zmin; endif
   i=i+1
   endwhile
   dist=cmax-cmin
   if(cmin >=0); cmin=-0.01*dist; endif
   if(cmax <=0); cmax=0.01*dist;  endif
     if(cmax > -cmin); cmin=-cmax ; endif
     if(-cmin > cmax); cmax=-cmin ; endif
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6);
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
     cpd=0.01*cintp; cpc=0.05*cintp; cpb=0.1*cintp; cpa=0.5*cintp
     cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
     cmd=-cpd; cmc=-cpc; cmb=-cpb; cma=-cpa; cm1=-cp1; cm2=-cp2; cm3=-cp3; cm4=-cp4; cm5=-cp5
   say 'cmin cmax cintm cintp 'cmin' 'cmax' 'cintm' 'cintp

*------------------------
  nframe=$nplot
  nframe2=2; nframe3=4;
  ymax0=9.7;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nplot =2);  ylen=-4.0; ygap=-0.7; endif
  if($nplot >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nplot >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nplot >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

  i=1
  while ( i <= nframe )
  'set gxout stat'  ;*compute mean over area and good points
  'd sn'%i
    icx=1; if (i > nframe2); icx=2; endif
    if (i > nframe3); icx=3; endif
    if (i > nframe4); icx=4; endif
    xmin=xmin0+(icx-1)*(xlen+xgap)
    xmax=xmin+xlen
    icy=i; if (i > nframe2); icy=i-nframe2; endif
    if (i > nframe3); icy=i-nframe3; endif
    if (i > nframe4); icy=i-nframe4; endif
    ymax=ymax0+(icy-1)*(ylen+ygap)
    ymin=ymax+ylen
    titlx=xmin+0.05
    titly=ymax+0.08
    'set parea 'xmin' 'xmax' 'ymin' 'ymax

    'run $gradsutil/rgbset.gs'
    'set xlopts 1 4 0.0'
    'set ylopts 1 4 0.0'
      if($nplot <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nplot >2 & $nplot <=4)
        if(i=2|i=$nplot);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nplot >4 & $nplot <=6)
        if(i=3|i=$nplot);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nplot >=7)
        if(i=4|i=$nplot);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
    'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs    'cm2' 'cm1' 'cma' 'cmb' 'cmc' 'cmd' 0 'cpd' 'cpc' 'cpb' 'cpa' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols  49   45    42    39    36     33    0  0    21     23   25    27     74    79    53   56    59'
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1); 'set rbcols 31    33   35    37    39    43    45   47     49    21     23    25   27  ';endif
    'd smth9(sn'%i')'
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs    'cm2' 'cm1' 'cma' 'cmb' 'cmc' 'cmd' 0 'cpd' 'cpc' 'cpb' 'cpa' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1);'d smth9(sn'%i')' ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly '   A, 'mdc.1'  'a; endif
    if(i=2); 'draw string 'titlx' 'titly ' RMS(A-B), 'mdc.1'  'a; endif
    k=i-1
    if(i>2); 'draw string 'titlx' 'titly ' RMS(A-B), 'mdc.k'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.45 RMS of $xdump Analysis Increments, ${varname}'
  'set strsiz 0.13 0.13'
  if ( $var = PS )          
   'draw string 4.3 10.21 [${cyclist}] Cyc, ${sata} ~ ${enda}'
  else
   'draw string 4.3 10.21 $levp hPa, [${cyclist}] Cyc, ${sata} ~ ${enda}'
  endif
  'set string 1 bc 3'
  'set strsiz 0.08 0.08'
  if($nplot >1 )
    'run $gradsutil/cbarn1.gs 1. 0 4.3 0.60'
  else
    'run $gradsutil/cbarn1.gs 1. 0 4.3 3.4'
  endif

  'printim ${var}${levn}_rms.png png x700 y680'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}${levn}_rms.gs"  &
sleep 10

#--------------------------------
 levn=$((levn+1))
done  ;#layers
#--------------------------------
sleep 60 
done  ;#variables
#--------------------------------

#--wait for maps to be made
nsleep=0
tsleep=60      #seconds to sleep before checking file again
msleep=120      #maximum number of times to sleep
while test ! -s $tmpdir/VGRDprs10_rms.png -a $nsleep -lt $msleep;do
  sleep $tsleep; nsleep=`expr $nsleep + 1`
done


cat << EOF >ftp_air
  binary
  prompt
  cd $ftpdir/2D/gdas   
  mput *.png
  quit
EOF
if [ $doftp = YES -a $CUE2RUN = $CUE2FTP ]; then
 sftp  ${webhostid}@${webhost} <ftp_air
 if [ $? -ne 0 ]; then
  scp -rp *.png ${webhostid}@${webhost}:$ftpdir/2D/gdas/.
 fi
fi
if [ ! -s $mapdir/2D/gdas ]; then mkdir -p $mapdir/2D/gdas ; fi
cp *.png $mapdir/2D/gdas/.



#### ---------------------------------------------------------------------
###  zonal mean time-averaged increments and zonal mean RMS of increments 
#### ---------------------------------------------------------------------

vlist="TMPprs SPFHprs RHprs UGRDprs VGRDprs O3MRprs CLWMRprs "
nvar=`echo $vlist |wc -w`
lev1=$pbtm; lev2=$ptop

#----------------------
for var in  $vlist; do                                                         
#----------------------

if [ $var = "TMPprs" ];   then varname="Temp (K)"           scal=1            ; fi
if [ $var = "SPFHprs" ];  then varname="Q (1E-6 kg/kg)"     scal=1000000      ; fi
if [ $var = "RHprs" ];    then varname="RH (%)"            scal=1            ; fi
if [ $var = "UGRDprs" ];  then varname="U (m/s)"            scal=1            ; fi
if [ $var = "VGRDprs" ];  then varname="V (m/s)"            scal=1            ; fi
if [ $var = "O3MRprs" ];  then varname="O3 (ppmg)"          scal=1000000      ; fi
if [ $var = "CLWMRprs" ]; then varname="Cloud Water (ppmg)" scal=1000000      ; fi

#.........................
# zonal mean increments
#.........................
cat >${var}_bias.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1a'
  'open $ctl1g'
   mdc.1=${sname[1]}
if  ($nexp >1)
  'open $ctl2a'
  'open $ctl2g'
   mdc.2=${sname[2]}
endif     
if  ($nexp >2)
  'open $ctl3a'
  'open $ctl3g'
   mdc.3=${sname[3]}
endif     
if  ($nexp >3)
  'open $ctl4a'
  'open $ctl4g'
   mdc.4=${sname[4]}
endif     
if  ($nexp >4)
  'open $ctl5a'
  'open $ctl5g'
   mdc.5=${sname[5]}
endif     
if  ($nexp >5)
  'open $ctl6a'
  'open $ctl6g'
   mdc.6=${sname[6]}
endif     
if  ($nexp >6)
  'open $ctl7a'
  'open $ctl7g'
   mdc.7=${sname[7]}
endif     
if  ($nexp >7)
  'open $ctl8a'
  'open $ctl8g'
   mdc.8=${sname[8]}
endif     
*-----

  'set lat $lat1 $lat2'
  'set lev $lev1 $lev2'
  'set t 1  '

*----control run analysis
  'set lon $lon1 $lon2'
  'define aa=${scal}*ave(${var}.1, time=${sata},time=${enda})'
  'set lon 0'
  'define sn1=ave(aa,lon=$lon1,lon=$lon2)'

n=1
while ( n <= ${nexp} )
  f1=(n-1)*2+1
  f2=(n-1)*2+2
  m=n+1

  'set lon $lon1 $lon2'
  'define aa=${scal}*(ave(${var}.'%f1', time=${sata},time=${enda})-ave(${var}.'%f2', time=${satg},time=${endg}))'
  'set lon 0'
  'define sn'%m'=ave(aa,lon=$lon1,lon=$lon2)'

 n=n+1
endwhile

*------------------------
*--find maximum and minmum values of control/first run 
   cmax=-10000000.0; cmin=10000000.0
    'set gxout stat'
    'd sn1'  
    range=sublin(result,9); zmin=subwrd(range,5); zmax=subwrd(range,6)
    ln=sublin(result,7); wd=subwrd(ln,8); b=substr(wd,1,3)
    if( b>0 )
      if(zmax > cmax); cmax=zmax; endif
      if(zmin < cmin); cmin=zmin; endif
    endif
   dist=cmax-cmin; cmin=cmin+0.1*dist; cmax=cmax-0.1*dist
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6); cint=10*substr((cmax-cmin)/100,1,4)
   if (cint = 0); cint=substr((cmax-cmin)/10,1,4); endif
   if (cint = 0); cint=0.1*substr((cmax-cmin),1,4); endif
   if (cint = 0); cint=0.01*substr((cmax-cmin)*10,1,4); endif
   say 'cmin cmax cint 'cmin' 'cmax' 'cint
    aa1=cmin; aa2=cmin+cint; aa3=aa2+cint; aa4=aa3+cint; aa5=aa4+cint; aa6=aa5+cint
    aa7=aa6+cint; aa8=aa7+cint; aa9=aa8+cint; aa10=aa9+cint; aa11=aa10+cint


*--find maximum and minmum values for analysis increment and difference map
   cmax=-10000000.0; cmin=10000000.0
   i=2
   while (i <= $nplot)
    'set gxout stat'
    'd sn'%i
    range=sublin(result,9); zmin=subwrd(range,5); zmax=subwrd(range,6)
    if(zmax > cmax); cmax=zmax; endif
    if(zmin < cmin); cmin=zmin; endif
   i=i+1
   endwhile
   dist=cmax-cmin; cmin=cmin+0.1*dist; cmax=cmax-0.1*dist
   if(cmin >=0); cmin=-0.1*dist;endif
   if(cmax <=0); cmax=0.1*dist; endif
     if(cmax > -cmin); cmin=-cmax ; endif
     if(-cmin > cmax); cmax=-cmin ; endif
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6)
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
     cp0=0.25*cintp; cps=0.5*cintp; cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
     cm0=-cp0; cms=-cps; cm1=-cp1; cm2=-cp2; cm3=-cp3; cm4=-cp4; cm5=-cp5
   say 'cmin cmax cintm cintp 'cmin' 'cmax' 'cintm' 'cintp
*------------------------

  nframe=$nplot
  nframe2=2; nframe3=4;
  ymax0=9.7;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nplot =2);  ylen=-4.0; ygap=-0.7; endif
  if($nplot >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nplot >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nplot >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

  i=1
  while ( i <= nframe )
  'set gxout stat'  ;*compute mean over area and good points
  'd sn'%i
    icx=1; if (i > nframe2); icx=2; endif
    if (i > nframe3); icx=3; endif
    if (i > nframe4); icx=4; endif
    xmin=xmin0+(icx-1)*(xlen+xgap)
    xmax=xmin+xlen
    icy=i; if (i > nframe2); icy=i-nframe2; endif
    if (i > nframe3); icy=i-nframe3; endif
    if (i > nframe4); icy=i-nframe4; endif
    ymax=ymax0+(icy-1)*(ylen+ygap)
    ymin=ymax+ylen
    titlx=xmin+0.05
    titly=ymax+0.08
    'set parea 'xmin' 'xmax' 'ymin' 'ymax

    'run $gradsutil/rgbset.gs'
    'set xlopts 1 4 0.0'
    'set ylopts 1 4 0.0'
      if($nplot <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nplot >2 & $nplot <=4)
        if(i=2|i=$nplot);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nplot >4 & $nplot <=6)
        if(i=3|i=$nplot);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nplot >=7)
        if(i=4|i=$nplot);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set mproj latlon'
    'set mproj scaled'
    'set zlog on'
*   'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set ylevs 1000 800 500 300 200 100 70 50 30 20 10 7 5 3 2 1'
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cm0' 0 'cp0' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols 49    46    42   39    37    34     32   0  0   22    24    26    29   73     76   79'
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1); 'set rbcols 49   46    43    39    36    33    73   76     79    23     25    27   29  ';endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cm0' 0 'cp0' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set string 1 bl 7'
    'set strsiz 0.18 0.18'
    if(i=1); 'draw string 'titlx' 'titly '   A, 'mdc.1; endif
    if(i=2); 'draw string 'titlx' 'titly ' A-B, 'mdc.1; endif
    k=i-1
    if(i>2); 'draw string 'titlx' 'titly ' A-B, 'mdc.k; endif
*   if(i>2); 'draw string 'titlx' 'titly ' A-B, 'mdc.k'-'mdc.1; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.45 $xdump Analysis Increments, ${varname}'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.21 [${cyclist}] Cycles, ${sata} ~ ${enda}'
  'set strsiz 0.15 0.15'
  if($nplot >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.40'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.4'
  endif

  'printim ${var}_zmean_bias.png png x700 y680'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}_bias.gs" &
sleep 60



#.........................
# zonal mean increment RMS
#.........................
cat >${var}_rms.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1a'
  'open $ctl1g'
   mdc.1=${sname[1]}
if  ($nexp >1)
  'open $ctl2a'
  'open $ctl2g'
   mdc.2=${sname[2]}
endif     
if  ($nexp >2)
  'open $ctl3a'
  'open $ctl3g'
   mdc.3=${sname[3]}
endif     
if  ($nexp >3)
  'open $ctl4a'
  'open $ctl4g'
   mdc.4=${sname[4]}
endif     
if  ($nexp >4)
  'open $ctl5a'
  'open $ctl5g'
   mdc.5=${sname[5]}
endif     
if  ($nexp >5)
  'open $ctl6a'
  'open $ctl6g'
   mdc.6=${sname[6]}
endif     
if  ($nexp >6)
  'open $ctl7a'
  'open $ctl7g'
   mdc.7=${sname[7]}
endif     
if  ($nexp >7)
  'open $ctl8a'
  'open $ctl8g'
   mdc.8=${sname[8]}
endif     
*-----

  'set lat $lat1 $lat2'
  'set lev $lev1 $lev2'
  'set t 1  '

*----control run analysis
  'set lon $lon1 $lon2'
  'define aa=${scal}*ave(${var}.1, time=${sata},time=${enda})'
  'set lon 0'
  'define sn1=ave(aa,lon=$lon1,lon=$lon2)'

n=1
while ( n <= ${nexp} )
  f1=(n-1)*2+1
  f2=(n-1)*2+2
  m=n+1

  if(n=1) 
   'set lon $lon1 $lon2'
   'define aa=${scal}*sqrt(ave((${var}.'%f1'-${var}.'%f2'(t-1))*(${var}.'%f1'-${var}.'%f2'(t-1)), time=${sata},time=${enda}))'
    'set lon 0'
   'define sn'%m'=ave(aa,lon=$lon1,lon=$lon2)'
  endif
  if(n>1) 
   'set lon $lon1 $lon2'
   'define bb=${scal}*sqrt(ave((${var}.'%f1'-${var}.'%f2'(t-1))*(${var}.'%f1'-${var}.'%f2'(t-1)), time=${sata},time=${enda}))-sn2'
    'set lon 0'
   'define sn'%m'=ave(bb,lon=$lon1,lon=$lon2)'
  endif
 n=n+1
endwhile

*------------------------
*--find maximum and minmum values of control analysis itself
   cmax=-10000000.0; cmin=10000000.0
    'set gxout stat'
    'd sn1'  
    range=sublin(result,9); zmin=subwrd(range,5); zmax=subwrd(range,6)
    ln=sublin(result,7); wd=subwrd(ln,8); b=substr(wd,1,3)
    if( b>0 )
      if(zmax > cmax); cmax=zmax; endif
      if(zmin < cmin); cmin=zmin; endif
    endif
   dist=cmax-cmin; cmin=cmin+0.1*dist; cmax=cmax-0.1*dist
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6); cint=10*substr((cmax-cmin)/100,1,4)
   if (cint = 0); cint=substr((cmax-cmin)/10,1,4); endif
   if (cint = 0); cint=0.1*substr((cmax-cmin),1,4); endif
   if (cint = 0); cint=0.01*substr((cmax-cmin)*10,1,4); endif
   say 'cmin cmax cint 'cmin' 'cmax' 'cint
    aa1=cmin; aa2=cmin+cint; aa3=aa2+cint; aa4=aa3+cint; aa5=aa4+cint; aa6=aa5+cint
    aa7=aa6+cint; aa8=aa7+cint; aa9=aa8+cint; aa10=aa9+cint; aa11=aa10+cint


*------------------------
*--find maximum and minmum values of the difference of RMS Increments between exp and control
   cmax=-10000000.0; cmin=10000000.0
   i=2
   while (i <= $nplot)
    'set gxout stat'
    'd sn'%i
    range=sublin(result,9); zmin=subwrd(range,5); zmax=subwrd(range,6)
    if(zmax > cmax); cmax=zmax; endif
    if(zmin < cmin); cmin=zmin; endif
   i=i+1
   endwhile
   dist=cmax-cmin; cmin=cmin+0.1*dist; cmax=cmax-0.1*dist
   if(cmin >=0); cmin=-0.1*dist;endif
   if(cmax <=0); cmax=0.1*dist; endif
     if(cmax > -cmin); cmin=-cmax ; endif
     if(-cmin > cmax); cmax=-cmin ; endif
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6)
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
     cpd=0.01*cintp; cpc=0.05*cintp; cpb=0.1*cintp; cpa=0.5*cintp
     cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
     cmd=-cpd; cmc=-cpc; cmb=-cpb; cma=-cpa; cm1=-cp1; cm2=-cp2; cm3=-cp3; cm4=-cp4; cm5=-cp5
   say 'cmin cmax cintm cintp 'cmin' 'cmax' 'cintm' 'cintp
*------------------------

  nframe=$nplot
  nframe2=2; nframe3=4;
  ymax0=9.7;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nplot =2);  ylen=-4.0; ygap=-0.7; endif
  if($nplot >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nplot >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nplot >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

  i=1
  while ( i <= nframe )
  'set gxout stat'  ;*compute mean over area and good points
  'd sn'%i
    icx=1; if (i > nframe2); icx=2; endif
    if (i > nframe3); icx=3; endif
    if (i > nframe4); icx=4; endif
    xmin=xmin0+(icx-1)*(xlen+xgap)
    xmax=xmin+xlen
    icy=i; if (i > nframe2); icy=i-nframe2; endif
    if (i > nframe3); icy=i-nframe3; endif
    if (i > nframe4); icy=i-nframe4; endif
    ymax=ymax0+(icy-1)*(ylen+ygap)
    ymin=ymax+ylen
    titlx=xmin+0.05
    titly=ymax+0.08
    'set parea 'xmin' 'xmax' 'ymin' 'ymax

    'run $gradsutil/rgbset.gs'
    'set xlopts 1 4 0.0'
    'set ylopts 1 4 0.0'
      if($nplot <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nplot >2 & $nplot <=4)
        if(i=2|i=$nplot);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nplot >4 & $nplot <=6)
        if(i=3|i=$nplot);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nplot >=7)
        if(i=4|i=$nplot);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set mproj latlon'
    'set mproj scaled'
    'set zlog on'
*   'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set ylevs 1000 800 500 300 200 100 70 50 30 20 10 7 5 3 2 1'
    'set clevs    'cm2' 'cm1' 'cma' 'cmb' 'cmc' 'cmd' 0 'cpd' 'cpc' 'cpb' 'cpa' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols  49   45    42    39    36     33    0  0    21     23   25    27     74    79    53   56    59'
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1); 'set rbcols 49   46    43    39    36    33    73   76     79    23     25    27   29  ';endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs    'cm2' 'cm1' 'cma' 'cmb' 'cmc' 'cmd' 0 'cpd' 'cpc' 'cpb' 'cpa' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set string 1 bl 7'
    'set strsiz 0.18 0.18'
    if(i=1); 'draw string 'titlx' 'titly '   A, 'mdc.1; endif
    if(i=2); 'draw string 'titlx' 'titly ' RMS(A-B), 'mdc.1; endif
    k=i-1
    if(i>2); 'draw string 'titlx' 'titly ' RMS(A-B), 'mdc.k'-'mdc.1; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.45 RMS of $xdump Analysis Increments, ${varname}'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.21 [${cyclist}] Cycles, ${sata} ~ ${enda}'
  'set string 1  bc 3'
  'set strsiz 0.08 0.08'
  if($nplot >1 )
    'run $gradsutil/cbarn1.gs 1. 0 4.3 0.40'
  else
    'run $gradsutil/cbarn1.gs 1. 0 4.3 3.4'
  endif

  'printim ${var}_zmean_rms.png png x700 y680'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}_rms.gs" &
sleep 60

#-------------------------
done ;#variables
#-------------------------

nvartot=$((2*nvar))
nsleep=0; tsleep=300;  msleep=60  
while [ $nsleep -lt $msleep ];do
  sleep $tsleep; nsleep=`expr $nsleep + 1`
  nplotout=`ls *zmean*.png |wc -w`
  if [ $nplotout -eq $nvartot ]; then nsleep=$msleep; fi
done

cat << EOF >ftp_zonal
  binary
  prompt
  cd $ftpdir/2D/gdas            
  mput *zmean*.png
  quit
EOF
if [ $doftp = YES -a $CUE2RUN = $CUE2FTP ]; then
 sftp  ${webhostid}@${webhost} <ftp_zonal
 if [ $? -ne 0 ]; then
  scp -rp *zmean*.png ${webhostid}@${webhost}:$ftpdir/2D/gdas/.
 fi
fi
cp *zmean*.png $mapdir/2D/gdas/.
#rm *.gs



#--------------------------------------------
##--send plots to web server using dedicated 
##--transfer node (required by NCEP WCOSS)
if [ $doftp = "YES" -a $CUE2RUN != $CUE2FTP ]; then
#--------------------------------------------
cd $tmpdir
cat << EOF >ftp2dmap.sh
#!/bin/ksh
set -x
ssh -q -l $webhostid ${webhost} " ls -l ${ftpdir}/2D/gdas "
if [ \$? -ne 0 ]; then
 ssh -l $webhostid ${webhost} " mkdir -p $ftpdir "
 scp -rp $srcdir/html/* ${webhostid}@${webhost}:$ftpdir/.
fi
if [ -s ftp_air ]; then sftp  ${webhostid}@${webhost} < ftp_air  ;fi
if [ -s ftp_zonal ]; then sftp  ${webhostid}@${webhost} < ftp_zonal  ;fi
EOF

chmod u+x $tmpdir/ftp2dmap.sh
$SUBJOB -a $ACCOUNT -q $CUE2FTP -g $GROUP -p 1/1/S -t 0:30:00 -r 256/1 -j ftp2dmap -o ftp2dmap.out $tmpdir/ftp2dmap.sh 
#--------------------------------------------
fi
#--------------------------------------------


exit
