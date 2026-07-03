
      * COBOL UT HELPER FUNCTIONS 
       
       CUT-END-TEST SECTION.
           EVALUATE TRUE 
           WHEN CUT-TEST-PASS
              ADD 1 TO CUT-TEST-PASS-COUNT
              MOVE CUT-DISPLAY-PASS TO UTOUT-RECORD
              PERFORM CUT-WRITE-UT-RECORD
              PERFORM CUT-PASS
           WHEN CUT-TEST-FAIL
              ADD 1 TO CUT-TEST-FAIL-COUNT
              PERFORM CUT-FAIL 
           WHEN CUT-TEST-SKIP
              *> CUT-END-TEST doesn't run if the case is SKIPPED
              CONTINUE 
           WHEN CUT-TEST-ERROR
              ADD 1 TO CUT-TEST-ERROR-COUNT
              PERFORM CUT-ERROR
           END-EVALUATE 
           PERFORM CUT-CLEAR-TRACE 
           MOVE ' ' TO UTOUT-RECORD
           PERFORM CUT-WRITE-UT-RECORD
       .
       
       CUT-END-TEST-SUITE SECTION.

           MOVE ' ' TO UTOUT-RECORD
           PERFORM CUT-WRITE-UT-RECORD
           MOVE 'TEST EXECUTION RESULTS' TO UTOUT-RECORD
           PERFORM CUT-WRITE-UT-RECORD

           MOVE CUT-TEST-PASS-COUNT TO CUT-TEST-PASS-COUNT-DISPLAY
           MOVE CUT-TEST-FAIL-COUNT TO CUT-TEST-FAIL-COUNT-DISPLAY
           MOVE CUT-TEST-SKIP-COUNT TO CUT-TEST-SKIP-COUNT-DISPLAY
           MOVE CUT-TEST-ERROR-COUNT TO CUT-TEST-ERROR-COUNT-DISPLAY
           MOVE '===================================================' TO 
                 UTOUT-RECORD
           PERFORM CUT-WRITE-UT-RECORD

           STRING 'PASS : ' FUNCTION TRIM(CUT-TEST-PASS-COUNT-DISPLAY)
           DELIMITED BY SIZE INTO UTOUT-RECORD 
           PERFORM CUT-WRITE-UT-RECORD

           STRING 'FAIL : ' FUNCTION TRIM(CUT-TEST-FAIL-COUNT-DISPLAY)
           DELIMITED BY SIZE INTO UTOUT-RECORD 
           PERFORM CUT-WRITE-UT-RECORD

           STRING 'SKIP : ' FUNCTION TRIM(CUT-TEST-SKIP-COUNT-DISPLAY)
           DELIMITED BY SIZE INTO UTOUT-RECORD 
           PERFORM CUT-WRITE-UT-RECORD

           IF CUT-TEST-ERROR-COUNT NOT = 0
            STRING 'ERROR: ' FUNCTION TRIM(CUT-TEST-ERROR-COUNT-DISPLAY)
               DELIMITED BY SIZE INTO UTOUT-RECORD
               PERFORM CUT-WRITE-UT-RECORD
           END-IF
           MOVE '===================================================' TO 
                 UTOUT-RECORD
           PERFORM CUT-WRITE-UT-RECORD
           CLOSE UTOUT 
           STOP RUN
       .

       CUT-ASSERT-TRACE SECTION.
           MOVE 1 TO CUT-TRACE-POINTER
           MOVE 0 TO CUT-TRACE-WORD-COUNT
           MOVE 1 TO CUT-TRACE-SECTION-INDEX
           
           PERFORM UNTIL CUT-TRACE-POINTER > LENGTH OF CUT-TRACE
                         OR CUT-TRACE-WORD-COUNT >= 20
              PERFORM CUT-ASSERT-TRACE-REGSTR-WORDS 
           END-PERFORM

           *> FIRST ITEM WILL ALWAYS BE A SECTION NAME

           MOVE CUT-EXEC-TRACE-WORD(1) TO CUT-TEMP-SECTION-NAME
           *> NEED TO SCAN THROUGH TRACE TO FIND FIRST SECTION NAME
           *> AND GO FROM THERE
           PERFORM CUT-FIND-FOLLOWED-BY 
           PERFORM VARYING CUT-EXEC-TRACE-INDEX FROM 2 BY 1 UNTIL 
                        CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX) = ' '
                        OR CUT-TEST-FAIL
              PERFORM CUT-ASSERT-TRACE-HANDLE-VERBS 
           END-PERFORM
           MOVE SPACES TO CUT-EXEC-TRACE-OCCURS
           .

       CUT-ASSERT-TRACE-REGSTR-WORDS SECTION.
           UNSTRING CUT-TRACE 
               DELIMITED BY ALL SPACE
               INTO CUT-TRACE-TEMP-WORD
               WITH POINTER CUT-TRACE-POINTER
           END-UNSTRING
           *>DISPLAY 'TRACE REGISTER ' CUT-TRACE-TEMP-WORD 
           IF CUT-TRACE-TEMP-WORD NOT = SPACES
               ADD 1 TO CUT-TRACE-WORD-COUNT
               MOVE CUT-TRACE-TEMP-WORD TO 
                           CUT-EXEC-TRACE-WORD(CUT-TRACE-WORD-COUNT)
           END-IF

           .

       CUT-ASSERT-TRACE-HANDLE-VERBS SECTION.
              *>DISPLAY 'TRACE ACTION ' 
              *>DISPLAY 'SECTION COUNT ' CUT-RT-SECTION-COUNT
              *>DISPLAY 'TRACE-INDEX ' CUT-EXEC-TRACE-INDEX
               *>CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX) 
           *> FOR EACH COMMAND IN CUT-EXEC-TRACE-WORD
              *> IF IT'S A FOLLOWED-BY COMMAND

              EVALUATE CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX) 
              WHEN 'FOLLOWED-BY'
                 ADD 1 TO CUT-EXEC-TRACE-INDEX
                 MOVE CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX) TO 
                                         CUT-TEMP-SECTION-NAME
                 *>DISPLAY 'SEARCHING FOR  ' CUT-TEMP-SECTION-NAME
                 PERFORM CUT-FIND-FOLLOWED-BY
              *> IF IT'S A DIRECTLY-FOLLOWED-BY COMMAND
              WHEN 'DIRECTLY-FOLLOWED-BY'
                 ADD 1 TO CUT-EXEC-TRACE-INDEX
                 MOVE CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX) TO 
                                         CUT-TEMP-SECTION-NAME
                 PERFORM CUT-FIND-DIRECTLY-FOLLOWED-BY
              *> IF IT'S A WITH COMMAND
              WHEN 'WITH'
                 PERFORM CUT-ASSERT-TRACE-HANDLE-WITH
              *> ELSE
              WHEN OTHER
                    *> MUST BE A NEW SECTION
                    MOVE CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX) 
                                            TO CUT-TEMP-SECTION-NAME
              END-EVALUATE

           . 

       CUT-ASSERT-EXPECT SECTION.
           MOVE 1 TO CUT-EXPECT-POINTER
           MOVE 0 TO CUT-EXPECT-WORD-COUNT
           
           PERFORM UNTIL CUT-EXPECT-POINTER > LENGTH OF 
                         CUT-EXPECT 
                         OR CUT-TRACE-WORD-COUNT >= 20
           
               UNSTRING CUT-EXPECT 
                   DELIMITED BY ALL SPACE
                   INTO CUT-EXPECT-TEMP-WORD
                   WITH POINTER CUT-EXPECT-POINTER
               END-UNSTRING
               *>DISPLAY 'EXPECT REGISTER: ' CUT-EXPECT-TEMP-WORD 
               IF CUT-EXPECT-TEMP-WORD NOT = SPACES
                   ADD 1 TO CUT-EXPECT-WORD-COUNT
                   MOVE CUT-EXPECT-TEMP-WORD TO 
                           CUT-EXPECT-WORD(CUT-EXPECT-WORD-COUNT)
               END-IF
           END-PERFORM
       .

       CUT-ASSERT-TRACE-HANDLE-WITH SECTION.
           *> GET THE FIELD AND BEING LOOPING FOR EACH FIELD
           *> UNTIL END-WITH
           ADD 1 TO CUT-EXEC-TRACE-INDEX
           *>DISPLAY 'EXEC INDEX' CUT-EXEC-TRACE-INDEX
           *> SHOULD ALWAYS BE IN ORDER
           *> WS-FIELD
           *> <OPERATOR>
           *> VALUE
           PERFORM VARYING CUT-EXEC-TRACE-INDEX FROM 
                           CUT-EXEC-TRACE-INDEX BY 1
              UNTIL CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX)
               = 'END-WITH'
              *>DISPLAY 'EXEC INDEX' CUT-EXEC-TRACE-INDEX
              MOVE CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX) TO 
                                      CUT-TEMP-FIELD-NAME
              ADD 1 TO CUT-EXEC-TRACE-INDEX
              MOVE CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX) TO 
                                      CUT-TEMP-FIELD-OPERATOR
              ADD 1 TO CUT-EXEC-TRACE-INDEX
              MOVE CUT-EXEC-TRACE-WORD(CUT-EXEC-TRACE-INDEX) TO 
                                      CUT-TEMP-FIELD-EXPECTED
              PERFORM CUT-FIND-WITH-IN-TRACE
           END-PERFORM 
              *> UNTIL END-WITH IS FOUND IN COMMAND
       .
          
       *> General assertion statement
       *> A check is done to see if the numeric fields were populated
       *> before invoking this section. if they were, then throw an
       *> error on the test case as this is likely incorrect
       *> TARGET-N and ACTUAL-N are for CUT-ASSERT-EQUALS-NUM 
       CUT-ASSERT-EQUALS SECTION.
           IF CUT-ASSERT-TARGET-N NOT = 0
              STRING 'USE CUT-ASSERT-EQUALS-NUM TO EVALUATE NUMBERS'
                     DELIMITED BY SIZE INTO CUT-DISPLAY-ERROR-MSG
              END-STRING
              PERFORM CUT-ERROR
           ELSE
               IF CUT-ASSERT-TARGET = CUT-ASSERT-ACTUAL
                   PERFORM CUT-PASS 
               ELSE
                   SET CUT-TEST-FAIL TO TRUE 
                   STRING
                       'Expected "' 
                     FUNCTION TRIM(CUT-ASSERT-TARGET)
                       '" but got "'
                    FUNCTION TRIM (CUT-ASSERT-ACTUAL) 
                       '"'
                       DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
                   END-STRING
                   PERFORM CUT-FAIL
               END-IF
           END-IF 
           MOVE SPACES TO CUT-ASSERT-TARGET
                          CUT-ASSERT-ACTUAL
       .      

       
       *> Use this when working with numerics of high precision or with
       *> Decimal places
       *> Will default to 2 decimal places of precision unless 
       *> that causes the output to display Expected X but got X where
       *> X is identical
       *> TODO revisit this, perhaps a better rounding / post decimal
       *> point z supression would be better
       CUT-ASSERT-EQUALS-NUM SECTION.
           IF CUT-ASSERT-TARGET-N = CUT-ASSERT-ACTUAL-N
               PERFORM CUT-PASS
           ELSE
               SET CUT-TEST-FAIL TO TRUE
               PERFORM CUT-ASSERT-EQUALS-NUM-FAIL
               PERFORM CUT-FAIL 
           END-IF 
           MOVE ZEROS TO CUT-ASSERT-TARGET-DIS-N-LONG
                         CUT-ASSERT-ACTUAL-DIS-N-LONG
                         CUT-ASSERT-TARGET-N
                         CUT-ASSERT-ACTUAL-N
       .

       CUT-ASSERT-EQUALS-NUM-FAIL SECTION.
           MOVE CUT-ASSERT-TARGET-N TO 
                                  CUT-ASSERT-TARGET-DIS-N
           MOVE CUT-ASSERT-ACTUAL-N TO 
                                  CUT-ASSERT-ACTUAL-DIS-N
           IF CUT-ASSERT-TARGET-DIS-N = CUT-ASSERT-ACTUAL-DIS-N
               *> This means a rounding error has happened
               *> Fallback to long number display
               PERFORM CUT-HANDLE-DIS-ROUND-ERROR
           ELSE 
               STRING
                   'Expected ' 
                   FUNCTION TRIM(CUT-ASSERT-TARGET-DIS-N)
                   ' but got '
                   FUNCTION TRIM (CUT-ASSERT-ACTUAL-DIS-N) 
                   DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
               END-STRING
           END-IF
       .

       CUT-HANDLE-DIS-ROUND-ERROR SECTION.

           MOVE CUT-ASSERT-TARGET-N TO 
                            CUT-ASSERT-TARGET-DIS-N-LONG
           MOVE CUT-ASSERT-ACTUAL-N TO 
                            CUT-ASSERT-ACTUAL-DIS-N-LONG
           STRING
               'Expected ' 
             FUNCTION TRIM(CUT-ASSERT-TARGET-DIS-N-LONG)
               ' but got '
            FUNCTION TRIM (CUT-ASSERT-ACTUAL-DIS-N-LONG) 
               DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
           END-STRING
       .

       CUT-REGISTER-FIELD SECTION.
           MOVE CUT-RT-SECTION-COUNT TO CUT-TRACE-SECTION-INDEX
           MOVE CUT-RT-SECTION-FIELD-COUNT(CUT-RT-SECTION-COUNT) TO
                                                CUT-TRACE-FIELD-INDEX
           MOVE CUT-TEMP-FIELD-NAME TO 
           CUT-RT-SECTION-FIELD-NAME(CUT-TRACE-SECTION-INDEX
           CUT-TRACE-FIELD-INDEX)
           MOVE CUT-TEMP-FIELD-VALUE TO
           CUT-RT-SECTION-FIELD-VALUE(CUT-TRACE-SECTION-INDEX
           CUT-TRACE-FIELD-INDEX)

           *> Advance the index
           ADD 1 TO CUT-RT-SECTION-FIELD-COUNT(CUT-TRACE-SECTION-INDEX)
           MOVE CUT-RT-SECTION-FIELD-COUNT(CUT-RT-SECTION-COUNT) TO 
              CUT-TRACE-FIELD-INDEX

       .


       CUT-FIND-FOLLOWED-BY SECTION.
           *> CUT-TEMP-SECTION-NAME <-- THE TARGET SECTION
           *> CUT-RT-SECTION-NAME(index) <-- LIST OF SECTIONS
           *> CUT-TRACE-SECTION-INDEX <-- INDEX OF THE SECTION TRACE

           SET CUT-SECTION-NOT-FOUND TO TRUE
           PERFORM VARYING CUT-TRACE-SECTION-INDEX FROM
                                    CUT-TRACE-SECTION-INDEX  BY 1 UNTIL 
                           CUT-SECTION-FOUND OR 
                         CUT-TRACE-SECTION-INDEX > CUT-RT-SECTION-COUNT
              *>DISPLAY 'FOUND SECTION: ' 
              *>CUT-RT-SECTION-NAME(CUT-TRACE-SECTION-INDEX)
              IF CUT-TEMP-SECTION-NAME = 
                 CUT-RT-SECTION-NAME(CUT-TRACE-SECTION-INDEX)
                 SET CUT-SECTION-FOUND TO TRUE
                 *> WE FOUND THE SECTION, LEAVE THE PERFORM  
                 *> PRE-EMTIVELY SUBTRACT 1 FROM THE INDEX TO COUNTER
                 *> THE ADD AT THE END OF THE PERFORM
                 *> SUBTRACT 1 FROM CUT-TRACE-SECTION-INDEX
                 EXIT PERFORM 
              END-IF
           END-PERFORM
           
           *> IF WE RAN OFF THE END THEN THE SECTION WASN'T IN THE TRACE
           IF CUT-SECTION-NOT-FOUND
              SET CUT-TEST-FAIL TO TRUE 
              STRING 'UNABLE TO FIND '
                     FUNCTION TRIM(CUT-TEMP-SECTION-NAME)
                     ' IN EXECUTION TRACE'
                     DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
              END-STRING
              PERFORM CUT-FAIL
           ELSE
              STRING 'FOUND SECTION ' 
              FUNCTION TRIM(CUT-TEMP-SECTION-NAME)
              ' IN EXECUTION TRACE'
              DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
              END-STRING
           END-IF
       .

       CUT-FIND-DIRECTLY-FOLLOWED-BY SECTION.
           *> CUT-TEMP-SECTION-NAME <-- THE TARGET SECTION
           *> CUT-RT-SECTION-NAME(index) <-- LIST OF SECTIONS
           *> CUT-TRACE-SECTION-INDEX <-- INDEX OF THE SECTION TRACE

           SET CUT-SECTION-NOT-FOUND TO TRUE
           *>DISPLAY 'FOUND SECTION: ' 
           *>CUT-RT-SECTION-NAME(CUT-TRACE-SECTION-INDEX)
           ADD 1 TO CUT-TRACE-SECTION-INDEX 
           IF CUT-TEMP-SECTION-NAME = 
              CUT-RT-SECTION-NAME(CUT-TRACE-SECTION-INDEX)
              SET CUT-SECTION-FOUND TO TRUE
              *> WE FOUND THE SECTION, LEAVE THE PERFORM  
              *> PRE-EMTIVELY SUBTRACT 1 FROM THE INDEX TO COUNTER
              *> THE ADD AT THE END OF THE PERFORM
              *> SUBTRACT 1 FROM CUT-TRACE-SECTION-INDEX
           END-IF
           
           *> IF WE RAN OFF THE END THEN THE SECTION WASN'T IN THE TRACE
           IF CUT-SECTION-NOT-FOUND
              SET CUT-TEST-FAIL TO TRUE 
              STRING 'UNABLE TO FIND '
                     FUNCTION TRIM(CUT-TEMP-SECTION-NAME)
                     ' DIRECTLY AFTER '
                     FUNCTION TRIM(CUT-RT-SECTION-NAME(
                                         CUT-TRACE-SECTION-INDEX))
                     ' IN EXECUTION TRACE'
                     DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
              END-STRING
              PERFORM CUT-FAIL
           ELSE
              STRING 'FOUND SECTION ' 
              FUNCTION TRIM(CUT-TEMP-SECTION-NAME)
              ' IN EXECUTION TRACE'
              DELIMITED BY SIZE INTO CUT-DISPLAY-PASS-MSG 
              END-STRING
           END-IF
       .

       CUT-FIND-WITH-IN-TRACE SECTION.
           *> USED TO SEARCH
           *> CUT-TRACE-SECTION-INDEX <-- INDEX OF THE TARGET SECTION
           *> v FIELD NAME(S) AT THIS SECTION
           *> CUT-RT-SECTION-FIELD-NAME(CUT-TRACE-SECTION-INDEX index)
           *> v FIELD VALUE(S) AT THIS SECTION (CAST TO CHARACTER)
           *> CUT-RT-SECTION-FIELD-VALUE(CUT-TRACE-SECTION-INDEX index)
           
           *> KNOWNS
           *> CUT-TEMP-FIELD-VALUE <-- ACTUAL VALUE (NEED TO FIND)
           *> CUT-TEMP-FIELD-EXPECTED <-- EXPECTED VALUE
           *> CUT-TEMP-FIELD-NAME <-- FIELD NAME TO FIND
           *> CUT-TEMP-FIELD-OPERATOR <-- THE OPERATOR

           *> LOOP THROUGH THE TRACKED FIELDS UNTIL 
           *> A NAME MATCHES THE TARGET TO FIND THE ACTUAL VALUE
           SET CUT-FIELD-NOT-FOUND TO TRUE
           PERFORM VARYING CUT-TRACE-FIELD-INDEX FROM 1 BY 1 UNTIL 
                             CUT-TRACE-FIELD-INDEX >
                     CUT-RT-SECTION-FIELD-COUNT(CUT-TRACE-SECTION-INDEX)
                
                *>DISPLAY 'SECTION INDEX ' CUT-TRACE-SECTION-INDEX
                *>DISPLAY 'FIELD INDEX ' CUT-TRACE-FIELD-INDEX
                *>DISPLAY 'SECTION TARGET ' CUT-TEMP-SECTION-NAME
                *>DISPLAY 'FOUND FIELD ' CUT-RT-SECTION-FIELD-NAME(
                *>       CUT-TRACE-SECTION-INDEX CUT-TRACE-FIELD-INDEX)

                *>DISPLAY 'FIELD-NAME ' CUT-TEMP-FIELD-NAME
                *>DISPLAY 'FIELD EXPECTED ' CUT-TEMP-FIELD-EXPECTED
                *>DISPLAY 'CUT-FIELD-COUNT '
                *>   CUT-RT-SECTION-FIELD-COUNT(CUT-TRACE-SECTION-INDEX)
                
                
                IF CUT-TEMP-FIELD-NAME = CUT-RT-SECTION-FIELD-NAME(
                       CUT-TRACE-SECTION-INDEX CUT-TRACE-FIELD-INDEX)
                    MOVE CUT-RT-SECTION-FIELD-VALUE(
                                               CUT-TRACE-SECTION-INDEX 
                                               CUT-TRACE-FIELD-INDEX) 
                    TO CUT-TEMP-FIELD-VALUE
                    SET CUT-FIELD-FOUND TO TRUE 
                    PERFORM CUT-EVALUATE-OPERATION
                    EXIT PERFORM 

                END-IF 
           END-PERFORM
           IF NOT CUT-FIELD-FOUND
              STRING 'FATAL ERROR: '
                     'UNABLE TO FIND FIELD NAME '
                     FUNCTION TRIM(CUT-TEMP-FIELD-NAME)
                     'FOR SECTION '
                     FUNCTION TRIM(CUT-TEMP-SECTION-NAME)
                     DELIMITED BY SIZE INTO CUT-DISPLAY-ERROR-MSG
              END-STRING
              PERFORM CUT-ERROR
           END-IF
       .

       CUT-CLEAR-TRACE SECTION.
           PERFORM VARYING CUT-TRACE-SECTION-INDEX FROM 1 BY 1 UNTIL 
                          CUT-TRACE-SECTION-INDEX > CUT-RT-SECTION-COUNT
              
              MOVE 1 TO CUT-RT-SECTION-FIELD-COUNT(
               CUT-TRACE-SECTION-INDEX)
              MOVE SPACES TO
                           CUT-RT-SECTION-NAME(CUT-TRACE-SECTION-INDEX)
               PERFORM VARYING CUT-TRACE-FIELD-INDEX FROM 1 BY 1 UNTIL 
               CUT-TRACE-FIELD-INDEX > 
               CUT-RT-SECTION-FIELD-COUNT(CUT-TRACE-SECTION-INDEX)
                   MOVE SPACES TO CUT-RT-SECTION-FIELDS(
                     CUT-TRACE-SECTION-INDEX 
                     CUT-TRACE-FIELD-INDEX 
                   )
               END-PERFORM
               MOVE 1 TO CUT-RT-SECTION-FIELD-COUNT(
                  CUT-TRACE-SECTION-INDEX)
           END-PERFORM
           MOVE 1 TO CUT-RT-SECTION-COUNT                       
           MOVE SPACES TO CUT-TRACE
       .



      * TODO: LESS THAN AND GREATER THAN?
      * TODO: HANDLE FIELD NAMES VS LITERALS? e.g WS-NUM-1 = WS-NUM-2
       CUT-EVALUATE-OPERATION SECTION.
           EVALUATE CUT-TEMP-FIELD-OPERATOR
           WHEN '='
              IF CUT-TEMP-FIELD-VALUE = CUT-TEMP-FIELD-EXPECTED
                 CONTINUE
              ELSE
                 SET CUT-TEST-FAIL TO TRUE 
              END-IF 
           WHEN '!='
              IF CUT-TEMP-FIELD-VALUE NOT = CUT-TEMP-FIELD-EXPECTED
                 CONTINUE
              ELSE
                 SET CUT-TEST-FAIL TO TRUE 
              END-IF 
           END-EVALUATE 


           IF CUT-TEST-FAIL
              STRING 'OPERATION EVALUATION FAILED FOR ' 
                     FUNCTION TRIM(CUT-TEMP-FIELD-NAME)
                     ' ON SECTION '
                     CUT-TEMP-SECTION-NAME
              DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
              PERFORM CUT-FAIL 
      
              STRING 'EXPECTED ' 
                      FUNCTION TRIM(CUT-TEMP-FIELD-NAME)
                      ' '
                      CUT-TEMP-FIELD-OPERATOR
                      ' '
                      FUNCTION TRIM(CUT-TEMP-FIELD-EXPECTED)
                      DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
              END-STRING
              PERFORM CUT-FAIL 
      
              STRING 'BUT GOT '
                     FUNCTION TRIM(CUT-TEMP-FIELD-NAME)
                     ' = '
                     FUNCTION TRIM(CUT-TEMP-FIELD-VALUE)
                     DELIMITED BY SIZE INTO CUT-DISPLAY-FAIL-MSG
              END-STRING
              PERFORM CUT-FAIL
           ELSE 
              CONTINUE 
           END-IF 
       .

      *****************************************************************
      * ADD CURRENT SECTION TO THE TRACE STACK
      * THIS SECTION SHOULD BE INSTANTIATED AT THE TOP OF EACH SECTION
      * BY THE TEST PRECOMPILER
      *****************************************************************
       CUT-ADD-TRACE-SECTION SECTION.
           MOVE CUT-TEMP-SECTION-NAME TO 
                             CUT-RT-SECTION-NAME(CUT-RT-SECTION-COUNT)
           PERFORM CUT-TRACE-FIELDS
           ADD 1 TO CUT-RT-SECTION-COUNT
       .

       CUT-DEBUG-DISPLAY-TRACE SECTION.
           DISPLAY 'DISPLAYING TRACE'
           *>DISPLAY 'SECTION INDEX ' CUT-TRACE-SECTION-INDEX
           PERFORM VARYING CUT-TRACE-SECTION-INDEX FROM 1 BY 1 UNTIL 
                         CUT-TRACE-SECTION-INDEX >= CUT-RT-SECTION-COUNT
              DISPLAY 'SECTION NAME: ' CUT-RT-SECTION-NAME(
                       CUT-TRACE-SECTION-INDEX)

              
              PERFORM VARYING CUT-TRACE-FIELD-INDEX  FROM 1 BY 1 UNTIL 
                          CUT-TRACE-FIELD-INDEX >= 
                     CUT-RT-SECTION-FIELD-COUNT(CUT-TRACE-SECTION-INDEX)

                 DISPLAY 'FIELD: ' CUT-RT-SECTION-FIELD-NAME(
                                            CUT-TRACE-SECTION-INDEX
                                            CUT-TRACE-FIELD-INDEX)
                 DISPLAY 'VALUE: ' CUT-RT-SECTION-FIELD-VALUE(
                           CUT-TRACE-SECTION-INDEX
                           CUT-TRACE-FIELD-INDEX)

              END-PERFORM
           END-PERFORM
       .

       CUT-ERROR SECTION.
           SET CUT-TEST-ERROR TO TRUE
           MOVE CUT-DISPLAY-ERROR TO UTOUT-RECORD
           PERFORM CUT-WRITE-UT-RECORD 
           MOVE SPACES TO CUT-DISPLAY-ERROR-MSG
       .

       CUT-FAIL SECTION.
           SET CUT-TEST-FAIL TO TRUE 
           MOVE CUT-DISPLAY-FAIL TO UTOUT-RECORD
           PERFORM CUT-WRITE-UT-RECORD
           MOVE SPACES TO CUT-DISPLAY-FAIL-MSG
       .

       CUT-PASS SECTION.
           *> No display on CUT-PASS 
           MOVE SPACES TO CUT-DISPLAY-PASS-MSG
       .

       CUT-SKIP SECTION.
           SET CUT-TEST-SKIP TO TRUE
           MOVE SPACES TO CUT-DISPLAY-SKIP-MSG 
           MOVE SPACES TO CUT-DISPLAY-PASS-MSG
           MOVE SPACES TO CUT-DISPLAY-FAIL-MSG
           PERFORM CUT-DISPLAY-TEST-CASE-NAME 
           MOVE CUT-DISPLAY-SKIP TO UTOUT-RECORD
           PERFORM CUT-WRITE-UT-RECORD 
           MOVE ' ' TO UTOUT-RECORD
           PERFORM CUT-WRITE-UT-RECORD 
           MOVE SPACES TO CUT-DISPLAY-SKIP-MSG
           ADD 1 TO CUT-TEST-SKIP-COUNT

       .

       CUT-TEST-INIT SECTION.
           PERFORM CUT-CLEAR-TRACE
           SET CUT-TEST-PASS TO TRUE
           MOVE SPACES TO CUT-DISPLAY-SKIP-MSG 
           MOVE SPACES TO CUT-DISPLAY-PASS-MSG
           MOVE SPACES TO CUT-DISPLAY-FAIL-MSG
           PERFORM CUT-DISPLAY-TEST-CASE-NAME 
           PERFORM BEFORE-EACH
       .

       CUT-WRITE-UT-RECORD SECTION.
           WRITE UTOUT-RECORD
           MOVE SPACES TO UTOUT-RECORD
       .

       CUT-DISPLAY-TEST-CASE-NAME SECTION.
           STRING 'TEST CASE - ' CUT-TEST-NAME DELIMITED BY 
           SIZE INTO UTOUT-RECORD

           PERFORM CUT-WRITE-UT-RECORD
           EXIT SECTION
       .
