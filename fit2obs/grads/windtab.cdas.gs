function windt(args)
ts00=subwrd(args,1)
te00=subwrd(args,2)
ts12=subwrd(args,3)
te12=subwrd(args,4)
pdir=subwrd(args,5)
gdir=subwrd(args,6)
exp1=subwrd(args,7)
exp2=subwrd(args,8)
fcs1=subwrd(args,9)
fcs2=subwrd(args,10)
ctldir=subwrd(args,11)
namstr=subwrd(args,12)

ftg1='f'substr(fcs1,1,2)
ftg2='f'substr(fcs2,1,2)

ctlfile=ctldir'/'exp1'.f'fcs1'.raob.ctl'
say ctlfile
'open 'ctlfile
ctlfile=ctldir'/'exp1'.f'fcs2'.raob.ctl'
say ctlfile
'open 'ctlfile
ctlfile=ctldir'/'exp2'.f'fcs1'.raob.ctl'
say ctlfile
'open 'ctlfile
ctlfile=ctldir'/'exp2'.f'fcs2'.raob.ctl'
say ctlfile
'open 'ctlfile
*
var=w; titvar='Vector Wind'
*
**  reg=1 is gl; reg=2 is nh; reg=3 is sh; reg=4 is tr; tr=5 is na; tr=6 is eu; as=asia
regs=1
rege=7
*
**  sub=1 is adpupa
subs=1
sube=1
*
**  =1 is 850 mb; -2 is 700 mb; =3 is 500 mb; =4 is 200 mb; =5 is 70 mb
levs=1
leve=15
*
sub=subs
while (sub<=sube)
titsub=getsub(sub)
gsub=getgsub(sub)
*
levx=levs
while (levx<=leve)
level=getlev(levx)
*
if(level<=1000); ymin=0; ymax=10  ; endif
if(level<=700) ; ymin=0; ymax=10  ; endif
if(level<=500) ; ymin=0; ymax=12  ; endif
if(level<=200) ; ymin=0; ymax=15  ; endif
if(level<=70)  ; ymin=0; ymax=12  ; endif

'reset'
'set display color white'
'clear'

pngfile=pdir'/'var''level'.all.'gsub'.png'; say pngfile

*'set vpage 0 8.5 0 11'
*'set strsiz 0.1'
*'set string 4 tl 6'
*'draw string 0.12 0.12 'namstr

'set strsiz 0.15'
'set string 1 tl 6'
'draw string 0.1 10.8 'titvar' 'level' mb RMS Fit to 'titsub' 'ts00' - 'te00

reg=regs
while (reg<=rege)
titreg=getreg(reg)

xminp=getxmin(reg)
xmaxp=getxmax(reg)
yminp=getymin(reg)
ymaxp=getymax(reg)
'set vpage 'xminp' 'xmaxp' 'yminp' 'ymaxp

'set grads off'
'set x 'reg
'set y 'sub
'set lev 'level
'set time 'ts00' 'te00
'set axlim 'ymin' 'ymax

* draw the time series

'set cstyle 1'; 'set ccolor 2'; 'set cmark 0'; 'set cthick 6'; 'd sqrt(uvf.1+uvo.1-2*uv.1)'
'set cstyle 1'; 'set ccolor 4'; 'set cmark 0'; 'set cthick 6'; 'd sqrt(uvf.2+uvo.2-2*uv.2)'
'set cstyle 2'; 'set ccolor 2'; 'set cmark 0'; 'set cthick 6'; 'd sqrt(uvf.3+uvo.3-2*uv.3)'
'set cstyle 2'; 'set ccolor 4'; 'set cmark 0'; 'set cthick 6'; 'd sqrt(uvf.4+uvo.4-2*uv.4)'
'draw title 'titreg

* compute and diaplay means

df=1;while(df<=4); 'set dfile 'df; 'set t 1'
'define cnt=ave(wcnt,time='ts00',time='te00')'
'define num1=ave(uvf*wcnt,time='ts00',time='te00')'
'define num2=ave(uvo*wcnt,time='ts00',time='te00')'
'define num3=ave( uv*wcnt,time='ts00',time='te00')'
'define score=sqrt((num1+num2-2*num3)/cnt)'; 'd score';
say result; line=sublin(result,1); word=subwrd(line,4)
avg.df=digs(word,2);df=df+1;endwhile

* display the mean values of the time series

