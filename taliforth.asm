; Tali Forth 2 for the 65c02
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014 (Tali Forth)
; This version: 28. Apr 2018

; This is the main file for Tali Forth 2

; By default, we have 32 KiB of RAM and 32 KiB of ROM. See docs/memorymap.txt
; for details
.advance $8000

; Label used to calculate UNUSED. Silly for Tali Forth, where we assume
; 32 KiB RAM and 32 KiB ROM, but kept here to make the code more useful
; for other hardware configurations
code0:

.require "definitions.asm"      ; Top-level definitions, memory map

; Insert point for Tali Forth after kernel hardware setup
forth:

.require "native_words.asm"     ; Native Forth words. Starts with COLD

; High-level Forth words, see forth_code/README.md
forth_words_start:
.incbin "forth_words.asc"
forth_words_end:

; User-defined Forth words, see forth_code/README.md
user_words_start:
.incbin "user_words.asc"
user_words_end:

.require "headers.asm"          ; Headers of native words
.require "strings.asm"          ; Strings and error messages

; =====================================================================
; COMPILE WORDS, JUMPS and SUBROUTINE JUMPS INTO CODE

; These three routines compile instructions such as "jsr xt_words" into a 
; word at compile time so they are available at run time. Words that use 
; this routine may not be natively compiled. We use "cmpl" as not to 
; confuse these routines with the COMPILE, word. Always call this with a 
; subroutine jump, which means combining JSR/RTS to JMP in those cases is
; not okay. To use, load the LSB of the address in A and the MSB in Y:
;
;               ldy #>addr      ; MSB
;               lda #<addr      ; LSB
;               jsr cmpl_subroutine
;
; You can remember which comes first by thinking of the song "Young Americans"
; ("YA") by David Bowie.
.scope
cmpl_subroutine:
                ; This is the entry point to compile JSR <ADDR>
                pha             ; save LSB of address
                lda #$20        ; load opcode for JSR
                bra cmpl_common
cmpl_jump:
                ; This is the entry point to compile JMP <ADDR>
                pha             ; save LSB of address
                lda #$4c        ; load opcode for JMP, fall thru to cmpl_common
cmpl_common:
                ; At this point, A contains the opcode to be compiled,
                ; the LSB of the address is on the 65c02 stack, and the MSB of
                ; the address is in Y
                jsr cmpl_a      ; compile opcode
                pla             ; retrieve address LSB; fall thru to cmpl_word
cmpl_word:
                ; This is the entry point to compile a word (little-endian)
                jsr cmpl_a      ; compile LSB of address
                tya             ; fall thru for MSB
cmpl_a:
                sta (cp)
                inc cp
                bne _done
                inc cp+1
_done:
		rts
.scend

; =====================================================================
; CODE FIELD ROUTINES

doconst:
        ; """Execute a CONSTANT: Push the data in the first two bytes of
        ; the Data Field onto the Data Stack
        ; """
                dex             ; make room for constant
                dex

                ; The value we need is stored in the two bytes after the
                ; JSR return address, which in turn is what is on top of
                ; the Return Stack
                pla             ; LSB of return address
                sta tmp1
                pla             ; MSB of return address
                sta tmp1+1

                ; start LDY with 1 instead of 0 because of how JSR stores
                ; the return address on the 65c02
                ldy #1
                lda (tmp1),y
                sta 0,x
                iny
                lda (tmp1),y
                sta 1,x

                ; this takes us back to the original caller, not the
                ; DOCONST caller
                rts


dodefer:
.scope
        ; """Execute a DEFER statement at runtime: Execute the address we
        ; find after the caller in the Data Field
        ; """
                ; The xt we need is stored in the two bytes after the JSR
                ; return address, which is what is on top of the Return
                ; Stack. So all we have to do is replace our return jump
                ; with what we find there
		pla             ; LSB
                sta tmp1
                pla             ; MSB
                sta tmp1+1

                ldy #1
                lda (tmp1),y
                sta tmp2
                iny
                lda (tmp1),y
                sta tmp2+1

                jmp (tmp2)      ; This is actually a jump to the new target
.scend

defer_error:
                ; """Error routine for undefined DEFER: Complain and abort"""
                lda #2          ; DEFER not defined yet
                jmp error

dodoes:
.scope
        ; """Execute the runtime portion of DOES>. See DOES> and
        ; docs/create-does.txt for details and
        ; http://www.bradrodriguez.com/papers/moving3.htm
        ; """
  		; Assumes the address of the CFA of the original defining word
                ; (say, CONSTANT) is on the top of the Return Stack. Save it
                ; for a later jump, adding one byte because of the way the
                ; 6502 works
                ply             ; LSB
                pla             ; MSB
                iny
                bne +
                inc
