# Reverse assembler header sequence 
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 30. Dez 2018
# This version: 30. Dez 2018

# This is a one-shot program to reverse the order of entries for the assembler
# wordlist in headers.asm. 

import string

SOURCE = 'asm_headers.asm' 
previous_link = '0000' # Start with end of list

src = []
dest = []
block = []

def is_link(s):
    """Takes a line from the listing and returns a bool depending on
    if the line is a link or not.
    """
    r = True
    ws = s.split()

    if (len(ws) != 2) or (ws[0] != '.word'):
        r = False

    return r


with open(SOURCE, 'r') as source_file:
    src = source_file.readlines()

last_line = len(src)-1

for l in range(last_line, -1, -1):
    line = src[l]

    if is_link(line):
        link = line.split()[1]
        line = " "*16 +".word "+previous_link

    if line[0] == 'n':
        previous_link = line.strip()[:-1]
    
    dest.insert(0, line) 


for l in dest:
    print(l.rstrip())



