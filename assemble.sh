#!/bin/sh
# Shell script to assemble Tali Forth 2 and generate listings
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 28. Nov 2017
# This version: 16. Apr 2018

# These are currently very specific to Scot's setup and might not work on yours

# Run ophis with parameters to automatically generate label map and listing
/usr/local/bin/ophis -l ./docs/ophis_listing.txt\
        -m ./docs/ophis_labelmap.txt\
        -c platform-py65mon.asm

# Automatically generate list of native Forth words as docs/WORDLIST.md
cd tools
python3 generate_wordlist.py > ../docs/WORDLIST.md
cd ..
