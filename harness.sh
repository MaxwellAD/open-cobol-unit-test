#!/bin/bash

# Define your source and target files
BUSINESS_PGM=$1 # PGM TO TEST
TEST_PGM=$2 # TEST PGM
PREFIX="MOCK-"

# Where the generated copybooks go - build output, inside the project under
# test, next to the source it was generated from. This lets editor tooling 
# resolves a workspace-relative path.
WORK_DIR="${COBTEST_WORK:-target}"

# The generated members go in a library of their own, one per business program,
# so two programs' STORAGE can't collide and a test program says which one it
# means: COPY STORAGE OF LINKAGE-PGM. GnuCOBOL resolves the library name as a
# directory under the copy path, so the library IS the directory name.
#
# cobtestrun sets COBTEST_LIB, because by the time the harness runs it has been
# handed a precompiled copy of the program and can no longer see where the
# original sat in the tree. Standalone, fall back to the file's own name.
LIB="${COBTEST_LIB:-$(basename "$BUSINESS_PGM")}"
LIB="$(printf '%s' "${LIB%.*}" | tr '[:lower:]' '[:upper:]')"
WORK_DIR="$WORK_DIR/$LIB"
mkdir -p "$WORK_DIR"
# Get everything post precedure division piped into adding section tracing

#=====================
# Business Program
#=====================

