 SUBROUTINE POLATES2(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI,  &
                     NO,RLAT,RLON,IBO,LO,GO,IRET)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! $Revision: 71314 $
!
! SUBPROGRAM:  POLATES2   INTERPOLATE SCALAR FIELDS (NEIGHBOR)
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: THIS SUBPROGRAM PERFORMS NEIGHBOR INTERPOLATION
!           FROM ANY GRID TO ANY GRID FOR SCALAR FIELDS.
!           OPTIONS ALLOW CHOOSING THE WIDTH OF THE GRID SQUARE
!           (IPOPT(1)) TO SEARCH FOR VALID DATA, WHICH DEFAULTS TO 1
!           (IF IPOPT(1)=-1).  ODD WIDTH SQUARES ARE CENTERED ON
!           THE NEAREST INPUT GRID POINT; EVEN WIDTH SQUARES ARE
!           CENTERED ON THE NEAREST FOUR INPUT GRID POINTS.
!           SQUARES ARE SEARCHED FOR VALID DATA IN A SPIRAL PATTERN
!           STARTING FROM THE CENTER.  NO SEARCHING IS DONE WHERE
!           THE OUTPUT GRID IS OUTSIDE THE INPUT GRID.
!           ONLY HORIZONTAL INTERPOLATION IS PERFORMED.
!           THE GRIDS ARE DEFINED BY THEIR GRID DESCRIPTION SECTIONS
!           (PASSED IN INTEGER FORM AS DECODED BY SUBPROGRAM W3FI63).
!           THE CURRENT CODE RECOGNIZES THE FOLLOWING PROJECTIONS:
!             (KGDS(1)=000) EQUIDISTANT CYLINDRICAL
!             (KGDS(1)=001) MERCATOR CYLINDRICAL
!             (KGDS(1)=003) LAMBERT CONFORMAL CONICAL
!             (KGDS(1)=004) GAUSSIAN CYLINDRICAL (SPECTRAL NATIVE)
!             (KGDS(1)=005) POLAR STEREOGRAPHIC AZIMUTHAL
!             (KGDS(1)=203) ROTATED EQUIDISTANT CYLINDRICAL (E-STAGGER)
!             (KGDS(1)=205) ROTATED EQUIDISTANT CYLINDRICAL (B-STAGGER)
!           WHERE KGDS COULD BE EITHER INPUT KGDSI OR OUTPUT KGDSO.
!           AS AN ADDED BONUS THE NUMBER OF OUTPUT GRID POINTS
!           AND THEIR LATITUDES AND LONGITUDES ARE ALSO RETURNED.
!           ON THE OTHER HAND, THE OUTPUT CAN BE A SET OF STATION POINTS
!           IF KGDSO(1)<0, IN WHICH CASE THE NUMBER OF POINTS
!           AND THEIR LATITUDES AND LONGITUDES MUST BE INPUT.
!           INPUT BITMAPS WILL BE INTERPOLATED TO OUTPUT BITMAPS.
!           OUTPUT BITMAPS WILL ALSO BE CREATED WHEN THE OUTPUT GRID
!           EXTENDS OUTSIDE OF THE DOMAIN OF THE INPUT GRID.
!           THE OUTPUT FIELD IS SET TO 0 WHERE THE OUTPUT BITMAP IS OFF.
!        
! PROGRAM HISTORY LOG:
!   96-04-10  IREDELL
! 1999-04-08  IREDELL  SPLIT IJKGDS INTO TWO PIECES
! 2001-06-18  IREDELL  INCLUDE SPIRAL SEARCH OPTION
! 2006-01-04  GAYNO    MINOR BUG FIX
! 2007-10-30  IREDELL  SAVE WEIGHTS AND THREAD FOR PERFORMANCE
! 2012-06-26  GAYNO    FIX OUT-OF-BOUNDS ERROR. SEE NCEPLIBS
!                      TICKET #9.
! 2015-01-27  GAYNO    REPLACE CALLS TO GDSWIZ WITH NEW MERGED
!                      VERSION OF GDSWZD.
!
! USAGE:    CALL POLATES2(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI,
!    &                    NO,RLAT,RLON,IBO,LO,GO,IRET)
!
!   INPUT ARGUMENT LIST:
!     IPOPT    - INTEGER (20) INTERPOLATION OPTIONS
!                IPOPT(1) IS WIDTH OF SQUARE TO EXAMINE IN SPIRAL SEARCH
!                (DEFAULTS TO 1 IF IPOPT(1)=-1)
!     KGDSI    - INTEGER (200) INPUT GDS PARAMETERS AS DECODED BY W3FI63
!     KGDSO    - INTEGER (200) OUTPUT GDS PARAMETERS
!                (KGDSO(1)<0 IMPLIES RANDOM STATION POINTS)
!     MI       - INTEGER SKIP NUMBER BETWEEN INPUT GRID FIELDS IF KM>1
!                OR DIMENSION OF INPUT GRID FIELDS IF KM=1
!     MO       - INTEGER SKIP NUMBER BETWEEN OUTPUT GRID FIELDS IF KM>1
!                OR DIMENSION OF OUTPUT GRID FIELDS IF KM=1
!     KM       - INTEGER NUMBER OF FIELDS TO INTERPOLATE
!     IBI      - INTEGER (KM) INPUT BITMAP FLAGS
!     LI       - LOGICAL*1 (MI,KM) INPUT BITMAPS (IF SOME IBI(K)=1)
!     GI       - REAL (MI,KM) INPUT FIELDS TO INTERPOLATE
!     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF KGDSO(1)<0)
!     RLAT     - REAL (NO) OUTPUT LATITUDES IN DEGREES (IF KGDSO(1)<0)
!     RLON     - REAL (NO) OUTPUT LONGITUDES IN DEGREES (IF KGDSO(1)<0)
!
!   OUTPUT ARGUMENT LIST:
!     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF KGDSO(1)>=0)
!     RLAT     - REAL (MO) OUTPUT LATITUDES IN DEGREES (IF KGDSO(1)>=0)
!     RLON     - REAL (MO) OUTPUT LONGITUDES IN DEGREES (IF KGDSO(1)>=0)
!     IBO      - INTEGER (KM) OUTPUT BITMAP FLAGS
!     LO       - LOGICAL*1 (MO,KM) OUTPUT BITMAPS (ALWAYS OUTPUT)
!     GO       - REAL (MO,KM) OUTPUT FIELDS INTERPOLATED
!     IRET     - INTEGER RETURN CODE
!                0    SUCCESSFUL INTERPOLATION
!                2    UNRECOGNIZED INPUT GRID OR NO GRID OVERLAP
!                3    UNRECOGNIZED OUTPUT GRID
!
! SUBPROGRAMS CALLED:
!   GDSWZD       GRID DESCRIPTION SECTION WIZARD
!   IJKGDS0      SET UP PARAMETERS FOR IJKGDS1
!   (IJKGDS1)    RETURN FIELD POSITION FOR A GIVEN GRID POINT
!   POLFIXS      MAKE MULTIPLE POLE SCALAR VALUES CONSISTENT
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 USE GDSWZD_MOD
!
 IMPLICIT NONE
