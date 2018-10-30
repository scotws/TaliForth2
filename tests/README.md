# The Tali Forth 2 Test Suite

This folder contains the test suite for Tali Forth. To run the tests (assuming
you have already run make in the main project directory), simply start the
talitest.py script. To see the options available, run the script with `--help`.
This script requires python3 and `py65` (available via pip) to be installed.

When the test is done, a summary will be printed. The detailed results can be
found in the file `results.txt`. The script will abort if it detects a crash. 

The tests are broken up into separate files to allow quick turnaround times with
specific tests. Without any options, the script will run all tests (also
can be triggered with the `--tests all`. The files roughly follow the separation
into ANS word sets (see https://forth-standard.org/standard/words). Words
special to Tali Forth have their own file, `tali.fs`. 

Currently, the tests suite is in ALPHA state as all of Tali Forth 2. Some tests
are missing, some other are only partial.

## Source of tests

The tests themselves originated with John Hayes S1I (see header of `tester.fs`
in this folder) and were distributed with the following copyright:
```
\ (C) 1995 JOHNS HOPKINS UNIVERSITY / APPLIED PHYSICS LABORATORY
\ MAY BE DISTRIBUTED FREELY AS LONG AS THIS COPYRIGHT NOTICE REMAINS.
```
Modification for Tali Forth 2 was by SamCo in 2018. Further tests were adapted
from the ANS Forth standard (see
https://forth-standard.org/standard/testsuite) or added *ad hoc*. As in all
cases with Tali Forth 2, the standard is the behavior of Gforth.

Because these tests are normal Forth programs, they feed the words through
**PARSE-NAME**, which assumes spaces as delimiters. Therefore, the test Forth
files should not contain tabs.

### Adding further tests

Please submit tests to the GitHub as pull requests at
https://github.com/scotws/TaliForth2/pulls . While adding tests, the main
source of errors was the number base. Care must be taken to ensure that **HEX**
and **DECIMAL** are correctly called.
