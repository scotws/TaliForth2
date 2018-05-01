COMMON_SOURCES=taliforth.asm definitions.asm native_words.asm headers.asm strings.asm

all: taliforth-py65mon.bin

taliforth-%.bin: platform-%.asm $(COMMON_SOURCES)
	ophis -l docs/$*-listing.txt \
	-m docs/$*-labelmap.txt \
	-o $@ \
	-c $<
