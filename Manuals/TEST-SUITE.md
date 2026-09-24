# TEST-SUITE User Manual

## Description
Assembling a whole test program — the copybooks it is built from, the sections the framework requires, how execution flows through it, and how to run it.

This manual covers the test program **as a whole**. For what goes inside a single `TEST-` section, see `TEST-CASE.md`.

---

## The Structure Of A Test Suite

A test suite is an ordinary COBOL program. It is built almost entirely out of `COPY` statements: the framework's own members, and the members `harness.sh` generates from the business program under test.

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-LEDGER.
       ENVIRONMENT DIVISION.
       COPY CUTENV.
       COPY FILECTL OF LEDGER.
       DATA DIVISION.
       COPY CUTDATA.
       COPY FILESEC OF LEDGER.
       WORKING-STORAGE SECTION.

       COPY STORAGE OF LEDGER.
       COPY CUTSTOR.

      * FIXTURES AND ANY STORAGE THE SUITE ITSELF NEEDS
       01 FIXTURES.
           05 FIXTURE-CUSTOMER       PIC X(20) VALUE 'ACME LIMITED'.

       PROCEDURE DIVISION.

      * RUNS ONCE, BECAUSE IT IS THE FIRST SECTION - SEE BELOW
       BEFORE-ALL SECTION.
           CONTINUE
           .

       TEST-MY-FIRST-TEST-CASE SECTION.
           *> GIVEN

           *> WHEN

           *> THEN

           PERFORM CUT-END-TEST
           .

      * ... ANY NUMBER OF FURTHER TEST- AND SKIP- CASES ...

       END-TEST-SUITE SECTION.
           PERFORM DISPLAY-COVERAGE
           PERFORM CUT-END-TEST-SUITE
           .

      * REQUIRED - SNAPSHOTS FIELDS INTO THE TRACE ON SECTION ENTRY
       CUT-TRACE-FIELDS SECTION.
           MOVE 'WS-REQ-QTY' TO CUT-TEMP-FIELD-NAME
           MOVE WS-REQ-QTY   TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD
           EXIT SECTION
           .

      * KEEP COMMENTARY ABOVE A MOCK HEADER, NEVER BELOW IT
       MOCK-ZZ-RETURN-TO-CALLER SECTION.
           EXIT SECTION
           .

      * REQUIRED - RUNS BEFORE EVERY TEST CASE
       BEFORE-EACH SECTION.
           MOVE ZERO   TO WS-REQ-QTY
           MOVE SPACES TO WS-REQ-STATUS
           EXIT SECTION
           .

      * ANY FIXTURES / HELPER SECTIONS CAN GO HERE

       COPY PROGRAM OF LEDGER.
       COPY CUTPROC.
