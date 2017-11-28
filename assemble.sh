#!/bin/sh
# Shell script to assemble Tali Forth 2 and generate listings
# Scot W. Stevenson 28. Nov 2017

/usr/local/bin/ophis -l ./docs/ophis_listing.txt\
        -m ./docs/ophis_labelmap.txt\
        -c taliforth.asm
