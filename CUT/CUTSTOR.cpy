      * COBOL UT WORKING STORAGE
      
      * SPDX-License-Identifier: GPL-3.0-or-later
      * SPDX-FileCopyrightText: 2026 MaxwellAD
       01 CUT-DATA.
           05 CUT-MESSAGE               PIC X(100).
           05 CUT-TEST-NAME             PIC X(100).
           05 CUT-TEST-PASS-COUNT       PIC 9(9).
           05 CUT-TEST-PASS-COUNT-DISPLAY
                                        PIC Z(8)9.
           05 CUT-TEST-FAIL-COUNT       PIC 9(9).
           05 CUT-TEST-ERROR-COUNT      PIC 9(9).
           05 CUT-TEST-FAIL-COUNT-DISPLAY
                                        PIC Z(8)9.
           05 CUT-TEST-SKIP-COUNT-DISPLAY
                                        PIC Z(8)9.
           05 CUT-TEST-ERROR-COUNT-DISPLAY
                                        PIC Z(8)9.
           05 CUT-TEST-SKIP-COUNT       PIC 9(9).
           05 CUT-TEST-STATUS           PIC X(1)       VALUE 'F'.
               88 CUT-TEST-FAIL                        VALUE 'F'.
               88 CUT-TEST-PASS                        VALUE 'P'.
               88 CUT-TEST-SKIP                        VALUE 'S'.
               88 CUT-TEST-ERROR                       VALUE 'E'.
           05 CUT-SECTION-SEARCH-STATUS PIC X.
               88 CUT-SECTION-FOUND                    VALUE 'Y'.
               88 CUT-SECTION-NOT-FOUND                VALUE 'N'.
           05 CUT-FIELD-SEARCH-STATUS   PIC X.
               88 CUT-FIELD-FOUND                      VALUE 'Y'.
               88 CUT-FIELD-NOT-FOUND                  VALUE 'N'.

       01 CUT-DISPLAYS.
           05 CUT-DISPLAY-FAIL.
               10 FILLER                PIC X(7)       VALUE '[FAIL] '.
               10 CUT-DISPLAY-FAIL-MSG  PIC X(150).
           05 CUT-DISPLAY-PASS.
               10 FILLER                PIC X(7)       VALUE '[PASS] '.
               10 CUT-DISPLAY-PASS-MSG  PIC X(150).
           05 CUT-DISPLAY-SKIP.
               10 FILLER                PIC X(7)       VALUE '[SKIP] '.
               10 CUT-DISPLAY-SKIP-MSG  PIC X(150).
           05 CUT-DISPLAY-INFO.
               10 FILLER                PIC X(7)       VALUE '[INFO] '.
               10 CUT-DISPLAY-INFO-MSG  PIC X(150).
           05 CUT-DISPLAY-WARN.
               10 FILLER                PIC X(7)       VALUE '[WARN] '.
               10 CUT-DISPLAY-WARN-MSG  PIC X(150).
           05 CUT-DISPLAY-ERROR.
               10 FILLER                PIC X(8)       VALUE '[ERROR] '.
               10 CUT-DISPLAY-ERROR-MSG PIC X(150).


       01 CUT-EXEC-TRACE.
           05 CUT-TRACE                 PIC X(1000).
                                     *> THE ACTUAL COMMAND
           05 CUT-TRACE-WORD-COUNT      PIC 9(2)       VALUE 0. 
           05 CUT-TRACE-TEMP-WORD       PIC X(31)      VALUE SPACES.
           05 CUT-TRACE-POINTER         PIC 9(4) COMP  VALUE 1.
           05 CUT-TRACE-FIELD-INDEX     PIC 9(3)       VALUE 1.
           05 CUT-TRACE-SECTION-INDEX   PIC 9(3)       VALUE 1.
           *> BELOW IS NEEDED TO DO A GHOST LOOKAHEAD ON NOT FOLLOWED-BY
           05 CUT-TRACE-SECTION-INDEX-MEM
                                        PIC 9(3)       VALUE 1.
           05 CUT-TEMP-SECTION-NAME     PIC X(30)      VALUE SPACES.
           05 CUT-TEMP-FIELD-NAME       PIC X(30)      VALUE SPACES.
           05 CUT-TEMP-FIELD-VALUE      PIC X(30)      VALUE SPACES.
           05 CUT-TEMP-FIELD-EXPECTED   PIC X(30)      VALUE SPACES.
           05 CUT-TEMP-FIELD-OPERATOR   PIC X(2)       VALUE SPACES.
           05 CUT-RT-SECTION-COUNT      PIC 9(3)       VALUE 1.
           05 CUT-EXEC-TRACE-INDEX      PIC 9(3)       VALUE 1.
                                                     *> ITERATE EXEC CMD
           05 CUT-EXEC-TRACE-NOT-FLAG   PIC X(1)       VALUE 'N'.
               88 CUT-EXEC-TRACE-NOT                   VALUE 'Y'.
               88 CUT-EXEC-TRACE-NORMAL                VALUE 'N'.
           05 CUT-EXEC-TRACE-OCCURS. *> THE COMMAND SPLIT INTO WORDS
               10 CUT-EXEC-TRACE-WORD   PIC X(30) OCCURS 50 TIMES.

           05 CUT-RT-TRACE OCCURS 100 TIMES. *> UP TO 100 SECTIONS
               10 CUT-RT-SECTION-NAME   PIC X(30)      VALUE SPACES.
               10 CUT-RT-SECTION-FIELD-COUNT
                                        PIC 9(3)       VALUE 1.
               10 CUT-RT-SECTION-FIELDS OCCURS 100 TIMES.*> UP TO 100
                                                  *> FIELDS PER SECTION
                   15 CUT-RT-SECTION-FIELD-NAME
                                        PIC X(30)      VALUE SPACES.
                   15 CUT-RT-SECTION-FIELD-VALUE
                                        PIC X(30)      VALUE SPACES.
       
       
       01 CUT-FILED-EXPECT.
           05 CUT-FIELDS-TO-TRACE       PIC X(1000).
           05 CUT-EXPECT                PIC X(1000).
           05 CUT-EXPECT-WORD-COUNT     PIC 9(2)       VALUE 0. 
           05 CUT-EXPECT-TEMP-WORD      PIC X(31).
           05 CUT-EXPECT-POINTER        PIC 9(4) COMP  VALUE 1.
           05 CUT-EXPECT-OCCURS.
               10 CUT-EXPECT-WORD       PIC X(30) OCCURS 50 TIMES.      


       01 CUT-ASSERT-FIELDS.
           05 CUT-ASSERT-TARGET         PIC X(256)     VALUE SPACES. 
           05 CUT-ASSERT-ACTUAL         PIC X(256)     VALUE SPACES.
           05 CUT-ASSERT-TARGET-N       PIC 9(18)V9(18).
           05 CUT-ASSERT-ACTUAL-N       PIC 9(18)V9(18).
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

           05 CUT-ASSERT-TARGET-DIS-N   PIC Z(34)9.99.
           05 CUT-ASSERT-ACTUAL-DIS-N   PIC Z(34)9.99.

           *> If the above gets a rounding error then fallback to these
           *> fields which are less pretty but provide the full context
           05 CUT-ASSERT-TARGET-DIS-N-LONG
                                        PIC Z(17)9.9(18).
           05 CUT-ASSERT-ACTUAL-DIS-N-LONG
                                        PIC Z(17)9.9(18).
