#!/bin/ksh
set -x

#### ------------------------------------------------------------------- 
###  Make lat-lon maps and zonal-mean vertical distributions of ensemble 
###  mean and ensemble spread. Use sfg_${cdate}_fhr${hr}s_ensmean.bin 
###  and sfg_${cdate}_fhr${hr}s_ensspread.bin, where hr={03,06,09}. 
###  Fanglin Yang, EMC/NCEP/NOAA,  June 2015 
###  fanglin.yang@noaa.gov; 301-6833722            
#### ---------------------------------------------------------- 

export expnlist=${expnlist:-"gfs pr4dev"}     ;#experiments, up to 8; gfs will point to ops data
export expdlist=${expdlist:-"/global/noscrub/emc.glopara/global /global/noscrub/emc.glopara/archive"}    ;#data archive
export cyclist=${cyclist:-"00 06 12 18"}      ;#analysis cycles to be included
export geshour=${geshour:-"06"}               ;#enkf forecast hours to be verified  
export levsig=${levsig:-"1 7 11 14 20 25 31 35 41 46 49 55 58 61"} ;#sigma layers for lat-lon maps,up to 14
export DATEST=${DATEST:-20140401}             ;#starting verifying date 
export DATEND=${DATEND:-20140401}             ;#endding verifying date

export JCAP_bin=${JCAP_bin:-254}              ;#binary file res, linear T574->1152x576 etc
export nlev=${nlev:-64}                       ;#sig file vertical layers, fixed for 64-L GFS
export pbtm=${pbtm:-1}                        ;#bottom layer number for zonal mean maps
export ptop=${ptop:-$nlev}                    ;#top layer number for zonal mean maps
export webhost=${webhost:-emcrzdm.ncep.noaa.gov}
export webhostid=${webhostid:-wx24fy}
export ftpdir=${ftpdir:-/home/people/emc/www/htdocs/gmb/$webhostid/vsdb/test}
export doftp=${doftp:-NO}

export rundir=${rundir:-/ptmpd2/$LOGNAME/ensspread}
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
export vsdbhome=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}
export SUBJOB=${SUBJOB:-$vsdbhome/bin/sub_wcoss}
export ACCOUNT=${ACCOUNT:-GFS-T2O}
export CUE2RUN=${CUE2RUN:-dev}
export CUE2FTP=${CUE2FTP:-transfer}
export GROUP=${GROUP:-g01}


#------------------------------------------------------------------
#------------------------------------------------------------------
srcdir=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}/plot2d
gradsutil=${vsdbhome:-/global/save/Fanglin.Yang/VRFY/vsdb}/map_util/grads
export GRADSBIN=${GRADSBIN:-/usrx/local/GrADS/2.0.2/bin}

if [ $doftp = YES -a $batch = NO ]; then
ssh -q -l $webhostid ${webhost} " ls -l ${ftpdir}/2D/ens "
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
export ncyc=`echo $cyclist | wc -w`
export ncount=`expr $ndays \* $ncyc `
export inthour=`expr 24 \/ $ncyc `
set -A sname  none $expnlist
set -A expdname none $expdlist
set -A cycname none $cyclist
export cycs=${cycname[1]}
nexp=`echo $expnlist |wc -w`                

#--define map range
area=${area:-gb}
latlon=${latlon:-"-90 90 0 360"}        ;#map area lat1, lat2, lon1 and lon2
set -A latlonc none $latlon
lat1=${latlonc[1]}; lat2=${latlonc[2]}
lon1=${latlonc[3]}; lon2=${latlonc[4]}

export ctldir=${rundir}/ctl                                   
mkdir -p $ctldir
export plotdir=$rundir/plot    
mkdir -p $plotdir 
#
#-------------------------------
#-------------------------------
nhr=1
for ghr in $geshour; do
#-------------------------------
#-------------------------------

#--------------
#-- GrADS ctl 
#--------------
n=1; while [ $n -le $nexp ]; do
 export exp=${sname[n]}
 export expdir=${expdname[n]}
 export ghr=$ghr
 $srcdir/makectl_ensspread.sh 
 export ctl${n}m=${rundir}/ctl/${exp}_sfg_fhr${ghr}s_ensmean.ctl
 export ctl${n}s=${rundir}/ctl/${exp}_sfg_fhr${ghr}s_ensspread.ctl
