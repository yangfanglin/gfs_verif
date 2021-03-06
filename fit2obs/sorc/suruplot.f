       parameter(nvar=4,nlev=21,nstcs=6,nstcw=9)
       parameter(nreg=7,nsub=1,ntx=1000)
c      parameter(nreg=2,nsub=1,ntx=100)
       parameter(iprreg=1,iprsub=1)
c
       CHARACTER*1  kdbug
       CHARACTER*250 mdl,mdldir,fcshr,iname,infile
       CHARACTER*250 outfile,outdir
       CHARACTER*10 ksyr,ksmth,ksday,kscy,kincr
       CHARACTER*10 keyr,kemth,keday,kecy
       CHARACTER*10 indate,datstr,datend
       CHARACTER*2 labm(12),labd(31),labc(4)
       CHARACTER*4 laby
       integer mand(21)
c
       dimension sprs(nreg,nsub,nlev,nstcw,nvar,ntx)
       dimension gdata(nreg,nsub)
       dimension fm(nreg,nsub,nlev)
       dimension om(nreg,nsub,nlev)
       dimension fom(nreg,nsub,nlev)
       dimension fsm(nreg,nsub,nlev)
       dimension osm(nreg,nsub,nlev)
       dimension tcnt(nreg,nsub,nlev)
       dimension rmse(nreg,nsub,nlev)
       dimension bias(nreg,nsub,nlev)
       dimension ufm(nreg,nsub,nlev)
       dimension vfm(nreg,nsub,nlev)
       dimension uom(nreg,nsub,nlev)
       dimension vom(nreg,nsub,nlev)
       dimension uvm(nreg,nsub,nlev)
       dimension uvfm(nreg,nsub,nlev)
       dimension uvom(nreg,nsub,nlev)
       dimension spdm(nreg,nsub,nlev)
       dimension icycl(4)
c
       DATA LABC/'00','06','12','18'/
       DATA icycl/0,6,12,18/
C
       DATA LABD/'01','02','03','04','05','06','07','08','09','10',
     *           '11','12','13','14','15','16','17','18','19','20',
     *           '21','22','23','24','25','26','27','28','29','30',
     *           '31'/
C
       DATA LABM/'01','02','03','04','05','06','07','08','09','10',
     *           '11','12'/
C
       DATA MAND / 1000, 925, 850, 700, 500, 400, 300,
     *               250, 200, 150, 100,  70,  50,  30,
     *                20,  10,   7,   5,   3,   2,   1/
c
       data undef/-99999.9/
c
       call getenv("idbug",kdbug)
       read(kdbug,'(i1)') idbug
       write(*,*) "idbug= ",idbug
c
       call getenv("mdl",mdl)
       write(*,*) "mdl= ",mdl
c
       call getenv("mdldir",mdldir)
       write(*,*) "mdldir= ",mdldir
c
       call getenv("outdir",outdir)
       write(*,*) "outdir= ",outdir
c
       call getenv("fcshr",fcshr)
       write(*,*) "fcshr= ",fcshr
c
       call getenv("syear",ksyr)
       read(ksyr,'(i4)') isyr
       write(*,*) "syear= ",isyr
C
       call getenv("smonth",ksmth)
       read(ksmth,'(i2)') ismth
       write(*,*) "smonth= ",ismth
C
       call getenv("sday",ksday)
       read(ksday,'(i2)') isday
       write(*,*) "sday= ",isday
C
       call getenv("shour",kscy)
       read(kscy,'(i2)') iscy
       write(*,*) "shour= ",iscy
C
       call getenv("eyear",keyr)
       read(keyr,'(i4)') ieyr
       write(*,*) "eyear= ",ieyr
C
       call getenv("emonth",kemth)
       read(kemth,'(i2)') iemth
       write(*,*) "emonth= ",iemth
C
       call getenv("eday",keday)
       read(keday,'(i2)') ieday
       write(*,*) "eday= ",ieday
C
       call getenv("ehour",kecy)
       read(kecy,'(i2)') iecy
       write(*,*) "ehour= ",iecy