```

`FILECTL` and `FILESEC` are only needed when the business program has a `FILE SECTION`. A program with no files omits both, as the minimal example at the end of this manual does.

---

## The Copybooks

Three kinds of member go into a suite, and they behave differently.

### Framework members — never qualified

| Member | Division | Holds |
| -- | -- | -- |
| `CUTENV` | `ENVIRONMENT` | The `SELECT`/`ASSIGN` for the report file |
| `CUTDATA` | `DATA` / `FILE SECTION` | The report file's record |
| `CUTSTOR` | `WORKING-STORAGE` | Counters, the trace table, assertion fields |
| `CUTPROC` | `PROCEDURE` | Every `CUT-` section — the framework's logic |

All four are written **unqualified**. An unqualified `COPY` assumes library `SYSLIB`, which resolves from `$COBTEST_HOME/CUT`. All four are required in every suite.

### Generated members — always qualified by the business program's library

| Member | Division | Holds |
| -- | -- | -- |
| `STORAGE` | `WORKING-STORAGE` | The business program's working storage, plus its relocated `LOCAL-STORAGE` and `LINKAGE` |
| `FILESEC` | `DATA` / `FILE SECTION` | The business program's `FILE SECTION` |
| `FILECTL` | `ENVIRONMENT` | The business program's `FILE-CONTROL` |
| `PROGRAM` | `PROCEDURE` | The business program's `PROCEDURE DIVISION`, instrumented with trace breadcrumbs |

These are written `COPY STORAGE OF LEDGER.` — qualified by a library named after the business program's **file name, without the extension, uppercased**:

| business program | library | written as |
| -- | -- | -- |
| `sorlib/LEDGER.cbl` | `target/LEDGER/` | `COPY STORAGE OF LEDGER.` |
| `sorlib/pgm-to-test.cbl` | `target/PGM-TO-TEST/` | `COPY STORAGE OF PGM-TO-TEST.` |
| `sorlib/CALC/OUTPUT.cbl` | `target/OUTPUT/` | `COPY STORAGE OF OUTPUT.` |

The path is deliberately not part of the name — `sorlib` and `testlib` may nest freely, but `target/` stays flat. A bare, unquoted word is the only form every toolchain reads: GnuCOBOL takes it as a directory under `-I`, IBM under JCL as a ddname, IBM under `cob2` as an environment variable, and Z Open Editor as a named library in `zapp.yaml`.

The qualifier is **case sensitive** under GnuCOBOL: `OF LEDGER` will not find `target/ledger`.

These four members are regenerated on every run. Never edit them — edit the business program.

### Project members — resolved by the compiler

A `COPY` inside the business program's own `WORKING-STORAGE`, `LINKAGE`, `FILE SECTION` or `FILE-CONTROL` is relocated **verbatim** by the harness and left for the compiler to resolve. `cobtestrun` puts `src/main/cobol/copylib` on the copy path for every suite, so a member like `LKPARM` is picked up with no extra work.

---

## Required Sections

Two sections are not optional. `CUTPROC` performs both unconditionally, so a suite without them **does not compile**.

### BEFORE-EACH — required

Performed by `CUT-TEST-INIT` before every test case. Omit it and the compile fails:

```
CUT/CUTPROC.cpy: in section 'CUT-TEST-INIT':
CUT/CUTPROC.cpy:1155: error: 'BEFORE-EACH' is not defined
```

Use it to reset state every case should start from. This matters more than it does in most xUnit frameworks: all cases share one working storage, and `LINKAGE`/`LOCAL-STORAGE` fields have been folded into it, so they no longer get fresh storage per invocation. Anything not reset here carries over from the previous case.

End it with `EXIT SECTION`. Without it, execution falls out of `BEFORE-EACH` into whatever section follows.

### CUT-TRACE-FIELDS — required

Performed by `CUT-ADD-TRACE-SECTION` on entry to every business section. Omit it and the compile fails:

```
CUT/CUTPROC.cpy: in section 'CUT-ADD-TRACE-SECTION':
CUT/CUTPROC.cpy:783: error: 'CUT-TRACE-FIELDS' is not defined
```

It registers which fields are snapshotted into the trace, which is what `CUT-DEBUG-DISPLAY-TRACE` prints and what a `WITH` clause asserts against. Each field costs three lines:

```cobol
           MOVE 'WS-REQ-QTY' TO CUT-TEMP-FIELD-NAME
           MOVE WS-REQ-QTY   TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD
```

A suite that never asserts on the trace still needs the section — an empty one is fine:

```cobol
       CUT-TRACE-FIELDS SECTION.
           EXIT SECTION
           .
```

---

## Conventional Sections

These are **not** framework hooks. The framework never looks for them by name — they work purely because of where they sit in the fall-through order, and you could rename them. The names are a convention worth keeping.

### BEFORE-ALL

One-time setup. It runs once because it is the **first section after `PROCEDURE DIVISION`**, and execution enters there. The name carries no meaning — a section called `ZZZ-ARBITRARY-NAME` in the same position runs exactly the same way. What matters is that it comes first, and that nothing else is placed above it.

### END-TEST-SUITE

Placed after the last test case, so fall-through reaches it once every case has run. It performs `CUT-END-TEST-SUITE`, which writes the totals, closes the report, sets the return code and stops the run.

`CUT-END-TEST-SUITE` is the framework section and is mandatory in the sense that **something** must perform it. See "Always terminate the suite" below for what happens when nothing does.

---

## How A Test Suite Executes

A test program uses **fall-through processing**. Execution starts at the first section under `PROCEDURE DIVISION` and runs straight down the source. Nothing dispatches the cases — each one runs because control arrives at it.

While fall-through is not generally recommended for modern COBOL, it buys three things here:

1. It matches how other xUnit frameworks run tests: top to bottom, in source order.
2. A case only has to be *defined*, never registered or invoked.
3. It gives the framework somewhere to stand when a business program uses `GO TO`.

The harness rewrites the source before compiling: ahead of every `TEST-` section it inserts a `MOVE` of the case name and a `PERFORM CUT-TEST-INIT`, which is what clears the trace, resets the result flag, prints the case name and performs `BEFORE-EACH`. `SKIP-` sections have their bodies stripped and replaced with a `PERFORM CUT-SKIP`.

So the order of a run is:

```
BEFORE-ALL  (once, because it is first)
   ↓
