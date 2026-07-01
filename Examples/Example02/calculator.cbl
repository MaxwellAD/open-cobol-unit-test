       IDENTIFICATION DIVISION. 
       PROGRAM-ID. CALCULATOR.

       DATA DIVISION.
       WORKING-STORAGE SECTION. 

       01 WS-NUM-1 PIC 9(9)v99.
       01 WS-NUM-2 PIC 9(9)v99.
       01 WS-RESULT PIC 9(9)v99.

       PROCEDURE DIVISION.
       AA000-MAINLINE.
           DISPLAY 'IN MAINLINE'
           PERFORM ZA-EXIT
       .

       AB-INIT.
           CONTINUE 
       .


       AC-DISPLAY-MENU.
           CONTINUE 
       .

       AD-ACCEPT-INPUT.
           CONTINUE 
       .

       BA-ADD-NUMBERS.
           COMPUTE WS-RESULT = WS-NUM-1 + WS-NUM-2
       .

       BB-SUB-NUMBERS.
           COMPUTE WS-RESULT = WS-NUM-1 - WS-NUM-2 
       .

       BC-DIV-NUMBERS.
           COMPUTE WS-RESULT  = WS-NUM-1 / WS-NUM-2 
           CONTINUE 
       .

       ZA-EXIT SECTION.
           DISPLAY 'EXITING PROGRAM'
           STOP RUN
       .   
      