n=$((n+1))
done


#--------------
#-- make maps
#--------------
cd $plotdir ||exit 8

#### -------------------------------------------------
###  generate 2D maps on selected sigma surface layers.
###  choose up to 14 layers to display, including time
###  averaged ensemble mean and ensemble spread
#### -------------------------------------------------
#--64-L GFS layer pressure for PS=1000hPa
set -A levpgfs none 1000 994 988 981 974 965 955 944 932 919 903 887 868 848 826 803 777 750 721 690 658 624 590 555 520 484 449 415 381 349 317 288 260 234 209 187 166 148 130 115 101 88 77 67 58 50 43 37 31 26 22 18 15 12 10 7.7 5.8 4.2 2.9 1.9 1.1 0.7 0.3 0.1 
nplot=$nexp

vlist="T Q U V O3 CLW PS"
nvar=`echo $vlist |wc -w`
#--------------------------------
for var in  $vlist; do                                                         
#--------------------------------
levsiga="$levsig"
if [ $var = PS ]; then levsiga=1; fi
levn=1
#--------------------------------
for lev in $levsiga ; do                                    
#--------------------------------
 levp=${levpgfs[$lev]}
 if [ $var = "T"                   ];   then varname="Temp (K)"           scal=1            ; fi
 if [ $var = "Q"                   ];   then varname="Q (1E-6 kg/kg)"     scal=1000000      ; fi
 if [ $var = "Q"  -a $levp -ge 250 ];   then varname="Q (g/kg)"           scal=1000         ; fi
 if [ $var = "RH"                  ];   then varname="RH (%)"             scal=1            ; fi
 if [ $var = "U"                   ];   then varname="U (m/s)"            scal=1            ; fi
 if [ $var = "V"                   ];   then varname="V (m/s)"            scal=1            ; fi
 if [ $var = "O3"                  ];   then varname="O3 (1E-6 kg/kg)"    scal=1000000      ; fi
 if [ $var = "O3" -a $levp -ge 200 ];   then varname="O3 (1E-9 kg/kg)"    scal=1000000000   ; fi
 if [ $var = "CLW"                 ];   then varname="Cld Water (1E-6 kg/kg)"  scal=1000000    ; fi
 if [ $var = "CLW" -a $levp -le 200 ];  then varname="Cld Water (1E-9 kg/kg)"  scal=1000000000 ; fi
 if [ $var = "PS"                  ];   then varname="Surface Pressure (hPa)"  scal=0.01    ; fi

#.............................
# time averaged ensemble mean
#.............................
cat >ensmean${nhr}_${var}${levn}.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1m'
   mdc.1=${sname[1]}
if  ($nexp >1)
  'open $ctl2m'
   mdc.2=${sname[2]}
endif     
if  ($nexp >2)
  'open $ctl3m'
   mdc.3=${sname[3]}
endif     
if  ($nexp >3)
  'open $ctl4m'
   mdc.4=${sname[4]}
endif     
if  ($nexp >4)
  'open $ctl5m'
   mdc.5=${sname[5]}
endif     
if  ($nexp >5)
  'open $ctl6m'
   mdc.6=${sname[6]}
endif     
if  ($nexp >6)
  'open $ctl7m'
   mdc.7=${sname[7]}
