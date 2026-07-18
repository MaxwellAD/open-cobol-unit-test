# ASSERT-TRACE User Manual

## Description
Validate complex execution flows and working storage constraints

---

## Fields Used
`CUT-TRACE` - Store the assertion

## Usage Example
```COBOL
STRING 'SECTION-A '
       'FOLLOWED-BY SECTION-B'
       DELIMITED BY SIZE
       INTO CUT-TRACE 
END-STRING
PERFORM CUT-ASSERT-TRACE 
```

Sets `CUT-TEST-FAIL` to true if `SECTION-B` does not follow `SECTION-A`

---

## Syntax Diagram
```

──────┬─── <trace-target> ───┬───────────────────────────────────────────────────────┬──────┬────────────────────────────────────────────────────────────── 
      │                      │                                                       │      │                      
      │                      └─ WITH ─────┬── FIELD-A = <value> ──┬───── END-WITH ───┘      └──┬───────────┬────┬────── FOLLOWED-BY ───────┬─────┐
      │                                   │                       V                            │           │    │                          │     V
      │                                   └───────────<───────────┘                            └─── NOT ───┘    └── DIRECTLY-FOLLOWED-BY ──┘     │
      │                                                                                                                                          │
      └────────────────<───────────────────────<───────────────────────────────<──────────────────────────────────────<──────────────────────────┘
```

| Name | Description |
| -- | -- |
|`<trace-target>` | A `paragraph` or `section` name found in the business program being tested |
|`<value>` | A field that has been registered as a trace field in `CUT-TRACE-FIELDS SECTION.` inside the test program |

---

## Key Words

### FOLLOWED-BY
Enables the chaining of various `<trace-target>` to build a complex execution flow assertion

```
SECTION-A
FOLLOWED-BY SECTION-B
```

Asserts that `SECTION-A` must happen, and then `SECTION-B` must follow before the end of execution

#### Assertion Error Output
```
[FAIL] UNABLE TO FIND SECTION-B IN EXECUTION TRACE
```

---

### DIRECTLY-FOLLOWED-BY
A strict version of `FOLLOWED-BY` which asserts that the `<trace-target>` must be the very next item in the trace

```
SECTION-A
DIRECTLY-FOLLOWED-BY SECTION-B
```

Asserts that `SECTION-A` must happen, and that the very next section to open is `SECTION-B`

Note - this doesn't necessarily assert that `SECTION-A` completes followed by `SECTION-B`. `SECTION-B` being invoked as a part of `SECTION-A`'s execution will also satisfy the case

Use this sparringly as it leads to rigid code

#### Assertion Error Output
```
[FAIL] UNABLE TO FIND SECTION-B DIRECTLY AFTER SECTION-A IN EXECUTION TRACE
```

---

### NOT
A modifier to the `FOLLOWED-BY` and `DIRECTLY-FOLLOWED-BY` statements

`NOT` `FOLLOWED-BY` asserts the reverse of `FOLLOWED-BY`, where `FOLLOWED-BY` needs the section to pass the test, `NOT` `FOLLOWED-BY` needs to not see the section

`NOT` `FOLLOWED-BY` searches from its location in the trace until the end of the trace but does not update the index, so the next non-NOT followed by will pick up from that last

`NOT` `DIRECTLY-FOLLOWED-BY` asserts that the very next section must not be the one specified

#### Example
```
UPDATE-DATABASE
FOLLOWED-BY HANDLE-DATABASE-ERROR
NOT FOLLOWED-BY COMMIT-DATABASE-UPDATE
FOLLOWED-BY ROLLBACK-UPDATE
```

Asserts that we `UPDATE-DATABASE` to run, followed by `HANDLE-DATABASE-ERROR`, after handling the database error, `COMMIT-DATABASE-UPDATE` can `NOT` run



---

### WITH 

Must be used following a `<trace-target>`

Defines a constraint of working storage at the beginning of the trace target

```
SECTION-A 
WITH 
    FIELD-A = "0.00"
END-WITH
```

Asserts that when `SECTION-A` beings execution, `FIELD-A` must have the value of "0.00"

#### Assertion Error Outut
```
[FAIL] OPERATION EVALUATION FAILED FOR FIELD-A ON SECTION SECTION-A
[FAIL] EXPECTED 0.00 
[FAIL] BUT GOT <actual value of FIELD-A>
```
