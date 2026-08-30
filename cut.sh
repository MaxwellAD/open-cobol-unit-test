printf "Stage 0 - Instrumenting Code Coverage\n"
printf "===================================================\n"
# If running without code-coverage-precompiler, skip this step and point harness.sh directly at the program under test
code-coverage-precompiler.sh Examples/Example01/pgm-to-test.cbl coverage/pgm-to-test.cbl &&

printf "\nStage 1 - Running the harness\n"
printf "===================================================\n"
./harness.sh coverage/pgm-to-test.cbl Examples/Example01/test-pgm.cbl &&

printf "\nStage 2 - Compile\n"
printf "===================================================\n"
cobc -x test-pgm-out.cbl -o testpgm -I "CUT" -I "tmp" &&

printf "\nStage 3 - Execute\n"
printf "===================================================\n"
./testpgm > Examples/Example01/dut-coverage-report.txt; cp CUT-RPTO "Examples/Example01/Unit Test Report.txt" &&

printf "\n"

grep -E -B 1 -A 1 '^\[(FAIL|ERROR)\]' CUT-RPTO

printf "\n"

cat CUT-RPTO | tail -7
