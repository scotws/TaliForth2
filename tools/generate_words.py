#!/usr/bin/env python3
# Generate TaliForth 2 structures from a word list
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 21. Nov 2017
# This version: 24. Nov 2017
"""Generate 65c02 assembler templates for Forth words

After running this script, various parts need to be adjusted by hand. For
instance, the boot sequence has COLD-ABORT-QUIT flowing into each other.
"""

import json
import pprint

WORDLIST = 'wordsource.json'
TEMPLATE_HEADER = '; ## {0} ( -- ) "TBA"\n'\
    '; ## {1}  type: TBA  group: TBA  bytes: TBA  cycles: TBA  '\
    'status: TBA'

TEMPLATE_WORDS = '(MISSING)'


def main(): 

    with open(WORDLIST) as f:
        json_data = json.load(f) 
    
    for item in json_data:
        print(item['name'], item['command'])

if __name__ == '__main__':
    main()
