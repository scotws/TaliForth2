#!/bin/bash
# PROGRAMMER  : Sam Colwell
# FILE        : ptest.sh
# DATE        : 2018-12-28
# DESCRIPTION : Launch all of the tali tests in parallel.

# This list will need to be kept in sync with the one in talitest.py
LEGAL_TESTS=( core string double facility ed asm
              stringlong tali tools block search
              user cycles )


# Launch the tester for each .fs file except tester.fs
for testname in ${LEGAL_TESTS[@]}; do
    ./talitest.py -m -o "results_$testname.txt" -s -t $testname && echo "$testname" &
done

# Wait for them all to finish.
wait

# Assemble all of the results.
# Delete the temporary result files.
rm results.txt
for testname in ${LEGAL_TESTS[@]}; do
    cat "results_$testname.txt" >> results.txt
    rm "results_$testname.txt"
done       
    
