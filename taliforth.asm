; Tali Forth 2 for the 65c02
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: FEHLT (Tali Forth)
; This version: 24. November 2017

; This is the main file for Tali Forth 2. At different points, it imports
; other files in this sequence::
;
;  - definitions.asm   Top-level definitions with memory map
;  - headers.asm       Headers of the Forth words
;  - native_words.asm  Code of the lower-level Forth words
;  - forth_words.asm   Code of the high-level Forth words
;  - strings.asm       Strings and error messages
;  - kernel.asm        Hardware-dependend routines (for py65mon by default)

; We assume 32k of RAM and 32k of ROM
.org $8000

; =============================================================================
; VECTOR INSERT POINT

; All vectors currently end up in the same place
v_nmi:
v_reset:
v_irq:


; .require "definitions.asm"
.require "headers.asm"
.require "native_words.asm"
.require "forth_words.asm"
.require "strings.asm"
; .require "kernel.asm"

; =============================================================================
; INTERRUPT VECTORS
.advance $FFFA  ; fill with zeros so we get a complete ROM image 

.word v_nmi     ; NMI vector (from defintions.asm)
.word v_reset   ; RESET vector (from defintions.asm)
.word v_irq     ; IRQ vector (from defintions.asm)

; END