endif     
if  ($nexp >7)
  'open $ctl8m'
   mdc.8=${sname[8]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2'
  'set lev $lev'
  'set t 1  '

n=1
while ( n <= ${nexp} )
  if(n=1) 
   'define sn'%n'=${scal}*ave(${var}.'%n', t=1,t=$ncount)'                    
  endif
  if(n>1) 
   'define sn'%n'=${scal}*ave(${var}.'%n', t=1,t=$ncount)-sn1'                    
  endif
  'define yn'%n'=aave(sn'%n',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile

*------------------------
*--find maximum and minmum values of control itself
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


*--find maximum and minmum values of differences between exp and control run               
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
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1); 'set rbcols 31    33   35    37    39    43    45   47     49    21     23    25   27  ';endif
    if ( $var= "T" & i > 1 )
      'set clevs    -2  -1   -0.5  -0.25  -0.1 -0.01 0.01 0.1 0.25  0.5  1  2'              
      'set rbcols 49  46   42   39      36     32    0   22  26    29  73 76  79'
    endif
    if ( $var= "U" )
     'set clevs    -5  -3   -2   -1  -0.5 -0.1 0.1  0.5  1   2  3  5 '
     'set rbcols 49  46   42   39  36   32    0   22   26 29  73 76   79'
     if(i=1); 'set clevs    -100   -70   -50  -30   -20   -10  -5     5  10  20  30  50  70  100'  ;endif
     if(i=1); 'set rbcols 49    47    45    43     37   35   33   0      63  65  67  73  75  77  79'; endif
    endif
    if ( $var= "V" )
     'set clevs    -5  -3   -2   -1  -0.5 -0.1 0.1  0.5  1   2  3  5 '
     'set rbcols 49  46   42   39  36   32    0   22   26 29  73 76   79'
     if(i=1); 'set clevs     -50  -30   -20    -10  -5     -1   1   5  10  20  30  50   '  ;endif
     if(i=1); 'set rbcols 49    47    45    37   35   33   0  63  65  67 75  77  79'; endif
    endif
    if ( $var= "CLW" )
     'set clevs   -20   -10   -6   -3  -1 -0.1  -0.01 0.01 0.1  1   3   6    10    20 '
     'set rbcols 4    46    42   39  36  34   32    0     22  24  26   29  73    76   79'
     if(i=1); 'set clevs    0.5  1  5   10   20   40  60   80 100 120 140'  ;endif
     if(i=1); 'set rbcols  0   63 65  67  69   73   75  77   79  33  35  37'; endif
    endif
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
    if ( $var= "U" )
     'set clevs   -10   -7   -5  -3   -2   -1   1  2  3  5  7  10'
     if(i=1); 'set clevs    -100   -70   -50  -30   -20   -10  -5     5  10  20  30  50  70  100'  ;endif
    endif
    if ( $var= "V" )
     'set clevs   -10   -7   -5  -3   -2   -1  -0.5 -0.2 0.2  0.5  1  2  3  5  7  10'
     if(i=1); 'set clevs     -50  -30   -20    -10  -5     -1   1   5  10  20  30  50   '  ;endif
    endif
    if ( $var= "CLW" )
     'set clevs   -40  -20   -10   -6   -3  -1 -0.1  0.1  1   3   6    10    20    40 '
     if(i=1); 'set clevs    0.5  1  5   10   20   40  60   80 100 120 140'  ;endif
    endif
    if(i=1);'d smth9(sn'%i')' ;endif

    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.14 0.14'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'  'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.45 Ensemble Mean, ${varname}, fh${ghr}'
  'set strsiz 0.13 0.13'
  if ( $var = PS )          
   'draw string 4.3 10.21 [${cyclist}] Cyc, ${DATEST} ~ ${DATEND}'
  else
   'draw string 4.3 10.21 siglev=${lev}, $levp hPa, [${cyclist}] Cyc, ${DATEST} ~ ${DATEND}'
  endif
  'set string 1 bc 3'
  'set strsiz 0.08 0.08'
  if($nplot >1 )
    'run $gradsutil/cbarn1.gs 1. 0 4.3 0.55'
  else
    'run $gradsutil/cbarn1.gs 1. 0 4.3 3.4'
  endif

  'printim ensmean${nhr}_${var}${levn}.png png x700 y680'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ensmean${nhr}_${var}${levn}.gs"  &
sleep 10


#.............................
# time averaged ensemble spread
#.............................
cat >ensspd${nhr}_${var}${levn}.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1s'
   mdc.1=${sname[1]}
if  ($nexp >1)
  'open $ctl2s'
   mdc.2=${sname[2]}
endif     
if  ($nexp >2)
  'open $ctl3s'
   mdc.3=${sname[3]}
endif     
if  ($nexp >3)
  'open $ctl4s'
   mdc.4=${sname[4]}
endif     
if  ($nexp >4)
  'open $ctl5s'
   mdc.5=${sname[5]}
endif     
if  ($nexp >5)
  'open $ctl6s'
   mdc.6=${sname[6]}
endif     
if  ($nexp >6)
  'open $ctl7s'
   mdc.7=${sname[7]}
