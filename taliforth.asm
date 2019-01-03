; Tali Forth 2 for the 65c02
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014 (Tali Forth 1)
; This version: 03. Jan 2018 (Version 1.0)

; This is the main file for Tali Forth 2

; Label used to calculate UNUSED. Silly for Tali Forth, where we assume
; 32 KiB RAM and 32 KiB ROM, but kept here to make the code more useful for
; other hardware configurations
code0:

.require "definitions.asm"      ; Top-level definitions, memory map

; Insert point for Tali Forth after kernel hardware setup
forth:

.require "native_words.asm"     ; Native Forth words. Starts with COLD
.require "assembler.asm"        ; SAN assembler
.require "disassembler.asm"     ; SAN disassembler
.require "ed.asm"               ; Line-based editor ed6502

; High-level Forth words, see forth_code/README.md
forth_words_start:
.incbin "forth_words.asc"
forth_words_end:

; User-defined Forth words, see forth_code/README.md
user_words_start:
.incbin "user_words.asc"
user_words_end:

.require "headers.asm"          ; Headers of native words
.require "strings.asm"          ; Strings, including error messages


; =====================================================================
; COMPILE WORDS, JUMPS and SUBROUTINE JUMPS INTO CODE

; These three routines compile instructions such as "jsr xt_words" into a word
; at compile time so they are available at run time. Words that use this
; routine may not be natively compiled. We use "cmpl" as not to confuse these
; routines with the COMPILE, word. Always call this with a subroutine jump.
; This means combining JSR/RTS to JMP in those cases is not going to work. To
; use, load the LSB of the address in A and the MSB in Y. You can remember
; which comes first by thinking of the song "Young Americans" ("YA") by David
; Bowie.

;               ldy #>addr      ; MSB   ; "Young"
;               lda #<addr      ; LSB   ; "Americans"
;               jsr cmpl_subroutine

; Also, we keep a routine here to compile a single byte passed through A.
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
                ; This is the entry point to compile a single byte which
                ; is passed in A. The built-in assembler assumes that this
                ; routine does not modify Y.
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

                ; Start LDY with 1 instead of 0 because of how JSR stores
                ; the return address on the 65c02
                ldy #1
                lda (tmp1),y
                sta 0,x
                iny
                lda (tmp1),y
                sta 1,x

                ; This takes us back to the original caller, not the
                ; DOCONST caller
                rts


dodefer:
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

defer_error:
                ; """Error routine for undefined DEFER: Complain and abort"""
                lda #err_defer
                jmp error

dodoes:
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


dovar:
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
                and #$0F
                ora #'0
                cmp #$3A        ; '9+1
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
                ; Low bytes are equal, so we compare high bytes
                lda 1,x                 ; MSB of TOS
                sbc 3,x                 ; MSB of NOS
                bvc _done
_overflow:
                ; Handle overflow because we use signed numbers
                eor #$80                ; complement negative flag
_not_equal:
                ora #1                  ; if overflow, we can't be eqal
_done:
                rts
.scend

current_to_dp:
        ; """Look up the current (compilation) dictionary pointer
        ; in the wordlist set and put it into the dp zero-page
        ; variable. Uses A and Y.
        ; """
                ; Determine which wordlist is current
                ldy #current_offset
                lda (up),y      ; current is a byte variable
                asl             ; turn it into an offset (in cells)

                ; Get the dictionary pointer for that wordlist.
                clc
                adc #wordlists_offset   ; add offset to wordlists base.
                tay
                lda (up),y              ; get the dp for that wordlist.
                sta dp
                iny
                lda (up),y
                sta dp+1

                rts


dp_to_current:
        ; """Look up which wordlist is current and update its pointer
        ; with the value in dp. Uses A and Y.
        ; """
                ; Determine which wordlist is current
                ldy #current_offset
                lda (up),y      ; current is a byte variable
                asl             ; turn it into an offset (in cells)

                ; Get the dictionary pointer for that wordlist.
                clc
                adc #wordlists_offset   ; add offset to wordlists base.
                tay
                lda dp
                sta (up),y              ; get the dp for that wordlist.
                iny
                lda dp+1
                sta (up),y

                rts

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

                ; A zero signals that we didn't find a word in the Dictionary
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

                ; We're compiling, so there is a bit more work.  Check
                ; status bit 5 to see if it's a single or double-cell
                ; number.
                lda #$20
                bit status
                beq _single_number

                ; It's a double cell number.  If we swap the
                ; upper and lower half, we can use the literal_runtime twice
                ; to compile it into the dictionary.
                jsr xt_swap
                ldy #>literal_runtime
                lda #<literal_runtime
                jsr cmpl_subroutine

                ; compile our number
                jsr xt_comma

                ; Fall into _single_number to process the other half.
