C                                                                               
C  Copyright 1990  Regents of the University of California                      
C                                                                               
C                                                                               
C  Author:  Dave Harris                                                         
C                                                                               
C           Lawrence Livermore National Laboratory                              
C           L-205                                                               
C           P.O. Box 808                                                        
C           Livermore, CA  94550                                                
C           USA                                                                 
C                                                                               
C           (415) 423-0617                                                      
C                                                                  DESIGN       
C                                                                               
C  Subroutine to design IIR digital filters from analog prototypes.             
C                                                                               
C  Input Arguments:                                                             
C  ----------------                                                             
C                                                                               
C    IORD                Filter order (10 MAXIMUM)                              
C                                                                               
C    TYPE                Character*2 variable containing filter type            
C                          LOWPASS (LP)                                         
C                          HIGHPASS (HP)                                        
C                          BANDPASS (BP)                                        
C                          BANDREJECT (BR)                                      
C                                                                               
C    APROTO              Character*2 variable designating analog prototype      
C                          Butterworth (BU)                                     
C                          Bessel (BE)                                          

C    FL                  Low-frequency cutoff                                   
C                                                                               
C    FH                  High-frequency cutoff                                  
C                                                                               
C    TS                  Sampling interval (in seconds)                         
C                                                                               
C  Output Arguments:                                                            
C  -----------------                                                            
C                                                                               
C    SN                  Array containing numerator coefficients of             
C                        second-order sections packed head-to-tail.             
C                                                                               
C    SD                  Array containing denominator coefficients              
C                        of second-order sections packed head-to-tail.          
C                                                                               
C    NSECTS              Number of second-order sections.                       
C                                                                               
C                                                                               
      SUBROUTINE DESIGN( IORD, TYPE, APROTO,                  
     &                   FL, FH, TS, SN, SD, NSECTS )                   
C                                                                               
        COMPLEX P(10), Z(10)                                            
        CHARACTER*2 TYPE, APROTO                                        
        CHARACTER*3 STYPE(10)                                           
        REAL*4 SN(1), SD(1)                                             
C                                                                               
C  Analog prototype selection                                                   
C                                                                               
        IF (     APROTO .EQ. 'BU' ) THEN                                
C                                                                               
          CALL BUROOTS( P, STYPE, DCVALUE, NSECTS, IORD )               
C                                                                               
        ELSE IF (    APROTO .EQ. 'BE' ) THEN                            
C                                                                               
          CALL BEROOTS( P, STYPE, DCVALUE, NSECTS, IORD )               
C                                                                               
        END IF                                                          
C                                                                               
C  Analog mapping selection                                                     
C                                                                               
        IF (     TYPE .EQ. 'BP' ) THEN                                  
C                                                                               
          FLW = WARP( FL*TS/2., 2. )                                    
          FHW = WARP( FH*TS/2., 2. )                                    
          CALL LPTBP( P, Z, STYPE, DCVALUE, NSECTS, FLW, FHW, SN, SD )  
C                                                                               
        ELSE IF (   TYPE .EQ. 'BR' ) THEN                               
C                                                                               
          FLW = WARP( FL*TS/2., 2. )                                    
          FHW = WARP( FH*TS/2., 2. )                                    
          CALL LPTBR( P, Z, STYPE, DCVALUE, NSECTS, FLW, FHW, SN, SD )  
C                                                                               
        ELSE IF (    TYPE .EQ. 'LP' ) THEN                              
C                                                                               
          FHW = WARP( FH*TS/2., 2. )                                    
          CALL LP( P, Z, STYPE, DCVALUE, NSECTS, SN, SD )               
          CALL CUTOFFS( SN, SD, NSECTS, FHW )                           
C                                                                               
        ELSE IF (    TYPE .EQ. 'HP' ) THEN                              
C                                                                               
          FLW = WARP( FL*TS/2., 2. )                                    
          CALL LPTHP( P, Z, STYPE, DCVALUE, NSECTS, SN, SD )            
          CALL CUTOFFS( SN, SD, NSECTS, FLW )                           
C                                                                               
        END IF                                                          
C                                                                               
C  Bilinear analog to digital transformation                                    
C                                                                               
        CALL BILIN2( SN, SD, NSECTS )                                   
C                                                                               
      RETURN                                                            
      END                                                               
                                                                        
                                                                        
                                                                        
                                                                        
                                                                        
                                                                        
                                                                        
