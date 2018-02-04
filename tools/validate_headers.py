#!/usr/bin/env python3
# Validate header file of Tali Forth 2
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 04. Feb 2018
# This version: 04. Feb 2018
"""Validate the header files of Tali Forth 2

Assume the header.asm file is in the parent directory. Checks
to make sure that the chain of headers is complete and that
all entries are contained.
"""

SOURCE = '../headers.asm'
COMMENT = ';'

nametokens = []

def main():
    """Main function"""

    with open(SOURCE) as raw_file:
        raw_list = raw_file.readlines()

    for line in raw_list:

        if line.strip() == '':
            continue

        if line.startswith(COMMENT):
            continue

        ws = line.split()

        if line.startswith('nt_'):
            nametokens.append(ws[0])

        print(line.strip())


if __name__ == '__main__':
    main()
    print('THIS IS AN ALPHA VERSION')
    print('Found', len(nametokens), 'name tokens')
