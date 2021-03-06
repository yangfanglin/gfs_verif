#!/bin/sh
#set -x

#-----------------------------------------------------------
#  This script collects forecast and analysis products from 
#  different sources, and save them at savetmp              
#  for the days satisfying the verfication length.  
#  Some file names are changed to follow the GFS naming convention.
#  Fanglin Yang, August 2006
#-----------------------------------------------------------
#
exp=${1:-gfs}
CDATE=${2:-$(date +%Y%m%d)00}
vlength=${3:-384}
fhout=${4:-24}
exe=${exe:-/climate/save/wx24fy/VRFY/exe}
statdir=${statdir:-/global/shared/stat}
savetmp=${savetmp:-/global/noscrub/wx24fy/global}

myhost=`echo $(hostname) |cut -c 1-1 `
if [ $myhost = c ]; then HOST=cirrus; CLIENT=stratus ; fi
if [ $myhost = s ]; then HOST=stratus; CLIENT=cirrus ; fi
if [ $myhost = d ]; then HOST=dew; CLIENT=cirrus;  fi


  if [ $exp  = "gfs" ]; then vlength=${vlength:-384}; fi
  if [ $exp  = "prx" ]; then vlength=${vlength:-384}; fi
  if [ $exp  = "ens" ]; then vlength=${vlength:-384}; fi
  if [ $exp  = "cdas" ];    then vlength=${vlength:-384}; fi
  if [ $exp  = "ecm" ];     then vlength=240; fi
  if [ $exp  = "fno" ];     then vlength=144; fi
  if [ $exp  = "cmc" ];     then vlength=144; fi
  if [ $exp  = "ukm" ];     then vlength=144; fi
  if [ $exp  = "jma" ];     then vlength=216; fi
  if [ $exp  = "nmmb" ];     then vlength=216; fi

 CDATEM1=` /nwprod/util/exec/ndate -24 $CDATE`
 IDATE=` /nwprod/util/exec/ndate -$vlength $CDATEM1`
 IDATEM1=` /nwprod/util/exec/ndate -240 $IDATE`
 IDAYM1=`echo ${IDATEM1} |cut -c 1-8`
 CYCM=`echo ${CDATE} |cut -c 9-10`

#-------------
 if [ $exp  = "gfs" ];     then 
# rm -r ${savetmp}/$exp/${exp}.${IDAYM1}                          
   loop=$IDATE
   while [ $loop -le $CDATE ]
   do
    IDAY=`echo $loop |cut -c 1-8`
    comout=${savetmp}/$exp/${exp}.${IDAY}
    mkdir -p $comout; cd $comout 

