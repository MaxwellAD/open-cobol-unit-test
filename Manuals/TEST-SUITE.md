# TEST-SUITE User Manual

## Description
Assembling a whole test program — the copybooks it is built from, the sections it needs, and how to run it.

For what goes inside a single `TEST-` section, see `TEST-CASE.md`.

---

## Where A Suite Lives

Use `cobtestrun <business program> <test program>` to manually target a business and test program.

Or use

`cobtest` which pairs each business program with a directory of the same name in the `src/test` directory

```
src/main/cobol/sorlib/calculator.cbl <-- Business program
  -> src/test/cobol/testlib/calculator/*.cbl <-- A collection of test programs
```

---

## The Skeleton

This is an example test program with the business program below

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TESTADD.
       ENVIRONMENT DIVISION.
       COPY CUTENV.
       DATA DIVISION.
       COPY CUTDATA.
       WORKING-STORAGE SECTION.

       COPY STORAGE OF ADDER.
       COPY CUTSTOR.

       PROCEDURE DIVISION.

       TEST-ADDS-TWO-NUMBERS SECTION.
           
           MOVE 2 TO WS-A
           MOVE 3 TO WS-B

           PERFORM AA-ADD
           
           MOVE 5 TO CUT-ASSERT-TARGET-N
           MOVE WS-TOTAL TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM
           
           PERFORM CUT-END-TEST
           .

       END-TEST-SUITE SECTION.
           PERFORM CUT-END-TEST-SUITE
           .

       CUT-TRACE-FIELDS SECTION.
           EXIT SECTION
           .

       BEFORE-EACH SECTION.
           MOVE ZERO TO WS-A WS-B WS-TOTAL
           EXIT SECTION
           .

       COPY PROGRAM OF ADDER.
       COPY CUTPROC.
```

## The Program The Skeleton Tests

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADDER.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-A        PIC 9(4) VALUE 0.
       01 WS-B        PIC 9(4) VALUE 0.
       01 WS-TOTAL    PIC 9(5) VALUE 0.

       PROCEDURE DIVISION.

       AA-ADD SECTION.
           COMPUTE WS-TOTAL = WS-A + WS-B
           .
```

---

## The Copybooks

**Framework members**

| Member | Goes in |
| -- | -- |
| `CUTENV` | `ENVIRONMENT DIVISION` |
| `CUTDATA` | `DATA DIVISION` |
| `CUTSTOR` | `WORKING-STORAGE SECTION` |
| `CUTPROC` | End of `PROCEDURE DIVISION` |


**Generated members — qualify each with the business program's file name, uppercased:**

| Member | Holds |
| -- | -- |
| `STORAGE` | The business program's working storage, plus its `LOCAL-STORAGE` and `LINKAGE` |
| `FILESEC` | Business program `FILE SECTION` |
| `FILECTL` | Business program `FILE-CONTROL` |
| `PROGRAM` | Business program `PROCEDURE DIVISION` |

| Business program | Write |
| -- | -- |
| `sorlib/LEDGER.cbl` | `COPY STORAGE OF LEDGER.` |
| `sorlib/pgm-to-test.cbl` | `COPY STORAGE OF PGM-TO-TEST.` |
| `sorlib/CALC/OUTPUT.cbl` | `COPY STORAGE OF OUTPUT.` |


## Required Sections

A suite will not compile without these two.

### BEFORE-EACH

Runs before every test case. Reset anything a case should not inherit from the case before it.

```cobol
       BEFORE-EACH SECTION.
           MOVE ZERO   TO WS-REQ-QTY
           MOVE SPACES TO WS-REQ-STATUS
           EXIT SECTION
           .
```

End it with `EXIT SECTION`.

### CUT-TRACE-FIELDS

Registers the fields captured into the trace on entry to every business section. These are the fields a `WITH` clause can assert on and the columns `CUT-DEBUG-DISPLAY-TRACE` prints.

```cobol
       CUT-TRACE-FIELDS SECTION.
           MOVE 'WS-REQ-QTY' TO CUT-TEMP-FIELD-NAME
           MOVE WS-REQ-QTY   TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD
           EXIT SECTION
           .
```

Three lines per field. If you are not asserting on the trace, leave it empty:

```cobol
       CUT-TRACE-FIELDS SECTION.
           EXIT SECTION
           .
```

---

## BEFORE-ALL And END-TEST-SUITE

`BEFORE-ALL` runs once. It has to be the **first** section under `PROCEDURE DIVISION`.

```cobol
       BEFORE-ALL SECTION.
           CONTINUE
           .
```

`END-TEST-SUITE` goes **after the last test case**. It writes the totals and ends the run. Every suite needs one:

```cobol
       END-TEST-SUITE SECTION.
           PERFORM CUT-END-TEST-SUITE
           .
```

If the totals come out one higher than the number of cases you wrote, or the run never finishes, that section is missing or is in the wrong place.

---

## How A Suite Runs

Cases run top to bottom, in source order.

