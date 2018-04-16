#!/usr/bin/env python3
# Generate Tali Forth 2 native word skeleton from a word list
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 21. Nov 2017
# This version: 16. Apr 2018
"""Generate 65c02 assembler templates for Tali Forth native words

After running this script, various parts need to be adjusted by hand. For
instance, the boot sequence has COLD-ABORT-QUIT flowing into each other.
See tools/README.txt for more details.

NOTE: This is the original format for the headers of the Forth native words.
This was modified later by hand
"""

import json

INDENT_SIZE = 16  # Two normal tabs
WORDLIST = 'wordsource.json'
TEMPLATE = '; ## {0} ( -- ) "<TBA>"\n'\
    '; ## "{1}"  src: {2}  b: TBA  c: TBA  status: TBA\n'\
    '.scope\n'\
    'xt_{3}:{spc_xt}nop\n'\
    'z_{3}:{spc_z}rts\n'\
    '.scend\n'


def main():
    """Main function"""

    with open(WORDLIST) as json_file:
        json_data = json.load(json_file)

    # The JSON date is return as a list of dictionaries in a pretty
    # random order. We move that data to a dictionary of dictionaries with
    # the name as the key so we can get a handle on sorting this
    words = {e['name']: e for e in json_data}
    word_list = sorted(words.keys())

    for entry in word_list:
        word_data = words[entry]
        name = word_data['name'].strip()  # paranoid
        upper_name = name.upper()
        spc_xt = ' '*(INDENT_SIZE-(len(name)+4))
        spc_z = ' '*(INDENT_SIZE-(len(name)+3))

        # If the label is too long, move following upcode to next line
        if len(name)+4 >= INDENT_SIZE:
            spc_xt = '\n'+(' '*(INDENT_SIZE))

        if len(name)+3 >= INDENT_SIZE:
            spc_z = '\n'+(' '*(INDENT_SIZE))

        print(TEMPLATE.format(upper_name,
                              word_data['word'],
                              word_data['source'],
                              word_data['name'],
                              spc_xt=spc_xt,
                              spc_z=spc_z))


if __name__ == '__main__':
    main()
