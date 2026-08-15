# Contributing to Open COBOL Unit Test

`README.md` covers what this project is and why it exists. This file is the
practical "how to work in the codebase" reference.

## Prerequisites

- **GnuCOBOL 3.x** — developed and tested against 3.1.2.0
- A POSIX shell (`harness.sh` is bash)

No JVM, no runner, no external test-definition format. If you can compile
COBOL, you can build and run this.

## Getting the code

The default branch (`main`) holds only the README and the licence. There is
no "version 1" yet, and an empty default branch is a deliberate signal that
nothing here is stable — not an oversight. All development happens on
`prototype`:

```sh
git clone --branch prototype \
  https://github.com/MaxwellAD/open-cobol-unit-test.git
cd open-cobol-unit-test
```

Branch from `prototype`, and target your pull request at `prototype`.

## Design principles

These explain most of the constraints below, and PRs are weighed against
them:

- **Portability is a feature, not a chore.** EBCDIC-safe output, the 30-char
  word limit, MVS/IBM-strict gates. It must run wherever COBOL runs.
- **It's just COBOL.** The developer only ever writes COBOL — no second
  language, no YAML/XML test file, no external runner. The harness's text
  extraction and instrumentation is machinery the user never touches.
- **Test COBOL as it actually is** — stateful, sequenced. The
  trace assertions embrace shared state and execution order rather than
  demanding the code be refactored into something "testable" first.
- **Readable by people who can't write it.** The trace DSL
  (`A FOLLOWED-BY B WITH <field> = <value>`) is deliberately English-like
  and COBOL-shaped, so a technical lead can grasp what a case asserts even
  if they couldn't author it.

For anything larger than a bug fix, please **open an issue before writing code**. A
short conversation about direction costs a few minutes; a substantial pull
request that turns out not to fit the principles above is a bad outcome for
everyone involved.

## Build, compile, run (the loop)

The test program is **generated** — always run the harness before compiling,
or you'll compile a stale `test-pgm-out.cbl`:

```sh
# 1. Generate test-pgm-out.cbl from the business pgm + test pgm
./harness.sh Examples/Example01/pgm-to-test.cbl Examples/Example01/test-pgm.cbl

# 2. Compile (copybooks resolve from tmp/ then CUT/)
cobc -x test-pgm-out.cbl -o testpgm -I "tmp" -I "CUT"

# 3. Run
./testpgm
```

`harness.sh <business-pgm> <test-pgm>` extracts the business program's
divisions into copybooks under `tmp/`, instruments a trace breadcrumb at the
top of every section/paragraph, wires up test-case init, and writes the
combined program to `test-pgm-out.cbl`.

### Checking it worked

`./testpgm` prints little or nothing to your terminal — results are written
to the **`CUT-RPTO`** file, not stdout. Open it; a healthy run ends with:

```
TEST EXECUTION RESULTS
===================================================
PASS : 53
FAIL : 0
SKIP : 0
===================================================
```

Individual cases appear above that as `TEST CASE - <NAME>` followed by
`[PASS]` or `[FAIL]`. The pass count grows as the suite does, so don't treat
that number as fixed — `FAIL : 0` is the part that matters.

