Tali Forth 2 Tests

This folder contains the test suite for Tali Forth. To run the tests (assuming
you have already run make in the main project directory), simply run the
talitest.py script.  This script requires python3, the pexpect package
(available via pip), and py65 (also available via pip) to be installed.

The tests take a long time to complete (about 25 minutes on a Ryzen 7
1700 and an Intel i7-4790K) as the emulator has to be spoon-fed the characters.
When done, a summary will be printed. The detailed results can be found in
results.txt.
