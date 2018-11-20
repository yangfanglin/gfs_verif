program mvgribdate                                     

!-----------------------------------------------------------------
! reset GRIB forecast file date and treat it as an analysis file
! Fanglin Yang, April 2015
!-----------------------------------------------------------------

integer, parameter :: mmax=5000000                   !maximum number of points to unpack 
logical*1     :: lb(mmax)
character*200 :: input,output    
integer       :: iargc
external      :: iargc
integer       :: nargs       ! number of command-line arguments
character*200 :: argument    ! space for command-line argument
integer       :: jpds(200),jgds(200)
integer       :: kpds(200),kgds(200)
integer       :: ymdh_anl
real*4        :: var(mmax)          

!-----------------------------------------------------
 
 nargs = iargc()              !  iargc() - number of arguments
 if (nargs.lt.3) then
   write(*,*)'usage : mvgribdate input output ymdh_anl'
   stop
 endif
 call getarg(1,argument)      
 read(argument,*) input      
 call getarg(2,argument)      
 read(argument,*) output      
 call getarg(3,argument)      
 read(argument,*) ymdh_anl     
!  print*, trim(input)," ",trim(output), ymdh_anl

 call baopenr(10,trim(input),iret)
 if (iret .ne. 0) write(6,*)" failed to open ", input
 call baopen(20,trim(output),iret)
 if (iret .ne. 0) write(6,*)" failed to open ", output  
 if (iret .ne. 0) goto 200    

nrec=-1
10 continue
   jpds=-1; jgds=-1
   call getgb(10,0,mmax,nrec,jpds,jgds,kf,k,kpds,kgds,lb,var,iret)
   if(iret.ne.0) goto 100   !reached end of record or incorrect file 
   nrec=nrec-1

!  write(1,*)
   write(1,'("nrec=",i4," iret=",i2," irec=",i10," nxny=",i10)')nrec,iret,k,kf
   write(1,'("kpds=",22i8)') (kpds(k),k=1,22)
!  write(1,'("kgds=",22i8)') (kgds(k),k=1,22)

!  iyear=kpds(8); imon=kpds(9); iday=kpds(10); ihour=kpds(11); imin=kpds(12)
!  ifh1=kpds(14); ifh2=kpds(15); itflag=kpds(16)    
     
!--write out grib1 forecast as an analysis file valid at ymdh_anl 
   kpds(2)=81   !GENERATING PROCESS ID NUMBER
   kpds(8)=int(ymdh_anl/1000000)-int(ymdh_anl/100000000)*100
   kpds(9)=int(ymdh_anl/10000)-int(ymdh_anl/1000000)*100
   kpds(10)=int(ymdh_anl/100)-int(ymdh_anl/10000)*100
   kpds(11)=ymdh_anl-int(ymdh_anl/100)*100
   kpds(14)=0; kpds(15)=0; kpds(16)=10
   write(1,'("kpdn=",22i8)') (kpds(k),k=1,22)

     call putgb(20,kf,kpds,kgds,lb,var(1:kf),iret)
     if(iret.ne.0) write(6,*) "failed to write record ",irec                      

goto 10

100  call baclose(10,iret)
     call baclose(20,iret)

200  end

