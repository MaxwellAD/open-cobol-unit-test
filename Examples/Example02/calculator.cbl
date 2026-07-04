       IDENTIFICATION DIVISION. 
       PROGRAM-ID. CALCULATOR.

       DATA DIVISION.
       WORKING-STORAGE SECTION. 

       01 WS-NUM-1 PIC 9(9)v99.
       01 WS-NUM-2 PIC 9(9)v99.
       01 WS-RESULT PIC Z(8)9.99.
       01 WS-INPUT PIC X(10).
           88  DUAL-INPUT    VALUE "ADD ", "SUB ", "MUL ", "DIV ".
           88  SINGLE-INPUT  VALUE "SQRT", "SQRE".
           

       PROCEDURE DIVISION.
       AA000-MAINLINE.
           PERFORM AB-INIT
           PERFORM AD-ACCEPT-INPUT
           PERFORM DA-EVALUATE-INPUT
           PERFORM DB-DISPLAY-OUTPUT
           STOP RUN
       .

       AB-INIT.
           PERFORM AC-DISPLAY-MENU
           CONTINUE 
       .


       AC-DISPLAY-MENU.
           DISPLAY 'SIMPLE CALCULATOR'
           DISPLAY '================================================'
           DISPLAY 'OPTIONS: '
           DISPLAY 'ADD     -     ADDS 2 NUMBERS'
           DISPLAY 'SUB     -     SUBTRACTS NUMBER 2 FROM NUMBER 1'
           DISPLAY 'MUL     -     MULTIPLIES 2 NUMBERS'
           DISPLAY 'DIV     -     DIVIDES NUMBER 1 BY NUMBER 2'
           DISPLAY 'SQRT    -     SQUARES NUMBER 1'
           DISPLAY 'SQRE    -     SQUARE ROOTS NUMBER 1'
           DISPLAY '================================================'
       .

       AD-ACCEPT-INPUT.
           
           PERFORM AG-ACCEPT-INPUT

           IF DUAL-INPUT 
               PERFORM AF-ACCEPT-NUM2 
           END-IF 
           PERFORM AE-ACCEPT-NUM1

       .

       

       AE-ACCEPT-NUM1.
           DISPLAY 'NUMBER 1: '
           ACCEPT WS-NUM-1 
       .

       AF-ACCEPT-NUM2.
           DISPLAY 'NUMBER 2: '
           ACCEPT WS-NUM-2 
       .

       AG-ACCEPT-INPUT.
           DISPLAY 'ACTION: '
           ACCEPT WS-INPUT 
       .

       BA-ADD-NUMBERS.
           COMPUTE WS-RESULT = WS-NUM-1 + WS-NUM-2
       .

       BB-SUB-NUMBERS.
           COMPUTE WS-RESULT = WS-NUM-1 - WS-NUM-2 
       .

       BC-DIV-NUMBERS.
           IF WS-NUM-2 = 0
               PERFORM CA-DISPLAY-ERROR 
           ELSE
              COMPUTE WS-RESULT  = WS-NUM-1 / WS-NUM-2 
           END-IF 
       .

       BD-MUL-NUMBERS.
           COMPUTE WS-RESULT = WS-NUM-1 * WS-NUM-2 
       .

       BE-SQUARE-NUMBERS.
           COMPUTE WS-RESULT = WS-NUM-1 * WS-NUM-1
       .

       BF-SQUARE-ROOT-NUMBERS.
           COMPUTE WS-RESULT  = FUNCTION SQRT(WS-NUM-1) 
       .

       CA-DISPLAY-ERROR.
           DISPLAY 'CANNOT DIVIDE BY ZERO!' 
       .

       DA-EVALUATE-INPUT.
           EVALUATE WS-INPUT 
           WHEN 'ADD'
              PERFORM BA-ADD-NUMBERS
           WHEN 'SUB'
              PERFORM BB-SUB-NUMBERS
           WHEN 'DIV'
              PERFORM BC-DIV-NUMBERS
           WHEN 'MUL'
              PERFORM BD-MUL-NUMBERS
           WHEN 'SQRE'
              PERFORM BE-SQUARE-NUMBERS
           WHEN 'SQRT'
              PERFORM BF-SQUARE-ROOT-NUMBERS
           END-EVALUATE 

       .

       DB-DISPLAY-OUTPUT.
           DISPLAY 'Result : ' FUNCTION TRIM(WS-RESULT) 
       .

       ZA-EXIT SECTION.
           DISPLAY 'EXITING PROGRAM'
           STOP RUN
       .   
      