#   if [ ! -s $comout/gfs.t${CYCM}z.pgrbf${vlength} ] ; then
#   mkdir -p $comout; cd $comout 
#     if [ -s /com/gfs/prod/gfs.${IDAY}/gfs.t00z.pgrbf${vlength} ];then
#       ffcst=00
#       while [ $ffcst -le $vlength ]
#      do
#        cp /com/gfs/prod/gfs.${IDAY}/gfs.t00z.pgrbf${ffcst} .
#        cp /com/gfs/prod/gfs.${IDAY}/gfs.t06z.pgrbf${ffcst} .
#        cp /com/gfs/prod/gfs.${IDAY}/gfs.t12z.pgrbf${ffcst} .
#        cp /com/gfs/prod/gfs.${IDAY}/gfs.t18z.pgrbf${ffcst} .
#        ffcst=`expr $ffcst + $fhout `
#        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
#      done
#      cp /com/gfs/prod/gfs.${IDAY}/gfs.t00z.pgrbanl    .               
#      cp /com/gfs/prod/gfs.${IDAY}/gfs.t06z.pgrbanl    .               
#      cp /com/gfs/prod/gfs.${IDAY}/gfs.t12z.pgrbanl    .               
#      cp /com/gfs/prod/gfs.${IDAY}/gfs.t18z.pgrbanl    .               
#      cp /com/gfs/prod/gdas.${IDAY}/gdas1.t00z.pgrbanl  .                
#      cp /com/gfs/prod/gdas.${IDAY}/gdas1.t06z.pgrbanl  .                
#      cp /com/gfs/prod/gdas.${IDAY}/gdas1.t12z.pgrbanl  .                
#      cp /com/gfs/prod/gdas.${IDAY}/gdas1.t18z.pgrbanl  .                
#      cp /com/gfs/prod/gdas.${IDAY}/gdas1.t00z.pgrbf00  .                
#      cp /com/gfs/prod/gdas.${IDAY}/gdas1.t06z.pgrbf00  .                
#      cp /com/gfs/prod/gdas.${IDAY}/gdas1.t12z.pgrbf00  .                
#      cp /com/gfs/prod/gdas.${IDAY}/gdas1.t18z.pgrbf00  .                
#     else
#      scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t00z.pgrbanl    .               
#      if [ $? -eq 0 ]; then 
#       ffcst=00
#       while [ $ffcst -le $vlength ]
#       do
#         scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t00z.pgrbf${ffcst} .
#         scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t06z.pgrbf${ffcst} .
#         scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t12z.pgrbf${ffcst} .
#         scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t18z.pgrbf${ffcst} .
#        ffcst=`expr $ffcst + $fhout `
#        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
#       done
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t00z.pgrbanl    .               
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t06z.pgrbanl    .               
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t12z.pgrbanl    .               
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t18z.pgrbanl    .               
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gdas.${IDAY}/gdas1.t00z.pgrbanl  .                
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gdas.${IDAY}/gdas1.t06z.pgrbanl  .                
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gdas.${IDAY}/gdas1.t12z.pgrbanl  .                
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gdas.${IDAY}/gdas1.t18z.pgrbanl  .                
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gdas.${IDAY}/gdas1.t00z.pgrbf00  .                
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gdas.${IDAY}/gdas1.t06z.pgrbf00  .                
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gdas.${IDAY}/gdas1.t12z.pgrbf00  .                
#       scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gdas.${IDAY}/gdas1.t18z.pgrbf00  .                
#      fi
#     fi
#   fi

## look for alternative source if data are still missing           
    if [ ! -s $comout/gfs.t${CYCM}z.pgrbf${vlength} ] ; then
      if [ -s $statdir/pra/pgbf${vlength}.${IDAY}${CYCM} ]; then
         ffcst=00
         while [ $ffcst -le $vlength ]
         do
#          ln -fs $statdir/pra/pgbf${ffcst}.${IDAY}${CYCM}  gfs.t${CYCM}z.pgrbf${ffcst} 
           ln -fs $statdir/pra/pgbf${ffcst}.${IDAY}00       gfs.t00z.pgrbf${ffcst} 
           ln -fs $statdir/pra/pgbf${ffcst}.${IDAY}06       gfs.t06z.pgrbf${ffcst} 
           ln -fs $statdir/pra/pgbf${ffcst}.${IDAY}12       gfs.t12z.pgrbf${ffcst} 
           ln -fs $statdir/pra/pgbf${ffcst}.${IDAY}18       gfs.t18z.pgrbf${ffcst} 
           ffcst=`expr $ffcst + $fhout `
           [[ $ffcst -le 10 ]] && ffcst=0$ffcst
         done
         cp $statdir/pra/pgbanl.${IDAY}00       gfs.t00z.pgrbanl
         if [ $? -ne 0 ]; then ln -fs gfs.t00z.pgrbf00      gfs.t00z.pgrbanl    ;fi
         cp $statdir/pra/pgbanl.${IDAY}06       gfs.t06z.pgrbanl
         if [ $? -ne 0 ]; then ln -fs gfs.t06z.pgrbf00      gfs.t06z.pgrbanl    ;fi
         cp $statdir/pra/pgbanl.${IDAY}12       gfs.t12z.pgrbanl
         if [ $? -ne 0 ]; then ln -fs gfs.t12z.pgrbf00      gfs.t12z.pgrbanl    ;fi
         cp $statdir/pra/pgbanl.${IDAY}18       gfs.t18z.pgrbanl
         if [ $? -ne 0 ]; then ln -fs gfs.t18z.pgrbf00      gfs.t18z.pgrbanl    ;fi
      else
        ${exe}/read_gfshpssprod.sh gfs $comout ${IDAY}00      $vlength $fhout
        ${exe}/read_gfshpssprod.sh gfs $comout ${IDAY}06      $vlength $fhout
        ${exe}/read_gfshpssprod.sh gfs $comout ${IDAY}12      $vlength $fhout
        ${exe}/read_gfshpssprod.sh gfs $comout ${IDAY}18      $vlength $fhout
        if [ ! -s $comout/gfs.t00z.pgrbanl ];  then
          cp $comout/gfs.t00z.pgrbf00 $comout/gfs.t00z.pgrbanl
        fi
        if [ ! -s $comout/gfs.t06z.pgrbanl ];  then
          cp $comout/gfs.t06z.pgrbf00 $comout/gfs.t06z.pgrbanl
        fi
        if [ ! -s $comout/gfs.t12z.pgrbanl ];  then
          cp $comout/gfs.t12z.pgrbf00 $comout/gfs.t12z.pgrbanl
        fi
        if [ ! -s $comout/gfs.t18z.pgrbanl ];  then
          cp $comout/gfs.t18z.pgrbf00 $comout/gfs.t18z.pgrbanl
        fi
      fi
    fi

   loop=` /nwprod/util/exec/ndate +24 $loop`
   done
 fi
