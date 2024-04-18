      SUBROUTINE HYDELT (STR1,LEN1,STR2,LEN2)
C--DELETES A FILE FOR HYPOINVERSE USED WITH INTERACTIVE PROCESSING
C--THE FILENAME IS THE CONCATENATION OF STR1 & STR2.
C--LEN1 AND LEN2 ARE THE LENGTHS OF THE ACTUAL FILE NAMES WITHIN THE 
C  CHARACTER STRINGS.  IF LEN2=0, ONLY THE FIRST STRING IS USED.

      CHARACTER STR1*(*),STR2*(*), CTEMP*100
      CTEMP=' '

C--VAX
C      IF (LEN2.EQ.0) THEN
C        CALL LIB$DELETE_FILE ((STR1(1:LEN1)//';*'))
C      ELSE
C        CALL LIB$DELETE_FILE ((STR1(1:LEN1)//STR2(1:LEN2)//';*'))
C      END IF

C--SUN/UNIX
      IF (LEN2.EQ.0) THEN
        CTEMP=('rm '//STR1(1:LEN1))
      ELSE
        CTEMP=('rm '//STR1(1:LEN1)//STR2(1:LEN2))
      END IF
      I = SYSTEM (CTEMP)
      WRITE (*,*) I

C--OS2
C      INCLUDE 'fsublib.fi'
C      CHARACTER STRING*80
C      IF (LEN2.EQ.0) THEN
C        STRING = ('rm ' // STR1(1:LEN1))
C      ELSE
C        STRING = ('rm ' // STR1(1:LEN1) // STR2(1:LEN2))
C      END IF
C      I = FSYSTEM (STRING)
C      WRITE (*,*) I

      RETURN
      END
