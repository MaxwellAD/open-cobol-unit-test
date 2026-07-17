       IDENTIFICATION DIVISION. 
       PROGRAM-ID. TEST-calculator.
       ENVIRONMENT DIVISION.
       COPY CUTENV.
       DATA DIVISION.
       COPY CUTDATA.
       WORKING-STORAGE SECTION. 

       COPY STORAGE.
       COPY CUTSTOR.

       01 MOCKS.
           05 MOCK-WS-INPUT PIC X(10).
           05 MOCK-WS-NUM-1 PIC 9(9)v99.
           05 MOCK-WS-NUM-2 PIC 9(9)v99.
           05 MOCK-WS-RESULT PIC X(10). 

       PROCEDURE DIVISION.
       TEST-ADD-NUMBERS SECTION.
           *> GIVEN
           MOVE 15 TO WS-NUM-1 
           MOVE 45 TO WS-NUM-2 

           *> WHEN
           PERFORM BA-ADD-NUMBERS          
           
           *> THEN
           MOVE 60.00 TO CUT-ASSERT-TARGET-N 
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST 
       .

       TEST-SUB-NUMBERS-POS SECTION.
           *> A TEST THAT THE SUB NUMBERS WORKS IN NORMAL CONDITIONS
       
           *> GIVEN
           MOVE 100 TO WS-NUM-1 
           MOVE 20 TO WS-NUM-2 
       
           *> WHEN
           PERFORM BB-SUB-NUMBERS
           
           *> THEN
           MOVE 80 TO CUT-ASSERT-TARGET-N 
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM
       
           PERFORM CUT-END-TEST 
       .

       TEST-DIV-NUMBERS-POS-WHOLE SECTION.
           *> TEST THE ABILITY TO DIVIDE NUMBERS WHOLE
       
           *> GIVEN
           MOVE 40 TO WS-NUM-1 
           MOVE 2 TO WS-NUM-2
       
           *> WHEN
           PERFORM BC-DIV-NUMBERS
           
           *> THEN
           MOVE 20 TO CUT-ASSERT-TARGET-N 
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 
       
           PERFORM CUT-END-TEST 
       .

       TEST-DIV-NUMBERS-POS-REMAINDER SECTION.
           *> TEST DIVIDING NUMBERS WHEN THERE'S A REMAINDER
       
           *> GIVEN
           MOVE 10 TO WS-NUM-1 
           MOVE 3 TO WS-NUM-2  
       
           *> WHEN
           PERFORM BC-DIV-NUMBERS 
           
           *> THEN
           MOVE 3.33 TO CUT-ASSERT-TARGET-N  
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM
       
           PERFORM CUT-END-TEST 
       .

       TEST-DIV-BY-ZERO-HANDLE SECTION.
           *> TEST THAT THE CALCULATOR CAN PROTECT 
           *> AGAINST DIVIDE BY ZEROS
       
           *> GIVEN
           MOVE 10 TO WS-NUM-1 
           MOVE 0 TO WS-NUM-2 
       
           *> WHEN
           PERFORM BC-DIV-NUMBERS
           
           *> THEN
           STRING 'BC-DIV-NUMBERS '
                  'FOLLOWED-BY CA-DISPLAY-ERROR'
                  DELIMITED BY SIZE
                  INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE 
    
           PERFORM CUT-END-TEST 
       .

       TEST-MUL-NUMBERS-POS SECTION.
           *> TESTING THAT MULTIPLY NUMBERS WORKS
       
           *> GIVEN
           MOVE 25 TO WS-NUM-1 
           MOVE 5 TO WS-NUM-2 
       
           *> WHEN
           PERFORM BD-MUL-NUMBERS
           
           *> THEN
           MOVE 125 TO CUT-ASSERT-TARGET-N 
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 
       
           PERFORM CUT-END-TEST 
       .

       TEST-SQUARE-NUMBERS-POS SECTION.
           *> TEST THE ABILITY TO SQUARE WHOLE NUMBERS
       
           *> GIVEN
           MOVE 3 TO WS-NUM-1 
       
           *> WHEN
           PERFORM BE-SQUARE-NUMBERS
           
           *> THEN
           MOVE 9 TO CUT-ASSERT-TARGET-N 
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 
       
           PERFORM CUT-END-TEST 
       .
       
       TEST-SQUARE-ROOT-POS SECTION.
           *> TEST CASE FOR SQUARE ROOTING A NUMBER
       
           *> GIVEN
           MOVE 9 TO WS-NUM-1 
       
           *> WHEN
           PERFORM BF-SQUARE-ROOT-NUMBERS
           
           *> THEN
           MOVE 3 TO CUT-ASSERT-TARGET-N 
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 
       
           PERFORM CUT-END-TEST 
       .

       TEST-ACCEPT-INPUT-DUAL SECTION.
           *> TEST THE ABILITY FOR ACCEPT-INPUT TO TAKE THE DUAL INPUT
           *> PATHWAY
       
           *> GIVEN
           MOVE 'ADD' TO MOCK-WS-INPUT 

           *> WHEN
           PERFORM AD-ACCEPT-INPUT
           
           *> THEN
           STRING 'AD-ACCEPT-INPUT '
                  'FOLLOWED-BY AF-ACCEPT-NUM2'
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE 
       
           PERFORM CUT-END-TEST 
       .

       TEST-ACCEPT-INPUT-SINGLE SECTION.
           *> TEST THE AVILITY FOR ACCEPT-INPUT TO TAKE SINGL PATH
       
           *> GIVEN
           MOVE 'SQRE' TO MOCK-WS-INPUT 
           MOVE 5 TO MOCK-WS-NUM-2 
       
           *> WHEN
           PERFORM AD-ACCEPT-INPUT 
           
           *> THEN
           STRING 'AD-ACCEPT-INPUT '
                  'NOT FOLLOWED-BY AF-ACCEPT-NUM2 '
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE
           PERFORM CUT-DEBUG-DISPLAY-TRACE 

           
       
           PERFORM CUT-END-TEST 
       .

       TEST-INPUT-EVAL-ADD SECTION.
           *> TEST THE INPUT EVALUATOR FOR ADD
       
           *> GIVEN
           MOVE 'ADD' TO WS-INPUT 
           MOVE 5 TO WS-NUM-1 
           MOVE 6 TO WS-NUM-2 
       
           *> WHEN
           PERFORM DA-EVALUATE-INPUT
           
           *> THEN
           STRING 'DA-EVALUATE-INPUT '
                  'FOLLOWED-BY BA-ADD-NUMBERS'
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           MOVE 11 TO CUT-ASSERT-TARGET-N 
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST 
       .


       END-TEST-SUITE SECTION.
           PERFORM DISPLAY-COVERAGE 
           PERFORM CUT-END-TEST-SUITE
       .
       
       
       MOCK-BA000-EXIT SECTION.
           DISPLAY 'MOCKED EXIT'
           EXIT SECTION
       .

      *****************************************************************
      * RUNS AT THE TOP OF EACH SECTION IN THE SOURCE CODE
      * ADDS THE SPECIFIED FIELDS TO THE TRACE
      *
      *    USE THE FOLLOWING FORMAT TO REGISTER FIELDS
      *    MOVE 'FIELD-A' TO CUT-TEMP-FIELD-NAME 
      *    MOVE FIELD-A TO CUT-TEMP-FIELD-VALUE
      *    PERFORM CUT-REGISTER-FIELD 
      *
      *    ...
      *    
      *    MOVE 'FIELD-Z' TO CUT-TEMP-FIELD-NAME 
      *    MOVE FIELD-Z TO CUT-TEMP-FIELD-VALUE
      *    PERFORM CUT-REGISTER-FIELD 
      *
      *    EXIT SECTION
      *****************************************************************
       CUT-TRACE-FIELDS SECTION.
               MOVE CUT-RT-SECTION-COUNT TO CUT-TRACE-SECTION-INDEX
               MOVE CUT-RT-SECTION-FIELD-COUNT(CUT-RT-SECTION-COUNT) TO
                                                CUT-TRACE-FIELD-INDEX

           EXIT SECTION
       .

       MOCK-AG-ACCEPT-INPUT SECTION.
           MOVE MOCK-WS-INPUT TO WS-INPUT 
           EXIT PARAGRAPH  
       .

       MOCK-AF-ACCEPT-NUM2 SECTION.
           MOVE MOCK-WS-NUM-2 TO WS-NUM-2  
           EXIT PARAGRAPH 
       .

       MOCK-AE-ACCEPT-NUM1 SECTION.
           MOVE MOCK-WS-NUM-1 TO WS-NUM-1 
           EXIT PARAGRAPH 
       .

      *****************************************************************
      * RUNS BEFORE EACH TEST CASE
      * USE THIS SECTION TO SETUP AND TEARDOWN YOUR TEST DATA AND 
      * RESULTS
      * DO NOT REMOVE THE EXIT SECTION OTHERWISE YOU WILL FALL INTO
      * THE BUSINESS PROGRAM
      *****************************************************************
       BEFORE-EACH SECTION.
           MOVE ZEROS TO WS-RESULT 
           EXIT SECTION  
       .


       COPY PROGRAM.
       COPY CUTPROC.