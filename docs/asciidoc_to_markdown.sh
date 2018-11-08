# Convert asciidoc to docbook using asciidoctor
# Based on: https://github.com/asciidoctor/asciidoctor/issues/1907
# by Dan Allen
# This version Scot W. Stevenson <scot.stevenson@gmail.com>
# First version 08. Nov 2018
# This version 08. Nov 2018
asciidoctor -b docbook -a leveloffset=+1 -o - manual.adoc | pandoc --atx-headers --wrap=preserve -t markdown_github -f docbook - > manual.md

# Known problems: The title line is eaten by pandoc, though the "leveloffset"
# value is supposed to stop this