#-------------

#-------------
 if [ $exp  = "prx" ];     then 
  rm -r ${savetmp}/$exp/${exp}.${IDAYM1}                          
   loop=$IDATE
   while [ $loop -le $CDATE ]
   do
    IDAY=`echo $loop |cut -c 1-8`
    comout=${savetmp}/$exp/${exp}.${IDAY}
    if [ ! -s $comout/gfs.t18z.pgrbf${vlength} ] ; then
    mkdir -p $comout; cd $comout 
      if [ -s /com/gfs/para/gfs.${IDAY}/gfs.t00z.pgrbanl ];then
        ffcst=00
        while [ $ffcst -le $vlength ]
        do
          cp /com/gfs/para/gfs.${IDAY}/gfs.t00z.pgrbf${ffcst} .
          cp /com/gfs/para/gfs.${IDAY}/gfs.t06z.pgrbf${ffcst} .
          cp /com/gfs/para/gfs.${IDAY}/gfs.t12z.pgrbf${ffcst} .
          cp /com/gfs/para/gfs.${IDAY}/gfs.t18z.pgrbf${ffcst} .
          ffcst=`expr $ffcst + $fhout `
          [[ $ffcst -le 10 ]] && ffcst=0$ffcst
        done
        cp /com/gfs/para/gfs.${IDAY}/gfs.t00z.pgrbanl    .               
        cp /com/gfs/para/gfs.${IDAY}/gfs.t06z.pgrbanl    .               
        cp /com/gfs/para/gfs.${IDAY}/gfs.t12z.pgrbanl    .               
        cp /com/gfs/para/gfs.${IDAY}/gfs.t18z.pgrbanl    .               
        cp /com/gfs/para/gdas.${IDAY}/gdas1.t00z.pgrbanl  .                
        cp /com/gfs/para/gdas.${IDAY}/gdas1.t06z.pgrbanl  .                
        cp /com/gfs/para/gdas.${IDAY}/gdas1.t12z.pgrbanl  .                
        cp /com/gfs/para/gdas.${IDAY}/gdas1.t18z.pgrbanl  .                
        cp /com/gfs/para/gdas.${IDAY}/gdas1.t00z.pgrbf00  .                
        cp /com/gfs/para/gdas.${IDAY}/gdas1.t06z.pgrbf00  .                
        cp /com/gfs/para/gdas.${IDAY}/gdas1.t12z.pgrbf00  .                
        cp /com/gfs/para/gdas.${IDAY}/gdas1.t18z.pgrbf00  .                
      elif [ -s $statdir/prx/pgbf${vlength}.${IDAY}00 ]; then
         ffcst=00
         while [ $ffcst -le $vlength ]
         do
           cp $statdir/prx/pgbf${ffcst}.${IDAY}00  gfs.t00z.pgrbf${ffcst} 
           cp $statdir/prx/pgbf${ffcst}.${IDAY}06  gfs.t06z.pgrbf${ffcst} 
           cp $statdir/prx/pgbf${ffcst}.${IDAY}12  gfs.t12z.pgrbf${ffcst} 
           cp $statdir/prx/pgbf${ffcst}.${IDAY}18  gfs.t18z.pgrbf${ffcst} 
           ffcst=`expr $ffcst + $fhout `
           [[ $ffcst -le 10 ]] && ffcst=0$ffcst
         done
         cp $statdir/prx/pgbanl.${IDAY}00  gfs.t00z.pgrbanl
          if [ $? -ne 0 ]; then ln -fs gfs.t00z.pgrbf00      gfs.t00z.pgrbanl    ;fi
         cp $statdir/prx/pgbanl.${IDAY}06  gfs.t06z.pgrbanl
          if [ $? -ne 0 ]; then ln -fs gfs.t06z.pgrbf00      gfs.t06z.pgrbanl    ;fi
         cp $statdir/prx/pgbanl.${IDAY}12  gfs.t12z.pgrbanl
          if [ $? -ne 0 ]; then ln -fs gfs.t12z.pgrbf00      gfs.t12z.pgrbanl    ;fi
         cp $statdir/prx/pgbanl.${IDAY}18  gfs.t18z.pgrbanl
          if [ $? -ne 0 ]; then ln -fs gfs.t18z.pgrbf00      gfs.t18z.pgrbanl    ;fi
      else
        ffcst=00
        while [ $ffcst -le $vlength ]
        do
          scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gfs.${IDAY}/gfs.t00z.pgrbf${ffcst} .
          scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gfs.${IDAY}/gfs.t06z.pgrbf${ffcst} .
          scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gfs.${IDAY}/gfs.t12z.pgrbf${ffcst} .
          scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gfs.${IDAY}/gfs.t18z.pgrbf${ffcst} .
          ffcst=`expr $ffcst + $fhout `
          [[ $ffcst -le 10 ]] && ffcst=0$ffcst
        done
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gfs.${IDAY}/gfs.t00z.pgrbanl    .               
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gfs.${IDAY}/gfs.t06z.pgrbanl    .               
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gfs.${IDAY}/gfs.t12z.pgrbanl    .               
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gfs.${IDAY}/gfs.t18z.pgrbanl    .               
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gdas.${IDAY}/gdas1.t00z.pgrbanl  .                
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gdas.${IDAY}/gdas1.t06z.pgrbanl  .                
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gdas.${IDAY}/gdas1.t12z.pgrbanl  .                
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gdas.${IDAY}/gdas1.t18z.pgrbanl  .                
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gdas.${IDAY}/gdas1.t00z.pgrbf00  .                
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gdas.${IDAY}/gdas1.t06z.pgrbf00  .                
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gdas.${IDAY}/gdas1.t12z.pgrbf00  .                
        scp ${LOGNAME}@${CLIENT}.ncep.noaa.gov:/com/gfs/para/gdas.${IDAY}/gdas1.t18z.pgrbf00  .                
      fi
    fi
   loop=` /nwprod/util/exec/ndate +24 $loop`
   done
 fi
