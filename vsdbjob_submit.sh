#!/bin/ksh
set -ux

##-------------------------------------------------------------------
## Fanglin Yang,  September 2010
## E-mail: fanglin.yang@noaa.gov, Tel: 301-6833722          
## Global Weather and Climate Modeling Branch, EMC/NCEP/NOAA/
##    This package generates forecast perfomance stats in VSDB format 
##    and makes a variety of graphics to compare anomaly correlation 
##    and RMSE among different experiments. It also makes graphics of
##    CONUS precip skill scores, and fits to rawindsonde and surafce 
##    observations, forecast maps and analysis increments maps.
##    The different components can be turned on or off as desired. 
##    Graphics are sent to a web server for display (for example:  
##    http://www.emc.ncep.noaa.gov/gmb/wx24fy/vsdb/gfs2016/)
##-------------------------------------------------------------------

#..............
MAKEVSDBDATA=YES          ;#To create VSDB date
MAKEMAPS=NO                ;#To make AC and RMS maps
#..............

#..............
CONUSDATA=YES              ;#To generate precip verification stats
CONUSPLOTS=NO              ;#To make precip verification maps
#..............

FIT2OBS=NO                ;#To make fit-to-obs maps              

MAPS2D=NO                  ;#To make forecast maps including lat-lon and zonal-mean distributions          

MAPSGDAS=NO              ;#To make analysis maps of time-mean increments

MAPSENS=NO               ;#To make maps of ENKF ensemble mean and ensemble spread

#----------------------------------------------------------------------
export machine=HERA               ;#WCOSS, WCOSS_C, WCOSS_D, HERA, JET etc         
export machine=$(echo $machine|tr '[a-z]' '[A-Z]')
myhome=`pwd`
set -a;. ${myhome}/setup_envs.sh $machine 
if [ $? -ne 0 -o $rc -gt 0 ]; then exit; fi
set -ux

export DATA=$STMP/$LOGNAME
export tmpdir=$STMP/$LOGNAME/nwpvrfy$$               ;#temporary directory for running verification
export mapdir=$tmpdir/web                            ;#local directory to display plots and web templates
mkdir -p $tmpdir ||exit
if [ ! -d $mapdir ]; then
 mkdir -p $mapdir ; cd $mapdir ||exit
 tar xvf ${vsdbhome}/vsdb_exp_webpage.tar 
fi
cd $tmpdir ||exit
rm *.out

myarch=$GNOSCRUB/$LOGNAME/archive              ;#archive directory of experiments 
COMROT=$PTMP/$LOGNAME/COMROT                   ;#running directory of experiments
chost=$(hostname)                              ;#current computer host name

export doftp="NO"                                               ;#whether or not to send maps to web server
export webhost=emcrzdm.ncep.noaa.gov                            ;#host for web display
export webhostid=$LOGNAME                                       ;#login id on webhost
export ftpdir=/home/people/emc/www/htdocs/gmb/$webhostid/vsdb   ;#where maps are displayed on webhost

### --------------------------------------------------------------
###   make vsdb database
      if [ $MAKEVSDBDATA = YES ] ; then
### --------------------------------------------------------------
export fcyclist="00"                           ;#forecast cycles to be verified
export expnlist="testa"                        ;#experiment names 
export expdlist="$myarch"                      ;#exp directories, can be different
export complist="$chost"                       ;#computer names, can be different if passwordless ftp works 
export dumplist=".gfs."                        ;#file format pgb${asub}${fhr}${dump}${yyyymmdd}${cyc}
export vhrlist="00"                            ;#verification hours for each day             
export DATEST=20200101                         ;#verification starting date
export DATEND=20200131                         ;#verification ending date
export vlength=240                             ;#forecast length in hour

export rundir=$tmpdir/stats
export listvar1=fcyclist,expnlist,expdlist,complist,dumplist,vhrlist,DATEST,DATEND,vlength,rundir,APRUN
export listvar2=machine,anl_type,iauf00,scppgb,sfcvsdb,canldir,ecmanldir,vsdbsave,vsdbhome,gd,NWPROD,batch
export listvar="$listvar1,$listvar2"