c
       call getenv("incr",kincr)
       read(kincr,'(i2)') incr
       write(*,*) "incr= ",incr
c
       iname = mdldir(1:nfill(mdldir)) // '/f' // 
     * fcshr(1:nfill(fcshr)) // '.raob.' 
       write(*,*) "iname= ",iname
c
       ncns=iw3jdn(isyr,ismth,isday)
       print *,' ncns ',ncns
       ncne=iw3jdn(ieyr,iemth,ieday)
       print *,' ncne ',ncne
       ndays=ncne-ncns+1
       print *,' ndays ',ndays
c
       if(iscy.eq.0) ncysx=1
       if(iscy.eq.6) ncysx=2
       if(iscy.eq.12) ncysx=3
       if(iscy.eq.18) ncysx=4
       ncysi=ncysx
c
       if(iecy.eq.0) ncyex=1
       if(iecy.eq.6) ncyex=2
       if(iecy.eq.12) ncyex=3
       if(iecy.eq.18) ncyex=4
       ncyei=ncyex
c
       if(incr.eq.24) then
       jincr=1
       ncyex=ncysx
       endif
       if(incr.eq.12) then
       jincr=2
       ncyex=ncysx+2
       endif
       if(incr.eq.6) then
       jincr=1
       ncysx=1
       ncyex=4
       endif
c
C      START THE TIME LOOP HERE...
C
       ntime=0
       DO 555 NCN=NCNS,NCNE
C
       CALL W3FS26(NCN,IYR,IMTH,IDAY,IDAYWK,IDAYYR)
       WRITE(LABY,'(I4)') IYR
       indate(1:4)=LABY
       indate(5:6)=LABM(IMTH)
       indate(7:8)=LABD(IDAY)
C
       ncysf=ncysx
       ncyef=ncyex
       if(ncn.eq.ncns) ncysf=ncysi
       if(ncn.eq.ncne) ncyef=ncyei
c
c      print *,'ncysx ',ncysx,' ncyex ',ncyex,' jincr ',jincr
c
       DO 444 ncy=ncysf,ncyef,jincr
       ICY=icycl(ncy)
C
       IF(ICY.EQ.0)  indate(9:10)=LABC(1)
       IF(ICY.EQ.6)  indate(9:10)=LABC(2)
       IF(ICY.EQ.12) indate(9:10)=LABC(3)
       IF(ICY.EQ.18) indate(9:10)=LABC(4)
C
       infile = iname(1:nfill(iname)) // indate
       write(*,*) "infile= ",infile
!!     open(11,file=infile,form='unformatted',err=445)
       call opendian(11,infile,ierr)
       if(ierr.ne.0) goto 445
c
c.... read the full data set in....
      ntxx=0
      do ivar=1,nvar
c
      if(ivar.eq.1) nstat=nstcs
      if(ivar.eq.2) nstat=nstcs
      if(ivar.eq.3) nstat=nstcw
      if(ivar.eq.4) nstat=nstcs
c
      do nst=1,nstat
      do ilev=1,nlev
c
      read(11,end=445,err=445) gdata
      ntxx=ntxx+1
      if(ntxx.eq.1) ntime=ntime+1
c
      do isub=1,nsub
      do ireg=1,nreg
      sprs(ireg,isub,ilev,nst,ivar,ntime)=gdata(ireg,isub)
       if( nst.eq.2 .and. abs(gdata(ireg,isub)) .ge. 1.0E+6) then
        sprs(ireg,isub,ilev,nst,ivar,ntime)=undef
        sprs(ireg,isub,ilev,1,ivar,ntime)=undef
!!      stop    ! Suru opposes to skip missing data. Let job fail
       endif
      enddo
      enddo
c
c... end level-loop
      enddo
c... end stat-loop
      enddo
c... end variable-loop
      enddo
c
      close(11)
      go to 444
c
 445   print *,'end of file for ',infile
c... end cycle-loop
 444  continue
c
c... end day-loop
 555  continue
c
       print *,'number of time levels ',ntime