#-------------

#-------------
 if [ $exp  = "cdas" ];     then 
  rm -r ${savetmp}/$exp/${exp}.${IDAYM1}                          
   loop=$IDATE
   while [ $loop -le $CDATE ]
   do
    IDAY=`echo $loop |cut -c 1-8`
    IMON=`echo $loop |cut -c 1-6`
    comout=${savetmp}/$exp/${exp}.${IDAY}
    if [ ! -s $comout/cdas.t00z.pgrbf${vlength} ] ; then
    mkdir -p $comout; cd $comout 
     if [ -s /com/arkv/prod/cdas.${IMON}/pgb.f${vlength}${IDAY}00 ]; then
       ffcst=00
       while [ $ffcst -le $vlength ]
       do
         cp /com/arkv/prod/cdas.${IMON}/pgb.f${ffcst}${IDAY}00 cdas.t00z.pgrbf${ffcst}
         ffcst=`expr $ffcst + $fhout `
         [[ $ffcst -le 10 ]] && ffcst=0$ffcst
       done
     elif [ -s $statdir/prc/pgbf${vlength}.${IDAY}00 ]; then
       ffcst=00
       while [ $ffcst -le $vlength ]
       do
         ln -fs $statdir/prc/pgbf${ffcst}.${IDAY}00  cdas.t00z.pgrbf${ffcst} 
         ffcst=`expr $ffcst + $fhout `
         [[ $ffcst -le 10 ]] && ffcst=0$ffcst
       done
     else
       ffcst=00
       while [ $ffcst -le $vlength ]
       do
         scp ${LOGNAME}@${CLIENT}:/com/arkv/prod/cdas.${IMON}/pgb.f${ffcst}${IDAY}00 cdas.t00z.pgrbf${ffcst}
         ffcst=`expr $ffcst + $fhout `
         [[ $ffcst -le 10 ]] && ffcst=0$ffcst
       done
     fi
     ln -fs cdas.t00z.pgrbf00  cdas.t00z.pgrbanl            
    fi
   loop=` /nwprod/util/exec/ndate +24 $loop`
   done
 fi
