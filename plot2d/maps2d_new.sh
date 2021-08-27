#!/bin/ksh
set -x

#### ----------------------------------------------------------------------------------- 
###  Make lat-lon maps and zonal-mean vertical distributions. Input must be grib files 
###  on regular lat-lon grid and on isobaric layers in the vertical. For air fields,  
###  Display single-hour differences between forecasts and between forecasts and analyses.
###  Fanglin Yang, EMC/NCEP/NOAA,  September 2011
###  fanglin.yang@noaa.gov; 301-6833722            
#### ----------------------------------------------------------------------------------- 

export expnlist=${expnlist:-"pr4devb prnems1w"}             ;#experiments, up to 8; gfs will point to ops data
export caplist=${caplist:-"$expnlist"}             
export expdlist=${expdlist:-"/global/noscrub/emc.glopara/archive /global/noscrub/Fanglin.Yang/archive"} ;#data archive
export dumplist=${dumplist:-".gfs. .gfs."}            ;#file format pgb${asub}${fhr}${dump}${yyyymmdd}${cyc}
export complist=${complist:-"gyre gyre"}              ;#computers where experiments are run

export fcst_day=${fcst_day:-5}                ;#forecast day-length to verify
export cyc=${cycle:-00}                       ;#forecast cycle to verify
export cdate=${DATEST:-20160101}              ;#starting verifying date
export ndays=${ndays:-2}                      ;#number of days (cases)

export nlev=${nlev:-31}                       ;#pgb file vertical layers
export grid=${grid:-G2}                       ;#pgb file resolution, G2->2.5deg; G3->1deg; G4->0.5deg
export pbtm=${pbtm:-1000}                     ;#bottom pressure for zonal mean maps
export ptop=${ptop:-1}                        ;#top pressure for zonal mean maps
export masksfc=${masksfc:-1}                  ;#if .ne.0 then mask layers below the surface for certain plots
export difmap=${difmap:-YES}                  ;#if YES, plot differences for all but the first panel.        
export cldwat=${cldwat:-YES}                  ;#if YES, plot zonal mean proiles of all cloud hydrometers      
export autolev=${autolev:-NO}                 ;#if YES, contour levels are automatically determined by grads               

export obdata=${obdata:-/global/save/Fanglin.Yang/obdata}
export webhost=${webhost:-emcrzdm.ncep.noaa.gov}
export webhostid=${webhostid:-wx24fy}
export ftpdir=${ftpdir:-/home/people/emc/www/htdocs/gmb/$webhostid/nems/nems1w}
export doftp=${doftp:-NO}

export rundir=${rundir:-/ptmpd2/$LOGNAME/2dmaps}
if [ ! -s $rundir ]; then mkdir -p $rundir ; fi
cd $rundir || exit 8
export mapdir=${mapdir:-$rundir/web}        ;#place where maps are saved locally
if [ ! -s $mapdir ]; then mkdir -p $mapdir ; fi

export APRUN=${APRUN:-""}   ;#for running jobs on Gaea
if [ ${batch:-NO} != YES ]; then export APRUN="" ; fi
export machine=${machine:-WCOSS}
export NWPROD=${NWPROD:-/nwprod}
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export cpygb=${cpygb:-"$APRUN $NWPROD/util/exec/copygb"}

export vsdbhome=${vsdbhome:-/global/save/$LOGNAME/VRFY/vsdb}
export SUBJOB=${SUBJOB:-$vsdbhome/bin/sub_wcoss}
export ACCOUNT=${ACCOUNT:-GFS-MTN}
export CUE2RUN=${CUE2RUN:-shared}
export CUE2FTP=${CUE2FTP:-${CUE2RUN:-transfer}}
export GROUP=${GROUP:-g01}

#------------------------------------------------------------------
#------------------------------------------------------------------
srcdir=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}/plot2d
gradsutil=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}/map_util/grads
export GRADSBIN=${GRADSBIN:-/usrx/local/GrADS/2.0.2/bin}