c
c... output file name
       write(LABY,'(I4)') ISYR
       datstr(1:4)=LABY
       datstr(5:6)=LABM(ISMTH)
       datstr(7:8)=LABD(ISDAY)
       if(iscy.eq.0) datstr(9:10)=LABC(1)
       if(iscy.eq.6) datstr(9:10)=LABC(2)
       if(iscy.eq.12) datstr(9:10)=LABC(3)
       if(iscy.eq.18) datstr(9:10)=LABC(4)
c
       write(LABY,'(I4)') IEYR
       datend(1:4)=LABY
       datend(5:6)=LABM(IEMTH)
       datend(7:8)=LABD(IEDAY)
       if(iecy.eq.0) datend(9:10)=LABC(1)
       if(iecy.eq.6) datend(9:10)=LABC(2)
       if(iecy.eq.12) datend(9:10)=LABC(3)
       if(iecy.eq.18) datend(9:10)=LABC(4)
       outfile = outdir(1:nfill(outdir)) // '/' // mdl(1:nfill(mdl)) //
     * '.f' // fcshr(1:nfill(fcshr)) // '.raob.' // 
     * datstr // '.' // datend
       write(*,*) "outfile= ",outfile
       open(51,file=outfile,form='unformatted')
c
c... do partial sums now...
c
      do ivar=1,nvar
c
      tcnt=0
      rmse=0.
      fm=0.
      om=0.
      fom=0.
      fsm=0.
      osm=0.
      bias=0.
      ufm=0.
      vfm=0.
      uom=0.
      vom=0.
      uvm=0.
      uvfm=0.
      uvom=0.
      spdm=0.
c
      if((ivar.le.2).or.(ivar.eq.4)) then
c
      do ilev=1,nlev
      do isub=1,nsub
      do ireg=1,nreg
c
      do nt=1,ntime
c
      cnt=sprs(ireg,isub,ilev,1,ivar,nt)
c
      if(cnt.gt.0.) then
      f=sprs(ireg,isub,ilev,2,ivar,nt)
      o=sprs(ireg,isub,ilev,3,ivar,nt)
      fo=sprs(ireg,isub,ilev,4,ivar,nt)
      fs=sprs(ireg,isub,ilev,5,ivar,nt)
      os=sprs(ireg,isub,ilev,6,ivar,nt)
c
      tcnt(ireg,isub,ilev)=tcnt(ireg,isub,ilev)+cnt
      fm(ireg,isub,ilev)=fm(ireg,isub,ilev)+(f*cnt)
      om(ireg,isub,ilev)=om(ireg,isub,ilev)+(o*cnt)
      fom(ireg,isub,ilev)=fom(ireg,isub,ilev)+(fo*cnt)
      fsm(ireg,isub,ilev)=fsm(ireg,isub,ilev)+(fs*cnt)
      osm(ireg,isub,ilev)=osm(ireg,isub,ilev)+(os*cnt)
      endif
c
c... end time-loop
      enddo
c
      cntx=tcnt(ireg,isub,ilev)
      if(cntx.gt.0.) then
      fm(ireg,isub,ilev)=fm(ireg,isub,ilev)/cntx
      om(ireg,isub,ilev)=om(ireg,isub,ilev)/cntx
      fom(ireg,isub,ilev)=fom(ireg,isub,ilev)/cntx
      fsm(ireg,isub,ilev)=fsm(ireg,isub,ilev)/cntx
      osm(ireg,isub,ilev)=osm(ireg,isub,ilev)/cntx
      smse=fsm(ireg,isub,ilev)+osm(ireg,isub,ilev)-2*fom(ireg,isub,ilev)
      if(smse.gt.0.) rmse(ireg,isub,ilev)=sqrt(smse)
       if(rmse(ireg,isub,ilev).ge.1.0e+3) rmse(ireg,isub,ilev)=undef
      bias(ireg,isub,ilev)=fm(ireg,isub,ilev)-om(ireg,isub,ilev)
      else
      fm(ireg,isub,ilev)=undef
      om(ireg,isub,ilev)=undef
      fom(ireg,isub,ilev)=undef
      fsm(ireg,isub,ilev)=undef
      osm(ireg,isub,ilev)=undef
      rmse(ireg,isub,ilev)=undef
      bias(ireg,isub,ilev)=undef
      endif