endif     
if  ($nexp >7)
  'open $ctl8s'
   mdc.8=${sname[8]}
endif     

*-----
  'set lat $lat1 $lat2'
  'set lon $lon1 $lon2'
  'set lev $lev'
  'set t 1  '

n=1
while ( n <= ${nexp} )
  if(n=1) 
   'define sn'%n'=${scal}*ave(${var}.'%n', t=1,t=$ncount)'                    
  endif
  if(n>1) 
   'define sn'%n'=${scal}*ave(${var}.'%n', t=1,t=$ncount)-sn1'                    
  endif
  'define yn'%n'=aave(sn'%n',lon=$lon1,lon=$lon2,lat=$lat1,lat=$lat2)'
  n=n+1
endwhile

*------------------------
*--find maximum and minmum values of control itself
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

   cintm=0
     if (cintm = 0 & -cmin/50  > 0.01); cintm=10*substr(cmin/50,1,4); endif
     if (cintm = 0 & -cmin/5   > 0.01); cintm=substr(cmin/5,1,4); endif
     if (cintm = 0 & -cmin     > 0.01); cintm=0.2*substr(cmin,1,4); endif
     if (cintm = 0 & -cmin*10  > 0.01); cintm=0.02*substr(cmin*10,1,4); endif
     if (cintm = 0 & -cmin*100 > 0.01); cintm=0.002*substr(cmin*100,1,4); endif
     cms1=0.25*cintm; cms=0.5*cintm; cm1=cintm; cm2=cm1+cintm; cm3=cm2+cintm; cm4=cm3+cintm; cm5=cm4+cintm
              cm6=cm5+cintm; cm7=cm6+cintm; cm8=cm7+cintm; cm9=cm8+cintm
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
     cps1=0.25*cintp; cps=0.5*cintp; cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
              cp6=cp5+cintp; cp7=cp6+cintp; cp8=cp7+cintp; cp9=cp8+cintp
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
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cms1' 'cps1' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols 49    46    42   39    36     34    32    0     22     24     26    29   73     76   79'
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
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cms1' 'cps1' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1);'d smth9(sn'%i')' ;endif
                                                                                                                 
    'set gxout stat'
    'd yn'%i
    ln=sublin(result,8); wd=subwrd(ln,4); a=substr(wd,1,14)
    'set string 1 bl 7'
    'set strsiz 0.14 0.14'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1'  'a; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1' 'a; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.45 Ensemble Spread, ${varname}, fh${ghr}'
  'set strsiz 0.13 0.13'
  if ( $var = PS )          
   'draw string 4.3 10.21 [${cyclist}] Cyc, ${DATEST} ~ ${DATEND}'
  else
   'draw string 4.3 10.21 siglev=${lev}, $levp hPa, [${cyclist}] Cyc, ${DATEST} ~ ${DATEND}'
  endif
  'set string 1 bc 3'
  'set strsiz 0.08 0.08'
  if($nplot >1 )
    'run $gradsutil/cbarn1.gs 1. 0 4.3 0.60'
  else
    'run $gradsutil/cbarn1.gs 1. 0 4.3 3.4'
  endif

  'printim ensspd${nhr}_${var}${levn}.png png x700 y680'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ensspd${nhr}_${var}${levn}.gs"  &
sleep 10


#--------------------------------
 levn=$((levn+1))
done  ;#layers
#--------------------------------
sleep 60 
done  ;#variables
#--------------------------------

#--wait for maps to be made
nsleep=0; tsleep=60;  msleep=60    
while test ! -s ensspd${nhr}_CLW5.png  -a $nsleep -lt $msleep;do
  sleep $tsleep; nsleep=`expr $nsleep + 1`
done


cat << EOF >ftp_air
  binary
  prompt
  cd $ftpdir/2D/ens   
  mput ens*.png 
  quit
EOF
if [ $doftp = YES ]; then
 if [ $CUE2RUN = $CUE2FTP -o $batch = NO ]; then
  sftp  ${webhostid}@${webhost} <ftp_air
  if [ $? -ne 0 ]; then
   scp -rp ens*png ${webhostid}@${webhost}:$ftpdir/2D/ens/.
  fi
fi
fi
if [ ! -s $mapdir/2D/ens ]; then mkdir -p $mapdir/2D/ens ; fi
cp ens*.png $mapdir/2D/ens/.