## pgb files must be saved as $expdlist/$expnlist/pgbf${fhr}${cdump}${yyyymmdd}${cyc}
if [ $batch = YES ]; then
  $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/N -r 4096/1 -t 6:00:00 \
     -j vstep1 -o $tmpdir/vstep1.out  ${vsdbhome}/verify_exp_step1.sh
else
     ${vsdbhome}/verify_exp_step1.sh 1>${tmpdir}/vstep1.out 2>&1
fi

### --------------------------------------------------------------
      fi                                       
### --------------------------------------------------------------


 
### --------------------------------------------------------------
###   make AC and RMSE maps            
      if [ $MAKEMAPS = YES ] ; then
### --------------------------------------------------------------
#
export fcycle="00"                         ;#forecast cycles to be verified
export mdlist="gfsv16 testa"               ;#experiment names, up to 10, to compare on maps
export caplist="gfsv16 testa"              ;#captions of experiments shown in plots      
export vsdblist="$gfsvsdb $vsdbsave"       ;#vsdb stats directories 
export vhrlist="00"                        ;#verification hours for each day to show on map
export DATEST=20200101                     ;#verification starting date to show on map
export DATEND=20200131                     ;#verification ending date to show on map
export vlength=240                         ;#forecast length in hour to show on map
export maptop=10                           ;#can be set to 10, 50 or 100 hPa for cross-section maps
export maskmiss=1                          ;#remove missing data from all models to unify sample size, 0-->NO, 1-->Yes
export rundir=$tmpdir/acrms$$
export scoredir=$rundir/score
export scorecard=YES
export day4card="1 3 5 6 8 10"             ;#fcst days shown on scorecard

  ${vsdbhome}/verify_exp_step2.sh  1>${tmpdir}/vstep2.out 2>&1 


##--wait 3 hours for all stats to be created and then generate scorecard 
if [ ${scorecard:-NO} = YES ]; then
 if [ $batch = YES ]; then
   listvar=DATEST,DATEND,mdlist,webhostid,webhost,ftpdir,doftp,rundir,scoredir,vsdbhome,mapdir,day4card
   $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2FTP -g $GROUP -p 1/1/S -r 1024/1 -t 1:00:00 -w +0300 \
      -j scorecard -o $rundir/score.out  ${vsdbhome}/run_scorecard.sh   
 else
    sleep 10800
    ${vsdbhome}/run_scorecard.sh  1>$rundir/score.out 2>&1 
 fi
fi
### --------------------------------------------------------------
    fi
### --------------------------------------------------------------



### --------------------------------------------------------------
###   compute precip threat score stats over CONUS   
      if [ $CONUSDATA = YES ] ; then
### --------------------------------------------------------------
#-------------------
for cyc in 00 12; do
#-------------------
export expnlist="testa"                                  ;#experiment names
export expdlist="$myarch"                                ;#fcst data directories, can be different
export complist="$chost"                                 ;#computer names, can be different if passwordless ftp works 
export ftyplist="flxf"                                   ;#file types: pgbq or flxf
export dumplist=".gfs."                                  ;#file format ${ftyp}f${fhr}${dump}${yyyymmdd}${cyc}
export ptyplist="PRATE"                                  ;#precip types in GRIB: PRATE or APCP
export bucket=6                                          ;#accumulation bucket in hours. bucket=0 -- continuous accumulation
export fhout=6                                           ;#forecast output frequency in hours
export cycle="$cyc"                                      ;#forecast cycle to verify, give only one
export DATEST=20200101                                   ;#forecast starting date 
export DATEND=20200131                                   ;#forecast ending date 
export vhour=180                                         ;#verification length in hour
export ARCDIR=$GNOSCRUB/$LOGNAME/archive                 ;#directory to save stats data
export rundir=$tmpdir/mkup_precip$cyc                    ;#temporary running directory
export runhpss=YES                                       ;#retrieve missing data from HPSS archive
export scrdir=${vsdbhome}/precip                  
                                                                                                                           
export listvar1=expnlist,expdlist,hpsslist,complist,ftyplist,dumplist,ptyplist,bucket,fhout,cycle
export listvar2=machine,DATEST,DATEND,ARCDIR,rundir,scrdir,OBSPCP,mapdir,scppgb,NWPROD,APRUN,batch
export listvar="$listvar1,$listvar2"

