#!/usr/bin/env python3
# Generate wordlist for documentation from words.asm file
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 21. Nov 2017
# This version: 21. Nov 2017

import argparse

SOURCE = '../words.asm'
MARKER = '; ## '

parser = argparse.ArgumentParser()
parser.add_argument('-o', '--outfile', dest='outfile',
        help='name of output file (default "wordlist.txt")')
ARGS = parser.parse_args()

def print_first_line(line):
    """Given a raw first line, print it formatted. Assumes line of form

    ; ## <NAME> ( -- ) <DECRIPTION>
    """

    line = line[len(MARKER):]
    # TODO decide on correct output
    print(line)


def print_second_line(line):
    """Given a raw second line, print it formatted. Assumes line of form
    
    ## drop type: native group: ANSI bytes: 6 cycles: 20 status: unwritten
    """

    line = line[len(MARKER):]
    # TODO decide on correct output
    print(line)


def main(): 

    with open(SOURCE) as f:
        raw_list = f.readlines()

    data_list = []

    for line in raw_list:
        
        if line.startswith(MARKER):
            data_list.append(line.strip())

    use_list = iter(data_list)


    while True:

        try:
            first_line = next(use_list)
            second_line = next(use_list) 
        except StopIteration:
            break

        print_first_line(first_line)
        print_second_line(second_line)
        print()

if __name__ == '__main__':
    main()

