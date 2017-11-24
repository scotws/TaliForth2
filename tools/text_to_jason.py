#!/usr/bin/env python3
# Convert text formatted list of words to JSON format
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 24. Nov 2017
# This version: 24. Nov 2017
"""Convert text list of Forth words to JSON for Tali Forth 2

Assumes the file "wordsource.txt" in the current directory with three
fields for the word in lower case, the name of the command as one word
(no internal whitespace), and the group the word belongs to in mixed
case with possible whitespace (eg "ANSI core"). Output is to the screen
to be captured by a redirect of the shell, not directly to a file. Lines
that start with # and empty lines are ignored
"""

SOURCE = 'wordsource.txt'
INDENT = '\t' 
# TEMPLATE = '{{"name": "{0}", "word": "{1}", "group": "{3}"}}'
TEMPLATE = '{{ "name": "{0}", "word": "{1}" }},'
COMMENT = '#'

def main(): 

    with open(SOURCE) as f:
        raw_list = f.readlines()

    print('[')

    for raw_line in raw_list:

        if raw_line.strip() == '':
            continue 

        if raw_line.startswith(COMMENT):
            continue 

        word, name = raw_line.split(maxsplit=2)

        if '\\' in word:
            word = word.replace('\\', '\\\\')  # Guys, this is silly

        if '"' in word:
            word = word.replace('"', '\\"')

        print(INDENT+TEMPLATE.format(name, word))

    print(']')

    print('Please remember to remove the last comma in the list by hand')


if __name__ == '__main__':
    main()