#-------------
 

#-------------
 if [ $exp  = "ecm" ];     then 
  rm -r ${savetmp}/$exp/${exp}.${IDAYM1}                          
   loop=$IDATE
   while [ $loop -le $CDATE ]
   do
    IDAY=`echo $loop |cut -c 1-8`
    export comout=${savetmp}/$exp/${exp}.${IDAY}
    if [ ! -s $comout/ecm.t12z.pgrbf${vlength} ] ; then
    mkdir -p $comout; cd $comout 
      if [ -s $statdir/ecm/pgbf${vlength}.${IDAY}00 ]; then
        ffcst=00
        while [ $ffcst -le $vlength ]
        do
          ln -fs $statdir/ecm/pgbf${ffcst}.${IDAY}00  ecm.t00z.pgrbf${ffcst} 
          if [ $? -ne 0 ]; then
           scp ${LOGNAME}@${CLIENT}:$statdir/ecm/pgbf${ffcst}.${IDAY}00  ecm.t00z.pgrbf${ffcst} 
          fi
          ln -fs $statdir/ecm/pgbf${ffcst}.${IDAY}12  ecm.t12z.pgrbf${ffcst} 
          if [ $? -ne 0 ]; then
           scp ${LOGNAME}@${CLIENT}:$statdir/ecm/pgbf${ffcst}.${IDAY}12  ecm.t12z.pgrbf${ffcst} 
          fi
          ffcst=`expr $ffcst + $fhout `
          [[ $ffcst -le 10 ]] && ffcst=0$ffcst
        done
        cp $statdir/ecm/pgbanl.${IDAY}00  ecm.t00z.pgrbanl
        if [ $? -ne 0 ]; then
         scp ${LOGNAME}@${CLIENT}:$statdir/ecm/pgbanl.${IDAY}00  ecm.t00z.pgrbanl                
        fi
        cp $statdir/ecm/pgbanl.${IDAY}12  ecm.t12z.pgrbanl
        if [ $? -ne 0 ]; then
         scp ${LOGNAME}@${CLIENT}:$statdir/ecm/pgbanl.${IDAY}12  ecm.t12z.pgrbanl                
        fi
      else
        ${exe}/misc/get_ecm_lookalike.sh 2 ${IDAY}00 ${IDAY}12 >log.$loop
        ffcst=00
        while [ $ffcst -le $vlength ]
        do
          mv pgbf${ffcst}.${IDAY}00 ecm.t00z.pgrbf${ffcst}
          mv pgbf${ffcst}.${IDAY}12 ecm.t12z.pgrbf${ffcst}
          ffcst=`expr $ffcst + $fhout `
          [[ $ffcst -le 10 ]] && ffcst=0$ffcst
        done
        mv pgbanl.${IDAY}00   ecm.t00z.pgrbanl
        mv pgbanl.${IDAY}12   ecm.t12z.pgrbanl
        rm $comout/pgb*
      fi
    fi
   loop=` /nwprod/util/exec/ndate +24 $loop`
   done
 fi
#-------------
 