#### ---------------------------------------------------------------------
###  zonal mean time-averaged ensemble mean and ensemble spread
#### ---------------------------------------------------------------------

vlist="T Q U V O3 CLW"
nvar=`echo $vlist |wc -w`
lev1=$pbtm; lev2=$ptop

#----------------------
for var in  $vlist; do                                                         
#----------------------

if [ $var = "T" ];   then varname="Temp (K)"           scal=1            ; fi
if [ $var = "Q" ];   then varname="Q (1E-6 kg/kg)"     scal=1000000      ; fi
if [ $var = "RH" ];   then varname="RH (%)"            scal=1            ; fi
if [ $var = "U" ];   then varname="U (m/s)"            scal=1            ; fi
if [ $var = "V" ];   then varname="V (m/s)"            scal=1            ; fi
if [ $var = "O3" ];  then varname="O3 (1E-9 kg/kg)"    scal=1000000000   ; fi
if [ $var = "CLW" ]; then varname="Cloud Water (ppmg)" scal=1000000      ; fi

#.........................
# zonal mean ensemble mean   
#.........................
cat >ensmean${nhr}_${var}.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1m'
   mdc.1=${sname[1]}
if  ($nexp >1)
  'open $ctl2m'
   mdc.2=${sname[2]}
endif     
if  ($nexp >2)
  'open $ctl3m'
   mdc.3=${sname[3]}
endif     
if  ($nexp >3)
  'open $ctl4m'
   mdc.4=${sname[4]}
endif     
if  ($nexp >4)
  'open $ctl5m'
   mdc.5=${sname[5]}
endif     
if  ($nexp >5)
  'open $ctl6m'
   mdc.6=${sname[6]}
endif     
if  ($nexp >6)
  'open $ctl7m'
   mdc.7=${sname[7]}
endif     
if  ($nexp >7)
  'open $ctl8m'
   mdc.8=${sname[8]}
endif     
*-----

  'set lat $lat1 $lat2'
  'set lev $lev1 $lev2'
  'set t 1  '

n=1
while ( n <= ${nexp} )
  if(n=1) 
   'set lon $lon1 $lon2'
   'define aa=${scal}*ave(${var}.'%n', t=1,t=$ncount)'                     
    'set lon 0'
   'define sn'%n'=ave(aa,lon=$lon1,lon=$lon2)'
  endif
  if(n>1) 
   'set lon $lon1 $lon2'
   'define bb=${scal}*ave(${var}.'%n', t=1,t=$ncount)-sn1'                     
    'set lon 0'
   'define sn'%n'=ave(bb,lon=$lon1,lon=$lon2)'
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
*   'set mpdset mres'

    'set gxout shaded'
    'set grads off'
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols 49    46    42   39    36     32    0     22    26    29   73     76   79'
    if ( $var = T ); 'set clevs  -2  -1   -0.5  -0.25  -0.1 -0.01 0.01 0.1 0.25  0.5  1  2';  endif
    if ( $var = U ); 'set clevs  -2  -1   -0.5  -0.25  -0.1 -0.01 0.01 0.1 0.25  0.5  1  2 '; endif
    if ( $var = V ); 'set clevs  -2  -1   -0.5  -0.25  -0.1 -0.01 0.01 0.1 0.25  0.5  1  2 '; endif
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1); 'set rbcols 49   46    43    39    36    33    73   76     79    23     25    27   29  ';endif
    if ( $var = "CLW" )
      'set clevs     -4   -2    -1  -0.5 -0.1  -0.01 0.01  0.1  0.5   1    2     4   '
      'set rbcols 49    46   42   39    36   32     0    22  26    29   73    76  79'
      if(i=1); 'set clevs    0   1     3      6   9     12     15   18   21';endif
      if(i=1); 'set rbcols 0   31   33    35   37    39    42    44   46   48';endif
    endif
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
    if ( $var = "CLW" )
      'set clevs     -15  -12  -9   -6   -3   -1 1 3 6 9 12 15 '
      if(i=1); 'set clevs  0      3      6   9     12     15   18   21';endif
    endif
    if(i=1);'d sn'%i ;endif

    'set string 1 bl 7'
    'set strsiz 0.14 0.14'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1; endif
    if(i>2); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.45 Ensemble Mean, ${varname}, fh${ghr}'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.21 [${cyclist}] Cycles, ${DATEST} ~ ${DATEND}'
  'set string 1  bc 3'
  'set strsiz 0.08 0.08'
  if($nplot >1 )
    'run $gradsutil/cbarn1.gs 1. 0 4.3 0.40'
  else
    'run $gradsutil/cbarn1.gs 1. 0 4.3 3.4'
  endif

  'printim ensmean${nhr}_${var}_zmean.png png x700 y680'
  'set vpage off'
