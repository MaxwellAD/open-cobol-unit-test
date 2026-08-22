# TEST-CASE User Manual

## Description
Writing a single test case, and the commands available inside one

This manual covers what goes **inside** a `TEST-` section. For assembling a test program — the copybooks, `BEFORE-EACH`, `CUT-TRACE-FIELDS`, declaring mocks, and building the suite — see `TEST-SUITE.md`.

---

## Anatomy Of A Test Case

A test case is an ordinary COBOL section whose name begins with `TEST-`. It ends with `CUT-END-TEST`.

```COBOL
       TEST-ACCEPT-REDUCES-STOCK SECTION.
      *> A VALID REQUEST IS ACCEPTED AND DRAWN DOWN FROM STOCK

           *> GIVEN
           MOVE 100 TO WS-ON-HAND
           MOVE 30  TO WS-REQ-QTY

           *> WHEN
           PERFORM AA000-MAIN

           *> THEN
           MOVE 70 TO CUT-ASSERT-TARGET-N
           MOVE WS-ON-HAND TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
       .
```

| Part | Purpose |
| -- | -- |
| `GIVEN` | Put working storage into the state the behaviour needs |
| `WHEN` | `PERFORM` the one section or paragraph under test |
| `THEN` | Assert on what happened |
| `CUT-END-TEST` | Record the result. Without it the case is never counted |

`GIVEN`, `WHEN`, `THEN` is an alternative wording to `Arrange`, `Act`, `Assert`. The comments are optional but recommended.

---

## Syntax Diagram

```

──── TEST- <case-name> SECTION. ─────── <given> ─────── <when> ─────── <then> ─────── PERFORM CUT-END-TEST ─── . ────
```

| Name | Description |
| -- | -- |
| `<case-name>` | Any COBOL word. The whole section name must be ≤ 30 characters |
| `<given>` | Statements that set up working storage |
| `<when>` | A `PERFORM` of the business section or paragraph under test |
| `<then>` | One or more assertion commands |

The three parts are conventions, not syntax. A case with no `GIVEN` is fine if the behaviour needs no setup, and assertions may be combined with further `PERFORM`s when you are testing a sequence.

---

## Naming A Case

| Prefix | Effect |
| -- | -- |
| `TEST-` | The section is executed, counted and reported |
| `SKIP-` | The section is not executed and is reported as `[SKIP]` |

---

## What A Case Can Assume

Each case starts from a known baseline. You do not need to arrange any of this yourself:

- The **execution trace is empty**. Anything `CUT-ASSERT-TRACE` finds was recorded by this case.
- **`BEFORE-EACH` has already run**, so shared state has been reset.
- **Mocks are active** for the whole run.
- **Trace fields are being captured** on entry to every business section. `WITH` can only assert on fields registered there.

What a case must *not* assume is that it runs alone. All cases share one working storage and run in source order, so a value left behind by an earlier case is visible to this one. Anything this case depends on, it must set in its own `GIVEN` — or it belongs in `BEFORE-EACH`.

Configuring `BEFORE-EACH` and the captured field list is covered in `TEST-SUITE.md`.

---

# Assertion Reference

The commands available inside a test case.

---

## CUT-ASSERT-EQUALS

Asserts that two **text** values are equal.

### Fields Used
`CUT-ASSERT-TARGET` `PIC X(256)` - the expected value
`CUT-ASSERT-ACTUAL` `PIC X(256)` - the actual value

```COBOL
           MOVE 'ACCEPT' TO CUT-ASSERT-TARGET
           MOVE WS-REQ-STATUS TO CUT-ASSERT-ACTUAL
           PERFORM CUT-ASSERT-EQUALS
```

Both fields are cleared automatically afterwards, so a case can hold as many assertions as it needs.

### Assertion Error Output
```
[FAIL] Expected REJECT but got ACCEPT
```

---

## CUT-ASSERT-EQUALS-NUM

Asserts that two **numeric** values are equal. Use this for anything with decimal places or high precision.

