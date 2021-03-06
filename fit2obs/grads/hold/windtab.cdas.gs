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
*
var=w
titvar='Wind'
*
**  reg=1 is gl; reg=2 is nh; reg=3 is sh; reg=4 is tr; tr=5 is na; tr=6 is eu; as=asia
regs=1
rege=7
*
**  sub=1 is adpupa
subs=1
sube=1
*
**  =1 is 850 mb; =2 is 700 mb ; =3 is 500 mb; =4 is 200 mb; =5 is 30 mb
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
if(level<=1000)
ymin=0
ymax=10
endif
if(level<=700)
ymin=0
ymax=10
endif
if(level<=500)
ymin=0
ymax=12
endif
if(level<=200)
ymin=0
ymax=15
endif
if(level<=30)
ymin=0
ymax=12
endif
*
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
'reset'
'set display color white'
'clear'
*
*grfile=pdir'/'var''level'.all.'gsub'.gr'
*say grfile
*'enable print 'grfile
giffile=pdir'/'var''level'.all.'gsub'.gif'
say giffile
*
'set vpage 0 8.5 0 11'
'set strsiz 0.1'
'set string 4 tl 6'
'draw string 0.12 0.12 'namstr
*
'set strsiz 0.15'
'set string 2 tl 6'
'draw string 0.1 10.8 'titvar' 'level' mb RMS Fit to 'titsub' 'ts00' - 'te00
*
'run 'gdir'/linesmpos.gs 'ctldir'/legf'fcs1'af'fcs2' 6 0.5 8 2.2'
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
'set lev 'level
'set time 'ts00' 'te00
'set xlopts 1 4 0.15'
'set ylopts 1 4 0.15'
'set cstyle 1'
'set ccolor 1'
'set cmark 0'
'set cthick 4'
'set axlim 'ymin' 'ymax
'd sqrt(uvf.1+uvo.1-2*uv.1)'
'set cstyle 1'
'set ccolor 2'
'set cmark 0'
'set cthick 4'
'set axlim 'ymin' 'ymax
'd sqrt(uvf.2+uvo.2-2*uv.2)'
'set cstyle 5'
'set ccolor 1'
'set cmark 0'
'set cthick 6'
'set axlim 'ymin' 'ymax
'd sqrt(uvf.3+uvo.3-2*uv.3)'
'set cstyle 5'
'set ccolor 2'
'set cmark 0'
'set cthick 6'
'set axlim 'ymin' 'ymax
'd sqrt(uvf.4+uvo.4-2*uv.4)'
'draw title 'titreg
*
'set dfile 1'
'set t 1'
'define tcnt=ave(wcnt.1,time='ts00',time='te00')'
'define num1=ave(uvf.1*wcnt.1,time='ts00',time='te00')'
'define num2=ave(uvo.1*wcnt.1,time='ts00',time='te00')'
'define num3=ave(uv.1*wcnt.1,time='ts00',time='te00')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f00a=digs(word,2)
'set dfile 2'
'set t 1'
'define tcnt=ave(wcnt.2,time='ts00',time='te00')'
'define num1=ave(uvf.2*wcnt.2,time='ts00',time='te00')'
'define num2=ave(uvo.2*wcnt.2,time='ts00',time='te00')'
'define num3=ave(uv.2*wcnt.2,time='ts00',time='te00')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f06a=digs(word,2)
'set dfile 3'
'set t 1'
'define tcnt=ave(wcnt.3,time='ts12',time='te12')'
'define num1=ave(uvf.3*wcnt.3,time='ts12',time='te12')'
'define num2=ave(uvo.3*wcnt.3,time='ts12',time='te12')'
'define num3=ave(uv.3*wcnt.3,time='ts12',time='te12')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f00b=digs(word,2)
'set dfile 4'
'set t 1'
'define tcnt=ave(wcnt.4,time='ts00',time='te00')'
'define num1=ave(uvf.4*wcnt.4,time='ts00',time='te00')'
'define num2=ave(uvo.4*wcnt.4,time='ts00',time='te00')'
'define num3=ave(uv.4*wcnt.4,time='ts00',time='te00')'
'define num1=num1/tcnt'
'define num2=num2/tcnt'
'define num3=num3/tcnt'
'define score=sqrt(num1+num2-2*num3)'
'd score'
say result
line=sublin(result,1)
word=subwrd(line,4)
f06b=digs(word,2)
*
'set vpage 0 8.5 0 11'
'set strsiz 0.12'
xpos=xminp+0.3
ypos=ymaxp-0.6
'set string 1 tl 4'
'draw string 'xpos' 'ypos' 'exp1
ypos=ymaxp-0.8
'set string 2 tl 4'
'draw string 'xpos' 'ypos' 'f06a
ypos=ymaxp-1.0
'set string 1 tl 4'
'draw string 'xpos' 'ypos' 'f00a
ypos=ymaxp-1.2
'set string 1 tl 4'
'draw string 'xpos' 'ypos' 'exp2
ypos=ymaxp-1.4
'set string 2 tl 4'
'draw string 'xpos' 'ypos' 'f06b
ypos=ymaxp-1.6
'set string 1 tl 4'
'draw string 'xpos' 'ypos' 'f00b
*
reg=reg+1
endwhile
*
'printim 'giffile' gif x650 y700'
*'print'
*'disable print'
*say 'type in c to continue or quit to exit'
*pull corquit
*corquit
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
