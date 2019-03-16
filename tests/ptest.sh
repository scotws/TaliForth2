#!/bin/bash
# PROGRAMMER  : Sam Colwell
# FILE        : ptest.sh
# DATE        : 2018-12-28
# DESCRIPTION : Launch all of the tali tests in parallel.

# This list will need to be kept in sync with the one in talitest.py
LEGAL_TESTS=( core_a core_b core_c string double facility ed asm
              tali tools block search user cycles )


# Launch the tester for each .fs file except tester.fs
for testname in ${LEGAL_TESTS[@]}; do
    # Keep the output when the tester loads for only the first test.
    if [ "$testname" == "${LEGAL_TESTS[0]}" ]; then
        ./talitest.py -m -o "results_$testname.txt" -t $testname &
    else
        ./talitest.py -m -o "results_$testname.txt" -s -t $testname &
    fi
done

# Wait for them all to finish.
wait

# Assemble all of the results.
# Delete the temporary result files.
rm results.txt
for testname in ${LEGAL_TESTS[@]}; do
    # Add each temporary result file, removing the "bye" at the end.
    sed '/^bye/d' "results_$testname.txt" >> results.txt
    rm "results_$testname.txt"
done       
    