if [ $doftp = YES -a $batch = NO ]; then
ssh -q -l $webhostid ${webhost} " ls -l ${ftpdir}/2D/d1 "
if [ $? -ne 0 ]; then
 ssh -l $webhostid ${webhost} " mkdir -p $ftpdir "
 scp -rp $srcdir/html/* ${webhostid}@${webhost}:$ftpdir/.
fi
fi
if [ ! -s $mapdir/index.html ]; then
 cp -rp $srcdir/html/* $mapdir/.
fi
 

#=============================
odir=${odir:-1}
tmpdir=$rundir/d${odir}
if [ -s $tmpdir ]; then rm -rf $tmpdir ; fi
mkdir $tmpdir ; cd $tmpdir || exit 8
#=============================

if [ $fcst_day = anl ]; then
 export fhlist="anl anl anl anl"
elif [ $fcst_day -eq 0 ]; then
 export fhlist="f00 f00 f00 f00"
else
 fhr4=`expr $fcst_day \* 24 `
 fhr3=`expr $fhr4 - 6  `
 fhr2=`expr $fhr4 - 12  `
 fhr1=`expr $fhr4 - 18  `
 if [ $fhr1 -lt 10 ]; then fhr1=0$fhr1 ; fi
 export fhlist=$(eval echo \${fhlist$fcst_day:-"f$fhr1 f$fhr2 f$fhr3 f$fhr4"})
fi

#--operational GFS only saves data on 31 layers up to 1hPa
set -A cname $caplist
set -A sname $expnlist
if [ ${sname[0]} = gfs ]; then 
 export nlev=31 
 export ptop=1
fi

#==================================================================
#-- create GrADS control files
export ctldir=${tmpdir}/ctl                                   
$srcdir/makectl.sh
set -A fhour $fhlist
fh1=${fhour[0]}; fh2=${fhour[1]}; fh3=${fhour[2]}; fh4=${fhour[3]}
if [ $fh4 != anl ]; then $srcdir/makectl_anl.sh ; fi

fma=${fma:-yes}    ;#make forecast-analysis maps
fma_map=no  
if [ $fma = yes ]; then
 if [ $fh4 = f00 -o $fh4 = f24 -o $fh4 = f48 -o $fh4 = f72 -o $fh4 = f96 -o $fh4 = f120 -o $fh4 = f144 -o $fh4 = f168 -o $fh4 = f192 \
     -o $fh4 = f216 -o $fh4 = f240 -o $fh4 = f264 -o $fh4 = f288 -o $fh4 = f312 -o $fh4 = f336 -o $fh4 = f360 -o $fh4 = f384 ]; then
     fma_map=yes
 fi
fi


#==================================================================
#-- make maps
cd $tmpdir || exit 8

mapobs=${mapobs:-yes}                  ;#compare forecast with observations (radiation, clouds and precip etc), monthly means
mapair_zonalmean=${mapair_zonalmean:-yes}  ;#compare forecasts of upper air quantities (T, U, V, Z, Q, RH, O3, CLW etc), zonal mean
mapair_layer=${mapair_layer:-yes}      ;#compare forecasts of upper air quantities (T, U, V, Z, Q, RH, O3, CLW etc), single layer
mapsfc=${mapsfc:-yes}                  ;#compare forecasts of all surface variables that are of interest

#export dayvf="Fcst Day $fcst_day ";
export dayvf="($fhlist) Fcst-Hour Average";
export dayvfa="Fcst-Hour $fh4 ";
#--------------------------------------------------------------------------

set -A mlist none Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
year=`echo $cdate |cut -c 1-4`
mon=`echo $cdate |cut -c 5-6`
day=`echo $cdate |cut -c 7-8`
monc=${mlist[$mon]}
sdate=${day}${monc}${year}

nhours=`expr $(expr $ndays \* 24) - 24 `
cdate2=`echo $($ndate +$nhours ${cdate}00) |cut -c 1-8 `
year2=`echo $cdate2 |cut -c 1-4`
mon2=`echo $cdate2 |cut -c 5-6`
day2=`echo $cdate2 |cut -c 7-8`
monc2=${mlist[$mon2]}
edate=${day2}${monc2}${year2}

##for using climatology corssing year boundaries
if [ $mon2 -lt $mon ]; then mon2=$((mon2+12)); fi


#--analysis time stamps
n=1
for hr in $fhlist; do
 fh=`echo $hr |cut -c 2-5`
 cdate_a=`$ndate +$fh ${cdate}${cyc}`    ;#first analysis time
 cdate2_a=`$ndate +$fh ${cdate2}${cyc}`   ;#last analysis time

 year_a=`echo $cdate_a |cut -c 1-4`
 mon_a=`echo $cdate_a |cut -c 5-6`
 day_a=`echo $cdate_a |cut -c 7-8`
 cyc_a=`echo $cdate_a |cut -c 9-10`
 monc_a=${mlist[$mon_a]}
 eval sdate_a${n}=${cyc_a}Z${day_a}${monc_a}${year_a}

 year2_a=`echo $cdate2_a |cut -c 1-4`
 mon2_a=`echo $cdate2_a |cut -c 5-6`
 day2_a=`echo $cdate2_a |cut -c 7-8`
 cyc2_a=`echo $cdate2_a |cut -c 9-10`
 monc2_a=${mlist[$mon2_a]}
 eval edate_a${n}=${cyc2_a}Z${day2_a}${monc2_a}${year2_a}
n=$((n+1))
done


#--define map range
area=${area:-gb}
latlon=${latlon:-"-90 90 0 360"}        ;#map area lat1, lat2, lon1 and lon2
set -A latlonc none $latlon
lat1=${latlonc[1]}; lat2=${latlonc[2]}
lon1=${latlonc[3]}; lon2=${latlonc[4]}

export nexp=`echo $expnlist |wc -w`                                  ;# number of experiments
 n=1; nn=0
 while [ $n -le $nexp ]; do
  k=1
  for fh in ${fhlist}; do
   export ctl${n}_f${k}=${ctldir}/${sname[$nn]}/${sname[$nn]}_${fh}.ctl
   if [ $fh = anl ]; then
    export ctl${n}_a${k}=${ctldir}/${sname[$nn]}/${sname[$nn]}_${fh}.ctl
   else
    export ctl${n}_a${k}=${ctldir}/${sname[$nn]}/${sname[$nn]}_${fh}_anl.ctl
   fi
   k=` expr $k + 1 `
  done
 n=` expr $n + 1 `
 nn=` expr $nn + 1 `
 done


#=====================================================================
if [ $mapsfc = "yes" ]; then
#=====================================================================
#### ------------------------------------------------------------------------ 
###  generate 2-D maps compare surface variables among different runs. No obs 
#### ------------------------------------------------------------------------ 

set -a;. ${srcdir}/vardef.sh
if [ $? -ne 0 ]; then exit; fi
set -x

#for var in  $grp_com $grp_wind $grp_rad $grp_cld $grp_soil $grp_sig $grp_pv $grp_en1 $grp_en2; do
for var in  $grp_com $grp_wind $grp_rad $grp_cld $grp_soil $grp_sig ; do

varname="$(eval echo \${vname_$var})"
varscal="$(eval echo \${scale_$var})"
varclev0="$(eval echo \${clevs0_$var})"
varcolr0="$(eval echo \${color0_$var})"
varclev="$(eval echo \${clevs_$var})"
varcolr="$(eval echo \${color_$var})"

SOILTAG=NONE
SOILTAG=`echo $var |cut -c 1-4`

#.........................
cat >${var}.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.1=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.2=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.3=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.4=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.5=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.6=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.7=${cname[6]}
endif     
if  ($nexp >7)
  'open $ctl8_f1'
  'open $ctl8_f2'
  'open $ctl8_f3'
  'open $ctl8_f4'
  mdc.8=${cname[7]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '


n=1
while ( n <= ${nexp} )
  f1=(n-1)*4+1
  f2=(n-1)*4+2
  f3=(n-1)*4+3
  f4=(n-1)*4+4
  say f1 f2 f3 f4 
   if(n=1); 'define sn'%n'=${varscal}*ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate})';endif
   if(n>1) 
    if( $difmap = YES ) 
     'define sn'%n'=${varscal}*ave((${var}.'%f1'-${var}.1 + ${var}.'%f2'-${var}.2 + ${var}.'%f3'-${var}.3 + ${var}.'%f4'-${var}.4 )/4, time=${sdate},time=${edate})'
    else
     'define sn'%n'=${varscal}*ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate})'
    endif
   endif
   if( $SOILTAG = "SOIL" ); 'define sn'%n'=maskout(sn'%n',-sn1+99.9)'; endif
  'define yn'%n'=aave(sn'%n',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile


*------------------------
if ( $autolev = YES )
*------------------------
*--find maximum and minmum values of control/first run 
   cmax=-10000000.0; cmin=10000000.0
   i=1
    'set gxout stat'
    'd sn'%i
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
*--find maximum and minmum values for difference map
   cmax=-10000000.0; cmin=10000000.0
   i=2
   while (i <= $nexp)
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
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6);
   cintm=0
     if (cintm = 0 & -cmin/50  > 0.01); cintm=10*substr(cmin/50,1,4); endif
     if (cintm = 0 & -cmin/5   > 0.01); cintm=substr(cmin/5,1,4); endif
     if (cintm = 0 & -cmin     > 0.01); cintm=0.2*substr(cmin,1,4); endif
     if (cintm = 0 & -cmin*10  > 0.01); cintm=0.02*substr(cmin*10,1,4); endif
     if (cintm = 0 & -cmin*100 > 0.01); cintm=0.002*substr(cmin*100,1,4); endif
   cms=0.5*cintm; cm1=cintm; cm2=cm1+cintm; cm3=cm2+cintm; cm4=cm3+cintm; cm5=cm4+cintm
              cm6=cm5+cintm; cm7=cm6+cintm; cm8=cm7+cintm; cm9=cm8+cintm
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
   cps=0.5*cintp; cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
              cp6=cp5+cintp; cp7=cp6+cintp; cp8=cp7+cintp; cp9=cp8+cintp
   say 'cmin cmax cintm cintp 'cmin' 'cmax' 'cintm' 'cintp
*------------------------
endif
*------------------------

  nframe=$nexp
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nexp =2);  ylen=-4.0; ygap=-0.7; endif
  if($nexp >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nexp >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nexp >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nexp <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nexp >2 & $nexp <=4)
        if(i=2|i=$nexp);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nexp >4 & $nexp <=6)
        if(i=3|i=$nexp);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nexp >=7)
        if(i=4|i=$nexp);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
   if ( $autolev = YES )
    'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 
    'set rbcols 31    33   35    37    39    43    45   47     49    23     25     27  '
   else
    'set clevs   $varclev0 '                                                            
    'set rbcols  $varcolr0 '
   endif
   if ( i>1 & $difmap = YES )
    if ( $autolev = YES )
     'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
     'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
    else
     'set clevs   $varclev '                                                            
     'set rbcols  $varcolr '
    endif
   endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
   if ( $autolev = YES )
    'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 
   else
    'set clevs   $varclev0 '                                                            
   endif
   if ( i>1 & $difmap = YES )
    if ( $autolev = YES )
     'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    else
     'set clevs   $varclev '                                                            
    endif
   endif
   if ( $difmap = YES & i=1 ); 'd sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'   'a; endif
    if(i>1)
     if ( $difmap = YES )
       'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a
     else
       'draw string 'titlx' 'titly ' 'mdc.i'  'a
     endif
    endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.55 $varname '
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.35 ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'draw string 4.3 10.15 ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nexp >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}.gs" 

#--------------------
# remove whitesapce from png files
# ImageMagic
#export PATH=$PATH:/usrx/local/imajik/bin
#export LIBPATH=/lib:/usr/lib
#export LIBPATH=$LIBPATH:/usrx/local/imajik/lib
#convert -crop 0.2x0.2 ${var}_${area}.png ${var}_${area}.png

done
#.........................

cat << EOF >ftp_sfc
  binary
  prompt
  cd $ftpdir/2D/d$odir/
  mput *.png
  quit
EOF
if [ $doftp = YES -a $CUE2RUN = $CUE2FTP ]; then
 sftp  ${webhostid}@${webhost} <ftp_sfc
 if [ $? -ne 0 ]; then
  scp -rp *.png ${webhostid}@${webhost}:$ftpdir/2D/d$odir/.
 fi
fi
cp *.png $mapdir/2D/d$odir/.
#=====================================================================
fi  ;# end of mapsfc 
#=====================================================================


#=====================================================================
if [ $mapobs = "yes"  ]; then
#=====================================================================

cloud=${cloud:-yes}           ;#plot cloud distributions, against ISCCP climatology
longw=${longw:-yes}           ;#plot longwave flux, against SRB2 climatology
solar=${solar:-yes}           ;#plot solar flux, against SRB2 climatology
preci=${preci:-yes}           ;#plot precipitation , against GPCP 
pwat=${pwat:-yes}             ;#plot column-integrated water vapor, against NVAP climatology (NASA Water Vapor Project)
t2m=${t2m:-yes}               ;#plot T2m against CPC GHCN_CAMS analysis, realtime
clwp=${clwp:-yes}             ;#plot column-integrated cloud liquid water, climatology           

#----------------------------------------------------------------------------------
if [ $cloud = "yes" ]; then
#----------------------------------------------------------------------------------
# cloud distribution

export ob_ctl=${obdata}/rad_isccp/isccp_cld8593_clim2p5.ctl
export ob_name="ISCCP"
export nmd=`expr $nexp + 1 `

for var in TCDCclm TCDChcl TCDCmcl TCDClcl ;  do
  if [ $var = "TCDCclm" ]; then varob=cldt varname="Total Cloud"; fi
  if [ $var = "TCDChcl" ]; then varob=cldh varname="High Cloud"; fi
  if [ $var = "TCDCmcl" ]; then varob=cldm varname="Middle Cloud"; fi
  if [ $var = "TCDClcl" ]; then varob=cldl varname="Low Cloud"; fi

#.........................
cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl'   
   mdc.1="${ob_name}"
  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

  'define sn1=ave(${varob},t=${mon},t=${mon2})'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+2
  f2=(n-1)*4+3
  f3=(n-1)*4+4
  f4=(n-1)*4+5
  say f1 f2 f3 f4 
  'define sn'%nn'=ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate})-sn1'
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile


  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'

    'set gxout shaded'
    'set grads off'
    'set clevs    -60 -40 -30 -20 -10 -5 5   10   20 30 40 60 '
    'set rbcols 49   46  42   39  36 32 0  22  26  29 73  76   79'
    if(i=1); 'set clevs   10 20 30 40 50 60 70 80 ' ;endif
    if(i=1); 'set rbcols 31 33 35 37 39 63 65 67  69 ' ;endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs    -60 -40 -30 -20 -10 -5 5   10   20 30 40 60 '
    if(i=1); 'set clevs   10 20 30 40 50 60 70 80 ' ;endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.14 0.14'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'85-93  'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i' - 'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs"  

#--------------------
# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png

done
#.........................

#----------------------------------------------------------------------------------
fi    ;#end of clouds
#----------------------------------------------------------------------------------


#----------------------------------------------------------------------------------
if [ $longw = "yes" ]; then
#----------------------------------------------------------------------------------
# LW flux distribution

export ob_name="SRB2"
export nmd=`expr $nexp + 1 `

for var in ULWRFsfc DLWRFsfc ULWRFtoa ;  do
  if [ $var = "ULWRFsfc" ]; then 
      ob_ctl=${obdata}/rad_srb2/clim25_LW_sfc_up.ctl
      varob=LW_sfc_up
      varname="Sfc Up LW"
  fi
  if [ $var = "DLWRFsfc" ]; then 
      ob_ctl=${obdata}/rad_srb2/clim25_LW_sfc_down.ctl
      varob=LW_sfc_down
      varname="Sfc Down LW"
  fi
  if [ $var = "ULWRFtoa" ]; then 
      ob_ctl=${obdata}/rad_srb2/clim25_LW_toa_up.ctl
      varob=LW_toa_up
      varname="TOA Up LW"
  fi

#.........................
cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl'   
   mdc.1="${ob_name}"
  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

  'define sn1=ave(${varob},t=${mon},t=${mon2})'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+2
  f2=(n-1)*4+3
  f3=(n-1)*4+4
  f4=(n-1)*4+5
  say f1 f2 f3 f4 
  'define sn'%nn'=ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate})-sn1'
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile

  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs     -60 -40 -30 -20 -10  10 20 30 40 60 '
    'set rbcols 49   46  42   39  36 32 0  22  26  29 73  76   79'
    if(i=1)
      'set clevs   50 100 150 200 250 300 350 400 ' 
      if($var = ULWRFtoa); 'set clevs   140 160 180 200 240 260 280 300' ;endif
     'set rbcols 31 33  35  37  39   63 65   67  69 ' 
    endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs     -60 -40 -30 -20 -10  10 20 30 40 60 '
    if(i=1)
      'set clevs   50 100 150 200 250 300 350 400 ' 
      if($var = ULWRFtoa); 'set clevs   140 160 180 200 240 260 280 300' ;endif
    endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'85-93   'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs" 

#--------------------
# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png
#.........................
done


#.........................
# Atmosphere LW cooling             

export ob_name="SRB2"
export nmd=`expr $nexp + 1 `

    var=LWatm
    varname="Atoms Emitted LW"
    ob_ctl1=${obdata}/rad_srb2/clim25_LW_sfc_down.ctl
    ob_ctl2=${obdata}/rad_srb2/clim25_LW_toa_up.ctl
    ob_ctl3=${obdata}/rad_srb2/clim25_LW_sfc_up.ctl

#.........................
cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl1'   
  'open $ob_ctl2'   
  'open $ob_ctl3'   
   mdc.1="${ob_name}"

  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

  'define sn1=ave(LW_sfc_down.1+LW_toa_up.2-LW_sfc_up.3,t=${mon},t=${mon2})'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+4
  f2=(n-1)*4+5
  f3=(n-1)*4+6
  f4=(n-1)*4+7
  say f1 f2 f3 f4 
  'define sfcd=ave((DLWRFsfc.'%f1' + DLWRFsfc.'%f2' + DLWRFsfc.'%f3' + DLWRFsfc.'%f4')/4, time=${sdate},time=${edate})'
  'define sfcu=ave((ULWRFsfc.'%f1' + ULWRFsfc.'%f2' + ULWRFsfc.'%f3' + ULWRFsfc.'%f4')/4, time=${sdate},time=${edate})'
  'define toau=ave((ULWRFtoa.'%f1' + ULWRFtoa.'%f2' + ULWRFtoa.'%f3' + ULWRFtoa.'%f4')/4, time=${sdate},time=${edate})'
  'define sn'%nn'=sfcd+toau-sfcu-sn1'
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile


  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs     -60 -40 -30 -20 -10 10 20 30 40 60 '
    'set rbcols 49   46  42   39  36 32 0  22  26  29 73  76   79'
    if(i=1); 'set clevs   100 120 140 160 180 200 220 240' ;endif
    if(i=1); 'set rbcols 31 33  35  37  39   63 65   67  69 ' ;endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs     -60 -40 -30 -20 -10 10 20 30 40 60 '
    if(i=1); 'set clevs   100 120 140 160 180 200 220 240' ;endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'85-93   'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs" 

#--------------------
# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png

#----------------------------------------------------------------------------------
fi    ;#end of longwave
#----------------------------------------------------------------------------------




#----------------------------------------------------------------------------------
if [ $solar = "yes" ]; then
#----------------------------------------------------------------------------------
# SW flux distribution

export ob_name="SRB2"
export nmd=`expr $nexp + 1 `

for var in USWRFtoa USWRFsfc DSWRFsfc ;  do
  if [ $var = "USWRFtoa" ]; then 
    ob_ctl=${obdata}/rad_srb2/clim25_SW_toa_up.ctl
    varob=SW_toa_up    
    varname="TOA Up SW"
  fi
  if [ $var = "USWRFsfc" ]; then 
    ob_ctl=${obdata}/rad_srb2/clim25_SW_sfc_up.ctl
    varob=SW_sfc_up    
    varname="Sfc Up SW"
  fi
  if [ $var = "DSWRFsfc" ]; then 
    ob_ctl=${obdata}/rad_srb2/clim25_SW_sfc_down.ctl
    varob=SW_sfc_down  
    varname="Sfc Down SW"
  fi

#.........................
cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl'   
   mdc.1="${ob_name}"

  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

  'define sn1=ave(${varob},t=${mon},t=${mon2})'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+2
  f2=(n-1)*4+3
  f3=(n-1)*4+4
  f4=(n-1)*4+5
  say f1 f2 f3 f4
  'define sn'%nn'=ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate})-sn1'
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile


  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs     -60 -40 -30 -20 -10  10 20 30 40 60 '
    'set rbcols 49   46  42   39  36 32 0  22  26  29 73  76   79'
    if(i=1)
      'set clevs  10  40 80 120 160 200 240 280  ' 
      if($var = DSWRFsfc); 'set clevs   10 50 100 150 200 250 300 350 ' ;endif
     'set rbcols 31 33  35  37  39   63 65   67  69 ' 
    endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs     -60 -40 -30 -20 -10  10 20 30 40 60 '
    if(i=1)
      'set clevs  10  40 80 120 160 200 240 280  ' 
      if($var = DSWRFsfc); 'set clevs   10 50 100 150 200 250 300 350 ' ;endif
    endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'85-93   'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs" 

#--------------------
# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png

#.........................
done

#.........................
# surface albedo
 var=SWalb

 ob_ctl1=${obdata}/rad_srb2/clim25_SW_toa_up.ctl
 ob_ctl2=${obdata}/rad_srb2/clim25_SW_sfc_up.ctl
 ob_ctl3=${obdata}/rad_srb2/clim25_SW_sfc_down.ctl
 ob_ctl4=${obdata}/rad_srb2/clim25_SW_toa_down.ctl

cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl1'   
  'open $ob_ctl2'   
  'open $ob_ctl3'   
  'open $ob_ctl4'   
   mdc.1="${ob_name}"

  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

  'define utoa1=ave(SW_toa_up.1, t=$mon, t=$mon2)'
  'define usfc1=ave(SW_sfc_up.2, t=$mon, t=$mon2)'
  'define dsfc1=ave(SW_sfc_down.3, t=$mon, t=$mon2)'
  'define dtoa1=ave(SW_toa_down.4, t=$mon, t=$mon2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+5
  f2=(n-1)*4+6
  f3=(n-1)*4+7
  f4=(n-1)*4+8
  say f1 f2 f3 f4 
  'define utoa'%nn'=ave((USWRFtoa.'%f1' + USWRFtoa.'%f2' + USWRFtoa.'%f3' + USWRFtoa.'%f4')/4, time=${sdate},time=${edate})'
  'define usfc'%nn'=ave((USWRFsfc.'%f1' + USWRFsfc.'%f2' + USWRFsfc.'%f3' + USWRFsfc.'%f4')/4, time=${sdate},time=${edate})'
  'define dsfc'%nn'=ave((DSWRFsfc.'%f1' + DSWRFsfc.'%f2' + DSWRFsfc.'%f3' + DSWRFsfc.'%f4')/4, time=${sdate},time=${edate})'
  n=n+1
endwhile


n=0
while ( n <= ${nexp} )
  nn=n+1
  'define sn'%nn'=maskout(usfc'%nn',usfc1-5)/maskout(dsfc'%nn' ,dsfc'%nn'-10)' 
  if(nn>1); 'define sn'%nn'=maskout(usfc'%nn',usfc1-5)/maskout(dsfc'%nn' ,dsfc'%nn'-10)-sn1' ;endif
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile

  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs     -0.06 -0.04 -0.03 -0.02 -0.01 0.01 0.02 0.03 0.04 0.06 '
    'set rbcols 49   46  42   39  36 32 0  22  26  29 73  76   79'
     if(i=1);'set clevs    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9';endif
     if(i=1);'set rbcols 71    73  76  79  21  23  25  27  28  29';endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs     -0.06 -0.04 -0.03 -0.02 -0.01 0.01 0.02 0.03 0.04 0.06 '
     if(i=1);'set clevs    0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9';endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'85-93   'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 Sfc Albedo, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs" 

# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png
#.........................


#.........................
# atmosphere absorbed SW
 var=SWatm

 ob_ctl1=${obdata}/rad_srb2/clim25_SW_toa_up.ctl
 ob_ctl2=${obdata}/rad_srb2/clim25_SW_sfc_up.ctl
 ob_ctl3=${obdata}/rad_srb2/clim25_SW_sfc_down.ctl
 ob_ctl4=${obdata}/rad_srb2/clim25_SW_toa_down.ctl

cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl1'   
  'open $ob_ctl2'   
  'open $ob_ctl3'   
  'open $ob_ctl4'   
   mdc.1="${ob_name}"

  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

  'define utoa1=ave(SW_toa_up.1, t=$mon, t=$mon2)'
  'define usfc1=ave(SW_sfc_up.2, t=$mon, t=$mon2)'
  'define dsfc1=ave(SW_sfc_down.3, t=$mon, t=$mon2)'
  'define dtoa1=ave(SW_toa_down.4, t=$mon, t=$mon2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+5
  f2=(n-1)*4+6
  f3=(n-1)*4+7
  f4=(n-1)*4+8
  say f1 f2 f3 f4 
  'define utoa'%nn'=ave((USWRFtoa.'%f1' + USWRFtoa.'%f2' + USWRFtoa.'%f3' + USWRFtoa.'%f4')/4, time=${sdate},time=${edate})'
  'define usfc'%nn'=ave((USWRFsfc.'%f1' + USWRFsfc.'%f2' + USWRFsfc.'%f3' + USWRFsfc.'%f4')/4, time=${sdate},time=${edate})'
  'define dsfc'%nn'=ave((DSWRFsfc.'%f1' + DSWRFsfc.'%f2' + DSWRFsfc.'%f3' + DSWRFsfc.'%f4')/4, time=${sdate},time=${edate})'
  n=n+1
endwhile


n=0
while ( n <= ${nexp} )
  nn=n+1
  'define sn'%nn'=dtoa1-dsfc'%nn'-utoa'%nn'+usfc'%nn
  if(nn>1); 'define sn'%nn'=dtoa1-dsfc'%nn'-utoa'%nn'+usfc'%nn'-sn1' ;endif
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile

  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs     -60 -40 -30 -20 -10 10 20 30 40 60 '
    'set rbcols 49   46  42   39  36 32 0  22  26  29 73  76   79'
    if(i=1); 'set clevs   10 30 50 70 90 110 120 130' ;endif
    if(i=1); 'set rbcols 31 33 35 37 39 63 65  67  69 ' ;endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs     -60 -40 -30 -20 -10 10 20 30 40 60 '
    if(i=1); 'set clevs   10 30 50 70 90 110 120 130' ;endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'85-93   'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 Atmos Absorbed SW, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs" 

#--------------------
# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png

#----------------------------------------------------------------------------------
fi    ;#end of solar radiation
#----------------------------------------------------------------------------------




#----------------------------------------------------------------------------------
if [ $preci = "yes" ]; then
#----------------------------------------------------------------------------------
# precipitation           

export ob_ctl=${obdata}/gpcp_mon/gpcpclim25_precip.ctl
export ob_name="GPCP"
export nmd=`expr $nexp + 1 `

for var in PRATEsfc ;  do

  if [ $var = "PRATEsfc" ]; then 
      varob=precip
      varname="Total Precip"
  fi

#.........................
cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl'   
   mdc.1="${ob_name}"
  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

  'define sn1=ave(${varob}, t=${mon},t=${mon2})'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+2
  f2=(n-1)*4+3
  f3=(n-1)*4+4
  f4=(n-1)*4+5
  say f1 f2 f3 f4 
  'define sn'%nn'=ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')*6*3600, time=${sdate},time=${edate})-sn1'
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile


  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs    -6 -4 -2 -1 -0.5 -0.1 0.1 0.5  1  2  4  6 '
    'set rbcols 49   46  42   39  36 32 0  22  26  29 73  76   79'
    if(i=1);'set clevs   0.1 0.5 1  2  3  4  5  6  7  8  9  10  12  15';endif
    if(i=1);'set rbcols 0   31  33 35 37 39 41 43 47 49 61 63 65  67  69';endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clevs     -6 -4 -2 -1 -0.5 -0.1 0.1 0.5  1  2  4  6 '
    if(i=1);'set clevs   0.1 0.5 1  2  3  4  5  6  7  8  9  10  12  15';endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'1979-2001   'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs" 

#--------------------
# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png
#.........................
done

#----------------------------------------------------------------------------------
fi    ;#end of precip
#----------------------------------------------------------------------------------




 
#----------------------------------------------------------------------------------
if [ $pwat = "yes" ]; then
#----------------------------------------------------------------------------------
# column integrated: obs -  water vapor; model: precipitable wtaer (vapor +cloud water)           

export ob_ctl=${obdata}/nvap/nvap_pwat8895_clim_tpw.ctl   
export ob_name="NVAP"
export nmd=`expr $nexp + 1 `

for var in PWATclm ;  do
      varob=tpw
      varname="Column Water Vapor (kg/m^2)"
      scal=1

#.........................
cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl'   
   mdc.1="${ob_name}"
  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

* water vapor only
  'define sn1=ave(${scal}*${varob}, t=${mon}, t=${mon2})'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+2
  f2=(n-1)*4+3
  f3=(n-1)*4+4
  f4=(n-1)*4+5
  say f1 f2 f3 f4 
  'define clwp=${scal}*ave((CWATclm.'%f1' + CWATclm.'%f2' + CWATclm.'%f3' + CWATclm.'%f4')/4, time=${sdate},time=${edate})'
  'define sn'%nn'=${scal}*ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate})-clwp-sn1'
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile


  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs     -6 -4 -3 -2 -1   1  2  3 4  6 '
    'set rbcols 49   46  42   39  36 32 0  22  26  29 73  76   79'
    if(i=1);'set clevs    1    5 10 15 20 25 30 35 40 45 50 55 60 65';endif
    if(i=1);'set rbcols 0   31  33 35 37 39 41 43 47 49 61 63 65 67  69';endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clevs     -6 -4 -3 -2 -1   1  2  3 4  6 '
    if(i=1);'set clevs    1    5 10 15 20 25 30 35 40 45 50 55 60 65';endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'1988-1995   'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs" 

#--------------------
# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png
#.........................
done

#----------------------------------------------------------------------------------
fi    ;#end of water vapor
#----------------------------------------------------------------------------------



#----------------------------------------------------------------------------------
if [ $clwp = "yes" ]; then
#----------------------------------------------------------------------------------
# column integrated cloud water (obs: liquid, g/m**2;    model: liquid+ice, kg/m**2)

export ob_ctl=${obdata}/clwp/UWsic_CLWP_clim19882007.ctl
export ob_name="UWisc"
export nmd=`expr $nexp + 1 `

for var in CWATclm ;  do
      varob=clwp
      varname="Obs CLWP & Fcst CLWP+CIWP (g/m^2)"
      scal=1000

#.........................
cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl'   
   mdc.1="${ob_name}"
  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

  'define sn1=ave(${varob}, t=${mon}, t=${mon2})'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+2
  f2=(n-1)*4+3
  f3=(n-1)*4+4
  f4=(n-1)*4+5
  say f1 f2 f3 f4 
  'define sn'%nn'=maskout(${scal}*ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate}),sn1)'
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile


  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
*   'set clevs     -70 -50 -30 -20  -10  10  20 30 50 70'
*   'set rbcols 49   48  46   44  42    0   21 23  25 27  29'
*   if(i=1); 'set clevs      0 10 30  50 70 90 110 130';endif
*   if(i=1); 'set rbcols   15 33 36 39  21 23 25 27  29';endif
      'set clevs      0 10 30  50 70 90 110 130'
      'set rbcols   15 33 36 39  21 23 25 27  29'
    'd sn'i 
*
    'set gxout contour'
    'set clopts 1 4 0.07'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clevs     -70 -50 -30 -20  -10  10  20 30 50 70'
    if(i=1); 'set clevs      0 10 30  50 70 90 110 130';endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.12 0.12'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1' 1988-2007 CLWP  'a; endif
*   if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'(CLWP+CIWP)-'mdc.1'  'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i' (CLWP+CIWP)  'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs" 

#--------------------
# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png
#.........................
done

#----------------------------------------------------------------------------------
fi    ;#end of water vapor
#----------------------------------------------------------------------------------


#----------------------------------------------------------------------------------
if [ $t2m = "yes" ]; then
#----------------------------------------------------------------------------------
# precipitation           

export ob_ctl=${obdata}/ghcn_cams_old/ghcn_cams_1948_cur_2.5.ctl     
export ob_name="GHCN_CAMS"
export nmd=`expr $nexp + 1 `

for var in TMP2m ;  do

  if [ $var = "TMP2m" ]; then 
      varob=tmp2m
      varname="T2m"
  fi

#.........................
cat >${var}ob.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ob_ctl'   
   mdc.1="${ob_name}"
  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.2=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.3=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.4=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.5=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.6=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.7=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.8=${cname[6]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2 '
  'set t 1  '

  'define sn1=ave(${varob}-273.15, time=$monc$year, time=$monc2$year2 )'
  'define yn1=aave(sn1,lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

n=1
while ( n <= ${nexp} )
  nn=n+1
  f1=(n-1)*4+2
  f2=(n-1)*4+3
  f3=(n-1)*4+4
  f4=(n-1)*4+5
  say f1 f2 f3 f4 
  'define sn'%nn'=ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate})-273.15-sn1'
  'define yn'%nn'=aave(sn'%nn',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile


  nframe=$nmd
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nmd =2);  ylen=-4.0; ygap=-0.7; endif
  if($nmd >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nmd >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nmd >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nmd <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nmd >2 & $nmd <=4)
        if(i=2|i=$nmd);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nmd >4 & $nmd <=6)
        if(i=3|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nmd >=7)
        if(i=4|i=$nmd);'set xlopts 1 4 0.11';endif
        if(i<=4);'set ylopts 1 4 0.11';endif
      endif
    'set clopts 1 4 0.09'
    'set grid off'
*   'set zlog on'
*   'set mproj latlon'
    'set mproj scaled'
*    'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs    -15 -10 -8 -6 -4 -2 -1  1  2  4  6 8  10 15'
    'set rbcols 49  47  44  41 39 36 33  0 21 24 26 29 72 76 79'
    if(i=1);'set clevs   -40 -35 -30 -25 -20 -15 -10 -5  0  5  10 15 20 25 30 35 37';endif
    if(i=1);'set rbcols 49  47  45  43  39 37  35   33 31 73 75 77 79 21 23 25 27 29';endif
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clevs    -15 -10 -8 -6 -4 -2 -1  1  2  4  6 8  10 15'
    if(i=1);'set clevs   -40 -35 -30 -25 -20 -15 -10 -5  0  5  10 15 20 25 30 35 37';endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1' 'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nmd >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}ob_${area}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ${var}ob.gs" 

#--------------------
# remove whitesapce from png files
#convert -crop 0.2x0.2 ${var}ob_${area}.png ${var}ob_${area}.png
#.........................
done

#----------------------------------------------------------------------------------
fi    ;#end of t2m
#----------------------------------------------------------------------------------

cat << EOF >ftp_obs
  binary
  prompt
  cd $ftpdir/2D/d$odir
  mput *ob*.png
  quit
EOF
if [ $doftp = YES -a $CUE2RUN = $CUE2FTP ]; then
 sftp  ${webhostid}@${webhost} <ftp_obs
 if [ $? -ne 0 ]; then
  scp -rp *ob*.png ${webhostid}@${webhost}:$ftpdir/2D/d$odir/.
 fi
fi
cp *.png $mapdir/2D/d$odir/.
#=====================================================================
fi    ;# end of mapobs            
#=====================================================================


#=====================================================================
if [ $mapair_layer = "yes" ]; then
#=====================================================================

#### ---------------------------------------------------------- 
###  generate 2D maps on specific layers of the air. No obs 
#### ---------------------------------------------------------- 

#varlist="TMPprs HGTprs O3MRprs RHprs  UGRDprs VGRDprs VVELprs SPFHprs CLWMRprs ICMRprs SNMRprs GRLEprs RWMRprs"
varlist="TMPprs HGTprs O3MRprs RHprs  UGRDprs VGRDprs VVELprs SPFHprs CLWMRprs ICMRprs SNMRprs GRLEprs RWMRprs"
if [ $cldwat = NO -o $cldwat = no ]; then
  varlist="TMPprs HGTprs O3MRprs RHprs  UGRDprs VGRDprs VVELprs SPFHprs"
fi

for var in  $varlist ; do

 levlist="1000 850 700 500 200 100 70 50 30 20 10 5 1 0.5 0.1 0.05 0.01"
 if [ ${sname[0]} = gfs ]; then 
    levlist="1000 850 700 500 200 100 70 50 30 20 10 5 1"
 fi

 if [ $var = RHprs -o $var = CLWMRprs -o  $var = ICMRprs -o  $var = SNMRprs -o $var = GRLEprs -o  $var = RWMRprs ]; then
   levlist="1000 850 700 500 200 100 70 50"
 fi

for lev in $levlist ; do

if [ $var = "TMPprs" ];   then varname="Temp (K)"            scal=1            ; fi
if [ $var = "ABSVprs" ];  then varname="Vorticity"           scal=1000         ; fi
if [ $var = "CLWMRprs" ]; then varname="Liquid Cloud (ppmg)" scal=1000000      ; fi
if [ $var = "ICMRprs" ];  then varname="Ice Cloud (ppmg)"    scal=1000000      ; fi
if [ $var = "SNMRprs" ];  then varname="Snow (ppmg)"         scal=1000000      ; fi
if [ $var = "GRLEprs" ];  then varname="Graupel (ppmg)"      scal=1000000      ; fi
if [ $var = "RWMRprs" ];  then varname="Rain Water (ppmg)"   scal=1000000      ; fi
if [ $var = "HGTprs" ];   then varname="HGT (m)"             scal=1            ; fi
if [ $var = "O3MRprs" ];  then varname="O3 (ppmg)"           scal=1000000      ; fi
if [ $var = "RHprs" ];    then varname="RH "                 scal=1            ; fi
if [ $var = "SPFHprs" ];  then varname="Q (1E-6 kg/kg)"      scal=1000000      ; fi
if [ $var = "UGRDprs" ];  then varname="U (m/s)"             scal=1            ; fi
if [ $var = "VGRDprs" ];  then varname="V (m/s)"             scal=1            ; fi
if [ $var = "VVELprs" ];  then varname="W (mb/hr)"           scal=36           ; fi

#...........................
if [ $fma_map = yes ]; then
nplot=$((2*nexp))
#.........................
cat >${var}${lev}.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1_f4'
  'open $ctl1_a4'
   mdc.1=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f4'
  'open $ctl2_a4'
  mdc.2=${cname[1]}
endif
if  ($nexp >2)
  'open $ctl3_f4'
  'open $ctl3_a4'
  mdc.3=${cname[2]}
endif
if  ($nexp >3)
  'open $ctl4_f4'
  'open $ctl4_a4'
  mdc.4=${cname[3]}
endif
if  ($nexp >4)
  'open $ctl5_f4'
  'open $ctl5_a4'
  mdc.5=${cname[4]}
endif
if  ($nexp >5)
  'open $ctl6_f4'
  'open $ctl6_a4'
  mdc.6=${cname[5]}
endif
if  ($nexp >6)
  'open $ctl7_f4'
  'open $ctl7_a4'
  mdc.7=${cname[6]}
endif
if  ($nexp >7)
  'open $ctl8_f4'
  'open $ctl8_a4'
  mdc.8=${cname[7]}
endif

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2'
  'set lev $lev'
  'set t 1  '

n=1
while ( n <= ${nexp} )
  f4=(n-1)*2+1
  a4=(n-1)*2+2

   'set lon $lon1 $lon2'
   'define fc4=${scal}*ave(${var}.'%f4', time=${sdate},time=${edate})'
   'define an4=${scal}*ave(${var}.'%a4', time=${sdate_a4},time=${edate_a4})'

  if(n=1)
   'define sn1=${scal}*ave(${var}.1, time=${sdate},time=${edate})'
  else
   'define sn'%n'=${scal}*ave(${var}.'%f4' - ${var}.1, time=${sdate},time=${edate})'
  endif
  'define yn'%n'=aave(sn'%n',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

  m=${nexp}+n
  'define sn'%m'=fc4-an4 '
  'define yn'%m'=aave(sn'%m',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

  n=n+1
endwhile


*------------------------
*--find maximum and minmum values of control/first run 
   cmax=-10000000.0; cmin=10000000.0
   i=1
    'set gxout stat'
    'd sn'%i
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
*--find maximum and minmum values for difference map
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
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6);
   cintm=0
     if (cintm = 0 & -cmin/50  > 0.01); cintm=10*substr(cmin/50,1,4); endif
     if (cintm = 0 & -cmin/5   > 0.01); cintm=substr(cmin/5,1,4); endif
     if (cintm = 0 & -cmin     > 0.01); cintm=0.2*substr(cmin,1,4); endif
     if (cintm = 0 & -cmin*10  > 0.01); cintm=0.02*substr(cmin*10,1,4); endif
     if (cintm = 0 & -cmin*100 > 0.01); cintm=0.002*substr(cmin*100,1,4); endif
   cms=0.5*cintm; cm1=cintm; cm2=cm1+cintm; cm3=cm2+cintm; cm4=cm3+cintm; cm5=cm4+cintm
              cm6=cm5+cintm; cm7=cm6+cintm; cm8=cm7+cintm; cm9=cm8+cintm
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
   cps=0.5*cintp; cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
              cp6=cp5+cintp; cp7=cp6+cintp; cp8=cp7+cintp; cp9=cp8+cintp
   say 'cmin cmax cintm cintp 'cmin' 'cmax' 'cintm' 'cintp
*------------------------

  nframe=$nplot
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
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
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1); 'set rbcols 31    33   35    37    39    43    45   47     49    21     23    25   27  ';endif
    if ( $var= "TMPprs" & i > 1 )
      'set clevs   -4     -3    -2    -1   -0.5   -0.1  0.1   0.5   1     2     3     4'
      'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
    endif
    if ( $var= "VVELprs" )
      'set clevs   -4    -3      -2   -1    -0.5   -0.1  0.1   0.5   1     2     3    4 '  
      'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
      if(i=1); 'set clevs   -4    -3      -2   -1    -0.5   -0.1  0.1   0.5   1     2     3    4 '  ;endif
      if(i=1); 'set rbcols 49    47    45    43    0   73  75  77  79'; endif
    endif
    if ( $var= "UGRDprs" )
     'set clevs   -10   -7   -5  -3   -2   -1   1  2  3  5  7  10'  
     'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
     if(i=1); 'set clevs    -100   -70   -50  -30   -20   -10  -5     5  10  20  30  50  70  100'  ;endif
     if(i=1); 'set rbcols 49    47    45    43     37   35   33   0      63  65  67  73  75  77  79'; endif
    endif
    if ( $var= "VGRDprs" )
     'set clevs   -10   -7   -5  -3   -2   -1  -0.5 -0.2 0.2  0.5  1  2  3  5  7  10'  
     'set rbcols 49    46   44  42   39   36  34   32    0     22    24   26    29   73  75   77   79'
     if(i=1); 'set clevs     -50  -30   -20    -10  -5     -1   1   5  10  20  30  50   '  ;endif
     if(i=1); 'set rbcols 49    47    45    37   35   33   0  63  65  67 75  77  79'; endif
    endif
    if ( $var= "RHprs" )
     'set clevs   -50   -40  -30   -20   -10   -5    5   10    20    30    40   50'  
     'set rbcols 49   46    42   39    36    32    0     22    26    29   73     76   79'
     if(i=1); 'set clevs     10  30  50  70  90 '  ;endif
     if(i=1); 'set rbcols  0   33  35  37  43  45 '; endif
    endif
    if ( $var= "CLWMRprs" | $var= "ICMRprs" | $var= "SNMRprs" | $var= "GRLEprs" | $var= "RWMRprs" )
     'set clevs   -40  -20   -10   -6   -3  -1 -0.1  0.1  1   3   6    10    20    40 '  
     'set rbcols 4    46    42   39    36  34   32    0     22  24  26    29   73     76   79'
     if(i=1); 'set clevs    0.5  1  5   10   20   40  60   80 100 120 140'  ;endif
     if(i=1); 'set rbcols  0   63 65  67  69   73   75  77   79  33  35  37'; endif
    endif
*   'set ylevs 1000 700 500 300 200 100 70 50 30 20 10 7 5 3 2 1'
    'd smth9(sn'%i')' 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if ( $var= "VVELprs" )
      'set clevs   -4    -3      -2   -1    -0.5   -0.1  0.1   0.5   1     2     3    4 '  
       if(i=1); 'set clevs   -4    -3      -2   -1    -0.5   -0.1  0.1   0.5   1     2     3    4 '  ;endif
     endif
    if ( $var= "UGRDprs" )
     'set clevs   -10   -7   -5  -3   -2   -1   1  2  3  5  7  10'  
     if(i=1); 'set clevs    -100   -70   -50  -30   -20   -10  -5     5  10  20  30  50  70  100'  ;endif
    endif
    if ( $var= "VGRDprs" )
     'set clevs   -10   -7   -5  -3   -2   -1  -0.5 -0.2 0.2  0.5  1  2  3  5  7  10'  
     if(i=1); 'set clevs     -50  -30   -20    -10  -5     -1   1   5  10  20  30  50   '  ;endif
    endif
    if ( $var= "RHprs" )
     'set clevs   -50   -40  -30   -20   -10   -5    5   10    20    30    40   50'  
     if(i=1); 'set clevs     10  30  50  70  90 '  ;endif
    endif
    if ( $var= "CLWMRprs" | $var= "ICMRprs" | $var= "SNMRprs" | $var= "GRLEprs" | $var= "RWMRprs" )
     'set clevs   -40  -20   -10   -6   -3  -1 -0.1  0.1  1   3   6    10    20    40 '  
     if(i=1); 'set clevs    0.5  1  5   10   20   40  60   80 100 120 140'  ;endif
    endif
    if(i=1);'d smth9(sn'%i')' ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'  'a; endif
    if(i>1 & i<=$nexp); 'draw string 'titlx' 'titly ' 'mdc.i' - 'mdc.1 ; endif
    if(i>$nexp);
     j=i-$nexp
     'draw string 'titlx' 'titly ' 'mdc.j' - analysis'
    endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 ${lev}hPa $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvfa}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nplot >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}${lev}.png png x700 y700'
  'set vpage off'
'quit'
EOF1

#...........................
else                           
#.........................

cat >${var}${lev}.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.1=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.2=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.3=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.4=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.5=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.6=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.7=${cname[6]}
endif     
if  ($nexp >7)
  'open $ctl8_f1'
  'open $ctl8_f2'
  'open $ctl8_f3'
  'open $ctl8_f4'
  mdc.8=${cname[7]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2'
  'set lev $lev'
  'set t 1  '


n=1
while ( n <= ${nexp} )
  f1=(n-1)*4+1
  f2=(n-1)*4+2
  f3=(n-1)*4+3
  f4=(n-1)*4+4
  say f1 f2 f3 f4 

  ps=0.0; cutoff=800
  if( $lev < 800 ); cutoff=$lev ; endif
  if( $masksfc > 0 )                
   'define ps=0.01*ave((PRESsfc.'%f1' + PRESsfc.'%f2' + PRESsfc.'%f3' + PRESsfc.'%f4')/4, time=${sdate},time=${edate})-'%cutoff
   'define sn'%n'=maskout(${scal}*ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate}),ps)'
  else
   'define sn'%n'=(${scal}*ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate}))'
  endif


  if( $difmap = YES & n>1 ) 
   if( $masksfc > 0 )                
    'define sn'%n'=maskout(${scal}*ave((${var}.'%f1'-${var}.1 + ${var}.'%f2'-${var}.2 + ${var}.'%f3'-${var}.3 + ${var}.'%f4'-${var}.4 )/4, time=${sdate},time=${edate}),ps)'
   else
    'define sn'%n'=(${scal}*ave((${var}.'%f1'-${var}.1 + ${var}.'%f2'-${var}.2 + ${var}.'%f3'-${var}.3 + ${var}.'%f4'-${var}.4 )/4, time=${sdate},time=${edate}))'
   endif
  endif
  'define yn'%n'=aave(sn'%n',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'

  n=n+1
endwhile


*------------------------
*--find maximum and minmum values of control/first run 
   cmax=-10000000.0; cmin=10000000.0
   i=1
    'set gxout stat'
    'd sn'%i
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
*--find maximum and minmum values for difference map
   cmax=-10000000.0; cmin=10000000.0
   i=2
   while (i <= $nexp)
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
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6);
   cintm=0
     if (cintm = 0 & -cmin/50  > 0.01); cintm=10*substr(cmin/50,1,4); endif
     if (cintm = 0 & -cmin/5   > 0.01); cintm=substr(cmin/5,1,4); endif
     if (cintm = 0 & -cmin     > 0.01); cintm=0.2*substr(cmin,1,4); endif
     if (cintm = 0 & -cmin*10  > 0.01); cintm=0.02*substr(cmin*10,1,4); endif
     if (cintm = 0 & -cmin*100 > 0.01); cintm=0.002*substr(cmin*100,1,4); endif
   cms=0.5*cintm; cm1=cintm; cm2=cm1+cintm; cm3=cm2+cintm; cm4=cm3+cintm; cm5=cm4+cintm
              cm6=cm5+cintm; cm7=cm6+cintm; cm8=cm7+cintm; cm9=cm8+cintm
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
   cps=0.5*cintp; cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
              cp6=cp5+cintp; cp7=cp6+cintp; cp8=cp7+cintp; cp9=cp8+cintp
   say 'cmin cmax cintm cintp 'cmin' 'cmax' 'cintm' 'cintp
*------------------------

  nframe=$nexp
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nexp =2);  ylen=-4.0; ygap=-0.7; endif
  if($nexp >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nexp >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nexp >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nexp <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nexp >2 & $nexp <=4)
        if(i=2|i=$nexp);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nexp >4 & $nexp <=6)
        if(i=3|i=$nexp);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nexp >=7)
        if(i=4|i=$nexp);'set xlopts 1 4 0.11';endif
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

    'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 
    'set rbcols 31    33   35    37    39    43    45   47     49    21     23    25   27  '
    if ( $var= "VVELprs" )
      'set clevs    -4    -3   -2   -1    -0.5   -0.1  0.1   0.5   1     2     3    4 '  
      'set rbcols 49    47   45   43    37   33      0     63   65   67     73   76  79'
    endif
    if ( $var= "UGRDprs" )
     'set clevs    -100   -70   -50  -30   -20   -10  -5     5  10  20  30  50  70  100' 
     'set rbcols 49    47    45    43     37   35   33   0      63  65  67  73  75  77  79'
    endif
    if ( $var= "VGRDprs" )
     'set clevs     -50  -30   -20    -10  -5     -1   1   5    10  20  30  50   '  
     'set rbcols 49    47    45    37   35    33     0    63  65  67 75  77  79'
    endif
    if ( $var= "RHprs" )
     'set clevs     10  30  50  70  90 '  
     'set rbcols  0   33  35  37  43  45 '
    endif
    if ( $var= "CLWMRprs" | $var= "ICMRprs" | $var= "SNMRprs" | $var= "GRLEprs" | $var= "RWMRprs" )
     'set clevs    0.5  1  5   10   20   40  60   80 100 120 140' 
     'set rbcols  0   63 65  67  69   73   75  77   79  33  35  37'
    endif


    if( $difmap = YES & i>1 ) 
     'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
     'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
     if ( $var= "HGTprs")
      'set clevs    -20   -15   -10   -6    -3     -1   1     3     6      10   15   20'
      'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
     endif
     if ( $var= "TMPprs")
      'set clevs   -4     -3    -2    -1   -0.5   -0.1  0.1   0.5   1     2     3     4'
      'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
     endif
     if ( $var= "VVELprs" )
      'set clevs   -4    -3      -2   -1    -0.5   -0.1  0.1   0.5   1     2     3    4 '  
      'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
     endif
     if ( $var= "UGRDprs" )
      'set clevs   -10   -7   -5  -3   -2   -1   1  2  3  5  7  10'  
      'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
     endif
     if ( $var= "VGRDprs" )
      'set clevs   -10   -7   -5  -3   -2   -1  -0.5 -0.2 0.2  0.5  1  2  3  5  7  10'  
      'set rbcols 49    46   44  42   39   36  34   32    0     22    24   26    29   73  75   77   79'
     endif
     if ( $var= "RHprs" )
      'set clevs   -50   -40  -30   -20   -10   -5    5   10    20    30    40   50'  
      'set rbcols 49   46    42   39    36    32    0     22    26    29   73     76   79'
     endif
    if ( $var= "CLWMRprs" | $var= "ICMRprs" | $var= "SNMRprs" | $var= "GRLEprs" | $var= "RWMRprs" )
      'set clevs   -40  -20   -10   -6   -3  -1 -0.1  0.1  1   3   6    10    20    40 '  
      'set rbcols 4    46    42   39    36  34   32    0     22  24  26    29   73     76   79'
     endif
    endif
    'd smth9(sn'%i')' 
*

    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 
    if ( $var= "VVELprs" )
     'set clevs   -4    -3      -2   -1    -0.5   -0.1  0.1   0.5   1     2     3    4 '  
    endif
    if ( $var= "UGRDprs" )
     'set clevs    -100   -70   -50  -30   -20   -10  -5     5  10  20  30  50  70  100' 
    endif
    if ( $var= "VGRDprs" )
     'set clevs     -50  -30   -20    -10  -5     -1   1   5  10  20  30  50   '  
    endif
    if ( $var= "RHprs" )
     'set clevs     10  30  50  70  90 '  
    endif
    if ( $var= "CLWMRprs" | $var= "ICMRprs" | $var= "SNMRprs" | $var= "GRLEprs" | $var= "RWMRprs" )
     'set clevs    0.5  1  5   10   20   40  60   80 100 120 140'
    endif
    if( $difmap = YES & i=1 );'d smth9(sn'%i')' ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.15 0.15'
    if( $difmap = YES & i>1) 
     'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; 
    else
     'draw string 'titlx' 'titly ' 'mdc.i'  'a; 
    endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 ${lev}hPa $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nexp >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}${lev}.png png x700 y700'
  'set vpage off'
'quit'
EOF1
#...........................
fi                           
#...........................
$GRADSBIN/grads -bcp "run ${var}${lev}.gs"  &
sleep 10
done
sleep 60 
done
#.........................

#--wait for maps to be made
nsleep=0
tsleep=60      #seconds to sleep before checking file again
msleep=120      #maximum number of times to sleep
while test ! -s $tmpdir/VGRDprs100.png -a $nsleep -lt $msleep;do
  sleep $tsleep
  nsleep=`expr $nsleep + 1`
done
sleep 120


cat << EOF >ftp_air
  binary
  prompt
  cd $ftpdir/2D/d$odir
  mput *.png
  quit
EOF
if [ $doftp = YES -a $CUE2RUN = $CUE2FTP ]; then
 sftp  ${webhostid}@${webhost} <ftp_air
 if [ $? -ne 0 ]; then
  scp -rp *.png ${webhostid}@${webhost}:$ftpdir/2D/d$odir/.
 fi
fi
cp *.png $mapdir/2D/d$odir/.
#=====================================================================
fi    ;# end of mapair_layer 
#=====================================================================



#=====================================================================
if [ $mapair_zonalmean = "yes" ]; then
#=====================================================================

#### ---------------------------------------------------------------- 
###  generate zonal mean maps  compare between different runs. No obs 
#### ---------------------------------------------------------------- 

#vlist="TMPprs HGTprs O3MRprs RHprs UGRDprs VGRDprs VVELprs SPFHprs CLWMRprs ICMRprs SNMRprs GRLEprs RWMRprs"
vlist="TMPprs HGTprs O3MRprs RHprs UGRDprs VGRDprs VVELprs SPFHprs CLWMRprs ICMRprs SNMRprs GRLEprs RWMRprs"

if [ $cldwat = NO -o $cldwat = no ]; then
    vlist="TMPprs HGTprs O3MRprs RHprs UGRDprs VGRDprs VVELprs SPFHprs"
fi

if [ ${sname[0]} = gfs ]; then 
  vlist="TMPprs HGTprs O3MRprs RHprs UGRDprs VGRDprs VVELprs SPFHprs CLWMRprs"
fi

nvar=`echo $vlist |wc -w`

#---------------------
for var in  $vlist ;do
#---------------------
lev1=$pbtm; lev2=$ptop

if [ $var = "TMPprs" ];   then varname="Temp (K)"            scal=1            ; fi
if [ $var = "ABSVprs" ];  then varname="Vorticity"           scal=1000         ; fi
if [ $var = "CLWMRprs" ]; then varname="Liquid Cloud (ppmg)" scal=1000000  lev2=50    ; fi
if [ $var = "ICMRprs" ];  then varname="Ice Cloud (ppmg)"    scal=1000000  lev2=50    ; fi
if [ $var = "SNMRprs" ];  then varname="Snow (ppmg)"         scal=1000000  lev2=50    ; fi
if [ $var = "GRLEprs" ];  then varname="Graupel (ppmg)"      scal=1000000  lev2=50    ; fi
if [ $var = "RWMRprs" ];  then varname="Rain Water (ppmg)"   scal=1000000  lev2=50    ; fi
if [ $var = "HGTprs" ];   then varname="HGT (m)"             scal=1            ; fi
if [ $var = "O3MRprs" ];  then varname="O3 (ppmg)"           scal=1000000      ; fi
if [ $var = "RHprs" ];    then varname="RH "                 scal=1        lev2=50 ; fi
if [ $var = "SPFHprs" ];  then varname="Q (1E-6 kg/kg)"      scal=1000000   ; fi
if [ $var = "UGRDprs" ];  then varname="U (m/s)"             scal=1            ; fi
if [ $var = "VGRDprs" ];  then varname="V (m/s)"             scal=1            ; fi
if [ $var = "VVELprs" ];  then varname="W (mb/hr)"           scal=36       lev2=50 ; fi


#.........................
if [ $fma_map = yes ]; then
nplot=$((2*nexp))
#.........................
cat >${var}.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1_f4'
  'open $ctl1_a4'
   mdc.1=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f4'
  'open $ctl2_a4'
  mdc.2=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f4'
  'open $ctl3_a4'
  mdc.3=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f4'
  'open $ctl4_a4'
  mdc.4=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f4'
  'open $ctl5_a4'
  mdc.5=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f4'
  'open $ctl6_a4'
  mdc.6=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f4'
  'open $ctl7_a4'
  mdc.7=${cname[6]}
endif     
if  ($nexp >7)
  'open $ctl8_f4'
  'open $ctl8_a4'
  mdc.8=${cname[7]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lev $lev1 $lev2'
  'set t 1  '


n=1
while ( n <= ${nexp} )
  f4=(n-1)*2+1
  a4=(n-1)*2+2

  if(n=1) 

   'set lon $lon1 $lon2'
   'define an1=${scal}*ave(${var}.'%a4', time=${sdate_a4},time=${edate_a4})'
   'define tm1=${scal}*ave(${var}.1, time=${sdate},time=${edate})'
   'set lon 0'
   'define zan1=ave(an1,lon=$lon1,lon=$lon2)'
   'define zm1=ave(tm1,lon=$lon1,lon=$lon2)'
   'define sn'%n'=zm1 '                                 
   m=${nexp}+n
   'define sn'%m'=zm1-zan1 '                                 

  else 

   'set lon $lon1 $lon2'
   'define an=${scal}*ave(${var}.'%a4', time=${sdate_a4},time=${edate_a4})'
   'define tm=${scal}*ave( ${var}.'%f4', time=${sdate},time=${edate})'
   'define tmd=${scal}*ave( ${var}.'%f4' - ${var}.1, time=${sdate},time=${edate})'

   'set lon 0'
   'define zan=ave(an,lon=$lon1,lon=$lon2)'
   'define zm=ave(tm,lon=$lon1,lon=$lon2)'
   'define zmd=ave(tmd,lon=$lon1,lon=$lon2)'
   'define sn'%n'=zmd '                                 
   m=${nexp}+n
   'define sn'%m'=zm-zan'                                 

  endif

  n=n+1
endwhile


*------------------------
*--find maximum and minmum values of control/first run 
   cmax=-10000000.0; cmin=10000000.0
   i=1
    'set gxout stat'
    'd sn'%i
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
*--find maximum and minmum values for difference map
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
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6)
   cintm=0
     if (cintm = 0 & -cmin/50  > 0.01); cintm=10*substr(cmin/50,1,4); endif
     if (cintm = 0 & -cmin/5   > 0.01); cintm=substr(cmin/5,1,4); endif
     if (cintm = 0 & -cmin     > 0.01); cintm=0.2*substr(cmin,1,4); endif
     if (cintm = 0 & -cmin*10  > 0.01); cintm=0.02*substr(cmin*10,1,4); endif
     if (cintm = 0 & -cmin*100 > 0.01); cintm=0.002*substr(cmin*100,1,4); endif
   cms=0.5*cintm; cm1=cintm; cm2=cm1+cintm; cm3=cm2+cintm; cm4=cm3+cintm; cm5=cm4+cintm
              cm6=cm5+cintm; cm7=cm6+cintm; cm8=cm7+cintm; cm9=cm8+cintm
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
   cps=0.5*cintp; cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
              cp6=cp5+cintp; cp7=cp6+cintp; cp8=cp7+cintp; cp9=cp8+cintp
   say 'cmin cmax cintm cintp 'cmin' 'cmax' 'cintm' 'cintp
*------------------------

  nframe=$nplot
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
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
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
    if ( $var = TMPprs ); 'set clevs   -4      -3   -2    -1   -0.5   -0.1  0.1   0.5   1     2     3     4';  endif
    if ( $var = HGTprs ); 'set clevs  -120 -80  -40   -20  -10     -5    5     10   20    40  80  120 ';  endif
    if ( $var = RHprs );  'set clevs  -80    -60   -40   -20  -10     -5    5     10   20    40    60   80 ';  endif
    if ( $var = UGRDprs );   'set clevs -10 -5 -3  -1 -0.5  -0.2    0.2   0.5 1 3 5 10'; endif
    if ( $var = VGRDprs );   'set clevs -3  -1 -0.5  -0.2  -0.1 -0.05 0.05 0.1   0.2   0.5 1 3 '; endif
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1); 'set rbcols 49   46    43    39    36    33    73   76     79    23     25    27   29  ';endif
    if ( $var = "VVELprs" )
      'set clevs    -1.8  -1.2 -0.9  -0.6  -0.3  -0.1  0.1 0.3    0.6   0.9   1.2  1.8 '
      'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
      if(i=1); 'set rbcols 49    46    43   39    37      35   33    0     73    76    79   23   25  27   29  '; endif
    endif
    if ( $var= "CLWMRprs" | $var= "ICMRprs" | $var= "SNMRprs" | $var= "GRLEprs" | $var= "RWMRprs" )
      'set clevs     -15  -12  -9   -6   -3   -1 1 3 6 9 12 15 '                                        
      'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
      if(i=1); 'set clevs             0      3      6   9     12     15   18   21';endif                    
      if(i=1); 'set rbcols          0   31     33    35   37    42     44   46   48';endif    
    endif
    'set ylevs 1000 700 500 300 200 100 70 50 30 20 10 7 5 3 2 1 0.7 0.4 0.2 0.1 0.07 0.04 0.02 0.01'
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if ( $var = "VVELprs" )
      'set clevs             -1.8  -1.2 -0.9  -0.6  -0.3  -0.1  0  0.1 0.3    0.6   0.9   1.2  1.8 '
    endif
    if ( $var= "CLWMRprs" | $var= "ICMRprs" | $var= "SNMRprs" | $var= "GRLEprs" | $var= "RWMRprs" )
      'set clevs     -15  -12  -9   -6   -3   -1 1 3 6 9 12 15 '                                        
      if(i=1); 'set clevs             0      3      6   9     12     15   18   21';endif                    
    endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
*   'set gxout stat'
*   'd yn'%i
*   ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.18 0.18'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1; endif
    if(i>1 & i<=$nexp); 'draw string 'titlx' 'titly ' 'mdc.i' - 'mdc.1 ; endif
    if(i>$nexp); 
     j=i-$nexp
     'draw string 'titlx' 'titly ' 'mdc.j' - analysis'
    endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvfa}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nplot >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}_zmean.png png x700 y700'
  'set vpage off'
'quit'
EOF1
#...........................
else
#.........................
cat >${var}.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1_f1'
  'open $ctl1_f2'
  'open $ctl1_f3'
  'open $ctl1_f4'
   mdc.1=${cname[0]}
if  ($nexp >1)
  'open $ctl2_f1'
  'open $ctl2_f2'
  'open $ctl2_f3'
  'open $ctl2_f4'
  mdc.2=${cname[1]}
endif     
if  ($nexp >2)
  'open $ctl3_f1'
  'open $ctl3_f2'
  'open $ctl3_f3'
  'open $ctl3_f4'
  mdc.3=${cname[2]}
endif     
if  ($nexp >3)
  'open $ctl4_f1'
  'open $ctl4_f2'
  'open $ctl4_f3'
  'open $ctl4_f4'
  mdc.4=${cname[3]}
endif     
if  ($nexp >4)
  'open $ctl5_f1'
  'open $ctl5_f2'
  'open $ctl5_f3'
  'open $ctl5_f4'
  mdc.5=${cname[4]}
endif     
if  ($nexp >5)
  'open $ctl6_f1'
  'open $ctl6_f2'
  'open $ctl6_f3'
  'open $ctl6_f4'
  mdc.6=${cname[5]}
endif     
if  ($nexp >6)
  'open $ctl7_f1'
  'open $ctl7_f2'
  'open $ctl7_f3'
  'open $ctl7_f4'
  mdc.7=${cname[6]}
endif     
if  ($nexp >7)
  'open $ctl8_f1'
  'open $ctl8_f2'
  'open $ctl8_f3'
  'open $ctl8_f4'
  mdc.8=${cname[7]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lev $lev1 $lev2'
  'set t 1  '

n=1
  'set lon $lon1 $lon2'
  'define aa1=${scal}*ave((${var}.1 + ${var}.2 + ${var}.3 + ${var}.4)/4, time=${sdate},time=${edate})'
  'set lon 0'
  'define sn1=ave(aa1,lon=$lon1,lon=$lon2)'

n=2
while ( n <= ${nexp} )
  f1=(n-1)*4+1
  f2=(n-1)*4+2
  f3=(n-1)*4+3
  f4=(n-1)*4+4
  say f1 f2 f3 f4 

  if( $difmap = YES ) 
   'set lon $lon1 $lon2'
   'define bb'%n'=${scal}*ave((${var}.'%f1'-${var}.1  + ${var}.'%f2' -${var}.2 + ${var}.'%f3' -${var}.3 + ${var}.'%f4'-${var}.4 )/4, time=${sdate},time=${edate})'
   'set lon 0'
   'define sn'%n'=ave(bb'%n',lon=$lon1,lon=$lon2)'
  else
  'set lon $lon1 $lon2'
  'define aa'%n'=${scal}*ave((${var}.'%f1' + ${var}.'%f2' + ${var}.'%f3' + ${var}.'%f4')/4, time=${sdate},time=${edate})'
  'set lon 0'
  'define sn'%n'=ave(aa'%n',lon=$lon1,lon=$lon2)'
  endif

  n=n+1
endwhile


*------------------------
*--find maximum and minmum values of control/first run 
   cmax=-10000000.0; cmin=10000000.0
   i=1
    'set gxout stat'
    'd sn'%i
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
*--find maximum and minmum values for difference map
   cmax=-10000000.0; cmin=10000000.0
   i=2
   while (i <= $nexp)
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
   cmin=substr(cmin,1,6); cmax=substr(cmax,1,6)
   cintm=0
     if (cintm = 0 & -cmin/50  > 0.01); cintm=10*substr(cmin/50,1,4); endif
     if (cintm = 0 & -cmin/5   > 0.01); cintm=substr(cmin/5,1,4); endif
     if (cintm = 0 & -cmin     > 0.01); cintm=0.2*substr(cmin,1,4); endif
     if (cintm = 0 & -cmin*10  > 0.01); cintm=0.02*substr(cmin*10,1,4); endif
     if (cintm = 0 & -cmin*100 > 0.01); cintm=0.002*substr(cmin*100,1,4); endif
   cms=0.5*cintm; cm1=cintm; cm2=cm1+cintm; cm3=cm2+cintm; cm4=cm3+cintm; cm5=cm4+cintm
              cm6=cm5+cintm; cm7=cm6+cintm; cm8=cm7+cintm; cm9=cm8+cintm
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
   cps=0.5*cintp; cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
              cp6=cp5+cintp; cp7=cp6+cintp; cp8=cp7+cintp; cp9=cp8+cintp
   say 'cmin cmax cintm cintp 'cmin' 'cmax' 'cintm' 'cintp
*------------------------

  nframe=$nexp
  nframe2=2; nframe3=4;
  ymax0=9.6;  xmin0=0.7;  ylen=-5.5; xlen=7.0;  xgap=0.2; ygap=-0.7
  if($nexp =2);  ylen=-4.0; ygap=-0.7; endif
  if($nexp >2); nframe2=2;  nframe3=4; xlen=3.5; ylen=-3.9; ygap=-0.6; endif
  if($nexp >4); nframe2=3;  nframe3=6; xlen=3.5; ylen=-2.6; ygap=-0.5; endif
  if($nexp >6); nframe2=4;  nframe3=8; xlen=3.5; ylen=-1.8; ygap=-0.4; endif

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
      if($nexp <=2)
        'set xlopts 1 4 0.13'
        'set ylopts 1 4 0.13'
      endif
      if($nexp >2 & $nexp <=4)
        if(i=2|i=$nexp);'set xlopts 1 4 0.12';endif
        if(i<=2);'set ylopts 1 4 0.12';endif
      endif
      if($nexp >4 & $nexp <=6)
        if(i=3|i=$nexp);'set xlopts 1 4 0.11';endif
        if(i<=3);'set ylopts 1 4 0.11';endif
      endif
      if($nexp >=7)
        if(i=4|i=$nexp);'set xlopts 1 4 0.11';endif
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
    'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 
    'set rbcols 49   46    43    39    36    33    73   76     79    23     25    27   29  '
   if( $difmap = YES & i >1 ) 
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
    if ( $var = TMPprs ); 'set clevs   -4      -3   -2    -1   -0.5   -0.1  0.1   0.5   1     2     3     4';  endif
    if ( $var = HGTprs ); 'set clevs  -120 -80  -40   -20  -10     -5    5     10   20    40  80  120 ';  endif
    if ( $var = RHprs );  'set clevs  -80    -60   -40   -20  -10     -5    5     10   20    40    60   80 ';  endif
    if ( $var = UGRDprs );   'set clevs -10 -5 -3  -1 -0.5  -0.2    0.2   0.5 1 3 5 10'; endif
    if ( $var = VGRDprs );   'set clevs -3  -1 -0.5  -0.2  -0.1 -0.05 0.05 0.1   0.2   0.5 1 3 '; endif
   endif
    if ( $var = "VVELprs" )
      'set clevs    -1.8  -1.2 -0.9  -0.6  -0.3  -0.1  0.1 0.3    0.6   0.9   1.2  1.8 '
      'set rbcols 49    46    42   39    36     32    0   22    26    29   73    76   79'
    endif
    if ( $var= "CLWMRprs" | $var= "ICMRprs" | $var= "SNMRprs" | $var= "GRLEprs" | $var= "RWMRprs" )
      'set clevs             0      3      6   9     12     15   18   21'
      'set rbcols          0   31     33    35   37    42     44   46   48'
      if( $difmap = YES & i >1 ) 
       'set clevs     -15  -12  -9   -6   -3   -1  1  3  6  9  12  15 '                                        
       'set rbcols 49    46    42   39  36  32   0  22 26  29 73 76   79'
      endif
    endif
    'set ylevs 1000 700 500 300 200 100 70 50 30 20 10 7 5 3 2 1 0.7 0.4 0.2 0.1 0.07 0.04 0.02 0.01'
    'd sn'i 
*
    'set gxout contour'
    'set grads off'
    'set ccolor 15'
*   'set clab forced'
    'set cstyle 1'
    'set clopts 1 4 0.07'
    'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 
    if( $difmap = YES & i >1 ) 
      'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    endif
    if ( $var = "VVELprs" )
      'set clevs             -1.8  -1.2 -0.9  -0.6  -0.3  -0.1  0  0.1 0.3    0.6   0.9   1.2  1.8 '
    endif
    if ( $var= "CLWMRprs" | $var= "ICMRprs" | $var= "SNMRprs" | $var= "GRLEprs" | $var= "RWMRprs" )
      'set clevs             0      3      6   9     12     15   18   21'
      if( $difmap = YES & i >1 ) 
       'set clevs     -15  -12  -9   -6   -3   -1 1 3 6 9 12 15 '                                        
      endif
    endif
    if( $difmap = YES & i=1 );'d sn'%i ;endif
                                                                                                                 
*   'set gxout stat'
*   'd yn'%i
*   ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.18 0.18'
    if( $difmap = YES & i >1 ) 
     'draw string 'titlx' 'titly ' 'mdc.i' - 'mdc.1 
    else
     'draw string 'titlx' 'titly ' 'mdc.i
    endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.35 $varname, ${cyc}Z-Cyc ${sdate}-${edate} Mean'
  'set strsiz 0.12 0.12'
  'draw string 4.3 10.15  ${dayvf}'
  'set string 1 bc 5'
  'set strsiz 0.15 0.15'
  if($nexp >1 )
    'run $gradsutil/cbarn.gs 1. 0 4.3 0.28'
  else
    'run $gradsutil/cbarn.gs 1. 0 4.3 3.3'
  endif

  'printim ${var}_zmean.png png x700 y700'
  'set vpage off'
'quit'
EOF1
#...........................
fi
#...........................
$APRUN $GRADSBIN/grads -bcp "run ${var}.gs" &
sleep 20

done
#.........................

nsleep=0; tsleep=300;  msleep=60
while [ $nsleep -lt $msleep ];do
  sleep $tsleep; nsleep=`expr $nsleep + 1`
  nplotout=`ls *zmean.png |wc -w`
  if [ $nplotout -eq $nvar ]; then nsleep=$msleep; fi
done

cat << EOF >ftp_zonal
  binary
  prompt
  cd $ftpdir/2D/d$odir
  mput *zmean*.png
  quit
EOF
if [ $doftp = YES -a $CUE2RUN = $CUE2FTP ]; then
 sftp  ${webhostid}@${webhost} <ftp_zonal
 if [ $? -ne 0 ]; then
  scp -rp *.png ${webhostid}@${webhost}:$ftpdir/2D/d$odir/.
 fi
fi
cp *.png $mapdir/2D/d$odir/.
#=====================================================================
fi    ;# end of mapair_zonalmean 
#=====================================================================

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
ssh -q -l $webhostid ${webhost} " ls -l ${ftpdir}/2D/d1 "
if [ \$? -ne 0 ]; then
 ssh -l $webhostid ${webhost} " mkdir -p $ftpdir "
 scp -rp $srcdir/html/* ${webhostid}@${webhost}:$ftpdir/.
fi
if [ -s ftp_obs ]; then sftp  ${webhostid}@${webhost} < ftp_obs  ;fi
if [ -s ftp_sfc ]; then sftp  ${webhostid}@${webhost} < ftp_sfc  ;fi
if [ -s ftp_air ]; then sftp  ${webhostid}@${webhost} < ftp_air  ;fi
if [ -s ftp_zonal ]; then sftp  ${webhostid}@${webhost} < ftp_zonal  ;fi
EOF

  chmod u+x $tmpdir/ftp2dmap.sh
  $SUBJOB -a $ACCOUNT -q $CUE2FTP -g $GROUP -p 1/1/S -t 0:30:00 -r 256/1 -j ftp2dmap -o ftp2dmap.out $tmpdir/ftp2dmap.sh 
#--------------------------------------------
fi
#--------------------------------------------


exit