'quit'
EOF1
$GRADSBIN/grads -bcp "run ensmean${nhr}_${var}.gs" &
sleep 60


#.........................
# zonal mean ensemble spead   
#.........................
cat >ensspd${nhr}_${var}.gs <<EOF1 
'reinit'; 'set font 1'
'set display color  white'
  'open $ctl1s'
   mdc.1=${sname[1]}
if  ($nexp >1)
  'open $ctl2s'
   mdc.2=${sname[2]}
endif     
if  ($nexp >2)
  'open $ctl3s'
   mdc.3=${sname[3]}
endif     
if  ($nexp >3)
  'open $ctl4s'
   mdc.4=${sname[4]}
endif     
if  ($nexp >4)
  'open $ctl5s'
   mdc.5=${sname[5]}
endif     
if  ($nexp >5)
  'open $ctl6s'
   mdc.6=${sname[6]}
endif     
if  ($nexp >6)
  'open $ctl7s'
   mdc.7=${sname[7]}
endif     
if  ($nexp >7)
  'open $ctl8s'
   mdc.8=${sname[8]}
endif     
*-----

  'set lat $lat1 $lat2'
  'set lev $lev1 $lev2'
  'set t 1  '

n=1
while ( n <= ${nexp} )
  if(n=1) 
   'set lon $lon1 $lon2'
   'define aa=${scal}*ave(${var}.'%n', t=1,t=$ncount)'                     
    'set lon 0'
   'define sn'%n'=ave(aa,lon=$lon1,lon=$lon2)'
  endif
  if(n>1) 
   'set lon $lon1 $lon2'
   'define bb=${scal}*ave(${var}.'%n', t=1,t=$ncount)-sn1'                     
    'set lon 0'
   'define sn'%n'=ave(bb,lon=$lon1,lon=$lon2)'
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
*--find maximum and minmum values of the difference  between exp and control
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
   cintm=0
     if (cintm = 0 & -cmin/50  > 0.01); cintm=10*substr(cmin/50,1,4); endif
     if (cintm = 0 & -cmin/5   > 0.01); cintm=substr(cmin/5,1,4); endif
     if (cintm = 0 & -cmin     > 0.01); cintm=0.2*substr(cmin,1,4); endif
     if (cintm = 0 & -cmin*10  > 0.01); cintm=0.02*substr(cmin*10,1,4); endif
     if (cintm = 0 & -cmin*100 > 0.01); cintm=0.002*substr(cmin*100,1,4); endif
     cms1=0.25*cintm; cms=0.5*cintm; cm1=cintm; cm2=cm1+cintm; cm3=cm2+cintm; cm4=cm3+cintm; cm5=cm4+cintm
              cm6=cm5+cintm; cm7=cm6+cintm; cm8=cm7+cintm; cm9=cm8+cintm
   cintp=0
     if (cintp = 0 & cmax/50  > 0.01); cintp=10*substr(cmax/50,1,4); endif
     if (cintp = 0 & cmax/5   > 0.01); cintp=substr(cmax/5,1,4); endif
     if (cintp = 0 & cmax     > 0.01); cintp=0.2*substr(cmax,1,4); endif
     if (cintp = 0 & cmax*10  > 0.01); cintp=0.02*substr(cmax*10,1,4); endif
     if (cintp = 0 & cmax*100 > 0.01); cintp=0.002*substr(cmax*100,1,4); endif
     cps1=0.25*cintp; cps=0.5*cintp; cp1=cintp; cp2=cp1+cintp; cp3=cp2+cintp; cp4=cp3+cintp; cp5=cp4+cintp
              cp6=cp5+cintp; cp7=cp6+cintp; cp8=cp7+cintp; cp9=cp8+cintp
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
*   'set mpdset mres'


    'set gxout shaded'
    'set grads off'
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cms1'  'cps1' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    'set rbcols 49    46    44    42   39    36     32     0       22    24    26   29   73     76   79'
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
    'set clevs   'cm5' 'cm4' 'cm3' 'cm2' 'cm1' 'cms' 'cms1'  'cps1' 'cps' 'cp1' 'cp2' 'cp3' 'cp4' 'cp5
    if(i=1); 'set clevs   'aa1' 'aa2' 'aa3' 'aa4' 'aa5' 'aa6' 'aa7' 'aa8' 'aa9' 'aa10' 'aa11 ;endif
    if(i=1);'d sn'%i ;endif
                                                                                                                 
    'set string 1 bl 7'
    'set strsiz 0.14 0.14'
    if(i=1); 'draw string 'titlx' 'titly ' 'mdc.1; endif
    if(i>1); 'draw string 'titlx' 'titly ' 'mdc.i'-'mdc.1; endif
  i=i+1
  endwhile

  'set string 4  bc 6'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.45 Ensemble Spread, ${varname}, fh${ghr}'
  'set strsiz 0.13 0.13'
  'draw string 4.3 10.21 [${cyclist}] Cycles, ${DATEST} ~ ${DATEND}'
  'set string 1  bc 3'
  'set strsiz 0.08 0.08'
  if($nplot >1 )
    'run $gradsutil/cbarn1.gs 1. 0 4.3 0.40'
  else
    'run $gradsutil/cbarn1.gs 1. 0 4.3 3.4'
  endif

  'printim ensspd${nhr}_${var}_zmean.png png x700 y680'
  'set vpage off'