*
                sty tmp2
                sta tmp2+1
               
                ; Next on the Return Stack should be the address of the PFA of
                ; the calling defined word (say, the name of whatever constant we
                ; just defined). Move this to the Data Stack, again adding one.
                dex
                dex
                
                ply
                pla
                iny
                clc
                bne +
                inc
*
                sty 0,x         ; LSB
                sta 1,x         ; MSB

                ; This leaves the return address from the original main routine
                ; on top of the Return Stack. We leave that untouched and jump
                ; to the special code of the defining word. It's RTS instruction
                ; will take us back to the main routine
                jmp (tmp2)
.scend


dovar:
.scope
        ; """Execute a variable: Push the address of the first bytes of
        ; the Data Field onto the stack. This is called with JSR so we
        ; can pick up the address of the calling variable off the 65c02's
        ; stack. The final RTS takes us to the original caller of the
        ; routine that itself called DOVAR. This is the default 
        ; routine installed with CREATE.
        ; """
                ; Pull the return address off the machine's stack, adding
                ; one because of the way the 65c02 handles subroutines
                ply             ; LSB
                pla             ; MSB
                iny
                bne +
                inc
*
                dex
                dex

                sta 1,x
                tya
                sta 0,x
                
                rts
.scend

; =====================================================================
; LOW LEVEL HELPER FUNCTIONS

byte_to_ascii:
        ; """Convert byte in A to two ASCII hex digits and EMIT them"""
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

compare_16bit:
        ; """Compare TOS/NOS and return results in form of the 65c02 flags
        ; Adapted from Leventhal "6502 Assembly Language Subroutines", see
        ; also http://www.6502.org/tutorials/compare_beyond.html
        ; For signed numbers, Z signals equality and N which number is larger: 
        ;       if TOS = NOS: Z=1 and N=0
        ;       if TOS > NOS: Z=0 and N=0
        ;       if TOS < NOS: Z=0 and N=1
        ; For unsigned numbers, Z signals equality and C which number is larger:
        ;       if TOS = NOS: Z=1 and N=0
        ;       if TOS > NOS: Z=0 and C=1
        ;       if TOS < NOS: Z=0 and C=0
        ; Compared to the book routine, WORD1 (MINUED) is TOS 
        ;                               WORD2 (SUBTRAHEND) is NOS
        ; """
.scope
                ; Compare LSB first to set the carry flag
                lda 0,x                 ; LSB of TOS
                cmp 2,x                 ; LSB of NOS
                beq _equal

                ; LSBs are not equal, compare MSB
                lda 1,x                 ; MSB of TOS
                sbc 3,x                 ; MSB of NOS
                ora #1                  ; Make zero flag 0 because not equal
                bvs _overflow
                bra _not_equal
_equal:
                ; low bytes are equal, so we compare high bytes
                lda 1,x                 ; MSB of TOS
                sbc 3,x                 ; MSB of NOS
                bvc _done
_overflow:
                ; handle overflow because we use signed numbers
                eor #$80                ; complement negative flag
_not_equal:     
                ora #1                  ; if overflow, we can't be eqal
_done:
                rts
.scend


interpret:
.scope
        ; """Core routine for the interpreter called by EVALUATE and QUIT.
        ; Process one line only. Assumes that the address of name is in
        ; cib and the length of the whole input line string is in ciblen
        ; """
                ; Normally we would use PARSE here with the SPACE character as
                ; a parameter (PARSE replaces WORD in modern Forths). However,
                ; Gforth's PARSE-NAME makes more sense as it uses spaces as
                ; delimiters per default and skips any leading spaces, which
                ; PARSE doesn't