CUT-TEST-INIT → BEFORE-EACH → TEST-CASE-1 → CUT-END-TEST
   ↓
CUT-TEST-INIT → BEFORE-EACH → TEST-CASE-2 → CUT-END-TEST
   ↓
... every remaining case, in source order ...
   ↓
END-TEST-SUITE → CUT-END-TEST-SUITE → report, return code, STOP RUN
```

Everything below `END-TEST-SUITE` — `CUT-TRACE-FIELDS`, the mocks, `BEFORE-EACH`, the helpers and the two trailing `COPY` members — is only ever reached by `PERFORM`, never by fall-through, because the suite has already stopped.

### Always terminate the suite

If nothing performs `CUT-END-TEST-SUITE`, execution does not stop at the last case — it keeps falling, through the trace-field section, through the mocks, through `BEFORE-EACH`, and into the copied `PROCEDURE DIVISION`s.

It fails quietly. `CUT-END-TEST` is the first section in `CUTPROC`, so fall-through reaches it and records **one extra passing case that was never written**, then falls into `CUT-END-TEST-SUITE` and stops as though nothing were wrong. A single-case suite reports:

```
TEST EXECUTION RESULTS
===================================================
PASS : 2            <-- only one TEST- case exists
FAIL : 0
SKIP : 0
===================================================
```

Worse, if any mock uses `GO TO` to jump back into a case — the pattern under "Testing A Section That Uses GO TO" — falling off the end re-enters that case and the run **loops forever**.

Give every suite an `END-TEST-SUITE` section.

### The order of the trailing COPY members

Both orderings compile and both run, and the shipped suites are not consistent: `test-calculator` and `test-linkage-pgm` put `COPY PROGRAM` first, `test-pgm` puts `COPY CUTPROC` first.

`COPY PROGRAM` first is the better default. Fall-through past the end of the business program then lands in `CUTPROC`, whose first section ends the suite, rather than running off the end of the compilation unit. It is a safety net rather than a fix — it still produces the phantom pass above — so it is no substitute for terminating the suite properly.

---

## Mocks

A mock replaces a business section's body for the whole run. Declare it in the **test program**, never in the business program:

```cobol
       MOCK-ZZ-RETURN-TO-CALLER SECTION.
           EXIT SECTION
           .
```

Before extracting anything, `harness.sh` scans the test program for sections named `MOCK-<name>`, and where a section literally named `<name>` exists in the business program, splices the mock's body in ahead of it.

Mocks are what make these testable:

- **A section that returns to the caller.** `GOBACK` and `STOP RUN` are not scoped to their section — performing one from a test case stops the whole suite mid-run. Keep the return verb in a section of its own and mock that section out, as `src/test/cobol/testlib/linkage-pgm/` does with `MOCK-BZ-RETURN-TO-CALLER`. The mainline then becomes performable.
- **I/O and display.** `src/test/cobol/testlib/calculator/` mocks its display sections so cases can run without console side effects.
- **A boundary you want to assert on.** A mock that sets a flag or writes to a field turns an external call into something a case can check.

Two things to watch:

- **Keep commentary above the mock header, never below it.** The harness captures every line after the header as part of the mock body, until the next Area A name. A comment block below the header becomes part of the mock.
- **The real section is not deleted.** The mock body is inserted ahead of it, so the mock must not fall through — end it with `EXIT SECTION`, or with a `GO TO` as below.

---

## Testing A Section That Uses GO TO

`GO TO` is not recommended in new COBOL, but it is common in programs that predate the budget for a refactor. A suite can still reach that code.

Given a business program where the section under test jumps away and never returns:

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

`ADD-NUMBERS` looks untestable: the `GO TO` destroys any chance of returning to the suite, and `EXIT-PROGRAM` would stop the run outright.

Mock the jump target and send it back into the case, to a paragraph placed between the `WHEN` and the `THEN`:

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
           DISPLAY 'INTERCEPTED EXIT PROGRAM'
           GO TO HANDLE-GO-TO-RETURN
           .
```

