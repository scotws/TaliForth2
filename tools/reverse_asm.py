# Reverse assembler header sequence 
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 30. Dez 2018
# This version: 30. Dez 2018

# This is a one-shot program to reverse the order of entries for the assembler
# wordlist in headers.asm. 

SOURCE = 'asm_headers.asm' 
src = []
dest = []
block = []

with open(SOURCE, 'r') as source_file:
    src = source_file.readlines()

for l in src:

    clean_l = l.rstrip()    # remove any trailing stuff while we're at it

    # We have to move the list block by block, not line by line
    if clean_l != '':
        block.append(clean_l)
    else:
        dest = block+dest
        dest.insert(0, '\n')        # Faster than adding the lists
        block = []

# EOF leaves us with TYA hanging, just add it this way because this is
# a one-shot
dest = block+dest
dest.insert(0, '\n')        # Faster than adding the lists

for l in dest:
    print(l.rstrip())


