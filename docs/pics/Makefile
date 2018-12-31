# Makefile for Tali Forth 2's diagrams (uses ditaa to compile)
# This version: 2018-12-16

# This makefile is called from the main project Makefile.

# Add any diagram images to this space separated list.
DIAGRAM_IMAGES=blocks-block.png blocks-flush.png blocks-newblock.png \
               blocks-update.png blocks-update3.png ed_node.png \
               stack_diagram.png double_cell.png header_diagram.png \
               memory_map.png

all:	$(DIAGRAM_IMAGES)

# Create a .png file for each .txt file in this directory.
%.png:	%.txt
	ditaa -o $<