'set vpage off'; 'set dignum 2'; 'set strsiz 0.10'; xp=xminp+0.3 ; yp=ymaxp
'set string 1 tl 4'; 'draw string 'xp' 'yp-0.5' 'substr(exp1,1,4)
'set string 4 tl 4'; 'draw string 'xp' 'yp-0.7' 'avg.2
'set string 2 tl 4'; 'draw string 'xp' 'yp-0.9' 'avg.1
'set string 1 tl 4'; 'draw string 'xp' 'yp-1.1' 'substr(exp2,1,4)
'set string 4 tl 4'; 'draw string 'xp' 'yp-1.3' 'avg.4
'set string 2 tl 4'; 'draw string 'xp' 'yp-1.5' 'avg.3
'set string 1 tl 4'; 'draw string 'xp' 'yp-1.7'  diff'
'set string 4 tl 4'; 'draw string 'xp' 'yp-1.9' 'math_format("%6.2f",avg.2-avg.4)
'set string 2 tl 4'; 'draw string 'xp' 'yp-2.1' 'math_format("%6.2f",avg.1-avg.3)

reg=reg+1
endwhile

'run 'gdir'/linesmpos.gs 'ctldir'/legf'fcs1'af'fcs2' 4.75 0.25 8.5 2.5'

'printim 'pngfile' png x650 y700'
*
levx=levx+1
endwhile
*
sub=sub+1
endwhile
*
'quit'
function getreg(reg)
if(reg=1);titreg='Global';endif;
if(reg=2);titreg='North Hemis';endif;
if(reg=3);titreg='South Hemis';endif;
if(reg=4);titreg='Tropics';endif;
if(reg=5);titreg='North America';endif;
if(reg=6);titreg='Europe';endif;
if(reg=7);titreg='Asia';endif;
return titreg
function getsub(sub)
if(sub=1);titsub='RAOBS';endif;
if(sub=2);titsub='ADPSFC';endif;
if(sub=3);titsub='SFCSHP';endif;
if(sub=4);titsub='AIRCFT';endif;
if(sub=5);titsub='AIRCAR';endif;
if(sub=6);titsub='SATWND';endif;
if(sub=7);titsub='SATEMP';endif;
if(sub=8);titsub='PROFLR';endif;
return titsub
function getgsub(sub)
if(sub=1);gsub='adp';endif;
if(sub=2);gsub='sfc';endif;
if(sub=3);gsub='shp';endif;
if(sub=4);gsub='acft';endif;
if(sub=5);gsub='acar';endif;
if(sub=6);gsub='satw';endif;
if(sub=7);gsub='satt';endif;
if(sub=8);gsub='prfl';endif;
return gsub
function getxmin(reg)
if(reg=1);xminp=0.;endif;
if(reg=2);xminp=4.;endif;
if(reg=3);xminp=0.;endif;
if(reg=4);xminp=4.;endif;
if(reg=5);xminp=0.;endif;
if(reg=6);xminp=4.;endif;
if(reg=7);xminp=0.;endif;
return xminp
function getxmax(reg)
if(reg=1);xmaxp=4.5;endif;
if(reg=2);xmaxp=8.5;endif;
if(reg=3);xmaxp=4.5;endif;
if(reg=4);xmaxp=8.5;endif;
if(reg=5);xmaxp=4.5;endif;
if(reg=6);xmaxp=8.5;endif;
if(reg=7);xmaxp=4.5;endif;
return xmaxp
function getymin(reg)
if(reg=1);yminp=8.1;endif;
if(reg=2);yminp=8.1;endif;
if(reg=3);yminp=5.4;endif;
if(reg=4);yminp=5.4;endif;
if(reg=5);yminp=2.7;endif;
if(reg=6);yminp=2.7;endif;
if(reg=7);yminp=0.;endif;
return yminp
function getymax(reg)
if(reg=1);ymaxp=10.8;endif;
if(reg=2);ymaxp=10.8;endif;
if(reg=3);ymaxp=8.1;endif;
if(reg=4);ymaxp=8.1;endif;
if(reg=5);ymaxp=5.4;endif;
if(reg=6);ymaxp=5.4;endif;
if(reg=7);ymaxp=2.7;endif;
return ymaxp
function digs(string,num)
  nc=0
  pt=""
  while(pt = "")
    nc=nc+1
    zzz=substr(string,nc,1)
    if(zzz = "." | zzz = ""); break; endif
  endwhile
  end=nc+num
  str=substr(string,1,end)
return str
function getlev(levx)
if(levx=1) ;return   20; endif;
if(levx=2) ;return   30; endif;
if(levx=3) ;return   50; endif;
if(levx=4) ;return   70; endif;
if(levx=5) ;return  100; endif;
if(levx=6) ;return  150; endif;
if(levx=7) ;return  200; endif;
if(levx=8) ;return  250; endif;
if(levx=9) ;return  300; endif;
if(levx=10);return  400; endif;
if(levx=11);return  500; endif;
if(levx=12);return  700; endif;
if(levx=13);return  850; endif;
if(levx=14);return  925; endif;
if(levx=15);return 1000; endif;
return xxx