If your terminal looked empty and you assumed nothing ran, this is why. See
[Where output goes](#where-output-goes).

## Optional build gates

Both are good CI candidates and both currently pass clean.

### MVS / Unix compliance check

The default `cobc` build is lenient. To validate that all user-defined words
stay within the traditional 30-character COBOL limit (so the source is clean
under strict/mainframe compilers and IBM Z Open Editor), compile with the
word-length gate — it passes clean or names each offender with a line
number:

```sh
cobc -fsyntax-only -fword-length=30 test-pgm-out.cbl -I "tmp" -I "CUT"
```

Add `-std=mvs-strict` (or `ibm-strict`) for a fuller dialect check. Keep
this as a per-run option, not the default, so users who don't target the
mainframe aren't forced through it.

### Bounds-checking build

Build with `-debug` to turn on GnuCOBOL runtime checks (subscript /
reference-modification bounds). The default build is lenient and lets an
out-of-bounds subscript silently corrupt memory (you'll get a `SIGSEGV`
somewhere unrelated); `-debug` fails fast and names the exact field, line,
and offending subscript:

```sh
cobc -x -debug test-pgm-out.cbl -o testpgm_dbg -I "tmp" -I "CUT"
./testpgm_dbg
```

Named separately on purpose — building it as `testpgm` would overwrite your
normal binary, and you'd carry on running bounds-checked builds without
realising.

## Where output goes

- **Test results** (`TEST CASE`, `[PASS]`/`[FAIL]`, the summary) are written
  to the **`CUT-RPTO`** file — `CUT-OUT` (`SELECT ... ASSIGN TO CUT-RPTO`,
  record `CUT-OUT-RECORD PIC X(160)`) via `CUT-WRITE-UT-RECORD`.
- **`DISPLAY` statements** (e.g. the debug trace table) go to **stdout**.

So to verify a run, check `CUT-RPTO` for pass/fail, and redirect stdout
(`./testpgm > out.txt`) for anything `DISPLAY`ed.

## Self-testing model (DUT / CUT)

The framework tests itself. Everything framework-owned is prefixed `CUT-`
(COBOL Unit Test). To avoid name clashes when testing itself, the test suite
exercises an imaginary mirror prefixed `DUT-` (Dummy Unit Test). New
features are prototyped in DUT, verified, then promoted to CUT.
`Examples/Example01` is the self-test suite.

**If you change a `CUT-` section, mirror it to `DUT-` in
`Examples/Example01/pgm-to-test.cbl`.** This is currently hand-maintained.

### Self-test trace capacity (a real limit)

The harness extracts the business program (`pgm-to-test.cbl`, i.e. the
`DUT-*` sections) into `tmp/PROGRAM.cpy` and injects a
`PERFORM CUT-ADD-TRACE-SECTION` breadcrumb at the top of **every**
business-program section. The `CUT-*` framework copybook (`COPY CUTPROC`)
is *not* instrumented. So during a self-test run the real framework trace
(`CUT-RT-TRACE`, `OCCURS 100`) records every `DUT-*` section entry, and
clears only **per test case**. Consequences:

- A single test case can't cause more than ~100 `DUT-*` section entries —
  e.g. `PERFORM`ing an instrumented section in a 100-iteration loop, or
  rendering a large debug table (`DUT-DEBUG-*` helpers are instrumented, so
  each cell fires a breadcrumb), overflows the trace and `SIGSEGV`s.

Work around it in tests by building large fixtures **inline** (a
`PERFORM VARYING` inside one section fires no new breadcrumb), and by
testing capacity-limit branches white-box — set the internal state directly
and call the target section once, rather than driving it through the full
front-door render path. See `TEST-DEBUG-COLUMN-OVERFLOW`.

## Writing test cases

The assertion and trace DSL has its own user manuals under `Manuals/`. Read
these before adding cases — they are the authoring reference, and nothing in
this file duplicates them:

- **`Manuals/TEST-CASE.md`** — the anatomy of a test case, the syntax
  diagram, and naming conventions. Start here.
- **`Manuals/ASSERT-TRACE.md`** — the execution-flow DSL
  (`A FOLLOWED-BY B WITH <field> = <value>`), the fields it uses, and a
  worked example.
- `Manuals/TEST-SUITE.md` — currently a stub.

`Examples/Example01/test-pgm.cbl` is the largest worked example available:
it's the framework's own suite, so essentially every assertion in the
library is exercised somewhere in it.

## Project layout

- `CUT/` — the framework copybooks:
  - `CUTSTOR.cpy` — working storage
  - `CUTPROC.cpy` — the helper sections/paragraphs (assertions, trace, etc.)
  - `CUTDATA.cpy`, `CUTENV.cpy` — FD / SELECT plumbing
- `Examples/Example01/` — `pgm-to-test.cbl` (business pgm) +
  `test-pgm.cbl` (the tests). This is the self-test.
- `harness.sh` — the extract/instrument/generate precompiler.
- `test-pgm-out.cbl` — generated; do not hand-edit.
- `Manuals/` — user-facing docs for the assertion and trace DSL.

## COBOL fixed-format gotchas

These have all bitten real edits in this codebase:

- **Columns 8–72 only.** Code past column 72 is silently truncated — wrap
  long statements. You may break before a `(` of a subscript/reference-mod
  and around the `:` in reference modification.
- **`FUNCTION LENGTH` of a fixed field returns the field size,** not the
  trimmed length. For the real text length use
  `FUNCTION LENGTH(FUNCTION TRIM(field))`.
- **User-defined words ≤ 30 characters.** Section, paragraph, and data names
  must fit the traditional 30-char COBOL limit — GnuCOBOL's default allows
  longer, but strict/mainframe compilers and Z Open Editor reject them.
  Verify with the word-length gate above. (The framework already honors
  this, e.g. `CUT-HANDL-DIRECTLY-FOLLOWED-BY` drops the `E` to fit.)

## EBCDIC / portability

Output is meant to survive an EBCDIC environment — avoid box-drawing
characters; stick to `|` and `-` for tables.

## Optional: coverage precompiler

`open-cobol-code-coverage` provides `DISPLAY-COVERAGE`. If a test program
`PERFORM DISPLAY-COVERAGE`s, it only resolves when built through that
precompiler — a plain `cobc` build will fail with `'DISPLAY-COVERAGE' is not
defined`. Remove or guard that call for a plain build.

## Before you submit

1. Regenerate — `./harness.sh` before every compile, so you're not testing a
   stale `test-pgm-out.cbl`.
2. The self-test suite passes (check `CUT-RPTO`, not just stdout).
3. The word-length gate passes.
4. The `-debug` bounds-checking build passes.
5. Any change to `CUT-` is mirrored into `DUT-` in
   `Examples/Example01/pgm-to-test.cbl`, and vice versa. The mirror is
   hand-maintained in both directions.

### Structuring the change

Not a gate — submit however you like, and a single commit is fine. But if
it's easy for you, this shape speeds up review:

1. The `DUT-` implementation plus its test cases, with `CUT/` untouched.
2. The promotion into `CUT-`.
3. A test case that uses the new `CUT-` assertion directly.

The reason is that the framework tests itself: the assertions under `CUT/`
are what validate the `DUT-` mirror, so a change touching both at once can
end up checking its own work. Splitting it means step 1 is verified by
assertions that predate the change. Step 3 matters because nothing else
exercises the promoted code — the earlier tests only ever tested `DUT-`, so
a slip made while renaming `DUT-` to `CUT-` would otherwise be caught only
by accident.

If that's more git surgery than you fancy, send one commit and say so in the
PR. The maintainer check below covers the same property.

## Questions and bugs

Open an issue on GitHub — for bug reports, feature suggestions, or simply to
ask how something is meant to work. There's no mailing list or chat channel;
issues are the whole process.

For a bug report, the most useful things to include are the relevant
`CUT-RPTO` output and the `cobc --version` you built with. Dialect and
version differences account for a fair share of surprises.

## Licence

This project is licensed under the **GNU General Public License v3** — see
`LICENSE` for the full text.

Unless you state otherwise, any contribution you submit for inclusion is
licensed under GPL-3 on the same terms, with no additional conditions. There
is no separate CLA to sign.

## For maintainers

### Confirm a `CUT/` change did not validate itself

Before merging anything that touches `CUT/`, rebuild the self-test with the
*target branch's* copybooks asserting against the *PR's* `DUT-` mirror. If
that passes, the new mirror has been verified by known-good assertions:

```sh
# from a checkout of the PR branch
mkdir -p /tmp/cut-baseline
git archive origin/<target-branch> CUT \
  | tar -x -C /tmp/cut-baseline --strip-components=1

./harness.sh Examples/Example01/pgm-to-test.cbl Examples/Example01/test-pgm.cbl
cobc -x test-pgm-out.cbl -o testpgm_baseline -I "tmp" -I "/tmp/cut-baseline"
./testpgm_baseline
```

The baseline copybooks are read out of git into a temp directory rather than
checked out over your files, so the working tree is left alone.

This works on a single-commit PR from someone who has never rebased, so it
doesn't depend on how the contribution was structured — which is what makes
it the durable version of the property. Good CI candidate: the same three
commands with the target branch supplied by the workflow.