_single_number:
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

                ; We arrive here with ( addr u nt ), so we NIP twice
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

                lda #err_compileonly
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


is_printable:
.scope
        ; """Given a character in A, check if it is a printable ASCII
        ; character in the range from $20 to $7E inclusive. Returns the
        ; result in the Carry Flag: 0 (clear) is not printable, 1 (set)
        ; is printable. Keeps A. See
        ; http://www.obelisk.me.uk/6502/algorithms.html for a
        ; discussion of various ways to do this
                cmp #AscSP              ; $20
                bcc _done
                cmp #'~ + 1             ; $7E
                bcs _failed

                sec
                bra _done
_failed:
                clc
_done:
                rts
.scend


is_whitespace:
.scope
        ; """Given a character in A, check if it is a whitespace
        ; character, that is, an ASCII value from 0 to 32 (where
        ; 32 is SPACE). Returns the result in the Carry Flag:
        ; 0 (clear) is no, it isn't whitespace, while 1 (set) means
        ; that it is whitespace. See PARSE and PARSE-NAME for
        ; a discussion of the uses. Does not change A or Y.
                cmp #00         ; explicit comparison to leave Y untouched
                bcc _done

                cmp #AscSP+1
                bcs _failed

                sec
                bra _done
_failed:
                clc
_done:
                rts
.scend


; Underflow tests. We jump to the label with the number of cells (not: bytes)
; required for the word. This routine flows into the generic error handling
; code
underflow_1:
        ; """Make sure we have at least one cell on the Data Stack"""
                cpx #dsp0-1
                bpl underflow_error
                rts
underflow_2:
        ; """Make sure we have at least two cells on the Data Stack"""
                cpx #dsp0-3
                bpl underflow_error
                rts
underflow_3:
        ; """Make sure we have at least three cells on the Data Stack"""
                cpx #dsp0-5
                bpl underflow_error
                rts
underflow_4:
        ; """Make sure we have at least four cells on the Data Stack"""
                cpx #dsp0-7
                bpl underflow_error
                rts

underflow_error:
                ; Entry for COLD/ABORT/QUIT
                lda #err_underflow      ; fall through to error

error:
        ; """Given the error number in a, print the associated error string and
        ; call abort. Uses tmp3.
        ; """
                asl
                tay
                lda error_table,y
                sta tmp3                ; LSB
                iny
                lda error_table,y
                sta tmp3+1              ; MSB

                jsr print_common
                jsr xt_cr
                jmp xt_abort            ; no jsr, as we clobber return stack


; =====================================================================
; PRINTING ROUTINES

; We distinguish two types of print calls, both of which take the string number
; (see strings.asm) in A:

;       print_string       - with a line feed
;       print_string_no_lf - without a line feed

; In addition, print_common provides a lower-level alternative for error
; handling and anything else that provides the address of the
; zero-terminated string directly in tmp3. All of those routines assume that
; printing should be more concerned with size than speed, because anything to
; do with humans reading text is going to be slow.

print_string_no_lf:
        ; """Given the number of a zero-terminated string in A, print it to the
        ; current output without adding a LF. Uses Y and tmp3 by falling
        ; through to print_common
        ; """
                ; Get the entry from the string table
                asl
                tay
                lda string_table,y
                sta tmp3                ; LSB
                iny
                lda string_table,y
                sta tmp3+1              ; MSB

                ; fall through to print_common
print_common:
        ; """Common print routine used by both the print functions and
        ; the error printing routine. Assumes string address is in tmp3. Uses
        ; Y.
        ; """
.scope
                ldy #0
_loop:
                lda (tmp3),y
                beq _done               ; strings are zero-terminated

                jsr emit_a              ; allows vectoring via output
                iny
                bra _loop
_done:
                rts
.scend

print_string:
        ; """Print a zero-terminated string to the console/screen, adding a LF.
        ; We do not check to see if the index is out of range. Uses tmp3.
        ; """
                jsr print_string_no_lf
                jmp xt_cr               ; JSR/RTS because never compiled


print_u:
        ; """basic printing routine used by higher-level constructs,
        ; the equivalent of the forth word  0 <# #s #> type  which is
        ; basically u. without the space at the end. used for various
        ; outputs
        ; """
                jsr xt_zero                     ; 0
                jsr xt_less_number_sign         ; <#
                jsr xt_number_sign_s            ; #S
                jsr xt_number_sign_greater      ; #>
                jmp xt_type                     ; JSR/RTS because never compiled

; END