c
c... end region-loop
      enddo
c... end subset-loop
      enddo
c... end level-loop
      enddo
c
      call wrtstat(51,tcnt,nreg,nsub,nlev)
      call wrtstat(51,fm,nreg,nsub,nlev)
      call wrtstat(51,om,nreg,nsub,nlev)
      call wrtstat(51,fom,nreg,nsub,nlev)
      call wrtstat(51,fsm,nreg,nsub,nlev)
      call wrtstat(51,osm,nreg,nsub,nlev)
      call wrtstat(51,rmse,nreg,nsub,nlev)
      call wrtstat(51,bias,nreg,nsub,nlev)
c
      if(idbug.eq.1) then
      if(ivar.eq.1) then
      do ilev=1,nlev
      level=mand(ilev)
      cntx=tcnt(iprreg,iprsub,ilev)
      if(cntx.gt.0.)
     *write(6,111) level,tcnt(iprreg,iprsub,ilev),
     *                   fm(iprreg,iprsub,ilev),
     *                   om(iprreg,iprsub,ilev),
     *                   rmse(iprreg,iprsub,ilev),
     *                   bias(iprreg,iprsub,ilev)
      enddo
      else
      do ilev=1,nlev
      level=mand(ilev)
      cntx=tcnt(iprreg,iprsub,ilev)
      if(cntx.gt.0.)
     *write(6,222) level,tcnt(iprreg,iprsub,ilev),
     *                   fm(iprreg,iprsub,ilev),
     *                   om(iprreg,iprsub,ilev),
     *                   rmse(iprreg,iprsub,ilev),
     *                   bias(iprreg,iprsub,ilev)
      enddo
      endif
      endif
c 
      else
c
c... do wind...
      do ilev=1,nlev
      do isub=1,nsub
      do ireg=1,nreg
c
      do nt=1,ntime
c
      cnt=sprs(ireg,isub,ilev,1,ivar,nt)
c
      if(cnt.gt.0.) then
      uf=sprs(ireg,isub,ilev,2,ivar,nt)
      vf=sprs(ireg,isub,ilev,3,ivar,nt)
      uo=sprs(ireg,isub,ilev,4,ivar,nt)
      vo=sprs(ireg,isub,ilev,5,ivar,nt)
      uv=sprs(ireg,isub,ilev,6,ivar,nt)
      uvf=sprs(ireg,isub,ilev,7,ivar,nt)
      uvo=sprs(ireg,isub,ilev,8,ivar,nt)
      spd=sprs(ireg,isub,ilev,9,ivar,nt)
c
      tcnt(ireg,isub,ilev)=tcnt(ireg,isub,ilev)+cnt
      ufm(ireg,isub,ilev)=ufm(ireg,isub,ilev)+(uf*cnt)
      vfm(ireg,isub,ilev)=vfm(ireg,isub,ilev)+(vf*cnt)
      uom(ireg,isub,ilev)=uom(ireg,isub,ilev)+(uo*cnt)
      vom(ireg,isub,ilev)=vom(ireg,isub,ilev)+(vo*cnt)
      uvm(ireg,isub,ilev)=uvm(ireg,isub,ilev)+(uv*cnt)
      uvfm(ireg,isub,ilev)=uvfm(ireg,isub,ilev)+(uvf*cnt)
      uvom(ireg,isub,ilev)=uvom(ireg,isub,ilev)+(uvo*cnt)
      spdm(ireg,isub,ilev)=spdm(ireg,isub,ilev)+(spd*cnt)
      endif
c
c... end time-loop
      enddo
