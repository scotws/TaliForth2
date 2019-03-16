#!/usr/bin/python3
"""Talitest creates a py65 65C02 emulator running Tali Forth 2 and
feeds it tests, saving the results.  This script requires py65 version
1.1.0 or later already be installed (`pip install --upgrade py65`).

RUNNING     : Run talitest.py from the tests directory.

Results will be found in results.txt when finished.

PROGRAMMERS : Sam Colwell and Scot W. Stevenson
FILE        : talitest.py

First version: 16. May 2018
This version: 13. Dec 2018
"""

import argparse
import sys
import py65.monitor as monitor
from py65.devices.mpu65c02 import MPU as CMOS65C02
from py65.memory import ObservableMemory

TESTER = 'tester.fs'
RESULTS = 'results.txt'
TALIFORTH_LOCATION = '../taliforth-py65mon.bin'
PY65MON_ERROR = '*** Unknown syntax:'
TALI_ERRORS = ['Undefined word',
               'Stack underflow',
               'ALLOT using all available memory',
               'Illegal SOURCE-ID during REFILL',
               'Interpreting a compile-only word',
               'DEFERed word not defined yet',
               'Division by zero',
               'Not in interpret mode',
               'Parsing failure',
               'No such xt found in Dictionary',
               'Digit larger than base',
               'QUIT could not get input (REFILL returned -1)',
               'Already in compile mode']

# Add name of file with test to the set of LEGAL_TESTS
LEGAL_TESTS = ['core_a', 'core_b', 'core_c', 'string', 'double',
               'facility', 'ed', 'asm', 'tali',
               'tools', 'block', 'search', 'user', 'cycles']
TESTLIST = ' '.join(["'"+str(t)+"' " for t in LEGAL_TESTS])

OUTPUT_HELP = 'Output File, default "'+RESULTS+'"'
TESTS_HELP = "Available tests: 'all' or one or more of "+TESTLIST

parser = argparse.ArgumentParser()
parser.add_argument('-b', '--beep', action='store_true',
                    help='Make a sound at end of testing', default=False)
parser.add_argument('-m', '--mute', action='store_true',
                    help='Only print errors and summary', default=False)
parser.add_argument('-o', '--output', dest='output',
                    help=OUTPUT_HELP, default=RESULTS)
parser.add_argument('-s', '--suppress_tester', action='store_true',
                    help='Suppress the output while the tester is loading', default=False)
parser.add_argument('-t', '--tests', nargs='+', type=str, default=['all'],
                    help=TESTS_HELP)
args = parser.parse_args()

# Make sure we were given a legal list of tests: Must be either 'all' or one or
# more of the legal tests
if (args.tests != ['all']) and (not set(args.tests).issubset(LEGAL_TESTS)):
    print('ERROR: Illegal test. Aborting.')
    sys.exit(1)

if args.tests == ['all']:
    args.tests = list(LEGAL_TESTS)

# Create a string with all of the tests we will be running in it.
test_string = ""
test_index = -1

# Load the tester first.
with open(TESTER, 'r') as tester:
    test_string = tester.read()
    end_of_tester = len(test_string)

# Load all of the tests selected from the command line.
for test in args.tests:

    # Determine the test file name.
    testfile = test + '.fs'

    with open(testfile, 'r') as infile:
        # Add a forth comment with the test file name.
        test_string = test_string +\
                      "\n ( Running test '{0}' from file '{1}' )\n".\
                      format(test, testfile)
        # Add the tests.
        test_string = test_string + infile.read()

# Have Tali2 quit at the end of all the tests.
test_string = test_string + "\nbye\n"