### Fields Used
`CUT-ASSERT-TARGET-N` `PIC S9(18)V9(18)` - the expected value
`CUT-ASSERT-ACTUAL-N` `PIC S9(18)V9(18)` - the actual value

```COBOL
           MOVE 70 TO CUT-ASSERT-TARGET-N
           MOVE WS-ON-HAND TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM
```

### Assertion Error Output
```
[FAIL] Expected 99.00 but got 70.00
```

Values display to two decimal places. When two decimal places would print the expected and actual as the same string, full precision is shown instead:

```
[FAIL] Expected 3.333000000000000000 but got 3.334000000000000000
```

### Picking The Right One

The two assertions are not interchangeable, and using the wrong one is caught and reported as an `[ERROR]` rather than a `[FAIL]`:

```
[ERROR] USE CUT-ASSERT-EQUALS-NUM TO EVALUATE NUMBERS
[ERROR] USE CUT-ASSERT-EQUALS TO EVALUATE STRINGS
```

An `[ERROR]` means the case never really ran. Treat it as a broken test, not a failing one.

---

## CUT-ASSERT-CONTAINS

Asserts that a **text** value contains another. Use it when only part of a value matters — a code inside a message, a name inside a formatted line — so the assertion does not break every time an unrelated part of the text changes.

### Fields Used
`CUT-ASSERT-TARGET` `PIC X(256)` - the value you expect to find
`CUT-ASSERT-ACTUAL` `PIC X(256)` - the value your program produced

The case passes when **`CUT-ASSERT-TARGET` is contained within `CUT-ASSERT-ACTUAL`**. The fields mean the same as they do for `CUT-ASSERT-EQUALS` — the target is what you expected, the actual is what the code gave you.

```COBOL
           MOVE 'REJECT' TO CUT-ASSERT-TARGET
           MOVE WS-RESPONSE-TEXT TO CUT-ASSERT-ACTUAL
           PERFORM CUT-ASSERT-CONTAINS
```

That passes when `WS-RESPONSE-TEXT` holds `REQUEST REJECTED - NO STOCK`, and keeps passing if the wording either side of `REJECT` is reworked later.

Both fields are cleared automatically afterwards, so a case can hold as many assertions as it needs.

### Assertion Error Output
```
[FAIL] Expected to contain REJECT but got REQUEST ACCEPTED
```

### What Counts As A Match

- **Position does not matter.** The target may sit at the start, in the middle, at the end, or be the whole value.
- **The match is case sensitive.** `smith` is *not* found in `JOHN SMITH`.
- **Spaces around the target are ignored.** A `PIC X(256)` field is mostly padding, so the target is trimmed before searching — at both ends, so `' SMITH'` and `'SMITH'` behave the same.
- **Spaces inside the target are kept.** `'SMITH JR'` is found in `'JOHN SMITH JR TOO'`.
- **A target longer than the actual simply fails.**

### An Empty Target Is An Error

Leaving `CUT-ASSERT-TARGET` as spaces is reported as an `[ERROR]`, not a pass:

```
[ERROR] CUT-ASSERT-CONTAINS NEEDS A TARGET VALUE
```

Every value contains nothing, so an empty target would be an assertion that can never fail — a test that looks green and checks nothing. It is treated as a broken test instead.

### There Is No Numeric Contains

Populating the numeric fields is reported the same way:

```
[ERROR] CUT-ASSERT-CONTAINS ONLY EVALUATES STRINGS
```

To check part of a number, move it to a text field first and assert on that — bearing in mind that how it is written (leading zeros, a sign, a decimal point) is then part of what you are matching.

---

## CUT-ASSERT-TRACE

Asserts on the **execution flow** — which sections ran, in what order, and what working storage held when they were entered.

### Fields Used
`CUT-TRACE` `PIC X(1000)` - the assertion

```COBOL
           STRING 'AB000-VALIDATE-REQUEST '
                  'FOLLOWED-BY ZZ000-WRITE-AUDIT '
                  'NOT FOLLOWED-BY AC000-ALLOCATE-STOCK '
                  DELIMITED BY SIZE
                  INTO CUT-TRACE
           END-STRING
           PERFORM CUT-ASSERT-TRACE
```