`ADD-NUMBERS` goes to `EXIT-PROGRAM`, which has been mocked to go to `HANDLE-GO-TO-RETURN`, dropping execution back into the case with the result ready to assert:

```
TEST CASE - TEST-CALC-WITH-GO-TO
[PASS]

TEST EXECUTION RESULTS
===================================================
PASS : 1
FAIL : 0
SKIP : 0
===================================================
```

Note the period ending the `PERFORM ADD-NUMBERS.` line — it closes the sentence so the paragraph header can follow.

When the same jump target is used by several cases — a shared exit routine, typically — one fixed return paragraph will not do. The current case name is exposed in `CUT-TEST-NAME`, so the mock can branch on it:

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

## Where A Suite Lives

`cobtest` discovers suites by directory convention. For each business program under `src/main/cobol/sorlib/`, it looks for a directory of the same path and name under `src/test/cobol/testlib/`, and runs **every** `.cbl` in it:

```
src/main/cobol/sorlib/calculator.cbl
  -> src/test/cobol/testlib/calculator/*.cbl

src/main/cobol/sorlib/calculator/calc-with-goto.cbl
  -> src/test/cobol/testlib/calculator/calc-with-goto/*.cbl
```

Directories nest freely, and a business program may have more than one suite — a second `.cbl` in the same test directory is discovered and run as a suite of its own.

---

## Running A Suite

Run the whole project from its root:

```bash
cobtest
```

Or one suite at a time, which is the faster loop while writing tests:

```bash
cobtestrun src/main/cobol/sorlib/calculator.cbl \
           src/test/cobol/testlib/calculator/test-calculator.cbl
```

Both need the framework on `PATH`:

```bash
export COBTEST_HOME=/path/to/open-cobol-unit-test
export PATH="$PATH:$COBTEST_HOME"
```

`COBTEST_WORK` (default `target`) sets where the generated copybooks go. Running the scripts **through a symlink is not supported** — set `COBTEST_HOME` instead.

### Output

Each run leaves two files per suite under `Reports/`, mirroring the `testlib` layout:

| File | Contains |
| -- | -- |
| `<suite>-unit-test-report.txt` | The pass/fail report written to `CUT-RPTO` — every `[PASS]`, `[FAIL]`, `[SKIP]`, `[ERROR]` and `[DEBUG]` line |
| `<suite>-coverage-report.txt` | Everything the suite sent to stdout — your own `DISPLAY`s, and the coverage report |

The split is not "results here, debugging there". `CUT-DEBUG-DISPLAY-TRACE` writes through `CUT-WRITE-UT-RECORD` like any assertion, so its trace table lands in the **report file**, tagged `[DEBUG]`, interleaved with the case it belongs to:

```
TEST CASE - TEST-PRICE-WITH-REFMOD
[DEBUG] EXECUTION TRACE TABLE
[DEBUG] |--------------|-----------|
[DEBUG] | SECTION-NAME | WS-PRICE  |
[DEBUG] |--------------|-----------|
[DEBUG] | AA-MAIN      | 000001050 |
[DEBUG] |--------------|-----------|
[DEBUG] | BB-PRICE     | 000001050 |
[DEBUG] |--------------|-----------|
[PASS]
```

That is deliberate — a trace table is only useful next to the assertion it explains. `cobtestrun` greps `[FAIL]`, `[ERROR]`, `[SKIP]` and `[DEBUG]` out of `CUT-RPTO` to echo to the console, so a debug table shows up in the terminal too.