if [ $batch = YES ]; then
  $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2FTP -g $GROUP -p 1/1/N -r 2048/1 -t 06:00:00  \
    -j mkup_rain_stat.sh -o $tmpdir/mkup_rain_stat.out ${scrdir}/mkup_rain_stat.sh
else
    ${scrdir}/mkup_rain_stat.sh  1>${tmpdir}/mkup_rain_stat.out 2>&1       
fi
#-------------------
done                   
#-------------------
### --------------------------------------------------------------
      fi
### --------------------------------------------------------------


### --------------------------------------------------------------
###   make CONUS precip skill score maps 
      if [ $CONUSPLOTS = YES ] ; then
### --------------------------------------------------------------
export expnlist="gfs testa"                               ;#experiment names, up to 6 , gfs is operational GFS
export caplist="gfs testa"                                ;#captions of experiments shown in plots      
export expdlist="${gfswgnedir} $myarch"                   ;#fcst data directories, can be different
export complist="$chost  $chost "                         ;#computer names, can be different if passwordless ftp works 
export cyclist="00 12"                                    ;#forecast cycles for making QPF maps, 00Z and/or 12Z 
export vhour="180"                                         ;#forecast length for making QPF maps 
export DATEST=20200101                                    ;#forecast starting date to show on map
export DATEND=20200131                                    ;#forecast ending date to show on map
export rundir=$tmpdir/plot_pcp
export scrdir=${vsdbhome}/precip                  
                                                                                                                           
export listvar1=expnlist,expdlist,complist,cyclist,DATEST,DATEND,rundir,scrdir,vhour
export listvar2=doftp,webhost,webhostid,ftpdir,scppgb,gstat,NWPROD,mapdir,GRADSBIN
export listvar3=vsdbhome,SUBJOB,ACCOUNT,GROUP,CUE2RUN,CUE2FTP
export listvar="$listvar1,$listvar2,$listvar3"

if [ $batch = YES ]; then
  $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/S -r 2048/1 -t 01:00:00  \
    -j plot_pcp -o $tmpdir/plot_pcp.out ${scrdir}/plot_pcp.sh
else
    ${scrdir}/plot_pcp.sh 1>${tmpdir}/plot_pcp.out 2>&1 
fi
### --------------------------------------------------------------
      fi
### --------------------------------------------------------------
                                                                                                                           

### --------------------------------------------------------------
###   make fit-to-obs plots
      if [ $FIT2OBS = YES ] ; then
### --------------------------------------------------------------
export expnlist="fnl testa"                                ;#experiment names, only two allowed, fnl is operatinal GFS
export expdlist="$gfsfitdir $myarch"                    ;#fcst data directories, can be different
export complist="$chost  $chost "                         ;#computer names, can be different if passwordless ftp works
export endianlist="little little"           ;#big_endian or little_endian of fits data, CCS-big, Zeus-little
export cycle="00"                                         ;#forecast cycle to verify, only one cycle allowed
export oinc_f2o=24                                         ;#increment (hours) between observation verify times for timeout plots
export finc_f2o=12                                         ;#increment (hours) between forecast lengths for timeout plots
export fmax_f2o=120                                       ;#max forecast length to show for timeout plots
export DATEST=20200101                                    ;#forecast starting date to show on map
export DATEND=20200131                                    ;#forecast ending date to show on map
export rundir=$tmpdir/fit
export scrdir=${vsdbhome}/fit2obs

 ${scrdir}/fit2obs.sh 1>${tmpdir}/fit2obs.out 2>&1 
### --------------------------------------------------------------
      fi
### --------------------------------------------------------------


### --------------------------------------------------------------
### make forecast maps including lat-lon and zonal-mean distributions          
      if [ $MAPS2D = YES ] ; then
### --------------------------------------------------------------
export expnlist="gfs testa"          ;#experiments, up to 8; gfs will point to ops data
export expdlist="$gstat  $myarch"    ;#fcst data directories, can be different
export complist="$chost  $chost "    ;#computer names, can be different if passwordless ftp works 
export dumplist=".gfs. .gfs."        ;#file format pgb${asub}${fhr}${dump}${yyyymmdd}${cyc}

