# Open COBOL Unit Test

An open source COBOL Unit Test library

Designed to be as xUnit compatible as possible

Allows the user to execute COBOL sections and paragraphs inside of a business program in a unit test environment

# Why
The ability to isolate test cases down to the scale of sections and paragraphs enables using code to:
- **Faster Execution:** Running a unit test should take milliseconds
- **Immediate Feedback:** When integrated into the compile step, developers catch bugs as soon as they appear
- **Precise Isolation:** Bugs that do happen have their exact scenario documented
- **More deterministic results:** Zero external file, database or API dependancies
- **Code structure improvements:** Baddly written code is difficult to unit test without refactoring
- **Higher code coverage:** Far easier to get deep into complex logic to test edge cases
- **Higher quality assurance:** Code based unit tests are cheap, easy and reliable leading to higher QA

# How
In xUnit style you would need a test program, and a business program

## 1. What your program did
A test program needs access to all of the fields and procedures of the business program

`harness.sh` extracts the business programs `DATA DIVISION`, `ENVIRONMENT DIVISION`, `WORKING STORAGE` and `PROCEDURE DIVISION` as various copybooks which you include in your test program

This puts the sections and paragraphs of your business program into a test program sandbox

## 2. How it did it
Or more precisely "which sections did you run, and what did working storage look like at each point"

As far as I can see, there's no easy way to expose this information in a way that's useful for this context

So `harness.sh` will also instrument a breadcrumb at the top of each section and paragraph of the business program to log which section or paragraph has been run
```COBOL
       READ-NEXT-RECORD SECTION .
           MOVE "READ-NEXT-RECORD"
           TO CUT-TEMP-SECTION-NAME
           PERFORM CUT-ADD-TRACE-SECTION
           ... 
           business logic 
           ...
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

This should encourage smaller sections and paragraphs as unit tests will be simpler with less data setup 

## Making This Data Accessible
Capturing this data is fine, but it needs to be queryable in a reasonably easy way which is where the CUTSTOR and CUTPROC come in

CUTSTOR and CUTPROC are a collection of helper fields and procedures that make querying and managing a unit test program easy and familiar to a COBOL programmer


## A Basic Example
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

GIVEN, WHEN, THEN is an alternative wording to Arrange, Act, Assert.

## A More Complex Example
Sometimes COBOL programs don't change data, they just call out to other systems. In this case working storage validation won't prove anything

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

If CA-DISPLAY-ERROR was not called the output of the test run would be
```
TEST CASE - TEST-DIV-BY-ZERO-HANDLE
[FAIL] UNABLE TO FIND CA-DISPLAY-ERROR IN EXECUTION TRACE
[FAIL]
```


# Is This Effective?
In my experience, yes

## It's Testing Itself
The framework is already in a state where it can test itself

Everything inside CUTSTOR and CUTPROC is prefix with "CUT-" (COBOL Unit Test) e.g `01  CUT-DATA.`. To avoid obvious naming conflicts, the framework is testing an imaginary program with "CUT-" replaced with "DUT-", for "Dummy Unit Test" e.g `01  DUT-DATA.`

Seen in Examples/Example01/

New features can be implemented into DUT and have their behaviours observed before being added to CUT. Making for a much easier development process

Having the inner working of each section documented by a unit test program makes expanding the capabilities and understanding the logic after some time away much easier


# The Output
When run against Examples/Example01/test-pgm.cbl
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

`test-pgm-out.cbl` is generated with `./harness.sh Examples/Example01/pgm-to-test.cbl Examples/Example01/test-pgm.cbl`

Use `cobc -x test-pgm-out.cbl -o testpgm -I "tmp" -I "CUT"` to compile the unit test program