Only what your program `DISPLAY`s itself — and the coverage report — goes to stdout.

### Exit codes

`CUT-END-TEST-SUITE` sets `RETURN-CODE` to **16** when a suite has any failures or errors, and leaves it at 0 otherwise. `cobtest` uses that to count failed suites and exits non-zero if any failed, which is what makes it usable in CI.

**Skips do not fail a build.** A suite whose every case is `SKIP-` still exits 0. Skips are reported on every run so they cannot be quietly forgotten, but nothing enforces a ceiling on them.

---

## Code Coverage

Coverage is not part of this framework. `cobtestrun` shells out to `code-coverage-precompiler.sh` from the sibling `open-cobol-code-coverage` project before running the harness, and that precompiler generates a `DISPLAY-COVERAGE` section into the business program.

To get a coverage report, perform it as the suite ends:

```cobol
       END-TEST-SUITE SECTION.
           PERFORM DISPLAY-COVERAGE
           PERFORM CUT-END-TEST-SUITE
           .
```

The `PERFORM` is optional — a suite that omits it runs fine and simply prints no coverage. What is **not** possible today is keeping the line while building without the precompiler: `DISPLAY-COVERAGE` will not exist and the compile fails.

A compiler-directive guard looks like the answer and is not:

```cobol
      * >>IF COVERAGE DEFINED
           PERFORM DISPLAY-COVERAGE
      * >>END-IF
```

As written, with `*` in column 7, both directives are **comments and do nothing** — the `PERFORM` is unconditional, which is the only reason this compiles. Correct the columns to make the guard real and the coverage report silently disappears, because nothing in the precompiler ever defines `COVERAGE`. Leave the `PERFORM` unguarded.

---

## Gotchas

### A comment mentioning GOBACK or STOP RUN breaks the build

The coverage precompiler matches `STOP RUN` and `GO BACK` against whole lines, comments included, and injects statements before them. In a business program under `src/main/cobol/sorlib/`, a comment that merely *mentions* either verb produces stray statements outside any section, and the compile fails somewhere unrelated — commonly `'AA-MAINLINE' is not defined` reported against whichever section precedes `COPY PROGRAM`.

Write "returns to the caller" in business-program comments instead.

### A registered trace field cannot have a V in its picture

`CUT-TEMP-FIELD-VALUE` is `PIC X(30)`, and COBOL will not move a **non-integer** numeric into an alphanumeric item. So the ordinary way to write a money field is exactly the way that gets rejected:

```
test-pgm-out.cbl: in section 'CUT-TRACE-FIELDS':
test-pgm-out.cbl:45: error: invalid MOVE statement
```

| Sending field | To `PIC X(30)` |
| -- | -- |
| `PIC 9(9)` | legal |
| `PIC S9(9)` | legal |
| `PIC ZZZ,ZZ9.99` and other edited pictures | legal |
| `PIC 9(9)V99` | **rejected** |
| `PIC S9(9)V99` | **rejected** |
| `PIC 9(9)V99 COMP-3` | **rejected** |

`V` is not a stored character — it only records where the decimal point sits among the digits. `PIC 9(9)V99` holding `123.45` stores eleven digit characters and no `.` at all, so a move to `PIC X` has no single right answer and the compiler refuses rather than choose. It is the picture that decides, not the usage, which is why `COMP-3` is rejected on the same grounds.

There are two ways through, and which one you want depends on whether you care what the value *looks like* in a `CUT-DEBUG-DISPLAY-TRACE` table.

**Reference modification — cheapest, and fine for unsigned `DISPLAY` fields.** It hands you the raw digits with no extra declaration:

```cobol
           MOVE 'WS-RESULT'    TO CUT-TEMP-FIELD-NAME
           MOVE WS-RESULT(1:)  TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD
```

`WS-RESULT` as `PIC 9(9)V99` holding `123.45` registers as `00000012345`. The decimal point is not shown, and that is not a problem: a `WITH` clause compares like for like, so you write `00000012345` as the target. If you match the stored form and the assertion still fails, the difference is real.

