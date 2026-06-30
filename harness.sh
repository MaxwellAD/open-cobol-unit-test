# Define your source and target files
BUSINESS_PGM=$1 # PGM TO TEST
TEST_PGM=$2 # TEST PGM
PREFIX="MOCK-"
# Get everything post precedure division piped into adding section tracing

#=====================
# Business Program
#=====================

# Instantiate MOCKS
# For any section in the TEST_PGM that starts with MOCK-XXX
# Search for a corresponding XXX section in the BUSINESS_PGM
# Output all to tmp/mocked.cbl <-- should make this a variable and configurable to go to /tmp/
awk -v p="MOCK-" '
  NR==FNR { if ($0 ~ "^[[:space:]]*" p) { sec=substr($1, length(p)+1); next } if ($0 ~ "SECTION\\.") sec="" ; if (sec) code[sec] = code[sec] $0 "\n"; next }
  { print }
  $0 ~ "SECTION\\." { name=$1; if (code[name]) printf "%s", code[name] }
' $TEST_PGM $BUSINESS_PGM > tmp/mocked.cbl 

# Get all working storage lines - output to STORAGE.cpy
awk '
  # 1. Match the starting line: Column 8-11 contains WORKING-STORAGE SECTION.
  # Substr checks from character 8 (length 23 matches "WORKING-STORAGE SECTION.")
  substr($0, 8, 24) ~ /^WORKING-STORAGE SECTION\./ {
    inside = 1;
    next; # Skip printing the header line itself
  }

  # 2. Match the stopping line: PROCEDURE DIVISION or LINKAGE SECTION starting at column 8
  inside && (substr($0, 8, 18) ~ /^PROCEDURE DIVISION/ || substr($0, 8, 15) ~ /^LINKAGE SECTION/) {
    inside = 0;
  }

  # 3. Print lines while inside the block
  inside
' tmp/mocked.cbl > tmp/STORAGE.cpy

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
' tmp/mocked.cbl | tail -n +2 | sed -E 's/(^.{6}[^*] {0,3}([A-Z-]+).*\.)/\1\n           MOVE "\2"\n           TO CUT-TEMP-SECTION-NAME\n           PERFORM CUT-ADD-TRACE-SECTION/' > tmp/PROGRAM.cpy

# Environment division and data division need to be incorporated to make the compiler happy, even if the files are never accessed at runtime

# Get all data division lines - output to DATADIV.cpy
awk '
  # 1. Match the starting line: Column 8 starts with DATA DIVISION.
  substr($0, 8, 14) ~ /^DATA DIVISION\./ {
    inside = 1;
    next; # Skip printing the header line itself
  }

  # 2. Match the stopping lines starting at column 8
  inside && (substr($0, 8, 23) ~ /^WORKING-STORAGE SECTION/ || 
             substr($0, 8, 15) ~ /^LINKAGE SECTION/         || 
             substr($0, 8, 18) ~ /^PROCEDURE DIVISION/) {
    inside = 0;
  }

  # 3. Print lines while inside the block
  inside
' tmp/mocked.cbl > tmp/DATADIV.cpy

# Get all environment division lines - output to ENVDIV.cpy
awk '
  # 1. Match the starting line: Column 8 starts with ENVIRONMENT DIVISION.
  substr($0, 8, 21) ~ /^ENVIRONMENT DIVISION\./ {
    inside = 1;
    next; # Skip printing the header line itself
  }

  # 2. Match the stopping lines starting at column 8
  inside && (substr($0, 8, 14) ~ /^DATA DIVISION/            || 
             substr($0, 8, 23) ~ /^WORKING-STORAGE SECTION/ || 
             substr($0, 8, 15) ~ /^LINKAGE SECTION/         || 
             substr($0, 8, 18) ~ /^PROCEDURE DIVISION/) {
    inside = 0;
  }

  # 3. Print lines while inside the block
  inside
' tmp/mocked.cbl > tmp/ENVDIV.cpy




#=====================
# Test Program
#=====================

# Add a move the test case name and perform the test case init routine
sed -E '/PROCEDURE DIVISION/,$ { /^[[:space:]]{1,7}(TEST-)[A-Za-z0-9_-]*(\s+SECTION)?\./ { /PROCEDURE DIVISION/b; p; s/^[[:space:]]*([A-Za-z0-9_-]+).*/            MOVE "\1"\n           TO CUT-TEST-NAME \n           PERFORM CUT-TEST-INIT./ } }' $2 |

# Remove SKIP- sections
sed '/^[[:space:]]*SKIP-/,/^[[:space:]]*[A-Za-z0-9-]\+[[:space:]]\+SECTION\./ { /^[[:space:]]*SKIP-/b; /^[[:space:]]*[A-Za-z0-9-]\+[[:space:]]\+SECTION\./b; d }' | \
sed '/^[[:space:]]*SKIP-/a\          .' |
sed -E '/PROCEDURE DIVISION/,$ { /^[[:space:]]{1,7}(SKIP-)[A-Za-z0-9_-]*(\s+SECTION)?\./ { /PROCEDURE DIVISION/b; p; s/^[[:space:]]*([A-Za-z0-9_-]+).*/            MOVE "\1"\n           TO CUT-TEST-NAME \n           PERFORM CUT-SKIP./ } }' > test-pgm-out.cbl
