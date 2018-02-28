#!/usr/bin/env python3
# Convert Forth code to ASCII for Ophis
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 27. Feb 2018
# First version: 27. Feb 2018
"""Convert Forth code to compact ASCII to use for inclusion into Ophis

Takes normal Forth code and strips out the comments before being
compacted to an ASCII code that contains only a single whitespace
between words. This can then be included into an Ophis assembler file
with the .inclbin command.
"""

import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', dest='source', required=True,\
                help='Forth source code file (required)')
args = parser.parse_args()


def has_bracket_comment(string):
    """Takes a string, return a bool if contains a Forth comment of the
    form of ( this )."""

    result = False
    words = set(string.split())

    # The problem is that ( has to occur on its own, separated by spaces,
    # while ) can occur at the end of a word without a leading space. We
    # should probably check for something like ') this (' but that is 
    # going to be so rare it doesn't seem to be worth it

    if '(' in words and ')' in string and not ': (' in string:
        result = True

    return result


def remove_bracket_comment(string):
    """Strips a Forth comment in the form of ( this ) out of a string.
    Might have problems with the .( print ) format."""

    # Add space to front of string so we can search for ' ('
    work = ' '+string.strip()

    while ' (' in work:
        start = work.find(' (')
        end = work.find(')', start)
        work = work[:start]+work[end+1:]

    return work.strip()


def main():

    all_words = []

    with open(args.source, "r") as f:

        for n, line in enumerate(f.readlines(), 1): 

            line = line.strip()

            if line == '':
                continue 

            if line[0] == '\\':
                continue
            
            if has_bracket_comment(line):
                line = remove_bracket_comment(line)
            
            words = line.split()
            all_words.extend(words)

    one_line = ' '.join(all_words)+' ' 
    print(one_line)
     
    

            


if __name__ == '__main__':
    main()
