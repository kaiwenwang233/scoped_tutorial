        
c	SUBROUTINE CONVERTm(XLATC,XLONC,XDEPC,XLAT,XLON,DEPTH,X,Y,Z,IACTION,n)
c        real*8  xlatc,xlonc,xdepc,xlat(*),xlon(*),depth(*)
c        real*8 x(*),y(*),z(*)
c        integer iaction,n

c        do j=1,n
c	   call CONVERT(XLATC,XLONC,XDEPC,XLAT(j),XLON(j),DEPTH(j),
c     +                  X(j),Y(j),Z(j),IACTION)
c        end do

c        return
c        end


	SUBROUTINE CONVERT(LATC,LONC,DEPC,LAT,LON,DEP,XX,YY,ZZ,IACTION)
c	SUBROUTINE CONVERT(XLATC,XLONC,XDEPC,XLAT,XLON,DEPTH,X,Y,Z,IACTION)

	IMPLICIT REAL*8 (A - H)
	IMPLICIT REAL*8 (O - Z)
	PARAMETER (ALPHA=0.0033528132)
	PARAMETER (RE=6378.163)	!equatorial radius
	PARAMETER (RP=6356.778)	!POLAR RADIUS
	PARAMETER (PI=3.141592654)

	REAL*8 XHAT(3),YHAT(3),ZHAT(3),TEMP(3)
	REAL*4 LATC,LONC,DEPC,LAT,LON,DEP,XX,YY,ZZ


	XLATC=DBLE(LATC)
	XLONC=DBLE(LONC)
	XDEPC=DBLE(DEPC)
	XLAT=DBLE(LAT)
	XLON=DBLE(LON)
	DEPTH=DBLE(DEP)


C	   FIRST EXPRESS THE CENTER OF THE NEW COORDINATE SYSTEM IN TERMS
C	   OF A RIGHT-HAND COORDINATE SYSTEM (ORIGIN AT CENTER OF EARTH,
C	   X AXIS POINTS TO 0 DEGREES LONGITUDE, Z POINTS TO NORTH POLE
c	   CORRECTING FOR THE ELLIPTICITY OF THE EARTH
	XLATRAD=XLATC*PI/180.0
	XLONRAD=XLONC*PI/180.0
	R=RP*RE/SQRT( (RE*SIN(XLATRAD))**2+(RP*COS(XLATRAD))**2)-XDEPC
	ZOLD=R*SIN(XLATRAD)
	XOLD=R*COS(XLATRAD)*COS(XLONRAD)
	YOLD=R*COS(XLATRAD)*SIN(XLONRAD)

C	   THE NEW COORDINATE SYSTEM WILL HAVE X POINTING TO THE NORTH
C	   AND NORMAL TO THE VECTOR POINTING FROM THE CENTER OF THE
C	   EARTH TO THE ORIGIN OF THE NEW COORDINATES, SO THE COORDINATES
C	   OF THE NEW X AXIS ARE:
	XHAT(3)=COS(XLATRAD)
	XHAT(1)=SIN(XLATRAD)*COS(XLONRAD+PI)
	XHAT(2)=SIN(XLATRAD)*SIN(XLONRAD+PI)

C	   THE Z AXIS IN THE NEW COORDINATE SYSTEM POINTS IN THE OPPOSITE
C	   DIRECTION TO THE VECTOR FROM THE CENTER OF THE EARTH TO THE
C	   ORIGIN OF COORDINATES SO IT IS GIVEN BY:
	DEN=SQRT(XOLD*XOLD+YOLD*YOLD+ZOLD*ZOLD)
	ZHAT(1)=-XOLD/DEN
	ZHAT(2)=-YOLD/DEN
	ZHAT(3)=-ZOLD/DEN

C	   THE Y AXIS IN THE NEW COORDINATE SYSTEM IS THE CROSS-PRODUCT
C	   OF ZHAT WITH XHAT
	YHAT(1)=ZHAT(2)*XHAT(3)-XHAT(2)*ZHAT(3)
	YHAT(2)=XHAT(1)*ZHAT(3)-ZHAT(1)*XHAT(3)
	YHAT(3)=ZHAT(1)*XHAT(2)-XHAT(1)*ZHAT(2)


	IF(IACTION.EQ.0)THEN		!CONVERT FROM LAT AND LON TO X,Y


C	   TO EXPRESS ANY POINT IN THE NEW COORDINATE SYSTEM WE FIRST
C	   TRANSFORM IT INTO THE COORDINATE SYSTEM CENTERED AT
C	   THE EARTH CENTER, THEN SHIFT IT BY -XOLD,-YOLD,-ZOLD, THEN
C	   DOT THE SHIFTED COORDINATES WITH THE AXIS VECTORS IN THE ROTATED
C	   COORDINATE SYSTEM.

	   XLATRAD=XLAT*PI/180.0
	   XLONRAD=XLON*PI/180.0
	   R=RP*RE/SQRT( (RE*SIN(XLATRAD))**2+(RP*COS(XLATRAD))**2)
     +       -DEPTH
	   TEMP(3)=R*SIN(XLATRAD)-ZOLD
	   TEMP(1)=R*COS(XLATRAD)*COS(XLONRAD)-XOLD
	   TEMP(2)=R*COS(XLATRAD)*SIN(XLONRAD)-YOLD
	   X=DOT(TEMP,XHAT)
	   Y=DOT(TEMP,YHAT)
	   Z=DOT(TEMP,ZHAT)
	   XX=X
	   YY=Y
	   ZZ=Z
	ELSE		!CONVERT FROM X,Y,Z TO LATITUDE,LONGITUDE,DEPT
C	   X=DBLE(XX)
C    	   Y=DBLE(YY)
C	   Z=DBLE(ZZ)

	   DO J=1,3
		TEMP(J)=X*XHAT(J)+Y*YHAT(J)+Z*ZHAT(J)
	   END DO
	   TEMP(1)=TEMP(1)+XOLD
	   TEMP(2)=TEMP(2)+YOLD
	   TEMP(3)=TEMP(3)+ZOLD
	   RADIUS=0.0
	   DO J=1,3
	      RADIUS=RADIUS+TEMP(J)**2
	   END DO
	   RADIUS=SQRT(RADIUS)
	   XLON=ATAN2(TEMP(2),TEMP(1))
	   XLAT=Asin(temp(3)/radius)
	   DEPTH=RP*RE/SQRT( (RE*SIN(XLAT))**2+(RP*COS(XLAT))**2)-RADIUS
	   XLAT=XLAT*180.0/PI
	   XLON=XLON*180.0/PI
	   DEP=DEPTH
	   LAT=XLAT
	   LON=XLON	   
	ENDIF



	RETURN
	END


        real*8 function dot(v1,v2)
        real*8 v1(3),v2(3)
        dot=v1(1)*v2(1)+v1(2)*v2(2)+v1(3)*v2(3)
        return
        end

