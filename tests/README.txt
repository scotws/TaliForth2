Tali Forth 2 Tests

This folder contains the test suite for Tali Forth. To run the tests (assuming
you have already run make in the main project directory), simply start the
talitest.py script. This script requires python3, the pexpect package
(available via pip), and py65 (also available via pip) to be installed.

When the test is done, a summary will be printed. The detailed results can be
found in results.txt. The script will abort if it detects a crash. If you seem
to be dropping characters -- for instance, with a "Unknown word" error when
"rror" was defined instead of "error" -- you'll have to increase the waiting
period for sending. This can be done with the --delay option and settings in
ms. 

Because these tests are normal Forth programs, they feed the words through
PARSE-NAME, which assumes spaces as delimiters. Therefore, the test Forth files
should not contain tabs.

Note that this is not a generic test for ANSI Forth, but rather includes
special tests for words that are specific to Tali Forth 2. If you use this code
for your own project, you'll have to change it accordingly. The "official" Forth
tests, on which some of this code is based, can be found at
https://forth-standard.org/standard/testsuite

KNOWN ISSUES:
        - The ACCEPT test currenty doesn't work (expects user to type in chars)
        - Because of ACCEPT problem, the test for dictionary rules doesn't work
