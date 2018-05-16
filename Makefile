# Makefile for Tali Forth 2
# This version: 16. May 2018

# Note the manual is not automatically updated because not everybody can be
# expected to have the full LaTeX toolchain installed

COMMON_SOURCES=taliforth.asm definitions.asm native_words.asm headers.asm strings.asm forth_words.asc user_words.asc

all: taliforth-py65mon.bin | WORDLIST.md

taliforth-%.bin: platform-%.asm $(COMMON_SOURCES)
	ophis -l docs/$*-listing.txt \
	-m docs/$*-labelmap.txt \
	-o $@ \
	-c $< ;

# Convert the high-level Forth words to ASCII files that Ophis can include
%.asc: forth_code/%.fs
	python3 forth_code/forth_to_ophisbin.py -i $< > $@

# Automatically update the wordlist which also gives us the status of the words
# We need for the binary to be generated first or else we won't be able to find
# new words in the label listing
WORDLIST.md: docs/WORDLIST.md
	python3 tools/generate_wordlist.py > docs/WORDLIST.md