'quit'
EOF1
$APRUN $GRADSBIN/grads -bcp "run ensspd${nhr}_${var}.gs" &
sleep 60

#-------------------------
done ;#variables 
#-------------------------

nvartot=$((nvar*2))
nsleep=0; tsleep=300;  msleep=30  
while [ $nsleep -lt $msleep ];do
  sleep $tsleep; nsleep=`expr $nsleep + 1`
  nplotout=`ls ens*zmean.png |wc -w`
  if [ $nplotout -eq $nvartot ]; then nsleep=$msleep; fi
done

cat << EOF >ftp_zonal
  binary
  prompt
  cd $ftpdir/2D/ens
  mput ens*zmean.png
  quit
EOF
if [ $doftp = YES ]; then
 if [ $CUE2RUN = $CUE2FTP -o $batch = NO ]; then
  sftp  ${webhostid}@${webhost} <ftp_zonal
  if [ $? -ne 0 ]; then
   scp -rp ens*zmean.png ${webhostid}@${webhost}:$ftpdir/2D/ens/.
  fi
 fi
fi
cp ens*zmean.png $mapdir/2D/ens/.

#-------------------------------
#-------------------------------
nhr=`expr $nhr + 1`
done   ;#geshour;
#-------------------------------
#-------------------------------
  
#-  -------------------------------------------
##--send plots to web server using dedicated 
##--transfer node (required by NCEP WCOSS)
 if [ $doftp = "YES" -a $CUE2RUN != $CUE2FTP ]; then
#--------------------------------------------
cd $plotdir
cat << EOF >ftp2dmap.sh
#!/bin/ksh
set -x
ssh -q -l $webhostid ${webhost} " ls -l ${ftpdir}/2D/ens "
if [ \$? -ne 0 ]; then
 ssh -l $webhostid ${webhost} " mkdir -p $ftpdir "
 scp -rp $srcdir/html/* ${webhostid}@${webhost}:$ftpdir/.
fi
cat << EOF1 >ftp_all
  binary
  prompt
  cd $ftpdir/2D/ens
  mput *.png
  quit
EOF1
sftp  ${webhostid}@${webhost} < ftp_all  
EOF

chmod u+x $plotdir/ftp2dmap.sh
$SUBJOB -a $ACCOUNT -q $CUE2FTP -g $GROUP -p 1/1/S -t 0:30:00 -r 256/1 -j ftp2dmap -o ftp2dmap.out $plotdir/ftp2dmap.sh 
#--------------------------------------------
fi
#--------------------------------------------


exit
