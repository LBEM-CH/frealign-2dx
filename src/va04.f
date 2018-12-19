C*
C* Copyright 2013 Howard Hughes Medical Institute.
C* All rights reserved.
C* Use is subject to Janelia Farm Research Campus Software Copyright 1.1
C* license terms ( http://license.janelia.org/license/jfrc_copyright_1_1.html )
C*
C**************************************************************************
      SUBROUTINE VA04A(X,E,N,F,ESCALE,IPRINT,ICON,MAXIT,XPAR,NPAR,
     .                 NSAM,MAXR1,MAXR2,MASK,C3DF,
     .		       IRAD,PBUF,SHX,SHY,IPAD,
     .		       CS,WL,WGH1,WGH2,THETATR,CTFF,
     .                 AMAG,RIH,HALFW,RI2,RI3,RI4,PHI,THETA,PSI,RMAX1,
     .		       RMAX2,XSTD,MBUF,ILST,DATC,IBUF,B3DV,
     .		       DATD,SINCLUT,IVFLAG,RBFACT,OUTD,OUTC,QBUC,
     .                 RBUF,FSCT,DFMID1,DFMID2,ANGAST,IEWALD,TX,TY,
     .                 XM,YM,SX,SY,SIG2,DFSTD,ASYM,THETAM,STHETA,
     .                 PSIM,SPSI,STIF,PWEIGHTS,PSSNR,FFTW_PLANS,SM,
     .                 SIGRAD,SIGPHA)
C**************************************************************************
C  STANDARD FORTRAN 66 (A VERIFIED PFORT SUBROUTINE)  - Powell minimisation
C  some changes were made to reduce diagnostic output and prevent occasional
C  crashes (Niko, 12. June 1998)
C  Calls CALCFX
C  Used in PREFINE, MAGREFINE, CTFREFINE.
C**************************************************************************
C
      USE ISO_C_BINDING
C
      INTEGER NSAM,MAXR1,MAXR2
      INTEGER NPAR,MASK(5),IRAD
      INTEGER IBUF,IVFLAG,IPAD,MAXX,I,ICNT,IEWALD
      REAL SHX(*),SHY(*),RBFACT,OUTD(*),RBUF(*),FSCT(*)
      REAL PBUF(*),PHI(*),THETA(*),PSI(*),MBUF(*),TX,TY
      REAL XPAR(6),RI2,RI3,RI4,RMAX1,RMAX2,DATD(*),DFSTD
      REAL CS,WL,WGH1,WGH2,THETATR,RIH,HALFW,SINCLUT(*)
      REAL AMAG,XSTD,XS(10),XM,YM,SX,SY,SIG2,THETAM
      REAL PWEIGHTS(*),PSSNR(*),SM(9)
      REAL DFMID1(*),DFMID2(*),ANGAST(*),STHETA,PSIM,SPSI
      REAL SIGRAD,SIGPHA
C       REAL RANDOM,FRAC
C       INTEGER IRAN
      COMPLEX C3DF(*),CTFF(*),OUTC(*),DATC(*),QBUC(*)
      CHARACTER ASYM*3
      DIMENSION W(60),X(*),E(*)
      TYPE(C_PTR) FFTW_PLANS(*)

      PARAMETER (PI=3.1415926535897)
C**************************************************************************
C	W[N*(N+3)]
C       PRINT *,'Initial PHI for this particle:',X(1)
C       PRINT *,'Initial THETA for this particle:',X(2)
C       PRINT *,'Initial PSI for this particle:',X(3)
C       PRINT *,'Initial DSHX for this particle:',X(4)*180.0*NSAM/PI
C       PRINT *,'Initial DSHY for this particle:',X(5)*180.0*NSAM/PI
C       PRINT *,'Initial EPHI for this particle:',E(1)
C       PRINT *,'Initial ETHETA for this particle:',E(2)
C       PRINT *,'Initial EPSI for this particle:',E(3)
C       PRINT *,'ESCALE:',ESCALE
C       PRINT *,'Initial EDSHX for this particle:',E(4)
C       PRINT *,'Initial EDSHY for this particle:',E(5)
C       PRINT *,'N:',N
C
C     The maximum change that can happen at a given iteration is limited by E(I)*ESCALE:
C       ESCALE=SIGRAD
C 
C       PRINT *,'VA04 SIGRAD:',SIGRAD
C       PRINT *,'VA04 SIGPHA:',SIGPHA
C
C      PRINT *,'FRAC = ',FRAC
C      PRINT *,'IRAN = ',IRAN
C      PRINT *,'RANDOM = ',RANDOM(IRAN)
      DDMAG=0.1*ESCALE
      SCER=0.05/ESCALE
      ICNT=0
      MAXX=100*MAXIT
      DO 999 I=1,N
        XS(I)=X(I)
  999 CONTINUE
      JJ=N*N+N
      JJJ=JJ+N
      K=N+1
      NFCC=1
      IND=1
      INN=1
      DO 1 I=1,N
      DO 2 J=1,N
      W(K)=0.
      IF(I-J)4,3,4
    3 W(K)=ABS(E(I))
      W(I)=ESCALE
C       W(I)=SIGRAD
    4 K=K+1
    2 CONTINUE
    1 CONTINUE
      ITERC=1
      ISGRAD=2
      ICNT=ICNT+1
      IF (ICNT.GT.MAXX) GOTO 998
      CALL CALCFX(N,X,F,XPAR,NPAR,NSAM,MAXR1,MAXR2,MASK,
     .   C3DF,IRAD,PBUF,SHX,SHY,CS,WL,WGH1,WGH2,THETATR,CTFF,
     .   AMAG,RIH,HALFW,RI2,RI3,RI4,PHI,THETA,PSI,RMAX1,RMAX2,
     .   XSTD,MBUF,ILST,DATC,IBUF,B3DV,DATD,
     .   SINCLUT,IVFLAG,RBFACT,OUTD,OUTC,QBUC,IPAD,
     .   RBUF,FSCT,DFMID1,DFMID2,ANGAST,IEWALD,TX,TY,XM,YM,
     .   SX,SY,SIG2,DFSTD,ASYM,THETAM,STHETA,PSIM,SPSI,STIF,
     .   PWEIGHTS,PSSNR,FFTW_PLANS,SM,SIGRAD,SIGPHA)
      FKEEP=ABS(F)+ABS(F)
    5 ITONE=1
      FP=F
      SUM=0.
      IXP=JJ
      DO 6 I=1,N
      IXP=IXP+1
      W(IXP)=X(I)
C       PRINT *,'W(I)',W(I)
    6 CONTINUE
      IDIRN=N+1
      ILINE=1
    7 DMAX=W(ILINE)
      DACC=DMAX*SCER
      DMAG=AMIN1(DDMAG,0.1*DMAX)
      DMAG=AMAX1(DMAG,20.*DACC)
      DDMAX=10.*DMAG
      GO TO (70,70,71),ITONE
   70 DL=0.
      D=DMAG
      FPREV=F
      IS=5
      FA=F
      DA=DL
    8 DD=D-DL
      DL=D
   58 K=IDIRN
      DO 9 I=1,N
C       PRINT *,'F=',F
C       PRINT *,'X(I)=',X(I)
C       PRINT *,'DDMAG=',DDMAG
C       PRINT *,'DMAX=',DMAX
C       PRINT *,'DACC=',DACC
C       PRINT *,'DMAG=',DMAG
C       PRINT *,'DL=',DL
C       PRINT *,'D=',D
C       PRINT *,'DD=',DD
C       PRINT *,'W(K)=',W(K)
      X(I)=X(I)+DD*W(K)
      K=K+1
    9 CONTINUE
      ICNT=ICNT+1
      IF (ICNT.GT.MAXX) GOTO 998
C       PRINT *,'Current PHI for this particle:',X(1)
C       PRINT *,'Current THETA for this particle:',X(2)
C       PRINT *,'Current PSI for this particle:',X(3)
C       PRINT *,'Current DSHX for this particle:',X(4)*180*NSAM/PI
C       PRINT *,'Current DSHY for this particle:',X(5)*180*NSAM/PI
      CALL CALCFX(N,X,F,XPAR,NPAR,NSAM,MAXR1,MAXR2,MASK,
     .   C3DF,IRAD,PBUF,SHX,SHY,CS,WL,WGH1,WGH2,THETATR,CTFF,
     .   AMAG,RIH,HALFW,RI2,RI3,RI4,PHI,THETA,PSI,RMAX1,RMAX2,
     .   XSTD,MBUF,ILST,DATC,IBUF,B3DV,DATD,
     .   SINCLUT,IVFLAG,RBFACT,OUTD,OUTC,QBUC,IPAD,
     .   RBUF,FSCT,DFMID1,DFMID2,ANGAST,IEWALD,TX,TY,XM,YM,
     .   SX,SY,SIG2,DFSTD,ASYM,THETAM,STHETA,PSIM,SPSI,STIF,
     .   PWEIGHTS,PSSNR,FFTW_PLANS,SM,SIGRAD,SIGPHA)
C       PRINT *,'Current F for this particle:',F
      NFCC=NFCC+1
      GO TO (10,11,12,13,14,96),IS
C    14 PRINT *,'D: ',D
C       PRINT *,'DMAX: ',DMAX
   14 IF(F-FA)15,16,24
   16 IF (ABS(D)-DMAX) 17,17,18
   17 D=D+D
      GO TO 8
   18 WRITE(6,19)
   19 FORMAT(5X,50HPOWELL MIN: MAXIMUM CHANGE DOES NOT ALTER FUNCTION)
C   19 FORMAT(5X,44HVA04A MAXIMUM CHANGE DOES NOT ALTER FUNCTION)
C       GO TO 20
      GO TO 998
   15 FB=F
      DB=D
      GO TO 21
   24 FB=FA
      DB=DA
      FA=F
      DA=D
   21 GO TO (83,23),ISGRAD
   23 D=DB+DB-DA
      IS=1
      GO TO 8
   83 D=0.5*(DA+DB-(FA-FB)/(DA-DB))
      IS=4
      IF((DA-D)*(D-DB))25,8,8
   25 IS=1
      IF(ABS(D-DB)-DDMAX)8,8,26
   26 D=DB+SIGN(DDMAX,DB-DA)
      IS=1
      DDMAX=DDMAX+DDMAX
      DDMAG=DDMAG+DDMAG
      IF(DDMAX-DMAX)8,8,27
   27 DDMAX=DMAX
      GO TO 8
   13 IF(F-FA)28,23,23
   28 FC=FB
      DC=DB
   29 FB=F
      DB=D
      GO TO 30
   12 IF(F-FB)28,28,31
   31 FA=F
      DA=D
      GO TO 30
   11 IF(F-FB)32,10,10
   32 FA=FB
      DA=DB
      GO TO 29
   71 DL=1.
      DDMAX=5.
      FA=FP
      DA=-1.
      FB=FHOLD
      DB=0.
      D=1.
   10 FC=F
      DC=D
   30 A=(DB-DC)*(FA-FC)
      B=(DC-DA)*(FB-FC)
      IF((A+B)*(DA-DC))33,33,34
   33 FA=FB
      DA=DB
      FB=FC
      DB=DC
      GO TO 26
   34 D=0.5*(A*(DB+DC)+B*(DA+DC))/(A+B)
      DI=DB
      FI=FB
      IF(FB-FC)44,44,43
   43 DI=DC
      FI=FC
   44 GO TO (86,86,85),ITONE
   85 ITONE=2
      GO TO 45
   86 IF (ABS(D-DI)-DACC) 41,41,93
   93 IF (ABS(D-DI)-0.03*ABS(D)) 41,41,45
   45 IF ((DA-DC)*(DC-D)) 47,46,46
   46 FA=FB
      DA=DB
      FB=FC
      DB=DC
      GO TO 25
   47 IS=2
      IF ((DB-D)*(D-DC)) 48,8,8
   48 IS=3
      GO TO 8
   41 F=FI
      D=DI-DL
      DD=(DC-DB)*(DC-DA)*(DA-DB)/(A+B)
      IF (DD.LT.0.0) DD=1E-10
      DD=SQRT(DD)
      DO 49 I=1,N
      X(I)=X(I)+D*W(IDIRN)
      W(IDIRN)=DD*W(IDIRN)
      IDIRN=IDIRN+1
   49 CONTINUE
      IF (DD.EQ.0.0) DD=1E-10
      W(ILINE)=W(ILINE)/DD
      ILINE=ILINE+1
      IF(IPRINT-1)51,50,51
   50 CONTINUE
C   50 WRITE(6,52) ITERC,NFCC,F,(X(I),I=1,N)
   52 FORMAT (/1X,9HITERATION,I5,I15,16H FUNCTION VALUES,
     110X,3HF =,E21.14/(5E24.14))
      GO TO(51,53),IPRINT
   51 GO TO (55,38),ITONE
   55 IF (FPREV-F-SUM) 94,95,95
   95 SUM=FPREV-F
      JIL=ILINE
   94 IF (IDIRN-JJ) 7,7,84
   84 GO TO (92,72),IND
   92 FHOLD=F
      IS=6
      IXP=JJ
      DO 59 I=1,N
      IXP=IXP+1
      W(IXP)=X(I)-W(IXP)
   59 CONTINUE
      DD=1.
      GO TO 58
   96 GO TO (112,87),IND
  112 IF (FP-F) 37,37,91
   91 D=2.*(FP+F-2.*FHOLD)/(FP-F)**2
      IF (D*(FP-FHOLD-SUM)**2-SUM) 87,37,37
   87 J=JIL*N+1
      IF (J-JJ) 60,60,61
   60 DO 62 I=J,JJ
      K=I-N
      W(K)=W(I)
   62 CONTINUE
      DO 97 I=JIL,N
      W(I-1)=W(I)
   97 CONTINUE
   61 IDIRN=IDIRN-N
      ITONE=3
      K=IDIRN
      IXP=JJ
      AAA=0.
      DO 65 I=1,N
      IXP=IXP+1
      W(K)=W(IXP)
      IF (AAA-ABS(W(K)/E(I))) 66,67,67
   66 AAA=ABS(W(K)/E(I))
   67 K=K+1
   65 CONTINUE
      DDMAG=1.
      IF (AAA.EQ.0.0) AAA=1E-10
      W(N)=ESCALE/AAA
      ILINE=N
      GO TO 7
   37 IXP=JJ
      AAA=0.
      F=FHOLD
      DO 99 I=1,N
      IXP=IXP+1
      X(I)=X(I)-W(IXP)
      IF (AAA*ABS(E(I))-ABS(W(IXP))) 98,99,99
   98 AAA=ABS(W(IXP)/E(I))
   99 CONTINUE
      GO TO 72
   38 AAA=AAA*(1.+DI)
      GO TO (72,106),IND
   72 IF (IPRINT-2) 53,50,50
   53 GO TO (109,88),IND
  109 IF (AAA-0.1) 89,89,76
   89 GO TO (20,116),ICON
  116 IND=2
      GO TO (100,101),INN
  100 INN=2
      K=JJJ
      DO 102 I=1,N
      K=K+1
      W(K)=X(I)
      X(I)=X(I)+10.*E(I)
  102 CONTINUE
      FKEEP=F
      ICNT=ICNT+1
      IF (ICNT.GT.MAXX) GOTO 998
      CALL CALCFX(N,X,F,XPAR,NPAR,NSAM,MAXR1,MAXR2,MASK,
     .   C3DF,IRAD,PBUF,SHX,SHY,CS,WL,WGH1,WGH2,THETATR,CTFF,
     .   AMAG,RIH,HALFW,RI2,RI3,RI4,PHI,THETA,PSI,RMAX1,RMAX2,
     .   XSTD,MBUF,ILST,DATC,IBUF,B3DV,DATD,
     .   SINCLUT,IVFLAG,RBFACT,OUTD,OUTC,QBUC,IPAD,
     .   RBUF,FSCT,DFMID1,DFMID2,ANGAST,IEWALD,TX,TY,XM,YM,
     .   SX,SY,SIG2,DFSTD,ASYM,THETAM,STHETA,PSIM,SPSI,STIF,
     .   PWEIGHTS,PSSNR,FFTW_PLANS,SM,SIGRAD,SIGPHA)
      NFCC=NFCC+1
      DDMAG=0.
      GO TO 108
   76 IF (F-FP) 35,78,78
   78 CONTINUE
C   78 WRITE(6,80)
   80 FORMAT (5X,43HPOWELL MIN: ACCURACY LIMITED BY ERRORS IN F)
C   80 FORMAT (5X,37HVA04A ACCURACY LIMITED BY ERRORS IN F)
      GO TO 20
   88 IND=1
   35 TMP=FP-F
      IF (TMP.GT.0.0) THEN
      DDMAG=0.4*SQRT(TMP)
      ELSE
      DDMAG=0.0
      ENDIF
      ISGRAD=1
  108 ITERC=ITERC+1
      IF (ITERC-MAXIT) 5,5,81
81    CONTINUE
C   81 WRITE(6,82) MAXIT
   82 FORMAT(I5,30H ITERATIONS COMPLETED BY VA04A)
      IF (F-FKEEP) 20,20,110
  110 F=FKEEP
      DO 111 I=1,N
      JJJ=JJJ+1
      X(I)=W(JJJ)
  111 CONTINUE
      GO TO 20
  101 JIL=1
      FP=FKEEP
      IF (F-FKEEP) 105,78,104
  104 JIL=2
      FP=F
      F=FKEEP
  105 IXP=JJ
      DO 113 I=1,N
      IXP=IXP+1
      K=IXP+N
      GO TO (114,115),JIL
  114 W(IXP)=W(K)
      GO TO 113
  115 W(IXP)=X(I)
      X(I)=W(K)
  113 CONTINUE
      JIL=2
      GO TO 92
  106 IF (AAA-0.1) 20,20,107
   20 CONTINUE
      RETURN
  107 INN=1
      GO TO 35
  998 CONTINUE
      DO 997 I=1,N
        X(I)=XS(I)
  997 CONTINUE
      CALL CALCFX(N,X,F,XPAR,NPAR,NSAM,MAXR1,MAXR2,MASK,
     .   C3DF,IRAD,PBUF,SHX,SHY,CS,WL,WGH1,WGH2,THETATR,CTFF,
     .   AMAG,RIH,HALFW,RI2,RI3,RI4,PHI,THETA,PSI,RMAX1,RMAX2,
     .   XSTD,MBUF,ILST,DATC,IBUF,B3DV,DATD,
     .   SINCLUT,IVFLAG,RBFACT,OUTD,OUTC,QBUC,IPAD,
     .   RBUF,FSCT,DFMID1,DFMID2,ANGAST,IEWALD,TX,TY,XM,YM,
     .   SX,SY,SIG2,DFSTD,ASYM,THETAM,STHETA,PSIM,SPSI,STIF,
     .   PWEIGHTS,PSSNR,FFTW_PLANS,SM,SIGRAD,SIGPHA)
      PRINT *,'VA04A ENDLESS LOOP SAFETY CATCH: ICNT = ',ICNT
      RETURN
      END