!
 INTEGER,               INTENT(IN   ):: IPOPT(20),KGDSI(200)
 INTEGER,               INTENT(IN   ):: KGDSO(200),MI,MO,KM
 INTEGER,               INTENT(IN   ):: IBI(KM)
 INTEGER,               INTENT(INOUT):: NO
 INTEGER,               INTENT(  OUT):: IRET, IBO(KM)
!
 LOGICAL*1,             INTENT(IN   ):: LI(MI,KM)
 LOGICAL*1,             INTENT(  OUT):: LO(MO,KM)
!
 REAL,                  INTENT(IN   ):: GI(MI,KM)
 REAL,                  INTENT(INOUT):: RLAT(MO),RLON(MO)
 REAL,                  INTENT(  OUT):: GO(MO,KM)
!
 REAL,                  PARAMETER    :: FILL=-9999.
!cdz+1
 REAL,                  PARAMETER    :: FILL9=9.999000260554009E+020
!
 INTEGER                             :: IJKGDSA(20)
 INTEGER                             :: I1,J1,IXS,JXS
 INTEGER                             :: MSPIRAL,N,K,NK
 INTEGER                             :: NV,IJKGDS1
 INTEGER                             :: MX,KXS,KXT,IX,JX,NX
 INTEGER,                       SAVE :: KGDSIX(200)=-1,KGDSOX(200)=-1
 INTEGER,                       SAVE :: NOX=-1,IRETX=-1
 INTEGER,           ALLOCATABLE,SAVE :: NXY(:)
