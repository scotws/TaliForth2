; Tali Forth 2 for the 65c02
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014 (Tali Forth)
; This version: 04. Dec 2017

; This is the main file for Tali Forth 2

; By default, we have 32 KiB of RAM and 32 KiB of ROM. See docs/memorymap.txt
; for details
.org $8000

; Label used to calculate UNUSED. Silly for Tali Forth, where we assume 32 KiB
; RAM and 32 KiB ROM, but required for Liara Forth, and kept here to make the
; code compatible
code0:

.require "definitions.asm"      ; Top-level definitions, memory map

; Insert point for Tali Forth after kernel hardware setup
forth:

.require "native_words.asm"     ; Native Forth words. Starts with COLD
.require "forth_words.asm"      ; High-level Forth words
.require "user_words.asm"       ; User-defined words (optional)
.require "headers.asm"          ; Headers of native words
.require "strings.asm"          ; Strings and error messages


; =====================================================================
; COMPILE WORDS, JUMPS and SUBROUTINE JUMPS INTO CODE

; These three routines compile instructions such as "jsr xt_words" into a 
; word at compile time so they are available at run time.  Words that use 
; this routine may not be natively compiled. We use "cmpl" as not to 
; confuse these routines with the COMPILE, word. Always call this with a 
; subroutine jump, which means combining JSR/RTS to JMP in those cases is
; not okay.

cmpl_word:

cmpl_subroutine:

cmpl_jump:

		rts


; =====================================================================
; CODE FIELD ROUTINES

doconst:
        ; """Execute a CONSTANT: Push the data in the first two bytes of
        ; the Data Field onto the stack
        ; """
        ; TODO
                rts


dodefer:
        ; """Execute a DEFER statement at runtime: Execute the address we
        ; find after the caller in the Data Field
        ; """
        ; TODO
                rts


dodoes:
        ; """Execute the runtime portion of DOES>. See DOES> and
        ; docs/create-does.txt for details
        ; """
        ; TODO
                rts


dovar:
        ; """Execute a variable: Push the address of the first bytes of
        ; the Data Field onto the stack. This is called with JSR so we
        ; can pick up the address of the calling variable off the 65c02's
        ; stack. The final RTS takes us to the original caller of the
        ; routine that itself called DOVAR. This is the default 
        ; routine installed with CREATE.
        ; """
        ; TODO
                rts


; =====================================================================
; LOW LEVEL HELPER FUNCTIONS


byte_to_ascii:
        ; """Convert byte in A to two ASCII hex digits and EMIT them.
        ; """
        ; TODO test routine
.scope
                pha
                lsr             ; convert high nibble first
                lsr
                lsr
                lsr
                jsr _nibble_to_ascii
                pla

                ; fall through to _nibble_to_ascii


_nibble_to_ascii:
        ; """Private helper function for byte_to_ascii: Print lower nibble
        ; of A and and EMIT it. This does the actual work.
        ; """
                and #$0f
                ora #'0
                cmp #$3a        ; '9+1
                bcc +
                adc #$06

*               jmp emit_a

        	rts
.scend



interpret:
        ; """Core routine for the interpreter called by EVALUATE and QUIT.
        ; Process one line only. Assumes that the address of name is in
        ; cib and the length of the whole input line string is in ciblen
        ; """
        ; TODO 
                rts

error: 
        ; """Given the error number in A, print the associated error string and 
        ; call ABORT. Uses tmp3.
        ; """
                tay
                lda error_table,y
                sta tmp3                ; LSB
                iny
                lda error_table,y
                sta tmp3+1              ; MSB

                jsr print_common
        	jmp xt_abort            ; no JSR, as we clobber Return Stack


print_string: 
        ; """Print a zero-terminated string to the console/screen, adding a
        ; LF. We are given the string number, which functions as an index to
        ; the string table. We do not check to see if the index is out of
        ; range. Uses tmp3.
        ; """
                tay
                lda string_table,y
                sta tmp3                ; LSB
                iny
                lda string_table,y
                sta tmp3+1              ; MSB

                ; falls through to print_common

print_common:
.scope
        ; """Common print loop for print_string and print_error. Assumes
        ; zero-terminated address of string to be printed is in tmp3. 
        ; Adds LF
        ; """
                ldy #00
_loop:
                lda (tmp3),y
                beq _done               ; strings are zero-terminated
                jsr emit_a              ; allows vectoring via OUTPUT
                iny
                bra _loop
_done:
                lda AscLF
                jsr emit_a

        	rts
.scend

print_u:
        ; """Print unsigned number on TOS. This is the equvalent to Forth's
        ; U. or 0 <# S# #> TYPE without the SPACE at the end. TODO convert
        ; this to more assembler for speed.
        ; """
        ; TODO
        	rts


; =====================================================================
; FINALLY

; Of the 32 KiB we use, 24 are reserved for Tali (from $8000 to $DFFF) and the
; last eight are left for whatever the user wants to use them for.

.advance $e000
.require "kernel.asm"

; END
