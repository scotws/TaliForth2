TaliForth2/tests

This folder contains the test suite for Tali Forth.
To run the tests (assuming you have already run make in the main
project directory), simply run the talitest.py script.  This script
requires python3, the pexpect package (available via pip), and
py65 (also available via pip) to be installed.

The tests take a long time to complete (about 25 minutes on a Ryzen 7
1700) as the emulator has to be spoon-fed the characters.  When done,
the results can be found in results.txt.  The following commands will
be useful for locating tests that have failed for one reason or
another.

# Find tests that Tali Forth 2 has failed due to undefined words.
grep Undefined results.txt

# Find tests that the test software has failed.
grep RESULT results.txt

