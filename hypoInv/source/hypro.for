      SUBROUTINE HYPRO
C--INTERACTIVELY PROCESS EVENTS IN INDIVIDUAL FILES.
      LOGICAL LR,KILLS, LTEMP, LKILL
      CHARACTER BASE*20,C13*15,CP*1,CC*1,CS*1,SCD*1,TRY(20)*103
      CHARACTER STA*5, SNET*2, SCOMP*3, SLOC*2
      CHARACTER PRVSTA*5, PRVNET*2, PRVCMP*3, PRVLOC*2
      INCLUDE 'common.inc'
      LOGICAL FOUNDIT
C--LASK IS A LOGICAL FUNCTION. THE OS2 COMPILER COMPLAINS WITHOUT THESE LINES
c      LOGICAL LASK
c      EXTERNAL LASK

      BASE=' '
      ISEQ=0

C--BLANK OUT STATION CODES
      STA=' '
      SNET=' '
      SCOMP=' '
      SLOC=' '
      PRVSTA=' '
      PRVNET=' '
      PRVCMP=' '
      PRVLOC=' '

C--IF ALL SUBSEQUENT STATIONS ARE WEIGHTED OUT USING !, KLAST REMEMBERS LAST
C  STATION KEPT
      KLAST=0

C--OPEN THE EVENT ID FILE WHICH LISTS BASE FILENAMES TO BE PROCESSED.
      CALL OPENR (17,LSTFIL,'F',IOS)
      IF (IOS.NE.0) GOTO 32

C****************** BEGIN EVENT LOOP **********************************
C--READ THE BASE ID STRING FROM THE EVENT LIST FILE
2     READ (17,LSTFOR,ERR=31,END=70) BASE(1:NCBASE)
C--IGNORE BLANK LINES OR ONES COMMENTED OUT WITH * IN COL 1
      IF (BASE.EQ.'                    ' .OR. BASE(1:1).EQ.'*') GOTO 2
C--TURN ANY BLANKS IN THE FILENAME TO ZEROS
      DO I=1,NCBASE
        IF (BASE(I:I).EQ.' ') BASE(I:I)='0'
      END DO