#-------------
 if [ $exp  = "cmc" ];     then 
  rm -r ${savetmp}/$exp/${exp}.${IDAYM1}                          
   loop=$IDATE
   while [ $loop -le $CDATE ]
   do
    IDAY=`echo $loop |cut -c 1-8`
    comout=${savetmp}/$exp/${exp}.${IDAY}
    if [ ! -s $comout/cmc.t12z.pgrbf${vlength} ] ; then
    mkdir -p $comout; cd $comout 
     if [ -s /dcom/us007003/${IDAY}/wgrbbul/cmc/cmc_${IDAY}12f${vlength} ]; then
      ffcst=00
      while [ $ffcst -le $vlength ]
      do
        ffcst3=$ffcst
        if [ $ffcst -lt 100 ]; then ffcst3=0$ffcst; fi
        cp /dcom/us007003/${IDAY}/wgrbbul/cmc/cmc_${IDAY}00f${ffcst3}  cmc.t00z.pgrbf${ffcst}
        cp /dcom/us007003/${IDAY}/wgrbbul/cmc/cmc_${IDAY}12f${ffcst3}  cmc.t12z.pgrbf${ffcst}
        ffcst=`expr $ffcst + $fhout `
        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
      done
     elif [ -s $statdir/cmc/pgbf${vlength}.${IDAY}00 ]; then
      ffcst=00
      while [ $ffcst -le $vlength ]
      do
        ln -fs $statdir/cmc/pgbf${ffcst}.${IDAY}00  cmc.t00z.pgrbf${ffcst} 
        ln -fs $statdir/cmc/pgbf${ffcst}.${IDAY}12  cmc.t12z.pgrbf${ffcst} 
        ffcst=`expr $ffcst + $fhout `
        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
      done
     else
      ffcst=00
      while [ $ffcst -le $vlength ]
      do
        ffcst3=$ffcst
        if [ $ffcst -lt 100 ]; then ffcst3=0$ffcst; fi
        scp ${LOGNAME}@${CLIENT}:/dcom/us007003/${IDAY}/wgrbbul/cmc/cmc_${IDAY}00f${ffcst3}  cmc.t00z.pgrbf${ffcst}
        scp ${LOGNAME}@${CLIENT}:/dcom/us007003/${IDAY}/wgrbbul/cmc/cmc_${IDAY}12f${ffcst3}  cmc.t12z.pgrbf${ffcst}
        ffcst=`expr $ffcst + $fhout `
        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
      done
     fi
     ln -fs cmc.t00z.pgrbf00 cmc.t00z.pgrbanl        
     ln -fs cmc.t12z.pgrbf00 cmc.t12z.pgrbanl        
    fi
   loop=` /nwprod/util/exec/ndate +24 $loop`
   done
 fi
#-------------

#-------------
 if [ $exp  = "fno" ];     then 
  rm -r ${savetmp}/$exp/${exp}.${IDAYM1}                          
   loop=$IDATE
   while [ $loop -le $CDATE ]
   do
    IDAY=`echo $loop |cut -c 1-8`
    comout=${savetmp}/$exp/${exp}.${IDAY}
    if [ ! -s $comout/${exp}.t12z.pgrbf${vlength} ] ; then
    mkdir -p $comout; cd $comout 
      if [ -s /com/fnmoc/prod/nogaps.${IDAY}/nogaps_${IDAY}00f000 ]; then
       ffcst=00
       while [ $ffcst -le $vlength ]
       do
         ffcst3=$ffcst
         if [ $ffcst -lt 100 ]; then ffcst3=0$ffcst; fi
         #cp /dcom/us007003/${IDAY}/wgrbbul/nogaps/nogaps_${IDAY}00f${ffcst3}  fno.t00z.pgrbf${ffcst}
         #cp /dcom/us007003/${IDAY}/wgrbbul/nogaps/nogaps_${IDAY}12f${ffcst3}  fno.t12z.pgrbf${ffcst}
         cp /com/fnmoc/prod/nogaps.${IDAY}/nogaps_${IDAY}00f${ffcst3}  fno.t00z.pgrbf${ffcst}
         cp /com/fnmoc/prod/nogaps.${IDAY}/nogaps_${IDAY}12f${ffcst3}  fno.t12z.pgrbf${ffcst}
         ffcst=`expr $ffcst + $fhout `
         [[ $ffcst -le 10 ]] && ffcst=0$ffcst
       done
      elif [ -s $statdir/fno/pgbf${vlength}.${IDAY}00 ]; then
       ffcst=00
       while [ $ffcst -le $vlength ]
       do
         ln -fs $statdir/fno/pgbf${ffcst}.${IDAY}00  fno.t00z.pgrbf${ffcst} 
         ln -fs $statdir/fno/pgbf${ffcst}.${IDAY}12  fno.t12z.pgrbf${ffcst} 
         ffcst=`expr $ffcst + $fhout `
         [[ $ffcst -le 10 ]] && ffcst=0$ffcst
       done
      else
       ffcst=00
       while [ $ffcst -le $vlength ]
       do
         ffcst3=$ffcst
         if [ $ffcst -lt 100 ]; then ffcst3=0$ffcst; fi
         scp ${LOGNAME}@${CLIENT}:/com/fnmoc/prod/nogaps.${IDAY}/nogaps_${IDAY}00f${ffcst3}  fno.t00z.pgrbf${ffcst}
         scp ${LOGNAME}@${CLIENT}:/com/fnmoc/prod/nogaps.${IDAY}/nogaps_${IDAY}12f${ffcst3}  fno.t12z.pgrbf${ffcst}
         ffcst=`expr $ffcst + $fhout `
         [[ $ffcst -le 10 ]] && ffcst=0$ffcst
       done
      fi
      ln -fs fno.t00z.pgrbf00 fno.t00z.pgrbanl        
      ln -fs fno.t12z.pgrbf00 fno.t12z.pgrbanl        
    fi
   loop=` /nwprod/util/exec/ndate +24 $loop`
   done
 fi