### Assertion Error Output
```
[FAIL] UNABLE TO FIND ZZ000-WRITE-AUDIT IN EXECUTION TRACE
```

The full keyword set — `FOLLOWED-BY`, `DIRECTLY-FOLLOWED-BY`, `NOT`, `WITH` — is documented in `ASSERT-TRACE.md`.

---

## CUT-FAIL

Fails the current case directly, for a condition the assertions cannot express.

### Fields Used
`CUT-DISPLAY-FAIL-MSG` `PIC X(150)` - an optional message

```COBOL
           IF WS-REC-COUNT > WS-LIMIT
               MOVE 'MORE RECORDS WRITTEN THAN THE LIMIT ALLOWS'
                  TO CUT-DISPLAY-FAIL-MSG
               PERFORM CUT-FAIL
           END-IF
```

### Output
```
[FAIL] MORE RECORDS WRITTEN THAN THE LIMIT ALLOWS
```

Try to always supply a message. A bare `CUT-FAIL` prints `[FAIL]` with nothing after it, and a reader has to open the source to find out what went wrong.

---

## CUT-END-TEST

Ends the case and records its result. Every `TEST-` case must end with it.

```COBOL
           PERFORM CUT-END-TEST
```

Put it once, at the very end, and make sure every path reaches it.

A case that exits before `CUT-END-TEST` is **not counted**. The summary then disagrees with the report above it:

```
TEST CASE - TEST-EXITS-EARLY
[FAIL] Expected 1.00 but got 2.00
TEST CASE - TEST-RUNS-AFTER-EARLY-EXIT
[PASS]

TEST EXECUTION RESULTS
===================================================
PASS : 1
FAIL : 0                <-- the failure above was never counted
SKIP : 0
===================================================
```

---

## CUT-DEBUG-DISPLAY-TRACE

Displays the recorded execution trace as a table. This is the tool to reach for when a case fails and you cannot see why.

```COBOL
           PERFORM AA000-MAIN
           PERFORM CUT-DEBUG-DISPLAY-TRACE
```

### Output
```
EXECUTION TRACE TABLE
|------------------------|------------|---------------|
| SECTION-NAME           | WS-REQ-QTY | WS-REQ-STATUS |
|------------------------|------------|---------------|
| AA000-MAIN             | 00025      |               |
|------------------------|------------|---------------|
| AB000-VALIDATE-REQUEST | 00025      |               |
|------------------------|------------|---------------|
| ZZ000-WRITE-AUDIT      | 00025      | REJECT        |
|------------------------|------------|---------------|
```

It answers the two questions a failing trace assertion raises: which sections actually ran, and what the captured fields actually held. The values shown are the exact text a `WITH` clause is compared against.

This goes to **stdout**, not to the test report, so run `./testpgm > out.txt` to capture it.

---

# Case Outcomes

| Outcome | Meaning |
| -- | -- |
| `[PASS]` | No assertion found a reason to fail |
| `[FAIL]` | An assertion failed, or you performed `CUT-FAIL` |
| `[SKIP]` | The case was prefixed `SKIP-` |
| `[ERROR]` | The case could not complete for some reason |

Consequences worth knowing:

- Cases are assumed to have passed, and assertions look for reasons to fail them. **An empty test case passes.** So does one whose assertions were never reached.
- A failure is **sticky**. Once a case has failed, a later passing assertion in the same case cannot flip it back to passing.
- Every `CUT-ASSERT-EQUALS`, `CUT-ASSERT-EQUALS-NUM` and `CUT-ASSERT-CONTAINS` in a case still runs and still reports after an earlier failure, so one case can print several `[FAIL]` lines:

```
TEST CASE - TEST-TWO-FAILURES
[FAIL] Expected 1.00 but got 2.00
[FAIL] Expected AAA but got BBB
[FAIL] Expected 7.00 but got 8.00
[FAIL]
```

