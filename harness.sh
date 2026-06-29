# Define your source and target files
FILE_A=$2 # TEST PGM
FILE_B=$1 # PGM TO TEST
PREFIX="MOCK-"
# Get everything post precedure division piped into adding section tracing

# Business Program
# Get all working storage lines
awk -v p="MOCK-" '
  NR==FNR { if ($0 ~ "^[[:space:]]*" p) { sec=substr($1, length(p)+1); next } if ($0 ~ "SECTION\\.") sec="" ; if (sec) code[sec] = code[sec] $0 "\n"; next }
  { print }
  $0 ~ "SECTION\\." { name=$1; if (code[name]) printf "%s", code[name] }
' $FILE_A $FILE_B > tmp/mocked.cbl 

grep -oPz "(?ms)^.{7}.{0,3}WORKING-STORAGE SECTION\.\r?\n(.*?)^.*(?:^.{7}.{0,3}PROCEDURE DIVISION|^.{7}.{0,3}LINKAGE SECTION)" tmp/mocked.cbl | tr '\0' '\n' | tail -n +2 | head -n -1 > tmp/STORAGE.cpy

# Get all procedure division lines, then add the section tracing to the sections and paragraphs
grep -oPz "(?ms)^.{7}.{0,3}PROCEDURE DIVISION[\s\S]*?\.([\s\S]*)" tmp/mocked.cbl | tr '\0' '\n' | tail -n +4 | sed -E 's/(^.{6}[^*] {0,3}([A-Z-]+).*\.)/\1\n           MOVE "\2"\n           TO CUT-TEMP-SECTION-NAME\n           PERFORM CUT-ADD-TRACE-SECTION/' > tmp/PROGRAM.cpy

# Get all data division lines
grep -oPz "(?ms)^.{7}.{0,3}DATA DIVISION\.\r?\n(.*?)^.*(?:^.{7}.{0,3}WORKING-STORAGE SECTION)" tmp/mocked.cbl | tr '\0' '\n' | tail -n +2 | head -n -1 > tmp/DATADIV.cpy


# Get all environment division lines
grep -oPz "(?ms)^.{7}.{0,3}ENVIRONMENT DIVISION\.\r?\n(.*?)^.*(?:^.{7}.{0,3}DATA DIVISION)" tmp/mocked.cbl | tr '\0' '\n' | tail -n +2 | head -n -1 > tmp/ENVDIV.cpy





# Test Program
# Add a move the test case name and perform the test case init routine
sed -E '/PROCEDURE DIVISION/,$ { /^[[:space:]]{1,7}(TEST-)[A-Za-z0-9_-]*(\s+SECTION)?\./ { /PROCEDURE DIVISION/b; p; s/^[[:space:]]*([A-Za-z0-9_-]+).*/            MOVE "\1"\n           TO CUT-TEST-NAME \n           PERFORM CUT-TEST-INIT./ } }' $2 |

# Remove SKIP- sections
sed '/^[[:space:]]*SKIP-/,/^[[:space:]]*[A-Za-z0-9-]\+[[:space:]]\+SECTION\./ { /^[[:space:]]*SKIP-/b; /^[[:space:]]*[A-Za-z0-9-]\+[[:space:]]\+SECTION\./b; d }' | \
sed '/^[[:space:]]*SKIP-/a\          .' |
sed -E '/PROCEDURE DIVISION/,$ { /^[[:space:]]{1,7}(SKIP-)[A-Za-z0-9_-]*(\s+SECTION)?\./ { /PROCEDURE DIVISION/b; p; s/^[[:space:]]*([A-Za-z0-9_-]+).*/            MOVE "\1"\n           TO CUT-TEST-NAME \n           PERFORM CUT-SKIP./ } }' > test-pgm-out.cbl
