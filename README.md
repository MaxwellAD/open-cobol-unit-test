# Open COBOL Unit Test

An open source COBOL Unit Test library

Allows the user to execute COBOL sections and paragraphs in a unit test environment

# Why
The ability to isolate test cases down to the scale of sections and paragraphs enables:
- **Faster execution:** Running a unit test should take milliseconds
- **Immediate feedback:** When integrated into the compile step, developers catch bugs as soon as they appear
- **Precise isolation:** Bugs that do happen have their exact scenario documented
- **More deterministic results:** Zero external file, database or API dependancies
- **Code structure improvements:** Baddly written code and mono-paragraphs are difficult to unit test without refactoring
- **Higher code coverage:** Far easier to get deep into complex logic to test edge cases
- **Higher quality assurance:** Code based unit tests are cheap, easy and reliable leading to higher QA

# How
You need a business program, containing your production logic, and one or many test programs, built to run distinct units of logic within your business program

A test program needs access to all of the fields and procedures of the business program

`harness.sh` extracts the business programs `DATA DIVISION`, `ENVIRONMENT DIVISION`, `WORKING STORAGE` and `PROCEDURE DIVISION` as various copybooks which you include in your test program

This puts the sections and paragraphs of your business program into a test program sandbox

## Execution Validation

At its most basic, you can interact with fields before and after executing a business routine

`CUTSTOR` and `CUTPROC` are a collection of helper fields and procedures that make querying and managing a unit test program easy and familiar

### A Basic Example
A simple calculator paragraph is shown below
```COBOL
       BA-ADD-NUMBERS.
           COMPUTE WS-RESULT = WS-NUM-1 + WS-NUM-2
       .
```

The corresponding test case looks like this
```COBOL
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
```

`GIVEN`, `WHEN`, `THEN` is an alternative wording to `Arrange`, `Act`, `Assert`.

### Trace Assertions

Often you need to validate how the code did something, not necessarily the end result of that

COBOL lacks reflection so it has limited ability to know what its own execution has done

`harness.sh` will instrument a breadcrumb at the top of each section and paragraph of the business program to register which sections/paragraphs have run
```COBOL
       READ-NEXT-RECORD SECTION.
           MOVE "READ-NEXT-RECORD"        *> line inserted by inserted by harness.sh
           TO CUT-TEMP-SECTION-NAME       *> line inserted by inserted by harness.sh
           PERFORM CUT-ADD-TRACE-SECTION  *> line inserted by inserted by harness.sh
           ... 
           business logic 
           ...
        .
```

This breadcrumb also takes a snapshot of various working storage fields, defined in the test program
```COBOL
       CUT-TRACE-FIELDS SECTION.
           MOVE 'FIELD-A' TO CUT-TEMP-FIELD-NAME 
           MOVE FIELD-A TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD 

           MOVE 'FIELD-B' TO CUT-TEMP-FIELD-NAME 
           MOVE FIELD-B TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD 
           CONTINUE
       .
```

### A More Complex Example
Sometimes COBOL programs don't change data, they just call out to other systems. In this case working storage validation won't prove anything. Success is defined by a certain sections and paragraphs being run

Let's look at an example of the calculator dividing by zero
```COBOL
       BC-DIV-NUMBERS.
           IF WS-NUM-2 = 0
               PERFORM CA-DISPLAY-ERROR 
           ELSE
              COMPUTE WS-RESULT  = WS-NUM-1 / WS-NUM-2 
           END-IF 
       .
```

We want to make sure that this paragraph can handle an attempted divide by zero. A test case would look like this
```COBOL
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
```

This case demonstrates the power of the `CUT-ASSERT-TRACE`, which allows you to query the section and paragraph trace of an execution

This case asserts that `BC-DIV-NUMBERS` must run, followed by `CA-DISPLAY-ERROR`. Demonstrating that the paragraph identified a divide by zero error

If `CA-DISPLAY-ERROR` was not called the output of the test run would be
```
TEST CASE - TEST-DIV-BY-ZERO-HANDLE
[FAIL] UNABLE TO FIND CA-DISPLAY-ERROR IN EXECUTION TRACE
[FAIL]
```


# Is This Effective?
In my experience, yes

## It's Testing Itself
The framework is already in a state where it can test itself

Everything inside CUTSTOR and CUTPROC is prefixed with "CUT-" (COBOL Unit Test) e.g `01  CUT-DATA.`. To avoid obvious naming conflicts, the framework is testing an imaginary program with "CUT-" replaced with "DUT-", for "Dummy Unit Test" e.g `01  DUT-DATA.`

New features can be implemented into DUT and have their behaviours observed before being added to CUT. Making for a much easier development process

Having the inner working of each section documented by a unit test program makes expanding the capabilities and understanding the logic after some time away much easier


# The Output
```
...
TEST CASE - TEST-ADD-TRACE-ADDS-TRACE
[PASS]

TEST CASE - TEST-EVALUATE-OP-EQ-POS  
[PASS]

TEST CASE - TEST-EVALUATE-OP-NEQ-POS 
[PASS]
 
 
TEST EXECUTION RESULTS
===================================================
PASS : 25
FAIL : 0
SKIP : 0
===================================================
```

`cobtest` combines the code coverage, harness, compile and execution into 1 step, it also prints an overview of the test results and any [FAIL]s or [DEBUG] lines to the output

# Getting Started

## Installing Open COBOL Unit Test
1. Download the release tar file containing the `CUT/` `cobtest` `cobtestrun` and `harness.sh` files
2. Extract the tar file to a folder of your choosing, I'll use the home area
3. Set the COBTEST_HOME variable: `export COBTEST_HOME=~/open-cobol-unit-test-0.1.0`
4. Add the COBTEST_HOME to your PATH: `export PATH=$PATH:$COBTEST_HOME`
5. Check it's successfully installed by running `cobtest --version`
   - Which should output `Open COBOL Unit Test 0.1.0` 

## Setting Up a Project
Use the following command to setup the expected folder structure for cobtest
```bash
mkdir -p src/main/cobol/sorlib/ src/main/cobol/copylib src/test/cobol/testlib
```
- sorlib/ is used for your business / production logic
- copylib/ is used for the copybooks required by your sorlib
- testlib/ is used for your unit test programs

## Snippets
You'll find some VS Code snippets in the [snippets/](snippets/) folder to get you up and running quickly.