#-------------
 

#-------------
 if [ $exp  = "ukm" ];     then 
  rm -r ${savetmp}/$exp/${exp}.${IDAYM1}                          
   loop=$IDATE
   while [ $loop -le $CDATE ]
   do
    IDAY=`echo $loop |cut -c 1-8`
    comout=${savetmp}/$exp/${exp}.${IDAY}
    if [ ! -s $comout/${exp}.t12z.pgrbf${vlength} ] ; then
    mkdir -p $comout; cd $comout 
     if [ -s /com/mrf/prod/ukmet.${IDAY}/ukmet.t00z.ukm25f72 ]; then
      ffcst=00
      while [ $ffcst -le $vlength ]
      do
        if [ $ffcst -le 72 ]; then
         cp /com/mrf/prod/ukmet.${IDAY}/ukmet.t00z.ukm25f${ffcst} ukm.t00z.pgrbf${ffcst}
         cp /com/mrf/prod/ukmet.${IDAY}/ukmet.t12z.ukm25f${ffcst} ukm.t12z.pgrbf${ffcst}
        else                       
         ln -fs ukm.t00z.pgrbf72 ukm.t00z.pgrbf${ffcst}
         ln -fs ukm.t12z.pgrbf72 ukm.t12z.pgrbf${ffcst}
        fi
        ffcst=`expr $ffcst + $fhout `
        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
      done
     elif [ -s $statdir/prk/ukmet.${IDAY}00 ]; then
      ffcst=00
      while [ $ffcst -le $vlength ]
      do
        ln -fs $statdir/prk/ukmet.${IDAY}00  ukm.t00z.pgrbf${ffcst}
        ln -fs $statdir/prk/ukmet.${IDAY}12  ukm.t12z.pgrbf${ffcst}
        ffcst=`expr $ffcst + $fhout `
        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
      done
     else
      ffcst=00
      while [ $ffcst -le $vlength ]
      do
        if [ $ffcst -le 72 ]; then
         scp ${LOGNAME}@${CLIENT}:/com/mrf/prod/ukmet.${IDAY}/ukmet.t00z.ukm25f${ffcst} ukm.t00z.pgrbf${ffcst}
         scp ${LOGNAME}@${CLIENT}:/com/mrf/prod/ukmet.${IDAY}/ukmet.t12z.ukm25f${ffcst} ukm.t12z.pgrbf${ffcst}
        else                       
         ln -fs ukm.t00z.pgrbf72 ukm.t00z.pgrbf${ffcst}
         ln -fs ukm.t12z.pgrbf72 ukm.t12z.pgrbf${ffcst}
        fi
        ffcst=`expr $ffcst + $fhout `
        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
      done
     fi
     ln -fs ukm.t00z.pgrbf00 ukm.t00z.pgrbanl        
     ln -fs ukm.t12z.pgrbf00 ukm.t12z.pgrbanl        
    fi
   loop=` /nwprod/util/exec/ndate +24 $loop`
   done
 fi
#-------------
 