export fdlist="anl 1 5 10"            ;#fcst day to verify, e.g., d-5 uses f120 f114 f108 and f102; anl-->analysis; -1->skip
                                      #note: these maps take a long time to make. be patient or set fewer cases
#export fhlist1="f06 f06 f18 f18"     ;#may specify exact fcst hours to compare for a specific day, must be four
#export fhlist5="f120 f120 f120 f120" ;#may specify exact fcst hours to compare for a specific day, must be four
export cycle="00"                     ;#forecast cycle to verify, given only one
export DATEST=20200101                ;#starting verifying date
export ndays=31                        ;#number of days (cases)

export ceres=no                       ;#no uses srb/isccp obs, yes uses ceres obs
export fma=no                         ;#make forecast-analysis maps, default=yes
export nlev=41                        ;#pgb file vertical layers
export grid=G2                        ;#pgb file resolution, G2-> 2.5deg;   G3-> 1deg
export pbtm=1000                      ;#bottom pressure for zonal mean maps
export ptop=0.01                      ;#top pressure for zonal mean maps
export latlon="-90 90 0 360"          ;#map area lat1, lat2, lon1 and lon2
export rundir=$tmpdir/2dmaps
export batch=NO

export climo_ceres=no                 ;#plot CERES climatology (yes) or monthly means (no); "no" valid Mar2000-Jun2016
export use_calipso_cldfrc=no          ;#plot cloud fractions use CALIPSO climatology; **only use if climo_ceres set to 'yes'**
export climo_gpcp=no                  ;#plot GPCP climatology (yes) or monthly means (no); "no" valid Mar2000-Jul2016
export climo_ghcncams=no              ;#plot GHCN CAMS climatology (yes) or monthly means (no); "no" valid Mar2000-Nov2016

export listvara=machine,gstat,expnlist,expdlist,complist,dumplist,cycle,DATEST,ndays,nlev,grid,pbtm,ptop,latlon
export listvarb=rundir,mapdir,obdata,webhost,webhostid,ftpdir,doftp,NWPROD,APRUN,vsdbhome,GRADSBIN,batch
export listvarc=SUBJOB,ACCOUNT,GROUP,CUE2RUN,CUE2FTP,climo_ceres,use_calipso_cldfrc,climo_gpcp,climo_ghcncams

export odir=0
for fcstday in $fdlist ; do
 export odir=`expr $odir + 1 `
 export fcst_day=$fcstday
 export listvar=$listvara,$listvarb,$listvarc,odir,fcst_day,fhlist$fcst_day

 if [ $batch = YES ]; then
     if [ $ceres = YES ]; then
        $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/N -r 2048/1 -t 6:00:00 \
     -j map2d$odir -o $tmpdir/2dmaps${odir}.out  ${vsdbhome}/plot2d/maps2d_newCERES.sh
     else
        $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/N -r 2048/1 -t 6:00:00 \
     -j map2d$odir -o $tmpdir/2dmaps${odir}.out  ${vsdbhome}/plot2d/maps2d_new.sh
     fi
 else
     if [ $ceres = YES ]; then
        ${vsdbhome}/plot2d/maps2d_newCERES.sh  1>${tmpdir}/2dmaps${odir}.out 2>&1 &
     else
        ${vsdbhome}/plot2d/maps2d_new.sh  1>${tmpdir}/2dmaps${odir}.out 2>&1 &
     fi
 fi
done
### --------------------------------------------------------------
      fi                                       
### --------------------------------------------------------------


### --------------------------------------------------------------
### make analysis maps of time-mean increments
      if [ $MAPSGDAS = YES ] ; then
### --------------------------------------------------------------
export expnlist="gfs pr4dev"         ;#experiments, up to 8
export expdlist="$gstat /global/noscrub/emc.glopara/archive" ;#data archive
export hpsslist="/NCEPPROD/hpssprod/runhistory /5year/NCEPDEV/emc-global/emc.glopara/WCOSS"  ;#hpss arch
export dumplist=".gdas. .gdas."      ;#file format siganl${dum}${cdate} and sigges${dump}$cdate
export complist="tide tide"          ;#computers where data are archived  