!
 REAL,              ALLOCATABLE,SAVE :: RLATX(:),RLONX(:)
 REAL,              ALLOCATABLE,SAVE :: XPTSX(:),YPTSX(:)
 REAL                                :: XPTS(MO),YPTS(MO)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  SET PARAMETERS
 IRET=0
 MSPIRAL=MAX(IPOPT(1),1)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  SAVE OR SKIP WEIGHT COMPUTATION
 IF(IRET.EQ.0.AND.(KGDSO(1).LT.0.OR. &
    ANY(KGDSI.NE.KGDSIX).OR.ANY(KGDSO.NE.KGDSOX))) THEN
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  COMPUTE NUMBER OF OUTPUT POINTS AND THEIR LATITUDES AND LONGITUDES.
   IF(KGDSO(1).GE.0) THEN
     CALL GDSWZD(KGDSO, 0,MO,FILL,XPTS,YPTS,RLON,RLAT,NO)
     IF(NO.EQ.0) IRET=3
   ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  LOCATE INPUT POINTS
   CALL GDSWZD(KGDSI,-1,NO,FILL,XPTS,YPTS,RLON,RLAT,NV)
   IF(IRET.EQ.0.AND.NV.EQ.0) IRET=2
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  ALLOCATE AND SAVE GRID DATA
   KGDSIX=KGDSI
   KGDSOX=KGDSO
   IF(NOX.NE.NO) THEN
     IF(NOX.GE.0) DEALLOCATE(RLATX,RLONX,XPTSX,YPTSX,NXY)
     ALLOCATE(RLATX(NO),RLONX(NO),XPTSX(NO),YPTSX(NO),NXY(NO))
     NOX=NO
   ENDIF
   IRETX=IRET
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  COMPUTE WEIGHTS
   IF(IRET.EQ.0) THEN
     CALL IJKGDS0(KGDSI,IJKGDSA)
!$OMP PARALLEL DO PRIVATE(N)
     DO N=1,NO
       RLONX(N)=RLON(N)
       RLATX(N)=RLAT(N)
       XPTSX(N)=XPTS(N)
       YPTSX(N)=YPTS(N)
       IF(XPTS(N).NE.FILL.AND.YPTS(N).NE.FILL) THEN
         NXY(N)=IJKGDS1(NINT(XPTS(N)),NINT(YPTS(N)),IJKGDSA)
       ELSE
         NXY(N)=0
       ENDIF
     ENDDO
   ENDIF
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
!  INTERPOLATE OVER ALL FIELDS
 IF(IRET.EQ.0.AND.IRETX.EQ.0) THEN
   IF(KGDSO(1).GE.0) THEN
     NO=NOX
     DO N=1,NO
       RLON(N)=RLONX(N)
       RLAT(N)=RLATX(N)
     ENDDO
   ENDIF
   DO N=1,NO
     XPTS(N)=XPTSX(N)
     YPTS(N)=YPTSX(N)
   ENDDO
!$OMP PARALLEL DO PRIVATE(NK,K,N,I1,J1,IXS,JXS,MX,KXS,KXT,IX,JX,NX)
   DO NK=1,NO*KM
     K=(NK-1)/NO+1
     N=NK-NO*(K-1)
     GO(N,K)=0
     LO(N,K)=.FALSE.
     IF(NXY(N).GT.0) THEN
       IF(IBI(K).EQ.0.OR.LI(NXY(N),K)) THEN
         GO(N,K)=GI(NXY(N),K)
         LO(N,K)=.TRUE.
!cdz+1
         IF(GI(NXY(N),K) == FILL9) LO(N,K)=.FALSE.
! SPIRAL AROUND UNTIL VALID DATA IS FOUND.
       ELSEIF(MSPIRAL.GT.1) THEN
         I1=NINT(XPTS(N))
         J1=NINT(YPTS(N))
         IXS=SIGN(1.,XPTS(N)-I1)
         JXS=SIGN(1.,YPTS(N)-J1)
         DO MX=2,MSPIRAL**2
           KXS=SQRT(4*MX-2.5)
           KXT=MX-(KXS**2/4+1)
           SELECT CASE(MOD(KXS,4))
           CASE(1)
             IX=I1-IXS*(KXS/4-KXT)
             JX=J1-JXS*KXS/4
           CASE(2)
             IX=I1+IXS*(1+KXS/4)
             JX=J1-JXS*(KXS/4-KXT)
           CASE(3)
             IX=I1+IXS*(1+KXS/4-KXT)
             JX=J1+JXS*(1+KXS/4)
           CASE DEFAULT
             IX=I1-IXS*KXS/4
             JX=J1+JXS*(KXS/4-KXT)
           END SELECT
           NX=IJKGDS1(IX,JX,IJKGDSA)
           IF(NX.GT.0) THEN
             IF(LI(NX,K)) THEN
               GO(N,K)=GI(NX,K)
               LO(N,K)=.TRUE.
!cdz+1
               IF(GI(NX,K) == FILL9) LO(N,K)=.FALSE.
               EXIT
             ENDIF
           ENDIF
         ENDDO
       ENDIF
     ENDIF
   ENDDO
   DO K=1,KM
     IBO(K)=IBI(K)
     IF(.NOT.ALL(LO(1:NO,K))) IBO(K)=1
   ENDDO
   IF(KGDSO(1).EQ.0) CALL POLFIXS(NO,MO,KM,RLAT,RLON,IBO,LO,GO)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 ELSE
   IF(IRET.EQ.0) IRET=IRETX
   IF(KGDSO(1).GE.0) NO=0
 ENDIF
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE POLATES2
