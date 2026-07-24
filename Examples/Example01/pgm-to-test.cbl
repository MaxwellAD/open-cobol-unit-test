       IDENTIFICATION DIVISION.
       PROGRAM-ID. DUTPGM.
       ENVIRONMENT DIVISION. 
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DUT-OUT ASSIGN TO DUT-RPTO
           ORGANIZATION IS LINE SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  DUT-OUT RECORDING MODE F.
       01 DUT-OUT-RECORD                PIC X(160).
       WORKING-STORAGE SECTION.
      * COBOL UT WORKING STORAGE

      * SPDX-License-Identifier: GPL-3.0-or-later
      * SPDX-FileCopyrightText: 2026 MaxwellAD
       01 DUT-DATA.
           05 DUT-MESSAGE               PIC X(100).
           05 DUT-TEST-NAME             PIC X(100).
           05 DUT-TEST-PASS-COUNT       PIC 9(9).
           05 DUT-TEST-PASS-COUNT-DISPLAY
                                        PIC Z(8)9.
           05 DUT-TEST-FAIL-COUNT       PIC 9(9).
           05 DUT-TEST-ERROR-COUNT      PIC 9(9).
           05 DUT-TEST-FAIL-COUNT-DISPLAY
                                        PIC Z(8)9.
           05 DUT-TEST-SKIP-COUNT-DISPLAY
                                        PIC Z(8)9.
           05 DUT-TEST-ERROR-COUNT-DISPLAY
                                        PIC Z(8)9.
           05 DUT-TEST-SKIP-COUNT       PIC 9(9).
           05 DUT-TEST-STATUS           PIC X(1)       VALUE 'F'.
               88 DUT-TEST-FAIL                        VALUE 'F'.
               88 DUT-TEST-PASS                        VALUE 'P'.
               88 DUT-TEST-SKIP                        VALUE 'S'.
               88 DUT-TEST-ERROR                       VALUE 'E'.
           05 DUT-SECTION-SEARCH-STATUS PIC X.
               88 DUT-SECTION-FOUND                    VALUE 'Y'.
               88 DUT-SECTION-NOT-FOUND                VALUE 'N'.
           05 DUT-FIELD-SEARCH-STATUS   PIC X.
               88 DUT-FIELD-FOUND                      VALUE 'Y'.
               88 DUT-FIELD-NOT-FOUND                  VALUE 'N'.

       01 DUT-DISPLAYS.
           05 DUT-DISPLAY-FAIL.
               10 FILLER                PIC X(7)       VALUE '[FAIL] '.
               10 DUT-DISPLAY-FAIL-MSG  PIC X(150).
           05 DUT-DISPLAY-PASS.
               10 FILLER                PIC X(7)       VALUE '[PASS] '.
               10 DUT-DISPLAY-PASS-MSG  PIC X(150).
           05 DUT-DISPLAY-SKIP.
               10 FILLER                PIC X(7)       VALUE '[SKIP] '.
               10 DUT-DISPLAY-SKIP-MSG  PIC X(150).
           05 DUT-DISPLAY-INFO.
               10 FILLER                PIC X(7)       VALUE '[INFO] '.
               10 DUT-DISPLAY-INFO-MSG  PIC X(150).
           05 DUT-DISPLAY-WARN.
               10 FILLER                PIC X(7)       VALUE '[WARN] '.
               10 DUT-DISPLAY-WARN-MSG  PIC X(150).
           05 DUT-DISPLAY-ERROR.
               10 FILLER                PIC X(8)       VALUE '[ERROR] '.
               10 DUT-DISPLAY-ERROR-MSG PIC X(150).


       01 DUT-EXEC-TRACE.
           05 DUT-TRACE                 PIC X(1000).
                                     *> THE ACTUAL COMMAND
           05 DUT-TRACE-WORD-COUNT      PIC 9(2)       VALUE 0. 
           05 DUT-TRACE-TEMP-WORD       PIC X(31)      VALUE SPACES.
           05 DUT-TRACE-POINTER         PIC 9(4) COMP  VALUE 1.
           05 DUT-TRACE-FIELD-INDEX     PIC 9(3)       VALUE 1.
           05 DUT-TRACE-SECTION-INDEX   PIC 9(3)       VALUE 1.
           *> BELOW IS NEEDED TO DO A GHOST LOOKAHEAD ON NOT FOLLOWED-BY
           05 DUT-TRACE-SECTION-INDEX-MEM
                                        PIC 9(3)       VALUE 1.
           05 DUT-TEMP-SECTION-NAME     PIC X(30)      VALUE SPACES.
           05 DUT-TEMP-FIELD-NAME       PIC X(30)      VALUE SPACES.
           05 DUT-TEMP-FIELD-VALUE      PIC X(30)      VALUE SPACES.
           05 DUT-TEMP-FIELD-EXPECTED   PIC X(30)      VALUE SPACES.
           05 DUT-TEMP-FIELD-OPERATOR   PIC X(2)       VALUE SPACES.
           05 DUT-RT-SECTION-COUNT      PIC 9(3)       VALUE 1.
           05 DUT-EXEC-TRACE-INDEX      PIC 9(3)       VALUE 1.
                                                     *> ITERATE EXEC CMD
           05 DUT-EXEC-TRACE-NOT-FLAG   PIC X(1)       VALUE 'N'.
               88 DUT-EXEC-TRACE-NOT                   VALUE 'Y'.
               88 DUT-EXEC-TRACE-NORMAL                VALUE 'N'.
           05 DUT-EXEC-TRACE-OCCURS. *> THE COMMAND SPLIT INTO WORDS
               10 DUT-EXEC-TRACE-WORD   PIC X(30) OCCURS 50 TIMES.

           05 DUT-RT-TRACE OCCURS 100 TIMES. *> UP TO 100 SECTIONS
               10 DUT-RT-SECTION-NAME   PIC X(30)      VALUE SPACES.
               10 DUT-RT-SECTION-FIELD-COUNT
                                        PIC 9(3)       VALUE 1.
               10 DUT-RT-SECTION-FIELDS OCCURS 100 TIMES.*> UP TO 100
                                                  *> FIELDS PER SECTION
                   15 DUT-RT-SECTION-FIELD-NAME
                                        PIC X(30)      VALUE SPACES.
                   15 DUT-RT-SECTION-FIELD-VALUE
                                        PIC X(30)      VALUE SPACES.
       
       
       01 DUT-FILED-EXPECT.
           05 DUT-FIELDS-TO-TRACE       PIC X(1000).
           05 DUT-EXPECT                PIC X(1000).
           05 DUT-EXPECT-WORD-COUNT     PIC 9(2)       VALUE 0. 
           05 DUT-EXPECT-TEMP-WORD      PIC X(31).
           05 DUT-EXPECT-POINTER        PIC 9(4) COMP  VALUE 1.
           05 DUT-EXPECT-OCCURS.
               10 DUT-EXPECT-WORD       PIC X(30) OCCURS 50 TIMES.      


       01 DUT-ASSERT-FIELDS.
           05 DUT-ASSERT-TARGET         PIC X(256)     VALUE SPACES. 
           05 DUT-ASSERT-ACTUAL         PIC X(256)     VALUE SPACES.
           05 DUT-ASSERT-TARGET-N       PIC 9(18)V9(18).
           05 DUT-ASSERT-ACTUAL-N       PIC 9(18)V9(18).
           *> Before displaying the TARGET and ACTUALS are moved to 
           *> THE DISPLAY-OUT mirrors

           *> Z(35).99 is probably "good enough"
           *> COBOL doesn't handle trailing zeros very well (or at all)
           *> This captures a lot of currency
           *> The test fail is done on the COMP-2 fields which have high
           *> precision, so the dev still knows something is up, even
           *> if the display can't show it
           *> And it's more than likely, if there's some issue with the 
           *> result then it'll be wrong by more than 2 decimal places

           05 DUT-ASSERT-TARGET-DIS-N   PIC Z(34)9.99.
           05 DUT-ASSERT-ACTUAL-DIS-N   PIC Z(34)9.99.

           *> If the above gets a rounding error then fallback to these
           *> fields which are less pretty but provide the full context
           05 DUT-ASSERT-TARGET-DIS-N-LONG
                                        PIC Z(17)9.9(18).
           05 DUT-ASSERT-ACTUAL-DIS-N-LONG
                                        PIC Z(17)9.9(18).

       PROCEDURE DIVISION.
      * COBOL UT HELPER FUNCTIONS 
      * SPDX-License-Identifier: GPL-3.0-or-later
      * SPDX-FileCopyrightText: 2026 MaxwellAD
       
       
      * CALLED AT THE END OF EVERY TEST CASE TO TERMINATE A TEST
      * INCREMENTS THE RESPECTIVE COUNTER FOR EACH TEST RESULT
      * CLEAR THE EXECUTION TRACE
      * WRITES ANY CLOSING LINES TO THE TEST RECORD  
       DUT-END-TEST SECTION.
           EVALUATE TRUE 
           WHEN DUT-TEST-PASS
               ADD 1 TO DUT-TEST-PASS-COUNT
               MOVE DUT-DISPLAY-PASS TO DUT-OUT-RECORD
               PERFORM DUT-WRITE-UT-RECORD
               PERFORM DUT-PASS
           WHEN DUT-TEST-FAIL
               ADD 1 TO DUT-TEST-FAIL-COUNT
               PERFORM DUT-FAIL 
           WHEN DUT-TEST-SKIP
              *> DUT-END-TEST doesn't run if the case is SKIPPED
               CONTINUE 
           WHEN DUT-TEST-ERROR
               ADD 1 TO DUT-TEST-ERROR-COUNT
               PERFORM DUT-ERROR
           END-EVALUATE 
           PERFORM DUT-CLEAR-TRACE 
           MOVE ' ' TO DUT-OUT-RECORD
           PERFORM DUT-WRITE-UT-RECORD
           .
       

      * CALLED AT THE END OF ALL THE TESTS TO TERMINATE THE TEST SUITE
      * OUTPUTS THE OVERALL TEST RESULT AND SHUTS DOWN THE TEST SUITE
       DUT-END-TEST-SUITE SECTION.

           MOVE ' ' TO DUT-OUT-RECORD
           PERFORM DUT-WRITE-UT-RECORD
           MOVE 'TEST EXECUTION RESULTS' TO DUT-OUT-RECORD
           PERFORM DUT-WRITE-UT-RECORD

           MOVE DUT-TEST-PASS-COUNT TO DUT-TEST-PASS-COUNT-DISPLAY
           MOVE DUT-TEST-FAIL-COUNT TO DUT-TEST-FAIL-COUNT-DISPLAY
           MOVE DUT-TEST-SKIP-COUNT TO DUT-TEST-SKIP-COUNT-DISPLAY
           MOVE '===================================================' TO
              DUT-OUT-RECORD
           PERFORM DUT-WRITE-UT-RECORD

           STRING 'PASS : ' FUNCTION TRIM(DUT-TEST-PASS-COUNT-DISPLAY)
              DELIMITED BY SIZE INTO DUT-OUT-RECORD 
           PERFORM DUT-WRITE-UT-RECORD

           STRING 'FAIL : ' FUNCTION TRIM(DUT-TEST-FAIL-COUNT-DISPLAY)
              DELIMITED BY SIZE INTO DUT-OUT-RECORD 
           PERFORM DUT-WRITE-UT-RECORD

           STRING 'SKIP : ' FUNCTION TRIM(DUT-TEST-SKIP-COUNT-DISPLAY)
              DELIMITED BY SIZE INTO DUT-OUT-RECORD 
           PERFORM DUT-WRITE-UT-RECORD

           IF DUT-TEST-ERROR-COUNT NOT = 0
               MOVE DUT-TEST-ERROR-COUNT TO DUT-TEST-ERROR-COUNT-DISPLAY
               STRING 'ERROR: '
                      FUNCTION TRIM
                  (DUT-TEST-ERROR-COUNT-DISPLAY)
                  DELIMITED BY SIZE INTO DUT-OUT-RECORD
               PERFORM DUT-WRITE-UT-RECORD
           END-IF
           MOVE '===================================================' TO
              DUT-OUT-RECORD
           PERFORM DUT-WRITE-UT-RECORD
           PERFORM DUT-SHUT-DOWN-TEST-SUITE 
           .

      * SHUTDOWN SECTION EXTRACTED FOR MOCKABLE UNIT TEST OF 
      * END-TEST-SUITE
       DUT-SHUT-DOWN-TEST-SUITE SECTION.
           CLOSE DUT-OUT 
           STOP RUN
           .

      * USAGE TYPE: EXTERNAL
      * DESCRIPTION: USED IN CONJUNCTION WITH THE DUT-TRACE FIELD
      * THIS SECTION CYCLES THROUGH EACH STATEMENT IN THE DUT-TRACE
       DUT-ASSERT-TRACE SECTION.
           MOVE 1 TO DUT-TRACE-POINTER
           MOVE 0 TO DUT-TRACE-WORD-COUNT
           MOVE 1 TO DUT-TRACE-SECTION-INDEX
           
           PERFORM UNTIL DUT-TRACE-POINTER > LENGTH OF DUT-TRACE
              OR DUT-TRACE-WORD-COUNT >= 20
               PERFORM DUT-ASSERT-TRACE-REGSTR-WORDS 
           END-PERFORM

           *> FIRST ITEM WILL ALWAYS BE A SECTION NAME

           MOVE DUT-EXEC-TRACE-WORD(1) TO DUT-TEMP-SECTION-NAME
           *> NEED TO SCAN THROUGH TRACE TO FIND FIRST SECTION NAME
           *> AND GO FROM THERE
           PERFORM DUT-FIND-FOLLOWED-BY 
           PERFORM VARYING DUT-EXEC-TRACE-INDEX FROM 2 BY 1 UNTIL
              DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX) = ' '
              OR DUT-TEST-FAIL
               PERFORM DUT-ASSERT-TRACE-HANDLE-VERBS 
           END-PERFORM
           MOVE SPACES TO DUT-EXEC-TRACE-OCCURS
           .

      * USAGE: INTERNAL
      * DESCRIPTION: SEPARATES EACH OF THE WORDS GIVE BY THE UNIT TESTER
      * IN THE DUT-TRACE INTO THE DUT-EXEC-TRACE-WORD OCCURS FIELD
      * WHICH IS LATER ITERATED OVER
       DUT-ASSERT-TRACE-REGSTR-WORDS SECTION.
           UNSTRING DUT-TRACE
              DELIMITED BY ALL SPACE
              INTO DUT-TRACE-TEMP-WORD
              WITH POINTER DUT-TRACE-POINTER
           END-UNSTRING

           IF DUT-TRACE-TEMP-WORD NOT = SPACES
               ADD 1 TO DUT-TRACE-WORD-COUNT
               MOVE DUT-TRACE-TEMP-WORD TO
                  DUT-EXEC-TRACE-WORD(DUT-TRACE-WORD-COUNT)
           END-IF

           .

      * USAGE: INTERNAL
      * DESCRIPTION: HANDLES THE START VERBS OF EACH STATEMENT IN THE 
      * DUT-TRACE. REPRESENTED BY EACH WHEN IN THE EVALUATE
       DUT-ASSERT-TRACE-HANDLE-VERBS SECTION.

           EVALUATE DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX) 
           *> IF IT'S A FOLLOWED-BY COMMAND
           WHEN 'FOLLOWED-BY'
               PERFORM DUT-HANDLE-FOLLOWED-BY
           *> IF IT'S A DIRECTLY-FOLLOWED-BY COMMAND
           WHEN 'DIRECTLY-FOLLOWED-BY'
               PERFORM DUT-HANDL-DIRECTLY-FOLLOWED-BY 
           *> IF IT'S A NOT COMMAND
           WHEN 'NOT'
               PERFORM DUT-ASSERT-TRACE-HANDLE-NOT  
           WHEN OTHER
                 *> TODO
                 *> THIS SHOULDN'T ACTUALLY RUN, THIS IS SOME UNEXPECTED
                 *> KEYWORD - ASSUME USER ERROR AND TRIGGER A FATAL
                 *> RESPONSE
               MOVE DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX)
                  TO DUT-TEMP-SECTION-NAME
           END-EVALUATE
           . 

      * USAGE: INTERNAL
      * DESCRIPTION: WHEN INVOKED BY THE DUT-ASSERT-TRACE THIS SECTION
      * SEARCHES THE EXECUTION TRACE FOR THE SECTION NAME GIVEN
      * IN THE FOLLOWED-BY STATEMENT
      * IF THERE IS A WITH CONDITION ON THE STATEMENT, THEN A WITH
      * LOOKUP IS ALSO PERFORMED
       DUT-HANDLE-FOLLOWED-BY SECTION.
           ADD 1 TO DUT-EXEC-TRACE-INDEX
           MOVE DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX) TO
              DUT-TEMP-SECTION-NAME
           *> SAVE THE CURRENT SECTION INDEX TO MEMORY
           *> IF THE FOLLOWED-BY IS A NOT FOLLOWED-BY WE'LL NEED
           *> TO REVERT AS A NOT FOLLOWED-BY DOES A "GHOST" LOOKAHEAD
           MOVE DUT-TRACE-SECTION-INDEX TO DUT-TRACE-SECTION-INDEX-MEM
           PERFORM DUT-FIND-FOLLOWED-BY
           *> IF THE NEXT WORD IS A WITH THEN CHECK THE WITH FIELDS
           IF DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX + 1)
              = 'WITH'
               ADD 1 TO DUT-EXEC-TRACE-INDEX 
               PERFORM DUT-ASSERT-TRACE-HANDLE-WITH 
           END-IF 
           *> Don't forget to reset NOT flag
           IF DUT-EXEC-TRACE-NOT 
               PERFORM DUT-ASSERT-TRACE-RESET-NOT 
           END-IF 

           .

      * USAGE: INTERNAL
      * DESCRIPTION: USED TO RESET THE "NOT" FLAG, THE NOT FLAG IS SET
      * AS THE OPENING TO A STATEMENT IN THE DUT-TRACE
       DUT-ASSERT-TRACE-RESET-NOT SECTION.
           *> "AND IT WAS ALL A DREAM"
           MOVE DUT-TRACE-SECTION-INDEX-MEM TO
              DUT-TRACE-SECTION-INDEX 
           SET DUT-EXEC-TRACE-NORMAL TO TRUE
           .
       
      * USAGE: INTERNAL
      * DESCRIPTION: ORCHESTRATES THE DIRECTLY-FOLLOWED-BY LOGIC
      * CHECKS THE NAME OF THE NEXT SECTION IN THE EXECUTION TRACE
      * IF THERE IS A WITH CONDITION THEN THAT WITH CONDITION IS 
      * ALSO VALIDATED 
       DUT-HANDL-DIRECTLY-FOLLOWED-BY SECTION.
           ADD 1 TO DUT-EXEC-TRACE-INDEX
           MOVE DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX) TO
              DUT-TEMP-SECTION-NAME
           MOVE DUT-TRACE-SECTION-INDEX TO DUT-TRACE-SECTION-INDEX-MEM
           
           PERFORM DUT-FIND-DIRECTLY-FOLLOWED-BY
           *>IF DUT-TEST-FAIL AND DUT-EXEC-TRACE-NOT 
           IF DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX + 1)
              = 'WITH'
               ADD 1 TO DUT-EXEC-TRACE-INDEX 
               PERFORM DUT-ASSERT-TRACE-HANDLE-WITH 
           END-IF 
           *> Don't forget to disable NOT flag
           IF DUT-EXEC-TRACE-NOT 
               PERFORM DUT-ASSERT-TRACE-RESET-NOT
           END-IF 

           .

      * USAGE: INTERNAL
      * DESCRIPTION: PROCESS OF ENABLING THE NOT FLAG
       DUT-ASSERT-TRACE-HANDLE-NOT SECTION.
           SET DUT-EXEC-TRACE-NOT TO TRUE 
           .

      * USEAGE: INTERNAL
      * DESCRIPTION: USED WHEN A WITH BLOCK IS FOUND. LOOPS UNTIL 
      * "END-WITH" IS FOUND AND DELEGATES TO THE WITH LOOKUP ROUTINES
       DUT-ASSERT-TRACE-HANDLE-WITH SECTION.
           *> GET THE FIELD AND BEING LOOPING FOR EACH FIELD
           *> UNTIL END-WITH
           ADD 1 TO DUT-EXEC-TRACE-INDEX
           *>DISPLAY 'EXEC INDEX' DUT-EXEC-TRACE-INDEX
           *> SHOULD ALWAYS BE IN ORDER
           *> WS-FIELD
           *> <OPERATOR>
           *> VALUE
           PERFORM VARYING DUT-EXEC-TRACE-INDEX FROM
              DUT-EXEC-TRACE-INDEX BY 1
              UNTIL DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX)
              = 'END-WITH'
              *>DISPLAY 'EXEC INDEX' DUT-EXEC-TRACE-INDEX
               MOVE DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX) TO
                  DUT-TEMP-FIELD-NAME
               ADD 1 TO DUT-EXEC-TRACE-INDEX
               MOVE DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX) TO
                  DUT-TEMP-FIELD-OPERATOR
               ADD 1 TO DUT-EXEC-TRACE-INDEX
               MOVE DUT-EXEC-TRACE-WORD(DUT-EXEC-TRACE-INDEX) TO
                  DUT-TEMP-FIELD-EXPECTED
               PERFORM DUT-FIND-WITH-IN-TRACE
           END-PERFORM 
              *> UNTIL END-WITH IS FOUND IN COMMAND
           .


      * USAGE: EXTERNAL
      * DESCRIPTION:    
       *> General assertion statement
       *> A check is done to see if the numeric fields were populated
       *> before invoking this section. if they were, then throw an
       *> error on the test case as this is likely incorrect
       *> TARGET-N and ACTUAL-N are for DUT-ASSERT-EQUALS-NUM 
       DUT-ASSERT-EQUALS SECTION.
           IF DUT-ASSERT-TARGET-N NOT = 0 OR DUT-ASSERT-ACTUAL-N NOT = 0
               STRING 'USE DUT-ASSERT-EQUALS-NUM TO EVALUATE NUMBERS'
                  DELIMITED BY SIZE INTO DUT-DISPLAY-ERROR-MSG
               END-STRING
               PERFORM DUT-ERROR
               MOVE ZEROS TO DUT-ASSERT-TARGET-N
                             DUT-ASSERT-ACTUAL-N
           ELSE
               IF DUT-ASSERT-TARGET = DUT-ASSERT-ACTUAL
                   PERFORM DUT-PASS 
               ELSE
                   SET DUT-TEST-FAIL TO TRUE 
                   STRING
                      'Expected '
                      FUNCTION TRIM(DUT-ASSERT-TARGET)
                      ' but got '
                      FUNCTION TRIM(DUT-ASSERT-ACTUAL)
                      DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
                   END-STRING
                   PERFORM DUT-FAIL
               END-IF
           END-IF 
           MOVE SPACES TO DUT-ASSERT-TARGET
                          DUT-ASSERT-ACTUAL
           .      

       
      * USAGE: EXTERNAL
      * DESCRIPTION: 
       *> Use this when working with numerics of high precision or with
       *> Decimal places
       *> Will default to 2 decimal places of precision unless 
       *> that causes the output to display Expected X but got X where
       *> X is identical
       *> TODO revisit this, perhaps a better rounding / post decimal
       *> point z supression would be better
       DUT-ASSERT-EQUALS-NUM SECTION.

           IF DUT-ASSERT-TARGET NOT = SPACES OR
              DUT-ASSERT-ACTUAL NOT = SPACES 
               STRING 'USE DUT-ASSERT-EQUALS TO EVALUATE STRINGS'
                  DELIMITED BY SIZE INTO DUT-DISPLAY-ERROR-MSG
               END-STRING
               PERFORM DUT-ERROR
               MOVE SPACES TO DUT-ASSERT-TARGET
                              DUT-ASSERT-ACTUAL
           ELSE
               IF DUT-ASSERT-TARGET-N = DUT-ASSERT-ACTUAL-N
                   PERFORM DUT-PASS
               ELSE
                   SET DUT-TEST-FAIL TO TRUE
                   PERFORM DUT-ASSERT-EQUALS-NUM-FAIL
                   PERFORM DUT-FAIL 
               END-IF 
           END-IF 
           MOVE ZEROS TO DUT-ASSERT-TARGET-DIS-N-LONG
                         DUT-ASSERT-ACTUAL-DIS-N-LONG
                         DUT-ASSERT-TARGET-N
                         DUT-ASSERT-ACTUAL-N
           .

      * USAGE: INTERNAL
      * DESCRIPTION: THE FAIL ROUTINE FOR WHEN A NUMERIC ASSERTION FAILS
       DUT-ASSERT-EQUALS-NUM-FAIL SECTION.
           MOVE DUT-ASSERT-TARGET-N TO
              DUT-ASSERT-TARGET-DIS-N
           MOVE DUT-ASSERT-ACTUAL-N TO
              DUT-ASSERT-ACTUAL-DIS-N
           IF DUT-ASSERT-TARGET-DIS-N = DUT-ASSERT-ACTUAL-DIS-N
               *> This means a rounding error has happened
               *> Fallback to long number display
               PERFORM DUT-HANDLE-DIS-ROUND-ERROR
           ELSE 
               STRING
                  'Expected '
                  FUNCTION TRIM(DUT-ASSERT-TARGET-DIS-N)
                  ' but got '
                  FUNCTION TRIM(DUT-ASSERT-ACTUAL-DIS-N)
                  DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
               END-STRING
           END-IF
           .


      * USAGE: INTERNAL
      * DESCRIPTION: IF A ROUNDING ERROR CAUSES A DISPLAY TO BE 
      * TRUNCATED IN A CONFUSING WAY, THIS SECTION WILL RUN TO DISPLAY
      * THE UNTRUNCATED VERSION OF THE NUMERIC VALUES
       DUT-HANDLE-DIS-ROUND-ERROR SECTION.

           MOVE DUT-ASSERT-TARGET-N TO
              DUT-ASSERT-TARGET-DIS-N-LONG
           MOVE DUT-ASSERT-ACTUAL-N TO
              DUT-ASSERT-ACTUAL-DIS-N-LONG
           STRING
              'Expected '
              FUNCTION TRIM(DUT-ASSERT-TARGET-DIS-N-LONG)
              ' but got '
              FUNCTION TRIM(DUT-ASSERT-ACTUAL-DIS-N-LONG)
              DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
           END-STRING
           .

      * USAGE: EXTERNAL
      * DESCRIPTION: WHEN DUT-TEMP-FIELD-NAME & DUT-TEMP-FIELD-VALUE ARE
      * POPULATED THIS SECTION IS INVOKED TO ADD THOSE FIELDS TO THE
      * EXECUTION TRACE, ASSOCIATED WITH THE SECTION BEING EXECUTED
       DUT-REGISTER-FIELD SECTION.
           MOVE DUT-RT-SECTION-COUNT TO DUT-TRACE-SECTION-INDEX
           MOVE DUT-RT-SECTION-FIELD-COUNT(DUT-RT-SECTION-COUNT) TO
              DUT-TRACE-FIELD-INDEX
           MOVE DUT-TEMP-FIELD-NAME TO
              DUT-RT-SECTION-FIELD-NAME(DUT-TRACE-SECTION-INDEX
              DUT-TRACE-FIELD-INDEX)
           MOVE DUT-TEMP-FIELD-VALUE TO
              DUT-RT-SECTION-FIELD-VALUE(DUT-TRACE-SECTION-INDEX
              DUT-TRACE-FIELD-INDEX)

           *> Advance the index
           ADD 1 TO DUT-RT-SECTION-FIELD-COUNT(DUT-TRACE-SECTION-INDEX)
           MOVE DUT-RT-SECTION-FIELD-COUNT(DUT-RT-SECTION-COUNT) TO
              DUT-TRACE-FIELD-INDEX

           .


      * USAGE: INTERNAL
      * DESCRIPTION: AS LISTED BELOW, SEARCHES THE EXECUTION TRACE FOR 
      * TARGET SECTION
      * THE TEST CASE IS FAILED IF IT'S NOT FOUND, UNLESS IT'S A NOT CASE 
       DUT-FIND-FOLLOWED-BY SECTION.
           *> DUT-TEMP-SECTION-NAME <-- THE TARGET SECTION
           *> DUT-RT-SECTION-NAME(index) <-- LIST OF SECTIONS
           *> DUT-TRACE-SECTION-INDEX <-- INDEX OF THE SECTION TRACE
           *> DUT-END-SECTION-NAME <-- THE END SECTION

           SET DUT-SECTION-NOT-FOUND TO TRUE
           PERFORM VARYING DUT-TRACE-SECTION-INDEX FROM
              DUT-TRACE-SECTION-INDEX BY 1 UNTIL
              DUT-SECTION-FOUND
              OR
              DUT-TRACE-SECTION-INDEX > DUT-RT-SECTION-COUNT


              *>DISPLAY 'FOUND SECTION: ' 
              *>DUT-RT-SECTION-NAME(DUT-TRACE-SECTION-INDEX)
               IF DUT-TEMP-SECTION-NAME =
                  DUT-RT-SECTION-NAME(DUT-TRACE-SECTION-INDEX)
                   SET DUT-SECTION-FOUND TO TRUE
                 *> WE FOUND THE SECTION, LEAVE THE PERFORM  
                 *> PRE-EMTIVELY SUBTRACT 1 FROM THE INDEX TO COUNTER
                 *> THE ADD AT THE END OF THE PERFORM
                 *> SUBTRACT 1 FROM DUT-TRACE-SECTION-INDEX
                   EXIT PERFORM 
               END-IF
           END-PERFORM
           
           *> IF WE RAN OFF THE END THEN THE SECTION WASN'T IN THE TRACE
           IF DUT-SECTION-NOT-FOUND
               IF DUT-EXEC-TRACE-NORMAL 
                   SET DUT-TEST-FAIL TO TRUE 
                   STRING 'UNABLE TO FIND '
                          FUNCTION TRIM(DUT-TEMP-SECTION-NAME)
                          ' IN EXECUTION TRACE'
                      DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
                   END-STRING
                   PERFORM DUT-FAIL
               END-IF 
           ELSE
               IF DUT-EXEC-TRACE-NOT 
                   SET DUT-TEST-FAIL TO TRUE 
                   STRING 'FOUND SECTION '
                          FUNCTION TRIM(DUT-TEMP-SECTION-NAME)
                          ' IN EXECUTION TRACE'
                      DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
                   END-STRING
                   PERFORM DUT-FAIL
               END-IF 
           END-IF
           .

      * USAGE: INTERNAL
      * DESCRIPTION: SEARCHES THE NEXT INDEX IN THE EXECUTION TRACE
      * FOR THE TARGET SECTION
      * THE TEST CASE IS FAILED IF IT'S NOT FOUND, UNLESS IT'S A NOT CASE 
       DUT-FIND-DIRECTLY-FOLLOWED-BY SECTION.
           *> DUT-TEMP-SECTION-NAME <-- THE TARGET SECTION
           *> DUT-RT-SECTION-NAME(index) <-- LIST OF SECTIONS
           *> DUT-TRACE-SECTION-INDEX <-- INDEX OF THE SECTION TRACE

           SET DUT-SECTION-NOT-FOUND TO TRUE
           *>DISPLAY 'FOUND SECTION: ' 
           *>DUT-RT-SECTION-NAME(DUT-TRACE-SECTION-INDEX)

           ADD 1 TO DUT-TRACE-SECTION-INDEX 

           IF DUT-TEMP-SECTION-NAME =
              DUT-RT-SECTION-NAME(DUT-TRACE-SECTION-INDEX)
               SET DUT-SECTION-FOUND TO TRUE
              *> WE FOUND THE SECTION, LEAVE THE PERFORM  
              *> PRE-EMTIVELY SUBTRACT 1 FROM THE INDEX TO COUNTER
              *> THE ADD AT THE END OF THE PERFORM
              *> SUBTRACT 1 FROM DUT-TRACE-SECTION-INDEX
           END-IF
           
           *> IF WE RAN OFF THE END THEN THE SECTION WASN'T IN THE TRACE
           IF DUT-SECTION-NOT-FOUND
               IF DUT-EXEC-TRACE-NORMAL 
                   SET DUT-TEST-FAIL TO TRUE 
                   STRING 'UNABLE TO FIND '
                          FUNCTION TRIM(DUT-TEMP-SECTION-NAME)
                          ' DIRECTLY AFTER '
                          FUNCTION TRIM(DUT-RT-SECTION-NAME
                      (DUT-TRACE-SECTION-INDEX))
                          ' IN EXECUTION TRACE'
                      DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
                   END-STRING
                   PERFORM DUT-FAIL
               END-IF
           ELSE 
               *> IF THE SECTION WAS FOUND
               IF DUT-EXEC-TRACE-NOT 
                   *> THIS IS BAD
                   SET DUT-TEST-FAIL TO TRUE 
                   STRING 'FOUND '
                          FUNCTION TRIM(DUT-TEMP-SECTION-NAME)
                          ' DIRECTLY AFTER '
                          FUNCTION TRIM(DUT-RT-SECTION-NAME
                      (DUT-TRACE-SECTION-INDEX))
                          ' IN EXECUTION TRACE '
                      DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
                   END-STRING
                   PERFORM DUT-FAIL 
               END-IF
           END-IF

           .

      * USAGE: INTERNAL
      * DESCRIPTION: SEARCHES WITHIN THE CURRENT SECTIONS TRACE TABLE
      * FOR THE FIELD VALUE PAIR AND THEN CHECKS THE ASSERTION STATEMENT
       DUT-FIND-WITH-IN-TRACE SECTION.
           *> USED TO SEARCH
           *> DUT-TRACE-SECTION-INDEX <-- INDEX OF THE TARGET SECTION
           *> v FIELD NAME(S) AT THIS SECTION
           *> DUT-RT-SECTION-FIELD-NAME(DUT-TRACE-SECTION-INDEX index)
           *> v FIELD VALUE(S) AT THIS SECTION (CAST TO CHARACTER)
           *> DUT-RT-SECTION-FIELD-VALUE(DUT-TRACE-SECTION-INDEX index)
           
           *> KNOWNS
           *> DUT-TEMP-FIELD-VALUE <-- ACTUAL VALUE (NEED TO FIND)
           *> DUT-TEMP-FIELD-EXPECTED <-- EXPECTED VALUE
           *> DUT-TEMP-FIELD-NAME <-- FIELD NAME TO FIND
           *> DUT-TEMP-FIELD-OPERATOR <-- THE OPERATOR

           *> LOOP THROUGH THE TRACKED FIELDS UNTIL 
           *> A NAME MATCHES THE TARGET TO FIND THE ACTUAL VALUE
           SET DUT-FIELD-NOT-FOUND TO TRUE
           PERFORM VARYING DUT-TRACE-FIELD-INDEX FROM 1 BY 1 UNTIL
              DUT-TRACE-FIELD-INDEX >
              DUT-RT-SECTION-FIELD-COUNT(DUT-TRACE-SECTION-INDEX)
                
                *>DISPLAY 'SECTION INDEX ' DUT-TRACE-SECTION-INDEX
                *>DISPLAY 'FIELD INDEX ' DUT-TRACE-FIELD-INDEX
                *>DISPLAY 'SECTION TARGET ' DUT-TEMP-SECTION-NAME
                *>DISPLAY 'FOUND FIELD ' DUT-RT-SECTION-FIELD-NAME(
                *>       DUT-TRACE-SECTION-INDEX DUT-TRACE-FIELD-INDEX)

                *>DISPLAY 'FIELD-NAME ' DUT-TEMP-FIELD-NAME
                *>DISPLAY 'FIELD EXPECTED ' DUT-TEMP-FIELD-EXPECTED
                *>DISPLAY 'DUT-FIELD-COUNT '
                *>   DUT-RT-SECTION-FIELD-COUNT(DUT-TRACE-SECTION-INDEX)
                
                
               IF DUT-TEMP-FIELD-NAME = DUT-RT-SECTION-FIELD-NAME
                  (DUT-TRACE-SECTION-INDEX DUT-TRACE-FIELD-INDEX)
                   MOVE DUT-RT-SECTION-FIELD-VALUE
                      (DUT-TRACE-SECTION-INDEX
                      DUT-TRACE-FIELD-INDEX)
                      TO DUT-TEMP-FIELD-VALUE
                   SET DUT-FIELD-FOUND TO TRUE 
                   PERFORM DUT-EVALUATE-OPERATION
                   EXIT PERFORM 

               END-IF 
           END-PERFORM
           IF NOT DUT-FIELD-FOUND
               STRING 'FATAL ERROR: '
                      'UNABLE TO FIND FIELD NAME '
                      FUNCTION TRIM(DUT-TEMP-FIELD-NAME)
                      'FOR SECTION '
                      FUNCTION TRIM(DUT-TEMP-SECTION-NAME)
                  DELIMITED BY SIZE INTO DUT-DISPLAY-ERROR-MSG
               END-STRING
               PERFORM DUT-ERROR
           END-IF
           .


      * USAGE: INTERNAL
      * DESCRIPTION: CLEARS THE EXECUTION TRACE INCLUDING WITH FIELDS
      * USUALLY DONE TO PREPARE FOR A FRESH TEST CASE
       DUT-CLEAR-TRACE SECTION.
           PERFORM VARYING DUT-TRACE-SECTION-INDEX FROM 1 BY 1 UNTIL
              DUT-TRACE-SECTION-INDEX > DUT-RT-SECTION-COUNT
              
               MOVE 1 TO DUT-RT-SECTION-FIELD-COUNT
                  (DUT-TRACE-SECTION-INDEX)
               MOVE SPACES TO
                  DUT-RT-SECTION-NAME(DUT-TRACE-SECTION-INDEX)
               PERFORM VARYING DUT-TRACE-FIELD-INDEX FROM 1 BY 1 UNTIL
                  DUT-TRACE-FIELD-INDEX >
                  DUT-RT-SECTION-FIELD-COUNT(DUT-TRACE-SECTION-INDEX)
                   MOVE SPACES TO DUT-RT-SECTION-FIELDS
                      (DUT-TRACE-SECTION-INDEX
                      DUT-TRACE-FIELD-INDEX)
               END-PERFORM
               MOVE 1 TO DUT-RT-SECTION-FIELD-COUNT
                  (
                  DUT-TRACE-SECTION-INDEX)
           END-PERFORM
           MOVE 1 TO DUT-RT-SECTION-COUNT                       
           MOVE SPACES TO DUT-TRACE
           .


      * USAGE: INTERNAL
      * DESCRIPTION: EVALUATES THE CONDITION FOR EACH FIELD VALUE IN 
      * THE WITH BLOCK, INVERTING THE RESULTS IF THE ASSERTION STATEMENT
      * IS A NOT STATEMENT
      * TODO: LESS THAN AND GREATER THAN?
      * TODO: HANDLE FIELD NAMES VS LITERALS? e.g WS-NUM-1 = WS-NUM-2
       DUT-EVALUATE-OPERATION SECTION.
           EVALUATE DUT-TEMP-FIELD-OPERATOR
           WHEN '='
               IF DUT-TEMP-FIELD-VALUE = DUT-TEMP-FIELD-EXPECTED
                   SET DUT-TEST-PASS TO TRUE 
               ELSE
                   SET DUT-TEST-FAIL TO TRUE 
               END-IF 
           WHEN '!='
               IF DUT-TEMP-FIELD-VALUE NOT = DUT-TEMP-FIELD-EXPECTED
                   SET DUT-TEST-PASS TO TRUE 
               ELSE
                   SET DUT-TEST-FAIL TO TRUE 
               END-IF 
           END-EVALUATE 


           *> IF IT'S A NOT SEARCH THEN INVERT THE RESULTS
           EVALUATE TRUE
           WHEN DUT-EXEC-TRACE-NOT AND DUT-TEST-FAIL 
               SET DUT-TEST-PASS TO TRUE 
           WHEN DUT-EXEC-TRACE-NOT AND DUT-TEST-PASS 
               SET DUT-TEST-FAIL TO TRUE
           END-EVALUATE 
               

           IF DUT-TEST-FAIL
               STRING 'OPERATION EVALUATION FAILED FOR '
                      FUNCTION TRIM(DUT-TEMP-FIELD-NAME)
                      ' ON SECTION '
                      DUT-TEMP-SECTION-NAME
                  DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
               PERFORM DUT-FAIL 
      
               STRING 'ASSERTED '
                      FUNCTION TRIM(DUT-TEMP-FIELD-NAME)
                      ' '
                      DUT-TEMP-FIELD-OPERATOR
                      ' '
                      FUNCTION TRIM(DUT-TEMP-FIELD-EXPECTED)
                  DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
               END-STRING
               PERFORM DUT-FAIL 
      
               STRING 'AND GOT '
                      FUNCTION TRIM(DUT-TEMP-FIELD-NAME)
                      ' = '
                      FUNCTION TRIM(DUT-TEMP-FIELD-VALUE)
                  DELIMITED BY SIZE INTO DUT-DISPLAY-FAIL-MSG
               END-STRING
               PERFORM DUT-FAIL
           ELSE 
               CONTINUE 
           END-IF 
           .

      *****************************************************************
      * ADD CURRENT SECTION TO THE TRACE STACK
      * THIS SECTION SHOULD BE INSTANTIATED AT THE TOP OF EACH SECTION
      * BY THE TEST PRECOMPILER
      *****************************************************************
       DUT-ADD-TRACE-SECTION SECTION.
           MOVE DUT-TEMP-SECTION-NAME TO
              DUT-RT-SECTION-NAME(DUT-RT-SECTION-COUNT)
           PERFORM DUT-TRACE-FIELDS
           ADD 1 TO DUT-RT-SECTION-COUNT
           .

      * USAGE: EXTERNAL
      * DESCRIPTION: A DEBUG SECTION THAT ALLOWS THE USER TO SEE THE 
      * RAW EXECUTION TRACE DATA
      * TODO - MAKE THIS DISPLAY LOOK NICER, PERHAPS A TABLE?
       DUT-DEBUG-DISPLAY-TRACE SECTION.
           DISPLAY 'DISPLAYING TRACE'
           *>DISPLAY 'SECTION INDEX ' DUT-TRACE-SECTION-INDEX
           PERFORM VARYING DUT-TRACE-SECTION-INDEX FROM 1 BY 1 UNTIL
              DUT-TRACE-SECTION-INDEX >= DUT-RT-SECTION-COUNT
               DISPLAY 'SECTION NAME: '
                       DUT-RT-SECTION-NAME(
                  DUT-TRACE-SECTION-INDEX)

              
               PERFORM VARYING DUT-TRACE-FIELD-INDEX FROM 1 BY 1 UNTIL
                  DUT-TRACE-FIELD-INDEX >=
                  DUT-RT-SECTION-FIELD-COUNT(DUT-TRACE-SECTION-INDEX)

                   DISPLAY 'FIELD: '
                           DUT-RT-SECTION-FIELD-NAME
                      (DUT-TRACE-SECTION-INDEX
                      DUT-TRACE-FIELD-INDEX)
                   DISPLAY 'VALUE: '
                           DUT-RT-SECTION-FIELD-VALUE
                      (DUT-TRACE-SECTION-INDEX
                      DUT-TRACE-FIELD-INDEX)

               END-PERFORM
           END-PERFORM
           .

      * USAGE: INTERNAL + EXTERNAL?
      * DESCRIPTION: THE ERROR ROUTINE, RUN WHEN A TEST CASE CANNOT 
      * COMPLETE FOR ANY REASON.
      * CURRENTLY ONLY THE DUT- FRAMEWORK USES THIS, HOWEVER PERHAPS
      * THERE IS A CASE FOR A TEST PROGRAM TO INVOKE THIS DIRECTLY
       DUT-ERROR SECTION.
           SET DUT-TEST-ERROR TO TRUE
           MOVE DUT-DISPLAY-ERROR TO DUT-OUT-RECORD
           PERFORM DUT-WRITE-UT-RECORD 
           MOVE SPACES TO DUT-DISPLAY-ERROR-MSG
           .

      * USAGE: INTERNAL + EXTERNAL
      * DESCRIPTION: THE DUT-FAIL ROUTINE RUNS WHEN AN ASSERTION HAS
      * FAILED OR WHEN THE USER WANTS TO MANUALLY FAIL A CASE BASED ON
      * A CONDITION SET IN THE TEST PROGRAM
       DUT-FAIL SECTION.
           SET DUT-TEST-FAIL TO TRUE 
           MOVE DUT-DISPLAY-FAIL TO DUT-OUT-RECORD
           PERFORM DUT-WRITE-UT-RECORD
           MOVE SPACES TO DUT-DISPLAY-FAIL-MSG
           .

      * USAGE: INTERNAL
      * DESCRIPTION: ALL CASES ARE ASSUMED TO HAVE PASSED AND ASSERTIONS 
      * FIND REASONS TO FAIL THEM
      * CURRENTLY THIS DOESN'T DO MUCH, COULD CHANGE IN THE FUTURE
       DUT-PASS SECTION.
           *> No display on DUT-PASS 
           MOVE SPACES TO DUT-DISPLAY-PASS-MSG
           .

      * USGAE: AUTO INSTRUMENT
      * DESCRIPTION: NEVER DIRECTLY INVOKED BY THE USER OR DUT-
      * THIS SECTION IS AUTO INSTRUMENTED IF A TEST CASES BEGINS WITH
      * SKIP- AND NOT TEST-
       DUT-SKIP SECTION.
           SET DUT-TEST-SKIP TO TRUE
           MOVE SPACES TO DUT-DISPLAY-SKIP-MSG 
           MOVE SPACES TO DUT-DISPLAY-PASS-MSG
           MOVE SPACES TO DUT-DISPLAY-FAIL-MSG
           PERFORM DUT-DISPLAY-TEST-CASE-NAME 
           MOVE DUT-DISPLAY-SKIP TO DUT-OUT-RECORD
           PERFORM DUT-WRITE-UT-RECORD 
           MOVE ' ' TO DUT-OUT-RECORD
           PERFORM DUT-WRITE-UT-RECORD 
           MOVE SPACES TO DUT-DISPLAY-SKIP-MSG
           ADD 1 TO DUT-TEST-SKIP-COUNT

           .


      * USAGE: AUTO INSTRUMENT
      * DESCRIPTION: NEVER DIRECTLY INVOKED BY THE USER OR DUT-, IS AUTO
      * INSTRUMENTED BY THE HARNESS TO SETUP THE DUT- TEST CASE
       DUT-TEST-INIT SECTION.
           PERFORM DUT-CLEAR-TRACE
           SET DUT-TEST-PASS TO TRUE
           MOVE SPACES TO DUT-DISPLAY-SKIP-MSG 
           MOVE SPACES TO DUT-DISPLAY-PASS-MSG
           MOVE SPACES TO DUT-DISPLAY-FAIL-MSG
           PERFORM DUT-DISPLAY-TEST-CASE-NAME 
           PERFORM BEFORE-EACH
           .

      * USAGE: INTERNAL
      * DESCRIPTION: WRITES THE UT BUFFER TO THE OUTPUT FILE
       DUT-WRITE-UT-RECORD SECTION.
           DISPLAY DUT-OUT-RECORD
           MOVE SPACES TO DUT-OUT-RECORD
           .

      * USAGE: INTERNAL
      * DESCRIPTION: CALLED DURING TEST CASE INIT TO SHOW THE CASE NAME
       DUT-DISPLAY-TEST-CASE-NAME SECTION.
           STRING 'TEST CASE - ' DUT-TEST-NAME DELIMITED BY
              SIZE INTO DUT-OUT-RECORD

           PERFORM DUT-WRITE-UT-RECORD
           EXIT SECTION
           .

      * USAGE: EXTERNAL
      * DESCRIPTION: THIS ENTIRE SECTION IS SUPPOSED TO BE CODED IN THE
      * TEST PROGRAM TO REGISTER FIELDS THAT ARE TO BE TRACED THROUGHOUT
      * EXECUTION
       DUT-TRACE-FIELDS SECTION.
           CONTINUE 
           .