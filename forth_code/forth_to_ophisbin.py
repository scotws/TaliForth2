#!/usr/bin/env python3
# Convert Forth code to ASCII for Ophis
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 27. Feb 2018
# First version: 01. Mar 2018

# This version : 18. Nov 2018
# Modfied by SamCo to use regular expressions to locate/remove comments.

"""Convert Forth code to compact ASCII to use for inclusion into Ophis

Takes normal Forth code and strips out the comments before being
compacted to an ASCII code that contains only a single whitespace
between words. This can then be included into an Ophis assembler file
with the .inclbin command. Outputs result on standard output
"""

import argparse
import sys
import re

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', dest='source', required=True,
                    help='Forth source code file (required)')
args = parser.parse_args()

def main():

    # Regular expressions used to find/remove Forth comments:

    # ((Beginning of line followed by "(" ) or (whitespace followed by
    # "(" )) followed by whitespace followed by zero or more non-")"
    # characters followed by ")"
    paren_comment = re.compile(r"(^\(|\s\()\s[^)]*\)")

    # ((Beginning of line followed by ":" ) or (whitespace followed by
    # ":" )) followed by whitespace followed by "(" followed by
    # whitespace
    paren_definition = re.compile(r"(^:|\s:)\s\(\s")

    # ((Beginning of line followed by "\" ) or (whitespace followed by
    # "\" )) followed by whitespace followed by anything all the way
    # to the end of the line.
    backslash_comment = re.compile(r"(^\\|\s\\)(\s.*)?$")

    all_words = []

    with open(args.source, "r") as f:

        for n, line in enumerate(f.readlines(), 1):

            line = line.strip()
            
            # Remove all ( ... ) comments.
            # Take special care not to remove a definition of "(" 
            if not paren_definition.search(line):
                line = paren_comment.sub(" ", line)

            # Remove all \ ... comments
            line = backslash_comment.sub("", line)

            # Paren comments were replaced with a space.
            # Remove any space from the beginning/end of the line.
            line = line.strip()

            # Ignore lines that are now blank.
            if line == '':
                continue

            # Add only the non-comment words to the results.
            words = line.split()
            all_words.extend(words)

    # Merge everything into one big line for compact printing
    # Add final space because we might be adding another batch of
    # Forth words after this one (say, forth_words and user_words
    one_line = ' '.join(all_words)

    # Use sys.stdout.write() instead of print() because we don't want
    # the line feed at the end
    sys.stdout.write(' '+one_line+' ')

if __name__ == '__main__':
    main()
