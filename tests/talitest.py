#!/usr/bin/python3
# """Talitest spawns a copy of py65mon running Tali Forth 2 and
# feeds it tests, saving the results.  This script requires pexpect
# (available via pip) and needs to run on a linux system.  The windows
# version of py65mon reads directly from the console rather than
# stdin, and therefore doesn't work with pexpect on Windows (even
# though pexpect is now supported on Windows).

# RUNNING     : Run talitest.py from the tests directory.

# This script takes a long time to run (25 minutes on my system).
# Results will be found in results.txt when finished.  Grep for
# "Undefined" to find words it couldn't run (some of these will be
# from a previous failed compilation).  Grep for "RESULT" to find
# WRONG NUMBER OF RESULTS errors and INCORRECT RESULTS errors.  Note
# that the original error messages show up first.
#
# PROGRAMMER  : Sam Colwell
# FILE        : talitest.py
#
# First version: 16. May 2018
# This version: 17. May 2018
# """

import time
import pexpect

CORE = 'core.fs'
TESTER = 'tester.fs'
RESULTS = 'results.txt'
SPAWN_COMMAND = 'py65mon -m 65c02 -r ../taliforth-py65mon.bin'


def sendslow(kid, string):
    """Slowly send a string to a subprocess using pexpect."""
    for char in string:
        # print(char) # For debugging
        # If it looks like characters from the tests are being dropped
        # by the py65mon emulator, increase the time below.
        time.sleep(0.001)
        kid.send(char)


def sendline(kid, string):
    """Send a line (with newline added) to the simulator, returning
    results
    """
    # print(string) # For debugging
    sendslow(kid, string + '\n')
    kid.expect('\r\n')
    return kid.before.decode('ascii')


# Create the py65mon process running Tali Forth 2.
# Linux Version (Windows version doesn't work with this simulator)
child = pexpect.spawn(SPAWN_COMMAND)

# Wait for the "Type 'bye' to exit" prompt.
print('Waiting for Tali Forth 2 to initialize...')
child.expect('to exit\r\n')

# An extra delay is needed or the emulator drops the first few chars.
print('Waiting a bit more')
time.sleep(3)

# Log the results.
with open(RESULTS, 'wb') as fout:

    # Send the tester file.
    with open(TESTER, 'r') as infile:

        # Using splitlines to get rid of newlines at the end of lines.
        for line in infile.read().splitlines():
            results = sendline(child, line)
            print(results)
            fout.write((results + '\n').encode('ascii'))

    # Send the suite of tests
    with open(CORE, 'r') as infile:

        # Using splitlines to get rid of newlines at the end of lines.
        for line in infile.read().splitlines():
            results = sendline(child, line)
            print(results)
            fout.write((results + '\n').encode('ascii'))

# Shut it all down.
sendslow(child, 'bye\n')
sendslow(child, 'quit\n')

# Walk through results and find stuff that went wrong.
print("="*80)
print("Summary:\n")

# First, stuff that failed due to undefined words
undefined = []

with open(RESULTS, 'r') as rfile:

    for line in rfile:
        if 'undefined' in line:
            undefined.append(line)

# We shouldn't have any undefined words at all.
if undefined:
    for line in undefined:
        print(line.strip())


# Second, stuff that failed the actual test
failed = []

with open(RESULTS, 'r') as rfile:

    for line in rfile:
        # Skip the message from compiling the test words
        if 'compiled' in line:
            continue

        if 'INCORRECT RESULT' in line:
            failed.append(line)

if failed:
    for line in failed:
        print(line.strip())

# Sum it all up.
print()
if (not undefined) and (not failed):
    print("All available tests passed.")