export cyclist="00 06 12 18"         ;#forecast cycles to verify, can include one to four
export DATEST=20150210               ;#starting verifying date for siganl
export DATEND=20150228               ;#starting verifying date for siganl

export pbtm=1000                     ;#bottom model layer number (or pressure if using pgb files) for zonal mean maps
export ptop=1                        ;#top model layer number (or pressure if using pgb files) for zonal mean maps
export nlev=31                       ;#vertical layers for sigma file (64 for gfs) or pgb file (31 for gfs)
export latlon="-90 90 0 360"         ;#map area lat1, lat2, lon1 and lon2
export rundir=$tmpdir/gdasmaps
export batch=NO                      ;#to run job in batch mode

export listvara=machine,gstat,expnlist,expdlist,hpsslist,complist,dumplist,cyclist,DATEST,DATEND,nlev,pbtm,ptop,latlon
export listvarb=rundir,mapdir,webhost,webhostid,ftpdir,doftp,NWPROD,APRUN,vsdbhome,GRADSBIN
export listvarc=SUBJOB,ACCOUNT,GROUP,CUE2RUN,CUE2FTP,batch
export listvar=$listvara,$listvarb,$listvarc

if [ $batch = YES ]; then
 $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/N -r 2048/1 -t 6:00:00 \
    -j mapgdas -o $tmpdir/mapsgdas.out  ${vsdbhome}/plot2d/maps2d_gdas_pgb.sh
#   -j mapgdas -o $tmpdir/mapsgdas.out  ${vsdbhome}/plot2d/maps2d_gdas_sig.sh
else
 ${vsdbhome}/plot2d/maps2d_gdas_pgb.sh  1>${tmpdir}/mapsgdas.out 2>&1 &
#${vsdbhome}/plot2d/maps2d_gdas_sig.sh  1>${tmpdir}/mapsgdas.out 2>&1 &
fi
### --------------------------------------------------------------
      fi                                       
### --------------------------------------------------------------


### --------------------------------------------------------------
### make maps of ENKF ensemble mean and ensemble spread, which must
##  be precomputed outside of this program.
      if [ $MAPSENS = YES ] ; then
### --------------------------------------------------------------
export expnlist="test5 test6"        ;#experiments, up to 8
export expdlist="/stmpd2/Fanglin.Yang /stmpd2/Fanglin.Yang"    ;#data archive
export cyclist="00 06 12 18"         ;#analysis cycles to be included 
export geshour="06"                  ;#enkf forecast hours to be verified
export DATEST=20140401               ;#starting verifying date
export DATEND=20140401               ;#endding verifying date

export JCAP_bin=254                  ;#binary file resolution, linear T254->512x256 etc
export pbtm=1                        ;#bottom model layer number for zonal mean maps
export ptop=64                       ;#top model layer number for zonal mean maps
export nlev=64                       ;#sigma file vertical layers, fix to 64 for gfs
export latlon="-90 90 0 360"         ;#map area lat1, lat2, lon1 and lon2
export levsig="1 7 11 14 20 25 31 35 41 46 49 55 58 61" ;#sigma layers for lat-lon maps,up to 14
export rundir=$tmpdir/ensmaps 
export batch=NO                      ;#to run job in batch mode

export listvara=machine,expnlist,expdlist,cyclist,geshour,DATEST,DATEND,nlev,pbtm,ptop,latlon,levsig
export listvarb=rundir,mapdir,webhost,webhostid,ftpdir,doftp,NWPROD,APRUN,vsdbhome,GRADSBIN
export listvarc=SUBJOB,ACCOUNT,GROUP,CUE2RUN,CUE2FTP,batch
export listvar=$listvara,$listvarb,$listvarc

if [ $batch = YES ]; then
 $SUBJOB -e $listvar -a $ACCOUNT  -q $CUE2RUN -g $GROUP -p 1/1/N -r 2048/1 -t 6:00:00 \
    -j mapens -o $tmpdir/mapens.out  ${vsdbhome}/plot2d/maps2d_ensspread.sh
else
 ${vsdbhome}/plot2d/maps2d_ensspread.sh 1>${tmpdir}/mapens.out 2>&1 &
fi
### --------------------------------------------------------------
      fi                                       
### --------------------------------------------------------------


exit

