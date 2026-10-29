       IDENTIFICATION DIVISION. 
       PROGRAM-ID. TEST-ASSERT-TRACE.
       ENVIRONMENT DIVISION.
       COPY CUTENV.
       COPY FILECTL OF PGM-TO-TEST.
       DATA DIVISION.
       COPY CUTDATA.
       COPY FILESEC OF PGM-TO-TEST.
       WORKING-STORAGE SECTION. 

       COPY STORAGE OF PGM-TO-TEST.
       COPY CUTSTOR.

       COPY FXTRSTOR.
       COPY ASRTDISP.

       PROCEDURE DIVISION.

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

       TEST-ASSERT-TRACE-WITH-FIRST SECTION.
           *> TEST THAT ASSERT-TRACE CAN EVALUATE A WITH ON THE FIRST 
           *> VERB
       
           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
           STRING 'AB000-INITIALIZATION '
                  'WITH '
                    'WS-NUMBER = 11 '
                  'END-WITH '
                  'FOLLOWED-BY BA000-MAIN-PROCESSING'
                  DELIMITED BY SIZE INTO DUT-TRACE 
           END-STRING
            
           *> WHEN
           PERFORM DUT-ASSERT-TRACE 
           *> THEN
           
           PERFORM EXPECT-DUT-FAILED 
       
           PERFORM CUT-END-TEST 
       .

       TEST-ASSERT-TRACE-WITH-FIRST-P SECTION.
           *> TEST THAT ASSERT-TRACE CAN FAIL ON FIRST SECTION
           *> EVEN WITH A WITH
       
           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
           STRING 'AB000-DOESNT-EXIST '
                  'WITH '
                    'WS-NUMBER = 11 '
                  'END-WITH '
                  'FOLLOWED-BY BA000-MAIN-PROCESSING'
                  DELIMITED BY SIZE INTO DUT-TRACE 
           END-STRING
            
           *> WHEN
           PERFORM DUT-ASSERT-TRACE 
           *> THEN
           
           PERFORM EXPECT-DUT-FAILED 
       
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
       
       TEST-ASSERT-TRACE-TBL-ON-FAIL SECTION.
           *> TEST THAT ASSERT-TRACE DISPLAYS THE TRACE TABLE
           *> ON TEST FAIL WHEN ENABLED
       
           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
           SET DUT-DEBUG-SHOW TO TRUE

           *> WHEN
           STRING 'A-FAKE-SECTION ' DELIMITED BY SIZE INTO DUT-TRACE 
           PERFORM DUT-ASSERT-TRACE 
           
           *> THEN
           STRING 'DUT-ASSERT-TRACE '
                  'FOLLOWED-BY DUT-FAIL '
                  'FOLLOWED-BY DUT-DEBUG-DISPLAY-TRACE '
               DELIMITED BY SIZE
               INTO CUT-TRACE 
           END-STRING
           PERFORM CUT-ASSERT-TRACE
       
           PERFORM CUT-END-TEST 
       .

       TEST-ASSERT-TRACE-NTBL-ON-FAIL SECTION.
           *> TEST THAT ASSERT-TRACE DOESN'T DISPLAY THE TABLE
           *> ON TEST FAIL WHEN THE FLAG IS NOT SET
       
           *> GIVEN
           PERFORM FIXTURE-ADD-EXEC-WITH-FIELD 
           SET DUT-DEBUG-NO-SHOW TO TRUE

           *> WHEN
           STRING 'A-FAKE-SECTION ' DELIMITED BY SIZE INTO DUT-TRACE 
           PERFORM DUT-ASSERT-TRACE 
           
           *> THEN
           STRING 'DUT-ASSERT-TRACE '
                  'FOLLOWED-BY DUT-FAIL '
                  'NOT FOLLOWED-BY DUT-DEBUG-DISPLAY-TRACE '
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
                  *> BB000-PROCESS-HEADER-RECORD
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

       END-TEST-SUITE SECTION.
           PERFORM DISPLAY-COVERAGE
           PERFORM CUT-END-TEST-SUITE
       .

       
       
       COPY ASRTHELP.

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
           MOVE 'DUT-TRACE-SECTION-INDEX' TO CUT-TEMP-FIELD-NAME 
           MOVE DUT-TRACE-SECTION-INDEX TO CUT-TEMP-FIELD-VALUE 
           PERFORM CUT-REGISTER-FIELD 

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
           MOVE SPACES TO DUT-OUT-RECORD
           MOVE 0 TO DUT-TEST-PASS-COUNT 
                     DUT-TEST-FAIL-COUNT
                     DUT-TEST-ERROR-COUNT 
                     DUT-TEST-SKIP-COUNT 
           EXIT SECTION  
       .

       MOCK-DUT-WRITE-UT-RECORD SECTION.
           EXIT SECTION 
       .

       COPY FXTRPROC.

       COPY PROGRAM OF PGM-TO-TEST.
       COPY CUTPROC.