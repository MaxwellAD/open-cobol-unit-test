       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-LINKPGM.
      *****************************************************************
      * TEST SUITE FOR SRC/MAIN/COBOL/SORLIB/LINKAGE-PGM.CBL
      *
      * LINKPGM IS A CALLED SUBPROGRAM - ITS INPUT AND OUTPUT LIVE IN
      * THE LINKAGE SECTION, AND ITS WORKINGS IN LOCAL-STORAGE. THE
      * HARNESS RELOCATES BOTH SECTIONS INTO STORAGE.CPY, SO THE COPY
      * STORAGE BELOW BRINGS LK- AND LS- FIELDS IN AS ORDINARY WORKING
      * STORAGE. THERE IS NO CALLER IN A TEST RUN, SO EACH CASE SETS
      * THE PARAMETERS ITSELF IN ITS GIVEN, AND BEFORE-EACH RESETS
      * THEM - THEY NO LONGER GET FRESH STORAGE PER INVOCATION.
      *
      * LK-REQUEST ARRIVES VIA COPY LKPARM, WHICH THE HARNESS MOVES
      * VERBATIM AND THE COMPILER RESOLVES FROM THE PROJECT COPYBOOK
      * LIBRARY, SRC/MAIN/COBOL/COPYLIB.
      *****************************************************************
       ENVIRONMENT DIVISION.
       COPY CUTENV.
       DATA DIVISION.
       COPY CUTDATA.
       WORKING-STORAGE SECTION.

       COPY STORAGE OF LINKAGE-PGM.
       COPY CUTSTOR.

       01 FIXTURES.
           05 FIXTURE-CUSTOMER          PIC X(20)
                                        VALUE 'ACME LIMITED'.

       PROCEDURE DIVISION.

      *****************************************************************
      * A FIELD DECLARED INLINE IN THE LINKAGE SECTION
      *****************************************************************
       TEST-PRICES-A-PLAIN-ORDER SECTION.
           *> GIVEN
           MOVE 2 TO LK-ORDER-QTY
           MOVE 10.50 TO LK-UNIT-PRICE

           *> WHEN
           PERFORM BB-CALCULATE-CHARGE

           *> THEN
           MOVE 21.00 TO CUT-ASSERT-TARGET-N
           MOVE LK-NET-AMOUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
           .

      * THE BULK DISCOUNT READS A TRUE WORKING STORAGE CONSTANT AND
      * THE QUANTITY OUT OF THE COPYBOOK HALF OF THE LINKAGE
       TEST-APPLIES-BULK-DISCOUNT SECTION.
           *> GIVEN
           MOVE 100 TO LK-ORDER-QTY
           MOVE 1.00 TO LK-UNIT-PRICE

           *> WHEN
           PERFORM BB-CALCULATE-CHARGE

           *> THEN
           MOVE 90.00 TO CUT-ASSERT-TARGET-N
           MOVE LK-NET-AMOUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
           .

      *****************************************************************
      * THE LOCAL-STORAGE WORKINGS ARE READABLE FROM A TEST CASE ONCE
      * THE HARNESS HAS FOLDED THEM INTO WORKING STORAGE
      *****************************************************************
       TEST-KEEPS-LOCAL-WORKINGS SECTION.
           *> GIVEN
           MOVE 100 TO LK-ORDER-QTY
           MOVE 1.00 TO LK-UNIT-PRICE

           *> WHEN
           PERFORM BB-CALCULATE-CHARGE

           *> THEN
           MOVE 100.00 TO CUT-ASSERT-TARGET-N
           MOVE LS-GROSS-AMOUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           MOVE 10.00 TO CUT-ASSERT-TARGET-N
           MOVE LS-DISCOUNT-AMOUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
           .

      *****************************************************************
      * CONDITION NAMES DECLARED IN THE LINKAGE SECTION STILL WORK
      *****************************************************************
       TEST-REJECTS-ZERO-QTY SECTION.
           *> GIVEN
           MOVE 0 TO LK-ORDER-QTY
           MOVE 10.50 TO LK-UNIT-PRICE

           *> WHEN
           PERFORM BA-VALIDATE-REQUEST
           PERFORM BC-BUILD-RESPONSE

           *> THEN
           MOVE '10' TO CUT-ASSERT-TARGET
           MOVE LK-RETURN-CODE TO CUT-ASSERT-ACTUAL
           PERFORM CUT-ASSERT-EQUALS

           MOVE 'ORDER QUANTITY MUST NOT BE ZERO'
              TO CUT-ASSERT-TARGET
           MOVE LK-MESSAGE TO CUT-ASSERT-ACTUAL
           PERFORM CUT-ASSERT-EQUALS

           PERFORM CUT-END-TEST
           .

       TEST-REJECTS-ZERO-PRICE SECTION.
           *> GIVEN
           MOVE 2 TO LK-ORDER-QTY
           MOVE 0 TO LK-UNIT-PRICE

           *> WHEN
           PERFORM BA-VALIDATE-REQUEST
           PERFORM BC-BUILD-RESPONSE

           *> THEN
           MOVE '20' TO CUT-ASSERT-TARGET
           MOVE LK-RETURN-CODE TO CUT-ASSERT-ACTUAL
           PERFORM CUT-ASSERT-EQUALS

           PERFORM CUT-END-TEST
           .

      *****************************************************************
      * LK-CUSTOMER-NAME COMES FROM LKPARM.CPY - A COPY MEMBER THE
      * HARNESS RELOCATED OUT OF THE LINKAGE SECTION
      *****************************************************************
       TEST-NAMES-THE-CUSTOMER SECTION.
           *> GIVEN
           MOVE FIXTURE-CUSTOMER TO LK-CUSTOMER-NAME
           MOVE 2 TO LK-ORDER-QTY
           MOVE 10.50 TO LK-UNIT-PRICE

           *> WHEN
           PERFORM BA-VALIDATE-REQUEST
           PERFORM BC-BUILD-RESPONSE

           *> THEN
           MOVE 'ORDER PRICED FOR ACME LIMITED'
              TO CUT-ASSERT-TARGET
           MOVE LK-MESSAGE TO CUT-ASSERT-ACTUAL
           PERFORM CUT-ASSERT-EQUALS

           PERFORM CUT-END-TEST
           .

      *****************************************************************
      * THE MAINLINE IS ONLY PERFORMABLE BECAUSE MOCK-BZ-RETURN-TO-
      * CALLER STANDS IN FOR THE GOBACK - SEE THE MOCK BELOW
      *****************************************************************
       TEST-MAINLINE-TRACE SECTION.
           *> GIVEN
           MOVE FIXTURE-CUSTOMER TO LK-CUSTOMER-NAME
           MOVE 2 TO LK-ORDER-QTY
           MOVE 10.50 TO LK-UNIT-PRICE

           *> WHEN
           PERFORM AA-MAINLINE

           *> THEN
           MOVE SPACES TO CUT-TRACE
           STRING 'AA-MAINLINE '
                  'DIRECTLY-FOLLOWED-BY BA-VALIDATE-REQUEST '
                  'FOLLOWED-BY BB-CALCULATE-CHARGE '
                  'FOLLOWED-BY BC-BUILD-RESPONSE '
                  'FOLLOWED-BY BZ-RETURN-TO-CALLER '
                  DELIMITED BY SIZE
                  INTO CUT-TRACE
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           MOVE 21.00 TO CUT-ASSERT-TARGET-N
           MOVE LK-NET-AMOUNT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
           .

      * A ZERO QUANTITY SHORT CIRCUITS THE PRICING
       TEST-MAINLINE-SKIPS-PRICING SECTION.
           *> GIVEN
           MOVE 0 TO LK-ORDER-QTY
           MOVE 10.50 TO LK-UNIT-PRICE

           *> WHEN
           PERFORM AA-MAINLINE

           *> THEN
           MOVE SPACES TO CUT-TRACE
           STRING 'AA-MAINLINE '
                  'FOLLOWED-BY BC-BUILD-RESPONSE '
                  'NOT FOLLOWED-BY BB-CALCULATE-CHARGE '
                  DELIMITED BY SIZE
                  INTO CUT-TRACE
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           PERFORM CUT-END-TEST
           .


      *****************************************************************
      * A LINKAGE FIELD REGISTERED IN CUT-TRACE-FIELDS IS SNAPSHOTTED
      * ON EVERY SECTION ENTRY, SO A WITH CLAUSE CAN ASSERT ON IT
      *****************************************************************
       TEST-TRACE-WITH-QTY SECTION.
           *> GIVEN
           MOVE 2 TO LK-ORDER-QTY
           MOVE 10.50 TO LK-UNIT-PRICE

           *> WHEN
           PERFORM AA-MAINLINE

           *> THEN
           MOVE SPACES TO CUT-TRACE
           STRING 'BB-CALCULATE-CHARGE '
                  'WITH '
                    'LK-ORDER-QTY = 002 '
                  'END-WITH '
                  DELIMITED BY SIZE
                  INTO CUT-TRACE
           END-STRING
           PERFORM CUT-ASSERT-TRACE

           PERFORM CUT-END-TEST
           .


       END-TEST-SUITE SECTION.
           PERFORM DISPLAY-COVERAGE
           PERFORM CUT-END-TEST-SUITE
           .


      *****************************************************************
      * RUNS AT THE TOP OF EVERY SECTION IN THE BUSINESS PROGRAM AND
      * SNAPSHOTS THE REGISTERED FIELDS INTO THE TRACE, SO A WITH
      * CLAUSE CAN ASSERT WHAT THEY HELD AT THAT MOMENT. LINKAGE
      * FIELDS REGISTER LIKE ANY OTHER FIELD ONCE RELOCATED
      *****************************************************************
       CUT-TRACE-FIELDS SECTION.
           MOVE 'LK-ORDER-QTY' TO CUT-TEMP-FIELD-NAME
           MOVE LK-ORDER-QTY TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD

           MOVE 'LK-RETURN-CODE' TO CUT-TEMP-FIELD-NAME
           MOVE LK-RETURN-CODE TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD

           EXIT SECTION
           .

      *****************************************************************
      * THE REAL SECTION IS A GOBACK. NOTHING CALLED THIS PROGRAM, SO
      * A GOBACK WOULD END THE TEST PROGRAM AND ABANDON THE REST OF
      * THE SUITE. THE EXIT SECTION IS WHAT SKIPS THE REAL BODY - THE
      * HARNESS INSERTS THE MOCK AHEAD OF IT, IT DOES NOT DELETE IT.
      *
      * KEEP COMMENTARY ABOVE THE MOCK HEADER, NOT BELOW IT - THE
      * HARNESS CAPTURES EVERY LINE AFTER THE HEADER AS PART OF THE
      * MOCK BODY UNTIL THE NEXT AREA A NAME
      *****************************************************************
       MOCK-BZ-RETURN-TO-CALLER SECTION.
           EXIT SECTION
           .

      *****************************************************************
      * RUNS BEFORE EACH TEST CASE
      * THE LINKAGE AND LOCAL-STORAGE FIELDS ARE ORDINARY WORKING
      * STORAGE IN THE GENERATED PROGRAM, SO THEY CARRY OVER FROM ONE
      * CASE TO THE NEXT UNLESS THEY ARE RESET HERE
      * DO NOT REMOVE THE EXIT SECTION OTHERWISE YOU WILL FALL INTO
      * THE BUSINESS PROGRAM
      *****************************************************************
       BEFORE-EACH SECTION.
           MOVE SPACES TO LK-CUSTOMER-NAME
           MOVE ZERO TO LK-ORDER-QTY
           MOVE ZERO TO LK-UNIT-PRICE
           MOVE SPACES TO LK-RETURN-CODE
           MOVE SPACES TO LK-MESSAGE
           MOVE ZERO TO LK-NET-AMOUNT
           MOVE ZERO TO LS-GROSS-AMOUNT
           MOVE ZERO TO LS-DISCOUNT-AMOUNT
           EXIT SECTION
           .


       COPY PROGRAM OF LINKAGE-PGM.
       COPY CUTPROC.