#-------------
 if [ $exp  = "jma" ];     then
  rm -r ${savetmp}/$exp/${exp}.${IDAYM1}
   loop=$IDATE
   while [ $loop -le $CDATE ]
   do
    IDAY=`echo $loop |cut -c 1-8`
    export comout=${savetmp}/$exp/${exp}.${IDAY}
    if [ ! -s $comout/${exp}.t12z.pgrbf${vlength} ] ; then
    mkdir -p $comout; cd $comout
      ffcst=00
      while [ $ffcst -le $vlength ]
      do
        ln -fs $statdir/jma/pgbf${ffcst}.${IDAY}00  jma.t00z.pgrbf${ffcst}
        if [ $? -ne 0 ]; then
         scp ${LOGNAME}@${CLIENT}:$statdir/jma/pgbf${ffcst}.${IDAY}00  jma.t00z.pgrbf${ffcst}
        fi
        ln -fs $statdir/jma/pgbf${ffcst}.${IDAY}12  jma.t12z.pgrbf${ffcst}
        if [ $? -ne 0 ]; then
         scp ${LOGNAME}@${CLIENT}:$statdir/jma/pgbf${ffcst}.${IDAY}12  jma.t12z.pgrbf${ffcst}
        fi
        ffcst=`expr $ffcst + $fhout `
        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
      done
      ln -fs $statdir/jma/pgbanl.${IDAY}00  jma.t00z.pgrbanl
      if [ $? -ne 0 ]; then
        scp ${LOGNAME}@${CLIENT}:$statdir/jma/pgbanl.${IDAY}00  jma.t00z.pgrbanl
      fi
      ln -fs $statdir/jma/pgbanl.${IDAY}12  jma.t12z.pgrbanl
      if [ $? -ne 0 ]; then
        scp ${LOGNAME}@${CLIENT}:$statdir/jma/pgbanl.${IDAY}12  jma.t12z.pgrbanl
      fi
    fi
   loop=` /nwprod/util/exec/ndate +24 $loop`
   done
 fi
#-------------


#-------------
 if [ $exp  = "nmmb" ];     then 
  rm -r ${savetmp}/$exp/${exp}.${IDAYM1}                          
   loop=$IDATE
   while [ $loop -le $CDATE ]
   do
    IDAY=`echo $loop |cut -c 1-8`
    export comout=${savetmp}/$exp/${exp}.${IDAY}
    if [ ! -s $comout/${exp}.t00z.pgrbf${vlength} ] ; then
    mkdir -p $comout; cd $comout 
      ffcst=00
      while [ $ffcst -le $vlength ]
      do
        cp /meso/noscrub/wx20rv/VRFY_data/00/CNTL1/pgbf${ffcst}.gfs.${IDAY}00  ${exp}.t00z.pgrbf${ffcst} 
        if [ $? -ne 0 ]; then
         scp ${LOGNAME}@${CLIENT}:/meso/noscrub/wx20rv/VRFY_data/00/CNTL1/pgbf${ffcst}.gfs.${IDAY}00  ${exp}.t00z.pgrbf${ffcst}
        fi
        cp /meso/noscrub/wx20rv/VRFY_data/12/CNTL1/pgbf${ffcst}.gfs.${IDAY}12  ${exp}.t12z.pgrbf${ffcst} 
        if [ $? -ne 0 ]; then
         scp ${LOGNAME}@${CLIENT}:/meso/noscrub/wx20rv/VRFY_data/12/CNTL1/pgbf${ffcst}.gfs.${IDAY}12  ${exp}.t12z.pgrbf${ffcst}
        fi
        ffcst=`expr $ffcst + $fhout `
        [[ $ffcst -le 10 ]] && ffcst=0$ffcst
      done
      cp /com/gfs/prod/gfs.${IDAY}/gfs.t00z.pgrbanl    ${exp}.t00z.pgrbanl               
      if [ $? -ne 0 ]; then
        scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t00z.pgrbanl    ${exp}.t00z.pgrbanl     
      fi
      cp /com/gfs/prod/gfs.${IDAY}/gfs.t12z.pgrbanl    ${exp}.t12z.pgrbanl               
      if [ $? -ne 0 ]; then
        scp ${LOGNAME}@${CLIENT}:/com/gfs/prod/gfs.${IDAY}/gfs.t12z.pgrbanl    ${exp}.t12z.pgrbanl     
      fi
    fi
   loop=` /nwprod/util/exec/ndate +24 $loop`
   done
 fi
#-------------

exit
