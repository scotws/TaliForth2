# Makefile for Tali Forth 2's diagrams (uses ditaa to compile)
# This version: 2018-12-16

# This makefile is called from the main project Makefile.

# Add any diagram images to this space separated list.
DIAGRAM_SOURCES=blocks-*.png 

all:	$(DIAGRAM_SOURCES)

# Create a .png file for each .txt file in this directory.
%.png:	%.txt
	ditaa -o $<

