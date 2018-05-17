#!/usr/bin/python3
# PROGRAMMER  : Sam Colwell
# FILE        : talitest.py
# DATE        : 2018-05-16

# DESCRIPTION : This spawns a copy of py65mon running Tali Forth 2 and
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

import pexpect
import sys
import time

def sendslow( child, str ):
    "Slowly send a string to a subprocess using pexpect."
    for c in str:
        # print(c) # For debugging
        # If it looks like characters from the tests are being dropped
        # by the py65mon emulator, increase the time below.
        time.sleep(0.001)
        child.send(c)
    return

def sendline( child, str ):
    "Send a line (with newline added) to the simulator, returning results"
    # print(str) # For debugging
    sendslow(child, str + '\n')
    child.expect('\r\n')
    return child.before.decode('ascii');


# Create the py65mon process running Tali Forth 2.
# Linux Version (Windows version doesn't work with this simulator)
child = pexpect.spawn('py65mon -m 65c02 -r ../taliforth-py65mon.bin')

# Wait for the "Type 'bye' to exit" prompt.
print('Waiting for Tali Forth 2 to initialize...')
child.expect('to exit\r\n')
# An extra delay is needed or the emulator drops the first few chars.
print('Waiting a bit more')
time.sleep(3)


# Log the results.
fout = open('results.txt','wb')

# Send the tester file.
infile = open("tester.fr","r")
# Using splitlines to get rid of newlines at the end of lines.
for line in infile.read().splitlines():
    results = sendline(child, line)
    print(results)
    fout.write((results + '\n').encode('ascii'))

infile.close()

# Send the suite of tests.
infile = open("core.fr","r")
# Using splitlines to get rid of newlines at the end of lines.
for line in infile.read().splitlines():
    results = sendline(child, line)
    print(results)
    fout.write((results + '\n').encode('ascii'))

infile.close()

# Shut it all down.
sendslow(child, 'bye\n')
sendslow(child, 'quit\n')
fout.close()