# Instantiate MOCKS
# For any section in the TEST_PGM that starts with MOCK-XXX
# Search for a corresponding XXX section in the BUSINESS_PGM
# Output all to $WORK_DIR/mocked.cbl
awk -v p="$PREFIX" '
  # === PHASE 1: Parse the NEW_CODE file ===
  NR==FNR { 
    # Match the prefix starting anywhere in columns 8-11 (Area A)
    if (substr($0, 8, length(p)) == p) {
      # Extract the name from column 8 onwards, removing the prefix
      match(substr($0, 8), /^[A-Za-z0-9#-]+/)
      sec = substr($0, 8 + length(p), RLENGTH - length(p))
      next
    } 
    # Stop capturing if we hit another Area A element (starts at column 8, ends with a period)
    if (sec && substr($0, 8) ~ /^[A-Za-z0-9#-]+.*\.(\s|$)/) { 
      sec = "" 
    } 
    # Accumulate the replacement code lines
    if (sec) { 
      code[sec] = code[sec] $0 "\n" 
    }
    next 
  }

  # === PHASE 2: Process and Update the OLD_CODE file ===
  {
    # Print the current line of OLD_CODE first
    print 
  }

  # Check if this line defines a Paragraph or Section in Area A (Column 8)
  # It must start with an alphanumeric character in column 8 and eventually contain a period
  substr($0, 8, 1) ~ /[A-Za-z0-9#-]/ && substr($0, 8) ~ /^[A-Za-z0-9#-]+.*\.(\s|$)/ {
    # Extract the clean paragraph/section name from column 8
    match(substr($0, 8), /^[A-Za-z0-9#-]+/)
    name = substr($0, 8, RLENGTH)
    
    # If we captured replacement code for this specific name, inject it
    if (code[name]) { 
      printf "%s", code[name] 
    }
  }
' $TEST_PGM $BUSINESS_PGM > "$WORK_DIR/mocked.cbl"

# Get all working storage lines - output to STORAGE.cpy
awk '
  # 1. Match the starting line: Column 8-11 contains WORKING-STORAGE SECTION.
  # Substr checks from character 8 (length 23 matches "WORKING-STORAGE SECTION.")
  substr($0, 8, 24) ~ /^WORKING-STORAGE SECTION\./ {
    inside = 1;
    next; # Skip printing the header line itself
  }

  # 2. Match the stopping lines starting at column 8
  inside && (substr($0, 8, 18) ~ /^PROCEDURE DIVISION/        ||
             substr($0, 8, 21) ~ /^LOCAL-STORAGE SECTION/     ||
             substr($0, 8, 15) ~ /^LINKAGE SECTION/) {
    inside = 0;
  }

  # 3. Print lines while inside the block
  inside
' "$WORK_DIR/mocked.cbl" > "$WORK_DIR/STORAGE.cpy"

# The generated program PERFORMs sections, it never CALLs the business program,
# so there is no caller to supply the parameters and no invocation boundary to
# re-initialise on. LOCAL-STORAGE and LINKAGE items therefore become ordinary
# working storage
# Both blocks append to STORAGE.cpy, which the test program COPYs inside its own
# WORKING-STORAGE SECTION. Lines pass through verbatim, so a COPY member declared
# in either section is relocated as-is and left for the compiler to resolve.

# Get all local storage lines - append to STORAGE.cpy
awk '
  # 1. Match the starting line: Column 8 starts with LOCAL-STORAGE SECTION.
  substr($0, 8, 22) ~ /^LOCAL-STORAGE SECTION\./ {
    inside = 1;
    print "      * LOCAL-STORAGE SECTION RELOCATED BY THE HARNESS";
    next; # Skip printing the header line itself
  }

  # 2. Match the stopping lines starting at column 8
  inside && (substr($0, 8, 18) ~ /^PROCEDURE DIVISION/ ||
             substr($0, 8, 15) ~ /^LINKAGE SECTION/) {
    inside = 0;
  }

  # 3. Print lines while inside the block
  inside
' "$WORK_DIR/mocked.cbl" >> "$WORK_DIR/STORAGE.cpy"

# Get all linkage section lines - append to STORAGE.cpy
awk '
  # 1. Match the starting line: Column 8 starts with LINKAGE SECTION.
  substr($0, 8, 16) ~ /^LINKAGE SECTION\./ {
    inside = 1;
    print "      * LINKAGE SECTION RELOCATED BY THE HARNESS";
    next; # Skip printing the header line itself
  }

  # 2. Match the stopping lines starting at column 8
  inside && (substr($0, 8, 18) ~ /^PROCEDURE DIVISION/ ||
             substr($0, 8, 21) ~ /^LOCAL-STORAGE SECTION/) {
    inside = 0;
  }

  # 3. Print lines while inside the block
  inside
' "$WORK_DIR/mocked.cbl" >> "$WORK_DIR/STORAGE.cpy"

# Get all procedure division lines, then add the section tracing to the sections and paragraphs - output to PROGRAM.cpy
awk '
  !found && /PROCEDURE DIVISION/ { 
    found=1; 
    if ($0 ~ /\./) { print_now=1; next } 
    next 
  }
  found && !print_now { 
    if ($0 ~ /\./) { print_now=1 } 
    next 
  }
  print_now
' "$WORK_DIR/mocked.cbl" | sed -E 's/(^.{6}[^*] {0,3}([A-Z|0-9|\-]+).*\.)/\1\n           MOVE "\2"\n           TO CUT-TEMP-SECTION-NAME\n           PERFORM CUT-ADD-TRACE-SECTION/' > "$WORK_DIR/PROGRAM.cpy"

# Environment division and data division need to be incorporated to make the compiler happy, even if the files are never accessed at runtime

# Get all data division lines - output to DATADIV.cpy
awk '
  # 1. Match the starting line: Column 8 starts with DATA DIVISION.
  substr($0, 8, 14) ~ /^FILE SECTION\./ {
    inside = 1;
    next; # Skip printing the header line itself
  }

  # 2. Match the stopping lines starting at column 8
  inside && (substr($0, 8, 23) ~ /^WORKING-STORAGE SECTION/ || 
             substr($0, 8, 21) ~ /^LOCAL-STORAGE SECTION/   ||
             substr($0, 8, 15) ~ /^LINKAGE SECTION/         || 
             substr($0, 8, 18) ~ /^PROCEDURE DIVISION/) {
    inside = 0;
  }

  # 3. Print lines while inside the block
  inside
' "$WORK_DIR/mocked.cbl" > "$WORK_DIR/FILESEC.cpy"

# Get all environment division lines - output to ENVDIV.cpy
awk '
  # 1. Match the starting line: Column 8 starts with ENVIRONMENT DIVISION.
  substr($0, 8, 21) ~ /^FILE-CONTROL\./ {
    inside = 1;
    next; # Skip printing the header line itself
  }

  # 2. Match the stopping lines starting at column 8
  inside && (substr($0, 8, 14) ~ /^DATA DIVISION/            || 
             substr($0, 8, 23) ~ /^WORKING-STORAGE SECTION/ || 
             substr($0, 8, 21) ~ /^LOCAL-STORAGE SECTION/   ||
             substr($0, 8, 15) ~ /^LINKAGE SECTION/         || 
             substr($0, 8, 18) ~ /^PROCEDURE DIVISION/) {
    inside = 0;
  }

  # 3. Print lines while inside the block
  inside
' "$WORK_DIR/mocked.cbl" > "$WORK_DIR/FILECTL.cpy"




#=====================
# Test Program
#=====================

# Add a move the test case name and perform the test case init routine
sed -E '/PROCEDURE DIVISION/,$ { /^[[:space:]]{1,7}(TEST-)[A-Za-z0-9_-]*(\s+SECTION)?\./ { /PROCEDURE DIVISION/b; p; s/^[[:space:]]*([A-Za-z0-9_-]+).*/            MOVE "\1"\n           TO CUT-TEST-NAME \n           PERFORM CUT-TEST-INIT./ } }' $2 |

# Add file output opening
sed '/PROCEDURE DIVISION/a\       OPEN-OUTPUT SECTION.\n           OPEN OUTPUT CUT-OUT .\n           MOVE SPACES TO CUT-OUT-RECORD .' |

# Remove SKIP- sections
sed '/^[[:space:]]*SKIP-/,/^[[:space:]]*[A-Za-z0-9-]\+[[:space:]]\+SECTION\./ { /^[[:space:]]*SKIP-/b; /^[[:space:]]*[A-Za-z0-9-]\+[[:space:]]\+SECTION\./b; d }' | \
sed '/^[[:space:]]*SKIP-/a\          .' |
sed -E '/PROCEDURE DIVISION/,$ { /^[[:space:]]{1,7}(SKIP-)[A-Za-z0-9_-]*(\s+SECTION)?\./ { /PROCEDURE DIVISION/b; p; s/^[[:space:]]*([A-Za-z0-9_-]+).*/            MOVE "\1"\n           TO CUT-TEST-NAME \n           PERFORM CUT-SKIP/ } }' > test-pgm-out.cbl
