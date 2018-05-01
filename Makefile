COMMON_SOURCES=taliforth.asm definitions.asm native_words.asm headers.asm strings.asm forth_words.asc user_words.asc

all: taliforth-py65mon.bin

taliforth-%.bin: platform-%.asm $(COMMON_SOURCES)
	ophis -l docs/$*-listing.txt \
	-m docs/$*-labelmap.txt \
	-o $@ \
	-c $<

%.asc: forth_code/%.fs
	python3 forth_code/forth_to_ophisbin.py -i $< > $@