- `CUT-ASSERT-TRACE` traverses the trace until it finds a fail point, at which it will output what the fail condition was. The message names the section and, where one is involved, the field — so a trace failure usually reads without opening the source:

```
TEST CASE - TEST-REJECT-IS-AUDITED
[FAIL] OPERATION EVALUATION FAILED FOR WS-REQ-STATUS ON SECTION ZZ000-WRITE-AUDIT
[FAIL] ASSERTED WS-REQ-STATUS =  ACCEPT
[FAIL] AND GOT WS-REQ-STATUS = REJECT
[FAIL]
```

A `WITH` clause that did not hold. The section was reached — the value it was entered with was not the asserted one.

---

# Skipping A Case

Change the prefix from `TEST-` to `SKIP-`. The body is not executed, and the case is reported on every run so it cannot be quietly forgotten:

```COBOL
       SKIP-ZERO-QTY-IS-REJECTED SECTION.
      *> NOT YET WRITTEN - COUNTED AS SKIPPED, NEVER EXECUTED

           MOVE 10 TO WS-ON-HAND
           MOVE 0  TO WS-REQ-QTY
           PERFORM AA000-MAIN
           PERFORM CUT-END-TEST
       .
```

```
TEST CASE - SKIP-ZERO-QTY-IS-REJECTED
[SKIP]
```

Because the body never runs, a `SKIP-` case cannot break the build through its own logic, and `CUT-END-TEST` never executes for it.

Use `SKIP-` for a case that is known-broken, not-yet-written, or blocked. Prefer it to commenting a case out: a commented case is invisible, a skipped one is reported every run and rots loudly.

---

# Techniques

## Test a section on its own

The test suite enables "White-box testing", meaning the TEST-CASE has access to all procedures and working storage fields of the business program. Set the state they expect and perform them directly, allowing for isolated logic proofing:

```COBOL
       TEST-ALLOCATE-DRAWS-DOWN SECTION.
           *> GIVEN - STATE SET DIRECTLY, NO CALLER INVOLVED
           MOVE 100 TO WS-ON-HAND
           MOVE 30  TO WS-REQ-QTY

           *> WHEN - ONE SECTION, NOT LOGIC THAT INVOKES IT
           PERFORM AC000-ALLOCATE-STOCK

           *> THEN
           MOVE 70 TO CUT-ASSERT-TARGET-N
           MOVE WS-ON-HAND TO CUT-ASSERT-ACTUAL-N
           PERFORM CUT-ASSERT-EQUALS-NUM

           PERFORM CUT-END-TEST
       .
```

This enables testing a branch that is awkward to trigger from the top — an error handler, a boundary, an overflow.

## Assert that a boundary was reached

A mock can record that it ran, which turns an external call into something a case can assert on.

Declaring the mock itself is covered in `TEST-SUITE.md`.

## Assert on flow when there is no result to read back

Code that calls out, writes a record, or displays an error, changes no working storage that a value assertion can inspect. `CUT-ASSERT-TRACE` is how those are tested:

```COBOL
           STRING 'BC-DIV-NUMBERS '
                  'FOLLOWED-BY CA-DISPLAY-ERROR'
                  DELIMITED BY SIZE
                  INTO CUT-TRACE
           END-STRING
           PERFORM CUT-ASSERT-TRACE
```

Two keywords extend this beyond what a value check can reach: `NOT` proves an absence — that a rejected request never reached the allocation logic — and `WITH` asserts on a field at the moment a section was entered, rather than at the end of the run, which matters when a later section overwrites it. Both are documented in `ASSERT-TRACE.md`.

---

# Gotchas

## Section names are limited to 30 characters

This applies to the whole name including the `TEST-` or `SKIP-` prefix. Longer names are accepted by some compilers and rejected by others.

---

# See Also

- `TEST-SUITE.md` — assembling the test program, `BEFORE-EACH`, captured fields, mocks, and running the suite
- `ASSERT-TRACE.md` — the execution-flow assertion keywords
- `README.md` — the concept, and why testing at this level is worth it