c
      cntx=tcnt(ireg,isub,ilev)
      if(cntx.gt.0.) then
      ufm(ireg,isub,ilev)=ufm(ireg,isub,ilev)/cntx
      vfm(ireg,isub,ilev)=vfm(ireg,isub,ilev)/cntx
      uom(ireg,isub,ilev)=uom(ireg,isub,ilev)/cntx
      vom(ireg,isub,ilev)=vom(ireg,isub,ilev)/cntx
      uvm(ireg,isub,ilev)=uvm(ireg,isub,ilev)/cntx
      uvfm(ireg,isub,ilev)=uvfm(ireg,isub,ilev)/cntx
      uvom(ireg,isub,ilev)=uvom(ireg,isub,ilev)/cntx
      spdm(ireg,isub,ilev)=spdm(ireg,isub,ilev)/cntx
      uvfmx=uvfm(ireg,isub,ilev)
      uvomx=uvom(ireg,isub,ilev)
      uvmx=uvm(ireg,isub,ilev)
      val=uvfmx+uvomx-2*uvmx
      if(val.gt.0.) rmse(ireg,isub,ilev)=sqrt(val)
       if(rmse(ireg,isub,ilev).ge.1.0e+3) rmse(ireg,isub,ilev)=undef
      else
      ufm(ireg,isub,ilev)=undef
      vfm(ireg,isub,ilev)=undef
      uom(ireg,isub,ilev)=undef
      vom(ireg,isub,ilev)=undef
      uvm(ireg,isub,ilev)=undef
      uvfm(ireg,isub,ilev)=undef
      uvom(ireg,isub,ilev)=undef
      spdm(ireg,isub,ilev)=undef
      rmse(ireg,isub,ilev)=undef
      endif
c
c... end region-loop
      enddo
c... end subset-loop
      enddo
c... end time-loop
      enddo
c
      call wrtstat(51,tcnt,nreg,nsub,nlev)
      call wrtstat(51,ufm,nreg,nsub,nlev)
      call wrtstat(51,vfm,nreg,nsub,nlev)
      call wrtstat(51,uom,nreg,nsub,nlev)
      call wrtstat(51,vom,nreg,nsub,nlev)
      call wrtstat(51,uvm,nreg,nsub,nlev)
      call wrtstat(51,uvfm,nreg,nsub,nlev)
      call wrtstat(51,uvom,nreg,nsub,nlev)
      call wrtstat(51,spdm,nreg,nsub,nlev)
      call wrtstat(51,rmse,nreg,nsub,nlev)
c 
      if(idbug.eq.1) then
      do ilev=1,nlev
      level=mand(ilev)
      cntx=tcnt(iprreg,iprsub,ilev)
      if(cntx.gt.0.) 
     *write(6,333) level,tcnt(iprreg,iprsub,ilev),
     *                   ufm(iprreg,iprsub,ilev),
     *                   vfm(iprreg,iprsub,ilev),
     *                   uom(iprreg,iprsub,ilev),
     *                   vom(iprreg,iprsub,ilev),
     *                   uvm(iprreg,iprsub,ilev),
     *                   uvfm(iprreg,iprsub,ilev),
     *                   uvom(iprreg,iprsub,ilev),
     *                   spdm(iprreg,iprsub,ilev),
     *                   rmse(iprreg,iprsub,ilev)
      enddo
      endif
c
      endif
c
c... end variable-loop
      enddo
c
 111  format(' t ',i5,1x,5f12.2)
 222  format(' z ',i5,1x,5f12.2)
 333  format(' w ',i5,1x,10e15.6)
c
      stop
      end
      subroutine wrtstat(iwr,var,nreg,nsub,nlev)
c
      dimension var(nreg,nsub,nlev)
      dimension gdata(nreg,nsub)

      do ilev=1,nlev
      do isub=1,nsub
      do ireg=1,nreg
      gdata(ireg,isub)=var(ireg,isub,ilev)
      enddo
      enddo
      write(iwr) gdata
      enddo
c
      return 
      end
C-----------------------------------------------------------------------
       FUNCTION IW3JDN(IYEAR,MONTH,IDAY)
