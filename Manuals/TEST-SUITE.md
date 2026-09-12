# TEST-SUITE User Manual

## Description
Under construction - will document the test program as a whole

## The Structure of a Test Suite

Test suites follow this skelton
```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. <NAME>.
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
       PROCEDURE DIVISION.
       
       BEFORE-ALL SECTION.
           *> THIS SECTION RUNS ONCE AT THE START OF THE TEST SUITE
           CONTINUE 
       .

       TEST-MY-FIRST-TEST-CASE SECTION.
           *> A COMMENT FOR MY FIRST TEST CASE
       
           *> GIVEN
           
       
           *> WHEN
           
           
           *> THEN
           
       
           PERFORM CUT-END-TEST 
       .

       *> A NUMBER OF TEST CASES

       END-TEST-SUITE SECTION.
      * DISPLAY-COVERAGE ONLY EXISTS WHEN THE COVERAGE PRECOMPILER HAS
      * RUN. THE GUARD REMOVES THE PERFORM AT COMPILE TIME OTHERWISE,
      * SO ONE SOURCE BUILDS BOTH WITH AND WITHOUT COVERAGE.
      * >>IF COVERAGE DEFINED
           PERFORM DISPLAY-COVERAGE
      * >>END-IF
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

           MOVE 'EXAMPLE-FIELD-NAME' TO CUT-TEMP-FIELD-NAME 
           MOVE EXAMPLE-FIELD-NAME TO CUT-TEMP-FIELD-VALUE 
           PERFORM CUT-REGISTER-FIELD 
           CONTINUE
       .

       MOCK-EXAMPLE-BUSINESS-SECTION SECTION.
           DISPLAY 'THIS MOCKS THE EXAMPLE-BUSINESS-SECTION SECTION'
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

       *> ANY FIXTURES / HELPERS CAN GO HERE

       COPY CUTPROC.
       COPY PROGRAM.

```

The copybooks starting with `CUT` should always be included are a part of the unit test framework
1. CUTENV
2. CUTDATA
3. CUTSTOR
4. CUTPROC


Other copybooks in the DATA DIVISION are the harness representation of the fields used in your business program and change dynamically as you update and recompile your code. Note these files should only be modified by the harness.
1. FILECTL
2. FILESEC
3. STORAGE


`COPY PROGRAM` is the harness representation of your business program PROCEDURE DIVISION. Containing all paragraphs and sections allowing you to perform them

It is adviseable to put CUTPROC first in case your business PROCEDURE DIVISION runs off the end of its file. If your business program does exit this way and it comes first it will fall into CUTPROC, which will promptly exit the test suite


### How TEST SUITES Execute and GO TO Support

Unit test programs use fall through processing, while not generally reccomended for modern COBOL development, it provides a number of benefits for unit testing
1. This style of execution reflects how other language unit tests libraries execute their tests top to bottom order
2. Tests just have to be defined and not manually invoked
3. The unit test framework can handle GO TOs

GO TOs are generally not reccomended to be coded in modern COBOL but they may be found in existing programs that don't have the budget for large refactors.

The unit test framework can *support* GO TOs in a business program, but you'll need clever mocking and a return paragraph inside your test case.

#### A Calculator Example

In your business program there may be:
```cobol
       ADD-NUMBERS SECTION.
           COMPUTE WS-RESULT = WS-NUM-1 + WS-NUM-2 
           GO TO EXIT-PROGRAM  
       .

       EXIT-PROGRAM SECTION.
           DISPLAY 'EXITING PROGRAM'
           STOP RUN
       .   
```
Which would ordinarily make `ADD-NUMBERS` un-testable as running that GO TO breaks any chance of returning to the TEST SUITE execution

In your test program you can code the following test case
```cobol
       TEST-CALC-WITH-GO-TO SECTION.
           *> THIS IS AN EXAMPLE OF HANDLING GO TO STATEMENTS
       
           *> GIVEN
           MOVE 1 TO WS-NUM-1
           MOVE 1 TO WS-NUM-2
       
           *> WHEN
           PERFORM ADD-NUMBERS.
           
       HANDLE-GO-TO-RETURN.
           
           *> THEN
           MOVE 3 TO CUT-ASSERT-TARGET-N 
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N 
           PERFORM CUT-ASSERT-EQUALS-NUM 
       
           PERFORM CUT-END-TEST 
       .
```

With a mock that looks like
```cobol
       MOCK-EXIT-PROGRAM SECTION.
           DISPLAY 'INTERCEPTED EXIT PROGRAM'
           GO TO HANDLE-GO-TO-RETURN
       .
```

So during test execution, ADD-NUMBERS goes to EXIT-PROGRAM which has been MOCKED to GO TO the HANDLE-GO-TO-RETURN paragraph, which drops the execution right back in the test case ready to assert the result


Which outputs
```
Discovered source file: src/main/cobol/sorlib/calculator/calc-with-goto.cbl
    Found test program: src/test/cobol/testlib/calculator/calc-with-goto/calc-test.cbl

Instrumenting Code Coverage
===================================================

Running the harness
===================================================

Compile
===================================================
<command-line>: warning: "_FORTIFY_SOURCE" redefined
<command-line>: note: this is the location of the previous definition

Execute
===================================================

TEST CASE - TEST-CALC-WITH-GO-TO
[FAIL] Expected 3.00 but got 2.00
[FAIL]



TEST EXECUTION RESULTS
===================================================
PASS : 0
FAIL : 1
SKIP : 0
===================================================
```

If a GO TO section is used in multiple test cases (such as a standard exit routine) you will need to conditionally GO TO different return paragraph depending on the specific test which is being executed. The test case name is exposed as `CUT-TEST-NAME`

## Special Sections

### BEFORE-ALL
This section runs before all test cases, use it for 1 time setup

### BEFORE-EACH
This section runs before each test case, use it to setup standard test data that every test case will need

### CUT-END-TEST-SUITE
This section formally ends all test execution, this is where the code coverage is reported and the result of the entire test suite is evaluated

### CUT-TRACE-FIELDS
This section is used to trace fields through execution, these fields can then be exposed by the CUT-DEBUG-DISPLAY-TRACE table

Or by the CUT-ASSERT-TRACE