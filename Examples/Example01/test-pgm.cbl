       IDENTIFICATION DIVISION.
       PROGRAM-ID. TESTCUT.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
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
      
       01 COUNTERS.
           05 WS-RT-TRACE-SECTION-COUNTER PIC 9(3) VALUE 1.
           05 WS-RT-TRACE-FIELD-COUNTER PIC 9(3) VALUE 1.
      
      
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
           MOVE 5 TO DUT-ASSERT-TARGET 
           MOVE 5 TO DUT-ASSERT-ACTUAL 
       
           *> WHEN
           PERFORM DUT-ASSERT-EQUALS-NUM 
           
           *> THEN
           IF DUT-TEST-FAIL 
               MOVE 'DUT FAILED THE CASE WHEN IT SHOULD HAVE PASSED' TO 
               CUT-DISPLAY-ERROR-MSG 
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
           *> "Expected 5.554400000000000000 but got 5.555500000000000000"

           *> GIVEN
           MOVE 5.5555 TO DUT-ASSERT-ACTUAL-N 
           MOVE 5.5544 TO DUT-ASSERT-TARGET-N
       
           *> WHEN
           PERFORM DUT-ASSERT-EQUALS-NUM 
           
           *> THEN
           IF DUT-TEST-PASS  
               MOVE 'DUT PASSED THE CASE WHEN IT SHOULD HAVE FAILED' TO 
               CUT-DISPLAY-ERROR-MSG 
               PERFORM CUT-FAIL 
           END-IF 

           *> TODO FOLLOWED-BY DUT-FAIL WITH "Expected ..."
           *> 'WITH DUT-DISPLAY-ERROR-MSG = '
           *> '"Expected 5.554400000000000000 but got '
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

       TEST-ASSERT-TRACE-DIR-DB-NEG SECTION.
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
                  'FOLLOWED-BY DUT-ASSERT-TRACE-HANDLE-VERBS '
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


       
      


              
       END-TEST-SUITE SECTION.
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
           CONTINUE
       .

       MOCK-DUT-STOP-RUN SECTION.

           DISPLAY 'WE MOCKED THE EXIT!'
           EXIT SECTION 
           DISPLAY 'WE DIDNT EXIT'
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

       COPY CUTPROC.
       COPY PROGRAM.