_loop:
                jsr xt_parse_name       ; ( "string" -- addr u ) 

                ; If PARSE-NAME returns 0 (empty line), no characters were left
                ; in the line and we need to go get a new line
                lda 0,x
                ora 1,x
                beq _line_done

                ; Go to FIND-NAME to see if this is a word we know. We have to
                ; make a copy of the address in case it isn't a word we know and
                ; we have to go see if it is a number
                jsr xt_two_dup          ; ( addr u -- addr u addr u ) 
                jsr xt_find_name        ; ( addr u addr u -- addr u nt|0 )

                ; a zero signals that we didn't find a word in the Dictionary
                lda 0,x
                ora 1,x
                bne _got_name_token

                ; We didn't get any nt we know of, so let's see if this is
                ; a number. 
                inx                     ; ( addr u 0 -- addr u )
                inx

                ; If the number conversion doesn't work, NUMBER will do the
                ; complaining for us
                jsr xt_number           ; ( addr u -- u|d ) 

                ; Otherweise, if we're interpreting, we're done
                lda state
                beq _loop

                ; We're compiling, so there is a bit more work. Note this
                ; doesn't work with double-cell numbers, only single-cell
                ldy #>literal_runtime
                lda #<literal_runtime
                jsr cmpl_subroutine

                ; compile our number
                jsr xt_comma
     
                ; That was so much fun, let's do it again!
                bra _loop

_got_name_token:
                ; We have a known word's nt TOS. We're going to need its xt
                ; though, which is four bytes father down. 
                
                ; we arrive here with ( addr u nt ), so we NIP twice
                lda 0,x
                sta 4,x
                lda 1,x
                sta 5,x

                inx
                inx
                inx
                inx                     ; ( nt ) 
                
                ; Save a version of nt for error handling and compilation stuff
                lda 0,x
                sta tmpbranch
                lda 1,x
                sta tmpbranch+1

                jsr xt_name_to_int      ; ( nt - xt ) 

                ; See if we are in interpret or compile mode, 0 is interpret
                lda state
                bne _compile

                ; We are interpreting, so EXECUTE the xt that is TOS. First,
                ; though, see if this isn't a compile-only word, which would be
                ; illegal. The status byte is the second one of the header.
                ldy #1
                lda (tmpbranch),y
                and #CO                 ; mask everything but Compile Only bit
                beq _interpret

                ; TODO see if we can print offending word first
                lda #1                  ; code for "compile only word" error
                jmp error

_interpret:
                ; We JSR to EXECUTE instead of calling the xt directly because
                ; the RTS of the word we're executing will bring us back here,
                ; skipping EXECUTE completely during RTS. If we were to execute
                ; xt directly, we have to fool around with the Return Stack
                ; instead, which is actually slightly slower
                jsr xt_execute

                ; That's quite enough for this word, let's get the next one
                jmp _loop

_compile:
                ; We're compiling! However, we need to see if this is an
                ; IMMEDIATE word, which would mean we execute it right now even
                ; during compilation mode. Fortunately, we saved the nt so life
                ; is easier. The flags are in the second byte of the header
                ldy #1
                lda (tmpbranch),y
                and #IM                 ; Mask all but IM bit
                bne _interpret          ; IMMEDIATE word, execute right now

                ; Compile the xt into the Dictionary with COMPILE,
                jsr xt_compile_comma
                jmp _loop

_line_done:
                ; drop stuff from PARSE_NAME
                inx
                inx
                inx
                inx

                rts
.scend

underflow:
        ; """Landing area for data stack underflow"""
                lda #11                 ; signal underflow

                ; fall through to error

error: 
        ; """Given the error number in A, print the associated error string and 
        ; call ABORT. Uses tmp3.
        ; """
                asl
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
                asl
                tay
                lda string_table,y
                sta tmp3                ; LSB
                iny
                lda string_table,y
                sta tmp3+1              ; MSB

                ; falls through to print_common

print_common:
        ; """Common print loop for print_string and print_error. Assumes
        ; zero-terminated address of string to be printed is in tmp3. 
        ; Adds LF
        ; """
.scope
                ldy #0
_loop:
                lda (tmp3),y
                beq _done               ; strings are zero-terminated
                jsr emit_a              ; allows vectoring via OUTPUT
                iny
                bra _loop
_done:
                lda #AscLF
                jsr emit_a

        	rts
.scend


print_u:
        ; """Basic printing routine used by higher-level constructs,
        ; the equivalent of the Forth word  0 <# #S #> TYPE  which is
        ; basically U. without the SPACE at the end. Used for various
        ; outputs
.scope
                dex                     ; 0
                dex
                stz 0,x
                stz 1,x

                jsr xt_less_number_sign         ; <#
                jsr xt_number_sign_s            ; #S
                jsr xt_number_sign_greater      ; #>
                jsr xt_type                     ; TYPE
        
                rts
.scend

; =====================================================================
; EDITOR
; (Currently no editor available)

; =====================================================================
; ASSEMBLER
; (Currently no assembler available)

; =====================================================================
; DISASSEMBLER
; (Currently no disassembler available)