C$$$   SUBPROGRAM  DOCUMENTATION  BLOCK
C
C SUBPROGRAM: IW3JDN         COMPUTE JULIAN DAY NUMBER
C   AUTHOR: JONES,R.E.       ORG: W342       DATE: 87-03-29
C
C ABSTRACT: COMPUTES JULIAN DAY NUMBER FROM YEAR (4 DIGITS), MONTH,
C   AND DAY. IW3JDN IS VALID FOR YEARS 1583 A.D. TO 3300 A.D.
C   JULIAN DAY NUMBER CAN BE USED TO COMPUTE DAY OF WEEK, DAY OF
C   YEAR, RECORD NUMBERS IN AN ARCHIVE, REPLACE DAY OF CENTURY,
C   FIND THE NUMBER OF DAYS BETWEEN TWO DATES.
C
C PROGRAM HISTORY LOG:
C   87-03-29  R.E.JONES
C   89-10-25  R.E.JONES   CONVERT TO CRAY CFT77 FORTRAN
C
C USAGE:   II = IW3JDN(IYEAR,MONTH,IDAY)
C
C   INPUT VARIABLES:
C     NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C     ------ --------- -----------------------------------------------
C     IYEAR  ARG LIST  INTEGER   YEAR           ( 4 DIGITS)
C     MONTH  ARG LIST  INTEGER   MONTH OF YEAR   (1 - 12)
C     IDAY   ARG LIST  INTEGER   DAY OF MONTH    (1 - 31)
C
C   OUTPUT VARIABLES:
C     NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C     ------ --------- -----------------------------------------------
C     IW3JDN FUNTION   INTEGER   JULIAN DAY NUMBER
C                      JAN. 1,1960 IS JULIAN DAY NUMBER 2436935
C                      JAN. 1,1987 IS JULIAN DAY NUMBER 2446797
C
C   REMARKS: JULIAN PERIOD WAS DEVISED BY JOSEPH SCALIGER IN 1582.
C     JULIAN DAY NUMBER #1 STARTED ON JAN. 1,4713 B.C. THREE MAJOR
C     CHRONOLOGICAL CYCLES BEGIN ON THE SAME DAY. A 28-YEAR SOLAR
C     CYCLE, A 19-YEAR LUNER CYCLE, A 15-YEAR INDICTION CYCLE, USED
C     IN ANCIENT ROME TO REGULATE TAXES. IT WILL TAKE 7980 YEARS
C     TO COMPLETE THE PERIOD, THE PRODUCT OF 28, 19, AND 15.
C     SCALIGER NAMED THE PERIOD, DATE, AND NUMBER AFTER HIS FATHER
C     JULIUS (NOT AFTER THE JULIAN CALENDAR). THIS SEEMS TO HAVE
C     CAUSED A LOT OF CONFUSION IN TEXT BOOKS. SCALIGER NAME IS
C     SPELLED THREE DIFFERENT WAYS. JULIAN DATE AND JULIAN DAY
C     NUMBER ARE INTERCHANGED. A JULIAN DATE IS USED BY ASTRONOMERS
C     TO COMPUTE ACCURATE TIME, IT HAS A FRACTION. WHEN TRUNCATED TO
C     AN INTEGER IT IS CALLED AN JULIAN DAY NUMBER. THIS FUNCTION
C     WAS IN A LETTER TO THE EDITOR OF THE COMMUNICATIONS OF THE ACM
C     VOLUME 11 / NUMBER 10 / OCTOBER 1968. THE JULIAN DAY NUMBER
C     CAN BE CONVERTED TO A YEAR, MONTH, DAY, DAY OF WEEK, DAY OF
C     YEAR BY CALLING SUBROUTINE W3FS26.
C
C ATTRIBUTES:
C   LANGUAGE: CRAY CFT77 FORTRAN
C   MACHINE:  CRAY Y-MP8/864, CRAY Y-MP EL2/256
C
C$$$
C
       IW3JDN  =    IDAY - 32075
     &            + 1461 * (IYEAR + 4800 + (MONTH - 14) / 12) / 4
     &            + 367 * (MONTH - 2 - (MONTH -14) / 12 * 12) / 12
     &            - 3 * ((IYEAR + 4900 + (MONTH - 14) / 12) / 100) / 4
       RETURN
       END
