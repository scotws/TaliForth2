; Tali Forth 2 for the 65c02
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014 (Tali Forth)
; This version: 27. Nov 2017

; This is the main file for Tali Forth 2. At different points, it imports
; other files in this sequence:
;
;  - definitions.asm   Top-level definitions with memory map
;  - headers.asm       Headers of the Forth words
;  - native_words.asm  Code of the lower-level Forth words
;  - forth_words.asm   Code of the high-level Forth words
;  - strings.asm       Strings and error messages
;  - kernel.asm        Hardware-dependend routines (for py65mon by default)

; By default, we have 32 KiB of RAM and 32 KiB of ROM. See docs/memorymap.txt
; for details
.org $8000

; The hardware initilization in the kernel jumps to this label, which must
; be present
forth:
                nop 

; .require "definitions.asm"
.require "headers.asm"
.require "native_words.asm"
.require "forth_words.asm"
.require "strings.asm"

; Of the 32 KiB we use, 24 are reserved for Tali (from $8000 to $DFFF) and the
; last eight are left for whatever the user wants to use them for.

.advance $e000
.require "kernel.asm"

; END
