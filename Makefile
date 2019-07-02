# Makefile for Tali Forth 2
# This version: 16. Oct 2018

# Note the manual is not automatically updated because not everybody can be
# expected to have the asciidoc toolchain installed

COMMON_SOURCES=taliforth.asm definitions.asm native_words.asm headers.asm strings.asm forth_words.asc user_words.asc disassembler.asm ed.asm assembler.asm
TEST_SOURCES=tests/core.fs tests/string.fs tests/double.fs tests/facility.fs tests/stringlong.fs tests/tali.fs tests/tools.fs tests/block.fs tests/user.fs tests/cycles.fs tests/talitest.py tests/ed.fs tests/search.fs tests/asm.fs

all: taliforth-py65mon.bin docs/WORDLIST.md
clean:
	rm *.bin *.prg

taliforth-%.bin: platform/platform-%.asm $(COMMON_SOURCES)
	ophis -l docs/$*-listing.txt \
	-m docs/$*-labelmap.txt \
	-o $@ \
	-c $< ;

taliforth-%.prg: platform/platform-%.asm $(COMMON_SOURCES)
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
docs/WORDLIST.md: taliforth-py65mon.bin
	python3 tools/generate_wordlist.py > docs/WORDLIST.md


# Some convenience targets to make running the tests and simulation easier.

# Convenience target for regular tests.
tests:	tests/results.txt

tests/results.txt:	taliforth-py65mon.bin $(TEST_SOURCES)
	cd tests; ./talitest.py

# Convenience target for parallel tests
ptests:	taliforth-py65mon.bin $(TEST_SOURCES)
	cd tests; ./ptest.sh

# Convenience target to run the py65mon simulator.
# Because taliforth-py65mon.bin is listed as a dependency, it will be
# reassembled first if any changes to its sources have been made.
sim:	taliforth-py65mon.bin
	py65mon -m 65c02 -r taliforth-py65mon.bin

# Some convenience targets for the documentation.
docs/manual.html: docs/*.adoc
	cd docs; asciidoctor -a toc=left manual.adoc

docs/ch_glossary.adoc:	native_words.asm
	tools/generate_glossary.py > docs/ch_glossary.adoc

# The diagrams use ditaa to generate pretty diagrams from text files.
# They have their own makefile in the docs/pics directory.
docs-diagrams: docs/pics/*.txt
	cd docs/pics; $(MAKE)

docs: docs/manual.html docs-diagrams

# This one is experimental at the moment.
docsmd: docs/manual.html
	cd docs; ./asciidoc_to_markdown.sh

# A convenience target for preparing for a git commit.
gitready: docs all tests
