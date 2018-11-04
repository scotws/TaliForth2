#!/usr/bin/env python3
# Collect some statistics from Tali Forth 2's code
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 04. Nov 2018
# This version: 04. Nov 2018
"""Takes a list of assembler files from the Tali Forth 2 project and
calculates the frequence of opcodes used and other information. This
is crude one-shot program and is not maintained.
"""
import operator
import sys

# Sources are Ophis assembler files with lots of code, but not things that
# definitions.asm with more data
SOURCES = ['disassembler.asm', 'ed.asm', 'native_words.asm', 'taliforth.asm']

comments_count = 0
directives_count = 0
labels_count = 0
lines_count = 0
local_labels_count = 0
opcodes_count = 0

found_opcodes = set()
mnemonics = {}

for src in SOURCES:
    
    # We assume this file lives in the tools folder
    with open('../'+src, 'r') as asm_file:
        lines = asm_file.readlines()

    for line in lines:
        lines_count += 1

        l = line.strip()
        
        if l == '':
            continue

        if l[0] == ';': 
            comments_count +=1 
            continue

        if l[0] == '*':
            local_labels_count += 1
            continue

        if  l[0] == '.':
            directives_count += 1
            continue

        # This should now be a list of 65c02 instructions and labels
        opcode = l.split()[0]

        if opcode[-1] == ':':
            labels_count += 1
            continue

        # One last filter just to be sure
        if len(opcode) != 3:
            continue

        # Use a set for speed, though really, I don't know why we bother
        if opcode not in found_opcodes:
            found_opcodes.add(opcode)
            mnemonics[opcode] = 1
        else:
            mnemonics[opcode] += 1

        opcodes_count += 1

print("Lines read: ", lines_count)

print("Labels found: ", labels_count)
print("Local labels found: ", local_labels_count)
print("Comments found: ", comments_count)
print("Directives found: ", directives_count)
print("Opcodes found: ", opcodes_count)
print()

data = []

for key in mnemonics:
    data.append((key, mnemonics[key], float(mnemonics[key]/opcodes_count)))

data.sort(key=operator.itemgetter(1), reverse=True)

for d in data:
    print("{0}:  {1:3}  {2:2.1%}".format(d[0], d[1], d[2]))