```
BEFORE-ALL
   ↓
BEFORE-EACH → TEST-CASE-1 → CUT-END-TEST
   ↓
BEFORE-EACH → TEST-CASE-2 → CUT-END-TEST
   ↓
... every remaining case ...
   ↓
END-TEST-SUITE → report, return code, stop
```

Everything you write below `END-TEST-SUITE` — the mocks, `BEFORE-EACH`, `CUT-TRACE-FIELDS`, the two `COPY` members is reached by a `PERFORM` statement.

---

## Mocks

A `MOCK-` section replaces the business section of the same name for the whole run. Write it in the test program:

```cobol
       MOCK-ZZ-RETURN-TO-CALLER SECTION.
           EXIT SECTION
           .
```

Use one to:

- **Neutralise a `GOBACK` or `STOP RUN`.** Performing one from a case stops the entire suite, so mock the section holding it and the mainline becomes testable.
- **Silence I/O or display.**
- **Record that a boundary was reached**, by setting a field a case can then assert on.

Two rules:

- End a mock with `EXIT` statement, omitting an `EXIT SECTION` or `EXIT PARAGRAPH` will allow execution to fall into the `MOCK`ed section, not usually desireable, but sometimes needed.

---

## Testing A Section That Uses GO TO

When the section under test jumps away and never comes back:

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

Put a paragraph between the `WHEN` and the `THEN`, and mock the jump target to go to it:

```cobol
       TEST-CALC-WITH-GO-TO SECTION.
           *> GIVEN
           MOVE 1 TO WS-NUM-1
           MOVE 1 TO WS-NUM-2

           *> WHEN
           PERFORM ADD-NUMBERS.

       HANDLE-GO-TO-RETURN.

           *> THEN
           MOVE 2 TO CUT-ASSERT-TARGET-N
           MOVE WS-RESULT TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
           .
```

```cobol
       MOCK-EXIT-PROGRAM SECTION.
           GO TO HANDLE-GO-TO-RETURN
           .
```

Execution lands back in the case with the result ready to assert. Note the period on `PERFORM ADD-NUMBERS.` — it closes the sentence so the paragraph can follow.

When several cases share one jump target, evaluate on `CUT-TEST-NAME`:

```cobol
       MOCK-EXIT-PROGRAM SECTION.
           EVALUATE CUT-TEST-NAME
           WHEN 'TEST-CALC-WITH-GO-TO'
               GO TO HANDLE-GO-TO-RETURN
           WHEN 'TEST-SUB-WITH-GO-TO'
               GO TO HANDLE-SUB-RETURN
           END-EVALUATE
           .
```

---

## Running A Suite

From the project root:

```bash
# every suite (assuming src/test/cobol/testlib compliance)
cobtest
# targetted runs
cobtestrun src/main/cobol/sorlib/calculator.cbl \
           src/test/cobol/testlib/test-calculator.cbl
```

Both need:

```bash
export COBTEST_HOME=/path/to/open-cobol-unit-test
export PATH="$PATH:$COBTEST_HOME"
```

Each run writes two files per suite under `Reports/`:

| File | Holds |
| -- | -- |
| `<suite>-unit-test-report.txt` | The results — `[PASS]`, `[FAIL]`, `[SKIP]`, `[ERROR]`, and `[DEBUG]` trace tables |
| `<suite>-coverage-report.txt` | Your own `DISPLAY`s, and the coverage report |

`CUT-DEBUG-DISPLAY-TRACE` output goes to the **first** file, beside the case that produced it.

A suite with any failure or error exits 16 and `cobtest` exits non-zero. Skips do not fail a build.

---

## Gotchas

**Section names used in ASSERT-TRACE are limited to 30 characters** If your compiler allows, you can extend TEST names beyond 30 characters.

**`PIC X ANY LENGTH` is not supported.** as this is only valid inside of a `LINKAGE SECTION` which the test program does not have.

**A captured field cannot have a `V` in its picture.** `MOVE WS-PRICE TO CUT-TEMP-FIELD-VALUE` on a `PIC 9(7)V99` field gives `error: invalid MOVE statement`. Two ways round it:

```cobol
      *> UNSIGNED, USAGE DISPLAY - REGISTERS AS 000001050
           MOVE WS-PRICE(1:) TO CUT-TEMP-FIELD-VALUE

      *> SIGNED OR COMP-3 - NEEDS AN EDITED FIELD
       01 WS-PRICE-DISPLAY PIC ZZZ,ZZ9.99.
      ...
           MOVE WS-PRICE         TO WS-PRICE-DISPLAY
           MOVE WS-PRICE-DISPLAY TO CUT-TEMP-FIELD-VALUE
```

Either way a `WITH` clause has to match the stored form exactly. `PERFORM CUT-DEBUG-DISPLAY-TRACE` once and copy the value out of the table.

---

# See Also

- `TEST-CASE.md` — writing a single case, and the assertion reference
- `ASSERT-TRACE.md` — the `CUT-ASSERT-TRACE` keywords