# Log the results
with open(args.output, 'wb') as fout:

    # Create a py65 monitor object loaded with Tali Forth 2.
    class TaliMachine(monitor.Monitor):
        """Emulator for running Tali Forth 2 test suite"""

        # Used for cycle counting tests.
        cycle_start = 0
        cycle_end   = 0

        def __init__(self):
            # Use the 65C02 as the CPU type.
            # Don't pass along any of the command line arguments.
            # Don't use the built-in I/O.
            super().__init__(mpu_type=CMOS65C02,
                             argv="",
                             putc_addr=None,
                             getc_addr=None)
            # Load our I/O routines that take the tests from a string
            # and log the results to a file, echoing if not muted.
            self._install_io()
            # Load the tali2 binary
            self.onecmd("load " + TALIFORTH_LOCATION + " 8000")

        def _install_io(self):

            def getc_from_test(_):
                """Parameter (originally "address") required by py65mon
                but unused here as "_"
                """
                global test_string, test_index
                test_index = test_index + 1

                if test_index < len(test_string):
                    result = ord(test_string[test_index])
                else:
                    result = 0

                return result

            def putc_results(_, value):
                """First parameter (originally "address") required
                by py65mon but unused here as "_"
                """
                global fout
                # Save results to file.
                if value != 0:
                    if not args.suppress_tester or \
                       test_index > end_of_tester:
                        fout.write(chr(value).encode())

                # Print to the screen if we are not muted.
                if not args.mute:
                    if not args.suppress_tester or \
                       test_index > end_of_tester:
                        sys.stdout.write(chr(value))
                        sys.stdout.flush()

            def update_cycle_start(_):
                """Parameter (originally "address") required by py65mon
                but unused here as "_"
                """
                # When this address is read from, note the cycle time.
                self.cycle_start = self._mpu.processorCycles
                return 0

            def update_cycle_end(_):
                """Parameter (originally "address") required by py65mon
                but unused here as "_"
                """
                # When this address is read from, note the cycle time.
                self.cycle_end = self._mpu.processorCycles
#                # Compute the elapsed time (in CPU cycles).
#                # With a 1MHz clock, this will also be in microseconds.
#                fout.write((" CYCLES: "+str(self.cycle_end-self.cycle_start)+" ").encode())
#
#                # Print to the screen if we are not muted.
#                if not args.mute:
#                    sys.stdout.write((" CYCLES: "+str(self.cycle_end-self.cycle_start)+" "))
#                    sys.stdout.flush()

                return 0

            def read_cycle_count(address):
                """Break up the 32-bit result into bytes for Tali to
                read out of virtual memory.  Note that the hex value
                12345678 is stored in memory as bytes 34 12 78 56.
                The value will be read (as a double) starting at
                memory address 0xF008
                """
                if address == 0xF008:
                    return ((self.cycle_end-self.cycle_start)&0x00FF0000)>>16
                elif address == 0xF009:
                    return ((self.cycle_end-self.cycle_start)&0xFF000000)>>24
                elif address == 0xF00A:
                    return ((self.cycle_end-self.cycle_start)&0x000000FF)
                elif address == 0xF00B:
                    return ((self.cycle_end-self.cycle_start)&0x0000FF00)>>8
                else:
                    return 0

            # Install the above handlers for I/O
            mem = ObservableMemory(subject=self.memory)
            mem.subscribe_to_write([0xF001], putc_results)
            mem.subscribe_to_read([0xF004], getc_from_test)

            # Install the handlers for timing cycles.
            mem.subscribe_to_read([0xF006], update_cycle_start)
            mem.subscribe_to_read([0xF007], update_cycle_end)
            mem.subscribe_to_read([0xF008, 0xF009, 0xF00A, 0xF00B], read_cycle_count)
            self._mpu.memory = mem

    # Start Tali.
    tali = TaliMachine()
    # Reset vector is $f006.
    tali._mpu.pc = 0xf006
    # Run until break detected.
    tali._run([0x00])

# Walk through results and find stuff that went wrong
print()
print('='*80)
print('Summary for: ' + ' '.join(args.tests))

# Check to see if we crashed before reading all of the tests.
if test_index < len(test_string) - 1:
    print("Tali Forth 2 crashed before all tests completed\n")
else:
    print("Tali Forth 2 ran all tests requested")

# First, stuff that failed due to undefined words
undefined = []

with open(args.output, 'r') as rfile:

    for line in rfile:
        if 'undefined' in line:
            undefined.append(line)

# We shouldn't have any undefined words at all
if undefined:

    for line in undefined:
        print(line.strip())

# Second, stuff that failed the actual test
failed = []

with open(args.output, 'r') as rfile:

    for line in rfile:
        # Skip the message from compiling the test words
        if 'compiled' in line:
            continue

        if 'INCORRECT RESULT' in line:
            failed.append(line)

        if 'WRONG NUMBER OF RESULTS' in line:
            failed.append(line)

        for error_str in TALI_ERRORS:
            if error_str in line:
                failed.append(line)

if failed:

    for line in failed:
        print(line.strip())

# Sum it all up.
if (not undefined) and (not failed):
    print('All available tests passed')

# If we got here, the program itself ran fine one way or another
if args.beep:
    print('\a')

sys.exit(0)
