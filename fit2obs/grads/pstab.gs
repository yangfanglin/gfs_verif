function windt(args)
ts00=subwrd(args,1)
te00=subwrd(args,2)
ts12=subwrd(args,3)
te12=subwrd(args,4)
pdir=subwrd(args,5)
gdir=subwrd(args,6)
exp=subwrd(args,7)
mean=subwrd(args,8)
ctldir=subwrd(args,9)
namstr=subwrd(args,10)

var=p
titvar='Surface Pressure'
*
**  reg=1 is gl; reg=2 is nh; reg=3 is sh; reg=4 is tr; tr=5 is na; tr=6 is eu; as=asia
regs=1
rege=7
*
**  sub=1 is adpsfc; sub=2 is sfcshp
subs=1
sube=2
*
sub=subs
while (sub<=sube)
titsub=getsub(sub)
gsub=getgsub(sub)
*
ymin=0
ymax=5
*
'open 'ctldir'/'exp'.f00.sfc.ctl'
'open 'ctldir'/'exp'.f06.sfc.ctl'
'open 'ctldir'/'exp'.f12.sfc.ctl'
'open 'ctldir'/'exp'.f24.sfc.ctl'
'open 'ctldir'/'exp'.f36.sfc.ctl'
'open 'ctldir'/'exp'.f48.sfc.ctl'
*
'reset'
'set display color white'
'clear'
*
*grfile=pdir'/'var'.all.'gsub'.gr'
*say grfile
*'enable print 'grfile
pngfile=pdir'/'var'.all.'gsub'.png'
say pngfile
*
'set vpage 0 8.5 0 11'
'set strsiz 0.1'
'set string 4 tl 6'
'draw string 0.12 0.12 'namstr
*
'set strsiz 0.15'
'set string 2 tl 6'
'draw string 0.3 10.8 'exp' 'titsub' 'titvar' RMS Fit 'ts00' - 'te00
*
'run 'gdir'/linesmpos.gs 'gdir'/legexp 6 0.5 8 2.2'
*
reg=regs
while (reg<=rege)
titreg=getreg(reg)
*
xminp=getxmin(reg)
xmaxp=getxmax(reg)
yminp=getymin(reg)
ymaxp=getymax(reg)
*
'set vpage 'xminp' 'xmaxp' 'yminp' 'ymaxp
'set grads off'
'set x 'reg
'set y 'sub
'set time 'ts00' 'te00
'set xlopts 1 4 0.15'
'set ylopts 1 4 0.15'
'set cstyle 1'
'set ccolor 1'
'set cmark 1'
'set cthick 4'
'set axlim 'ymin' 'ymax
'd sqrt(pfs.1+pos.1-2*pfo.1)'
'set cstyle 1'
'set ccolor 2'
'set cmark 6'
'set cthick 4'
'set axlim 'ymin' 'ymax
'd sqrt(pfs.2+pos.2-2*pfo.2)'
'set cstyle 1'
'set ccolor 3'
'set cmark 3'
'set cthick 4'
'set axlim 'ymin' 'ymax
'd sqrt(pfs.3+pos.3-2*pfo.3)'
'set cstyle 1'
'set ccolor 4'
'set cmark 4'
'set cthick 4'
'set axlim 'ymin' 'ymax
'd sqrt(pfs.4+pos.4-2*pfo.4)'
'set cstyle 1'
'set ccolor 5'
'set cmark 5'
'set cthick 4'
'set axlim 'ymin' 'ymax
'd sqrt(pfs.5+pos.5-2*pfo.5)'
'set cstyle 1'
'set ccolor 6'
'set cmark 2'
'set cthick 4'
'set axlim 'ymin' 'ymax
'd sqrt(pfs.6+pos.6-2*pfo.6)'
'draw title 'exp' 'titreg
*
if(mean=1)
'set dfile 1'
'set t 1'
'define tcnt=ave(pcnt.1,time='ts00',time='te00')'
'define num1=ave(pfs.1*pcnt.1,time='ts00',time='te00')'
'define num2=ave(pos.1*pcnt.1,time='ts00',time='te00')'
'define num3=ave(pfo.1*pcnt.1,time='ts00',time='te00')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f00=digs(word,2)
'set dfile 2'
'set t 1'
'define tcnt=ave(pcnt.2,time='ts00',time='te00')'
'define num1=ave(pfs.2*pcnt.2,time='ts00',time='te00')'
'define num2=ave(pos.2*pcnt.2,time='ts00',time='te00')'
'define num3=ave(pfo.2*pcnt.2,time='ts00',time='te00')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f06=digs(word,2)
'set dfile 3'
'set t 1'
'define tcnt=ave(pcnt.3,time='ts12',time='te12')'
'define num1=ave(pfs.3*pcnt.3,time='ts12',time='te12')'
'define num2=ave(pos.3*pcnt.3,time='ts12',time='te12')'
'define num3=ave(pfo.3*pcnt.3,time='ts12',time='te12')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f12=digs(word,2)
'set dfile 4'
'set t 1'
'define tcnt=ave(pcnt.4,time='ts00',time='te00')'
'define num1=ave(pfs.4*pcnt.4,time='ts00',time='te00')'
'define num2=ave(pos.4*pcnt.4,time='ts00',time='te00')'
'define num3=ave(pfo.4*pcnt.4,time='ts00',time='te00')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f24=digs(word,2)
'set dfile 5'
'set t 1'
'define tcnt=ave(pcnt.5,time='ts12',time='te12')'
'define num1=ave(pfs.5*pcnt.5,time='ts12',time='te12')'
'define num2=ave(pos.5*pcnt.5,time='ts12',time='te12')'
'define num3=ave(pfo.5*pcnt.5,time='ts12',time='te12')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f36=digs(word,2)
'set dfile 6'
'set t 1'
'define tcnt=ave(pcnt.6,time='ts00',time='te00')'
'define num1=ave(pfs.6*pcnt.6,time='ts00',time='te00')'
'define num2=ave(pos.6*pcnt.6,time='ts00',time='te00')'
'define num3=ave(pfo.6*pcnt.6,time='ts00',time='te00')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f48=digs(word,2)
'set vpage 0 8.5 0 11'
'set strsiz 0.12'
xpos=xminp+0.3
ypos=ymaxp-0.8
'set string 6 tl 4'
'draw string 'xpos' 'ypos' 'f48
ypos=ymaxp-1.0
'set string 5 tl 4'
'draw string 'xpos' 'ypos' 'f36
ypos=ymaxp-1.2
'set string 4 tl 4'
'draw string 'xpos' 'ypos' 'f24
ypos=ymaxp-1.4
'set string 3 tl 4'
'draw string 'xpos' 'ypos' 'f12
ypos=ymaxp-1.6
'set string 2 tl 4'
'draw string 'xpos' 'ypos' 'f06
ypos=ymaxp-1.8
'set string 1 tl 4'
'draw string 'xpos' 'ypos' 'f00
endif
*
reg=reg+1
endwhile
*
'printim 'pngfile' png x550 y720'
*'print'
*'disable print'
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
if(sub=1);titsub='LAND';endif;
if(sub=2);titsub='OCEAN';endif;
return titsub
function getgsub(sub)
if(sub=1);gsub='sfc';endif;
if(sub=2);gsub='shp';endif;
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
