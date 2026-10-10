# Contributing to Open COBOL Unit Test

<!--
SPDX-License-Identifier: GPL-3.0-or-later
SPDX-FileCopyrightText: 2026 MaxwellAD
-->

`README.md` covers what this project is and why it exists. This file is the practical "how to work in the codebase" reference.

## Prerequisites

- **A COBOL Compiler** — developed and tested with GnuCOBOL, with care taken to support other COBOL dialects and compilers
- A POSIX shell (`harness.sh` is bash)

## Getting the code

```sh
git clone https://github.com/MaxwellAD/open-cobol-unit-test.git
cd open-cobol-unit-test
```

## Design principles

These explain most of the constraints below:

- **Portability.** EBCDIC-safe output, the 30-char word limit, MVS/IBM-strict gates. It must run wherever COBOL runs
- **It's just COBOL.** The developer only ever writes COBOL — no second language, no YAML/XML test file.
- **Encourage Better COBOL** Large monolithic sections and paragraphs are difficult to unit test, this feedback is crucial for a developer. The framework shouldn't make it easier to continue bad habbits 
- **Test COBOL as it actually is** However it's naive to assume a developer has a pristine piece of code to start with. Trace assertions should empower large stateful processes to be tested without an implicit requirement to alter the way the codebase is written
- **Readable by people who can't write it.** The trace DSL (`A FOLLOWED-BY B WITH <field> = <value>`) is deliberately English-like and COBOL-shaped, so a technical lead can grasp what a case asserts even if they couldn't author it.

## Optional build gates

### MVS / Unix compliance check

The default gnucobol `cobc` build is lenient. To validate that all user-defined words stay within the traditional 30-character COBOL limit (so the source is clean under strict/mainframe compilers and IBM Z Open Editor), compile with the word-length gate — it passes clean or names each offender with a line number:

```sh
cobc -fsyntax-only -fword-length=30 test-pgm-out.cbl -I "tmp" -I "CUT"
```

Add `-std=mvs-strict` (or `ibm-strict`) for a fuller dialect check. Keep this as a per-run option, not the default, so users who don't target the mainframe aren't forced through it.

### Bounds-checking build

Build with `-debug` to turn on GnuCOBOL runtime checks (subscript / reference-modification bounds). The default build is lenient and lets an out-of-bounds subscript silently corrupt memory.

```sh
cobc -x -debug test-pgm-out.cbl -o testpgm_dbg -I "tmp" -I "CUT"
./testpgm_dbg
```

## Where output goes

Test result are written to the `Reports/` folder.
Any fails should be loudly brought into the STDOUT of the terminal executing cobtest / cobtestrun. With `FAIL`s and `ERROR`s causing a high return code

## Self-testing model (DUT / CUT)

The framework tests itself. Everything framework-owned is prefixed `CUT-` (COBOL Unit Test). To avoid name clashes when testing itself, the test suite exercises an imaginary mirror prefixed `DUT-` (Dummy Unit Test). New features are prototyped in DUT, verified, then promoted to CUT.
`src/main/cobol/pgm-to-test.cbl` is the self-test suite.

## Writing test cases

Please refer to Manuals/ to understand how the various aspects of the unit test framework are supposed to work

`src/test/cobol/testlib/pgm-to-test.cbl/test-pgm.cbl` is the largest worked example available. It's the framework's own suite, so essentially every assertion in the library is exercised somewhere in it.

## Project layout

- `CUT/` — the framework copybooks:
  - `CUTSTOR.cpy` — working storage
  - `CUTPROC.cpy` — the helper sections/paragraphs (assertions, trace, etc.)
  - `CUTDATA.cpy`, `CUTENV.cpy` — FD / SELECT plumbing
- `src/main/cobol/sorlib/` — `pgm-to-test.cbl` (business pgm)
- `src/test/cobol/testlib/test-pgm.cbl` (the tests). This is the self-test.
- `harness.sh` — the extract/instrument/generate precompiler.
- `test-pgm-out.cbl` — generated; do not hand-edit.
- `Manuals/` — user-facing docs for the assertion and trace DSL.

## COBOL fixed-format gotchas

- **User-defined words ≤ 30 characters.** Section, paragraph, and data names must fit the traditional 30-char COBOL limit — GnuCOBOL's default allows longer, but strict/mainframe compilers and Z Open Editor reject them.

## EBCDIC / portability

Output is meant to survive an EBCDIC environment — avoid box-drawing characters; stick to `|` and `-` for tables.

## Optional: coverage precompiler

`open-cobol-code-coverage` provides `DISPLAY-COVERAGE`. If a test program `PERFORM DISPLAY-COVERAGE`s, it only resolves when built through that precompiler — a plain `cobc` build will fail with `'DISPLAY-COVERAGE' is not defined`. Remove or guard that call for a plain build.

## Before you submit

1. Regenerate — cobtest or cobtestrun <business pgm> <test-pgm>
2. The self-test suite passes
3. The word-length gate passes.
4. The `-debug` bounds-checking build passes.
5. Any change to `CUT-` is mirrored into `DUT-` in `src/main/cobol/sorlib/pgm-to-test.cbl`, and vice versa. The mirror is hand-maintained in both directions.

### Structuring the change

CUT tests DUT, don't change both at the same time. If you alter CUT then you can't trust its output as it is unproven

## Questions and bugs

Open an issue on GitHub — for bug reports, feature suggestions, or simply to ask how something is meant to work.

For a bug report, the most useful things to include are the relevant `Replorts/` output and the cobol compiler + version you built with.

## Licence

This project is licensed under the **GNU General Public License v3** — see `LICENSE` for the full text.

Any contribution you submit for inclusion is licensed under GPL-3.