C--FORM THE I/O FILENAMES FROM THE BASE STRING
      PHSFIL=' '
      ARCFIL=' '
      SUMFIL=' '
      PRTFIL=' '
      PHSFIL=(BASE(1:NCBASE)//EXTPHS)
      ARCFIL=(BASE(1:NCBASE)//EXTARC)
      SUMFIL=(BASE(1:NCBASE)//EXTSUM)
      PRTFIL=(BASE(1:NCBASE)//EXTPRT)

C--INITIALIZE SOME VARIABLES. DONT CALL HYOPEN OR HYSTL.
      ISEQ=ISEQ+1
      CALL HYINIT
      GOTO 38

C--ERROR READING EVENT ID
31    WRITE (6,*)' *** ERROR - BAD EVENT ID OR FORMAT NEAR: '
      WRITE (6,*) BASE(1:NCBASE)
      GOTO 2

C--HERE IS THE ERROR MESSAGE FOR NON-EXISTENT EVENT LIST FILES
32    WRITE (6,*)' *** ERROR - EVENT LIST FILE DOES NOT EXIST ***'
      RETURN

C--HERE IS THE ERROR MESSAGE FOR NON-EXISTENT PHASE FILES
33    WRITE (6,1010) PHSFIL
1010      FORMAT (' *** ERROR - PHASE FILE DOES NOT EXIST:'/1X,A)
      GOTO 2

C--ERROR MESSAGE FOR NON-EXISTENT PRINT FILES
34    WRITE (6,1003) PRTFIL
1003      FORMAT (' *** ERROR - PRINT FILE DOES NOT EXIST:'/1X,A)
      GOTO 42

C********************** BEGIN EVENT PROCESSING LOOP *******************
C--OPEN PHASE FILE & READ IT
38    KEND=0
      IF (JCP.LT.6) THEN
        CALL OPENR (14,PHSFIL,'F',IOS)
        IF (IOS.NE.0) GOTO 33
      ELSE
        WRITE (6,'('' *** CANNOT PROCESS CUSP EVENTS INTERACTIVELY'')')
        RETURN
      END IF

C--GO READ THE EVENT
      CALL HYPHS
C--CLOSE FILE UNLESS IT IS A LARGE EVENT AND MORE PHASES REMAIN
      IF (.NOT.LTBIG) CLOSE (14)

C--INITIALIZE SOME VALUES
      INUM=0

C--KEND IS SET BY HYPHS DEPENDING ON END-OF-FILE STATUS
C  =-1  END OF FILE, STOP RIGHT AWAY
C  = 0  LOCATE THIS EVENT, THEN READ ANOTHER
C  = 1  END OF FILE, LOCATE THIS EVENT THEN STOP
      IF (KEND.LT.0) THEN
        WRITE (6,1004) BASE(1:NCBASE)
1004    FORMAT (' *** CANNOT FIND DATA FOR ',A)
        GOTO 2
      END IF

C--SET THE TRIAL HYPOCENTER
C--RETURN HERE IF ONLY THE WEIGHTS WERE CHANGED IN THE PRINT FILE
42    CALL HYTRL

C--OPEN OUTPUT FILES
      IF (LSUM) CALL OPENW (12,SUMFIL,'F',IOS,'S')
      IF (LARC) CALL OPENW (7,ARCFIL,'F',IOS,'S')
      IF (LPRT) CALL OPENW (15,PRTFIL,'F',IOS,'S')

C--WRITE HEADER
      IF (LPRT) WRITE (15,1005) ISEQ,INUM,IDNO
1005  FORMAT (I6,'=SEQUENCE',I4,'=TRY',I10,'=ID')
C--LOCATE THE EVENT
      CALL HYLOC

C--ASSIGN A 3-LETTER CODE AND NAME BASED ON LOCATION
C  I IS THE REGION NUMBER, PRESENTLY UNUSED
      IF (NET.GT.0) I=KLAS (NET,CLAT,-CLON,Z1,REMK,FULNAM)

C--CALCULATE THE EARTHQUAKE'S MAGNITUDE
      CALL HYMAG

C--CALCULATE THE EARTHQUAKE'S P AMPLITUDE MAGNITUDE
      CALL HYMAGP

C--SELECT PREFERRED MAGNITUDE
      CALL HYPREF

C--TABULATE DATA SOURCE CODES
      CALL HYSOU

C--WRITE PAST LOCATION TRIES, IF ANY
      IF (INUM.GT.1 .AND. LPRT) THEN
        WRITE (15,1000)
        DO I=1,INUM-1
          WRITE (15,'(A)') TRY(I)
        END DO
      END IF

C--GENERATE PRINTED AND ARCHIVE OUTPUT
      CALL HYLST

C--ABORT THE LOOP IF THERE ARE NOT ENOUGH READINGS
      IF (NWR.LT.MINSTA) THEN
        WRITE (6,1002) NWR,KYEAR2,KMONTH,KDAY,KHOUR,KMIN
        IF (LPRT) WRITE (15,1002) NWR,KYEAR2,KMONTH,KDAY,KHOUR,KMIN
1002    FORMAT (' *** ABANDON EVENT WITH ONLY',I2,' READINGS:',I4,4I3)
        GOTO 2
      END IF

C--OUTPUT SUMMARY DATA USING UNIT NUMBER FOR SUMMARY FILE
      IF (LSUM) CALL HYSUM (12)

C--COPY THE REST OF A LARGE EVENT TO OUTPUT FILES
      IF (LTBIG) THEN
        CALL HYPHS
        CLOSE (14)
      END IF

C--RECORD THIS LOCATION TRY
      IT=NINT(XLTM)
      IN=NINT(XLNM)
      IDMIN=NINT(DMIN)
      WRITE (TRY(INUM),1011) ISEQ,INUM,KYEAR2,KMONTH,KDAY,
     2 KHOUR,KMIN,REMK, RMK1,RMK2, LAT,IT,LON,IN,
     3 Z1,RMS,PMAG,LABPR,NWR, ERH,ERZ,IDMIN,IDNO

1011  FORMAT (1X,I4,I3,I5,'/',I2,'/',I2,
     2 I3,':',I2.2, 1X,A3, 2A1, 1X,2I3,I5,I3, 
     3 F7.2,F5.2,F5.1,A1,I3, 2F5.1,I5,I10)

C--OUTPUT A MESSAGE ON THE CONSOLE FOR EACH EVENT SO FAR
      IF (LREP) THEN
        WRITE (6,1000)
1000    FORMAT ('  SEQ TRY ---DATE--  TIME REMARK -LAT-  --LON-  ',
     2 'DEPTH  RMS PMAG NUM  ERH  ERZ DMIN')
        DO I=1,INUM
          WRITE (6,'(A)') TRY(I)
        END DO
      END IF

C--CLOSE FILES
      CLOSE (12)
      CLOSE (7)
      CLOSE (15)

C--NOW GO EDIT THE PRINT FILE TO LOOK AT THE EVENT
      IF (LPRT) THEN
C--IF THE EDITOR AUTOMATICALLY ERASES THE SCREEN, IT MAY BE GOOD TO HAVE A
C  DELAY OR PAUSE HERE, LIKE THIS:
C        WRITE (6,*)' PRESS RETURN TO CONTINUE'
C        READ (5,*)
        CALL HYEDIT (IEDFLG,PRTFIL)
      END IF

C--DECIDE WHETHER TO RELOCATE, ISSUE A COMMAND OR CONTINUE TO NEXT EVENT
48    INST=' '
      KILLS=.FALSE.
      WRITE(6,*)' T=RELOCATE, RETURN=CONTINUE, KS=KILL S & RELOCATE,'
      CALL ASKC(
     2 'KA=KILL P&S & CONTINUE, ZXZ=DELETE, ELSE SYSTEM COMMAND',INST)
      IF (INST.EQ.' ') GOTO 2

C--DELETE ENTIRE EVENT
      IF (INST.EQ.'ZXZ ' .OR. INST.EQ.'zxz ') THEN
        LX=LENG(EXTPHS)
        CALL HYDELT (BASE,NCBASE, EXTPHS,LX)
        LX=LENG(EXTARC)
        CALL HYDELT (BASE,NCBASE, EXTARC,LX)
        LX=LENG(EXTPRT)
        CALL HYDELT (BASE,NCBASE, EXTPRT,LX)
        LX=LENG(EXTSUM)
        CALL HYDELT (BASE,NCBASE, EXTSUM,LX)
        GOTO 48
      END IF

C--KILL (UPWEIGHT) ALL P & S
      IF (INST.EQ.'KA  ' .OR. INST.EQ.'ka  ') THEN
C--UPWEIGHT P&S WEIGHTS. DATA SHOULD STILL BE IN MEMORY
        DO K=1,KSTA
          KWT(K)=99
        END DO

C--OPEN ARC FILE, BUT OMIT PRINT FILE
        IF (LARC) CALL OPENW (7,ARCFIL,'F',IOS,'S')
        LTEMP=LPRT
        LPRT=.FALSE.
        CALL HYLST
        LPRT=LTEMP
C--CLOSE FILE & GO TO NEXT EVENT
        CLOSE (7)
        GOTO 2
      END IF

C--ISSUE A COMMAND
      IF (INST.NE.'T    ' .AND. INST.NE.'t    ' .AND.
     2  INST.NE.'KS  ' .AND. INST.NE.'ks  ') THEN
        CALL SPAWN (INST)
        GOTO 48
      END IF

C--SET FLAG TO KILL S WEIGHTS AFTER REREADING EVENT
      KILLS= INST.EQ.'KS  ' .OR. INST.EQ.'ks  '

C--RELOCATE THE EVENT
C--DECIDE WHETHER TO EDIT PHASE FILE TO MAKE MORE CHANGES THAN JUST WEIGHTING
      LR=LASK('EDIT THE INPUT PHASE FILE',.FALSE.)
      IF (LR)  CALL HYEDIT (IEDFLG,PHSFIL)

C--READ THE PHASE FILE EVEN IF IT WAS NOT CHANGED TO RESET TRIAL HYPO, ETC.
      KEND=0
      CALL OPENR (14,PHSFIL,'F',IOS)
      CALL HYPHS
      CLOSE (14)
      IF (KEND.LT.0) THEN
        WRITE (6,1004) BASE(1:NCBASE)
        GOTO 2
      END IF

C--UPWEIGHT (KILL) ALL S READINGS
      IF (KILLS) THEN
        DO K=1,KSTA
          IF (KSRK(K).NE.'  ') THEN
            LSWT=KWT(K)/10
            LPWT=KWT(K)-10*LSWT
            IF (LSWT.LT.5) LSWT=LSWT+5
            KWT(K)=LPWT+10*LSWT
          END IF
        END DO
      END IF

C--READ THE PRINT FILE TO SEE IF ANY WEIGHTS WERE CHANGED. THESE CHANGES WILL
C  OVERRIDE ANY MADE IN THE PHASE FILE. USE THE PHASE UNIT NUMBER.
      IF (LPRT) THEN
        CALL OPENR (14,PRTFIL,'F',IOS)
        IF (IOS.NE.0) GOTO 34

C--SEARCH THE PRINT FILE FOR THE BEGINNING OF THE STATION LIST
51      READ (14,'(A15)',END=59) C13
        IF (C13.NE.' STA NET COM L ') GOTO 51

C--SEARCH FOR STATIONS WITH NEW WEIGHTS IN COLS 1 & 6. NEW WEIGHT CODES:
C  BLANK: NO CHANGE
C  0-9  : NEW WEIGHT CODE
C  "-"  : ADD 5 TO WEIGHT CODE (WEIGHT OUT)
C  "+"  : SUBTRACT 5 FROM WEIGHT CODE (RESTORE)
C  "!"  : WEIGHT OUT THIS AND ALL FOLLOWING P & S READINGS
C
C  COL  1: P WEIGHT CODE
C  COL  9: CODA WEIGHT CODE
C  COL 13: S WEIGHT CODE

C--LKILL SIGNALS WHETHER ALL SUBSEQUENT STATIONS ARE TO BE WEIGHTED OUT
        LKILL=.FALSE.

C--READ AND MATCH THE SOURCE CODE FROM PRINT COL 75 (FWK CHANGE V. 1.38)
53      READ (14,'(A15,T75,A1)',END=59) C13,SCD
        CP=C13(1:1)
        CC=C13(9:9)
        CS=C13(13:13)
        STA=C13(2:6)
        SNET=C13(7:8)
        SCOMP=C13(10:12)
        SLOC=C13(14:15)

C--IF STATION CODE WAS LEFT OUT, GET IT FROM PREVIOUS LINE (PRVSTA
C  SHOULD NEVER BE BLANK WHEN STA IS BLANK)
        IF (STA.EQ.'     ') THEN
          STA=PRVSTA
          SNET=PRVNET
          SCOMP=PRVCMP
          SLOC=PRVLOC
        END IF
        PRVSTA=STA
        PRVNET=SNET
        PRVCMP=SCOMP
        PRVLOC=SLOC
        FOUNDIT=.FALSE.

C--WEIGHT OUT THIS AND ALL SUBSEQUENT STATIONS
        IF (CP.EQ.'!') LKILL=.TRUE.

        IF (CP.EQ.' ' .AND. CC.EQ.' ' .AND.
     2  (CS.LT.'+' .OR. CS.GT.'9') .AND. .NOT.LKILL) GOTO 53

C--FIND STATION CODE IN STATION TABLE, THEN IN PHASE TABLE
        DO J=1,JSTA
          IF (STA(1:NSTLET) .EQ. STANAM(J)(1:NSTLET) .AND.
     2    SNET(1:NETLET) .EQ. JNET(J)(1:NETLET) .AND.
     3    (SLOC(1:NSLOC2) .EQ. JSLOC(J)(1:NSLOC2) .OR.
     3    SLOC(1:NSLOC2) .EQ. JSLOC2(J)(1:NSLOC2)) .AND.
     4    SCOMP(1:NCOMP) .EQ. JCOMP3(J)(1:NCOMP)) THEN
            DO K=1,KSTA
C--CONTINUE SEARCHING UNTIL DATA SOURCE CODES ALSO MATCH (IN CASE OF DUP. DATA)
              IF (KINDX(K).EQ.J .AND. SCD.EQ.KSOU(K)) THEN
                KLAST=K

C--GET PREVIOUS WEIGHT CODES
                LSWT=KWT(K)/10
                LPWT=KWT(K)-10*LSWT

C--WEIGHT OUT P & S WITHOUT CHECKING WHATS MARKED FOR THIS STATION
                IF (LKILL) THEN
                  IF (LPWT.LT.5) LPWT=LPWT+5
                  IF (KSRK(K).NE.'  ' .AND. LSWT.LT.5) LSWT=LSWT+5
                  GOTO 55
                END IF

C--DECODE NEW P WEIGHT CODE
                IF (CP.GE.'0' .AND. CP.LE.'9') THEN
                  READ (CP,'(I1)') LPWT
                ELSE IF (CP.EQ.'-') THEN
                  IF (LPWT.LT.5) LPWT=LPWT+5
                ELSE IF (CP.EQ.'+') THEN
                  LPWT=LPWT-5
                  IF (LPWT.LT.0) LPWT=0
                END IF

C--DECODE NEW S WEIGHT CODE
                IF (CS.GE.'0' .AND. CS.LE.'9') THEN
                  READ (CS,'(I1)') LSWT
                ELSE IF (CS.EQ.'-') THEN
                  IF (LSWT.LT.5) LSWT=LSWT+5
                ELSE IF (CS.EQ.'+') THEN
                  LSWT=LSWT-5
                  IF (LSWT.LT.0) LSWT=0
                END IF

C--DECODE NEW CODA WEIGHT CODE
55              IF (CC.GE.'0' .AND. CC.LE.'9') THEN
                  READ (CC,'(I1)') KFWT(K)
                ELSE IF (CC.EQ.'-') THEN
                  IF (KFWT(K).LT.5) KFWT(K)=KFWT(K)+5
                ELSE IF (CC.EQ.'+') THEN
                  KFWT(K)=KFWT(K)-5
                  IF (KFWT(K).LT.0) KFWT(K)=0
                END IF

C--RELOAD NEW P & S WEIGHTS
                KWT(K)=LPWT+10*LSWT
                FOUNDIT=.TRUE.
C--THIS STATION IN THE PHASE LIST IS DONE
C--CONTINUE SEARCHING THE PHASE LIST FOR MORE OCCURRENCES OF THE SAME STATION
C                GOTO 53 !STATEMENT COMMENTED OUT TO CONTINUE SEARCHING PHASES
              END IF
            END DO
            IF (.NOT.FOUNDIT) WRITE (6,1059) STA,SCD
1059        FORMAT (' *** CANNOT CHANGE STATION ',A5,1X,A1,
     2      '. NOT USED IN THIS EVENT') 
            GOTO 53
          END IF
        END DO
        WRITE (6,1060) STA
1060    FORMAT (' *** CANNOT CHANGE STATION ',A5,
     2  ' WAS NEVER IN STATION FILE')
        GOTO 53

59      CLOSE (14)
      END IF

C--NOW GO RELOCATE THE EVENT USING THE DATA IN MEMORY
      GOTO 42

C--END OF EVENT LIST TO BE PROCESSED
70    CLOSE (17)
      RETURN
      END
