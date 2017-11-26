#!/usr/bin/env python3
# Convert JSON list of Forth words to Tali Forth 2 header file
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 24. Nov 2017
# This version: 26. Nov 2017
"""Convert JSON Forth word information to Tali Forth 2 header file

Assumes the file "wordsource.json" in the current directory with three
keys "name", "word", and "group" which are then processed and printed
to the screen in the format of entries to header.asm, the Tali 2 list
of headers in the form of:

    nt_drop:
            .byte 4, 0
            .word 0000, xt_drop, z_drop
            .byte "drop"

See the comments in the file header.asm for details. The first word
field ("0000") and the details of the flags (second .byte value) are
added later by the user by hand to the actual header.asm file; there
is some processing of the "tricky words" with quotation marks and
backslashes required anyway. See tools/README.txt for details
"""

import json

SOURCE = 'wordsource.json'
TEMPLATE = 'nt_{0}:\n'\
        '        .byte {1}, 0\n'\
        '        .word 0000, xt_{2}, z_{3}\n'\
        '        .byte "{4}"\n'


def main():
    """Main function"""

    with open(SOURCE) as json_file:
        json_data = json.load(json_file)

    for item in json_data:
        length = len(item['word'])
        name = item['name']
        word = item['word']
        print(TEMPLATE.format(name, length, name, name, word))


if __name__ == '__main__':
    main()
