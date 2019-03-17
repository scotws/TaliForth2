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

### Running tests

To run the test suite, simply run the **talitest.py** script in this folder.
The output will show up on the screen and a summary will display at
the end. The results can be found in the file results.txt once it
completes. This should work on all systems.

If you have a Linux machine, the shell script **ptest.sh** can be used
instead. This spawns a separate process for each test (14 at the time
of this writing) and runs them all in parallel. With a multicore CPU,
this noticeably shortens the test time. This script runs the tests
with the -m (--mute) option to supress output and only displays the
summary results for each test. Once all of the test have completed,
the results are compiled into the results.txt file.

It's worth noting that if you interrupt ptest.sh (eg. with a CTRL-C)
it will leave behind some "results_testname.txt" files.  These can
safely be deleted or they will be cleaned up once ptest.sh is run
again and allowed to finish.  It's also worth noting that this method
is a CPU hog and you may want to run it with nice if you want to do
other work on your machine while it is running:

```
nice -n 19 ./ptest.sh
```


### Adding further tests

Please submit tests to the GitHub as pull requests at
https://github.com/scotws/TaliForth2/pulls . While adding tests, the main
source of errors was the number base. Care must be taken to ensure that **HEX**
and **DECIMAL** are correctly called.