Two cases where it bites:

- **A signed field overpunches its sign into the last digit.** `PIC S9(9)V99` holding `-123.45` registers as `0000001234u`, not `...45`. Legal, stable, and unreadable.
- **`COMP-3` and `COMP` compile and produce garbage.** Reference modification takes the raw bytes, which for a packed field are not text. Nothing warns you.

**An edited field — more typing, readable output.** Use it for signed or packed fields, and whenever a human will read the trace table:

```cobol
       01 WS-RESULT-DISPLAY   PIC ZZZ,ZZZ,ZZ9.99.
      ...
           MOVE 'WS-RESULT'       TO CUT-TEMP-FIELD-NAME
           MOVE WS-RESULT         TO WS-RESULT-DISPLAY
           MOVE WS-RESULT-DISPLAY TO CUT-TEMP-FIELD-VALUE
           PERFORM CUT-REGISTER-FIELD
```

You have now chosen the text form, and the `WITH` target must match it exactly — including the leading spaces `Z` produces, so `21.00` registers as `        21.00`. If that padding is awkward to write, `PIC 9(9).99` gives `000000021.00`: fixed width, decimal point shown, nothing to count.

Whichever you pick, do not count digits by hand. `PERFORM CUT-DEBUG-DISPLAY-TRACE` once and copy the value out of the table — it shows the stored form, which is exactly what `WITH` compares against:

```
[DEBUG] | SECTION-NAME | WS-PRICE  |
[DEBUG] |--------------|-----------|
[DEBUG] | BB-PRICE     | 000001050 |
```

```cobol
           STRING 'BB-PRICE '
                  'WITH '
                    'WS-PRICE = 000001050 '
                  'END-WITH '
                  DELIMITED BY SIZE
                  INTO CUT-TRACE
           END-STRING
           PERFORM CUT-ASSERT-TRACE
```

That is `WS-PRICE` as `PIC 9(7)V99` holding `10.50` — nine digits, no point. And when a target does not match, the failure prints both forms side by side, so the correction is usually visible without opening the source:

```
[FAIL] OPERATION EVALUATION FAILED FOR WS-PRICE ON SECTION BB-PRICE
[FAIL] ASSERTED WS-PRICE =  001050
[FAIL] AND GOT WS-PRICE = 000001050
```

### Everything must be fixed-format

`harness.sh` keys off exact column positions: section and division headers begin in Area A at column 8, the comment indicator sits at column 7. Get the columns wrong and extraction fails **silently** rather than loudly. `zcodeformat.json` at the repo root configures a formatter to keep this consistent.

### Section names are limited to 30 characters

Including the `TEST-`/`SKIP-` prefix. Some compilers accept longer names and others reject them.

### ANY LENGTH linkage items are not supported

`PIC X ANY LENGTH` is only legal in a `LINKAGE SECTION`. The harness relocates linkage into working storage, where the compiler rejects it. Everything else legal in linkage — condition names, `OCCURS`, `REDEFINES` — carries over unchanged.

### Two programs with the same file name share a library

`sorlib/CALC/OUTPUT.cbl` and `sorlib/PAYROLL/OUTPUT.cbl` both generate `target/OUTPUT/`. This stays invisible because `cobtest` runs suites one at a time and each compiles straight after its own generation — but it is why suites must stay sequential, and why an editor linting `COPY ... OF OUTPUT` shows whichever was generated last.

---

## The Smallest Working Suite

A business program with no files, no mocks and one section:

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

and the whole suite that tests it:

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-ADDER.
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

Note what is absent: no `FILECTL`/`FILESEC` (the program has no files), no `BEFORE-ALL`, no mocks, no `DISPLAY-COVERAGE`. What is present is the irreducible minimum — the four framework members, `STORAGE` and `PROGRAM`, one case, `END-TEST-SUITE`, and the two required sections.

---

# See Also

- `TEST-CASE.md` — writing a single case, and the assertion reference
- `ASSERT-TRACE.md` — the `CUT-ASSERT-TRACE` grammar in full
- `README.md` — the concept, and why testing at this level is worth it
