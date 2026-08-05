       IDENTIFICATION DIVISION.
       PROGRAM-ID. TESTCUT.
       ENVIRONMENT DIVISION.
       COPY CUTENV.
       COPY FILECTL.
       DATA DIVISION.
       COPY CUTDATA.
       COPY FILESEC.
       WORKING-STORAGE SECTION.
       
       
       *> TEST PROGRAM WORKING STORAGE / LINKAGE
       COPY STORAGE.
       COPY CUTSTOR.

       01 FIXTURES.
           05 FIXTURE-CONSTANT-10 PIC X(10) VALUE '10'.
           05 FIXTURE-CONSTANT-5 PIC X(10) VALUE '5'. 
           05 FIXTURE-CONSTANT-2 PIC X(10) VALUE '2'. 
           05 FIXTURE-CONSTANT-7 PIC X(10) VALUE '7'. 
           05 FIXTURE-CONSTANT-20 PIC X(10) VALUE '20'. 
           05 FIXTURE-TRACE-FIELD-VALUE PIC X(10) VALUE SPACES.
           05 FIXTURE-FIELD-NAME        PIC X(30) VALUE SPACES.
      
       01 COUNTERS.
           05 WS-RT-TRACE-SECTION-COUNTER PIC 9(3) VALUE 1.
           05 WS-RT-TRACE-FIELD-COUNTER PIC 9(3) VALUE 1.
      *> DRIVES THE OVERFLOW FIXTURE: LOOP INDEX + ZERO-PADDED DISPLAY
      *> USED TO BUILD UNIQUE FIELD-NNN NAMES
           05 WS-OVERFLOW-IDX          PIC 9(3) VALUE 1.
           05 WS-OVERFLOW-IDX-D        PIC 9(3) VALUE 0.
      
      
       PROCEDURE DIVISION.
       TEST-INIT-CLEARS-TRACE SECTION.
           
           *> WHEN
           PERFORM DUT-TEST-INIT 

           *> THEN:
           STRING 'DUT-TEST-INIT '
                  'FOLLOWED-BY DUT-CLEAR-TRACE '
                  DELIMITED BY SIZE 
                  INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           PERFORM CUT-END-TEST
       .      

       TEST-ADD-TRACE-CALLS-TRACE SECTION.

           *> WHEN
           PERFORM DUT-ADD-TRACE-SECTION.
           
           *> THEN
           STRING 'DUT-ADD-TRACE-SECTION '
                  'FOLLOWED-BY DUT-TRACE-FIELDS '
                  DELIMITED BY SIZE 
                  INTO CUT-TRACE 
           END-STRING

           PERFORM CUT-ASSERT-TRACE 

           PERFORM CUT-END-TEST 
       .

       
       TEST-ASSERT-TRACE-BASIC-POS SECTION.
           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
           STRING 'AB000-INITIALIZATION '
                  'FOLLOWED-BY '
                  'BA000-MAIN-PROCESSING '
                  'FOLLOWED-BY '
                  'BB000-PROCESS-HEADER-RECORD '
                  DELIMITED BY SIZE 
                  INTO DUT-TRACE
           END-STRING
           PERFORM CUT-CLEAR-TRACE 
           
           *> WHEN

           PERFORM DUT-ASSERT-TRACE 

           *>THEN
           STRING 'DUT-ASSERT-TRACE '
                  'FOLLOWED-BY DUT-FIND-FOLLOWED-BY '
                  'FOLLOWED-BY DUT-FIND-FOLLOWED-BY '
                  DELIMITED BY SIZE 
                  INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE 

           
           PERFORM CUT-END-TEST 

       .

       TEST-ASSERT-TRACE-MISSING-LAST SECTION.
           *> ASSERT TRACE SHOULD FAIL IF THE LAST SECTION IS MISSING

           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
           PERFORM DUT-CLEAR-TRACE 
           STRING 'AB000-INITIALIZATION '
                  'FOLLOWED-BY '
                  'BA000-MAIN-PROCESSING '
                  'FOLLOWED-BY '
                  'BB000-PROCESS-HEADER-RECORD '
                  'FOLLOWED-BY '
                  'ZZ000-END-PROCESSING'
                  DELIMITED BY SIZE 
                  INTO DUT-TRACE
           END-STRING
           PERFORM CUT-CLEAR-TRACE 

           *> WHEN
           PERFORM DUT-ASSERT-TRACE

           *> THEN
           STRING 'DUT-ASSERT-TRACE '
                  'FOLLOWED-BY DUT-FAIL '
                  DELIMITED BY SIZE 
                  INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE 

           PERFORM CUT-END-TEST 
       .
       

       TEST-ASSERT-EQUALS-FAIL SECTION.
           *> BASIC TEST OF DUT-ASSERT-EQUALS
           *> GIVEN
           MOVE 5 TO DUT-ASSERT-TARGET
           MOVE 6 TO DUT-ASSERT-ACTUAL
           PERFORM CUT-CLEAR-TRACE 

           *> WHEN
           PERFORM DUT-ASSERT-EQUALS

           *> THEN
           STRING 'DUT-ASSERT-EQUALS '
                  'FOLLOWED-BY DUT-FAIL '
                  DELIMITED BY SIZE 
                  INTO CUT-TRACE 
           END-STRING

           PERFORM CUT-ASSERT-TRACE 

           PERFORM CUT-END-TEST 
       .

       TEST-ASSERT-EQUALS-BASIC SECTION.
           *> CAN ASSERT EQUALS WORK USING 88 LEVELS
           *> AS FAR AS I KNOW YOU CAN'T GET THE VALUES OF AN 88 LEVEL,
           *> JUST THE TOP LEVEL OWNING ITEM

           *> IF YOU WANT TO COMPARE FIELD ITEMS TO 88 LEVELS YOU'LL
           *> HAVE TO DO IT MANUALLY IN THE TEST CASE

           *> GIVEN
           MOVE 5 TO DUT-ASSERT-TARGET 
           MOVE 5 TO DUT-ASSERT-ACTUAL 

           *> WHEN
           PERFORM DUT-TEST-INIT 
           PERFORM DUT-ASSERT-EQUALS 

           *> THEN
           *> THIS SHOULD PASS, IF IT FAILS THEN SET THE CASE TO FAILED
           IF DUT-TEST-FAIL 
               PERFORM CUT-FAIL 
           END-IF 

           PERFORM CUT-END-TEST 

       .

       TEST-ASSERT-EQUALS-NUM-BASIC SECTION.
           *> TEST THE ASSERT EQUALS NUM WITH A SIMPLE NUMBER
       
           *> GIVEN
           MOVE 5 TO DUT-ASSERT-TARGET-N
           MOVE 5 TO DUT-ASSERT-ACTUAL-N
       
           *> WHEN
           PERFORM DUT-ASSERT-EQUALS-NUM 
           
           *> THEN
           IF NOT DUT-TEST-PASS  
               MOVE 'DUT DIDN''T PASS THE CASE WHEN IT SHOULD HAVE' TO 
               CUT-DISPLAY-FAIL-MSG 
               PERFORM CUT-FAIL 
           END-IF

           STRING 'DUT-ASSERT-EQUALS-NUM '
                  'FOLLOWED-BY DUT-PASS'
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE
       
           PERFORM CUT-END-TEST 
       .

       TEST-ASSERT-EQUALS-NUM-FAIL SECTION.
           *> TEST THAT ASSERT-EQUALS-NUM HANDLES A BASIC FAIL WITH NO
           *> ROUNDING ISSUE
       
           *> GIVEN
           MOVE 5.5 TO DUT-ASSERT-TARGET-N 
           MOVE 5.4 TO DUT-ASSERT-ACTUAL-N
       
           *> WHEN
           PERFORM DUT-ASSERT-EQUALS-NUM
           
           *> THEN
           *> ENSURE WE DON'T TRY TO HANDLE A ROUNDING ERROR
           STRING 'DUT-ASSERT-EQUALS-NUM '
                  'FOLLOWED-BY DUT-ASSERT-EQUALS-NUM-FAIL '
                  'NOT FOLLOWED-BY DUT-HANDLE-DIS-ROUND-ERROR '
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE


           IF NOT DUT-TEST-FAIL 
               MOVE 'DUT DIDN''T FAIL THE CASE WHEN IT SHOULD HAVE'
               TO CUT-DISPLAY-FAIL-MSG 
               PERFORM CUT-FAIL 
           END-IF 

       
           PERFORM CUT-END-TEST 
       .

       TEST-ASSERT-EQUALS-NUM-F-LONG SECTION.
           *> TEST WHAT HAPPENS WHEN THE NUMERIC ASSERTION FAILS A LONG
           *> The "pretty" numeric display out only goes to 2 decimal
           *> places, which isn't helpful if the output looks like this
           *> "Expected 5.55 but got 5.55"
           *> In this case DUT needs to detect that the display out
           *> for either side are identical, and fall back to long 
           *> display
           *> Which in this case should look like
           *> Expected 5.554400000000000000 but got 5.555500000000000000

           *> GIVEN
           MOVE 5.5555 TO DUT-ASSERT-ACTUAL-N 
           MOVE 5.5544 TO DUT-ASSERT-TARGET-N
       
           *> WHEN
           PERFORM DUT-ASSERT-EQUALS-NUM 
           
           *> THEN
           IF NOT DUT-TEST-FAIL  
               MOVE 'DUT DIDN''T FAIL THE CASE WHEN IT SHOULD HAVE' TO 
               CUT-DISPLAY-FAIL-MSG 
               PERFORM CUT-FAIL 
           END-IF 
           *> TODO FOLLOWED-BY DUT-FAIL WITH "'Expected ..."
           *> 'WITH DUT-DISPLAY-ERROR-MSG = '
           *> 'Expected 5.554400000000000000 but got '
           *> '5.555500000000000000"'
           *> Currently this doesn't work because of the spaces
           STRING 'DUT-ASSERT-EQUALS-NUM '
                  'FOLLOWED-BY DUT-ASSERT-EQUALS-NUM-FAIL '
                  'FOLLOWED-BY DUT-HANDLE-DIS-ROUND-ERROR '
                  'FOLLOWED-BY DUT-FAIL '
                  DELIMITED BY SIZE 
                  INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE 
       
           PERFORM CUT-END-TEST 
       .

       TEST-ASSERT-EQUALS-NUM-ERROR SECTION.
           *> TEST CASE FOR ASSERT EQUALS NUM DETECTING INCORRECT USGAE

       
           *> GIVEN
           *> THESE FIELDS ARE INVALID FOR ASSERT-EQUALS-NUM
           MOVE 5 TO DUT-ASSERT-ACTUAL 
           MOVE 5 TO DUT-ASSERT-TARGET 
       
           *> WHEN
           PERFORM DUT-ASSERT-EQUALS-NUM 
           
           *> THEN
           IF NOT DUT-TEST-ERROR
               MOVE 'DUT SHOULD HAVE ERRORED THE CASE BUT IT DIDN''T'
               TO CUT-DISPLAY-FAIL-MSG
           END-IF

           *> ENSURE THAT THE VALUES ARE ZEROED OUT ON ERROR
           MOVE SPACES TO CUT-ASSERT-TARGET 
           MOVE DUT-ASSERT-TARGET TO CUT-ASSERT-ACTUAL 
           PERFORM CUT-ASSERT-EQUALS 

           MOVE SPACES TO CUT-ASSERT-TARGET 
           MOVE DUT-ASSERT-ACTUAL TO CUT-ASSERT-ACTUAL 
           PERFORM CUT-ASSERT-EQUALS 

           PERFORM CUT-END-TEST 
       .

       TEST-ASSERT-EQUALS-ERROR SECTION.
           *> TEST THAT ASSERT-EQUALS CAN HANDLE INCORRECT USEAGE
       
           *> GIVEN
           MOVE 5 TO DUT-ASSERT-TARGET-N 
           MOVE 5 TO DUT-ASSERT-ACTUAL-N 
       
           *> WHEN
           PERFORM DUT-ASSERT-EQUALS 
           
           *> THEN
           STRING 'DUT-ASSERT-EQUALS '
                  'FOLLOWED-BY DUT-ERROR '
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE


           *> ENSURE THAT THE INCORRECT VALUES ARE INDEED RESET
           MOVE 0 TO CUT-ASSERT-TARGET-N
           MOVE DUT-ASSERT-TARGET-N TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM

           MOVE 0 TO CUT-ASSERT-ACTUAL-N
           MOVE DUT-ASSERT-ACTUAL-N TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM

       
           PERFORM CUT-END-TEST 
       .

       TEST-FIND-FOLLOWED-BY-POS SECTION.
           *> BASIC TEST CASE FOR THE FIND-FOLLOWED-BY SECTION TO FIND
           *> SOME TARGET SECTION IN THE MIDDLE OF A TRACE


           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
           MOVE 'BC000-PROCESS-DETAIL-RECORD' TO DUT-TEMP-SECTION-NAME 
           
           *> WHEN
           PERFORM DUT-FIND-FOLLOWED-BY 

           IF DUT-TEST-FAIL 
              MOVE 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED' TO 
              CUT-DISPLAY-ERROR-MSG  
              PERFORM CUT-FAIL 
           END-IF 
           

           PERFORM CUT-END-TEST 

       .

       TEST-FIND-FOLLOWED-BY-NEG SECTION.

           *> BASIC TEST CASE FOR FIND-FOLLOWED-BY WHEN SECTION IS NOT 
           *> THERE DUT SHOULD FAIL THE TEST CASE

           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
           MOVE 'DD000-A-FAKE-SECTION' TO DUT-TEMP-SECTION-NAME 

           *> WHEN
           PERFORM DUT-FIND-FOLLOWED-BY 

           *> THEN
           IF DUT-TEST-PASS 
               MOVE 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED' TO 
               CUT-DISPLAY-ERROR-MSG
               PERFORM CUT-FAIL 
           END-IF 

           PERFORM CUT-END-TEST 
       .

       TEST-FIND-DIR-FOLLOWED-BY-POS SECTION.
           *> BASIC TEST CASE FOR FIND-DIRECTLY-FOLLOWED-BY WHEN SECTION
           *> IS DIRECTLY FOLLWOED-BY

           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
           SET DUT-TEST-PASS TO TRUE
           MOVE 'BC000-PROCESS-DETAIL-RECORD' TO DUT-TEMP-SECTION-NAME 
           MOVE 3 TO DUT-TRACE-SECTION-INDEX 
           
           *> WHEN
           PERFORM DUT-FIND-DIRECTLY-FOLLOWED-BY 

           *> THEN

           *> DUT SHOULD PASS THE CASE
           IF DUT-TEST-FAIL 
               MOVE 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
           END-IF 

           PERFORM CUT-END-TEST 

       .

       TEST-FIND-DIR-FOLLOWED-BY-NEG SECTION.
           *> BASIC TEST CASE FOR FIND-DIRECTLY-FOLLOWED-BY WHEN SECTION
           *> IS *NOT* DIRECTLY FOLLOWED-BY. I.e a section in the middle


           *>GIVEN 
           PERFORM FIXTURE-BASIC-ADD-EXEC 
           SET DUT-TEST-PASS TO TRUE 
           *> BC000 is at pos 4, FIND-DIRECTLY-FOLLOWED should check pos
           *> 3, see that BC000 is not there and fail the case
           MOVE 'BC000-PROCESS-DETAIL-RECORD' TO DUT-TEMP-SECTION-NAME 
           MOVE 2 TO DUT-TRACE-SECTION-INDEX 


           *> WHEN
           PERFORM DUT-FIND-DIRECTLY-FOLLOWED-BY 


           *> THEN

           *> DUT SHOULD NOT PASS THE CASE
           IF DUT-TEST-PASS 
               MOVE 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
               PERFORM DUT-DEBUG-DISPLAY-TRACE 
               DISPLAY DUT-RT-SECTION-NAME(DUT-TRACE-SECTION-INDEX)
           END-IF 
           
           PERFORM CUT-END-TEST 
       .

       TEST-ASSERT-TRACE-DIR-FB-POS SECTION.
           *> BASIC TEST FOR ASSERTING DIRECTLY FOLLOWED BY IN AN
           *> EXECUTION TRACE

           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
           SET DUT-TEST-PASS TO TRUE 
           STRING 'BA000-MAIN-PROCESSING '
                  'DIRECTLY-FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
                  'FOLLOWED-BY BZ000-PROCESS-TRAILER-RECORD '
                  DELIMITED BY SIZE 
                  INTO DUT-TRACE 
           END-STRING
           
           *> WHEN
           PERFORM DUT-ASSERT-TRACE 

           *> THEN

           *> DUT SHOULD NOT FAIL THIS CASE
           IF DUT-TEST-FAIL 
              MOVE 'DUT FAILED THIS CASE WHEN IT SHOULD HAVE PASSED' TO 
              CUT-DISPLAY-ERROR-MSG 
              PERFORM CUT-FAIL 
           END-IF 

           PERFORM CUT-END-TEST 
       .

       TEST-ASSERT-TRACE-DIR-FB-NEG SECTION.
           *> BASIC TEST FOR ASSERTING DIRECTLY FOLLOWED BY IN AN
           *> EXECUTION TRACE WHERE THE FIELD IS NOT DIRECTLY FOLLOWED 
           *> BY

           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
           SET DUT-TEST-PASS TO TRUE 
           STRING 'BA000-MAIN-PROCESSING '
                  'DIRECTLY-FOLLOWED-BY BC000-PROCESS-DETAIL-RECORD '
                  'FOLLOWED-BY BZ000-PROCESS-TRAILER-RECORD '
                  DELIMITED BY SIZE 
                  INTO DUT-TRACE 
           END-STRING

           *> WHEN
           PERFORM DUT-ASSERT-TRACE 

           *> THEN
           IF DUT-TEST-PASS 
               MOVE 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
           END-IF 

           PERFORM CUT-END-TEST 
          

       .

       *> GOOD TIME TO IMPLEMENT "TIMES" KEYWORD
       TEST-HANDLE-VERBS-CORRECT-PATH SECTION.
           *> TEST TO ENSURE HANDLE-VERBS TAKES THE CORRECT PATHS
           *> THIS IS GONNA BE A BIG ASSERT FOR AN E2E STYLE EXECUTION
           *> This might be overkill

           *> GIVEN
           PERFORM DUT-CLEAR-TRACE 
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
           SET DUT-TEST-PASS TO TRUE 
           STRING 'AB000-INITIALIZATION '
                  'FOLLOWED-BY BA000-MAIN-PROCESSING '
                  'WITH '
                     'WS-NUMBER = 7 '
                  'END-WITH '
                  'DIRECTLY-FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
                  'WITH '
                     'WS-NUMBER = 10 ' *> SHOULD FAIL
                  'END-WITH '
                  'FOLLOWED-BY BZ000-PROCESS-TRAILER-RECORD '
                  DELIMITED BY SIZE 
                  INTO DUT-TRACE 
           END-STRING
           PERFORM CUT-CLEAR-TRACE 
           *> WHEN
           PERFORM DUT-ASSERT-TRACE 
           

           *> THEN

           *> DUT SHOULD TAKE THE FOLLOWING PATH
           STRING 'DUT-ASSERT-TRACE ' *> ENTRY POINT
                  *> REGISTER EACH COMMAND
                  'FOLLOWED-BY DUT-ASSERT-TRACE-REGSTR-WORDS '
                  *> FIRST SECTION
                  'FOLLOWED-BY DUT-FIND-FOLLOWED-BY ' 
                  *> HANDLE FIRST VERB (FOLLOWED-BY)
                  'FOLLOWED-BY DUT-ASSERT-TRACE-HANDLE-VERBS '
                  'FOLLOWED-BY DUT-FIND-FOLLOWED-BY '
                  'FOLLOWED-BY DUT-ASSERT-TRACE-HANDLE-WITH '
                  'FOLLOWED-BY DUT-FIND-WITH-IN-TRACE '
                  'FOLLOWED-BY DUT-EVALUATE-OPERATION ' 
                  *> EVALUATE OPERATION SUCCESSFUL
                  *> MOVING ONTO NEXT VERB
                  'FOLLOWED-BY DUT-FIND-DIRECTLY-FOLLOWED-BY '
                  *>'FOLLOWED-BY DUT-ASSERT-TRACE-HANDLE-VERBS '
                  'FOLLOWED-BY DUT-FIND-DIRECTLY-FOLLOWED-BY '
                  *> BB000-PROCESS-HEADER-RECORD
                  'FOLLOWED-BY DUT-ASSERT-TRACE-HANDLE-VERBS '
                  *> WITH WS-NUMBER = 10
                  'FOLLOWED-BY DUT-ASSERT-TRACE-HANDLE-WITH '
                  'FOLLOWED-BY DUT-FIND-WITH-IN-TRACE '
                  *> WS-NUMBER IS NOT 10
                  'FOLLOWED-BY DUT-EVALUATE-OPERATION '
                  'FOLLOWED-BY DUT-FAIL '
                  DELIMITED BY SIZE 
                  INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE 
           
           
           PERFORM CUT-END-TEST 
       .


       TEST-EVALUATE-OP-EQ-NEG SECTION.
           *> TEST FOR THE DUT-EVALUATE-OPERATION
           *> HAPPENS IN THE WITH BRANCH OF EXPECTED-EXEC
           
           *> GIVEN
           MOVE 5 TO DUT-TEMP-FIELD-VALUE 
           MOVE 10 TO DUT-TEMP-FIELD-EXPECTED 
           MOVE '=' TO DUT-TEMP-FIELD-OPERATOR 
           SET DUT-TEST-PASS TO TRUE

           *> WHEN
           PERFORM DUT-EVALUATE-OPERATION 
           
           *> THEN
           
           IF DUT-TEST-PASS
               MOVE 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
           END-IF 
           
           PERFORM CUT-END-TEST 
       .

       TEST-EVALUATE-OP-NEQ-NEG SECTION.
           *> TEST FOR THE DUT-EVALUATE-OPERATION
           *> HAPPENS IN THE WITH BRANCH OF EXPECTED-EXEC
           
           *> GIVEN
           MOVE 10 TO DUT-TEMP-FIELD-VALUE 
           MOVE 10 TO DUT-TEMP-FIELD-EXPECTED 
           MOVE '!=' TO DUT-TEMP-FIELD-OPERATOR 
           SET DUT-TEST-PASS TO TRUE

           *> WHEN
           PERFORM DUT-EVALUATE-OPERATION 
           
           *> THEN
           
           IF DUT-TEST-PASS
               MOVE 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
           END-IF 
           
           PERFORM CUT-END-TEST 
       .

       TEST-FIND-WITH-IN-TRACE-POS SECTION.
           *> TEST THE ABILITY TO FIND A WITH IN THE SECTION TRACE
           
           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
           SET DUT-TEST-PASS TO TRUE 
           STRING 'BB000-PROCESS-HEADER-RECORD '
                  'DIRECTLY-FOLLOWED-BY BC000-PROCESS-DETAIL-RECORD '
                  'WITH '
                     'WS-NUMBER = 10 '
                  'END-WITH '
                  'FOLLOWED-BY BZ000-PROCESS-TRAILER-RECORD '
                  DELIMITED BY SIZE 
                  INTO DUT-TRACE 
           END-STRING

           *> WHEN
           PERFORM DUT-ASSERT-TRACE 


           *> THEN

           *> THE CASE SHOULD PASS AS WS-NUMBER WAS REGISTERED AS 10
           IF DUT-TEST-FAIL 
              MOVE 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED' TO 
              CUT-DISPLAY-ERROR-MSG 
              PERFORM CUT-FAIL 
           END-IF 

           PERFORM CUT-END-TEST 
           
       .

       TEST-FIND-WITH-IN-TRACE-NEG SECTION.
           *> TEST THE ABILITY TO FIND A WITH IN THE SECTION TRACE
           
           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
           SET DUT-TEST-PASS TO TRUE 
           STRING 'BA000-MAIN-PROCESSING '
                  'DIRECTLY-FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
                  'WITH '
                     'WS-NUMBER = 10 '
                  'END-WITH '
                  'FOLLOWED-BY BZ000-PROCESS-TRAILER-RECORD '
                  DELIMITED BY SIZE 
                  INTO DUT-TRACE 
           END-STRING

           *> WHEN
           PERFORM DUT-ASSERT-TRACE 

           *> THEN

           *> THE CASE SHOULD FAIL AS WS-NUMBER WAS REGISTERED AS 2
           IF DUT-TEST-PASS 
              MOVE 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED' TO 
              CUT-DISPLAY-ERROR-MSG 
              PERFORM CUT-FAIL 
           END-IF 

           PERFORM CUT-END-TEST 
           
       .

       TEST-ASSERT-EQ-NUM-HANLE SECTION.
           *> TEST THAT ASSERT-EQUALS CAN HANDLE INCORRECT USAGE
           *> WHEN THE USER MEANT TO USE ASSERT-EQUALS-NUM
       
           *> GIVEN
           MOVE 1 TO DUT-ASSERT-TARGET-N 
       
           *> WHEN
           PERFORM DUT-ASSERT-EQUALS
           
           *> THEN
           STRING 'DUT-ASSERT-EQUALS '
               'FOLLOWED-BY DUT-ERROR'
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING

           *> ENSURE THAT THE FIELD IS RESET
           MOVE 0 TO CUT-ASSERT-TARGET-N 
           MOVE DUT-ASSERT-TARGET-N TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 
       
           PERFORM CUT-END-TEST 
       .

       TEST-FIND-WITH-IN-TRACE-FATAL SECTION.
           *> Verify that if a field is unable to be found a fatel error
           *> is logged
           
           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
           SET DUT-TEST-PASS TO TRUE 
           STRING 'BA000-MAIN-PROCESSING '
                  'DIRECTLY-FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
                  'WITH '
                     'DOESNT-EXIST = 10 '
                  'END-WITH '
                  'FOLLOWED-BY BZ000-PROCESS-TRAILER-RECORD '
                  DELIMITED BY SIZE 
                  INTO DUT-TRACE 
           END-STRING

           *> WHEN
           PERFORM  DUT-ASSERT-TRACE

           *> THEN

           *> THE CASE SHOULD FAIL AS WS-NUMBER WAS REGISTERED AS 2
           IF DUT-TEST-PASS 
              MOVE 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED' TO 
              CUT-DISPLAY-ERROR-MSG 
              PERFORM CUT-FAIL 
           END-IF 

           PERFORM CUT-END-TEST 
       
       .



       TEST-CLEAR-TRACE-CLEARS-TRACE SECTION.
           *> TEST TO ENSURE CLEARING THE TRACE CLEARS THE WHOLE TRACE
           *> SECTION NAMES AND WITHS

           *> DUT-RT-TRACE <- TOP LEVEL ITEM (OCCURS X TIMES)
           *>     DUT-RT-SECTION-NAME <- SHOULD BE SPACES
           *>     DUT-RT-SECTION-FIELD-COUNT <- SHOULD BE 1
           *>     DUT-RT-SECTION-FIELDS <- CONTAINS 2 ITEMS, BOTH SHOULD
           *>                              BE SPACES
           
           *> GIVEN
           PERFORM DUT-CLEAR-TRACE 
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 

           *> WHEN
           PERFORM DUT-CLEAR-TRACE 

           *> THEN

           *> FOR EACH SECTION, FOR EACH FIELD, CHECK FOR SPACES
           PERFORM VARYING WS-RT-TRACE-SECTION-COUNTER FROM 1 BY 1
                       UNTIL WS-RT-TRACE-SECTION-COUNTER > 
                       100
                IF DUT-RT-SECTION-NAME(
                WS-RT-TRACE-SECTION-COUNTER) NOT = SPACES
                   STRING 'FOUND SECTION '
                          DUT-RT-SECTION-NAME(
                          WS-RT-TRACE-SECTION-COUNTER)
                          'AT INDEX ' 
                          WS-RT-TRACE-SECTION-COUNTER
                          ' EXPECTED SPACES' 
                          DELIMITED BY SIZE 
                          INTO CUT-DISPLAY-ERROR-MSG 
                   END-STRING
                   PERFORM CUT-FAIL 
               END-IF
                   PERFORM VARYING WS-RT-TRACE-FIELD-COUNTER FROM 1 BY 1
                           UNTIL WS-RT-TRACE-FIELD-COUNTER >
                           100
                       IF DUT-RT-SECTION-FIELDS(
                        WS-RT-TRACE-SECTION-COUNTER
                        WS-RT-TRACE-FIELD-COUNTER) NOT = SPACES
                           STRING 'FOUND FIELD '
                               FUNCTION TRIM(DUT-RT-SECTION-FIELDS(
                               WS-RT-TRACE-SECTION-COUNTER
                               WS-RT-TRACE-FIELD-COUNTER))
                               ' AT SECTION INDEX: '
                              FUNCTION TRIM(WS-RT-TRACE-SECTION-COUNTER) 
                               ' AT FIELD INDEX: '
                              FUNCTION TRIM(WS-RT-TRACE-FIELD-COUNTER)
                               ' EXPECTED SPACES'
                               DELIMITED BY SIZE 
                               INTO CUT-DISPLAY-ERROR-MSG 
                           END-STRING
                           PERFORM CUT-FAIL 
                   END-PERFORM
           END-PERFORM
           
           PERFORM CUT-END-TEST 
       .

       TEST-ADD-TRACE-ADDS-TRACE SECTION.
           *> BASIC TEST, ENSURRING THE SECTION TRACE IS STILL BEING
           *> ADDED

           *> GIVEN
           PERFORM DUT-CLEAR-TRACE 
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 

           *> WHEN (n/a)

           *> THEN
           IF DUT-RT-SECTION-NAME(3) NOT = 'BB000-PROCESS-HEADER-RECORD'
               MOVE 'COULD NOT FIND EXPECTED FIELD AT INDEX' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
           END-IF

           IF(DUT-RT-SECTION-FIELD-NAME(3,1) NOT = 'WS-NUMBER')
               MOVE 'COULD NOT FIND EXPECTED FIELD NAME AT INDEX' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
           END-IF 

           IF(DUT-RT-SECTION-FIELD-VALUE(3,1) NOT = 2)
               MOVE 'VOULD NOT FIND EXPECTED FIELD VALUE' TO 
               CUT-DISPLAY-ERROR 
               PERFORM CUT-FAIL 
           END-IF 
           PERFORM CUT-END-TEST 

       .

       TEST-EVALUATE-OP-EQ-POS SECTION.
           *> TEST FOR DUT-ASSERT-EXPECT <- not sure if this is really
           *>                               needed
           *> TEST FOR THE DUT-EVALUATE-OPERATION
           *> HAPPENS IN THE WITH BRANCH OF EXPECTED-EXEC
           
           *> GIVEN
           MOVE 5 TO DUT-TEMP-FIELD-VALUE 
           MOVE 5 TO DUT-TEMP-FIELD-EXPECTED 
           MOVE '=' TO DUT-TEMP-FIELD-OPERATOR 
           SET DUT-TEST-PASS TO TRUE

           *> WHEN
           PERFORM DUT-EVALUATE-OPERATION 
           
           *> THEN
           
           IF DUT-TEST-FAIL 
               MOVE 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
           END-IF 
           
           PERFORM CUT-END-TEST 
       .

       TEST-EVALUATE-OP-NEQ-POS SECTION.
           *> TEST FOR THE DUT-EVALUATE-OPERATION
           *> HAPPENS IN THE WITH BRANCH OF EXPECTED-EXEC
           
           *> GIVEN
           MOVE 5 TO DUT-TEMP-FIELD-VALUE 
           MOVE 10 TO DUT-TEMP-FIELD-EXPECTED 
           MOVE '!=' TO DUT-TEMP-FIELD-OPERATOR 
           SET DUT-TEST-PASS TO TRUE

           *> WHEN
           PERFORM DUT-EVALUATE-OPERATION 
           
           *> THEN
           
           IF DUT-TEST-FAIL
               MOVE 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
           END-IF 
           
           PERFORM CUT-END-TEST 
       .
       
       TEST-END-TEST-PASS SECTION.
           *> TEST THAT THE END-TEST PROCESS CAN TAKE THE RIGHT PATH
       
           *> GIVEN
           SET DUT-TEST-PASS TO TRUE
           MOVE 0 TO DUT-TEST-PASS-COUNT 
       
           *> WHEN
           PERFORM DUT-END-TEST 
           
           *> THEN
           STRING 'DUT-END-TEST '
                  'FOLLOWED-BY DUT-WRITE-UT-RECORD '
                  'FOLLOWED-BY DUT-PASS '
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           MOVE 1 TO CUT-ASSERT-TARGET-N 
           MOVE DUT-TEST-PASS-COUNT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 
       
           PERFORM CUT-END-TEST 
       .

       TEST-END-TEST-FAIL SECTION.
           *> TEST THAT END-TEST CAN TAKE THE CORRECT PATH IN A TEST
           *> FAIL
       
           *> GIVEN
           SET DUT-TEST-FAIL TO TRUE 
           MOVE 0 TO DUT-TEST-FAIL-COUNT 
       
           *> WHEN
           PERFORM DUT-END-TEST 
           
           *> THEN
           STRING 'DUT-END-TEST '
                  'FOLLOWED-BY DUT-FAIL'
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           MOVE 1 TO CUT-ASSERT-TARGET-N 
           MOVE DUT-TEST-FAIL-COUNT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 
       
           PERFORM CUT-END-TEST 
       .

       
       TEST-END-TEST-ERROR SECTION.
           *> TEST THAT THE ERROR PATHWAY IS TAKEN ON ERROR RESULT
       
           *> GIVEN
           SET DUT-TEST-ERROR TO TRUE 
           MOVE 0 TO DUT-TEST-ERROR-COUNT 

           *> WHEN
           PERFORM DUT-END-TEST 
           
           *> THEN
           STRING 'DUT-END-TEST '
                  'FOLLOWED-BY DUT-ERROR'
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           MOVE 1 TO CUT-ASSERT-TARGET-N 
           MOVE DUT-TEST-ERROR-COUNT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 
       
           PERFORM CUT-END-TEST 
       .

       TEST-DISPLAY-TRACE-SHOWS-ALL SECTION.
           *> THE DEBUG TABLE MUST VISIT EVERY SECTION: DETECT ALL
           *> COLUMNS AND SIZE THE SECTION COLUMN TO THE LONGEST NAME

           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD

           *> WHEN
           PERFORM DUT-DEBUG-DISPLAY-TRACE

           *> THEN
           *> ALL 5 SECTIONS REGISTER ONLY WS-NUMBER -> 1 UNIQUE COLUMN
           MOVE 1 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-UNIQUE-FIELD-COUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           *> SECTION COLUMN = LONGEST NAME
           *> (BZ000-PROCESS-TRAILER-RECORD = 28), PROVING EVERY
           *> SECTION WAS SCANNED
           MOVE 28 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-SECTION-NAME-WIDTH TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM


           PERFORM CUT-END-TEST
       .

       TEST-DEBUG-MULTI-COLUMNS SECTION.
           *> WITH A MIXED-FIELD TRACE THE TABLE MUST DETECT EACH DISTINCT
           *> FIELD AS A COLUMN AND SIZE EACH COLUMN CORRECTLY

           *> GIVEN
           PERFORM FIXTURE-ADD-MULTI-FIELD

           *> WHEN
           PERFORM DUT-DEBUG-DISPLAY-TRACE

           *> THEN
           *> THREE DISTINCT FIELD NAMES -> THREE COLUMNS
           MOVE 3 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-UNIQUE-FIELD-COUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           *> COL 1 = WS-AGE: NAME (6) IS WIDER THAN ITS VALUES -> 6
           MOVE 6 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-FIELD-WIDTH(1) TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           *> COL 2 = WS-NAME: VALUE 'JOHN SMITH' (10) IS WIDER THAN THE
           *> 7-CHAR NAME -> 10, PROVING VALUE LENGTH DRIVES WIDTH
           MOVE 10 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-FIELD-WIDTH(2) TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           *> SECTION COLUMN = LONGEST NAME (PROCESS-RECORD = 14)
           MOVE 14 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-SECTION-NAME-WIDTH TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
       .

       TEST-DEBUG-FIND-PRESENT-ABSENT SECTION.
           *> FIND-FIELD-VALUE RETURNS A SECTION'S VALUE FOR A COLUMN, OR
           *> SPACES WHERE THAT SECTION NEVER REGISTERED THE FIELD (BLANK
           *> CELL). COL 2 = WS-NAME, SECTION 2 = READ-FILE, SECTION 1 =
           *> MAINLINE (WHICH HAS NO WS-NAME)

           *> GIVEN
           PERFORM FIXTURE-ADD-MULTI-FIELD
           PERFORM DUT-DEBUG-DISPLAY-TRACE

           *> WHEN / THEN - PRESENT: READ-FILE HAS WS-NAME = JOHN SMITH
           MOVE 2 TO DUT-DEBUG-SECTION-IDX
           MOVE 2 TO DUT-DEBUG-COLUMN-IDX
           PERFORM DUT-DEBUG-FIND-FIELD-VALUE
           MOVE 'JOHN SMITH' TO CUT-ASSERT-TARGET
           MOVE DUT-TEMP-FIELD-VALUE TO CUT-ASSERT-ACTUAL
           PERFORM CUT-ASSERT-EQUALS

           *> WHEN / THEN - ABSENT: MAINLINE NEVER REGISTERED WS-NAME
           MOVE 1 TO DUT-DEBUG-SECTION-IDX
           MOVE 2 TO DUT-DEBUG-COLUMN-IDX
           PERFORM DUT-DEBUG-FIND-FIELD-VALUE
           MOVE SPACES TO CUT-ASSERT-TARGET
           MOVE DUT-TEMP-FIELD-VALUE TO CUT-ASSERT-ACTUAL
           PERFORM CUT-ASSERT-EQUALS

           PERFORM CUT-END-TEST
       .

       TEST-DEBUG-BLANK-VALUE-WIDTH SECTION.
           *> A FIELD REGISTERED WITH A NON-BLANK NAME BUT A BLANK VALUE
           *> MUST NOT INFLATE (OR SHRINK) ITS COLUMN: THE WIDTH STAYS AT
           *> THE NAME LENGTH. EXERCISES THE SPACES BRANCH IN
           *> DUT-DEBUG-UPDATE-FIELD-WIDTH

           *> GIVEN
           PERFORM FIXTURE-ADD-BLANK-VALUE

           *> WHEN
           PERFORM DUT-DEBUG-DISPLAY-TRACE

           *> THEN
           *> ONE FIELD -> ONE COLUMN
           MOVE 1 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-UNIQUE-FIELD-COUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           *> WIDTH = LEN('WS-NAME') = 7; THE BLANK VALUE ADDED NOTHING
           MOVE 7 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-FIELD-WIDTH(1) TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
       .

       TEST-DEBUG-EMIT-EMPTY-ROW SECTION.
           *> DEFENSIVE GUARD: EMIT-ROW CALLED WITH NOTHING STRINGED INTO
           *> THE BUFFER (ROW-POINTER STILL AT ITS DEFAULT 1) MUST CLAMP
           *> THE REFERENCE-MOD LENGTH TO 1 RATHER THAN 0, WHICH WOULD BE
           *> AN INVALID (1:0) DISPLAY AND CRASH UNDER BOUNDS CHECKING.
           *> NO PUBLIC CALLER REACHES THIS STATE, SO WE DRIVE EMIT-ROW
           *> DIRECTLY

           *> GIVEN - EMPTY ROW, POINTER AT COLUMN 1
           MOVE SPACES TO DUT-DEBUG-TRACE-ROW
           MOVE 1 TO DUT-DEBUG-ROW-POINTER

           *> WHEN
           PERFORM DUT-DEBUG-EMIT-ROW

           *> THEN - LENGTH CLAMPED TO 1, NOT 0
           MOVE 1 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-ROW-LENGTH TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
       .

       TEST-DEBUG-COLUMN-OVERFLOW SECTION.
           *> THE OVERFLOW GUARD IN DUT-DEBUG-REGISTER-FIELD MUST CAP THE
           *> COLUMN COUNT AT 100 AND RAISE THE TRUNCATION FLAG RATHER
           *> THAN WRITE PAST THE OCCURS-100 COLUMN TABLE.
           *>
           *> WHITE-BOX: WE DRIVE REGISTER-FIELD DIRECTLY WITH THE TABLE
           *> ALREADY FULL. RENDERING A REAL 100-COLUMN TABLE IS NOT AN
           *> OPTION - THE HARNESS INSTRUMENTS EVERY SECTION WITH A TRACE
           *> BREADCRUMB, AND RENDERING PERFORMS HELPERS >100 TIMES, WHICH
           *> WOULD OVERFLOW THE FRAMEWORK'S OWN 100-SLOT EXECUTION TRACE

           *> GIVEN - A TRACE HOLDING ONE NEW, UNTRACKED FIELD
           PERFORM DUT-CLEAR-TRACE
           MOVE 'NEW-FIELD' TO DUT-RT-SECTION-FIELD-NAME(1 1)
           MOVE 1 TO DUT-DEBUG-SECTION-IDX
           MOVE 1 TO DUT-DEBUG-FIELD-IDX

           *> AND - THE COLUMN TABLE IS ALREADY FULL WITH 100 DISTINCT
           *> COLUMNS THAT WON'T MATCH 'NEW-FIELD'
           SET DUT-DEBUG-COLS-OK TO TRUE
           MOVE 100 TO DUT-DEBUG-UNIQUE-FIELD-COUNT
           PERFORM VARYING WS-OVERFLOW-IDX FROM 1 BY 1 UNTIL
               WS-OVERFLOW-IDX > 100
               MOVE WS-OVERFLOW-IDX TO WS-OVERFLOW-IDX-D
               MOVE SPACES TO FIXTURE-FIELD-NAME
               STRING 'FILLER-' WS-OVERFLOW-IDX-D DELIMITED BY SIZE
                   INTO FIXTURE-FIELD-NAME
               MOVE FIXTURE-FIELD-NAME TO
                   DUT-DEBUG-FIELD-NAME(WS-OVERFLOW-IDX)
           END-PERFORM

           *> WHEN - REGISTERING THE 101ST UNIQUE FIELD
           PERFORM DUT-DEBUG-REGISTER-FIELD

           *> THEN - COUNT STAYS CAPPED AT THE TABLE CAPACITY
           MOVE 100 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-UNIQUE-FIELD-COUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           *> AND - THE TRUNCATION FLAG IS RAISED
           MOVE 'Y' TO CUT-ASSERT-TARGET
           MOVE DUT-DEBUG-COLS-TRUNC-FLAG TO CUT-ASSERT-ACTUAL
           PERFORM CUT-ASSERT-EQUALS

           PERFORM CUT-END-TEST
       .

       TEST-DEBUG-EMPTY-TRACE SECTION.
           *> DEGENERATE CASE: A CLEARED TRACE (NO SECTIONS) MUST RENDER
           *> WITHOUT CRASHING - ZERO FIELD COLUMNS, AND THE SECTION
           *> COLUMN FLOORED AT THE 'SECTION-NAME' HEADER WIDTH

           *> GIVEN - AN EMPTY TRACE
           PERFORM DUT-CLEAR-TRACE

           *> WHEN
           PERFORM DUT-DEBUG-DISPLAY-TRACE

           *> THEN - NO FIELD COLUMNS DETECTED
           MOVE 0 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-UNIQUE-FIELD-COUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           *> AND - SECTION COLUMN FLOORED AT LEN('SECTION-NAME') = 12
           MOVE 12 TO CUT-ASSERT-TARGET-N
           MOVE DUT-DEBUG-SECTION-NAME-WIDTH TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
       .

       TEST-END-TEST-SUITE-ERROR SECTION.
           *> TEST THE DUT-END-TEST-SUITE WHEN THERE IS AN ERROE VALUE
           *> ERROR VALUES SHOULD ONLY BE WRITTEN IF GREATER THAN 0
       
           *> GIVEN
           MOVE 1 TO DUT-TEST-ERROR-COUNT  
           MOVE 0 TO DUT-TEST-ERROR-COUNT-DISPLAY 
       
           *> WHEN
           PERFORM DUT-END-TEST-SUITE
           
           *> THEN
           *> ONLY WHEN THERE'S AN ERROR DOES THE VALUE GET MOVED
           *> TO THE DISPLAY FIELD
           MOVE DUT-TEST-ERROR-COUNT TO CUT-ASSERT-TARGET-N            
           MOVE DUT-TEST-ERROR-COUNT-DISPLAY TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM 

       
           PERFORM CUT-END-TEST 
       .
       

       TEST-END-TEST-SUITE-NOERR SECTION.
           *> TEST WHEN END-TEST-SUITE RUNS AND THERE IS NO ERROR VALUE

       
           *> GIVEN
           MOVE 0 TO DUT-TEST-ERROR-COUNT 
           MOVE 5 TO DUT-TEST-ERROR-COUNT-DISPLAY
       
           *> WHEN
           PERFORM DUT-END-TEST-SUITE 
           
           *> THEN
           *> AS TEST-ERROR-COUNT IS 0 THEN THE DISPLAY FIELD SHOULD
           *> NOT BE UPDATED
           MOVE 5 TO CUT-ASSERT-TARGET-N 
           MOVE DUT-TEST-ERROR-COUNT-DISPLAY TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM 
       

           PERFORM CUT-END-TEST 
       .

       TEST-DUT-SKIP SECTION.
           *> TEST THAT DUT-SKIP INCREMENTS THE SKIP COUNTER AND LOGS
           *> ITS NAME
       
           *> GIVEN
           MOVE 0 TO DUT-TEST-SKIP-COUNT 
       
           *> WHEN
           PERFORM DUT-SKIP 
           
           *> THEN
           MOVE 1 TO CUT-ASSERT-TARGET-N 
           MOVE DUT-TEST-SKIP-COUNT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 

           STRING 'DUT-SKIP '
                  'FOLLOWED-BY DUT-DISPLAY-TEST-CASE-NAME'
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE
       
           PERFORM CUT-END-TEST 
       .

       TEST-REGISTER-FIELD-REGISTERS SECTION.
           *> TEST THAT REGISTER FIELD REGISTERS A FIELD AND INCREMENTS
           *> COUNTER PROPERLY
       
           *> GIVEN
           *> AUTOMATED SETUP
           *> 1 registered section
           MOVE 1 TO DUT-RT-SECTION-COUNT
           *> 2 fields per section 
           MOVE 2 TO DUT-RT-SECTION-FIELD-COUNT(DUT-RT-SECTION-COUNT)



           *> WHEN
           *> WHAT IS ACTUALLY CODED IN THE CUT-TRACE-FIELDS
           MOVE 'WS-EXAMPLE' TO DUT-TEMP-FIELD-NAME
           MOVE 1000 TO DUT-TEMP-FIELD-VALUE 
           PERFORM DUT-REGISTER-FIELD 
           
           *> THEN
           *> WE NEED 3 FIELDS TO BE REGISTERED AND THE INDEX TO BE 3

           MOVE 3 TO CUT-ASSERT-TARGET-N 
           MOVE DUT-RT-SECTION-FIELD-COUNT(DUT-TRACE-SECTION-INDEX) TO 
           CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 

           MOVE 3 TO CUT-ASSERT-TARGET-N 
           MOVE DUT-TRACE-FIELD-INDEX TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 

       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-DIR-FB-SIMPLE-FAIL SECTION.
           *> TEST THE NOT DIRECTLY FOLLOWED BY PATH SIMPLY WHEN THE
           *> SECTION IS THERE
           *> MAIN-PROCESSING IS NOT DIRECTLY AFTER INITIALIZATION
       
           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
       
           *> WHEN
           STRING 'AB000-INITIALIZATION '
                  'NOT DIRECTLY-FOLLOWED-BY BA000-MAIN-PROCESSING '
                  'FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE 
           
           *> THEN

           STRING 'DUT-ASSERT-TRACE-HANDLE-VERBS '
                  'FOLLOWED-BY DUT-ASSERT-TRACE-HANDLE-NOT '
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           IF DUT-TEST-PASS 
              STRING 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED ON'
                     ' NOT DIRECTLY FOLLOWED BY' DELIMITED BY SIZE INTO 
                     CUT-DISPLAY-FAIL-MSG 
              END-STRING
              PERFORM CUT-FAIL 
           END-IF 
       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-DIR-FB-SIMPLE-PASS SECTION.
           *> TEST A SIMPLE CASE WHERE SOME SECTION DOES NOT 
           *> DIRECTLY FOLLOW SOME OTHER SECTION
           *> HEADER-RECORD IS NOT DIRECTLY AFTER INIT SO THIS SHOULD PASS
       
           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
       
           *> WHEN
           STRING 'AB000-INITIALIZATION '
                 'NOT DIRECTLY-FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
                  'FOLLOWED-BY BC000-PROCESS-DETAIL-RECORD '
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE 
           
           *> THEN
           IF DUT-TEST-FAIL 
               STRING 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED'
               DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG 
               END-STRING
               PERFORM CUT-FAIL 
           END-IF 
       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-DIR-FB-WITH-PASS SECTION.
           *> TEST THAT NOT DIRECTLY FOLLOWED-BY CAN HANDLE A MORE COMPLEX
           *> EXAMPLE WITH WITH CASES
           *> THE SECTION IS ALLOWED ONLY BECAUSE WORKING STORAGE WAS
           *> WS-NUMER = 7 and not 6
       
           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD

           *> WHEN
           STRING 'AB000-INITIALIZATION '
                  'NOT DIRECTLY-FOLLOWED-BY BA000-MAIN-PROCESSING '
                  'WITH '
                  'WS-NUMBER = 6 '
                  'END-WITH '
                  'FOLLOWED-BY BB000-PROCESS-HEADER-RECORD'
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE
           
           *> THEN
           IF DUT-TEST-FAIL 
              STRING 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED'
              DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG 
              END-STRING
              PERFORM CUT-FAIL 
           END-IF 
       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-DIR-FB-WITH-FAIL SECTION.
           *> TEST THAT NOT DIRECTLY FOLLOWED BY CAN HANDLE FAILING ON
           *> A WITH CASE
       
           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
       
           *> WHEN
           *> THIS SHOULD FAIL ON THE NOT DIRECTLY FOLLOWED BY
           *> BUT IF A WITH IS PRESENT THEN THE CODE DOES A CHECK
           *> TO ENSURE THE WITH CAN'T SAVE THE CASE
           STRING 'AB000-INITIALIZATION '
                  'NOT DIRECTLY-FOLLOWED-BY BA000-MAIN-PROCESSING '
                  'WITH '
                      'WS-NUMBER = 7 '
                  'END-WITH '
                  'FOLLOWED-BY BB000-PROCESS-HEADER-RECORD'
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE
           
           *> THEN

           STRING 'DUT-ASSERT-TRACE '
                  'FOLLOWED-BY DUT-FIND-WITH-IN-TRACE '
                  'FOLLOWED-BY DUT-FAIL'
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           IF DUT-TEST-PASS  
              STRING 'DUT PASSED THE CASE WHEN IT SHOULD HAVE PASSED'
              DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG 
              END-STRING
              PERFORM CUT-FAIL 
           END-IF 
           
       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-FB-SIMPLE-FAIL SECTION.
           *> TEST THAT NOT FOLLOWED-BY CAN PASS A SIMPLE CASE
       
           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC
       
           *> WHEN
           STRING 'BA000-MAIN-PROCESSING '
                  'NOT FOLLOWED-BY AB000-INITIALIZATION'
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE
           
           *> THEN
           IF DUT-TEST-FAIL 
               STRING 'DUT FAILED THE TEST WHEN IT SHOULD HAVE PASSED'
               DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG 
               END-STRING
               PERFORM CUT-FAIL 
           END-IF 

       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-FB-SIMPLE-PASS SECTION.
           *> TEST THAT NOT FB CAN FAIL A SIMPLE CASE
       
           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
       
           *> WHEN
           STRING 'AB000-INITIALIZATION '
                  'NOT FOLLOWED-BY BB000-PROCESS-HEADER-RECORD'
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE
           
           *> THEN
           IF DUT-TEST-PASS
               STRING 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED '
               'AS BB000 DOES FOLLOW AB000' DELIMITED BY SIZE 
               INTO CUT-DISPLAY-FAIL-MSG
               END-STRING
               PERFORM CUT-FAIL 
           END-IF 

       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-FB-WITH-PASS SECTION.
           *> TEST THAT NOT FOLLWOED BY CAN SAVE A CASE BASED ON A WITH
       
           *> THIS CASE SHOULD ACTUALLY FAIL BASED ON THE HEADER-RECORD
           *> FOLLOWING MAIN PROCESSING BUT THE WITH WS-NUMBER = 3
           *> SAVES THE CASE AS BB000 IS ONLY INVALID WHEN WS-NUMBER = 3
           *> WHICH IS NOT THE CASE IN THE FIXTURE

           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
       
           *> WHEN
           STRING 'BA000-MAIN-PROCESSING '
                  'NOT FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
                  'WITH '
                      'WS-NUMBER = 3 '
                  'END-WITH '
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE
           
           *> THEN
           IF DUT-TEST-FAIL 
               STRING 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED '
                      'AS WS-NUMBER IS 2, NOT 3'
               DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG 
               END-STRING
               PERFORM CUT-FAIL 
           END-IF 

       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-FB-WTIH-FAIL-PASS SECTION.
           *> TEST THAT A WITH CONDITION STILL WORKS EVEN WITH
           *> A LONG ASSERTION


           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
       
           *> WHEN
           *> THIS ASSERTION STATES THAT BB000 MUST FOLLOW BA000, BUT
           *> IT CAN'T HAVE WS-NUMBER = 3
           *> THIS SHOULD STILL PASS, BECAUSE BB000 DOES FOLLOW
           *> AND WS-NUMBER = 2
           STRING 'BA000-MAIN-PROCESSING '
                  'NOT FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
                  'WITH '
                      'WS-NUMBER = 3 '
                  'END-WITH '
                  'DIRECTLY-FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE
                     
           *> THEN

           *> ASSERT THAT FOLLOWED-BY IS HAPPENING 
           *> AND THAT THE NOT IS BEING HANDLED
           *> AND THE GHOST LOOKUP IS RESETTING THE TRACE-SECTION-INDEX
           STRING 'DUT-ASSERT-TRACE '
                  'FOLLOWED-BY DUT-FIND-FOLLOWED-BY '
                  'WITH ' 
                      'DUT-TRACE-SECTION-INDEX = 001 '
                  'END-WITH '
                  'FOLLOWED-BY DUT-ASSERT-TRACE-HANDLE-NOT '
                  'FOLLOWED-BY DUT-FIND-FOLLOWED-BY '
                  'WITH ' 
                      *> ANCHOR IS AT 002; FOLLOWED-BY SEARCHES ONE PAST
                      *> IT, SO THE CURSOR HERE IS 003
                      'DUT-TRACE-SECTION-INDEX = 003 '
                  'END-WITH '
                  'FOLLOWED-BY DUT-ASSERT-TRACE-RESET-NOT '
                  'FOLLOWED-BY DUT-FIND-DIRECTLY-FOLLOWED-BY '
                  'WITH '
                      'DUT-TRACE-SECTION-INDEX = 002 '
                  'END-WITH'
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           IF DUT-TEST-FAIL 
               STRING 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED'
               DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG 
               PERFORM CUT-FAIL 
           END-IF
       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-FB-SIMPLE-PASS-LONG SECTION.
           *> TEST THAT NOT FB PASSED A CASE WITH ASSERTIONS AFTER
           *> THE NOT
       
           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
       
           *> WHEN
           STRING 'BA000-MAIN-PROCESSING '
                  'NOT FOLLOWED-BY AB000-INITIALIZATION '
                  'FOLLOWED-BY BB000-PROCESS-HEADER-RECORD '
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE
           
           *> THEN
           IF DUT-TEST-FAIL
               STRING 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED'
               DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG 
               PERFORM CUT-FAIL
           END-IF
       
           PERFORM CUT-END-TEST 
       .

       TEST-NOT-FB-SIMPLE-FAIL-LONG SECTION.
           *> TEST THAT NOT FB FAILS A CASE WITH ASSERTIONS AFTER
           *> THE NOT
       
           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC 
       
           *> WHEN
           STRING 'BB000-PROCESS-HEADER-RECORD '
                  'NOT FOLLOWED-BY AB000-INITIALIZATION '
                  'FOLLOWED-BY BA000-MAIN-PROCESSING '
               DELIMITED BY SIZE
               INTO DUT-TRACE 
           END-STRING
           PERFORM DUT-ASSERT-TRACE
           
           *> THEN
           IF DUT-TEST-PASS
               STRING 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED '
                      'AS BA000 DOESNT FOLLOW BB000'
               DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG 
               PERFORM CUT-FAIL
           END-IF
           

           PERFORM CUT-END-TEST 
       .



              
       TEST-ASSERT-TRACE-BASIC-DOUBLE SECTION.
           *> A SECTION FOLLOWED-BY ITSELF MUST FAIL WHEN IT ONLY
           *> OCCURS ONCE - THE MATCHER MUST ADVANCE PAST THE ANCHOR
           *> SO THE SAME TRACE ENTRY CANNOT SATISFY BOTH TOKENS

           *> GIVEN
           PERFORM FIXTURE-BASIC-ADD-EXEC

           *> WHEN
           STRING 'BA000-MAIN-PROCESSING '
                  'FOLLOWED-BY BA000-MAIN-PROCESSING '
                  DELIMITED BY SIZE
                  INTO DUT-TRACE
           END-STRING
           PERFORM DUT-ASSERT-TRACE

           *> THEN
           IF DUT-TEST-PASS
               STRING 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED '
                      'AS BA000 DOESNT FOLLOW BA000'
               DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
               PERFORM CUT-FAIL
           END-IF

           PERFORM CUT-END-TEST
       .


       END-TEST-SUITE SECTION.
           PERFORM DISPLAY-COVERAGE
           PERFORM CUT-END-TEST-SUITE
       .
      *****************************************************************
      * RUNS AT THE TOP OF EACH SECTION IN THE SOURCE CODE
      * ADDS THE SPECIFIED FIELDS TO THE TRACE
      * IS UPDATED BY THE INSTANTIATOR TO ACTUALLY GENERATE THE MOVE
      * STATEMENTS
      *
      * DEFINE A FIELD TO BE TRACKED BY *WS-FIELD-NAME
      *****************************************************************
       CUT-TRACE-FIELDS SECTION.
           MOVE 'FIELD-A' TO CUT-TEMP-FIELD-NAME 
           MOVE 1000 TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD 

           MOVE 'FIELD-B' TO CUT-TEMP-FIELD-NAME 
           MOVE "example" TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD 

           MOVE 'DUT-TRACE-SECTION-INDEX' TO CUT-TEMP-FIELD-NAME 
           MOVE DUT-TRACE-SECTION-INDEX TO CUT-TEMP-FIELD-VALUE 
           PERFORM CUT-REGISTER-FIELD 
           CONTINUE
       .

       MOCK-DUT-SHUT-DOWN-TEST-SUITE SECTION.
           EXIT SECTION
       .


      *****************************************************************
      * RUNS BEFORE EACH TEST CASE
      * USE THIS SECTION TO SETUP AND TEARDOWN YOUR TEST DATA AND 
      * RESULTS
      * DO NOT REMOVE THE EXIT SECTION OTHERWISE YOU WILL FALL INTO
      * THE BUSINESS PROGRAM
      *****************************************************************
       BEFORE-EACH SECTION.
           SET DUT-TEST-PASS TO TRUE 
           EXIT SECTION  
       .


      * FIXTURES

       FIXTURE-BASIC-ADD-EXEC SECTION.
           PERFORM DUT-CLEAR-TRACE
           *> BASIC 3 SECTION TRACE
           MOVE 'AB000-INITIALIZATION'
           TO DUT-TEMP-SECTION-NAME
           PERFORM DUT-ADD-TRACE-SECTION

           MOVE 'BA000-MAIN-PROCESSING'
           TO DUT-TEMP-SECTION-NAME
           PERFORM DUT-ADD-TRACE-SECTION

           MOVE 'BB000-PROCESS-HEADER-RECORD'
           TO DUT-TEMP-SECTION-NAME
           PERFORM DUT-ADD-TRACE-SECTION

           MOVE 'BC000-PROCESS-DETAIL-RECORD'
           TO DUT-TEMP-SECTION-NAME 
           PERFORM DUT-ADD-TRACE-SECTION 

           MOVE 'BZ000-PROCESS-TRAILER-RECORD'
           TO DUT-TEMP-SECTION-NAME 
           PERFORM DUT-ADD-TRACE-SECTION 

           
       .

       FIXTURE-REGISTER-WITH-FIELD SECTION.
            *> THIS FIXTURE MIMICKS THE DUT-TRACE-FIELDS SECTION
            *> WHICH WOULD BE AUTOMATICALLY INVOKED AT THE TOP OF EACH
            *> SECTION

            MOVE DUT-RT-SECTION-COUNT TO DUT-TRACE-SECTION-INDEX
            MOVE DUT-RT-SECTION-FIELD-COUNT(DUT-RT-SECTION-COUNT) TO
                                                DUT-TRACE-FIELD-INDEX
            
            MOVE 'WS-NUMBER' TO
            DUT-RT-SECTION-FIELD-NAME(DUT-TRACE-SECTION-INDEX
            DUT-TRACE-FIELD-INDEX)
            MOVE FIXTURE-TRACE-FIELD-VALUE TO
            DUT-RT-SECTION-FIELD-VALUE(DUT-TRACE-SECTION-INDEX
            DUT-TRACE-FIELD-INDEX)
            ADD 1 TO DUT-RT-SECTION-FIELD-COUNT(DUT-TRACE-SECTION-INDEX)
            MOVE DUT-RT-SECTION-FIELD-COUNT(DUT-RT-SECTION-COUNT) TO
                                     DUT-TRACE-FIELD-INDEX

       .

       FIXTURE-ADD-EXEC-WITH-FIELD SECTION.
           PERFORM DUT-CLEAR-TRACE
           *> BASIC 3 SECTION TRACE
           MOVE 'AB000-INITIALIZATION'
           TO DUT-TEMP-SECTION-NAME
           MOVE FIXTURE-CONSTANT-10 TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-WITH-FIELD 
           PERFORM DUT-ADD-TRACE-SECTION

           MOVE 'BA000-MAIN-PROCESSING'
           TO DUT-TEMP-SECTION-NAME
           MOVE FIXTURE-CONSTANT-7 TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-WITH-FIELD 
           PERFORM DUT-ADD-TRACE-SECTION


           MOVE 'BB000-PROCESS-HEADER-RECORD'
           TO DUT-TEMP-SECTION-NAME
           MOVE FIXTURE-CONSTANT-2 TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-WITH-FIELD 
           PERFORM DUT-ADD-TRACE-SECTION

           MOVE 'BC000-PROCESS-DETAIL-RECORD'
           TO DUT-TEMP-SECTION-NAME 
           MOVE FIXTURE-CONSTANT-10 TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-WITH-FIELD 
           PERFORM DUT-ADD-TRACE-SECTION 

           MOVE 'BZ000-PROCESS-TRAILER-RECORD'
           TO DUT-TEMP-SECTION-NAME
           MOVE FIXTURE-CONSTANT-20 TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-WITH-FIELD
           PERFORM DUT-ADD-TRACE-SECTION

       .

       FIXTURE-REGISTER-NAMED-FIELD SECTION.
            *> LIKE FIXTURE-REGISTER-WITH-FIELD BUT REGISTERS AN ARBITRARY
            *> FIXTURE-FIELD-NAME / FIXTURE-TRACE-FIELD-VALUE PAIR INTO THE
            *> CURRENT SECTION, SO A FIXTURE CAN BUILD MIXED-FIELD TRACES

            MOVE DUT-RT-SECTION-COUNT TO DUT-TRACE-SECTION-INDEX
            MOVE DUT-RT-SECTION-FIELD-COUNT(DUT-RT-SECTION-COUNT) TO
                                                DUT-TRACE-FIELD-INDEX

            MOVE FIXTURE-FIELD-NAME TO
            DUT-RT-SECTION-FIELD-NAME(DUT-TRACE-SECTION-INDEX
            DUT-TRACE-FIELD-INDEX)
            MOVE FIXTURE-TRACE-FIELD-VALUE TO
            DUT-RT-SECTION-FIELD-VALUE(DUT-TRACE-SECTION-INDEX
            DUT-TRACE-FIELD-INDEX)
            ADD 1 TO DUT-RT-SECTION-FIELD-COUNT(DUT-TRACE-SECTION-INDEX)
            MOVE DUT-RT-SECTION-FIELD-COUNT(DUT-RT-SECTION-COUNT) TO
                                     DUT-TRACE-FIELD-INDEX

       .

      *> THREE SECTIONS WITH DIFFERENT FIELD MIXES SO THE DEBUG TABLE
      *> HAS TO DETECT MULTIPLE COLUMNS AND LEAVE BLANKS WHERE A SECTION
      *> DID NOT REGISTER A FIELD.
      *> COLUMNS ARE FIRST-SEEN ORDER: 1=WS-AGE 2=WS-NAME 3=WS-ID
       FIXTURE-ADD-MULTI-FIELD SECTION.
           PERFORM DUT-CLEAR-TRACE

           *> SECTION 1: MAINLINE - ONLY WS-AGE
           MOVE 'MAINLINE' TO DUT-TEMP-SECTION-NAME
           MOVE 'WS-AGE' TO FIXTURE-FIELD-NAME
           MOVE '0' TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-NAMED-FIELD
           PERFORM DUT-ADD-TRACE-SECTION

           *> SECTION 2: READ-FILE - WS-NAME, WS-AGE, WS-ID
           MOVE 'READ-FILE' TO DUT-TEMP-SECTION-NAME
           MOVE 'WS-NAME' TO FIXTURE-FIELD-NAME
           MOVE 'JOHN SMITH' TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-NAMED-FIELD
           MOVE 'WS-AGE' TO FIXTURE-FIELD-NAME
           MOVE '37' TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-NAMED-FIELD
           MOVE 'WS-ID' TO FIXTURE-FIELD-NAME
           MOVE '000123456' TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-NAMED-FIELD
           PERFORM DUT-ADD-TRACE-SECTION

           *> SECTION 3: PROCESS-RECORD - WS-NAME, WS-ID (NO WS-AGE)
           MOVE 'PROCESS-RECORD' TO DUT-TEMP-SECTION-NAME
           MOVE 'WS-NAME' TO FIXTURE-FIELD-NAME
           MOVE 'JOHN SMITH' TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-NAMED-FIELD
           MOVE 'WS-ID' TO FIXTURE-FIELD-NAME
           MOVE '000123456' TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-NAMED-FIELD
           PERFORM DUT-ADD-TRACE-SECTION

       .

      *> ONE SECTION REGISTERING A NAMED FIELD WHOSE VALUE IS BLANK, SO
      *> DUT-DEBUG-UPDATE-FIELD-WIDTH TAKES ITS SPACES BRANCH AND THE
      *> COLUMN WIDTH IS DRIVEN BY THE FIELD NAME ALONE
       FIXTURE-ADD-BLANK-VALUE SECTION.
           PERFORM DUT-CLEAR-TRACE

           MOVE 'MAINLINE' TO DUT-TEMP-SECTION-NAME
           MOVE 'WS-NAME' TO FIXTURE-FIELD-NAME
           MOVE SPACES TO FIXTURE-TRACE-FIELD-VALUE
           PERFORM FIXTURE-REGISTER-NAMED-FIELD
           PERFORM DUT-ADD-TRACE-SECTION

       .


       COPY CUTPROC.
       COPY PROGRAM.
