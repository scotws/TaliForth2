; Low-level Forth word routines
; Tali Forth 2 for the 65c02
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014
; This version: 03. Jan 2018

; This list is ordered alphabetically by the names of the words, not their
; strings (so "!" is sorted as "STORE"). However, we start off with COLD,
; ABORT, and QUIT as the natural start sequence. Each word has two special
; status lines that begins with "; ## ", which allows auto-generation of the
; WORDLIST.md file and other entries in the docs folder. Status entries are:

;       TBA --> fragment --> coded --> tested --> auto

; "Auto" means that the word is automatically tested by the test suite (good),
; "tested" means that it was tested by hand in some way (okay), "coded" means
; it hasn't been tested at all (bad). See the test suite for more details.

; ## COLD ( -- ) "Reset the Forth system"
; ## "cold"  tested  Tali Forth
;       """Reset the Forth system. Does not restart the kernel,
;       use the 65c02 reset for that. Flows into ABORT.
;       """
xt_cold:
                cld

                ; Set the OUTPUT vector to the default kernel_putc
                ; We do this really early so we can print error messages
                ; during debugging
                lda #<kernel_putc
                sta output
                lda #>kernel_putc
                sta output+1

                ; Load all of the important zero page variables from ROM
                ldx #cold_zp_table_end-cold_zp_table-1

_load_zp_loop:
                ; This loop loads them back to front. We can use X here
                ; because Tali hasn't started using the stack yet.
                lda cold_zp_table,x
                sta zpage,x
                dex
                bne _load_zp_loop

                ; Copy the 0th element.
                lda cold_zp_table
                sta zpage

                ; Initialize 65c02 stack (Return Stack)
                ldx #rsp0
                txs

                ; Clear Data Stack. This is repeated in ABORT, but this way we
                ; can load high-level words with EVALUATE
                ldx #dsp0

                ; Initialize the user variables.
                ldy #cold_user_table_end-cold_user_table-1
                lda #0

_load_user_vars_loop:
                ; Like the zero page variables, these are initialized
                ; back to front.
                lda cold_user_table,y
                sta (up),y
                dey
                bne _load_user_vars_loop

                ; Copy the 0th element.
                lda cold_user_table
                sta (up)
                jsr xt_cr

                ; Define high-level words in forth_words.asm via EVALUATE. If
                ; you do not have any high-level words, this part can be
                ; commented out.
                dex
                dex
                dex
                dex

                ; start address goes NOS
                lda #<forth_words_start
                sta 2,x
                lda #>forth_words_start
                sta 3,x

                ; length goes TOS
                lda #<forth_words_end
                sec
                sbc #<forth_words_start
                sta 0,x

                lda #>forth_words_end
                sbc #>forth_words_start
                sta 1,x

                jsr xt_evaluate

                ; Now define any user words via EVALUATE. If you do not have
                ; any user-defined words, this part can be commented out as
                ; well.
                dex
                dex
                dex
                dex

                ; start address goes NOS
                lda #<user_words_start
                sta 2,x
                lda #>user_words_start
                sta 3,x

                ; length goes TOS
                lda #<user_words_end
                sec
                sbc #<user_words_start
                sta 0,x

                lda #>user_words_end
                sbc #>user_words_start
                sta 1,x

                jsr xt_evaluate

                ; Initialize all of the history buffers by putting a zero in
                ; each length byte.
                stz hist_buff
                stz hist_buff+$80
                stz hist_buff+$100
                stz hist_buff+$180
                stz hist_buff+$200
                stz hist_buff+$280
                stz hist_buff+$300
                stz hist_buff+$380

                ; fall through to ABORT


; ## ABORT ( -- ) "Reset the Data Stack and restart the CLI"
; ## "abort"  tested  ANS core
        ; """https://forth-standard.org/standard/core/ABORT
        ; Clear Data Stack and continue into QUIT. We can jump here via
        ; subroutine if we want to because we are going to reset the 65c02's
        ; stack pointer (the Return Stack) anyway during QUIT. Note we don't
        ; actually delete the stuff on the Data Stack.
        ; """
xt_abort:
                ldx #dsp0

                ; fall through to QUIT


; ## QUIT ( -- ) "Reset the input and get new input"
; ## "quit"  tested  ANS core
        ; """https://forth-standard.org/standard/core/QUIT
        ; Rest the input and start command loop
        ; """
.scope
xt_quit:
                ; Clear the Return Stack. This is a little screwed up
                ; because the 65c02 can only set the Return Stack via X,
                ; which is our Data Stack pointer. The ANS specification
                ; demands, however, that ABORT reset the Data Stack pointer
                txa             ; Save the DSP that we just defined
                ldx #rsp0
                txs
                tax             ; Restore the DSP. Dude, seriously.

                ; make sure instruction pointer is empty
                stz ip
                stz ip+1

                ; SOURCE-ID is zero (keyboard input)
                stz insrc
                stz insrc+1

                ; STATE is zero (interpret, not compile)
                stz state
                stz state+1
_get_line:
                lda #<buffer0   ; input buffer, this is paranoid
                sta cib
                lda #>buffer0
                sta cib+1

                ; Size of current input buffer (CIB) is zero
                stz ciblen
                stz ciblen+1

                ; Accept a line from the current import source. This is how
                ; modern Forths do it.
                jsr xt_refill           ; ( -- f )

                ; Test flag: LSB of TOS
                lda 0,x
                bne _success

                ; If REFILL returned a FALSE flag, something went wrong and we
                ; need to print an error message and reset the machine. We
                ; don't need to save TOS because we're going to clobber it
                ; anyway when we go back to ABORT.
                lda #err_refill
                jmp error

_success:
                ; Assume we have successfully accepted a string of input from
                ; a source, with address cib and length of input in ciblen. We
                ; arrive here still with the TRUE flag from REFILL as TOS
                inx                     ; drop
                inx

                ; Main compile/execute routine
                jsr interpret

                ; Test for Data Stack underflow. Tali Forth does not check for
                ; overflow because it is so rare
                cpx #dsp0
                beq _stack_ok
                bcc _stack_ok           ; DSP must always be smaller than DSP0

                jmp underflow_error

_stack_ok:
                ; Display system prompt if all went well. If we're interpreting,
                ; this is " ok", if we're compiling, it's " compiled". Note
                ; space at beginning of the string.
                lda state
                beq _print

                lda #1                  ; number for "compile" string
_print:
                jsr print_string

                ; Awesome line, everybody! Now get the next one.
                bra _get_line

z_cold:
z_abort:
z_quit:         ; no RTS required
.scend


; This table holds all of the initial values for the variables in zero page.
; This table is used by COLD.
cold_zp_table:
        .word cp0+256+1024      ; cp moved to make room for user vars and
                                ; block buffer
        .word dictionary_start  ; dp
        .word 0                 ; workword
        .word 0                 ; insrc (SOURCE-ID is 0 for keyboard)
        .word buffer0           ; cib
        .word 0                 ; ciblen
        .word 0                 ; toin
        .word 0                 ; ip
        .word kernel_putc       ; output
        .word kernel_getc       ; input
        .word 0                 ; havekey
        .word 0                 ; state (0 = interpret)
        .word 10                ; base
        .word 20                ; nc-limit
        .word 0                 ; uf_strip (off by default)
        .word cp0               ; up (user vars put right at beginning of
                                ; available RAM)
        .word 0                 ; status
cold_zp_table_end:

; No further ZP variables are initialized. The variables past this point are
; all temporaries.

; This table holds the inital values for the user variables. This table is
; used by COLD.
cold_user_table:
        .word 0                         ; BLK
        .word 0                         ; SCR
        .byte 0                         ; CURRENT = FORTH-WORDLIST
        .byte 4                         ; #WORDLISTS (FORTH EDITOR ASSEMBLER ROOT)
        .word dictionary_start          ; FORTH-WORDLIST
        .word editor_dictionary_start   ; EDITOR-WORDLIST
        .word assembler_dictionary_start ; ASSEMBLER-WORDLIST
        .word root_dictionary_start     ; ROOT-WORDLIST
        .word 0,0,0,0,0,0,0,0           ; User wordlists
        .byte 1                         ; #ORDER
        .byte 0,0,0,0,0,0,0,0,0         ; search-order
        .word cp0+256                   ; Address of buffer (right after USER vars)
        .word 0                         ; block in buffer
        .word 0                         ; buffer status (not in use)
        .word xt_block_word_error       ; block-read vector
        .word xt_block_word_error       ; block-write vector
cold_user_table_end:


; ## ABORT_QUOTE ( "string" -- ) "If flag TOS is true, ABORT with message"
; ## "abort""  tested  ANS core
        ; """https://forth-standard.org/standard/core/ABORTq
        ; Abort and print a string.
        ; """
.scope
xt_abort_quote:
                ; save the string
                jsr xt_s_quote          ; S"

                ; compile run-time part
                ldy #>abort_quote_runtime
                lda #<abort_quote_runtime
                jsr cmpl_subroutine     ; may not be JMP as JSR/RTS

z_abort_quote:  rts
.scend

abort_quote_runtime:
        ; """Runtime aspect of ABORT_QUOTE"""
.scope
                ; We arrive here with ( f addr u )
                lda 4,x
                ora 5,x
                beq _done       ; if FALSE, we're done

                ; We're true, so print string and ABORT. We follow Gforth
                ; in going to a new line after the string
                jsr xt_type
                jsr xt_cr
                jmp xt_abort    ; not JSR, so never come back
_done:
                ; Drop three entries from the Data Stack
                txa
                clc
                adc #6
                tax

                rts
.scend


; ## ABS ( n -- u ) "Return absolute value of a number"
; ## "abs"  auto  ANS core
        ; """https://forth-standard.org/standard/core/ABS
        ; Return the absolute value of a number.
        ; """
.scope
xt_abs:
                jsr underflow_1

                lda 1,x
                bpl _done       ; positive number, easy money!

                ; negative: calculate 0 - n
                sec
                lda #0
                sbc 0,x         ; LSB
                sta 0,x

                lda #0          ; MSB
                sbc 1,x
                sta 1,x

_done:
z_abs:          rts
.scend


; ## ACCEPT ( addr n -- n ) "Receive a string of characters from the keyboard"
; ## "accept"  auto  ANS core
        ; """https://forth-standard.org/standard/core/ACCEPT
        ; Receive a string of at most n1 characters, placing them at
        ; addr. Return the actual number of characters as n2. Characters
        ; are echoed as they are received. ACCEPT is called by REFILL in
        ; modern Forths.
        ; """
.scope
xt_accept:
                jsr underflow_2

                ; Abort if we were asked to receive 0 chars
                lda 0,x
                ora 1,x
                bne _not_zero

                inx
                inx
                stz 0,x
                stz 1,x

                jmp _done

_not_zero:
                lda 0,x         ; number of chars to get in tmp2 ...
                sta tmp2
                stz tmp2+1      ; ... but we only accept max 255 chars

                lda 2,x         ; address of buffer is NOS, to tmp1
                sta tmp1
                lda 3,x
                sta tmp1+1

                inx
                inx

                ldy #0

                ; Select the next history buffer. Clear bit 3 first (so overflow
                ; from bit 2 to 3 is OK)
                lda status
                and #$f7

                ; Increment the buffer number (overflow from 7 to 0 OK)
                inc

                ; Set bit 3 for detecting if CTRL-n has been pressed the first
                ; time. This bit will be cleared on the first CTRL-n or CTRL-p
                ; received and won't be used to calculate the history buffer
                ; offset.
                ora #$08
                sta status

_loop:
                ; Out of the box, py65mon catches some CTRL sequences such as
                ; CTRL-c. We also don't need to check for CTRL-l because a
                ; vt100 terminal clears the screen automatically.

                ; This is the internal version of KEY without all the mucking
                ; about with the Data Stack while still using the input vector
                jsr key_a

                ; We quit on both line feed and carriage return
                cmp #AscLF
                beq _eol
                cmp #AscCR
                beq _eol

                ; BACKSPACE and DEL do the same thing for the moment
                cmp #AscBS
                beq _backspace
                cmp #AscDEL     ; (CTRL-h)
                beq _backspace

                ; Check for CTRL-p and CTRL-n to recall input history
                cmp #AscCP
                beq _ctrl_p
                cmp #AscCN
                beq _ctrl_n

                ; That's enough for now. Save and echo character.
                sta (tmp1),y
                iny

                ; EMIT_A sidesteps all the fooling around with the Data Stack
                jsr emit_a

                cpy tmp2        ; reached character limit?
                bne _loop       ; fall through if buffer limit reached
                bra _buffer_full

_eol:
                jsr xt_space    ; print final space

_buffer_full:
                ; REFILL updates ciblen and toin, we don't need to do it here
                sty 0,x         ; Y contains number of chars accepted already
                stz 1,x         ; we only accept 256 chars

                jmp _done

_backspace:
                ; Handle backspace and delete kex, which currently do the same
                ; thing
                cpy #0          ; buffer empty?
                bne +

                lda #AscBELL    ; complain and don't delete beyond the start of line
                jsr emit_a
                iny
*
                dey
                lda #AscBS      ; move back one
                jsr emit_a
                lda #AscSP      ; print a space (rubout)
                jsr emit_a
                lda #AscBS      ; move back over space
                jsr emit_a

                bra _loop

_ctrl_p:
                ; CTRL-p was pressed. Recall the previous input buffer.

                ; Select the previous buffer
                lda status

                ; Check for 0 (need to wrap back to 7)
                and #7
                bne _ctrl_p_dec

                ; We need to wrap back to 7.
                lda status
                ora #7
                sta status
                bra _recall_history

_ctrl_p_dec:
                ; It's safe to decrement the buffer index directly.
                dec status
                bra _recall_history

_ctrl_n:
                ; CTRL-n was pressed. Recall the next input buffer. Select
                ; the next buffer Check bit 3. If it's set, this is the first
                ; time CTRL-n has been pressed and we should select the CURRENT
                ; history buffer.
                lda #$8
                bit status
                bne _recall_history

                ; This isn't the first time CTRL-n has been pressed, select the
                ; next history buffer. Clear bit 3 first (so overflow is OK)
                lda status
                and #$f7

                ; Increment the buffer number (overflow from 7 to 0 OK)
                inc

                ; Bit 3 (if it got set by going from buffer 7 to 0) will
                ; be cleared below.
                sta status

                ; Falls through to _recall_history

_recall_history:
                ; Clear bit 3 (first time ctrl-n recall) bit in status
                lda #%00001000
                trb status

                jsr _total_recall

                ; tmp3 now has the address of the previous history buffer.
                ; First byte of buffer is length. Clear the line by sending
                ; CR, Y spaces, then CR.
                lda #AscCR
                jsr emit_a

input_clear:
                cpy #0
                beq input_cleared

                lda #AscSP
                jsr emit_a
                dey
                bra input_clear

input_cleared:
                lda #AscCR
                jsr emit_a

                ; Save the history length byte into histinfo+1
                ; ldy #0        ; Y is already 0 by clearing the line.
                lda (tmp3),y
                sta status+1

                ; Increment the tmp3 pointer so we can use ,y addressing
                ; on both tmp1 (the input buffer) and tmp3 (the history
                ; buffer)
                inc tmp3
                bne +           ; Increment the upper byte on carry.
                inc tmp3+1
*
                ; Copy the history buffer into the input buffer,
                ; sending the characters to the output as we go.
                lda #AscCR
                jsr emit_a

_history_loop:
                ; See if we have reached the end of the history buffer.
                cpy status+1
                bne +
                jmp _loop       ; Needs a long jump
*
                ; See if we have reached the end of the input buffer.
                ; (only comparing to lower byte as we currently limit
                ; to 255 characters max)
                cpy tmp2
                beq _hist_filled_buffer

                ; Copy a character and echo.
                lda (tmp3),y
                sta (tmp1),y
                jsr emit_a

                ; Move to the next character.
                iny
                bra _history_loop

_hist_filled_buffer:
                ; We don't want a history recall to EOL our buffer,
                ; so back up one character and return to editing.
                dey
                jmp _loop

_done:
                ; Copy the input buffer into the currently
                ; selected history buffer.
                jsr _total_recall
                sta status+1

                ; Also save it in the first buffer byte.
                ldy #0
                sta (tmp3),y

                ; Move path the count to the data bytes
                inc tmp3
                bne +           ; Increment the upper byte on carry.
                inc tmp3+1
*
                ; Copy the characters from the input buffer to the
                ; history buffer.

_save_history_loop:
                cpy status+1
                beq _save_history_done

                lda (tmp1),y
                sta (tmp3),y
                iny
                bra _save_history_loop

_save_history_done:
z_accept:
                rts

_total_recall:
        ; """Internal subroutine for ACCEPT that recalls history entry"""

                ; Generate the address of the buffer in tmp3. Start with the
                ; base address.
                lda #<hist_buff
                sta tmp3
                lda #>hist_buff
                sta tmp3+1

                ; This is a bit annoying as some bits go into each byte.
                ; .....xxx gets put into address like ......xx x.......
                lda status
                ror
                and #3
                clc
                adc tmp3+1
                sta tmp3+1

                lda status
                ror             ; Rotate through carry into msb.
                ror
                and #$80
                clc
                adc tmp3
                sta tmp3
                bcc +           ; Increment the upper byte on carry.
                inc tmp3+1
*
                ; Save the current length of the input buffer in
                ; histinfo+1 temporarily.  Reduce to 127 if larger.
                tya
                cmp #$80
                bcc +
                lda #$7F
*
                rts
.scend




; ## ACTION_OF ( "name" -- xt ) "Get named deferred word's xt"
; ## "action-of"  auto  ANS core ext
        ; """http://forth-standard.org/standard/core/ACTION-OF"""
.scope
xt_action_of:
                ; This is a state aware word with differet behavior
                ; when used while compiling vs interpreting.
                ; Check STATE
                lda state
                ora state+1
                beq _interpreting

_compiling:
                ; Run ['] to compile the xt of the next word
                ; as a literal.
                jsr xt_bracket_tick

                ; Postpone DEFER@ by compiling a JSR to it.
                ldy #>xt_defer_fetch
                lda #<xt_defer_fetch
                jsr cmpl_subroutine
                bra _done

_interpreting:
                jsr xt_tick
                jsr xt_defer_fetch

_done:
z_action_of:           rts
.scend


; ## AGAIN ( addr -- ) "Code backwards branch to address left by BEGIN"
; ## "again"  tested  ANS core ext
        ; """https://forth-standard.org/standard/core/AGAIN"""
.scope
xt_again:
                jsr underflow_1

                ; Add the opcode for a JMP. We use JMP instead of BRA
                ; so we have the range and don't have to calculate the
                ; offset.
                ldy #0
                lda #$4C        ; JMP
                sta (cp),y
                iny

                lda 0,x         ; LSB of address
                sta (cp),y
                iny

                lda 1,x         ; MSB of address
                sta (cp),y
                iny

                ; Allot the space we just used
                tya
                clc
                adc cp
                sta cp
                bcc _done
                inc cp+1
_done:
                inx
                inx

z_again:        rts
.scend


; ## ALIGN ( -- ) "Make sure CP is aligned on word size"
; ## "align"  auto  ANS core
        ; """https://forth-standard.org/standard/core/ALIGN
        ; On a 8-bit machine, this does nothing. ALIGNED uses this
        ; routine as well, and also does nothing
        ; """

; ## ALIGNED ( addr -- addr ) "Return the first aligned address"
; ## "aligned"  auto  ANS core
        ; """https://forth-standard.org/standard/core/ALIGNED"""
.scope
xt_align:
xt_aligned:
z_align:
z_aligned:      rts             ; stripped out during native compile
.scend


; ## ALLOT ( n -- ) "Reserve or release memory"
; ## "allot"  auto  ANS core
        ; """https://forth-standard.org/standard/core/ALLOT
        ; Reserve a certain number of bytes (not cells) or release them.
        ; If n = 0, do nothing. If n is negative, release n bytes, but only
        ; to the beginning of the Dictionary. If n is positive (the most
        ; common case), reserve n bytes, but not past the end of the
        ; Dictionary. See http://forth-standard.org/standard/core/ALLOT
        ; """
.scope
xt_allot:
                jsr underflow_1

                ; Releasing memory is going to be a very rare operation,
                ; so we check for it at the beginning and try to make
                ; the most common case as fast as possible
                lda 1,x
                bmi _release

                ; Common case: We are reserving memory, not releasing it
                clc
                lda cp
                adc 0,x
                sta cp

                lda cp+1
                adc 1,x
                sta cp+1

                ; Wait, did we just grant more space than we have? This is
                ; a check we only do here, not for other situations like cmpl_a
                ; where smaller amounts are reserved.
                ldy #<cp_end
                cpy cp
                lda #>cp_end
                sbc cp+1
                bcs _done               ; we're fine.

                ; Oops, that was too much, we're beyond the end of
                ; legal Dictionary RAM. Reduce to max memory and report
                ; an error
                sty cp                  ; still #<cp_end
                lda #>cp_end
                sta cp+1

                lda #err_allot
                jmp error

_release:
   		; The ANS standard doesn't really say what to do if too much
                ; memory is freed ("negatively alloted"). In fact, there isn't
                ; even an official test. Gforth is little help either. The good
                ; news is, this is going to be a rare case. We want to use as
                ; few bytes as possible.

                ; What we do is let the user free anything up to the beginning
                ; of the RAM area assigned to the Dicionary (CP0), but at
                ; their own risk. This means that the Dictionary pointer DP
                ; might end up pointing to garbage. However, an attempt to
                ; free more than RAM than CP0 will lead to CP being set to CP0,
                ; the DP pointing to the last word in RAM (should be DROP) and
                ; an error message.

                ; We arrive here with ( n ) which is negative. First step,
                ; subtract the number TOS from the CP for a new CP
                dex
                dex
                lda cp
                sta 0,x
                lda cp+1
                sta 1,x

                jsr xt_plus                     ; new CP is now TOS

                ; Second step, see if we've gone too far. We compare the new
                ; CP on TOS (which, if we've really screwed up, might be
                ; negative) with CP0. This is a signed comparison
                dex
                dex                             ; new CP now NOS
                lda #<cp0
                sta 0,x
                lda #>cp0
                sta 1,x                         ; CP0 is TOS

                jsr compare_16bit               ; still ( CP CP0 )

                ; If CP (NOS) is smaller than CP0 (TOS), we're in trouble.
                ; This means we want Z=1 or N=1
                beq _nega_done
                bmi _nega_done

                ; Yep, we're in trouble. Set CP to CP0, set DP to the first
                ; word in ROM (should be DROP), and abort with an error
                lda #<cp0
                sta cp
                lda #>cp0
                sta cp+1

                lda #<dictionary_start
                sta dp
                lda #>dictionary_start
                sta dp+1

                lda #err_negallot
                jmp error

_nega_done:
                ; Save new CP, which is NOS
                lda 2,x
                sta cp
                lda 3,x
                sta cp+1

                inx
                inx                     ; drop through to _done
_done:
                inx
                inx
z_allot:
                rts
.scend


; ## ALLOW_NATIVE ( -- ) "Flag last word to allow native compiling"
; ## "allow-native"  auto  Tali Forth
xt_allow_native:
                jsr current_to_dp
                ldy #1          ; offset for status byte
                lda (dp),y
                and #$ff-NN-AN  ; AN and NN flag is clear.
                sta (dp),y
z_allow_native:
                rts


; ## ALSO ( -- ) "Make room in the search order for another wordlist"
; ## "also"  auto  ANS search ext
        ; """http://forth-standard.org/standard/search/ALSO"""
xt_also:
                jsr xt_get_order
                jsr xt_over
                jsr xt_swap
                jsr xt_one_plus
                jsr xt_set_order

z_also:         rts


; ## ALWAYS_NATIVE ( -- ) "Flag last word as always natively compiled"
; ## "always-native"  auto  Tali Forth
xt_always_native:
                jsr current_to_dp
                ldy #1          ; offset for status byte
                lda (dp),y
                ora #AN         ; Make sure AN flag is set
                and #$ff-NN     ; and NN flag is clear.
                sta (dp),y
z_always_native:
                rts


; ## AND ( n n -- n ) "Logically AND TOS and NOS"
; ## "and"  auto  ANS core
        ; """https://forth-standard.org/standard/core/AND"""
xt_and:
                jsr underflow_2

                lda 0,x
                and 2,x
                sta 2,x

                lda 1,x
                and 3,x
                sta 3,x

                inx
                inx

z_and:          rts


; ## ASSEMBLER_WORDLIST ( -- u ) "WID for the Assembler wordlist"
; ## "assembler-wordlist"  tested  Tali Assembler
        ; """ Commonly used like `assembler-wordlist >order` to add the
        ; assembler words to the search order so they can be used.
        ; See the tutorial on Wordlists and the Search Order for
        ; more information.
        ;
        ; This is a dummy entry, the code is shared with TWO
        ; """


; ## AT_XY ( n m -- ) "Move cursor to position given"
; ## "at-xy"  tested  ANS facility
        ; """https://forth-standard.org/standard/facility/AT-XY
        ; On an ANSI compatible terminal, place cursor at row n colum m.
        ; ANSI code is ESC[<n>;<m>H
        ;
        ; Do not use U. to print the numbers because the
        ; trailing space will not work with xterm
        ; """
xt_at_xy:
                jsr underflow_2

                lda #AscESC
                jsr emit_a
                lda #$5B        ; ASCII for "["
                jsr emit_a
                jsr print_u
                lda #$3B        ; ASCII for ";"
                jsr emit_a
                jsr print_u
                lda #'H
                jsr emit_a

z_at_xy:        rts


; ## BACKSLASH ( -- ) "Ignore rest of line"
; ## "\"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/bs"""
xt_backslash:
                lda ciblen
                sta toin
                lda ciblen+1
                sta toin+1

z_backslash:    rts


; ## BASE ( -- addr ) "Push address of radix base to stack"
; ## "base"  auto  ANS core
        ; """https://forth-standard.org/standard/core/BASE
        ; The ANS Forth standard sees the base up to 36, so we can cheat and
        ; ingore the MSB
        ; """
xt_base:
                dex
                dex
                lda #<base
                sta 0,x         ; LSB
                stz 1,x         ; MSB is always 0

z_base:         rts


; ## BEGIN ( -- addr ) "Mark entry point for loop"
; ## "begin"  auto  ANS core
        ; """https://forth-standard.org/standard/core/BEGIN
        ;
        ; This is just an immediate version of here which could just
        ; as well be coded in Forth as
        ;       : BEGIN HERE ; IMMEDIATE COMPILE-ONLY
        ; Since this is a compiling word, we don't care that much about
        ; about speed
        ; """
.scope
xt_begin:
                jsr xt_here
z_begin:        rts
.scend


; ## BELL ( -- ) "Emit ASCII BELL"
; ## "bell"  tested  Tali Forth
xt_bell:
                lda #7          ; ASCII value for BELl
                jsr emit_a

z_bell:         rts


; ## BL ( -- c ) "Push ASCII value of SPACE to stack"
; ## "bl"  auto  ANS core
        ; """https://forth-standard.org/standard/core/BL"""
.scope
xt_bl:
                dex
                dex
                lda #AscSP
                sta 0,x
                stz 1,x

z_bl:           rts
.scend

; ## BLK ( -- addr ) "Push address of block being interpreted"
; ## "block"  auto  ANS block
        ; """https://forth-standard.org/standard/block/BLK"""
xt_blk:
                ; BLK is at UP + blk_offset
                dex
                dex
                clc
                lda up
                adc #blk_offset ; Add offset
                sta 0,x
                lda up+1
                adc #0          ; Adding carry
                sta 1,x

z_blk:          rts


; ## BLKBUFFER ( -- addr ) "Push address of block buffer"
; ## "blkbuffer"  auto  Tali block
xt_blkbuffer:
                ; blkbuffer address is at UP + blkbuffer_offset.
                ; Unlike some of the other user variables, we actually
                ; want to push the address stored here, which will
                ; point to somewhere outside of the user variables.
                dex
                dex
                ; Put the address on the stack.
                ldy #blkbuffer_offset
                lda (up),y
                sta 0,x
                iny             ; Move along to the next byte
                lda (up),y
                sta 1,x

z_blkbuffer:    rts


; ## BLOCK ( u -- a-addr ) "Fetch a block into a buffer"
; ## "block"  auto  ANS block
        ; """https://forth-standard.org/standard/block/BLOCK"""
.scope
xt_block:

                ; See if the block requested is the same as the one we
                ; currently have in the buffer. Check the LSB.
                ldy #buffblocknum_offset
                lda (up),y
                cmp 0,x
                bne _not_in_buffer

                ; Check the MSB.
                iny
                lda (up),y
                cmp 1,x
                bne _not_in_buffer

                ; The block is in the buffer. See if the buffer is in use.
                ldy #buffstatus_offset
                lda (up),y
                and #1          ; Check the in-use flag (bit 0)
                bne _done       ; It's already in the buffer and in use.
                                ; _done will replace the block# with the
                                ; buffer address.
_not_in_buffer:
                ; Check the buffer status
                ldy #buffstatus_offset
                lda (up),y      ; Only bits 0 and 1 are used, so only
                cmp #3          ; LSB is needed.
                bne _buffer_available ; Unused or not dirty = available

                ; We need to save the block.
                jsr xt_blkbuffer
                jsr xt_buffblocknum
                jsr xt_fetch
                jsr xt_block_write

_buffer_available:
                ; Save the block number.
                ldy #buffblocknum_offset
                lda 0,x
                sta (up),y
                iny
                lda 1,x
                sta (up),y

                ; Get the requested block.
                jsr xt_blkbuffer
                jsr xt_swap
                jsr xt_block_read

                ; Mark the buffer as clean and in-use.
                lda #1
                ldy #buffstatus_offset
                sta (up),y

                ; Make room on the stack for the return address.
                dex
                dex

_done:
                ; It's in the buffer. Return the buffer address.
                ldy #blkbuffer_offset
                lda (up),y
                sta 0,x
                iny
                lda (up),y
                sta 1,x

z_block:        rts
.scend


; ## BLOCK_RAMDRIVE_INIT ( u -- ) "Create a ramdrive for blocks"
; ## "block-ramdrive-init"  auto  Tali block
        ; """Create a RAM drive, with the given number of
        ; blocks, in the dictionary along with setting up the block words to
        ; use it.  The read/write routines do not provide bounds checking.
        ; Expected use: `4 block-ramdrive-init` ( to create blocks 0-3 )
        ; """
.scope
xt_block_ramdrive_init:
                jsr underflow_1

                ; Store the string to run here as a string literal.
                ; See SLITERAL for the format information. This way, we
                ; don't have the words defined below in the Dictionary until
                ; we really use them.
                jmp _after_ramdrive_code

_ramdrive_code:
        .byte "base @ swap decimal"
        .byte " 1024 *" ; ( Calculate how many bytes are needed for numblocks blocks )
        .byte " dup"    ; ( Save a copy for formatting it at the end )
        .byte " buffer: ramdrive" ; ( Create ramdrive )
        ; ( These routines just copy between the buffer and the ramdrive blocks )
        .byte " : block-read-ramdrive"  ; ( addr u -- )
        .byte " ramdrive swap 1024 * + swap 1024 move ;"
        .byte " : block-write-ramdrive" ; ( addr u -- )
        .byte " ramdrive swap 1024 * + 1024 move ;"
        .byte " ' block-read-ramdrive block-read-vector !" ; ( Replace I/O vectors )
        .byte " ' block-write-ramdrive block-write-vector !"
        .byte " ramdrive swap blank base !"

_after_ramdrive_code:
                jsr sliteral_runtime

.word _ramdrive_code, _after_ramdrive_code-_ramdrive_code

                ; The address and length of the ramdrive code is now on the
                ; stack. Call EVALUATE to run it.
                jsr xt_evaluate

z_block_ramdrive_init:
                rts
.scend


; ## BLOCK_READ ( addr u -- ) "Read a block from storage (deferred word)"
; ## "block-read"  auto  Tali block
        ; """BLOCK-READ is a vectored word that the user needs to override
        ; with their own version to read a block from storage.
        ; The stack parameters are ( buffer_address block# -- ).
        ; """
xt_block_read:
                ; Execute the BLOCK-READ-VECTOR
                ldy #blockread_offset
                lda (up),y
                sta tmp1
                iny
                lda (up),y
                sta tmp1+1

                jmp (tmp1)

z_block_read:   ; No RTS needed


; ## BLOCK_READ_VECTOR ( -- addr ) "Address of the block-read vector"
; ## "block-read-vector"  auto  Tali block
        ; """BLOCK-READ is a vectored word that the user needs to override
        ; with their own version to read a block from storage.
        ; This word gives the address of the vector so it can be replaced.
        ; """
xt_block_read_vector:
                ; Get the BLOCK-READ-VECTOR address
                dex
                dex
                clc
                lda up
                adc #blockread_offset
                sta 0,x
                lda up+1
                adc #0          ; Add carry
                sta 1,x

z_block_read_vector:
                rts


; This is the default error message the vectored words BLOCK-READ and
; BLOCK-WRITE start with. This word is not included in the dictionary.
xt_block_word_error:
                lda #err_blockwords
                jmp error       ; no RTS needed
z_block_word_error:

; ## BLOCK_WRITE ( addr u -- ) "Write a block to storage (deferred word)"
; ## "block-write"  auto  Tali block
        ; """BLOCK-WRITE is a vectored word that the user needs to override
        ; with their own version to write a block to storage.
        ; The stack parameters are ( buffer_address block# -- ).
        ; """
xt_block_write:
                ; Execute the BLOCK-READ-VECTOR
                ldy #blockwrite_offset
                lda (up),y
                sta tmp1
                iny
                lda (up),y
                sta tmp1+1
                jmp (tmp1)

z_block_write:  ; No RTS needed


; ## BLOCK_WRITE_VECTOR ( -- addr ) "Address of the block-write vector"
; ## "block-write-vector"  auto  Tali block
        ; """BLOCK-WRITE is a vectored word that the user needs to override
        ; with their own version to write a block to storage.
        ; This word gives the address of the vector so it can be replaced.
        ; """
xt_block_write_vector:
                ; Get the BLOCK-WRITE-VECTOR address
                dex
                dex
                clc
                lda up
                adc #blockwrite_offset
                sta 0,x
                lda up+1
                adc #0          ; Add carry
                sta 1,x

z_block_write_vector:
                rts


; ## BOUNDS ( addr u -- addr+u addr ) "Prepare address for looping"
; ## "bounds"  auto  Gforth
        ; """http://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Memory-Blocks.html
        ; Given a string, return the correct Data Stack parameters for
        ; a DO/LOOP loop over its characters. This is realized as
        ; OVER + SWAP in Forth, but we do it a lot faster in assembler
        ; """
xt_bounds:
                jsr underflow_2

                clc
                lda 0,x                 ; LSB u
                ldy 2,x                 ; LSB addr
                adc 2,x
                sta 2,x                 ; LSB addr+u
                sty 0,x

                lda 1,x                 ; MSB u
                ldy 3,x                 ; MSB addr
                adc 3,x
                sta 3,x                 ; MSB addr+u
                sty 1,x

z_bounds:       rts


; ## BRACKET_CHAR ( "c" -- ) "Compile character"
; ## "[char]"  auto  ANS core
        ; """https://forth-standard.org/standard/core/BracketCHAR
        ; Compile the ASCII value of a character as a literal. This is an
        ; immediate, compile-only word.
        ;
        ; A definition given in
        ; http://forth-standard.org/standard/implement is
        ; : [CHAR]  CHAR POSTPONE LITERAL ; IMMEDIATE
        ; """
xt_bracket_char:
                jsr xt_char
                jsr xt_literal
z_bracket_char: rts


; ## BRACKET_TICK ( -- ) "Store xt of following word during compilation"
; ## "[']"  auto  ANS core
        ; """https://forth-standard.org/standard/core/BracketTick"""
xt_bracket_tick:
                jsr xt_tick
                jsr xt_literal
z_bracket_tick: rts


; ## BUFFBLOCKNUM ( -- addr ) "Push address of variable holding block in buffer"
; ## "buffblocknum"  auto  Tali block
xt_buffblocknum:
                ; BUFFBLOCKNUM is at UP + buffblocknum_offset
                dex
                dex
                clc
                lda up
                adc #buffblocknum_offset        ; Add offset
                sta 0,x
                lda up+1
                adc #0                          ; Adding carry
                sta 1,x

z_buffblocknum: rts


; ## BUFFER ( u -- a-addr ) "Get a buffer for a block"
; ## "buffer"  auto  ANS block
        ; """https://forth-standard.org/standard/block/BUFFER"""
.scope
xt_buffer:
                ; Check the buffer status
                ldy #buffstatus_offset
                lda (up),y      ; Only bits 0 and 1 are used, so only
                cmp #3          ; LSB is needed.
                bne _buffer_available ; Unused or not dirty = available

                ; We need to save the block.
                jsr xt_blkbuffer
                jsr xt_buffblocknum
                jsr xt_fetch
                jsr xt_block_write

_buffer_available:
                ; Save the block number.
                ldy #buffblocknum_offset
                lda 0,x
                sta (up),y
                iny
                lda 1,x
                sta (up),y

                ; Mark the buffer as clean and in-use.
                lda #1
                ldy #buffstatus_offset
                sta (up),y

_done:
                ; Return the buffer address.
                ldy #blkbuffer_offset
                lda (up),y
                sta 0,x
                iny
                lda (up),y
                sta 1,x

z_buffer:       rts
.scend


; ## BUFFER_COLON ( u "<name>" -- ; -- addr ) "Create an uninitialized buffer"
; ## "buffer:"  auto  ANS core ext
                ; """https://forth-standard.org/standard/core/BUFFERColon
                ; Create a buffer of size u that puts its address on the stack
                ; when its name is used.
                ; """
xt_buffer_colon:
                jsr xt_create
                jsr xt_allot
z_buffer_colon: rts


; ## BUFFSTATUS ( -- addr ) "Push address of variable holding buffer status"
; ## "buffstatus"  auto  Tali block
xt_buffstatus:
                ; BUFFSTATUS is at UP + buffstatus_offset
                dex
                dex
                clc
                lda up
                adc #buffstatus_offset  ; Add offset
                sta 0,x
                lda up+1
                adc #0                  ; Adding carry
                sta 1,x

z_buffstatus:   rts


; ## BYE ( -- ) "Break"
; ## "bye"  tested  ANS tools ext
        ; """https://forth-standard.org/standard/tools/BYE"""
.scope
xt_bye:
                ;brk
                jmp platform_bye
z_bye:          ;rts             ; never reached
.scend


; ## C_COMMA ( c -- ) "Store one byte/char in the Dictionary"
; ## "c,"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CComma"""
.scope
xt_c_comma:
                jsr underflow_1

                lda 0,x
                jsr cmpl_a

                inx
                inx

z_c_comma:      rts
.scend


; ## C_FETCH ( addr -- c ) "Get a character/byte from given address"
; ## "c@"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CFetch"""
xt_c_fetch:
                jsr underflow_1

                lda (0,x)
                sta 0,x
                stz 1,x         ; Ignore LSB

z_c_fetch:      rts


; ## C_STORE ( c addr -- ) "Store character at address given"
; ## "c!"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CStore"""
xt_c_store:
                jsr underflow_2

                lda 2,x
                sta (0,x)

                inx
                inx
                inx
                inx

z_c_store:      rts


; ## CASE (C: -- 0) ( -- ) "Conditional flow control"
; ## "case"  auto  ANS core ext
        ; """http://forth-standard.org/standard/core/CASE
        ;
        ; This is a dummy header, CASE shares the actual code with ZERO.
        ; """


; ## CELL_PLUS ( u -- u ) "Add cell size in bytes"
; ## "cell+"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CELLPlus
        ; Add the number of bytes ("address units") that one cell needs.
        ; Since this is an 8 bit machine with 16 bit cells, we add two bytes.
        ; """
.scope
xt_cell_plus:
                jsr underflow_1

                inc 0,x
                bne +
                inc 1,x
*
                inc 0,x
                bne _done
                inc 1,x
_done:
z_cell_plus:    rts
.scend


; ## CELLS ( u -- u ) "Convert cells to size in bytes"
; ## "cells"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CELLS
        ;
        ; Dummy entry for the CELLS word, the code is the same as for
        ; 2*, which is where the header directs us to
        ; """


; ## CHAR ( "c" -- u ) "Convert character to ASCII value"
; ## "char"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CHAR"""
.scope
xt_char:
                ; get character from string, returns ( addr u )
                jsr xt_parse_name

                ; if we got back a zero, we have a problem
                lda 0,x
                ora 1,x
                bne _not_empty

                lda #err_noname
                jmp error

_not_empty:
                inx             ; drop number of characters, leave addr
                inx
                lda (0,x)       ; get character (equivalent to C@)
                sta 0,x
                stz 1,x         ; MSB is always zero

z_char:         rts
.scend


; ## CHAR_PLUS ( addr -- addr+1 ) "Add the size of a character unit to address"
; ## "char+"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CHARPlus
        ;
        ; This is a dummy entry, the code is shared with ONE_PLUS
        ; """


; ## CHARS ( n -- n ) "Number of bytes that n chars need"
; ## "chars"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CHARS
        ; Return how many address units n chars are. Since this is an 8 bit
        ; machine, this does absolutely nothing and is included for
        ; compatibility with other Forth versions
        ; """
.scope
xt_chars:
                ; Checking for underflow seems a bit stupid because this
                ; routine does nothing on this machine. However, the user
                ; should be warned that there is something wrong with the
                ; code if this occurs.
                jsr underflow_1

z_chars:        rts
.scend

; ## CLEAVE ( addr u -- addr2 u2 addr1 u1 ) "Split off word from string"
; ## "cleave"  auto  Tali Forth

        ; """Given a range of memory with words delimited by whitespace,return
        ; the first word at the top of the stack and the rest of the word
        ; following it.
        ;
        ; Example:
        ; s" w1 w2 w3" cleave  -> "w2 w3" "w1"
        ; s" w1" cleave        -> "" "w1"
        ;
        ; Since it will be used in loops a lot, we want it to work in pure
        ; assembler and be as fast as we can make it. Calls PARSE-NAME so we
        ; strip leading delimiters.
        ; """
.scope
xt_cleave:
                jsr underflow_2

                ; We arrive here with ( addr u ). We need to strip any leading
                ; spaces by hand: PARSE-NAME does do that, but it doesn't
                ; remember how many spaces were stripped. This means we can't
                ; calculate the length of the remainder. Fortunately, Tali
                ; Forth has just the word we need for this:
                jsr xt_minus_leading    ; -LEADING ( addr u )

                ; The main part we can turn over to PARSE-NAME, except that we
                ; have a string ( addr u ) and not stuff in the input buffer.
                ; We get around this by cheating: We place ( addr u ) in the
                ; input buffer and then call PARSE-NAME.
                jsr xt_input_to_r       ; save old imput state

                lda 0,x         ; u is new ciblen
                sta ciblen
                lda 1,x
                sta ciblen+1

                lda 2,x         ; addr is new cib
                sta cib
                lda 3,x
                sta cib+1

                stz toin        ; >IN pointer is zero
                stz toin+1

                ; PARSE-NAME gives us back the substring of the first word
                jsr xt_parse_name       ; ( addr u addr-s u-s )

                ; If we were given an empty string, then we're done. It's the
                ; resposibility of the user to catch this as a sign to end the
                ; any loop
                lda 0,x
                ora 1,x
                beq _done

                ; Now we have to adjust the original string
                lda 4,x         ; LSB of original u
                sec
                sbc 0,x
                sta 4,x

                lda 5,x         ; MSB of original u
                sbc 1,x
                sta 5,x

                lda 6,x         ; LSB of original addr
                clc
                adc 0,x
                sta 6,x

                lda 7,x         ; MSB of original addr
                adc 1,x
                sta 7,x

                ; There is one small problem: PARSE-NAME will probably have
                ; left the string with the rest of the words with leading
                ; delimiters. We use our magic -LEADING again
                jsr xt_two_swap         ; ( addr-s u-s addr u )
                jsr xt_minus_leading
                jsr xt_two_swap         ; ( addr u addr-s u-s )
_done:
                ; Restore input
                jsr xt_r_to_input

z_cleave:       rts
.scend


; ## CMOVE ( addr1 addr2 u -- ) "Copy bytes going from low to high"
; ## "cmove"  auto  ANS string
        ; """https://forth-standard.org/standard/string/CMOVE
        ; Copy u bytes from addr1 to addr2, going low to high (addr2 is
        ; larger than addr1). Based on code in Leventhal, Lance A.
        ; "6502 Assembly Language Routines", p. 201, where it is called
        ; "move left".
        ;
        ; There are no official tests for this word.
        ; """
.scope
xt_cmove:
                jsr underflow_3

                ; move destination address to where we can work with it
                lda 2,x
                sta tmp2        ; use tmp2 because easier to remember
                lda 3,x
                sta tmp2+1

                ; move source address to where we can work with it
                lda 4,x
                sta tmp1        ; use tmp1 because easier to remember
                lda 5,x
                sta tmp1+1

                ldy #0
                lda 1,x         ; number of whole pages to move
                beq _dopartial

_page:
                lda (tmp1),y
                sta (tmp2),y
                iny
                bne _page

                inc tmp1+1
                inc tmp2+1
                dec 1,x
                bne _page

_dopartial:
                lda 0,x         ; length of last page
                beq _done

_partial:
                lda (tmp1),y
                sta (tmp2),y
                iny

                dec 0,x
                bne _partial

_done:          ; clear the stack
                txa
                clc
                adc #6
                tax

z_cmove:        rts
.scend


; ## CMOVE_UP ( add1 add2 u -- ) "Copy bytes from high to low"
; ## "cmove>"  auto  ANS string
        ; """https://forth-standard.org/standard/string/CMOVEtop
        ; Based on code in Leventhal, Lance A. "6502 Assembly Language
        ; Routines", p. 201, where it is called "move right".
        ;
        ; There are no official tests for this word.
        ; """
.scope
xt_cmove_up:
                jsr underflow_3

                ; Move destination address to where we can work with it
                lda 2,x
                sta tmp2        ; use tmp2 because easier to remember
                lda 3,x
                clc
                adc 1,x
                sta tmp2+1      ; point to last page of destination

                ; Move source address to where we can work with it
                lda 4,x
                sta tmp1        ; use tmp1 because easier to remember
                lda 5,x
                clc
                adc 1,x
                sta tmp1+1      ; point to last page of source
                inc 1,x         ; allows us to use bne with dec 1,x below

                ; Move the last partial page first
                ldy 0,x         ; length of last page
                beq _nopartial

_outerloop:
                dey
                beq _finishpage

_innerloop:
                lda (tmp1),y
                sta (tmp2),y
                dey
                bne _innerloop

_finishpage:
                lda (tmp1)      ; handle y = 0 separately
                sta (tmp2)

_nopartial:
                dec tmp1+1      ; back up to previous pages
                dec tmp2+1
                dec 1,x
                bne _outerloop
_done:
                ; clear up the stack and leave
                txa
                clc
                adc #6
                tax

z_cmove_up:     rts
.scend


; ## COLON ( "name" -- ) "Start compilation of a new word"
; ## ":"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Colon
        ;
        ; Use the CREATE routine and fill in the rest by hand.
        ; """
.scope
xt_colon:
                ; If we're already in the compile state, complain
                ; and quit
                lda state
                ora state+1
                beq +

                lda #err_state
                jmp error
*
                ; switch to compile state
                dec state
                dec state+1

                ; Set bit 6 in status to tell ";" and RECURSE this is a normal
                ; word
                lda #%01000000
                tsb status

                ; CREATE is going to change the DP to point to the new word's
                ; header. While this is fine for (say) variables, it would mean
                ; that FIND-NAME etc would find a half-finished word when
                ; looking in the Dictionary. To prevent this, we save the old
                ; version of DP and restore it later. The new DP is placed in
                ; the variable WORKWORD until we're finished with a SEMICOLON.
                jsr current_to_dp
                lda dp+1            ; CREATE uses a lot of variables
                pha
                lda dp
                pha

                ; Tell create not to print warning for duplicate name.
                lda #%10000000
                tsb status

                jsr xt_create

                ; Get the nt (not the xt!) of the new word as described above.
                ; Only COLON, SEMICOLON and RECURSE get to access WORKWORD
                jsr current_to_dp   ; This might be able to be omitted
                lda dp
                sta workword
                lda dp+1
                sta workword+1

                ; Restore original DP
                pla
                sta dp
                pla
                sta dp+1
                jsr dp_to_current

                ; CREATE includes a subroutine jump to DOVAR by default. We
                ; back up three bytes and overwrite that.
                lda cp
                sec
                sbc #3
                sta cp
                bcs _done
                dec cp+1
_done:
z_colon:        rts
.scend

; ## COLON_NONAME ( -- ) "Start compilation of a new word""
; ## ":NONAME"  auto  ANS core
        ; """https://forth-standard.org/standard/core/ColonNONAME
        ; Compile a word with no nt.  ";" will put its xt on the stack.
        ; """
.scope
xt_colon_noname:
                ; If we're already in the compile state, complain
                ; and quit
                lda state
                ora state+1
                beq +

                lda #err_state
                jmp error
*
                ; switch to compile state
                dec state
                dec state+1

                ; Clear bit 6 in status to tell ";" and RECURSE this is
                ; a :NONAME word.
                lda #%01000000
                trb status

                ; Put cp (the xt for this word) in WORKWORD. The flag above
                ; lets both ";" and RECURSE know that is is an xt instead of an
                ; nt and they will modify their behavior.
                lda cp
                sta workword
                lda cp+1
                sta workword+1
_done:
z_colon_noname:        rts
.scend


; ## COMMA ( n -- ) "Allot and store one cell in memory"
; ## ","  auto  ANS core
        ; """https://forth-standard.org/standard/core/Comma
        ; Store TOS at current place in memory.
        ;
        ; Since this an eight-bit machine, we can ignore all alignment issues.
        ; """
.scope
xt_comma:
                jsr underflow_1

                lda 0,x
                sta (cp)

                inc cp
                bne +
                inc cp+1
*
                lda 1,x
                sta (cp)

                inc cp
                bne _done
                inc cp+1
_done:
                inx
                inx

z_comma:        rts
.scend


; ## COMPARE ( addr1 u1 addr2 u2 -- -1 | 0 | 1) "Compare two strings"
; ## "compare"   auto  ANS string
        ; """https://forth-standard.org/standard/string/COMPARE
        ; Compare string1 (denoted by addr1 u1) to string2 (denoted by
        ; addr2 u2).  Return -1 if string1 < string2, 0 if string1 = string2
        ; and 1 if string1 > string2 (ASCIIbetical comparison).  A string
        ; that entirely matches the beginning of the other string, but is
        ; shorter, is considered less than the longer string.
        ; """
.scope
xt_compare:
                jsr underflow_4

                ; Load the two string addresses into tmp1 and tmp2.
                lda 2,x
                sta tmp2
                lda 3,x
                sta tmp2+1
                lda 6,x
                sta tmp1
                lda 7,x
                sta tmp1+1
                ; The counts will be used in-place on the stack.

_compare_loop:
                ; Check to see if we are out of letters.

                ; Check string1
                lda 4,x
                ora 5,x
                beq _str1_done

                ; Check string2
                lda 0,x
                ora 1,x
                beq _greater    ; Str2 empty first

_check_letter:
                ; Both strings have at least one letter left.
                ; Check the letters against each other.
                lda (tmp1)
                cmp (tmp2)
                bcc _less
                bne _greater
_next_letter:
                ; Move both tmp pointers and decrement the counts
                ; on the stack.
                ; Increment tmp1
                inc tmp1
                bne +
                inc tmp1+1
*
                ; Increment tmp2
                inc tmp2
                bne +
                inc tmp2+1
*
                ; Decrement count1 on the stack.
                lda 4,x
                bne +
                dec 5,x
*
                dec 4,x

                ; Decrement count2 on the stack.
                lda 0,x
                bne +
                dec 1,x
*
                dec 0,x

                ; Loop around and check again.
                bra _compare_loop

_str1_done:
                ; String 1 is out of letters. Check string 2.
                lda 0,x
                ora 1,x
                beq _equal      ; Both out of letters

                ; Falls into less (str1 is out but str2 has more)
_less:
                ; Return -1
                lda #$FF
                sta 6,x
                sta 7,x
                bra _done
_equal:
                ; Return 0
                stz 6,x
                stz 7,x
                bra _done
_greater:
                ; Return 1
                lda #1
                sta 6,x
                stz 7,x
                ; Falls into _done
_done:
                ; Remove all but the result from the stack.
                txa
                clc
                adc #6
                tax

z_compare:      rts
.scend


; ## COMPILE_COMMA ( xt -- ) "Compile xt"
; ## "compile,"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/COMPILEComma
        ; Compile the given xt in the current word definition. It is an
        ; error if we are not in the compile state. Because we are using
        ; subroutine threading, we can't use , (COMMA) to compile new words
        ; the traditional way. By default, native compiled is allowed, unless
        ; there is a NN (Never Native) flag associated. If not, we use the
        ; value NC_LIMIT (from definitions.tasm) to decide if the code
        ; is too large to be natively coded: If the size is larger than
        ; NC_LIMIT, we silently use subroutine coding. If the AN (Always
        ; Native) flag is set, the word is always natively compiled.
        ; """
.scope
xt_compile_comma:
                jsr underflow_1

                ; See if this is an Always Native (AN) word by checking the
                ; AN flag. We need nt for this. First, save a copy of xt to
                ; the Return Stack
                lda 1,x                 ; MSB
                pha
                lda 0,x
                pha                     ; LSB

                jsr xt_int_to_name      ; ( xt -- nt )

                ; See if this xt even has an nt.
                lda 0,x
                ora 1,x
                bne _check_nt

                ; No nt in dictionary. Just compile as a JSR.
                jmp _compile_as_jump

_check_nt:
                ; put nt away for safe keeping
                lda 0,x
                sta tmptos
                lda 1,x
                sta tmptos+1

                ; status byte is one further down
                inc 0,x
                bne +
                inc 1,x                 ; ( nt -- nt+1 )
*
                lda (0,x)
                sta tmp3                ; keep copy of status byte for NN
                and #AN                 ; mask all but Always Native (AN) bit
                beq _compile_check

                ; We're natively compiling no matter what. Get length and
                ; compile in code. Get the original nt back
                lda tmptos
                sta 0,x
                lda tmptos+1
                sta 1,x

                jsr xt_wordsize         ; ( nt -- u )

                bra _compile_as_code

_compile_check:
                ; See if Native Compile is even alowed by checking the NN
                ; flag
                lda tmp3
                and #NN
                beq _check_size_limit

                jmp _compile_as_jump    ; too far for BRA

_check_size_limit:
                ; Native compile is a legal option, but we need to see what
                ; limit the user set for size (in nc_limit)
                lda tmptos
                sta 0,x
                lda tmptos+1
                sta 1,x

                jsr xt_wordsize         ; ( nt -- u )

                ; Check the wordsize MSB against the user-defined limit.
                lda 1,x
                cmp nc_limit+1
                bcc _compile_as_code    ; user-defined limit MSB
                bne _jumpto_compile_as_jump

                ; Check the wordsize LSB against the user-defined limit.
                lda 0,x
                cmp nc_limit            ; user-defined limit LSB
                bcc _compile_as_code    ; Allow native compiling for less
                beq _compile_as_code    ; than or equal to the limit.

_jumpto_compile_as_jump:
                ; If the wordsize is greater than the user-defined
                ; limit, it will be compiled as a subroutine jump.
                jmp _compile_as_jump    ; too far for BRA

_compile_as_code:
                ; We arrive here with the length of the word's code TOS and
                ; xt on top of the Return Stack. MOVE will need ( xt cp u )
                ; on the data stack
                dex
                dex                     ; ( -- u ? )
                dex
                dex                     ; ( -- u ? ? )

                lda 4,x
                sta 0,x                 ; LSB of u
                lda 5,x
                sta 1,x                 ; ( -- u ? u )

                pla
                sta 4,x                 ; LSB of xt
                pla
                sta 5,x                 ; ( -- xt ? u )

                lda cp                  ; LSB of cp
                sta 2,x
                lda cp+1
                sta 3,x                 ; ( -- xt cp u )

                ; --- SPECIAL CASE 1: PREVENT RETURN STACK THRASHINIG ---

                ; Native compiling allows us to strip the stack antics off
                ; a number of words that use the Return Stack such as >R, R>,
                ; 2>R and 2R> (but not 2R@ in this version). We compare the
                ; xt with the contents of the table
                ldy #0

_strip_loop:
                lda _strip_table,y      ; LSB of first word
                cmp 4,x                 ; LSB of xt
                bne _next_entry

                ; LSB is the same, test MSB
                lda _strip_table+1,y
                cmp 5,x
                beq _found_entry

                ; MSB is not equal. Pretend though that we've come from LSB
                ; so we can use the next step for both cases
_next_entry:
                ; Not a word that needs stripping, so check next entry in table
                ; Let's see if we're done with the table (marked by zero entry)
                lda _strip_table,y      ; pointing to LSB
                ora _strip_table+1,y    ; get MSB
                beq _underflow_strip    ; table done, let's get out of here

                iny
                iny
                bra _strip_loop
_found_entry:
                ; This word is one of the ones that needs to have its size
                ; adjusted during native compile. We find the values in the
                ; next table with the same index, which is Y. However, Y is
                ; pointing to the MSB, so we need to go back to the LSB and
                ; halve the index before we can use it.
                tya
                lsr
                tay

                ; Get the adjustment out of the size table. We were clever
                ; enough to make sure the cut on both ends of the code is
                ; is the same size.
                lda _strip_size,y
                sta tmptos              ; save a copy

                ; Adjust xt: Start later
                clc
                adc 4,x
                sta 4,x
                bcc+
                inc 5,x                 ; we just care about the carry
*

                ; Adjust u: Quit earlier. Since we cut off the top and the
                ; bottom of the code, we have to double the value
                asl tmptos

                sec
                lda 0,x
                sbc tmptos
                sta 0,x
                bcs +
                dec 1,x                 ; we just care about the borrow
*
                ; drop through to underflow check stripping

_underflow_strip:
                ; --- SPECIAL CASE 2: REMOVE UNDERFLOW CHECKING ---

                ; The user can choose to remove the unterflow testing in those
                ; words that have the UF flag. This shortens the word by
                ; 3 bytes if there is no underflow.

                ; See if the user wants underflow stripping turned on
                lda uf_strip
                ora uf_strip+1
                beq _specials_done

                ; See if this word even contains underflow checking
                lda tmp3
                and #UF
                beq _specials_done

                ; If we arrived here, underflow has to go. It's always 3 bytes
                ; long. Note hat PICK is a special case.

                ; Adjust xt: Start later
                clc
                lda 4,x
                adc #3
                sta 4,x
                bcc +
                inc 5,x                  ; we just care about the carry
*
                ; Adjust u: End earlier
                sec
                lda 0,x
                sbc #3
                sta 0,x
                bcs +
                dec 1,x                  ; we just care about the borrow
*

                ; --- END OF SPECIAL CASES ---
_specials_done:
                ; Store size of area to be copied for calculation of
                ; new CP. We have to do this after all of the special cases
                ; because they might change the size
                lda 1,x                 ; MSB
                pha
                lda 0,x                 ; LSB
                pha

                ; Enough of this, let's move those bytes already! We have
                ; ( xt cp u ) on the stack at this point
                jsr xt_move

                ; Update CP
                clc
                pla                     ; LSB
                adc cp
                sta cp

                pla                     ; MSB
                adc cp+1
                sta cp+1

                bra _done

_strip_table:
               ; List of words we strip the Return Stack antics from
               ; during native compile, zero terminated. The index here
               ; must be the same as for the sizes
                .word xt_r_from, xt_r_fetch, xt_to_r    ; R>, R@, >R
                .word xt_two_to_r, xt_two_r_from, 0000  ; 2>R, 2R>, EOL

_strip_size:
                ; List of bytes to be stripped from the words that get their
                ; Return Stack antics removed during native compile. Index must
                ; be the same as for the xts. Zero terminated.
                .byte 4, 4, 4, 6, 6, 0          ; R>, R@, >R, 2>R, 2R>, EOL

_compile_as_jump:
                ; Compile xt as a subroutine jump
                lda #$20
                sta (cp)

                ldy #1
                pla             ; LSB
                sta (cp),y
                iny
                pla             ; MSB
                sta (cp),y

                ; allot space we just used
                lda #3
                clc
                adc cp
                sta cp
                bcc +
                inc cp+1
*
                inx             ; drop xt
                inx
_done:
z_compile_comma:
                rts
.scend


; ## COMPILE_ONLY ( -- ) "Mark most recent word as COMPILE-ONLY"
; ## "compile-only"  tested  Tali Forth
        ; """Set the Compile Only flag (CO) of the most recently defined
        ; word.
        ;
        ; The alternative way to do this is to define a word
        ; ?COMPILE that makes sure  we're in compile mode
        ; """
.scope
xt_compile_only:
                jsr current_to_dp
                ldy #1          ; offset for status byte
                lda (dp),y
                ora #CO        ; make sure bit 7 is set
                sta (dp),y

z_compile_only: rts
.scend


; ## CONSTANT ( n "name" -- ) "Define a constant"
; ## "constant"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CONSTANT
        ;
        ; Forth equivalent is  CREATE , DOES> @  but we do
        ; more in assembler and let CREATE do the heavy lifting.
        ; See http://www.bradrodriguez.com/papers/moving3.htm for
        ; a primer on how this works in various Forths. This is the
        ; same code as VALUE in our case.
        ; """
xt_value:
xt_constant:
                jsr underflow_1

                jsr xt_create

            	; CREATE by default installs a subroutine jump to DOVAR,
                ; but we want DOCONST for constants. Go back two bytes and
                ; replace the subroutine jump target
                sec
                lda cp
                sbc #2
                sta tmp1
                lda cp+1
                sbc #0
                sta tmp1+1

                lda #<doconst           ; LSB of DOCONST
                sta (tmp1)
                ldy #1
                lda #>doconst           ; MSB of DOCONST
                sta (tmp1),y

                ; Now we save the constant number itself in the next cell
                jsr xt_comma            ; drop through to adjust_z

adjust_z:
                ; Now the length of the complete word (z_word) has increased by
                ; two. We need to update that number or else words such as SEE
                ; will ignore the PFA. We use this same routine for VARIABLE,
                ; VALUE and DEFER
                jsr xt_latestnt         ; gives us ( -- nt )

                ; z_word is six bytes further down
                lda 0,x
                sta tmp1
                lda 1,x
                sta tmp1+1

                ldy #6
                lda (tmp1),y
                clc
                adc #2
                sta (tmp1),y
                iny
                lda (tmp1),y
                adc #0                  ; only need carry
                sta (tmp1),y

                inx
                inx

z_value:
z_constant:     rts


; ## COUNT ( c-addr -- addr u ) "Convert character string to normal format"
; ## "count"  auto  ANS core
        ; """https://forth-standard.org/standard/core/COUNT
        ; Convert old-style character string to address-length pair. Note
        ; that the length of the string c-addr is stored in character length
        ; (8 bit), not cell length (16 bit). This is rarely used these days,
        ; though COUNT can also be used to step through a string character by
        ; character.
        ; """
xt_count:
                jsr underflow_1

                lda (0,x)       ; Get number of characters (255 max)
                tay

                ; move start address up by one
                inc 0,x         ; LSB
                bne +
                inc 1,x         ; MSB

                ; save number of characters to stack
*               tya
                dex
                dex
                sta 0,x         ; LSB
                stz 1,x         ; MSB, always zero

z_count:        rts


; ## CR ( -- ) "Print a line feed"
; ## "cr"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CR"""
xt_cr:
                lda #AscLF
                jsr emit_a
z_cr:           rts


; ## CREATE ( "name" -- ) "Create Dictionary entry for 'name'"
; ## "create"  auto  ANS core
        ; """https://forth-standard.org/standard/core/CREATE
        ;
        ; See the drawing in headers.asm for details on the header
        ; """
.scope
xt_create:
                ; get string
                jsr xt_parse_name       ; ( addr u )

                ; if we were given an empty string, we complain and quit
                lda 0,x
                ora 1,x
                bne _got_name

                lda #err_noname
                jmp error

_got_name:
                ; Enforce maximal length of string by overwriting the MSB of
                ; the length. There is a possible error here: If the string
                ; is exactly 255 chars long, then a lot of the following
                ; additions will fail because of wrapping
                stz 1,x

                ; Check to see if this name already exists.
                jsr xt_two_dup          ; ( addr u addr u )
                jsr xt_find_name        ; ( addr u flag ) (non-zero nt as flag)

                lda 0,x
                ora 1,x
                beq _new_name           ; We haven't seen this one before.

                ; This name already exists.  See if we are supposed to print
                ; the message for it.
                inx                     ; Drop flag (nt) from find-name.
                inx

                ; Check bit 7
                bit status
                bpl _redefined_name     ; Bit 7 is zero, so print the message.

                ; We aren't supposed to print the redefined message ourselves,
                ; but we should indicate that it is redefined (for ; to print
                ; later).
                lda #$80                ; Set bit 7 to indicate dup
                ora status
                sta status
                bra _process_name

_redefined_name:
                ; Print the message that the name is redefined.
                lda #str_redefined
                jsr print_string_no_lf

                jsr xt_two_dup           ; ( addr u addr u )
                jsr xt_type
                jsr xt_space

                bra _process_name

_new_name:
                inx                     ; Drop flag (0) from find-name.
                inx
                lda #$7F                ; Clear bit 0 of status to indicate new word.
                and status
                sta status

_process_name:
                lda 0,x
                sta tmp2                ; store length of string in tmp2

                ; remember the first free byte of memory as the start of
                ; the new word
                lda cp
                sta tmp1
                lda cp+1
                sta tmp1+1

                ; We need 8 bytes plus the length of the string for our new header.
                ; This is also the offset for the start of the code field (the
                ; xt_ label) so we need to remember it. Otherwise, we could
                ; just allot the space afterwards
                lda 0,x
                clc
                adc #8
                sta tmp3                ; total header length

                ; We need three more bytes for for the hardcoded code field
                ; area (CFA), the "payload" of the word which by default will
                ; be a subroutine jump to DOVAR
                clc
                adc #3

                ; We overwrite the length of the string returned by PARSE-NAME
                ; and then call ALLOT
                sta 0,x
                stz 1,x         ; max header size is 255 chars
                jsr xt_allot    ; ( addr )

                ; Get the CURRENT dictionary pointer.
                jsr current_to_dp

                ; Now we walk through the header with Y as the index, adding
                ; information byte-by-byte
                ldy #0

                ; HEADER BYTE 0: Length of string
                lda tmp2
                sta (tmp1),y

                ; HEADER BYTE 1: Status byte. By default, we set all new words
                ; to "never native", user will have to decide if they should
                ; be inlined
                lda #NN

                ; Also, words defined by CREATE are marked in the header has
                ; having a Code Field Area (CFA), which is a bit tricky for
                ; Subroutine Threaded Code (STC). We do this so >BODY works
                ; correctly with DOES> and CREATE. See the discussion at
                ; http://forum.6502.org/viewtopic.php?f=9&t=5182 for details
                ora #HC
                iny
                sta (tmp1),y
                iny

                ; HEADER BYTE 2,3: Next header. This is the current last word
                ; in the Dictionary
                lda dp
                sta (tmp1),y
                iny
                lda dp+1
                sta (tmp1),y
                iny

                ; Interlude: Make old CP new DP (new start of Dictionary)
                lda tmp1+1
                sta dp+1
                lda tmp1
                sta dp

                ; HEADER BYTE 4,5: Start of the code field ("xt_" of this word).
                ; This begins after the header so we take the length of the
                ; header, which we cleverly saved in tmp3, and use it as an
                ; offset to the address of the start of the word. We come here
                ; with tmp1 in A
                clc
                adc tmp3        ; add total header length
                sta (tmp1),y
                pha             ; we need this in the next step
                iny

                lda tmp1+1
                adc #0          ; only need the carry
                sta (tmp1),y
                iny

                ; HEADER BYTE 6,7: End of code ("z_" of this word). By default,
                ; we execute a jump to the DOVAR routine, so we need to move three
                ; bytes down, and then one more byte so that the z_ label points
                ; to the (still fictional) RTS instruction for correct compilation
                pla             ; LSB of "z_" address
                clc
                adc #3
                sta (tmp1),y

                dey             ; get the MSB of xt back
                lda (tmp1),y
                adc #0          ; only need the carry
                iny
                iny
                sta (tmp1),y
                iny

                ; HEADER BYTE 8: Start of name string. The address is TOS, the
                ; length in tmp2. We subtract 8 from the address so we can
                ; use the same loop index, which is already 8 byte ahead at
                ; this point
                lda 0,x
                sec
                sbc #8
                sta tmptos

                lda 1,x
                sbc #0          ; only need carry
                sta tmptos+1

_name_loop:
                lda (tmptos),y

                ; Make sure it goes into the dictionary in lower case.
                cmp #$5B         ; ASCII '[' (one past Z)
                bcs _store_name
                cmp #$41        ; ASCII 'A'
                bcc _store_name

                ; An uppercase letter has been located. Make it
                ; lowercase.
                clc
                adc #$20

                ; Fall into _store_name.

_store_name:
                sta (tmp1),y
                iny
                dec tmp2
                bne _name_loop

                ; After thename string comes the code field, starting at the
                ; current xt of this word, which is initially a jump to the
                ; subroutine to DOVAR. We code this jump by hand
                lda #$20        ; opcode of JSR
                sta (tmp1),y
                iny
                lda #<dovar
                sta (tmp1),y
                iny
                lda #>dovar
                sta (tmp1),y

                ; Update the CURRENT wordlist with the new DP.
                ; We do this down here because this routine uses Y.
                jsr dp_to_current

                ; And we're done. Restore stack
                inx
                inx

z_create:       rts
.scend


; ## D_MINUS ( d d -- d ) "Subtract two double-celled numbers"
; ## "d-"  auto  ANS double
        ; """https://forth-standard.org/standard/double/DMinus"""
.scope
xt_d_minus:
                jsr underflow_4 ; two double numbers

                sec

                lda 6,x         ; LSB of lower word
                sbc 2,x
                sta 6,x

                lda 7,x         ; MSB of lower word
                sbc 3,x
                sta 7,x

                lda 4,x         ; LSB of upper word
                sbc 0,x
                sta 4,x

                lda 5,x         ; MSB of upper word
                sbc 1,x
                sta 5,x

                inx
                inx
                inx
                inx

z_d_minus:      rts
.scend


; ## D_PLUS ( d d -- d ) "Add two double-celled numbers"
; ## "d+"  auto  ANS double
        ; """https://forth-standard.org/standard/double/DPlus"""
.scope
xt_d_plus:
                jsr underflow_4 ; two double numbers

                clc
                lda 2,x         ; LSB of lower word
                adc 6,x
                sta 6,x

                lda 3,x         ; MSB of lower word
                adc 7,x
                sta 7,x

                lda 0,x         ; LSB of upper word
                adc 4,x
                sta 4,x

                lda 1,x         ; MSB of upper word
                adc 5,x
                sta 5,x

                inx
                inx
                inx
                inx

z_d_plus:       rts
.scend


; ## D_TO_S ( d -- n ) "Convert a double number to single"
; ## "d>s"  auto  ANS double
        ; """https://forth-standard.org/standard/double/DtoS
        ; Though this is basically just DROP, we keep it
        ; separate so we can test for underflow
        ; """
.scope
xt_d_to_s:
                jsr underflow_2

                inx
                inx

z_d_to_s:       rts
.scend


; ## DABS ( d -- d ) "Return the absolute value of a double"
; ## "dabs"  auto  ANS double
        ; """https://forth-standard.org/standard/double/DABS"""
.scope
xt_dabs:
                jsr underflow_2 ; double number

                lda 1,x         ; MSB of high cell
                bpl _done       ; positive, we get off light

                ; negative, calculate 0 - d
                ldy #0
                sec

                tya
                sbc 2,x         ; LSB of low cell
                sta 2,x

                tya
                sbc 3,x         ; MSB of low cell
                sta 3,x

                tya
                sbc 0,x         ; LSB of high cell
                sta 0,x

                tya
                sbc 1,x         ; MSB of high cell
                sta 1,x
_done:
z_dabs:         rts
.scend


; ## DECIMAL ( -- ) "Change radix base to decimal"
; ## "decimal"  auto  ANS core
        ; """https://forth-standard.org/standard/core/DECIMAL"""
xt_decimal:
                lda #10
                sta base
                stz base+1              ; paranoid

z_decimal:      rts


; ## DEFER ( "name" -- ) "Create a placeholder for words by name"
; ## "defer"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/DEFER
        ; Reserve an name that can be linked to various xt by IS.
        ;
        ; The ANS reference implementation is
        ;       CREATE ['] ABORT , DOES> @ EXECUTE ;
        ; But we use this routine as a low-level word so things go faster
.scope
xt_defer:
                jsr xt_create

                ; CREATE by default installs a subroutine jump to DOVAR,
                ; but we actually want DODEFER this time. Go back two
                ; bytes and repace the subroutine jump target
                lda cp          ; LSB
                sec
                sbc #2
                sta tmp1

                lda cp+1        ; MSB
                sbc #0          ; we only care about the borrow
                sta tmp1+1

                ; Save the target address
                ldy #0
                lda #<dodefer   ; LSB
                sta (tmp1),y
                iny
                lda #>dodefer   ; MSB
                sta (tmp1),y


                ; DODEFER executes the next address it finds after
                ; its call. As default, we include the error
                ; "Defer not defined"
                lda #<defer_error
                sta (cp)
                inc cp
                bne +
                inc cp+1
*
                lda #>defer_error
                sta (cp)
                inc cp
                bne +
                inc cp+1
*
                jsr adjust_z    ; adjust header to correct length

z_defer:        rts
.scend


; ## DEFER_FETCH ( xt1 -- xt2 ) "Get the current XT for a deferred word"
; ## "defer@"  auto  ANS core ext
        ; """http://forth-standard.org/standard/core/DEFERFetch"""
.scope
xt_defer_fetch:
                ; No underflow checking as >BODY does it.
                jsr xt_to_body
                jsr xt_fetch
z_defer_fetch:  rts
.scend


; ## DEFER_STORE ( xt2 x1 -- ) "Set xt1 to execute xt2"
; ## "defer!"  auto  ANS core ext
        ; """http://forth-standard.org/standard/core/DEFERStore"""
.scope
xt_defer_store:
                ; No underflow checking as >BODY and ! do it.
                jsr xt_to_body
                jsr xt_store
z_defer_store:  rts
.scend


; ## DEFINITIONS ( -- ) "Make first wordlist in search order the current wordlist"
; ## "definitions" auto ANS search
xt_definitions:
                ldy #search_order_offset    ; Transfer byte variable
                lda (up),y                  ; SEARCH_ORDER[0] to
                ldy #current_offset         ; byte variable CURRENT.
                sta (up),y
z_definitions:  rts


; ## DEPTH ( -- u ) "Get number of cells (not bytes) used by stack"
; ## "depth"  auto  ANS core
        ; """https://forth-standard.org/standard/core/DEPTH"""
xt_depth:
                lda #dsp0
                stx tmpdsp
                sec
                sbc tmpdsp

                ; divide by two because each cell is two bytes
                lsr

                dex
                dex
                sta 0,x
                stz 1,x

z_depth:        rts


; ## DIGIT_QUESTION ( char -- u f | char f ) "Convert ASCII char to number"
; ## "digit?"  auto  Tali Forth
        ; """Inspired by the pForth instruction DIGIT, see
        ; https://github.com/philburk/pforth/blob/master/fth/numberio.fth
        ; Rewritten from DIGIT>NUMBER in Tali Forth. Note in contrast to
        ; pForth, we get the base (radix) ourselves instead of having the
        ; user provide it. There is no standard name for this routine, which
        ; itself is not ANS; we use DIGIT? following pForth and Gforth.
        ; """
.scope
xt_digit_question:
                jsr underflow_1

                ; one way or another, we're going to need room for the
                ; flag on the stack
                dex
                dex
                stz 0,x                 ; default flag is failure
                stz 1,x
                stz 3,x                 ; paranoid

                ; Check the character, now in the LSB of NOS. First, make
                ; sure we're not below the ASCII code for "0"
                lda 2,x
                cmp #'0
                bcc _done               ; failure flag already set

                ; Next, see if we are below "9", because that would make
                ; this a normal number
                cmp #'9+1               ; this is actually ":"
                bcc _checkbase

                ; Well, then let's see if this is the gap between "9" and "A"
                ; so we can treat the whole range as a number
                cmp #'A
                bcc _done               ; failure flag is already set

                ; probably a letter, so we make sure it is uppercase
                cmp #'a
                bcc _case_done          ; not lower case, too low
                cmp #'z+1
                bcs _case_done          ; not lower case, too high

                clc                     ; just right
                adc #$e0                ; offset to upper case (wraps)

_case_done:
                ; get rid of the gap between "9" and "A" so we can treat
                ; the whole range as one number
                sec
                sbc #7                  ; fall through to _checkbase

_checkbase:
                ; we have a number, now see if it falls inside the range
                ; provided by BASE
                sec
                sbc #'0                 ; this is also the conversion step
                cmp base
                bcs _done               ; already have false flag

                ; Found a legal number
                sta 2,x                 ; put number in NOS
                dec 0,x                 ; set success flag
                dec 1,x

_done:
z_digit_question:
                rts
.scend

; ## DISASM ( addr u -- ) "Disassemble a block of memory"
; ## "disasm"  tested  Tali Forth
        ; """Convert a segment of memory to assembler output. This
        ; word is vectored so people can add their own disassembler.
        ; Natively, this produces Simpler Assembly Notation (SAN)
        ; code, see the section on The Disassembler in the manual and
        ; the file disassembler.asm for more details.
        ; """
xt_disasm:
                jsr underflow_2

                jsr disassembler

z_disasm:       rts


; ## DNEGATE ( d -- d ) "Negate double cell number"
; ## "dnegate"  auto  ANS double
        ; """https://forth-standard.org/standard/double/DNEGATE"""
xt_dnegate:
                jsr underflow_2 ; double number

     		ldy #0
                sec

                tya
                sbc 2,x         ; LSB of low cell
                sta 2,x

                tya
                sbc 3,x         ; MSB of low cell
                sta 3,x

                tya
                sbc 0,x         ; LSB of high cell
                sta 0,x

                tya
                sbc 1,x         ; MSB of high cell
                sta 1,x

z_dnegate:      rts


; ## QUESTION_DO ( limit start -- )(R: -- limit start) "Conditional loop start"
; ## "?do"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/qDO"""
xt_question_do:
                ; ?DO shares most of its code with DO. We use the tmp1 flag
                ; to mark which is which
                lda #$ff                ; -1 is ?DO, jump to common code
                sta tmp1
                bra do_common           ; skip flag for DO

; ## DO ( limit start -- )(R: -- limit start)  "Start a loop"
; ## "do"  auto  ANS core
        ; """https://forth-standard.org/standard/core/DO
        ;
        ; Compile-time part of DO. Could be realized in Forth as
        ;       : DO POSTPONE (DO) HERE ; IMMEDIATE COMPILE-ONLY
        ; but we do it in assembler for speed. To work with LEAVE, we compile
        ; a routine that pushes the end address to the Return Stack at run
        ; time. This is based on a suggestion by Garth Wilson, see
        ; the Control Flow section of the manual for details.
        ;
        ; This may not be native compile. Don't check for a stack underflow
        ; """
.scope
xt_do:
                ; DO and ?DO share most of their code, use tmp1 as a flag.
                stz tmp1                ; 0 is DO, drop through to DO_COMMON
do_common:
                ; We push HERE to the Data Stack so LOOP/+LOOP knows where to
                ; compile the address we need to LDA at runtime
                dex
                dex
                lda cp
                sta 0,x                 ; LSB
                lda cp+1
                sta 1,x                 ; MSB   ( limit start here )

                ; now we compile six dummy bytes that LOOP/+LOOP will
                ; replace by the actual LDA/PHA instructions
                lda #5                  ; we don't really care about the value,
                tay                     ; so we use 5 to be tricky
_loop:
                sta (CP),y
                dey
                bpl _loop

                ; update CP
                inc             ; we used 5 as a dummy value, this is why
                clc
                adc CP
                sta CP
                bcc +
                inc CP+1
*
                ; compile the (?DO) portion of ?DO if appropriate
                lda tmp1
                beq _compile_do

                ; We came from ?DO, so compile its runtime first. We do
                ; this with a quick loop because we know it has to be
                ; Always Native anyway
                ldy #question_do_runtime_end-question_do_runtime
                phy             ; save counter to calculate new CP
*
                lda question_do_runtime,y
                sta (cp),y
                dey
                bpl -

                ; adjust CP
                pla             ; retrieve counter
                clc
                adc cp
                sta cp
                lda cp+1
                adc #0          ; only care about carry
                sta cp+1        ; fall through to _compile_do

_compile_do:
                ; compile runtime part of DO.
                ldy #do_runtime_end-do_runtime  ; counter
                phy             ; save counter to calculate new CP
*
                lda do_runtime,y
                sta (cp),y
                dey
                bpl -

                ; adjust CP
                pla             ; retrieve counter
                clc
                adc cp
                sta cp
                lda cp+1
                adc #0          ; only care about carry
                sta cp+1

                ; HERE, hardcoded for speed. We put it on the Data Stack
                ; where LOOP/+LOOP takes it from. Note this has nothing to
                ; do with the HERE we're saving for LEAVE
                dex
                dex
                lda CP          ; LSB
                sta 0,x
                lda CP+1        ; MSB
                sta 1,x
z_question_do:
z_do:           rts
.scend

do_runtime:
        ; """Runtime routine for DO loop. Note that ANS loops quit when the
        ; boundry of limit-1 and limit is reached, a different mechanism than
        ; the FIG Forth loop (you can see which version you have by running
        ; a loop with start and limit as the same value, for instance
        ; 0 0 DO -- these will walk through the number space). We use a
        ; "fudge factor" for the limit that makes the Overflow Flag trip when
        ; it is reached; see http://forum.6502.org/viewtopic.php?f=9&t=2026
        ; for further discussion of this. The source given there for
        ; this idea is Laxen & Perry F83. -- This routine is called (DO)
        ; in some Forths. Usually, we would define this as a separate word
        ; and compile it with COMPILE, and the Always Native (AN) flag.
        ; However, we can do it faster if we just copy the bytes
        ; of this routine with a simple loop in DO.
        ; """
                ; First step: create fudge factor (FUFA) by subtracting the
                ; limit from $8000, the number that will trip the overflow
                ; flag
                sec
                lda #0
                sbc 2,x         ; LSB of limit
                sta 2,x         ; save FUFA for later use

                lda #$80
                sbc 3,x         ; MSB of limit
                sta 3,x         ; save FUFA for later use
                pha             ; FUFA replaces limit on R stack
                lda 2,x         ; LSB of limit
                pha

                ; Second step: index is FUFA plus original index
                clc
                lda 0,x         ; LSB of original index
                adc 2,x         ; add LSB of FUFA
                sta 0,x
                lda 1,x         ; MSB of orginal index
                adc 3,x         ; add MSB of FUFA
                pha
                lda 0,x         ; LSB of index
                pha

                ; we've saved the FUFA on the NOS of the R stack, so we can
                ; use it later. Clean the Data Stack
                inx
                inx
                inx
                inx             ; no RTS because this is copied into code
do_runtime_end:

question_do_runtime:
.scope
        ; """This is called (?DO) in some Forths. See the explanation at
        ; do_runtime for the background on this design
        ; """
                ; see if TOS and NOS are equal. Change this to assembler
                ; for speed
                jsr xt_two_dup          ; ( n1 n2 n1 n2 )
                jsr xt_equal            ; ( -- n1 n2 f )

                lda 0,x
                ora 1,x
                beq _do_do

                ; We're equal, so dump everything and jump beyond the loop.
                ; But first, dump six entries off of the Data Stack
                txa
                clc
                adc #6
                tax

                ; Then abort the whole loop
                rts
_do_do:
                inx             ; clear flag from EQUAL off stack
                inx             ; no RTS because this is copied into code
question_do_runtime_end:
.scend


; ## DOES ( -- ) "Add payload when defining new words"
; ## "does>"  auto  ANS core
        ; """https://forth-standard.org/standard/core/DOES
        ; Create the payload for defining new defining words. See
        ; http://www.bradrodriguez.com/papers/moving3.htm and
        ; the Developer Guide in the manual for a discussion of
        ; DOES>'s internal workings. This uses tmp1 and tmp2.
        ; """
.scope
xt_does:
                ; compile a subroutine jump to runtime of DOES>
                ldy #>does_runtime
                lda #<does_runtime
                jsr cmpl_subroutine

                ; compile a subroutine jump to DODOES. In traditional
                ; terms, this is the Code Field Area (CFA) of the new
                ; word
                ldy #>dodoes
                lda #<dodoes
                jsr cmpl_subroutine

z_does:         rts
.scend

does_runtime:
        ; """Runtime portion of DOES>. This replaces the subroutine jump
        ; to DOVAR that CREATE automatically encodes by a jump to the
        ; address that contains a subroutine jump to DODOES. We don't
        ; jump to DODOES directly because we need to work our magic with
        ; the return addresses. This routine is also known as "(DOES)" in
        ; other Forths
        ; """
.scope
                ply             ; LSB
                pla             ; MSB

                iny
                bne +
                inc
*
                sty tmp1
                sta tmp1+1

                ; CREATE has also already modified the DP to point to the new
                ; word. We have no idea which instructions followed the CREATE
                ; command if there is a DOES> so the CP could point anywhere
                ; by now. The address of the word's xt is four bytes down.
                jsr current_to_dp   ; Grab the DP from the CURRENT wordlist.
                lda dp
                clc
                adc #4
                sta tmp2
                lda dp+1
                adc #0          ; we only care about the carry
                sta tmp2+1

                ; Now we get that address and add one byte to skip over the JSR
                ; opcode
                lda (tmp2)
                clc
                adc #1
                sta tmp3
                ldy #1
                lda (tmp2),y
                adc #0          ; we only care about the carry
                sta tmp3+1

                ; Replace the DOVAR address with our own
                lda tmp1        ; LSB
                sta (tmp3)
                lda tmp1+1
                sta (tmp3),y    ; Y is still 1

                ; Since we removed the return address that brought us here, we
                ; go back to whatever the main routine was. Otherwise, we we
                ; smash into the subroutine jump to DODOES.
                rts
.scend


; ## DOT ( u -- ) "Print TOS"
; ## "."  auto  ANS core
        ; """https://forth-standard.org/standard/core/d"""
.scope
xt_dot:
                jsr underflow_1

                jsr xt_dup                      ; ( n n )
                jsr xt_abs                      ; ( n u )
                jsr xt_zero                     ; ( n u 0 )
                jsr xt_less_number_sign         ; ( n u 0 )
                jsr xt_number_sign_s            ; ( n ud )
                jsr xt_rot                      ; ( ud n )
                jsr xt_sign                     ; ( ud )
                jsr xt_number_sign_greater      ; ( addr u )
                jsr xt_type
                jsr xt_space

z_dot:          rts
.scend


; ## DOT_PAREN ( -- ) "Print input up to close paren .( comment )"
; ## ".("  auto  ANS core
        ; """http://forth-standard.org/standard/core/Dotp"""
.scope
xt_dot_paren:
                ; Put a right paren on the stack.
                dex
                dex
                lda #41     ; Right parenthesis
                sta 0,x
                stz 1,x

                jsr xt_parse
                jsr xt_type

z_dot_paren:    rts
.scend


; ## DOT_QUOTE ( "string" -- ) "Print string from compiled word"
; ## ".""  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/Dotq
        ; Compile string that is printed during run time. ANS Forth wants
        ; this to be compile-only, even though everybody and their friend
        ; uses it for everything. We follow the book here, and recommend
        ; `.(` for general printing.
        ; """
.scope
xt_dot_quote:
                ; we let S" do the heavy lifting. Since we're in
                ; compile mode, it will save the string and reproduce it
                ; during runtime
                jsr xt_s_quote

                ; We then let TYPE do the actual printing
                ldy #>xt_type
                lda #<xt_type
                jsr cmpl_subroutine

z_dot_quote:    rts
.scend


; ## DOT_R ( n u -- ) "Print NOS as unsigned number with TOS with"
; ## ".r"  tested  ANS core ext
        ; """https://forth-standard.org/standard/core/DotR
        ;
        ; Based on the Forth code
        ;  : .R  >R DUP ABS 0 <# #S ROT SIGN #> R> OVER - SPACES TYPE ;
        ; """
.scope
xt_dot_r:
                jsr underflow_2

                jsr xt_to_r
                jsr xt_dup
                jsr xt_abs
                jsr xt_zero
                jsr xt_less_number_sign
                jsr xt_number_sign_s
                jsr xt_rot
                jsr xt_sign
                jsr xt_number_sign_greater
                jsr xt_r_from
                jsr xt_over
                jsr xt_minus
                jsr xt_spaces
                jsr xt_type

z_dot_r:        rts
.scend


; ## DOT_S ( -- ) "Print content of Data Stack"
; ## ".s"  tested  ANS tools
        ; """https://forth-standard.org/standard/tools/DotS
        ; Print content of Data Stack non-distructively. We follow the format
        ; of Gforth and print the number of elements first in brackets,
        ; followed by the Data Stack content (if any).
        ;
        ; Since this is for humans, we don't have to worry about speed.
        ; """
.scope
xt_dot_s:
                jsr xt_depth    ; ( -- u )

                ; Print stack depth in brackets
                lda #$3c        ; ASCII for "<"
                jsr emit_a

                ; We keep a copy of the number of the things on the stack
                ; to use as a counter later down. This assumes that there
                ; are less than 255 elements on the stack
                lda 0,x
                pha

                ; print unsigned number without the trailing space
                dex             ; DUP
                dex
                sta 0,x
                stz 1,x

                jsr print_u

                lda #$3e        ; ASCII for ">"
                jsr emit_a
                lda #AscSP      ; ASCII for SPACE
                jsr emit_a

                inx
                inx

                ; There will be lots of cases where the stack is empty. If that
                ; is so, get out of here quickly
                cpx #dsp0
                beq _done

_have_stack:
                ; We have at least one element on the stack. The depth of the
                ; stack is on the stack, we can use it as a counter. We go
                ; from bottom to top
                ply

                lda #dsp0-1     ; go up one to avoid garbage
                sta tmp3
                stz tmp3+1      ; must be zero page on the 65c02
_loop:
                dex
                dex

                lda (tmp3)
                sta 1,x
                dec tmp3

                lda (tmp3)
                sta 0,x
                dec tmp3
                phy

                jsr xt_dot

                ply
                dey
                bne _loop

                pha             ; dummy to balance stack
_done:
                pla
z_dot_s:        rts
.scend


; ## D_DOT ( d -- ) "Print double"
; ## "d."  tested  ANS double
        ; """http://forth-standard.org/standard/double/Dd"""
        ;
        ; From the Forth code:
        ; : D. TUCK DABS <# #S ROT SIGN #> TYPE SPACE ;
        ; """
.scope
xt_d_dot:
                jsr underflow_2

                jsr xt_tuck
                jsr xt_dabs
                jsr xt_less_number_sign
                jsr xt_number_sign_s
                jsr xt_rot
                jsr xt_sign
                jsr xt_number_sign_greater
                jsr xt_type
                jsr xt_space

z_d_dot:        rts
.scend


; ## D_DOT_R ( d u -- ) "Print double right-justified u wide"
; ## "d.r"  tested  ANS double
        ; """http://forth-standard.org/standard/double/DDotR"""
        ; Based on the Forth code
        ;  : D.R >R TUCK DABS <# #S ROT SIGN #> R> OVER - SPACES TYPE ;
        ; """
.scope
xt_d_dot_r:
                jsr underflow_3
                ; From the forth code:
                jsr xt_to_r
                jsr xt_tuck
                jsr xt_dabs
                jsr xt_less_number_sign
                jsr xt_number_sign_s
                jsr xt_rot
                jsr xt_sign
                jsr xt_number_sign_greater
                jsr xt_r_from
                jsr xt_over
                jsr xt_minus
                jsr xt_spaces
                jsr xt_type

z_d_dot_r:      rts
.scend


; ## DROP ( u -- ) "Pop top entry on Data Stack"
; ## "drop"  auto  ANS core
        ; """https://forth-standard.org/standard/core/DROP"""
xt_drop:
                jsr underflow_1

                inx
                inx

z_drop:         rts


; ## DUMP ( addr u -- ) "Display a memory region"
; ## "dump"  tested  ANS tools
        ; """https://forth-standard.org/standard/tools/DUMP
        ;
        ; DUMP's exact output is defined as "implementation dependent".
        ; This is in assembler because it is
        ; useful for testing and development, so we want to have it work
        ; as soon as possible. Uses TMP2
        ; """
.scope
xt_dump:
                jsr underflow_2
_row:
                ; start counter for 16 numbers per row
                ldy #16

                ; We use TMP2 as the index for the ASCII characters
                ; that we print at the and of the hex block. We
                ; start saving them at HERE (CP)
                stz tmp2

                jsr xt_cr

                ; print address number
                lda 3,x
                jsr byte_to_ascii
                lda 2,x
                jsr byte_to_ascii

                jsr xt_space
                jsr xt_space
_loop:
                ; if there are zero bytes left to display, we're done
                lda 0,x
                ora 1,x
                beq _all_printed

                ; dump the contents
                lda (2,x)
                pha                     ; byte_to_ascii destroys A
                jsr byte_to_ascii
                jsr xt_space
                pla

                ; Handle ASCII printing
                jsr is_printable
                bcs _printable
                lda #'.                 ; Print dot if not printable
_printable:
                phy                     ; save counter
                ldy tmp2
                sta (cp),y
                inc tmp2
                ply

                ; extra space after eight bytes
                cpy #9
                bne _next_char
                jsr xt_space

_next_char:
                inc 2,x
                bne _counter
                inc 3,x

_counter:
                ; loop counter
                lda 0,x
                bne +
                dec 1,x
*
                dec 0,x
                dey
                bne _loop               ; next byte

                ; Done with one line, print the ASCII version of these
                ; characters
                jsr xt_space
                jsr _print_ascii

                bra _row                ; new row

_all_printed:
                ; See if there are any ASCII characters in the buffer
                ; left to print
                lda tmp2
                beq _done

                ; In theory, we could try to make the ASCII part line
                ; up with the line before it. But that is a hassle (we
                ; use three bytes for each missed hex entry, and
                ; then there is the gap after eight entries) and it
                ; makes it harder to read. We settle for one extra
                ; space instead for the moment
                jsr xt_space
                jsr _print_ascii
_done:
                jsr xt_two_drop         ; one byte less than 4x INX
z_dump:         rts


_print_ascii:
                ; Print the ASCII characters that we have saved from
                ; HERE (CP) to HERE plus whatever is in TMP2. This routine
                ; is not compiled (DUMP is probably never compiled anyway)
                ; but we keep it inside the scope of DUMP.
                ldy #0
_ascii_loop:
                lda (cp),y
                jsr emit_a
                iny

                ; extra space after eight chars
                cpy #8
                bne +
                jsr xt_space
*
                dec tmp2
                bne _ascii_loop

                rts
.scend


; ## DUP ( u -- u u ) "Duplicate TOS"
; ## "dup"  auto  ANS core
        ; """https://forth-standard.org/standard/core/DUP"""
xt_dup:
                jsr underflow_1

                dex
                dex

                lda 2,x         ; LSB
                sta 0,x
                lda 3,x         ; MSB
                sta 1,x

z_dup:          rts


; ## ED ( -- u ) "Line-based editor"
; ## "ed"  fragment  Tali Forth
        ; """Start the line-based editor ed6502. See separate file
        ; ed.asm or the manual for details.
        ; """
xt_ed:
                jsr ed6502      ; kept in separate file

z_ed:           rts


; ## EDITOR_WORDLIST ( -- u ) "WID for the Editor wordlist"
; ## "editor-wordlist"  tested  Tali Editor
        ; """ Commonly used like `editor-wordlist >order` to add the editor
        ; words to the search order so they can be used.  This will need
        ; to be done before any of the words marked "Tali Editor" can be
        ; used.  See the tutorial on Wordlists and the Search Order for
        ; more information.

        ;
        ; This is a dummy entry, the code is shared with ONE
        ; """


; ## ELSE (C: orig -- orig) ( -- ) "Conditional flow control"
; ## "else"  auto  ANS core
        ; """http://forth-standard.org/standard/core/ELSE
        ;
        ; The code is shared with ENDOF
        ; """
.scope
xt_else:
xt_endof:
                ; Put an unconditional branch.
                ldy #>branch_runtime
                lda #<branch_runtime
                jsr cmpl_subroutine

                ; Put the address of the branch address on the stack.
                jsr xt_here

                ; Use zero for the branch address for now.
                ; THEN will fill it in later.
                jsr xt_zero
                jsr xt_comma

                ; Get the address to jump to (just after the
                ; unconditional branch) for the IF to jump to
                ; when false.
                jsr xt_here
                jsr xt_rot

                ; Update the original if 0branch address.
                jsr xt_store
z_else:
z_endof:
                rts
.scend


branch_runtime:
        ; """Runtime component for a branch. Used by ELSE and ENDOF. This was
        ; formally part of a separate word BRANCH which was later removed.
        ; """
.scope
                ; The address on the Return Stack points to the last byte
                ; of the JSR address, one byte below the branch literal
                pla
                sta tmpbranch
                pla
                sta tmpbranch+1

                ; Keep in mind: the address we just popped points one byte
                ; lower than the branch literal we want to grab
                ldy #1
                lda (tmpbranch),y  ; LSB
                sta tmp1
                iny
                lda (tmpbranch),y  ; MSB
                sta tmp1+1

                jmp (tmp1)
.scend


; ## EMIT ( char -- ) "Print character to current output"
; ## "emit"  auto  ANS core
        ; """https://forth-standard.org/standard/core/EMIT
        ; Run-time default for EMIT. The user can revector this by changing
        ; the value of the OUTPUT variable. We ignore the MSB completely, and
        ; do not check to see if we have been given a valid ASCII character.
        ; Don't make this native compile.
        ; """
.scope
xt_emit:
                jsr underflow_1

                lda 0,x
                inx
                inx

emit_a:
        ; We frequently want to print the character in A without fooling
        ; around with the Data Stack. This is emit_a's job, which still
        ; allows the output to be vectored. Call it with JSR as you
        ; would XT_EMIT
                jmp (output)            ; JSR/RTS

z_emit:         ; never reached
.scend


; ## EMPTY_BUFFERS ( -- ) "Empty all buffers without saving"
; ## "empty-buffers"  tested  ANS block ext
        ; """https://forth-standard.org/standard/block/EMPTY-BUFFERS"""
xt_empty_buffers:
                ; Set the buffer status to empty.
                ldy #buffstatus_offset
                lda #0
                sta (up),y      ; Only LSB is used.
z_empty_buffers:
                rts


; ## ENDCASE (C: case-sys -- ) ( x -- ) "Conditional flow control"
; ## "endcase"  auto  ANS core ext
        ; """http://forth-standard.org/standard/core/ENDCASE"""
.scope
xt_endcase:
                ; Postpone DROP to remove the item
                ; being checked.
                ldy #>xt_drop
                lda #<xt_drop
                jsr cmpl_subroutine

                ; There are a number of address (of branches that need their
                ; jump addressed filled in with the address of right here).
                ; Keep calling THEN to deal with them until we reach the
                ; 0 that CASE put on the stack at the beginning.
_endcase_loop:
                ; Check for 0 on the stack.
                lda 0,x
                ora 1,x
                beq _done

                jsr xt_then
                bra _endcase_loop
_done:
                ; Remove the 0 from the stack.
                inx
                inx
z_endcase:      rts
.scend


; ## ENDOF (C: case-sys1 of-sys1-- case-sys2) ( -- ) "Conditional flow control"
; ## "endof"  auto  ANS core ext
        ; """http://forth-standard.org/standard/core/ENDOF
        ; This is a dummy entry, the code is shared with ELSE
        ; """


; ## ENVIRONMENT_Q  ( addr u -- 0 | i*x true )  "Return system information"
; ## "environment?"  auto  ANS core
        ; """https://forth-standard.org/standard/core/ENVIRONMENTq
        ;
        ; By ANS definition, we use upper-case strings here, see the
        ; string file for details. This can be realized as a high-level
        ; Forth word as
        ;
        ; : STRING_OF POSTPONE 2OVER POSTPONE COMPARE POSTPONE 0=
        ;    POSTPONE IF POSTPONE 2DROP ; IMMEDIATE COMPILE-ONLY
        ; HEX
        ; : ENVIRONMENT? ( C-ADDR U -- FALSE | I*X TRUE )
        ; CASE
        ; S" /COUNTED-STRING"    STRING_OF  7FFF TRUE ENDOF
        ; S" /HOLD"              STRING_OF    FF TRUE ENDOF
        ; S" /PAD"               STRING_OF    54 TRUE ENDOF ( 84 DECIMAL )
        ; S" ADDRESS-UNIT-BITS"  STRING_OF     8 TRUE ENDOF
        ; S" FLOORED"            STRING_OF FALSE TRUE ENDOF ( WE HAVE SYMMETRIC )
        ; S" MAX-CHAR"           STRING_OF   255 TRUE ENDOF
        ; S" MAX-D"              STRING_OF
                                     ; 7FFFFFFF. TRUE ENDOF
        ; S" MAX-N"              STRING_OF  7FFF TRUE ENDOF
        ; S" MAX-U"              STRING_OF  FFFF TRUE ENDOF
        ; S" MAX-UD"             STRING_OF
                                     ; FFFFFFFF. TRUE ENDOF
        ; S" RETURN-STACK-CELLS" STRING_OF    80 TRUE ENDOF
        ; S" STACK-CELLS"        STRING_OF    20 TRUE ENDOF ( FROM DEFINITIONS.ASM )
        ; ( DEFAULT ) 2DROP FALSE FALSE ( ONE FALSE WILL DROPPED BY ENDCASE )
        ; ENDCASE ;
        ;
        ; but that uses lots of memory and increases the start up time. This
        ; word is rarely used so we can try to keep it short at the expense
        ; of speed.
        ; """
.scope
xt_environment_q:
                jsr underflow_1

                ; This code is table-driven: We walk through the list of
                ; strings until we find one that matches, and then we take
                ; the equivalent data from the results table. This is made
                ; a bit harder by the fact that some of these return a
                ; double-cell number and some a single-cell one.

                ; We will walk through the table with variables that return
                ; a single-cell result
                ldy #00                 ; counter for table

                ; We use a flag on the the stack to signal if we have a single-cell
                ; or double-cell number. We use 0 to signal single-cell and 1 for
                ; double-cell.
                phy
_table_loop:
                ; We arrived here with the address of the string to be checked
                ; on the stack. We make a copy. Index is in Y
                jsr xt_two_dup          ; ( addr u addr u ) 2DUP does not use Y

                ; We do our work on the TOS to speed things up
                dex
                dex                     ; ( addr u addr u ? )

                ; Get address of string to check from table
                lda _env_table_single,y
                sta 0,x
                iny
                lda _env_table_single,y
                sta 1,x                 ; ( addr u addr u addr-t )
                iny

                ; See if this is the last entry. The LSB is still in A
                ora 0,x
                beq _table_done

                ; We have a string entry. The address there is stored in
                ; old-style address format, that is, the first byte is the
                ; length of the string
                phy                     ; save Y, which is used by COUNT
                jsr xt_count            ; ( addr u addr u addr-s u-s )
                jsr xt_compare          ; ( addr u f )
                ply

                ; If we found a match (flag is zero -- COMPARE is weird
                ; that way), return the result
                lda 0,x
                ora 1,x
                beq _got_result

                ; Flag is not zero, so not a perfect match, so try next
                ; word
                inx                     ; DROP, now ( addr u )
                inx

                bra _table_loop

_got_result:
                ; We arrive here with ( addr u -1 ) and know that we've found
                ; a match. The index of the match+2 is in Y.
                inx                     ; drop flag, now ( addr u )
                inx
                dey                     ; go back to index we had
                dey

                ; See if this is a single-cell word.
                pla
                bne _double_result

                ; Single-cell result
                lda _env_results_single,y
                sta 2,x
                iny
                lda _env_results_single,y
                sta 3,x                 ; ( res u )

                bra _set_flag

_double_result:
                ; This is a double-celled result, which means we have to
                ; fool around with the index some more. We also need a
                ; further cell on the stack
                dex                     ; ( addr u ? )
                dex

                ; We have 11 single-cell words we check, plus the 0000 as
                ; a marker for the end of the table, so we arrive here
                ; with Y as 22 or more. To get the index for the double-
                ; cell words, we move the result
                tya
                sec
                sbc #24

                ; We have four bytes per entry in the table, but the index
                ; keeps increasing by two, so we only have to multiply by
                ; two (shift left once) to get the right result
                asl
                tay

                lda _env_results_double,y
                sta 2,x
                iny
                lda _env_results_double,y
                sta 3,x                 ; ( res u ? )
                iny

                lda _env_results_double,y
                sta 4,x
                iny
                lda _env_results_double,y
                sta 5,x                 ; ( res res ? )

                ; fall through to _set_flag
_set_flag:
                lda #$ff
                sta 0,x
                sta 1,x                 ; ( res f )

                bra _done
_table_done:
                ; We're done with a table, because the entry was a zero.
                ; We arrive here with ( addr u addr u 0 )

                ; We take the flag from stack and increase it by one. If the
                ; flag is zero, we have just completed the single-cell number
                ; strings, so we in increase the flag and try again. Otherwise,
                ; we're done with the double-cell table without having found
                ; a match, and we're done
                pla
                bne _no_match

                ; Flag is zero, increase it to one and start over to check
                ; double-cell values
                inc
                pha

                txa
                clc
                adc #6                  ; skip six bytes
                tax                     ; ( addr u )

                bra _table_loop
_no_match:
                ; Bummer, not found. We arrive here with
                ; ( addr u addr u 0 ) and need to return just a zero
                txa
                clc
                adc #10
                tax                     ; ( addr ) - not ( 0 ) !

                jsr xt_false
_done:
z_environment_q:
                rts
.scend

; Tables for ENVIRONMENT?. We use two separate ones, one for the single-cell
; results and one for the double-celled results. The zero cell at the
; end of each table marks its, uh, end. The strings themselves are defined
; in strings.asm. Note if we add more entries to the single-cell table, we
; have to adapt the result code for double printout, where we subtract 22
; (two bytes each single-cell string and two bytes for the end-of-table
; marker 0000
_env_table_single:
        .word envs_cs, envs_hold, envs_pad, envs_aub, envs_floored
        .word envs_max_char, envs_max_n, envs_max_u, envs_rsc
        .word envs_sc, envs_wl, 0000

_env_table_double:
        .word envs_max_d, envs_max_ud, 0000

_env_results_single:
        .word $7FFF     ; /COUNTED-STRING
        .word $00FF     ; /HOLD
        .word $0054     ; /PAD (this is 84 decimal)
        .word $0008     ; ADDRESS-UNIT-BITS (keep "$" to avoid octal!)
        .word 0000      ; FLOORED ("FALSE", we have symmetric)
        .word $00FF     ; MAX-CHAR
        .word $7FFF     ; MAX-N
        .word $FFFF     ; MAX-U
        .word $0080     ; RETURN-STACK-CELLS
        .word $0020     ; STACK-CELLS (from definitions.asm)
        .word $0009     ; WORDLISTS

_env_results_double:
        .word $7FFF, $FFFF      ; MAX-D
        .word $FFFF, $FFFF      ; MAX-UD


; ## EQUAL ( n n -- f ) "See if TOS and NOS are equal"
; ## "="  auto  ANS core
        ; """https://forth-standard.org/standard/core/Equal"""
.scope
xt_equal:
                jsr underflow_2

                lda 0,x                 ; LSB
                cmp 2,x
                bne _false

                lda 1,x                 ; MSB
                cmp 3,x
                bne _false

                lda #$ff
                bra _done

_false:         lda #0                  ; drop thru to done

_done:          sta 2,x
                sta 3,x

                inx
                inx

z_equal:        rts
.scend


; ## BLANK ( addr u -- ) "Fill memory region with spaces"
; ## "blank"  auto  ANS string
        ; """https://forth-standard.org/standard/string/BLANK"""
xt_blank:
                ; We don't check for underflow here because
                ; we deal with that in FILL
                dex
                dex
                lda #AscSP
                sta 0,x
                stz 1,x

                bra xt_fill     ; skip over code for ERASE


; ## ERASE ( addr u -- ) "Fill memory region with zeros"
; ## "erase"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/ERASE
        ; Note that ERASE works with "address" units
        ; (bytes), not cells.
        ; """
.scope
xt_erase:
                ; We don't check for underflow here because
                ; we deal with that in FILL
                dex
                dex
                stz 0,x
                stz 1,x

                ; fall through to FILL

; ## FILL ( addr u char -- ) "Fill a memory region with a character"
; ## "fill"  auto  ANS core
        ; """https://forth-standard.org/standard/core/FILL
        ; Fill u bytes of memory with char starting at addr. Note that
        ; this works on bytes, not on cells. On an 8-bit machine such as the
        ; 65c02, this is a serious pain in the rear. It is not defined what
        ; happens when we reach the end of the address space
        ; """
xt_fill:
                jsr underflow_3

                ; We use tmp1 to hold the address
                lda 4,x         ; LSB
                sta tmp1
                lda 5,x
                sta tmp1+1

                ; We use tmp2 to hold the counter
                lda 2,x
                sta tmp2
                lda 3,x
                sta tmp2+1

                ; We use Y to hold the character
                lda 0,x
                tay
_loop:
                ; Unfortunately, we also need to make sure that we don't
                ; write further than the end of the RAM. So RAM_END must
                ; be larger or equal to the current address
                lda #>ram_end           ; MSB
                cmp tmp1+1
                bcc _done               ; RAM_END < TMP1, so leave
                bne _check_counter      ; RAM_END is not smaller and not equal

                lda #<ram_end           ; LSB, because MSBs were equal
                cmp tmp1
                bcc _done               ; RAM_END < TMP1, so leave

_check_counter:
                ; See if our counter has reached zero
                lda tmp2
                ora tmp2+1
                beq _done

                ; We're not in ROM and we still have stuff on the counter, so
                ; let's actually do what we came here to do
                tya
                sta (tmp1)

                ; Adjust the counter
                lda tmp2
                bne +
                dec tmp2+1
*               dec tmp2

                ; Next address
                inc tmp1
                bne _loop
                inc tmp1+1

                bra _loop

_done:
                ; Drop three cells off the Data Stack. This uses one byte
                ; less than six times INX
                txa
                clc
                adc #6
                tax
z_blank:
z_erase:
z_fill:         rts
.scend


; ## EXECUTE ( xt -- ) "Jump to word based on execution token"
; ## "execute"  auto  ANS core
        ; """https://forth-standard.org/standard/core/EXECUTE"""
xt_execute:
                jsr underflow_1

                jsr doexecute   ; do not combine to JMP (native coding)

z_execute:      rts

doexecute:
                lda 0,x
                sta ip
                lda 1,x
                sta ip+1

                inx
                inx

                ; we don't need a RTS here because we highjack the RTS of
                ; the word we're calling to get back to xt_execute
                jmp (ip)

; end of doexecute


; ## EXECUTE_PARSING ( addr u xt -- ) "Pass a string to a parsing word"
; ## "execute-parsing"  auto  Gforth
        ; """https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/The-Input-Stream.html
        ; Execute the parsing word defined by the execution token (xt) on the
        ; string as if it were passed on the command line. See the file
        ; tests/tali.fs for examples.
        ;
        ; Note that this word is coded completely
        ; different in its Gforth version, see the file execute-parsing.fs
        ; (in /usr/share/gforth/0.7.3/compat/ on Ubuntu 18.04 LTS) for details.
        ; """
xt_execute_parsing:
                jsr underflow_3

                jsr xt_input_to_r       ; save normal input for later
                jsr xt_not_rote         ; -ROT ( xt addr u )

                lda 0,x                 ; TOS is new ciblen
                sta ciblen
                lda 1,x
                sta ciblen+1

                lda 2,x                 ; NOS is new cib
                sta cib
                lda 3,x
                sta cib+1

                stz toin                ; Set >IN to zero
                stz toin+1

                jsr xt_two_drop         ; 2DROP ( xt )
                jsr xt_execute

                jsr xt_r_to_input

z_execute_parsing:
                rts


; ## EXIT ( -- ) "Return control to the calling word immediately"
; ## "exit"  auto  ANS core
        ; """https://forth-standard.org/standard/core/EXIT
        ; If we're in a loop, we need to UNLOOP first and get everything
        ; we we might have put on the Return Stack off as well. This should
        ; be natively compiled.
        ; """
.scope
xt_exit:
                rts             ; keep before z_exit
z_exit:                         ; never reached
.scend


; ## FALSE ( -- f ) "Push flag FALSE to Data Stack"
; ## "false"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/FALSE"""
xt_false:
                dex
                dex
                stz 0,x
                stz 1,x

z_false:        rts


; ## FETCH ( addr -- n ) "Push cell content from memory to stack"
; ## "@"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Fetch"""
xt_fetch:
                jsr underflow_1

                lda (0,x)               ; LSB
                tay
                inc 0,x
                bne +
                inc 1,x
*
                lda (0,x)               ; MSB
                sta 1,x
                sty 0,x

z_fetch:        rts


; ## FIND ( caddr -- addr 0 | xt 1 | xt -1 ) "Find word in Dictionary"
; ## "find"  auto  ANS core
        ; """https://forth-standard.org/standard/core/FIND
        ; Included for backwards compatibility only, because it still
        ; can be found in so may examples. It should, however, be replaced
        ; by FIND-NAME. Counted string either returns address with a FALSE
        ; flag if not found in the Dictionary, or the xt with a flag to
        ; indicate if this is immediate or not. FIND is a wrapper around
        ; FIND-NAME, we get this all over with as quickly as possible. See
        ; https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Word-Lists.html
        ; https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Name-token.html
        ; """
.scope
xt_find:
                jsr underflow_1

                ; Save address in case conversion fails. We use the
                ; Return Stack instead of temporary variables like TMP1
                ; because this is shorter and anybody still using FIND
                ; can't be worried about speed anyway
                lda 1,x                 ; MSB
                pha
                lda 0,x                 ; LSB
                pha

                ; Convert ancient-type counted string address to
                ; modern format
                jsr xt_count            ; ( caddr -- addr u )
                jsr xt_find_name        ; ( addr u -- nt | 0 )

                lda 0,x
                ora 1,x
                bne _found_word

                ; No word found. Return address of the string and a false
                ; flag
                jsr xt_false            ; ( 0 0 )

                ; The address needs to be restored.
                pla                     ; LSB of address
                sta 2,x
                pla
                sta 3,x                 ; MSB of address

                bra _done               ; ( addr 0 )

_found_word:
                ; We don't need the address after all, dump it
                pla
                pla

                ; We arrive here with ( nt ) on the TOS. Now we have to
                ; convert the return values to FIND's format
                jsr xt_dup              ; ( nt nt )
                jsr xt_name_to_int      ; ( nt xt )
                jsr xt_swap             ; ( xt nt )

                ldy #0                  ; Prepare flag

                ; The flags are in the second byte of the header
                inc 0,x
                bne +
                inc 1,x                 ; ( xt nt+1 )
*
                lda (0,x)               ; ( xt char )
                and #IM
                bne _immediate          ; bit set, we're immediate

                lda #$FF                ; We're not immediate, return -1
                sta 0,x
                sta 1,x
                bra _done

_immediate:
                lda #1                  ; We're immediate, return 1
                sta 0,x
                stz 1,x
_done:
z_find:         rts
.scend


; ## FIND_NAME ( addr u -- nt|0 ) "Get the name token of input word"
; ## "find-name"  auto  Gforth
.scope
xt_find_name:
        ; """www.complang.tuwien.ac.at/forth/gforth/Docs-html/Name-token.html
        ; Given a string, find the Name Token (nt) of a word or return
        ; zero if the word is not in the dictionary. We use this instead of
        ; ancient FIND to look up words in the Dictionary passed by
        ; PARSE-NAME. Note this returns the nt, not the xt of a word like
        ; FIND. To convert, use NAME>INT. This is a Gforth word. See
        ; https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Name-token.html
        ; FIND calls this word
        ; """
                jsr underflow_2

                ; check for special case of an empty string (length zero)
                lda 0,x
                ora 1,x
                bne _nonempty

                jmp _fail_done

_nonempty:
                ; Set up for traversing the wordlist search order.
                stz tmp3                ; Start at the beginning

_wordlist_loop:
                ldy #num_order_offset   ; Compare to byte variable #ORDER
                lda tmp3
                cmp (up),y              ; Check to see if we are done
                bne _have_string

                ; We ran out of wordlists to search.
                jmp _fail_done

_have_string:
                ; set up first loop iteration

                ; Get the current wordlist id
                clc             ; SEARCH-ORDER is array of bytes.
                adc #search_order_offset
                tay
                lda (up),y      ; Get the id byte, which is the offset
                                ; into the cell array WORDLISTS

                ; Get the DP for that wordlist.
                asl                     ; Turn offset into cells offset.
                clc
                adc #wordlists_offset
                tay
                lda (up),y
                sta tmp1
                iny
                lda (up),y
                sta tmp1+1

                lda 2,x                 ; Address of mystery string
                sta tmp2
                lda 3,x
                sta tmp2+1

_loop:
                ; first quick test: Are strings the same length?
                lda (tmp1)
                cmp 0,x
                bne _next_entry

_compare_string:
                ; are the same length, so we now have to compare each
                ; character

                ; second quick test: Is the first character the same?
                lda (tmp2)      ; first character of mystery string

                ; Lowercase the incoming charcter.
                cmp #$5B        ; ASCII '[' (one past Z)
                bcs _compare_first
                cmp #$41        ; ASCII 'A'
                bcc _compare_first

                ; An uppercase letter has been located.  Make it
                ; lowercase.
                clc
                adc #$20

_compare_first:
                ldy #8          ; Offset in nt to name
                cmp (tmp1),y    ; first character of current word
                bne _next_entry

                ; String length is the same and the first character is the
                ; same. If the length of the string is 1, we're already done
                lda 0,x
                dec
                beq _success

                ; No such luck: The strings are the same length and the first
                ; char is the same, but the word is more than one char long.
                ; So we suck it up and compare every single character. We go
                ; from back to front, because words like CELLS and CELL+ would
                ; take longer otherwise. We can also shorten the loop by one
                ; because we've already compared the first char.

                ; The string of the word we're testing against is 8 bytes down
                lda tmp1
                pha             ; Preserve tmp1 on the return stack.
                clc
                adc #8
                sta tmp1        ; Reusing tmp1 temporarily for string check.
                lda tmp1+1
                pha             ; Preserve tmp1+1 on the return stack.
                adc #0          ; we only need the carry
                sta tmp1+1

                ldy 0,x         ; index is length of string minus 1
                dey

_string_loop:
                lda (tmp2),y    ; last char of mystery string

                ; Lowercase the incoming charcter.
                cmp #$5B         ; ASCII '[' (one past Z)
                bcs _check_char
                cmp #$41        ; ASCII 'A'
                bcc _check_char

                ; An uppercase letter has been located.  Make it
                ; lowercase.
                clc
                adc #$20

_check_char:
                cmp (tmp1),y    ; last char of word we're testing against
                bne _next_entry_tmp1

                dey
                bne _string_loop

_success_tmp1:
                pla             ; Restore tmp1 from the return stack.
                sta tmp1+1
                pla
                sta tmp1

_success:
                ; The strings match. Put correct nt NOS, because we'll drop
                ; TOS before we leave
                lda tmp1
                sta 2,x
                lda tmp1+1
                sta 3,x

                bra _done

_next_entry_tmp1:
                pla             ; Restore tmp1 from the return stack.
                sta tmp1+1
                pla
                sta tmp1

_next_entry:
                ; Not the same, so we get the next word. Next header
                ; address is two bytes down
                ldy #2
                lda (tmp1),y
                pha
                iny
                lda (tmp1),y
                sta tmp1+1
                pla
                sta tmp1

                ; If we got a zero, we've walked the whole Dictionary and
                ; return as a failure, otherwise try again
                ora tmp1+1
                bne _loop

                ; Move on to the next wordlist in the search order.
                inc tmp3
                jmp _wordlist_loop

_fail_done:
                stz 2,x         ; failure flag
                stz 3,x
_done:
                inx
                inx

z_find_name:    rts
.scend


; ## FLUSH ( -- ) "Save dirty buffers and empty buffers"
; ## "flush"  auto  ANS block
        ; """https://forth-standard.org/standard/block/FLUSH"""
xt_flush:
                jsr xt_save_buffers

                ; Set the buffer status to empty.
                ldy #buffstatus_offset
                lda #0
                sta (up),y      ; Only LSB is used.
z_flush:
                rts


; ## FM_SLASH_MOD ( d n1  -- rem n2 ) "Floored signed division"
; ## "fm/mod"  auto  ANS core
        ; """https://forth-standard.org/standard/core/FMDivMOD
        ; Note that by default, Tali Forth uses SM/REM for most things.
        ;
        ; There are various ways to realize this. We follow EForth with
        ;    DUP 0< DUP >R  IF NEGATE >R DNEGATE R> THEN >R DUP
        ;    0<  IF R@ + THEN  R> UM/MOD R> IF SWAP NEGATE SWAP THEN
        ; See (http://www.forth.org/eforth.html). However you can also
        ; go FM/MOD via SM/REM (http://www.figuk.plus.com/build/arith.htm):
        ;     DUP >R  SM/REM DUP 0< IF SWAP R> + SWAP 1+ ELSE  R> DROP THEN
        ; """
.scope
xt_fm_slash_mod:
                jsr underflow_3

                ; if sign of n1 is negative, negate both n1 and d
                stz tmp2        ; default: n is positive
                lda 1,x         ; MSB of n1
                bpl _check_d

                inc tmp2        ; set flag to negative for n1
                jsr xt_negate   ; NEGATE
                jsr xt_to_r     ; >R
                jsr xt_dnegate  ; DNEGATE
                jsr xt_r_from   ; R>

_check_d:
                ; If d is negative, add n1 to high cell of d
                lda 3,x         ; MSB of high word of d
                bpl _multiply

                clc
                lda 0,x         ; LSB of n1
                adc 2,x         ; LSB of dh
                sta 2,x

                lda 1,x         ; MSB of n1
                adc 3,x         ; MSB of dh
                sta 3,x

_multiply:
                jsr xt_um_slash_mod     ; ( d n1 -- rem n2 )

                ; if n was negative, negate the result
                lda tmp2
                beq _done

                inx             ; pretend that we SWAP
                inx
                jsr xt_negate
                dex
                dex
_done:
z_fm_slash_mod: rts
.scend


; ## FORTH ( -- ) "Replace first WID in search order with Forth-Wordlist"
; ## "forth"  auto  ANS search ext
        ; """https://forth-standard.org/standard/search/FORTH"""
xt_forth:
                ldy #search_order_offset
                lda #0          ; The WID for Forth is 0.

                sta (up),y
z_forth:
                rts


; This is a special jsr target to skip the zeroing of BLK at the beginning
; of evaluate.  It's used by LOAD to allow setting BLK while the block is
; being evaluated.  Evaluate's normal behavior is to zero BLK.
load_evaluate:
                ; Set a flag (using tmp1) to not zero BLK
                lda #$FF
                sta tmp1
                bra load_evaluate_start

; ## EVALUATE ( addr u -- ) "Execute a string"
; ## "evaluate"  auto  ANS core
        ; """https://forth-standard.org/standard/core/EVALUATE
        ; Set SOURCE-ID to -1, make addr u the input source, set >IN to zero.
        ; After processing the line, revert to old input source. We use this
        ; to compile high-level Forth words and user-defined words during
        ; start up and cold boot. In contrast to ACCEPT, we need to, uh,
        ; accept more than 255 characters here, even though it's a pain in
        ; the 8-bit.
        ; """
.scope
xt_evaluate:
                jsr underflow_2

                ; Clear the flag to zero BLK.  Only LOAD will set the flag,
                ; and will set the block number.
                stz tmp1

                ; If u is zero (which can happen a lot for the user-defined
                ; words), just leave again
                lda 0,x
                ora 1,x
                bne _got_work

                inx
                inx
                inx
                inx

                bra _done

; Special entry point for LOAD to bypass the zeroing of BLK.
load_evaluate_start:
_got_work:
                ; Save the current value of BLK on the return stack.
                ldy #blk_offset+1
                lda (up),y
                pha
                dey
                lda (up),y
                pha

                ; See if we should zero BLK.
                lda tmp1
                bne _nozero

                ; Set BLK to zero.
                ; lda #0        ; A is already zero from loading tmp1
                sta (up),y
                iny
                sta (up),y

_nozero:
                ; Save the input state to the Return Stack
                jsr xt_input_to_r

                ; set SOURCE-ID to -1
                lda #$ff
                sta insrc
                sta insrc+1

                ; set >IN to zero
                stz toin
                stz toin+1

                ; move TOS and NOS to input buffers
                lda 0,x
                sta ciblen
                lda 1,x
                sta ciblen+1

                lda 2,x
                sta cib
                lda 3,x
                sta cib+1

                inx             ; A clean stack is a clean mind
                inx
                inx
                inx

                jsr interpret   ; ( -- )

                ; restore variables
                jsr xt_r_to_input

                ; Restore BLK from the return stack.
                ldy #blk_offset
                pla
                sta (up),y
                iny
                pla
                sta (up),y

_done:
z_evaluate:     rts
.scend


; ## FORTH_WORDLIST ( -- u ) "WID for the Forth Wordlist"
; ## "forth-wordlist"  auto  ANS search
        ; """https://forth-standard.org/standard/search/FORTH-WORDLIST"""
        ; This is a dummy entry, the actual code is shared with ZERO.


; ## GET_CURRENT ( -- wid ) "Get the id of the compilation wordlist"
; ## "get-current" auto ANS search
        ; """https://forth-standard.org/standard/search/GET-CURRENT"""
.scope
xt_get_current:
                ; This is a little different than some of the variables
                ; in the user area as we want the value rather than
                ; the address.
                dex
                dex
                ldy #current_offset
                lda (up),y
                sta 0,x         ; CURRENT is a byte variable
                stz 1,x         ; so the MSB is zero.

z_get_current:  rts
.scend


; ## GET_ORDER ( -- wid_n .. wid_1 n) "Get the current search order"
; ## "get-order" auto ANS search
        ; """https://forth-standard.org/standard/search/GET-ORDER"""
.scope
xt_get_order:
                ; Get #ORDER - the number of wordlists in the search order.
                ldy #num_order_offset
                lda (up),y
                sta tmp1
                beq _done       ; If zero, there are no wordlists.

_loop:
                ; Count down towards the front of the list.
                ; By decrementing first, we also turn the length into an offset.
                dec tmp1        ; Count down by bytes.

                ; Get a pointer to the current wordlist, working back to front.
                lda #search_order_offset
                clc
                adc tmp1
                tay

                ; Put that wordlist id on the stack.
                dex
                dex
                lda (up),y
                sta 0,x         ; Search order array is bytes, so
                stz 1,x         ; put a zero in the high byte.

                ; See if that was the last one to process (first in the list).
                lda #0
                cmp tmp1
                bne _loop

_done:
                ; Put the number of items on the stack.
                dex
                dex
                ldy #num_order_offset
                lda (up),y
                sta 0,x
                stz 1,x         ; We only support 8 wordlists.

z_get_order:    rts
.scend


; ## GREATER_THAN ( n n -- f ) "See if NOS is greater than TOS"
; ## ">"  auto  ANS core
        ; """https://forth-standard.org/standard/core/more"""
.scope
xt_greater_than:
                jsr underflow_2

                ldy #0          ; default false
                jsr compare_16bit

                ; for signed numbers, NOS>TOS gives us Z=0 and N=1
                beq _false
                bpl _false

                ; true
                dey
_false:
                tya

                inx
                inx
                sta 0,x
                sta 1,x

z_greater_than: rts
.scend


; ## HERE ( -- addr ) "Put Compiler Pointer on Data Stack"
; ## "here"  auto  ANS core
        ; """https://forth-standard.org/standard/core/HERE
        ; This code is also used by the assembler directive ARROW
        ; ("->") though as immediate"""
xt_here:
xt_asm_arrow:
                dex
                dex
                lda cp
                sta 0,x
                lda cp+1
                sta 1,x

z_asm_arrow:
z_here:         rts


; ## HEX ( -- ) "Change base radix to hexadecimal"
; ## "hex"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/HEX"""
xt_hex:
                lda #16
                sta base
                stz base+1              ; paranoid

z_hex:          rts


; ## HEXSTORE ( addr1 u1 addr2 -- u2 ) "Store a list of numbers"
; ## "hexstore"  auto  Tali
        ; """Given a string addr1 u1 with numbers in the current base seperated
        ; by spaces, store the numbers at the address addr2, returning the
        ; number of elements. Non-number elements are skipped, an zero-length
        ; string produces a zero output.
        ; """
.scope
xt_hexstore:
                jsr underflow_3

                jsr xt_dup              ; Save copy of original address
                jsr xt_two_to_r         ; ( addr1 u1 ) ( R: addr2 addr2 )

_loop:
                ; Loop until string is totally consumed
                lda 0,x
                ora 1,x
                beq _done

                jsr xt_cleave           ; ( addr1 u1 addr3 u3 ) ( R: addr2 addr2 )

                ; Prepare the conversion of the number.
                jsr xt_two_to_r
                jsr xt_zero
                jsr xt_zero
                jsr xt_two_r_from       ; ( addr1 u1 0 0 addr3 u3 ) ( R: addr2 addr2 )
                jsr xt_to_number        ; ( addr1 u1 n n addr4 u4 ) ( R: addr2 addr2 )

                ; If u4 is not zero, we have leftover chars and have to do
                ; things differently
                lda 0,x
                ora 1,x
                bne _have_chars_left

                ; Normal case, this number is all done
                jsr xt_two_drop         ; ( addr1 u1 n n ) ( R: addr2 addr2 )
                jsr xt_d_to_s           ; ( addr1 u1 n ) ( R: addr2 addr2 )

                ; Store the new value
                jsr xt_r_fetch          ; ( addr1 u1 n addr2 ) ( R: addr2 addr2 )
                jsr xt_c_store          ; ( addr1 u1 ) ( R: addr2 addr2 )

                ; Increase counter
                jsr xt_r_from           ; R>
                jsr xt_one_plus         ; 1+
                jsr xt_to_r             ; >R ( addr1 u1 ) ( R: addr2+1 addr2 )
                bra _loop

_have_chars_left:
                ; Pathological case: Drop the rest of this number off the stack
                ; and continue with the next word. Doesn't print a warning. We
                ; need to drop four cells, that is, eight bytes
                txa
                clc
                adc #8
                tax
                bra _loop

_done:
                ; Clean up return stack and calculate number of chars stored
                inx
                inx
                inx
                inx                     ; 2DROP

                jsr xt_two_r_from       ; ( addr2+n addr2 )
                jsr xt_swap
                jsr xt_minus            ; ( n )

z_hexstore:     rts
.scend


; ## HOLD ( char -- ) "Insert character at current output"
; ## "hold"  auto  ANS core
        ; """https://forth-standard.org/standard/core/HOLD
        ; Insert a character at the current position of a pictured numeric
        ; output string on
        ; https://github.com/philburk/pforth/blob/master/fth/numberio.fth
        ;
        ; Forth code is : HOLD  -1 HLD +!  HLD @ C! ;  We use the the internal
        ; variable tohold instead of HLD.
        ; """
xt_hold:
                jsr underflow_1

                lda tohold
                bne +
                dec tohold+1
*
                dec tohold

                lda 0,x
                sta (tohold)
                inx
                inx

z_hold:         rts


; ## I ( -- n )(R: n -- n)  "Copy loop counter to stack"
; ## "i"  auto  ANS core
        ; """https://forth-standard.org/standard/core/I
        ; Note that this is not the same as R@ because we use a fudge
        ; factor for loop control; see the Control Flow section of the
        ; manual for details.
        ;
        ; We should make this native compile for speed.
        ; """
.scope
xt_i:
                dex
                dex

                ; Get the fudged index off of the top of the stack. It's
                ; easier to do math on the stack directly than to pop and
                ; push stuff around
                stx tmpdsp
                tsx

                sec
                lda $0101,x     ; LSB
                sbc $0103,x
                tay

                lda $0102,x     ; MSB
                sbc $0104,x

                ldx tmpdsp

                sta 1,x         ; MSB of de-fudged index
                sty 0,x         ; LSB of de-fudged index

z_i:            rts
.scend


; ## IF (C: -- orig) (flag -- ) "Conditional flow control"
; ## "if"  auto  ANS core
        ; """http://forth-standard.org/standard/core/IF"""
.scope
xt_if:
                ; Compile a 0BRANCH
                ldy #>zero_branch_runtime
                lda #<zero_branch_runtime
                jsr cmpl_subroutine

                ; Put the origination address on the stack for else/then
                jsr xt_here

                ; Stuff zero in for the branch address right now.
                ; THEN or ELSE will fix it later.
                jsr xt_zero
                jsr xt_comma
z_if:           rts
.scend

zero_branch_runtime:
        ; """In some Forths, this is called (0BRANCH). Tali Forth originally
        ; included 0BRANCH as a high-level word that inserted this code at
        ; runtime.
        ; """
.scope
                ; We use the return value on the 65c02 stack to determine
                ; where we want to return to.
                pla
                sta tmpbranch
                pla
                sta tmpbranch+1

                ; See if the flag is zero, which is the whole purpose of
                ; this all
                lda 0,x
                ora 1,x
                beq _zero

                ; Flag is TRUE, so we skip over the next two bytes. This is
                ; the part between IF and THEN
                lda tmpbranch   ; LSB
                clc
                adc #2
                sta tmp1
                lda tmpbranch+1 ; MSB
                adc #0          ; For carry
                sta tmp1+1

                bra _done

_zero:
                ; Flag is FALSE (0) so we take the jump to the address given in
                ; the next two bytes. However, the address points to the last
                ; byte of the JSR instruction, not to the next byte afterwards
                ldy #1
                lda (tmpbranch),y
                sta tmp1
                iny
                lda (tmpbranch),y
                sta tmp1+1

                ; Now we have to subtract one byte from the address
                ; given because of the way the 6502 calculates RTS
                lda tmp1
                bne +
                dec tmp1+1
*
                dec tmp1

_done:
                ; However we got here, tmp1 has the value we push to jump
                ; to
                lda tmp1+1
                pha             ; MSB first
                lda tmp1
                pha

                ; clean up the stack and jump
                inx
                inx

                rts
.scend


; ## IMMEDIATE ( -- ) "Mark most recent word as IMMEDIATE"
; ## "immediate"  auto  ANS core
        ; """https://forth-standard.org/standard/core/IMMEDIATE
        ; Make sure the most recently defined word is immediate. Will only
        ; affect the last word in the dictionary. Note that if the word is
        ; defined in ROM, this will have no affect, but will not produce an
        ; error message.
        ; """
xt_immediate:
                jsr current_to_dp
                ldy #1          ; offset for status byte
                lda (dp),y
                ora #IM        ; make sure bit 7 is set
                sta (dp),y

z_immediate:    rts


; ## INPUT ( -- addr ) "Return address of input vector"
; ## "input" tested Tali Forth
.scope
xt_input:
                dex
                dex
                lda #<input
                sta 0,x
                lda #>input
                sta 1,x

z_input:        rts
.scend


; ## INPUT_TO_R ( -- ) ( R: -- n n n n ) "Save input state to the Return Stack"
; ## "input>r"  tested  Tali Forth
   	; """Save the current input state as defined by insrc, cib, ciblen, and
        ; toin to the Return Stack. Used by EVALUTE.
        ;
        ; The naive way of doing
        ; this is to push each two-byte variable to the stack in the form of
        ;
        ;       lda insrc
        ;       pha
        ;       lda insrc+1
        ;       pha
        ;
        ; for a total of 24 byte of instruction in one direction and later
        ; a further 24 bytes to reverse the process. We shorten this at the
        ; cost of some speed by assuming the four variables are grouped
        ; together on the Zero Page and start with insrc (see definitions.asm
        ; for details). The reverse operation is r_to_input. These words must
        ; be flagged as Never Native. Uses tmp1
        ; """
.scope
xt_input_to_r:
                ; We arrive here with the return address on the top of the
                ; 65c02's stack. We need to move it out of the way first
                pla
                sta tmp1
                pla
                sta tmp1+1

                ; This assumes that insrc is the first of eight bytes and
                ; toin+1 the last in the sequence we want to save from the Zero
                ; Page.
                ldy #7
_loop:
                lda insrc,y     ; insrc+7 is toin+1
                pha
                dey
                bpl _loop

                ; Restore address for return jump
                lda tmp1+1
                pha
                lda tmp1
                pha

z_input_to_r: 	rts
.scend


; ## INT_TO_NAME ( xt -- nt ) "Get name token from execution token"
; ## "int>name"  auto  Tali Forth
        ; """www.complang.tuwien.ac.at/forth/gforth/Docs-html/Name-token.html
        ; This is called >NAME in Gforth, but we change it to
        ; INT>NAME to match NAME>INT
        ; """
.scope
xt_int_to_name:
                jsr underflow_1

                ; Unfortunately, to find the header, we have to walk through
                ; all of the wordlists. We are running out of tmp variables.
                ; (I'm assuming there is a reason this is avoiding tmp1) so
                ; hold the current wordlist on the data stack. This searches
                ; all of the wordlists in id order.
                dex
                dex
                stz 0,x
                stz 1,x

_wordlist_loop:
                ; A needs to have the current wordlist id in it at
                ; the top of this loop.
                lda 0,x                 ; Get the current wordlist.

                ; Get the DP for that wordlist.
                asl                     ; Turn offset into cells offset.
                clc
                adc #wordlists_offset
                tay
                lda (up),y              ; Save the DP for this wordlist
                sta tmp2                ; into tmp2
                iny
                lda (up),y
                sta tmp2+1

                ; Check for an empty wordlist (DP will be 0)
                lda tmp2
                ora tmp2+1
                beq _next_wordlist

                lda 2,x         ; Target xt is now behind wordlist id.
                sta tmp3        ; Save target xt in tmp3
                lda 3,x
                sta tmp3+1

_loop:
                ldy #4          ; xt is four bytes down
                lda (tmp2),y    ; LSB of xt of current nt
                cmp tmp3
                bne _no_match

                ; LSB is the same, now check MSB
                iny
                lda (tmp2),y    ; MSB of xt of current nt
                cmp tmp3+1
                beq _match

_no_match:
                ; no match, so we need to get the next word. Next nt is two
                ; bytes down
                clc
                lda tmp2
                adc #2
                sta tmp2
                lda tmp2+1
                adc #0          ; only care about carry
                sta tmp2+1

                ldy #0
                lda (tmp2),y
                pha
                iny
                ora (tmp2),y
                beq _zero

                ; Not zero continue
                lda (tmp2),y
                sta tmp2+1
                pla
                sta tmp2
                bra _loop

_zero:
                ; if next word is zero, the xt has no nt in this wordlist
                pla             ; Leftover from above loop

_next_wordlist:
                ; Move on to the next wordlist.
                lda 0,x
                inc
                sta 0,x
                cmp #max_wordlists
                bne _wordlist_loop

                ; We didn't find it in any of the wordlists.
                ; Remove the wordlist id from the stack.
                inx
                inx

                ; We return a zero to indicate that we didn't find it.
                stz 0,x
                stz 1,x
                bra z_int_to_name

_match:
                ; We found it. Remove wordlist id from stack.
                inx
                inx

                ; It's a match! Replace TOS with nt
                lda tmp2
                sta 0,x
                lda tmp2+1
                sta 1,x

z_int_to_name:  rts
.scend


; ## INVERT ( n -- n ) "Complement of TOS"
; ## "invert"  auto  ANS core
        ; """https://forth-standard.org/standard/core/INVERT"""
xt_invert:
                jsr underflow_1

                lda #$FF
                eor 0,x         ; LSB
                sta 0,x

                lda #$FF
                eor 1,x         ; MSB
                sta 1,x

z_invert:       rts


; ## IS ( xt "name" -- ) "Set named word to execute xt"
; ## "is"  auto  ANS core ext
        ; """http://forth-standard.org/standard/core/IS"""
.scope
xt_is:
                ; This is a state aware word with differet behavior
                ; when used while compiling vs interpreting.
                ; Check STATE
                lda state
                ora state+1
                beq _interpreting

_compiling:
                ; Run ['] to compile the xt of the next word as a literal.
                jsr xt_bracket_tick

                ; Postpone DEFER! by compiling a JSR to it.
                ldy #>xt_defer_store
                lda #<xt_defer_store
                jsr cmpl_subroutine

                bra _done

_interpreting:
                jsr xt_tick
                jsr xt_defer_store
_done:
z_is:           rts
.scend


; ## J ( -- n ) (R: n -- n ) "Copy second loop counter to stack"
; ## "j"  auto  ANS core
        ; """https://forth-standard.org/standard/core/J
        ; Copy second loop counter from Return Stack to stack. Note we use
        ; a fudge factor for loop control; see the Control Flow section of
        ; the manual for more details.
        ; At this point, we have the "I" counter/limit and the LEAVE address
        ; on the stack above this (three entries), whereas the ideal Forth
        ; implementation would just have two.
        ;
        ; Make this native compiled for speed
        ; """
.scope
xt_j:
                dex
                dex

                ; Get the fudged index off from the stack. It's easier to
                ; do math on the stack directly than to pop and push stuff
                ; around
                stx tmpdsp
                tsx

                sec
                lda $0107,x     ; LSB
                sbc $0109,x
                tay

                lda $0108,x     ; MSB
                sbc $010A,x

                ldx tmpdsp

                sta 1,x         ; MSB of de-fudged index
                sty 0,x         ; LSB of de-fudged index

z_j:            rts
.scend


; ## KEY ( -- char ) "Get one character from the input"
; ## "key"  tested  ANS core
xt_key:
        ; """https://forth-standard.org/standard/core/KEY
        ; Get a single character of input from the vectored
        ; input without echoing.
        ; """
                jsr key_a               ; returns char in A

                dex
                dex
                sta 0,x
                stz 1,x

z_key:          rts

key_a:
        ; The 65c02 doesn't have a JSR (ADDR,X) instruction like the
        ; 65816, so we have to fake the indirect jump to vector it.
        ; This is depressingly slow. We use this routine internally
        ; to avoid manipulating the Data Stack when we just want a
        ; character
                jmp (input)             ; JSR/RTS


; ## LATESTNT ( -- nt ) "Push most recent nt to the stack"
; ## "latestnt"  auto  Tali Forth
        ; """www.complang.tuwien.ac.at/forth/gforth/Docs-html/Name-token.html
        ; The Gforth version of this word is called LATEST
        ; """
xt_latestnt:
                dex
                dex

                jsr current_to_dp

                lda dp
                sta 0,x
                lda dp+1
                sta 1,x

z_latestnt:     rts


; ## LATESTXT ( -- xt ) "Push most recent xt to the stack"
; ## "latestxt"  auto  Gforth
        ; """http://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Anonymous-Definitions.html"""
xt_latestxt:
                jsr xt_latestnt         ; ( nt )
                jsr xt_name_to_int      ; ( xt )

z_latestxt:     rts


; ## LEAVE ( -- ) "Leave DO/LOOP construct"
; ## "leave"  auto  ANS core
        ; """https://forth-standard.org/standard/core/LEAVE
        ; Note that this does not work with anything but a DO/LOOP in
        ; contrast to other versions such as discussed at
        ; http://blogs.msdn.com/b/ashleyf/archive/2011/02/06/loopty-do-i-loop.aspx
        ;
        ;       : LEAVE POSTPONE BRANCH HERE SWAP 0 , ; IMMEDIATE COMPILE-ONLY
        ; See the Control Flow section in the manual for details of how this works.
        ; This must be native compile and not IMMEDIATE
        ; """
.scope
xt_leave:
                ; We dump the limit/start entries off the Return Stack
                ; (four bytes)
                pla
                pla
                pla
                pla

                rts             ; this must be compiled, so keep before z_leave
z_leave:                        ; not reached, not compiled
.scend


; ## LEFT_BRACKET ( -- ) "Enter interpretation state"
; ## "["  auto  ANS core
        ; """https://forth-standard.org/standard/core/Bracket
        ; This is an immediate and compile-only word
        ; """
xt_left_bracket:
                stz state
                stz state+1

z_left_bracket: rts


; ## LESS_NUMBER_SIGN ( -- ) "Start number conversion"
; ## "<#"  auto  ANS core
        ; """https://forth-standard.org/standard/core/num-start
        ; Start the process to create pictured numeric output.
        ;
        ; The new
        ; string is constructed from back to front, saving the new character
        ; at the beginning of the output string. Since we use PAD as a
        ; starting address and work backward (!), the string is constructed
        ; in the space between the end of the Dictionary (as defined by CP)
        ; and the PAD. This allows us to satisfy the ANS Forth condition that
        ; programs don't fool around with the PAD but still use its address.
        ; Based on pForth
        ; http://pforth.googlecode.com/svn/trunk/fth/numberio.fth
        ; pForth is in the pubic domain. Forth is : <# PAD HLD ! ; we use the
        ; internal variable tohold instead of HLD.
        ; """
xt_less_number_sign:
                jsr xt_pad      ; ( addr )

                lda 0,x
                sta tohold
                lda 1,x
                sta tohold+1

                inx
                inx

z_less_number_sign:
                rts

; ## LESS_THAN ( n m -- f ) "Return true if NOS < TOS"
; ## "<"  auto  ANS core
        ; """https://forth-standard.org/standard/core/less"""
.scope
xt_less_than:
                jsr underflow_2

                ldy #0          ; default false
                jsr compare_16bit

                ; for signed numbers, NOS < TOS if Z=0 and N=0
                beq _false
                bmi _false

                ; true
                dey
_false:
                tya

                inx
                inx
                sta 0,x
                sta 1,x

z_less_than:    rts
.scend


; ## LIST ( scr# -- ) "List the given screen"
; ## "list"  tested  ANS block ext
        ; """https://forth-standard.org/standard/block/LIST"""
.scope
xt_list:
                jsr underflow_1

                ; Save the screen number in SCR
                jsr xt_scr
                jsr xt_store

                ; Use L from the editor-wordlist to display the screen.
                jsr xt_editor_l

z_list:         rts
.scend


; ## LITERAL ( n -- ) "Store TOS to be push on stack during runtime"
; ## "literal"  auto  ANS core
        ; """https://forth-standard.org/standard/core/LITERAL
        ; Compile-only word to store TOS so that it is pushed on stack
        ; during runtime. This is a immediate, compile-only word. At runtime,
        ; it works by calling literal_runtime by compling JSR LITERAL_RT.
        ;
        ; Note the cmpl_ routines use TMPTOS
        ; """
xt_literal:
                jsr underflow_1

                ldy #>literal_runtime
                lda #<literal_runtime
                jsr cmpl_subroutine

                ; Compile the value that is to be pushed on the Stack during
                ; runtime
                jsr xt_comma

z_literal:      rts

literal_runtime:
.scope
                ; During runtime, we push the value following this word back
                ; on the Data Stack. The subroutine jump that brought us
                ; here put the address to return to on the Return Stack -
                ; this points to the data we need to get. This routine is
                ; also called (LITERAL) in some Forths
                dex
                dex

            	; The 65c02 stores <RETURN-ADDRESS>-1 on the Return Stack,
                ; so we are actually popping the address-1 of the literal
                pla             ; LSB
                sta tmp1
                pla             ; MSB
                sta tmp1+1

                ; Fetch the actual literal value and push it on Data stack
                ldy #1
                lda (tmp1),y    ; LSB
                sta 0,x
                iny
                lda (tmp1),y    ; MSB
                sta 1,x

                ; Adjust return address and push back on the Return Stack
                tya
                clc
                adc tmp1
                tay
                lda tmp1+1
                adc #0
                pha
                phy

                rts
.scend


; ## LOAD ( scr# -- ) "Load the Forth code in a screen/block"
; ## "load"  auto  ANS block
        ; """https://forth-standard.org/standard/block/LOAD
        ;
        ; Note: LOAD current works because there is only one buffer.
        ; If/when multiple buffers are supported, we'll have to deal
        ; with the fact that it might re-load the old block into a
        ; different buffer.
        ; """
.scope
xt_load:
                jsr underflow_1

                ; Save the current value of BLK on the return stack.
                ldy #blk_offset+1
                lda (up),y
                pha
                dey
                lda (up),y
                pha

                ; Set BLK to the given block/screen number.
                lda 0,x
                sta (up),y
                iny
                lda 1,x
                sta (up),y

                ; Load that block into a buffer
                jsr xt_block

                ; Put 1024 on the stack for the screen length.
                dex
                dex
                lda #4
                sta 1,x
                stz 0,x

                ; Jump to a special evluate target. This bypasses the underflow
                ; check and skips the zeroing of BLK.
                jsr load_evaluate

                ; Restore the value of BLK from before the LOAD command.
                ldy #blk_offset
                pla
                sta (up),y
                iny
                pla
                sta (up),y

                ; If BLK is not zero, read it back into the buffer.
                ; A still has MSB
                dey
                ora (up),y
                beq _done

                ; The block needs to be read back into the buffer.
                dex
                dex
                ldy #blk_offset
                lda (up),y
                sta 0,x
                iny
                lda (up),y
                sta 1,x
                jsr xt_block

                ; Drop the buffer address.
                inx
                inx

_done:
z_load:         rts
.scend


; ## LOOP ( -- ) "Finish loop construct"
; ## "loop"  auto  ANS core
        ; """https://forth-standard.org/standard/core/LOOP
        ; Compile-time part of LOOP. This does nothing more but push 1 on
        ; the stack and then call +LOOP.
        ;
        ; In Forth, this is
        ;       : LOOP  POSTPONE 1 POSTPONE (+LOOP) , POSTPONE UNLOOP ;
        ;       IMMEDIATE ; COMPILE-ONLY
        ; """
xt_loop:
                ; Have the finished word push 1 on the stack
                ldy #>xt_one
                lda #<xt_one
                jsr cmpl_subroutine     ; drop through to +LOOP


; ## PLUS_LOOP ( -- ) "Finish loop construct"
; ## "+loop"  auto  ANS core
        ; """https://forth-standard.org/standard/core/PlusLOOP
        ;
        ; Compile-time part of +LOOP, also used for LOOP. Is usually
        ;       : +LOOP POSTPONE (+LOOP) , POSTPONE UNLOOP ; IMMEDIATE
        ;       COMPILE-ONLY
        ; in Forth. LOOP uses this routine as well. We jump here with the
        ; address for looping as TOS and the address for aborting the loop
        ; (LEAVE) as the second double-byte entry on the Return Stack (see
        ; DO and the Control Flow section of the manual for details).
        ; """
.scope
xt_plus_loop:
                ; Compile the run-time part. We do this with a short loop
                ; and not a call to COMPILE, because it has to be natively
                ; coded anyway.
                ldy #plus_loop_runtime_end-plus_loop_runtime
                phy             ; save counter to adjust CP
*
                lda plus_loop_runtime,y
                sta (cp),y
                dey
                bpl -

                ; Adjust CP
                pla
                clc
                adc cp
                sta cp
                lda cp+1
                adc #0          ; only need carry
                sta cp+1

                ; The address we need to loop back to is TOS. Store it so
                ; the runtime part of +LOOP jumps back up there
                jsr xt_comma

                ; Compile an UNLOOP for when we're all done. This is a series
                ; of six PLA, so we just do it here instead jumping around
                ; all over the place
                lda #$68                ; opcode for PLA
                ldy #6
*
                sta (cp),y
                dey
                bpl -

                ; Adjust CP
                lda #6
                clc
                adc cp
                sta cp
                lda cp+1
                adc #0                  ; only need carry
                sta cp+1

                ; Complete compile of DO/?DO by replacing the six
                ; dummy bytes by PHA instructions. The address where
                ; they are located is on the Data Stack
                lda 0,x
                sta tmp1
                lda 1,x
                sta tmp1+1
                inx
                inx

                ; Because of the way that CP works, we don't have to save
                ; CP, but CP-1
                lda cp
                sec
                sbc #1
                sta tmp2
                lda cp+1
                sbc #0
                sta tmp2+1

                ; now compile this in the DO/?DO routine
                ldy #0

                lda #$A9        ; opcode for LDA immediate
                sta (tmp1),y
                iny
                lda tmp2+1      ; MSB
                sta (tmp1),y
                iny
                lda #$48        ; Opcode for PHA
                sta (tmp1),y
                iny

                lda #$A9        ; opcode for LDA immediate
                sta (tmp1),y
                iny
                lda tmp2        ; LSB
                sta (tmp1),y
                iny
                lda #$48        ; Opcode for PHA
                sta (tmp1),y
z_loop:
z_plus_loop:    rts
.scend

plus_loop_runtime:
        ; """Runtime compile for loop control. This is used for both +LOOP and
        ; LOOP which are defined at high level. Note we use a fudge factor for
        ; loop control so we can test with the Overflow Flag. See
        ; the Control Flow section of the manual for details.
        ; The step value is TOS in the loop. This
        ; must always be native compiled. In some Forths, this is a separate
        ; word called (+LOOP) or (LOOP)
        ; """
.scope
                clc
                pla             ; LSB of index
                adc 0,x         ; LSB of step
                tay             ; temporary storage of LSB

                clv
                pla             ; MSB of index
                adc 1,x         ; MSB of step
                pha             ; put MSB of index back on stack

                tya             ; put LSB of index back on stack
                pha

                inx             ; dump step from TOS
                inx

                ; If V flag is set, we're done looping and continue
                ; after the +LOOP instruction
                bvs _hack+3     ; skip over JMP instruction

_hack:          ; This is why this routine must be natively compiled: We
                ; compile the opcode for JMP here without an address to
                ; go to, which is added by the next next instruction of
                ; LOOP/+LOOP during compile time
                .byte $4C
.scend
plus_loop_runtime_end:


; ## LSHIFT ( x u -- u ) "Shift TOS left"
; ## "lshift"  auto  ANS core
        ; """https://forth-standard.org/standard/core/LSHIFT"""
.scope
xt_lshift:
                jsr underflow_2

                ; max shift 16 times
                lda 0,x
                and #%00001111
                beq _done

                tay

_loop:
                asl 2,x
                rol 3,x
                dey
                bne _loop

_done:
                inx
                inx

z_lshift:       rts
.scend


; ## M_STAR ( n n -- d ) "16 * 16 --> 32"
; ## "m*"  auto  ANS core
        ; """https://forth-standard.org/standard/core/MTimes
        ; Multiply two 16 bit numbers, producing a 32 bit result. All
        ; values are signed. Adapted from FIG Forth for Tali Forth.
        ;
        ; The original Forth is : M* OVER OVER XOR >R ABS SWAP ABS UM* R> D+- ;
        ; with  : D+- O< IF DNEGATE THEN ;
        ; """
.scope
xt_m_star:
                jsr underflow_2

                ; figure out the sign
                lda 1,x         ; MSB of n1
                eor 3,x         ; MSB of n2

                ; UM* uses all kinds of temporary variables so we don't
                ; risk a conflict but just take the cycle hit and push
                ; this to the stack
                pha

                ; get the absolute value of both numbers so we can feed
                ; them to UM*, which does the real work
                jsr xt_abs
                jsr xt_swap
                jsr xt_abs

                jsr xt_um_star          ; ( d )

                ; handle the sign
                pla
                bpl _done

                jsr xt_dnegate
_done:
z_m_star:       rts
.scend


; ## MARKER ( "name" -- ) "Create a deletion boundry"
; ## "marker"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/MARKER
        ; This word replaces FORGET in earlier Forths. Old entries are not
        ; actually deleted, but merely overwritten by restoring CP and DP.
        ; Run the named word at a later time to restore all of the wordlists
        ; to their state when the word was created with marker.  Any words
        ; created after the marker (including the marker) will be forgotten.
        ;
        ; To do this, we want to end up with something that jumps to a
        ; run-time component with a link to the original CP and DP values:
        ;
        ;       jsr marker_runtime
        ;       <Original CP MSB>
        ;       <Original CP LSB>
        ;       <Original DP MSB> ( for CURRENT wordlist )
        ;       <Original DP LSB>
        ;       < USER variables from offset 4 to 39 >
        ;
        ;       The user variables include:
        ;       CURRENT (byte variable)
        ;       <All wordlists> (currently 12) (cell array)
        ;       <#ORDER> (byte variable)
        ;       <All search order> (currently 9) (byte array)
        ;
        ; This code uses tmp1 and tmp2
        ; """
.scope
xt_marker:
                ; Before we do anything, we need to save CP, which
                ; after all is the whole point of this operation. CREATE
                ; uses tmp1 and tmp2, so we take the speed hit and push stuff
                ; to the stack
                jsr current_to_dp

                lda dp
                pha
                lda dp+1
                pha

                lda cp
                pha
                lda cp+1
                pha

                jsr xt_create

                ; By default, CREATE installs a subroutine jump to DOVAR, which
                ; we have to replace by a jump to marker_runtime. We back up
                ; two bytes and then overwrite the address
                lda cp          ; LSB
                sec
                sbc #2
                sta cp

                lda cp+1        ; MSB
                sbc #0          ; we only care about the borrow
                sta cp+1

                ; Add the address of the runtime component
                ldy #>marker_runtime
                lda #<marker_runtime
                jsr cmpl_word

                ; Add original CP as payload
                ply                     ; MSB
                pla                     ; LSB
                jsr cmpl_word

                ; Add original DP as payload
                ply                     ; MSB
                pla                     ; LSB
                jsr cmpl_word

                ; Add the user variables for the wordlists and search order.
                ; We're compiling them in byte order.
                ldy #4                  ; Start at CURRENT
_marker_loop:
                lda (up),y
                jsr cmpl_a
                iny
                tya
                cmp #40                 ; One past the end of the search order.
                bne _marker_loop

z_marker:       rts
.scend

.scope
marker_runtime:
        ; """Restore Dictionary and memory (DP and CP) to where the were
        ; when this marker was defined. We arrive here with the return
        ; address on the Return Stack in the usual 65c02 format
        ; """

                ; Get the address of the string address off the stack and
                ; increase by one because of the RTS mechanics
                pla
                sta tmp1        ; LSB of address
                pla
                sta tmp1+1      ; MSB of address

                inc tmp1
                bne +
                inc tmp1+1
*
                ldy #0

                ; CP was stored first
                lda (tmp1),y
                sta cp
                iny
                lda (tmp1),y
                sta cp+1

                ; Next was DP
                iny
                lda (tmp1),y
                sta dp
                iny
                lda (tmp1),y
                sta dp+1

                ; Conveniently, the offset into both tmp1 and UP is 4
                ; to start restoring the wordlists and search order.
                ldy #4

_marker_restore_loop:
                ; Copy from the dictionary back on top of the wordlists
                ; and search order.
                lda (tmp1), y
                sta (up), y
                iny
                tya
                cmp #40                 ; One past the end of the search order.
                bne _marker_restore_loop

                jsr dp_to_current       ; Move the CURRENT DP back.

                ; The return instruction takes us back to the original caller
                rts
.scend


; ## MAX ( n n -- n ) "Keep larger of two numbers"
; ## "max"  auto  ANS core
        ; """https://forth-standard.org/standard/core/MAX
        ; Compare TOS and NOS and keep which one is larger. Adapted from
        ; Lance A. Leventhal "6502 Assembly Language Subroutines". Negative
        ; Flag indicates which number is larger. See also
        ; http://6502.org/tutorials/compare_instructions.html and
        ; http://www.righto.com/2012/12/the-6502-overflow-flag-explained.html
        ; """
.scope
xt_max:
                jsr underflow_2

                ; Compare LSB. We do this first to set the carry flag
                lda 0,x         ; LSB of TOS
                cmp 2,x         ; LSB of NOS, this sets the carry

                lda 1,x         ; MSB of TOS
                sbc 3,x         ; MSB of NOS
                bvc _no_overflow

                ; handle overflow, because we use signed numbers
                eor #$80        ; complement negative flag

_no_overflow:
                ; if negative, NOS is larger and needs to be kept
                bmi _keep_nos

                ; move TOS to NOS
                lda 0,x
                sta 2,x
                lda 1,x
                sta 3,x

_keep_nos:
                inx
                inx

z_max:          rts
.scend


; ## MIN ( n n -- n ) "Keep smaller of two numbers"
; ## "min"  auto  ANS core
        ; """https://forth-standard.org/standard/core/MIN
        ; Adapted from Lance A. Leventhal "6502 Assembly Language
        ; Subroutines." Negative Flag indicateds which number is larger. See
        ; http://www.righto.com/2012/12/the-6502-overflow-flag-explained.html
        ; """
.scope
xt_min:
                jsr underflow_2

                ; compare LSB. We do this first to set the carry flag
                lda 0,x         ; LSB of TOS
                cmp 2,x         ; LSB of NOS, this sets carry

                lda 1,x         ; MSB of TOS
                sbc 3,x         ; MSB of NOS
                bvc _no_overflow

                ; handle overflow because we use signed numbers
                eor #$80

_no_overflow:
                ; if negative, NOS is larger and needs to be dumped
                bpl _keep_nos

                ; move TOS to NOS
                lda 0,x
                sta 2,x
                lda 1,x
                sta 3,x

_keep_nos:
                inx
                inx

z_min:          rts
.scend


; ## MINUS ( n n -- n ) "Subtract TOS from NOS"
; ## "-"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Minus"""
xt_minus:
                jsr underflow_2

                sec
                lda 2,x         ; LSB
                sbc 0,x
                sta 2,x

                lda 3,x         ; MSB
                sbc 1,x
                sta 3,x

                inx
                inx

z_minus:        rts


; ## MINUS_LEADING ( addr1 u1 -- addr2 u2 ) "Remove leading spaces"
; ## "-leading"  auto  Tali String
        ; """Remove leading whitespace. This is the reverse of -TRAILING
        ; """
.scope
xt_minus_leading:
                jsr underflow_2

_loop:
                ; Quit if we were given an empty string. This also terminates
                ; the main loop
                lda 0,x
                ora 1,x
                beq _done

                lda (2,x)               ; get first character
                jsr is_whitespace
                bcc _done

                ; It's whitespace, move one down
                jsr xt_one              ; ( addr u 1 )
                jsr xt_slash_string     ; ( addr+ u-1 )

                bra _loop
_done:
z_minus_leading:
                rts
.scend


; ## MINUS_TRAILING ( addr u1 -- addr u2 ) "Remove trailing spaces"
; ## "-trailing"  auto  ANS string
        ; """https://forth-standard.org/standard/string/MinusTRAILING
        ; Remove trailing spaces
        ; """
.scope
xt_minus_trailing:
                jsr underflow_2

                ; if length entry is zero, return a zero and leave the
                ; address part untouched
                lda 0,x         ; LSB of n
                ora 1,x         ; MSB of n
                beq _done

                ; Compute address of last char in tmp1 as
                ; addr + u1 - 1

                ; addr + u1
                clc
                lda 2,x         ; LSB of addr
                adc 0,x
                sta tmp1
                lda 3,x         ; MSB of addr
                adc 1,x
                sta tmp1+1

                ; - 1
                lda tmp1
                bne +
                dec tmp1+1
*
                dec tmp1

_loop:
                ; While spaces are found, move tmp1 backwards and
                ; decrease the count on the data stack.
                lda (tmp1)
                cmp #AscSP
                bne _done

                ; Move back one address.
                lda tmp1
                bne +
                dec tmp1+1
*
                dec tmp1

                ; Decrement count by one.
                lda 0,x
                bne +
                dec 1,x
*
                dec 0,x

                ; Check if there are any characters left.
                lda 0,x
                ora 1,x
                beq _done       ; Count has reached zero - we're done!

                bra _loop

_done:
z_minus_trailing:
                rts
.scend


; ## MOD ( n1 n2 -- n ) "Divide NOS by TOS and return the remainder"
; ## "mod"  auto  ANS core
        ; """https://forth-standard.org/standard/core/MOD
        ;
        ; The Forth definition of this word is  : MOD /MOD DROP ;
        ; so we just jump to xt_slash_mod and dump the actual result.
        ; """
xt_mod:
                jsr underflow_2

                jsr xt_slash_mod

                inx             ; DROP
                inx
z_mod:
                rts


; ## MOVE ( addr1 addr2 u -- ) "Copy bytes"
; ## "move"  auto  ANS core
        ; """https://forth-standard.org/standard/core/MOVE
        ; Copy u "address units" from addr1 to addr2. Since our address
        ; units are bytes, this is just a front-end for CMOVE and CMOVE>. This
        ; is actually the only one of these three words that is in the CORE
        ; set.
        ;
        ; This word must not be natively compiled.
        ; """
.scope
xt_move:
                ; We let CMOVE and CMOVE> check if there is underflow or
                ; we've been told to copy zero bytes

                ; compare MSB first
                lda 3,x                 ; MSB of addr2
                cmp 5,x                 ; MSB of addr1
                beq _lsb                ; wasn't helpful, move to LSB
                bcs _to_move_up         ; we want CMOVE>

                jmp xt_cmove            ; JSR/RTS

_lsb:
                ; MSB were equal, so do the whole thing over with LSB
                lda 2,x                 ; LSB of addr2
                cmp 4,x                 ; LSB of addr1
                beq _equal              ; LSB is equal as well
                bcs _to_move_up         ; we want CMOVE>

                jmp xt_cmove            ; JSR/RTS

_to_move_up:
                jmp xt_cmove_up         ; JSR/RTS
_equal:
                ; drop three entries from Data Stack
                txa
                clc
                adc #6
                tax

z_move:         rts
.scend


; ## NAME_TO_INT ( nt -- xt ) "Convert Name Token to Execute Token"
; ## "name>int"  tested  Gforth
        ; """See
        ; https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Name-token.html
        ; """
.scope
xt_name_to_int:
                jsr underflow_1

                ; The xt starts four bytes down from the nt
                lda 0,x
                clc
                adc #4
                sta tmp3

                lda 1,x
                bcc _done
                inc
_done:
                sta tmp3+1

                ldy #0
                lda (tmp3),y
                sta 0,x
                iny
                lda (tmp3),y
                sta 1,x

z_name_to_int:  rts
.scend


; ## NAME_TO_STRING ( nt -- addr u ) "Given a name token, return string of word"
; ## "name>string"  tested  Gforth
        ; """http://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Name-token.html"""
.scope
xt_name_to_string:
                jsr underflow_1

                dex
                dex

                ; the length of the string is the first byte of the
                ; header pointed to by nt
                lda (2,x)
                sta 0,x
                stz 1,x

                ; the string itself always starts eight bytes down
                lda 2,x         ; LSB
                clc
                adc #8
                tay
                lda 3,x         ; MSB
                adc #0          ; just need carry
                sta 3,x
                sty 2,x

z_name_to_string:
                rts
.scend

; ## NC_LIMIT ( -- addr ) "Return address where NC-LIMIT value is kept"
; ## "nc-limit"  tested  Tali Forth
.scope
xt_nc_limit:
                dex
                dex
                lda #<nc_limit
                sta 0,x
                lda #>nc_limit
                sta 1,x

z_nc_limit:     rts
.scend


; ## NEGATE ( n -- n ) "Two's complement"
; ## "negate"  auto  ANS core
        ; """https://forth-standard.org/standard/core/NEGATE"""
xt_negate:
                jsr underflow_1

        	lda #0
                sec
                sbc 0,x         ; LSB
                sta 0,x

                lda #0
                sbc 1,x         ; MSB
                sta 1,x

z_negate:       rts


; ## NEVER_NATIVE ( -- ) "Flag last word as never natively compiled"
; ## "never-native"  auto  Tali Forth
xt_never_native:
                jsr current_to_dp
                ldy #1          ; offset for status byte
                lda (dp),y
                ora #NN         ; Make sure NN flag is set
                and #$ff-AN     ; and AN flag is clear.
                sta (dp),y
z_never_native:
                rts


; ## NIP ( b a -- a ) "Delete NOS"
; ## "nip"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/NIP"""
xt_nip:
                jsr underflow_2

                lda 0,x         ; LSB
                sta 2,x
                lda 1,x         ; MSB
                sta 3,x

                inx
                inx

z_nip:          rts


; ## NOT_EQUALS ( n m -- f ) "Return a true flag if TOS != NOS"
; ## "<>"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/ne
        ;
        ; This is just a variant of EQUAL, we code it separately
        ; for speed.
        ; """
.scope
xt_not_equals:
                jsr underflow_2

                ldy #0                  ; default is true

                lda 0,x                 ; LSB
                cmp 2,x
                bne _not_equal

                ; LSB is equal
                lda 1,x                 ; MSB
                cmp 3,x
                bne _not_equal

                lda #$FF
                bra _done

_not_equal:
                dey                     ; drop thru to done

_done:
                tya
                inx
                inx
                sta 0,x
                sta 1,x

z_not_equals:   rts
.scend


; ## NOT_ROTE ( a b c -- c a b ) "Rotate upwards"
; ## "-rot"  auto  Gforth
        ; """http://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Data-stack.html"""
.scope
xt_not_rote:
                jsr underflow_3

                ldy 1,x         ; MSB first
                lda 3,x
                sta 1,x

                lda 5,x
                sta 3,x
                sty 5,x

                ldy 0,x         ; LSB second
                lda 2,x
                sta 0,x

                lda 4,x
                sta 2,x
                sty 4,x

z_not_rote:     rts
.scend


; ## NUMBER ( addr u -- u | d ) "Convert a number string"
; ## "number"  auto  Tali Forth
        ; """Convert a number string to a double or single cell number. This
        ; is a wrapper for >NUMBER and follows the convention set out in the
        ; "Forth Programmer's Handbook" (Conklin & Rather) 3rd edition p. 87.
        ; Based in part on the "Starting Forth" code
        ; https://www.forth.com/starting-forth/10-input-output-operators/
        ; Gforth uses S>NUMBER? and S>UNUMBER? which return numbers and a flag
        ; https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Number-Conversion.html
        ; Another difference to Gforth is that we follow ANS Forth that the
        ; dot to signal a double cell number is required to be the last
        ; character of the string.
        ;
        ; Number calls >NUMBER which in turn calls UM*,
        ; which uses tmp1, tmp2, and tmp3, so we can't use them here, which is
        ; a pain.
        ;"""
.scope
xt_number:
                jsr underflow_2

                ; we keep the flags for sign and double in tmpdsp because
                ; we've run out of temporary variables
                stz tmpdsp      ; flag for double
                stz tmpdsp+1    ; flag for minus

                ; If the first character is a minus, strip it off and set
                ; the flag
                lda (2,x)
                cmp #$2D        ; ASCII for "-"
                bne _check_dot

                ; It's a minus
                dec tmpdsp+1
                inc 2,x         ; start one character later
                bne +
                inc 3,x
*
                dec 0,x         ; decrease string length by one

_check_dot:
                ; If the last character is a dot, strip it off and set a
                ; flag. We can use tmptos as a temporary variable
                lda 2,x         ; LSB of address
                clc
                adc 0,x         ; length of string
                sta tmptos
                lda 3,x
                adc #0          ; only need carry
                sta tmptos+1

                ; tmptos now points to the first character after the string,
                ; but we need the last character
                lda tmptos
                bne +
                dec tmptos+1
*
                dec tmptos

                lda (tmptos)
                cmp #'.
                bne _main

                ; We have a dot, which means this is a double number. Flag
                ; the fact and reduce string length by one
                dec tmpdsp
                dec 0,x

_main:
                ; Set up stack for subroutine jump to >NUMBER, which means
                ; we have to go ( addr u --> ud addr u )
                dex
                dex
                dex
                dex

                lda 4,x         ; LSB of length
                sta 0,x
                stz 1,x         ; MSB, max length 255 chars

                lda 6,x         ; LSB of address
                sta 2,x
                lda 7,x         ; MSB of address
                sta 3,x

                stz 4,x         ; clear space for ud
                stz 5,x
                stz 6,x
                stz 7,x

                jsr xt_to_number        ; (ud addr u -- ud addr u )

                ; test length of returned string, which should be zero
                lda 0,x
                beq _all_converted

                ; Something went wrong, we still have characters left over,
                ; so we print an error and abort. If the NUMBER was called
                ; by INTERPRET, we've already checked for Forth words, so
                ; we're in deep trouble one way or another
                lda #$3E        ; ASCII for ">"
                jsr emit_a
                jsr xt_type
                lda #$3C        ; ASCII for "<"
                jsr emit_a
                jsr xt_space

                lda #err_syntax
                jmp error

_all_converted:
                ; We can drop the string info
                inx
                inx
                inx
                inx

                ; We have a double-cell number on the Data Stack that might
                ; actually have a minus and might actually be single-cell
                lda tmpdsp      ; flag for double
                beq _single

                ; Set status bit 5 to indicate this is a double number
                lda #%00100000
                tsb status

                ; This is a double cell number. If it had a minus, we'll have
                ; to negate it
                lda tmpdsp+1
                beq _done       ; no minus, all done

                jsr xt_dnegate

                bra _done

_single:
                ; This is a single number, so we just drop the top cell
                inx
                inx

                ; Clear status bit 5 to indicate this is a single number
                lda #%00100000
                trb status

                ; If we had a minus, we'll have to negate it
                lda tmpdsp+1
                beq _done       ; no minus, all done

                jsr xt_negate
_done:
z_number:       rts
.scend


; ## NUMBER_SIGN ( ud -- ud ) "Add character to pictured output string"
; ## "#"  auto  ANS core
        ; """https://forth-standard.org/standard/core/num
        ; Add one char to the beginning of the pictured output string.
        ;
        ; Based on
        ; https://github.com/philburk/pforth/blob/master/fth/numberio.fth
        ; Forth code  BASE @ UD/MOD ROT 9 OVER < IF 7 + THEN [CHAR] 0 + HOLD ;
        ; """
xt_number_sign:
                jsr underflow_2         ; double number

                jsr xt_base
                jsr xt_fetch            ; ( ud1 base )

                ; The following code is the ancient Forth word UD/MOD, which in
                ; various Forths (including Gforth) lives on under the hood,
                ; even though it's not an ANS standard word, it doesn't appear
                ; in the docs, it's only used here, and there are no tests for
                ; it. This is why we got rid of it. We'll be converting this
                ; mess to something more sane in the long run.
                jsr xt_to_r             ; >r
                jsr xt_zero             ; 0
                jsr xt_r_fetch          ; r@
                jsr xt_um_slash_mod     ; um/mod
                jsr xt_rot              ; rot
                jsr xt_rot              ; rot
                jsr xt_r_from           ; r>
                jsr xt_um_slash_mod     ; um/mod
                jsr xt_rot              ; rot
                ; end of UD/MOD ( rem ud )

                jsr xt_rot              ; ( ud rem )

                ; Convert the number that is left over to an ASCII character. We
                ; use a string lookup for speed. Use either abc_str_lower for
                ; lower case or abc_str_upper for upper case (prefered)
                lda 0,x
                tay
                lda s_abc_upper,y
                sta 0,x
                stz 1,x                 ; paranoid; now ( ud char )

                jsr xt_hold

z_number_sign:
                rts


; ## NUMBER_SIGN_GREATER ( d -- addr u ) "Finish pictured number conversion"
; ## "#>"  auto  ANS core
        ; """https://forth-standard.org/standard/core/num-end
        ; Finish conversion of pictured number string, putting address and
        ; length on the Data Stack.
        ;
        ; Original Fort is  2DROP HLD @ PAD OVER -
        ; Based on
        ; https://github.com/philburk/pforth/blob/master/fth/numberio.fth
        ; """
xt_number_sign_greater:

                jsr underflow_2         ; double number

                ; The start address lives in tohold
                lda tohold
                sta 0,x         ; LSB of tohold
                sta 2,x
                lda tohold+1
                sta 1,x         ; MSB of addr
                sta 3,x         ; ( addr addr )

                ; The length of the string is pad - addr
                jsr xt_pad      ; ( addr addr pad )

                sec
                lda 0,x         ; LSB of pad address
                sbc 2,x
                sta 2,x

                lda 1,x         ; MSB, which should always be zero
                sbc 3,x
                sta 3,x         ; ( addr u pad )

                inx
                inx

z_number_sign_greater:
                rts


; ## NUMBER_SIGN_S ( d -- addr u ) "Completely convert pictured output"
; ## "#s"  auto  ANS core
        ; """https://forth-standard.org/standard/core/numS
        ; Completely convert number for pictured numerical output.
        ;
        ; Based on
        ; https://github.com/philburk/pforth/blob/master/fth/system.fth
        ; Original Forth code  BEGIN # 2DUP OR 0= UNTIL
        ; """
.scope
xt_number_sign_s:
                jsr underflow_2
_loop:
                ; convert a single number ("#")
                jsr xt_number_sign

                ; stop when double-celled number in TOS is zero:
                lda 0,x
                ora 1,x
                ora 2,x
                ora 3,x
                bne _loop

z_number_sign_s:
                rts
.scend


; ## OF (C: -- of-sys) (x1 x2 -- |x1) "Conditional flow control"
; ## "of"  auto  ANS core ext
        ; """http://forth-standard.org/standard/core/OF"""
.scope
xt_of:
                ; Check if value is equal to this case.
                ; Postpone over (eg. compile a jsr to it)
                ldy #>xt_over
                lda #<xt_over
                jsr cmpl_subroutine

                ; Postpone = (EQUAL), that is, compile a jsr to it
                ldy #>xt_equal
                lda #<xt_equal
                jsr cmpl_subroutine

                jsr xt_if

                ; If it's true, consume the original value.
                ; Postpone DROP (eg. compile a jsr to it)
                ldy #>xt_drop
                lda #<xt_drop
                jsr cmpl_subroutine

z_of:           rts
.scend


; ## ONE ( -- n ) "Push the number 1 to the Data Stack"
; ## "1"  auto  Tali Forth
        ; """This is also the code for EDITOR-WORDLIST"""
xt_editor_wordlist:
xt_one:
                dex
                dex
                lda #1
                sta 0,x
                stz 1,x

z_editor_wordlist:
z_one:
                rts


; ## ONE_MINUS ( u -- u-1 ) "Decrease TOS by one"
; ## "1-"  auto  ANS core
        ; """https://forth-standard.org/standard/core/OneMinus"""
.scope
xt_one_minus:
                jsr underflow_1

                lda 0,x
                bne +
                dec 1,x
*
                dec 0,x

z_one_minus:    rts
.scend


; ## ONE_PLUS ( u -- u+1 ) "Increase TOS by one"
; ## "1+"  auto  ANS core
        ; """https://forth-standard.org/standard/core/OnePlus
        ;
        ; Code is shared with CHAR-PLUS
        ; """
.scope
xt_char_plus:
xt_one_plus:
                jsr underflow_1

                inc 0,x
                bne _done
                inc 1,x

_done:
z_char_plus:
z_one_plus:     rts
.scend


; ## ONLY ( -- ) "Set earch order to minimum wordlist"
; ## "only"  auto  ANS search ext
        ; """https://forth-standard.org/standard/search/ONLY"""
.scope
xt_only:
                ; Put -1 on data stack.
                dex
                dex
                lda #$FF
                sta 0,x
                sta 1,x

                ; Invoke set-order to set the minimum search order.
                jsr xt_set_order

z_only:         rts
.scend


; ## OR ( m n -- n ) "Logically OR TOS and NOS"
; ## "or"  auto  ANS core
        ; """https://forth-standard.org/standard/core/OR"
xt_or:
                jsr underflow_2

                lda 0,x
                ora 2,x
                sta 2,x

                lda 1,x
                ora 3,x
                sta 3,x

                inx
                inx

z_or:           rts


; ## ORDER ( -- ) "Print current word order list and current WID"
; ## "order"  auto  ANS core
        ; """https://forth-standard.org/standard/search/ORDER
        ; Note the search order is displayed from first search to last
        ; searched and is therefore exactly the reverse of the order in which
        ; Forth stacks are displayed.
        ;
        ; A Forth implementation of this word is:
        ;
        ; 	: .wid ( wid -- )
        ; 	dup 0=  if ." Forth "  drop    else
        ; 	dup 1 = if ." Editor " drop    else
        ; 	dup 2 = if ." Assembler " drop else
        ; 	dup 3 = if ." Root " drop      else
        ; 	           . ( just print the number )
        ; 	then then then then ;
        ;
        ; : ORDER ( -- )
        ; 	cr get-order 0 ?do .wid loop
        ; 	space space get-current .wid ;
        ;
        ; This is an interactive program, so speed
        ; is not as important as size. We assume we do not have more than 255
        ; wordlists.
        ; """
.scope
xt_order:
                jsr xt_cr
                jsr xt_get_order        ; ( wid_n ... wid_1 n )

                ; Paranoid: Check if there are no wordlists, a rather
                ; pathological case. this would mean ( 0 ) on the stack. In
                ; that case, we just drop n and run
                lda 0,x                 ; assumes no more than 255 wordlists
                beq _drop_done

_have_wordlists:
                ; We arrive here with the LSB of TOS in A, the number of WIDs
                ; on the stack
                tay
_loop:
                inx
                inx                     ; DROP, now ( wid_n ... wid_1 )
                lda 0,x

                phy
                jsr _print_wid_string   ; internal helper function
                ply

                dey
                bne _loop

                ; We've printed the wordlists, now we add the current wordlist.
                ; This follows the convention of Gforth
                jsr xt_space
                jsr xt_space
                jsr xt_get_current      ; ( wid )

                lda 0,x
                jsr _print_wid_string
                jsr xt_cr

_drop_done:
                inx
                inx
z_order:
                rts

_print_wid_string:
        ; """Helper function for ORDER: Given a WID in A, print the
        ; corresponding string. If there is no such word list defined, just
        ; print the number. Assumes we will not have more than 256 WIDs; also
        ; assumes we have just loaded A so Z reflects status of byte.  In
        ; theory, we could speed this up by having the WID be the same as the
        ; number of the strings. However, ORDER is used rather infrequently and
        ; this would make changes to the strings.asm file very dangerous, so we
        ; follow the slightly more complicated route with a translation table.
        ; """
                ; If the WID is larger than 3, we have no string avaliable and
                ; just print the number.
                ; See http://6502.org/tutorials/compare_instructions.html
                ; for details
                cmp #4
                bcc _output_string      ; less than 4, print a real string

                ; Our WID is not less than 4, that is, 4 or larger. We just
                ; print the number
                dex
                dex
                sta 0,x
                stz 1,x
                jmp xt_u_dot            ; JSR/RTS as this routine is not compiled

_output_string:
                ; Get the string number based on WID 0 to 3
                tay
                lda _wid_data,y

                ; Print without a line feed
                jmp print_string_no_lf  ; JSR/RTS as this routine is not compiled

_wid_data:
        ; Table of string numbers (see strings.asm) indexed by the WID if
        ; less than 4.
        .byte str_wid_forth            ; WID 0: "Forth"
        .byte str_wid_editor           ; WID 1: "Editor"
        .byte str_wid_assembler        ; WID 2: "Assembler"
        .byte str_wid_root             ; WID 3: "Root"
.scend


; ## OUTPUT ( -- addr ) "Return the address of the EMIT vector address"
; ## "output"  tested  Tali Forth
xt_output:
        ; """Return the address where the jump target for EMIT is stored (but
        ; not the vector itself). By default, this will hold the value of
        ; kernel_putc routine, but this can be changed by the user, hence this
        ; routine.
        ; """
                dex
                dex
                lda #<output
                sta 0,x
                lda #>output
                sta 1,x

z_output:       rts


; ## OVER ( b a -- b a b ) "Copy NOS to TOS"
; ## "over"  auto  ANS core
        ; """https://forth-standard.org/standard/core/OVER"""
xt_over:
                jsr underflow_2

                dex
                dex

                lda 4,x         ; LSB
                sta 0,x
                lda 5,x         ; MSB
                sta 1,x

z_over:         rts


; ## PAD ( -- addr ) "Return address of user scratchpad"
; ## "pad"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/PAD
        ; Return address to a temporary area in free memory for user. Must
        ; be at least 84 bytes in size (says ANS). It is located relative to
        ; the compile area pointer (CP) and therefore varies in position.
        ; This area is reserved for the user and not used by the system
        ; """
xt_pad:
                dex
                dex

                lda cp
                clc
                adc #padoffset  ; assumes padoffset one byte in size
                sta 0,x

                lda cp+1
                adc #0          ; only need carry
                sta 1,x

z_pad:          rts


; ## PAGE ( -- ) "Clear the screen"
; ## "page"  tested  ANS facility
        ; """https://forth-standard.org/standard/facility/PAGE
        ; Clears a page if supported by ANS terminal codes. This is
        ; Clear Screen ("ESC[2J") plus moving the cursor to the top
        ; left of the screen
        ; """
xt_page:
                lda #AscESC
                jsr emit_a
                lda #$5B        ; ASCII for "["
                jsr emit_a
                lda #'2
                jsr emit_a
                lda #'J
                jsr emit_a

                ; move cursor to top left of screen
                jsr xt_zero
                jsr xt_zero
                jsr xt_at_xy

z_page:         rts


; ## PAREN ( -- ) "Discard input up to close paren ( comment )"
; ## "("  auto  ANS core
        ; """http://forth-standard.org/standard/core/p"""
.scope
xt_paren:
                ; Put a right paren on the stack.
                dex
                dex
                lda #41     ; Right parenthesis
                sta 0,x
                stz 1,x

                ; Call parse.
                jsr xt_parse

                ; Throw away the result.
                inx
                inx
                inx
                inx

z_paren:        rts
.scend


; ## PARSE_NAME ( "name" -- addr u ) "Parse the input"
; ## "parse-name"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/PARSE-NAME
        ; Find next word in input string, skipping leading whitespace. This is
        ; a special form of PARSE and drops through to that word. See PARSE
        ; for more detail. We use this word internally for the interpreter
        ; because it is a lot easier to use. Reference implementations at
        ; http://forth-standard.org/standard/core/PARSE-NAME and
        ; http://www.forth200x.org/reference-implementations/parse-name.fs
        ; Roughly, the word is comparable to BL WORD COUNT. -- Note that
        ; though the ANS standard talks about skipping "spaces", whitespace
        ; is actually perfectly legal (see for example
        ; http://forth-standard.org/standard/usage#subsubsection.3.4.1.1).
        ; Otherwise, PARSE-NAME chokes on tabs.
        ; """
.scope
xt_parse_name:
                ; To enable the compilation of the high-level Forth words
                ; in forth-words.asm and user-words.asm at boot time,
                ; PARSE-NAME and PARSE must be able to deal with 16-bit string
                ; lengths. This is a pain on an 8-bit machine. The pointer
                ; to the current location is in toin (>IN). We need to check,
                ; worst case, the characters from cib+toin to cib+ciblen, and
                ; we can't just use Y as an index.

                ; The counter is CIBLEN-TOIN and stored in tmp1
                lda ciblen              ; LSB of counter
                sec
                sbc toin
                sta tmp1
                lda ciblen+1            ; MSB
                sbc toin+1
                sta tmp1+1

                ; Check the result for zero (TOIN is equal to CIBLEN)
                lda tmp1
                ora tmp1+1
                beq _empty_line

                ; We walk through the characters starting at CIB+TOIN, so we
                ; save a temp version of that in tmp2
                lda cib
                clc
                adc toin
                sta tmp2                ; LSB of first character
                lda cib+1
                adc toin+1
                sta tmp2+1              ; MSB

_skip_loop:
                lda (tmp2)              ; work copy of cib
                jsr is_whitespace
                bcc _char_found

                ; Char is still whitespace, continue
                inc tmp2
                bne +
                inc tmp2+1
*
                ; Adjust counter
                lda tmp1
                bne +
                dec tmp1+1
*               dec tmp1

                lda tmp1
                ora tmp1+1
                bne _skip_loop          ; fall through if empty line

_empty_line:
                ; Neither the ANS Forth nor the Gforth documentation say
                ; what to return as an address if a string with only
                ; spaces is given. For speed reasons, we just return junk
                ; NOS, with the TOS zero as per standard
                dex
                dex
                dex
                dex

                stz 0,x                 ; TOS is zero
                stz 1,x

                jmp z_parse_name        ; skip over PARSE

_char_found:
                ; We arrive here with tmp2 pointing to the first non-space
                ; character. This is where the word really starts, so
                ; we use it to calculate the new >IN by subtracting
                lda tmp2
                sec
                sbc cib
                sta toin
                lda tmp2+1
                sbc cib+1
                sta toin+1

                ; prepare Data Stack for PARSE by adding space
                ; as the delimiter
                dex
                dex

                lda #AscSP
                sta 0,x
                stz 1,x                 ; paranoid, now ( "name" c )
.scend

; ## PARSE ( "name" c -- addr u ) "Parse input with delimiter character"
; ## "parse"  tested  ANS core ext
        ; """https://forth-standard.org/standard/core/PARSE
        ; Find word in input string delimited by character given. Do not
        ; skip leading delimiters -- this is the main difference to PARSE-NAME.
        ; PARSE and PARSE-NAME replace WORD in modern systems. ANS discussion
        ; http://www.forth200x.org/documents/html3/rationale.html#rat:core:PARSE
        ;
        ;
        ;     cib  cib+toin   cib+ciblen
        ;      v      v            v
        ;     |###################|
        ;
        ;     |------>|  toin (>IN)
        ;     |------------------->|  ciblen
        ;
        ; The input string is stored starting at the address in the Current
        ; Input Buffer (CIB), the length of which is in CIBLEN. While searching
        ; for the delimiter, TOIN (>IN) points to the where we currently are.
        ; Since PARSE does not skip leading delimiters, we assume we are on a
        ; useful string if there are any characters at all. As with
        ; PARSE-NAME, we must be able to handle strings with a length of
        ; 16-bit for EVALUTE, which is a pain on an 8-bit machine.
        ; """
.scope
xt_parse:
                jsr underflow_1

                ; If the input buffer is empty, we just return
                lda ciblen
                ora ciblen+1
                beq _abort_parse

                ; If the pointer >IN is larger or equal to the length of
                ; the input buffer (CIBLEN), the line is done. Put
                ; differently, we only continue if >IN is smaller than
                ; CIBLEN
                lda toin+1              ; MSB
                cmp ciblen+1
                bcc _go_parse           ; unsigned comparison

                lda toin                ; LSB
                cmp ciblen
                bcc _go_parse

_abort_parse:
                ; Sorry, this line is over
                dex
                dex
                stz 0,x
                stz 1,x

                bra _done
_go_parse:
                ; We actually have work to do. Save the delimiter in
                ; tmptos.
                lda 0,x
                sta tmptos

                ; We can now prepare the Data Stack for the return value
                dex
                dex

                ; tmp1 is CIB+TOIN, the beginning of the current string
                ; tmp2 is initially the same as tmp1, then the work index
                ; tmp3 is CIB+CIBLEN, one char past the end of the string

                ; Calculate the beginning of the string, which is also the
                ; address to return
                lda cib
                clc
                adc toin        ; LSB
                sta tmp1
                sta tmp2
                sta 2,x

                lda cib+1
                adc toin+1      ; MSB
                sta tmp1+1
                sta tmp2+1
                sta 3,x

                ; Calculate the address where the input buffer ends plus 1, so
                ; we can compare it with TOIN, which is an index
                lda cib
                clc
                adc ciblen
                sta tmp3
                lda cib+1
                adc ciblen+1
                sta tmp3+1

                ; Initialize the offset we use to adjust EOL or found delimiter
                stz tmptos+1
_loop:
                ; If we are at the end of the string, quit
                lda tmp2
                cmp tmp3
                bne _not_empty

                lda tmp2+1
                cmp tmp3+1
                beq _eol
_not_empty:
                ; We have to do this the hard way. In fact, it's really
                ; hard since if we are dealing with a SPACE, the standard
                ; wants us to skip all whitespace, not just spaces. Otherwise,
                ; Tali would choke on tabs between words. For details, see
                ; http://forth-standard.org/standard/file#subsection.11.3.5
                ; In theory, we could make this faster by defining a delimiter
                ; that is 00 as the sign that we skip all whitespace, thereby
                ; avoiding having to test every time. However, somebody,
                ; somewhere might want to parse a zero-delimited list. Since
                ; any byte value could be chosen for that, we just test for
                ; a space every single time for the moment.
                lda (tmp2)

                ldy tmptos
                cpy #AscSP
                bne _not_whitespace

                ; The delimiter is a space, so we're looking for all
                ; whitespace
                jsr is_whitespace
                bcc _not_whitespace
                bra _found_delimiter

_not_whitespace:
                ; The delimiter is not a space, so we're looking for
                ; whatever it is
                cmp tmptos
                beq _found_delimiter

                ; Not a delimiter, next character
                inc tmp2
                bne _loop
                inc tmp2+1
                bra _loop

_found_delimiter:
                ; Increase the offset: If we've found a delimiter, we want
                ; TOIN to point to the character after it, not the delimiter
                ; itself
                inc tmptos+1
_eol:
                ; The length of the new string is tmp2-tmp1
                lda tmp2
                sec
                sbc tmp1
                sta 0,x

                lda tmp2+1
                sbc tmp1+1
                sta 1,x

                ; The new offset is tmp2-cib
                lda tmp2
                sec
                sbc cib
                sta toin
                lda tmp2+1
                sbc cib+1
                sta toin+1

                ; Add in the delimiter
                lda toin
                clc
                adc tmptos+1
                sta toin
                lda toin+1
                adc #0          ; we only need the carry
                sta toin+1
_done:
z_parse_name:
z_parse:        rts
.scend


; ## PICK ( n n u -- n n n ) "Move element u of the stack to TOS"
; ## "pick"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/PICK
        ; Take the u-th element out of the stack and put it on TOS,
        ; overwriting the original TOS. 0 PICK is equivalent to DUP, 1 PICK to
        ; OVER. Note that using PICK is considered poor coding form. Also note
        ; that FIG Forth has a different behavior for PICK than ANS Forth.
        ; """
.scope
xt_pick:
                ; Checking for underflow is difficult because it depends on
                ; which element we want to grab. We could probably figure
                ; something out, but it wouldn't work with underflow stripping
                ; Since using PICK is considered poor form anyway, we just
                ; leave it as it is
                asl 0,x         ; we assume u < 128 (stack is small)
                txa
                adc 0,x
                tay

                lda 0002,y
                sta 0,x
                lda 0003,y
                sta 1,x

z_pick:         rts
.scend


; ## PLUS ( n n -- n ) "Add TOS and NOS"
; ## "+"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Plus"""
xt_plus:
                jsr underflow_2

                clc
                lda 0,x         ; LSB
                adc 2,x
                sta 2,x

                lda 1,x         ; MSB. No CLC, conserve carry bit
                adc 3,x
                sta 3,x

                inx
                inx

z_plus:         rts


; ## PLUS_STORE ( n addr -- ) "Add number to value at given address"
; ## "+!"  auto  ANS core
        ; """https://forth-standard.org/standard/core/PlusStore"""
xt_plus_store:
                jsr underflow_2

                ; move address to tmp1 so we can work with it
                lda 0,x
                sta tmp1
                lda 1,x
                sta tmp1+1

                ldy #0          ; LSB
                lda (tmp1),y
                clc
                adc 2,x
                sta (tmp1),y

                iny             ; MSB
                lda (tmp1),y
                adc 3,x
                sta (tmp1),y

                inx
                inx
                inx
                inx

z_plus_store:   rts


; ## POSTPONE ( -- ) "Change IMMEDIATE status (it's complicated)"
; ## "postpone"  auto   ANS core
        ; """https://forth-standard.org/standard/core/POSTPONE
        ; Add the compilation behavior of a word to a new word at
        ; compile time. If the word that follows it is immediate, include
        ; it so that it will be compiled when the word being defined is
        ; itself used for a new word. Tricky, but very useful.
        ;
        ; Because POSTPONE expects a word (not an xt) in the input stream (not
        ; on the Data Stack). This means we cannot build words with
        ; "jsr xt_postpone, jsr <word>" directly.
        ; """
.scope
xt_postpone:
                jsr xt_parse_name               ; ( -- addr n )

                ; if there was no word provided, complain and quit
                lda 0,x
                ora 1,x
                bne +

                lda #err_noname
                jmp error
*
                jsr xt_find_name                ; ( -- nt | 0 )

                ; if word not in Dictionary, complain and quit
                bne +
                lda #err_noname
                jmp error

*
                ; keep a copy of nt for later
                lda 0,x
                sta tmp1
                lda 1,x
                sta tmp1+1

                ; We need the xt instead of the nt
                jsr xt_name_to_int              ; ( nt -- xt )

                ; See if this is an immediate word. This is easier
                ; with nt than with xt. The status byte of the word
                ; is nt+1
                inc tmp1
                bne +
                inc tmp1+1
*
                lda (tmp1)
                and #IM         ; mask all but Intermediate flag
                beq _not_immediate

                ; We're immediate, so instead of executing it right now, we
                ; compile it. xt is TOS, so this is easy. The RTS at the end
                ; takes us back to the original caller
                jsr xt_compile_comma
                bra _done

_not_immediate:
                ; This is not an immediate word, so we enact "deferred
                ; compilation" by including ' <NAME> COMPILE, which we do by
                ; compiling the run-time routine of LITERAL, the xt itself, and
                ; a subroutine jump to COMPILE,
                jsr xt_literal

                ; Last, compile COMPILE,
                ldy #>xt_compile_comma
                lda #<xt_compile_comma
                jsr cmpl_subroutine
_done:
z_postpone:     rts
.scend


; ## PREVIOUS ( -- ) "Remove the first wordlist in the search order"
; ## "previous"  auto  ANS search ext
        ; """http://forth-standard.org/standard/search/PREVIOUS"""
.scope
xt_previous:
                jsr xt_get_order
                jsr xt_nip
                jsr xt_one_minus
                jsr xt_set_order

z_previous:     rts
.scend


; ## QUESTION ( addr -- ) "Print content of a variable"
; ## "?"  tested  ANS tools
        ; """https://forth-standard.org/standard/tools/q
        ;
        ; Only used interactively. Since humans are so slow, we
        ; save size and just go for the subroutine jumps
        ; """
xt_question:
                ; FETCH takes care of underflow check
                jsr xt_fetch
                jsr xt_dot

z_question:     rts


; ## QUESTION_DUP ( n -- 0 | n n ) "Duplicate TOS non-zero"
; ## "?dup"  auto  ANS core
        ; """https://forth-standard.org/standard/core/qDUP"""
.scope
xt_question_dup:
                jsr underflow_1

                ; Check if TOS is zero
                lda 0,x
                ora 1,x
                beq _done

                ; not zero, duplicate
                dex
                dex
                lda 2,x
                sta 0,x
                lda 3,x
                sta 1,x
_done:
z_question_dup: rts
.scend


; ## R_FETCH ( -- n ) "Get copy of top of Return Stack"
; ## "r@"  auto  ANS core
        ; """https://forth-standard.org/standard/core/RFetch
        ; This word is Compile Only in Tali Forth, though Gforth has it
        ; work normally as well
        ;
        ; An alternative way to write this word
        ; would be to access the elements on the stack directly like 2R@
        ; does, these versions should be compared at some point.
        ; """
xt_r_fetch:
                ; get the return address
                ply             ; LSB
                sty tmp1
                ply             ; MSB

                ; --- CUT FOR NATIVE COMPILE ---

                ; get the actual top of Return Stack
                dex
                dex

                pla             ; LSB
                sta 0,x
                pla             ; MSB
                sta 1,x

                ; now we have to put that value back
                pha
                lda 0,x
                pha

                ; --- CUT FOR NATIVE COMPILE ---

                ; restore return value
                phy             ; MSB
                ldy tmp1
                phy             ; LSB

z_r_fetch:      rts


; ## R_FROM ( -- n )(R: n --) "Move top of Return Stack to TOS"
; ## "r>"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Rfrom
        ; Move Top of Return Stack to Top of Data Stack.
        ;
        ; We have to move
        ; the RTS address out of the way first. This word is handled
        ; differently for native and and subroutine compilation, see COMPILE,
        ; This is a compile-only word
        ; """

xt_r_from:
                ; Rescue the address of the return jump that is currently
                ; on top of the Return Stack. If this word is natively
                ; compiled, this is a total waste of time
                pla             ; LSB
                sta tmptos
                ply             ; MSB

                ; --- CUT FOR NATIVE CODING ---

                dex
                dex

                ; now we can access the actual data

                pla             ; LSB
                sta 0,x
                pla             ; MSB
                sta 1,x

                ; --- CUT FOR NATIVE CODING ---

                ; restore the return address
                phy             ; MSB
                lda tmptos
                pha             ; LSB

z_r_from:       rts


; ## R_TO_INPUT ( -- ) ( R: n n n n -- ) "Restore input state from Return Stack"
; ## "r>input"  tested  Tali Forth
        ; """Restore the current input state as defined by insrc, cib, ciblen,
        ; and toin from the Return Stack.
        ;
        ; See INPUT_TO_R for a discussion of this word. Uses tmp1
        ; """
.scope
xt_r_to_input:

                ; We arrive here with the return address on the top of the
                ; 65c02's stack. We need to move it out of the way first
                pla
                sta tmp1
                pla
                sta tmp1+1

                ; This assumes that insrc is the first of eight bytes and
                ; toin+1 the last in the sequence we want to save from the Zero
                ; Page. Since we went in reverse order, insrc is now on the top
                ; of the Return Stack.
                ldy #0
_loop:
                pla
                sta insrc,y
                iny
                cpy #8
                bne _loop

                ; Restore address for return jump
                lda tmp1+1
                pha
                lda tmp1
                pha

z_r_to_input: 	rts
.scend


; ## RECURSE ( -- ) "Copy recursive call to word being defined"
; ## "recurse"  auto  ANS core
        ; """https://forth-standard.org/standard/core/RECURSE
        ;
        ; This word may not be natively compiled
        ; """
.scope
xt_recurse:
                ; The whole routine amounts to compiling a reference to
                ; the word that is being compiled. First, we save the JSR
                ; instruction
                ldy #0

                lda #$20        ; opcode for JSR
                sta (cp),y
                iny

                ; Next, we save the LSB and MSB of the xt of the word
                ; we are currently working on. We first need to see if
                ; WORKWORD has the nt (: started the word) or the
                ; xt (:NONAME started the word). Bit 6 in status tells us.
                bit status
                bvs _nt_in_workword

                ; This is a special :NONAME word. Just copy the xt
                ; from WORKWORD into the dictionary.
                lda workword
                sta (cp),y
                iny
                lda workword+1
                sta (cp),y
                iny
                bra _update_cp

_nt_in_workword:
                ; This is a regular : word, so the xt is four bytes down
                ; from the nt which we saved in WORKWORD. We could probably
                ; use NAME>INT here but this is going to be faster, and
                ; fast counts with recursion
                lda workword            ; LSB
                clc
                adc #4
                sta tmp1
                lda workword+1          ; MSB
                adc #0
                sta tmp1+1

                lda (tmp1)
                sta (cp),y
                phy
                ldy #1
                lda (tmp1),y
                ply
                iny
                sta (cp),y
                iny

_update_cp:
                tya
                clc
                adc cp
                sta cp
                bcc _done
                inc cp+1
_done:
z_recurse:      rts
.scend


; ## REFILL ( -- f ) "Refill the input buffer"
; ## "refill"  tested  ANS core ext
        ; """https://forth-standard.org/standard/core/REFILL
        ; Attempt to fill the input buffer from the input source, returning
        ; a true flag if successful. When the input source is the user input
        ; device, attempt to receive input into the terminal input buffer. If
        ; successful, make the result the input buffer, set >IN to zero, and
        ; return true. Receipt of a line containing no characters is considered
        ; successful. If there is no input available from the current input
        ; source, return false. When the input source is a string from EVALUATE,
        ; return false and perform no other action." See
        ; https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/The-Input-Stream.html
        ; and Conklin & Rather p. 156. Note we don't have to care about blocks
        ; because REFILL is never used on blocks - Tali is able to evaluate the
        ; entire block as a 1024 byte string.
        ; """"
.scope
xt_refill:
                ; Get input source from SOURCE-ID. This is an
                ; optimized version of a subroutine jump to SOURCE-ID
                lda insrc               ; cheat: We only check LSB
                bne _src_not_kbd

                ; SOURCE-ID of zero means we're getting stuff from the keyboard
                ; with ACCEPT, which wants the address of the current input
                ; buffer NOS and the max number of characters to accept TOS
                dex
                dex
                dex
                dex

                lda cib                 ; address of CIB is NOS
                sta 2,x
                lda cib+1
                sta 3,x

                stz ciblen              ; go in with empty buffer
                stz ciblen+1

                lda #bsize              ; max number of chars is TOS
                sta 0,x
                stz 1,x                 ; cheat: We only accept max 255

                jsr xt_accept           ; ( addr n1 -- n2)

                ; ACCEPT returns the number of characters accepted, which
                ; belong in CIBLEN
                lda 0,x
                sta ciblen
                lda 1,x
                sta ciblen+1            ; though we only accept 255 chars

                ; make >IN point to beginning of buffer
                stz toin
                stz toin+1

                lda #$FF                ; overwrite with TRUE flag
                sta 0,x
                sta 1,x

                bra _done

_src_not_kbd:
                ; If SOURCE-ID doesn't return a zero, it must be a string in
                ; memory or a file (remember, no blocks in this version).
                ; If source is a string, we were given the flag -1 ($FFFF)
                inc
                bne _src_not_string

                ; Simply return FALSE flag as per specification
                dex
                dex
                stz 0,x
                stz 1,x

                bra z_refill

_src_not_string:
                ; Since we don't have blocks, this must mean that we are trying
                ; to read from a file. However, we don't have files yet, so we
                ; report an error and jump to ABORT.
                lda #err_badsource
                jmp error
_done:
z_refill:       rts
.scend


; ## REPEAT (C: orig dest -- ) ( -- ) "Loop flow control"
; ## "repeat"  auto  ANS core
        ; """http://forth-standard.org/standard/core/REPEAT"""
.scope
xt_repeat:
                ; Run again first
                jsr xt_again

                ; Stuff HERE in for the branch address
                ; to get out of the loop
                jsr xt_here
                jsr xt_swap
                jsr xt_store

z_repeat:       rts
.scend


; ## RIGHT_BRACKET ( -- ) "Enter the compile state"
; ## "]"  auto  ANS core
        ; """https://forth-standard.org/standard/right-bracket
        ; This is an immediate word.
        ; """
xt_right_bracket:
                lda #$FF
                sta state
                sta state+1
z_right_bracket:
                rts


; ## ROOT_WORDLIST ( -- u ) "WID for the Root (minimal) wordlist"
; ## "root-wordlist"  tested  Tali Editor
xt_root_wordlist:
                dex             ; The WID for the Root wordlist is 3.
                dex
                lda #3
                sta 0,x
                stz 1,x

z_root_wordlist:
                rts


; ## ROT ( a b c -- b c a ) "Rotate first three stack entries downwards"
; ## "rot"  auto  ANS core
        ; """https://forth-standard.org/standard/core/ROT
        ; Remember "R for 'Revolution'" - the bottom entry comes out
        ; on top!
        ; """
.scope
xt_rot:
                jsr underflow_3

                ldy 5,x         ; MSB first
                lda 3,x
                sta 5,x
                lda 1,x
                sta 3,x
                sty 1,x

                ldy 4,x         ; LSB next
                lda 2,x
                sta 4,x
                lda 0,x
                sta 2,x
                sty 0,x

z_rot:          rts
.scend


; ## RSHIFT ( x u -- x ) "Shift TOS to the right"
; ## "rshift"  auto  ANS core
        ; """https://forth-standard.org/standard/core/RSHIFT"""
xt_rshift:
                jsr underflow_2

                ; We shift maximal by 16 bits, mask everything else
                lda 0,x
                and #%00001111
                beq _done               ; if 0 shifts, quit

                tay
_loop:
                lsr 3,x
                ror 2,x
                dey
                bne _loop
_done:
                inx
                inx

z_rshift:       rts


; ## S_BACKSLASH_QUOTE ( "string" -- )( -- addr u ) "Store string in memory"
; ## "s\""  auto  ANS core
        ; """https://forth-standard.org/standard/core/Seq
        ; Store address and length of string given, returning ( addr u ).
        ; ANS core claims this is compile-only, but the file set expands it
        ; to be interpreted, so it is a state-sensitive word, which in theory
        ; are evil. We follow general usage. This is just like S" except
        ; that it allows for some special escaped characters.
        ; """
.scope
xt_s_backslash_quote:
                ; tmp2 will be used to determine if we are handling
                ; escaped characters or not. In this case, we are,
                ; so set it to $FF (the upper byte will be used to
                ; determine if we just had a \ and the next character
                ; needs to be modifed as an escaped character).
                lda #$FF
                sta tmp2
                stz tmp2+1

                ; Now that the flag is set, jump into s_quote to process
                ; the string.
                jsr s_quote_start
_done:
z_s_backslash_quote:
                rts
.scend

; This is a helper function for s_backslash_quote to convert a character
; from ASCII to the corresponding hex value, eg 'F'->15
convert_hex_value:
.scope
        cmp #'A
        bcc _digit

        ; It's A-F
        and #$DF                ; Make it uppercase.
        sec
        sbc #'7                 ; gives value 10 for 'A'
        bra _done

_digit:
        ; It's 0-9
        sec
        sbc #'0

_done:
        rts
.scend


; ## SEARCH_WORDLIST ( caddr u wid -- 0 | xt 1 | xt -1) "Search for a word in a wordlist"
; ## "search-wordlist" auto ANS search
        ; """https://forth-standard.org/standard/search/SEARCH_WORDLIST"""
.scope
xt_search_wordlist:
                jsr underflow_3

                ; Set up tmp1 with the wordlist indicated by wid
                ; on the stack. Start by putting the base address
                ; of the wordlists in tmp2.
                lda up
                clc
                adc #wordlists_offset
                sta tmp2
                lda up+1
                adc #0          ; Adding carry
                sta tmp2+1

                ; Add the wid (in cells) to the base address.
                lda 0,x
                asl             ; Convert wid to offset in cells (x2)
                adc tmp2
                sta tmp2
                bcc +
                inc tmp2+1      ; Propagate carry if needed.

                ; tmp2 now holds the address of the dictionary pointer
                ; for the given wordlist.
*
                ; Remove the wid from the stack.
                inx
                inx

                ; check for special case of an empty string (length zero)
                lda 0,x
                ora 1,x
                bne _check_wordlist
                jmp _done

_check_wordlist:
                ; Check for special case of empty wordlist
                ; (dictionary pointer, in tmp2, is 0)
                lda tmp2
                ora tmp2+1
                bne _have_string
                jmp _done

_have_string:
                ; set up first loop iteration
                lda (tmp2)              ; nt of first word in Dictionary
                sta tmp1

                inc tmp2                ; Move to the upper byte
                bne +
                inc tmp2+1
*
                lda (tmp2)
                sta tmp1+1

                ; Reuse tmp2 to hold the address of the mystery string.
                lda 2,x                 ; Address of mystery string
                sta tmp2
                lda 3,x
                sta tmp2+1

_loop:
                ; first quick test: Are strings the same length?
                lda (tmp1)
                cmp 0,x
                bne _next_entry

_compare_string:
                ; are the same length, so we now have to compare each
                ; character

                ; second quick test: Is the first character the same?
                lda (tmp2)      ; first character of mystery string

                ; Lowercase the incoming charcter.
                cmp #$5B        ; ASCII '[' (one past Z)
                bcs _compare_first
                cmp #$41        ; ASCII 'A'
                bcc _compare_first

                ; An uppercase letter has been located.  Make it
                ; lowercase.
                clc
                adc #$20

_compare_first:
                ldy #8          ; Offset in nt to name
                cmp (tmp1),y    ; first character of current word
                bne _next_entry

                ; string length are the same and the first character is the
                ; same. If the length of the string is 1, we're already done
                lda 0,x
                dec
                beq _success

                ; No such luck: The strings are the same length and the first
                ; char is the same, but the word is more than one char long.
                ; So we suck it up and compare every single character. We go
                ; from back to front, because words like CELLS and CELL+ would
                ; take longer otherwise. We can also shorten the loop by one
                ; because we've already compared the first char.

                ; The string of the word we're testing against is 8 bytes down
                lda tmp1
                pha             ; Preserve tmp1 on the return stack.
                clc
                adc #8
                sta tmp1        ; Reusing tmp1 temporarily for string check.
                lda tmp1+1
                pha             ; Preserve tmp1+1 on the return stack.
                adc #0          ; we only need the carry
                sta tmp1+1

                ldy 0,x         ; index is length of string minus 1
                dey

_string_loop:
                lda (tmp2),y    ; last char of mystery string

                ; Lowercase the incoming charcter.
                cmp #$5B         ; ASCII '[' (one past Z)
                bcs _check_char
                cmp #$41        ; ASCII 'A'
                bcc _check_char

                ; An uppercase letter has been located.  Make it
                ; lowercase.
                clc
                adc #$20
_check_char:
                cmp (tmp1),y    ; last char of word we're testing against
                bne _next_entry_tmp1

                dey
                bne _string_loop

_success_tmp1:
                pla             ; Restore tmp1 from the return stack.
                sta tmp1+1
                pla
                sta tmp1

_success:
                ; The strings match. Drop the count and put correct nt TOS
                inx
                inx
                lda tmp1
                sta 0,x
                lda tmp1+1
                sta 1,x

                ; Change the nt into an xt, but save a copy of the nt
                ; to look up whether the word is immediate or not.
                jsr xt_dup              ; ( nt nt )
                jsr xt_name_to_int      ; ( nt xt )
                jsr xt_swap             ; ( xt nt )

                ldy #0                  ; Prepare flag

                ; The flags are in the second byte of the header
                inc 0,x
                bne +
                inc 1,x                 ; ( xt nt+1 )
*
                lda (0,x)               ; ( xt char )
                and #IM
                bne _immediate          ; bit set, we're immediate

                lda #$FF                ; We're not immediate, return -1
                sta 0,x
                sta 1,x
                bra _done_nodrop

_immediate:
                lda #1                  ; We're immediate, return 1
                sta 0,x
                stz 1,x

                bra _done_nodrop

_next_entry_tmp1:
                pla             ; Restore tmp1 from the return stack.
                sta tmp1+1
                pla
                sta tmp1
_next_entry:
                ; Not the same, so we get the next word. Next header
                ; address is two bytes down
                ldy #2
                lda (tmp1),y
                pha
                iny
                lda (tmp1),y
                sta tmp1+1
                pla
                sta tmp1

                ; If we got a zero, we've walked the whole Dictionary and
                ; return as a failure, otherwise try again
                ora tmp1+1
                beq _fail_done
                jmp _loop

_fail_done:
                stz 2,x         ; failure flag
                stz 3,x
_done:
                inx
                inx
_done_nodrop:
z_search_wordlist:
                rts
.scend


; ## SEE ( "name" -- ) "Print information about a Forth word"
; ## "see" tested  ANS tools
        ; """https://forth-standard.org/standard/tools/SEE
        ; SEE takes the name of a word and prints its name token (nt),
        ; execution token (xt), size in bytes, flags used, and then dumps the
        ; code and disassembles it.
        ; """
.scope
xt_see:
                jsr xt_parse_name       ; ( addr u )
                jsr xt_find_name        ; ( nt | 0 )

                ; If we got back a zero we don't know that word and so we quit
                ; with an error
                lda 0,x
                ora 1,x
                bne +

                lda #err_noname
                jmp error
*
                jsr xt_cr

                ; We have a legal word, so let's get serious. Save the current
                ; number base and use hexadecimal instead.
                lda base
                pha
                jsr xt_hex

                lda #str_see_nt
                jsr print_string_no_lf

                jsr xt_dup              ; ( nt nt )
                jsr xt_u_dot
                jsr xt_space            ; ( nt )

                jsr xt_dup              ; ( nt nt )
                jsr xt_name_to_int      ; ( nt xt )

                lda #str_see_xt
                jsr print_string_no_lf

                jsr xt_dup              ; ( nt xt xt )
                jsr xt_u_dot
                jsr xt_cr               ; ( nt xt )

                ; We print letters for flags and then later follow it with 1 or
                ; 0 to mark if which flag is set
                lda #str_see_flags
                jsr print_string_no_lf

                jsr xt_over             ; ( nt xt nt )
                jsr xt_one_plus         ; ( nt xt nt+1 )
                jsr xt_fetch            ; ( nt xt flags )

                lda 0,x

                ; This is crude, but for the moment it is good enough
                ldy #6                  ; Not all bits are used
_flag_loop:
                pha
                and #%00000001
                clc
                adc #$30                ; ASCII "0"
                jsr emit_a
                jsr xt_space

                pla
                ror                     ; Next flag

                dey
                bne _flag_loop

                jsr xt_cr

                inx
                inx                     ; ( nt xt )

                ; Figure out the size
                lda #str_see_size
                jsr print_string_no_lf

                jsr xt_swap             ; ( xt nt )
                jsr xt_wordsize         ; ( xt u )
                jsr xt_dup              ; ( xt u u ) for DUMP and DISASM
                jsr xt_decimal
                jsr xt_u_dot            ; ( xt u )
                jsr xt_hex
                jsr xt_cr

                ; Dump hex and disassemble
                jsr xt_two_dup          ; ( xt u xt u )
                jsr xt_dump
                jsr xt_cr
                jsr xt_disasm

                pla
                sta base

z_see:          rts
.scend


; ## SET_CURRENT ( wid -- ) "Set the compilation wordlist"
; ## "set-current" auto ANS search
        ; """https://forth-standard.org/standard/search/SET-CURRENT"""
.scope
xt_set_current:
                jsr underflow_1

                ; Save the value from the data stack.
                ldy #current_offset
                lda 0,x         ; CURRENT is byte variable
                sta (up),y      ; so only the LSB is used.

                inx
                inx

z_set_current:  rts
.scend


; ## SET_ORDER ( wid_n .. wid_1 n -- ) "Set the current search order"
; ## "set-order" auto ANS search
        ; """https://forth-standard.org/standard/search/SET-ORDER"""
.scope
xt_set_order:
                ; Test for -1 TOS
                lda #$FF
                cmp 1,x
                bne _start
                cmp 0,x
                bne _start

                ; There is a -1 TOS.  Replace it with the default
                ; search order, which is just the FORTH-WORDLIST.
                dex             ; Make room for the count.
                dex
                stz 3,x         ; ROOT-WORDLIST is 3
                lda #3
                sta 2,x
                stz 1,x         ; Count is 1.
                lda #1
                sta 0,x

                ; Continue processing with ( forth-wordlist 1 -- )
_start:
                ; Set #ORDER - the number of wordlists in the search order.
                ldy #num_order_offset
                lda 0,x
                sta (up),y      ; #ORDER is a byte variable.
                sta tmp1        ; Save a copy for zero check and looping.
                                ; Only the low byte is saved in tmp1 as
                                ; only 8 wordlists are allowed.

                inx             ; Drop the count off the data stack.
                inx

                ; Check if there are zero wordlists.
                lda tmp1
                beq _done       ; If zero, there are no wordlists.

                ; Move the wordlist ids from the data stack to the search order.
                ldy #search_order_offset
_loop:
                ; Move one wordlist id over into the search order.
                lda 0,x         ; The search order is a byte array
                sta (up),y      ; so only save the LSB
                iny

                ; Remove it from the data stack.
                inx
                inx

                ; See if that was the last one to process (first in the list).
                dec tmp1
                bne _loop

_done:
z_set_order:    rts
.scend



; ## S_QUOTE ( "string" -- )( -- addr u ) "Store string in memory"
; ## "s""  auto  ANS core
        ; """https://forth-standard.org/standard/core/Sq
        ; Store address and length of string given, returning ( addr u ).
        ; ANS core claims this is compile-only, but the file set expands it
        ; to be interpreted, so it is a state-sensitive word, which in theory
        ; are evil. We follow general usage.
        ;
        ; Can also be realized as
        ;     : S" [CHAR] " PARSE POSTPONE SLITERAL ; IMMEDIATE
        ; but it is used so much we want it in code.
        ; """
.scope
xt_s_quote:
                ; tmp2 will be used to determine if we are handling
                ; escaped characters or not.  In this case, we are
                ; not, so set it to zero.
                stz tmp2
                stz tmp2+1

s_quote_start:
                ; Make room on the data stack for the address.
                dex
                dex
                ; Make room on the data stack for the count.
                dex
                dex

                ; Put a jmp over the string data with address to be filled
                ; in later.
                lda #$4C
                jsr cmpl_a

                ; Address to be filled in later, just use $4C for the moment
                jsr cmpl_a
                jsr cmpl_a

                ; Save the current value of HERE on the data stack for the
                ; address of the string.
                lda cp
                sta 2,x
                lda cp+1
                sta 3,x

_savechars_loop:
                ; Start saving the string into the dictionary up to the
                ; ending double quote. First, check to see if the input
                ; buffer is empty.
                lda toin+1              ; MSB
                cmp ciblen+1
                bcc _input_fine         ; unsigned comparison

                lda toin                ; LSB
                cmp ciblen
                bcc _input_fine

                ; Input buffer is empty. Refill it. Refill calls accept,
                ; which uses tmp2 and tmp3. Save and restore them.
                lda tmp2
                pha
                lda tmp2+1
                pha
                lda tmp3    ; Only tmp3 used, so don't bother with tmp3+1
                pha

                jsr xt_refill           ; ( -- f )

                pla
                sta tmp3
                pla
                sta tmp2+1
                pla
                sta tmp2

                ; Check result of refill.
                lda 0,x
                ora 1,x
                bne _refill_ok

                ; Something when wrong with refill.
                lda #err_refill
                jmp error

_refill_ok:
                ; Remove the refill flag from the data stack.
                inx
                inx

                ; For refill success, jump back up to the empty check, just in
                ; case refill gave us an empty buffer (eg. empty/blank line of
                ; input)
                bra _savechars_loop

_input_fine:
                ; There should be at least one valid char to use.
                ; Calculate it's address at CIB+TOIN into tmp1
                lda cib
                clc
                adc toin        ; LSB
                sta tmp1
                lda cib+1
                adc toin+1      ; MSB
                sta tmp1+1

                ; Get the character
                lda (tmp1)

                ; Check to see if we are handling escaped characters.
                bit tmp2
                bmi _handle_escapes    ; Only checking bit 7
                jmp _regular_char

_handle_escapes:
                ; We are handling escaped characters.  See if we have
                ; already seen the backslash.
                bit tmp2+1
                bmi _escaped
                jmp _not_escaped

_escaped:

                ; We have seen a backslash (previous character). Check to see if
                ; we are in the middle of a \x sequence (bit 6 of tmp2+1 will
                ; be clear in that case )
                bvs _check_esc_chars

                ; We are in the middle of a \x sequence. Check to see if we
                ; are on the first or second digit.
                lda #1
                bit tmp2+1
                bne _esc_x_second_digit

                ; First digit.
                inc tmp2+1  ; Adjust flag for second digit next time.
                lda (tmp1)  ; Get the char again.

                ; Convert to hex
                jsr convert_hex_value

                ; This is the upper nybble, so move it up.
                asl
                asl
                asl
                asl
                sta tmp3    ; Save it for later.
                jmp _next_character

_esc_x_second_digit:

                ; We are on the second hex digit of a \x sequence. Clear the
                ; escaped character flag (because we are handling it right
                ; here)
                stz tmp2+1
                lda (tmp1)

                ; Convert to hex, combine with value in tmp3
                jsr convert_hex_value
                ora tmp3

                jmp _save_character

_check_esc_chars:
                ; Clear the escaped character flag (because we are
                ; handling it right here)
                stz tmp2+1

                ; Process the escaped character
_check_esc_a:
                cmp #'a
                bne _check_esc_b

                ; BEL (ASCII value 7)
                lda #7
                jmp _save_character

_check_esc_b:
                cmp #'b
                bne _check_esc_e

                ; Backspace (ASCII value 8)
                lda #8
                jmp _save_character

_check_esc_e:
                cmp #'e
                bne _check_esc_f

                ; ESC (ASCII value 27)
                lda #27
                bra _save_character

_check_esc_f:
                cmp #'f
                bne _check_esc_l

                ; FF (ASCII value 12)
                lda #12
                bra _save_character

_check_esc_l:
                cmp #'l
                bne _check_esc_m

                ; LF (ASCII value 10)
                lda #10
                bra _save_character

_check_esc_m:
                ; This one is not like the others because we save two
                ; characters
                cmp #'m
                bne _check_esc_n

                ; CR/LF pair (ASCII values 13, 10)
                lda #13
                jsr cmpl_a
                lda #10
                bra _save_character

_check_esc_n:
                cmp #'n
                bne _check_esc_q

                ; newline, impl. dependant, using LF (ASCII values 10)
                lda #10
                bra _save_character

_check_esc_q:
                cmp #'q
                bne _check_esc_r

                ; Double quote (ASCII value 34)
                lda #34
                bra _save_character

_check_esc_r:
                cmp #'r
                bne _check_esc_t

                ; CR (ASCII value 13)
                lda #13
                bra _save_character

_check_esc_t:
                cmp #'t
                bne _check_esc_v

                ; Horizontal TAB (ASCII value 9)
                lda #9
                bra _save_character

_check_esc_v:
                cmp #'v
                bne _check_esc_z

                ; Vertical TAB (ASCII value 11)
                lda #11
                bra _save_character

_check_esc_z:
                cmp #'z
                bne _check_esc_quote

                ; NULL (ASCII value 0)
                lda #0
                bra _save_character

_check_esc_quote:
                cmp #$22
                bne _check_esc_x

                ; Double quote (ASCII value 34)
                lda #34
                bra _save_character

_check_esc_x:
                cmp #'x
                bne _check_esc_backslash

                ; This one is difficult. We need to get the next TWO
                ; characters (which might require a refill in the middle)
                ; and combine them as two hex digits. We do this by
                ; clearing bit 6 of tmp2+1 to indicate we are in a digit
                ; and using bit 0 to keep track of which digit we are on.
                lda #$BE        ; Clear bits 6 and 0
                sta tmp2+1
                bra _next_character

_check_esc_backslash:
                cmp #$5C
                bne _not_escaped

                ; Backslash (ASCII value 92)
                lda #92
                bra _save_character

_not_escaped:
                ; Check for the backslash to see if we should escape
                ; the next char.
                cmp #$5C        ; The backslash char
                bne _regular_char

                ; We found a backslash.  Don't save anyhing, but set
                ; a flag (in tmp2+1) to handle the next char. We don't
                ; try to get the next char here as it may require a
                ; refill of the input buffer.
                lda #$FF
                sta tmp2+1
                bra _next_character

_regular_char:
                ; Check if the current character is the end of the string.
                cmp #$22        ; ASCII for "
                beq _found_string_end

_save_character:
                ; If we didn't reach the end of the string, compile this
                ; character into the dictionary
                jsr cmpl_a

_next_character:
                ; Move on to the next character.
                inc toin
                bne _savechars_loop_longjump
                inc toin+1

_savechars_loop_longjump:
                jmp _savechars_loop

_found_string_end:
                ; Use up the delimiter.
                inc toin
                bne +
                inc toin+1
*
                ; Calculate the length of the string, which is the
                ; difference between cp and the address of the start
                ; of the string (currently saved on the stack).
                lda cp
                sec
                sbc 2,x
                sta 0,x         ; LSB
                lda cp+1
                sbc 3,x
                sta 1,x         ; MSB

                ; Update the address of the jump-over jmp instruction.
                ; First determine location of jmp instructions address.
                ; It should be 2 bytes before the start of the string.
                ; Compute it into tmp1, which is no longer being used.
                lda 2,x
                sec
                sbc #2
                sta tmp1
                lda 3,x
                sbc #0          ; Propagate borrow
                sta tmp1+1

                ; Update the address of the jump to HERE.
                lda cp
                sta (tmp1)
                ldy #1
                lda cp+1
                sta (tmp1),y

                ; What happens next depends on the state (which is bad, but
                ; that's the way it works at the moment). If we are
                ; interpretating, we save the string to a transient buffer
                ; and return that address (used for file calls, see
                ; https://forth-standard.org/standard/file/Sq . If we're
                ; compiling, we just need SLITERAL
                lda state
                ora state+1             ; paranoid
                beq _done

                ; Jump into the middle of the sliteral word, after the
                ; string data has been compiled into the dictionary,
                ; because we've already done that step.
                jsr sliteral_const_str         ; ( addr u -- )

_done:
z_s_quote:      rts
.scend


; ## S_TO_D ( u -- d ) "Convert single cell number to double cell"
; ## "s>d"  auto  ANS core
        ; """https://forth-standard.org/standard/core/StoD"""
.scope
xt_s_to_d:
                jsr underflow_1

                dex
                dex
                stz 0,x
                stz 1,x

                lda 3,x
                bpl _done

                ; negative, extend sign
                dec 0,x
                dec 1,x
_done:
z_s_to_d:       rts
.scend


; ## SAVE_BUFFERS ( -- ) "Save all dirty buffers to storage"
; ## "save-buffers"  tested  ANS block
        ; """https://forth-standard.org/standard/block/SAVE-BUFFERS"""
.scope
xt_save_buffers:
                ; Check the buffer status
                ldy #buffstatus_offset
                lda (up),y      ; Only bits 0 and 1 are used, so only
                cmp #3          ; LSB is needed.
                bne _done       ; Either not used or not dirty = done!

                ; We need to save the block.
                jsr xt_blkbuffer
                jsr xt_buffblocknum
                jsr xt_fetch
                jsr xt_block_write

                ; Mark the buffer as clean now.
                lda #1
                ldy #buffstatus_offset
                sta (up),y

_done:
z_save_buffers: rts
.scend


; ## SCR ( -- addr ) "Push address of variable holding last screen listed"
; ## "scr"  auto  ANS block ext
        ; """https://forth-standard.org/standard/block/SCR"""
xt_scr:
                ; SCR is at UP + scr_offset
                dex
                dex
                clc
                lda up
                adc #scr_offset ; Add offset
                sta 0,x
                lda up+1
                adc #0          ; Adding carry
                sta 1,x

z_scr:          rts


; ## SEARCH ( addr1 u1 addr2 u2 -- addr3 u3 flag) "Search for a substring"
; ## "search"   auto  ANS string
        ; """https://forth-standard.org/standard/string/SEARCH
        ; Search for string2 (denoted by addr2 u2) in string1 (denoted by
        ; addr1 u1). If a match is found the flag will be true and
        ; addr3 will have the address of the start of the match and u3 will have
        ; the number of characters remaining from the match point to the end
        ; of the original string1. If a match is not found, the flag will be
        ; false and addr3 and u3 will be the original string1's addr1 and u1.
        ; """
.scope
xt_search:
                jsr underflow_4

                ; ANS says if the second string is a zero-length string it
                ; automatically matches.
                lda 0,x
                ora 1,x
                bne _start_search

                ; The second string is a zero length string.  Just remove
                ; the second string and put a true flag.
                inx             ; Remove u2
                inx
                lda #$FF        ; Turn addr2 into a true flag
                sta 0,x
                sta 1,x
                jmp z_search

_start_search:
                ; Put an offset (starting at zero) on the stack.
                jsr xt_zero

_search_loop:
                ; We stop (not found) when u2 + offset > u1
                ; Calculate u2+offset into tmp1
                clc
                lda 0,x
                adc 2,x
                sta tmp1
                lda 1,x
                adc 3,x


                ; Compare to u1. Start with the high byte
                cmp 7,x
                bcc _init_comparison ; Obviously less
                bne _not_found

                ; The upper address byte matched - check the lower byte
                ; Load u1 first so we can use just a carry to check.
                lda 6,x
                cmp tmp1
                bcs _init_comparison

_not_found:
                ; The substring isn't in the main string.
                ; Return just the main string and a false flag.
                inx             ; Remove offset
                inx
                inx             ; Remove u2
                inx
                stz 0,x         ; Turn addr2 into a false flag
                stz 1,x
                bra z_search

_init_comparison:
                ; Use tmp1 to hold address in string 1.
                ; Use tmp2 to hold address in string 2.
                ; Use tmp3 to hold the number of characters left to check.

                ; Compute the starting address in string 1
                ; as addr1 + offset
                clc
                lda 8,x
                adc 0,x
                sta tmp1
                lda 9,x
                adc 1,x
                sta tmp1+1

                ; The starting address in string 2 is just addr2.
                lda 4,x
                sta tmp2
                lda 5,x
                sta tmp2+1

                ; The number of characters to check is u2.
                lda 2,x
                sta tmp3
                lda 3,x
                sta tmp3+1

_comparison_loop:
                ; Check to see if the current characters match.
                lda (tmp1)
                cmp (tmp2)
                beq _letters_match

                ; One of the letters didn't match.
                ; Increment the offset and try again.
                jsr xt_one_plus
                bra _search_loop

_letters_match:
                ; The letters match.  Advance the pointers until the
                ; count reaches zero.
                inc tmp1
                bne +
                inc tmp1+1
*
                inc tmp2
                bne +
                inc tmp2+1
*
                ; Decrement the count of remaining letters to check.
                lda tmp3
                bne +
                dec tmp3+1
*
                dec tmp3

                ; Check if we've reached zero.
                lda tmp3
                ora tmp3+1
                bne _comparison_loop ; Check the next letter

                ; We've run out of letters and they all match!
                ; Return (addr1+offset) (u1-offset) true
                ; Add offset to addr1.
                clc
                lda 0,x
                adc 8,x
                sta 8,x
                lda 1,x
                adc 9,x
                sta 9,x

                ; Subtract offset from u1.
                sec
                lda 6,x
                sbc 0,x
                sta 6,x
                lda 7,x
                sbc 1,x
                sta 7,x

                ; Replace addr2, u2, and offset with a true flag.
                inx             ; drop offset
                inx
                inx             ; drop u2
                inx
                lda #$FF
                sta 0,x         ; Turn addr2 into a true flag.
                sta 1,x

z_search:       rts
.scend


; ## SEMICOLON ( -- ) "End compilation of new word"
; ## ";"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Semi
        ; End the compilation of a new word into the Dictionary.
        ;
        ; When we
        ; enter this, WORKWORD is pointing to the nt_ of this word in the
        ; Dictionary, DP to the previous word, and CP to the next free byte.
        ; A Forth definition would be (see "Starting Forth"):
        ; : POSTPONE EXIT  REVEAL POSTPONE ; [ ; IMMEDIATE  Following the
        ; practice of Gforth, we warn here if a word has been redefined.
        ; """
.scope
xt_semicolon:
                ; Check if this is a : word or a :NONAME word.
                bit status
                bvs _colonword

                ; This is a :NONAME word - just put an RTS on the end and
                ; the address (held in workword) on the stack.
                lda #$60                ; opcode for RTS
                jsr cmpl_a

                dex
                dex
                lda workword
                sta 0,x
                lda workword+1
                sta 1,x
                bra _semicolon_done

_colonword:
                ; CP is the byte that will be the address we use in the
                ; header as the end-of-compile address (z_word). This is
                ; six bytes down from the header
                ldy #6
                lda cp
                sta (workword),y
                iny
                lda cp+1
                sta (workword),y

                ; Allocate one further byte and save the RTS instruction
                ; there
                lda #$60                ; opcode for RTS
                jsr cmpl_a

                ; Before we formally add the word to the Dictionary, we
                ; check to see if it is already present, and if yes, we
                ; warn the user.

                ; See if word already in Dictionary.
                ; (STATUS bit 7 will be high as CREATE already
                ;  checked for us.)
                bit status
                bpl _new_word   ; Bit 7 is clear = new word

                ; We start by putting the string of the
                ; word we're defining on the stack
                dex
                dex
                dex
                dex

                ; WORKWORD points to the beginning of the head of our new
                ; word, where the first byte is the length of the string
                ; We can't use LATESTNT because we haven't added the new
                ; word to the Dictionary yet
                lda (workword)
                sta 0,x
                stz 1,x

                ; Eight bytes below WORKWORD is the actual beginning of
                ; the string
                lda workword
                clc
                adc #8
                sta 2,x
                lda workword+1
                adc #0                  ; only want carry
                sta 3,x

                ; This word is already in the Dictionary, so we print a
                ; warning to the user.
                lda #str_redefined       ; address of string "redefined"
                jsr print_string_no_lf

                ; Now we print the offending word.
                jsr xt_type
                jsr xt_space

                ; Clear bit 7 of status (so future words will print message
                ; by defaut)
                lda #%10000000
                trb status

_new_word:
                ; Let's get this over with. Save beginning of our word
                ; as new last word in the Dictionary
                lda workword
                sta dp
                lda workword+1
                sta dp+1
                jsr dp_to_current       ; Save the updated DP to the
                                        ; CURRENT wordlist.
_semicolon_done:
                ; Word definition complete. Return compile flag to zero
                ; to return to interpret mode
                stz state
                stz state+1

z_semicolon:    rts
.scend


; ## SIGN ( n -- ) "Add minus to pictured output"
; ## "sign"  auto  ANS core
        ; """https://forth-standard.org/standard/core/SIGN
        ;
        ; Code based on
        ; http://pforth.googlecode.com/svn/trunk/fth/numberio.fth
        ; Original Forth code is   0< IF ASCII - HOLD THEN
        ; """
.scope
xt_sign:
                jsr underflow_1

                lda 1,x         ; check MSB of TOS
                bmi _minus

                inx
                inx
                bra _done
_minus:
                lda #$2D        ; ASCII for "-"
                sta 0,x         ; overwrite TOS
                stz 1,x         ; paranoid

                jsr xt_hold
_done:
z_sign:         rts
.scend


; ## SLASH ( n1 n2 -- n ) "Divide NOS by TOS"
; ## "/"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Div
        ;
        ; Forth code is either  >R S>D R> FM/MOD SWAP DROP
        ; or >R S>D R> SM/REM SWAP DROP -- we use SM/REM in Tali Forth.
        ; This code is currently unoptimized. This code without the SLASH
        ; DROP at the end is /MOD, so we share the code as far as possible.
        ; """
.scope
xt_slash:
                ; With all the multiplication going on, it would be hard to
                ; make sure that one of our temporary variables is not
                ; overwritten. We make sure that doesn't happen by taking the
                ; hit of pushing the flag to the 65c02's stack
                lda #0
                pha
                bra _common

xt_slash_mod:
                ; Note that /MOD accesses this code
                lda #$FF
                pha             ; falls through to _common

_common:
                jsr xt_to_r             ; >R
                jsr xt_s_to_d           ; S>D
                jsr xt_r_from           ; R>
                jsr xt_sm_slash_rem     ; SM/REM

                ; Get the flag back from the 65c02's stack. Zero is SLASH,
                ; $FF is SLASH MOD
                pla
                bne _done

                ; The following code is for SLASH only
                jsr xt_swap
                inx             ; DROP
                inx
_done:
z_slash_mod:
z_slash:        rts
.scend


; ## SLASH_MOD ( n1 n2 -- n3 n4 ) "Divide NOS by TOS with a remainder"
; ## "/mod"  auto  ANS core
        ; """https://forth-standard.org/standard/core/DivMOD
        ;
        ; This is a dummy entry, the actual code is shared with SLASH
        ; """


; ## SLASH_STRING ( addr u n -- addr u ) "Shorten string by n"
; ## "/string"  auto  ANS string
        ; """https://forth-standard.org/standard/string/DivSTRING
        ;
        ; Forth code is
        ; : /STRING ( ADDR U N -- ADDR U ) ROT OVER + ROT ROT - ;
        ; Put differently, we need to add TOS and 3OS, and subtract
        ; TOS from NOS, and then drop TOS
        ; """
.scope
xt_slash_string:
                jsr underflow_3

                clc             ; 3OS+TOS
                lda 0,x
                adc 4,x
                sta 4,x

                lda 1,x
                adc 5,x
                sta 5,x

                sec             ; NOS-TOS
                lda 2,x
                sbc 0,x
                sta 2,x

                lda 3,x
                sbc 1,x
                sta 3,x

                inx
                inx

z_slash_string: rts
.scend


; ## SLITERAL ( addr u -- )( -- addr u ) "Compile a string for runtime"
; ## "sliteral" auto  ANS string
        ; """https://forth-standard.org/standard/string/SLITERAL
        ; Add the runtime for an existing string.
        ; """
.scope
xt_sliteral:
                jsr underflow_2

                ; We can't assume that ( addr u ) of the current string is in
                ; a stable area (eg. already in the dictionary.) Copy the
                ; string data into the dictionary using move.

                ; Put a jmp over the string data with address to be filled
                ; in later.
                lda #$4C
                jsr cmpl_a

                ; Address to be filled in later.
                jsr cmpl_a
                jsr cmpl_a

                ; Turn the data stack from ( addr u ) into
                ; ( here u addr here u ) so move can be called with
                ; the remaining items on the stack ready for processing.
                ; Reserve three extra words on the stack.
                txa
                sec
                sbc #6
                tax

                ; Move addr down from TOS-4 to TOS-2
                lda 8,x
                sta 4,x
                lda 9,x
                sta 5,x

                ; Copy u from TOS-3 to TOS
                lda 6,x
                sta 0,x
                lda 7,x
                sta 1,x

                ; Put HERE into TOS-1 and TOS-4
                lda cp
                sta 8,x
                sta 2,x
                lda cp+1
                sta 9,x
                sta 3,x

                ; Copy the string into the dictionary.
                jsr xt_move

                ; Update cp.
                clc
                lda cp
                adc 0,x
                sta cp
                lda cp+1
                adc 1,x
                sta cp+1

                ; Update the address of the jump-over jmp instruction.
                ; First determine location of jmp instructions address.
                ; It should be 2 bytes before the start of the string.

                ; Compute it into tmp1, which is no longer being used.
                lda 2,x
                sec
                sbc #2
                sta tmp1
                lda 3,x
                sbc #0          ; Propagate borrow
                sta tmp1+1

                ; Update the address of the jump to HERE.
                lda cp
                sta (tmp1)
                ldy #1
                lda cp+1
                sta (tmp1),y

                ; Stack is now ( addr2 u ) where addr2 is the new
                ; location in the dictionary.

sliteral_const_str:
                ; Compile a subroutine jump to the runtime of SLITERAL that
                ; pushes the new ( addr u ) pair to the Data Stack.
                ; When we're done, the code will look like this:

                ; xt -->    jmp a
                ;           <string data bytes>
                ;  a -->    jsr sliteral_runtime
                ;           <string address>
                ;           <string length>
                ; rts -->

                ; This means we'll have to adjust the return address for two
                ; cells, not just one
                ldy #>sliteral_runtime
                lda #<sliteral_runtime
                jsr cmpl_subroutine

                ; We want to have the address end up as NOS and the length
                ; as TOS, so we store the address first
                ldy 3,x                ; address MSB
                lda 2,x                ; address LSB
                jsr cmpl_word

                ldy 1,x                ; length MSB
                lda 0,x                ; length LSB
                jsr cmpl_word

                ; clean up and leave
                inx
                inx
                inx
                inx

z_sliteral:     rts
.scend

sliteral_runtime:
.scope
        ; """Run time behaviour of SLITERAL: Push ( addr u ) of string to
        ; the Data Stack. We arrive here with the return address as the
        ; top of Return Stack, which points to the address of the string
        ; """
                dex
                dex
                dex
                dex

                ; Get the address of the string address off the stack and
                ; increase by one because of the RTS mechanics
                pla
                sta tmp1        ; LSB of address
                pla
                sta tmp1+1      ; MSB of address

                ; Walk through both and save them
                ldy #1          ; adjust for JSR/RTS mechanics on 65c02
                lda (tmp1),y
                sta 2,x         ; LSB of address
                iny

                lda (tmp1),y
                sta 3,x         ; MSB of address
                iny

                lda (tmp1),y
                sta 0,x         ; LSB of length
                iny

                lda (tmp1),y
                sta 1,x         ; MSB of length

                ; restore return address
                clc
                lda tmp1
                adc #4
                tay             ; LSB
                lda tmp1+1
                adc #0          ; we only need carry
                pha             ; MSB
                phy

                rts
.scend


; ## SM_SLASH_REM ( d n1 -- n2 n3 ) "Symmetic signed division"
; ## "sm/rem"  auto  ANS core
        ; """https://forth-standard.org/standard/core/SMDivREM
        ; Symmetic signed division. Compare FM/MOD. Based on F-PC 3.6
        ; by Ulrich Hoffmann. See http://www.xlerb.de/uho/ansi.seq
        ;
        ; Forth:
        ; OVER >R 2DUP XOR 0< >R ABS >R DABS R> UM/MOD R> ?NEGATE SWAP
        ; R> ?NEGATE SWAP
        ; """
.scope
xt_sm_slash_rem:
                jsr underflow_3 ; contains double number

                ; push MSB of high cell of d to Data Stack so we can check
                ; its sign later
                lda 3,x
                pha

                ; XOR the MSB of the high cell of d and n1 so we figure out
                ; its sign later as well
                lda 1,x
                eor 3,x
                pha

                ; Prepare division by getting absolute of n1 and d
                jsr xt_abs
                inx             ; pretend we pushed n1 to R
                inx

                jsr xt_dabs
                dex
                dex

                jsr xt_um_slash_mod     ; UM/MOD

                ; if the XOR compiled above is negative, negate the
                ; quotient (n3)
                pla
                bpl +
                jsr xt_negate
*
                ; if d was negative, negate the remainder (n2)
                pla
                bpl _done

                inx             ; pretend we pushed quotient to R
                inx
                jsr xt_negate
                dex
                dex

_done:
z_sm_slash_rem: rts
.scend


; ## SOURCE ( -- addr u ) "Return location and size of input buffer""
; ## "source"  auto  ANS core
        ; """https://forth-standard.org/standard/core/SOURCE"""
xt_source:
                ; add address
                dex
                dex
                lda cib
                sta 0,x
                lda cib+1
                sta 1,x

                ; add size
                dex
                dex
                lda ciblen
                sta 0,x
                lda ciblen+1
                sta 1,x

z_source:       rts


; ## SOURCE_ID ( -- n ) "Return source identifier"
; ## "source-id"  tested  ANS core ext
        ; """https://forth-standard.org/standard/core/SOURCE-ID Identify the
        ; input source unless it is a block (s. Conklin & Rather p. 156). This
        ; will give the input source: 0 is keyboard, -1 ($FFFF) is character
        ; string, and a text file gives the fileid.
        ; """
xt_source_id:
                dex
                dex

                lda insrc
                sta 0,x
                lda insrc+1
                sta 1,x

z_source_id:    rts


; ## SPACE ( -- ) "Print a single space"
; ## "space"  auto  ANS core
        ; """https://forth-standard.org/standard/core/SPACE"""
xt_space:
                lda #AscSP
                jsr emit_a

z_space:        rts


; ## SPACES ( u -- ) "Print a number of spaces"
; ## "spaces"  auto  ANS core
        ; """https://forth-standard.org/standard/core/SPACES"""
.scope
xt_spaces:
                jsr underflow_1

                ; catch any zero in TOS fast
                lda 0,x
                ora 1,x
                beq _done

                ; Usually we're only going to print far less than 256 spaces,
                ; so we create a quick loop for that. Short loop could be realized
                ; as a separate subroutine, but unless we're really pressed for
                ; memory at some point, this is faster
                ldy 1,x
                bne _lots_of_spaces

                ldy 0,x
_quick_loop:
                ; we reach here knowing that there must be a number that is not
                ; zero in the TOS
                lda #AscSP
                jsr emit_a
                dey
                beq _done
                bra _quick_loop

_lots_of_spaces:
                ; We go through the first loop once to get rid of the lower
                ; counter byte. This could be zero
                ldy 0,x

_first_slow_loop:
                beq _slow_outer_loop
                lda #AscSP
                jsr emit_a
                dey
                bra _first_slow_loop

_slow_outer_loop:
                ; we arrive here knowing that the MSB of TOS cannot be a zero
                ldy #00

_slow_inner_loop:
                lda #AscSP
                jsr emit_a
                dey
                bne _slow_inner_loop

                dec 1,x
                bne _slow_outer_loop

_done:
                inx             ; drop
                inx

z_spaces:       rts
.scend


; ## STAR ( n n -- n ) "16*16 --> 16 "
; ## "*"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Times
        ; Multiply two signed 16 bit numbers, returning a 16 bit result.
        ;
        ; This is nothing  more than UM* DROP
        ; """
.scope
xt_star:
                jsr underflow_2

                jsr xt_um_star
                inx
                inx

z_star:         rts
.scend


; ## STAR_SLASH  ( n1 n2 n3 -- n4 ) "n1 * n2 / n3 -->  n"
; ## "*/"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TimesDiv
        ; Multiply n1 by n2 and divide by n3, returning the result
        ; without a remainder. This is */MOD without the mod.
        ;
        ; This word
        ; can be defined in Forth as : */  */MOD SWAP DROP ; which is
        ; pretty much what we do here
        ; """
xt_star_slash:
                ; We let */MOD check for underflow
                jsr xt_star_slash_mod
                jsr xt_swap
                inx
                inx
z_star_slash:
                rts


; ## STAR_SLASH_MOD  ( n1 n2 n3 -- n4 n5 ) "n1 * n2 / n3 --> n-mod n"
; ## "*/mod"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TimesDivMOD
        ; Multiply n1 by n2 producing the intermediate double-cell result d.
        ; Divide d by n3 producing the single-cell remainder n4 and the
        ; single-cell quotient n5.
        ;
        ; In Forth, this is
        ; : */MOD  >R M* >R SM/REM ;  Note that */ accesses this routine.
        ; """
xt_star_slash_mod:
                jsr underflow_3

                jsr xt_to_r
                jsr xt_m_star
                jsr xt_r_from
                jsr xt_sm_slash_rem

z_star_slash_mod:
                rts


; ## STATE ( -- addr ) "Return the address of compilation state flag"
; ## "state"  auto  ANS core
        ; """https://forth-standard.org/standard/core/STATE
        ; STATE is true when in compilation state, false otherwise. Note
        ; we do not return the state itself, but only the address where
        ; it lives. The state should not be changed directly by the user; see
        ; http://forth.sourceforge.net/standard/dpans/dpans6.htm#6.1.2250
        ; """
xt_state:
                dex
                dex
                lda #<state
                sta 0,x
                lda #>state
                sta 1,x

z_state:        rts


; ## STORE ( n addr -- ) "Store TOS in memory"
; ## "!"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Store"""
xt_store:
                jsr underflow_2

                lda 2,x         ; LSB
                sta (0,x)

                inc 0,x
                bne +
                inc 1,x
*
                lda 3,x         ; MSB
                sta (0,x)

                inx             ; 2DROP
                inx
                inx
                inx

z_store:        rts


; ## STRIP_UNDERFLOW ( -- addr ) "Return address where underflow status is kept"
; ## "strip-underflow"  tested  Tali Forth
        ; """`STRIP-UNDERFLOW` is a flag variable that determines if underflow
        ; checking should be removed during the compilation of new words.
        ; Default is false.
        ; """
xt_strip_underflow:
                dex
                dex

                lda #<uf_strip
                sta 0,x
                lda #>uf_strip
                sta 1,x

z_strip_underflow:
                rts


; ## SWAP ( b a -- a b ) "Exchange TOS and NOS"
; ## "swap"  auto  ANS core
        ; """https://forth-standard.org/standard/core/SWAP"""
xt_swap:
                jsr underflow_2

                lda 0,x         ; LSB
                ldy 2,x
                sta 2,x
                sty 0,x

                lda 1,x         ; MSB
                ldy 3,x
                sta 3,x
                sty 1,x

z_swap:         rts


; ## THEN (C: orig -- ) ( -- ) "Conditional flow control"
; ## "then"  auto  ANS core
        ; """http://forth-standard.org/standard/core/THEN"""
xt_then:
                ; Get the address to jump to.
                jsr xt_here

                ; Stuff HERE in for the branch address back
                ; at the IF or ELSE (origination address is on stack).
                jsr xt_swap
                jsr xt_store

z_then:         rts


; ## THRU ( scr# scr# -- ) "Load screens in the given range"
; ## "thru"  tested  ANS block ext
        ; """https://forth-standard.org/standard/block/THRU"""
.scope
xt_thru:
                jsr underflow_2

                ; We need to loop here, and can't use the data stack
                ; because the LOADed screens might use it.  We'll
                ; need to use the same trick that DO loops use, holding
                ; the limit and current index on the return stack.

                ; Put the ending screen number on the return stack
                lda 1,x
                pha
                lda 0,x
                pha
                inx
                inx
_thru_loop:
                ; Put the starting screen number on the stack,
                ; but keep a copy
                lda 1,x
                pha
                lda 0,x
                pha

                ; Load this screen.
                jsr xt_load

                ; Get the number and limit back off the stack.  Rather than
                ; waste time making room on the stack, just use tmp1 and tmp2.

                ; Get the screen we just loaded.
                pla
                sta tmp1
                pla
                sta tmp1+1

                ; Get the ending screen.
                pla
                sta tmp2
                pla
                sta tmp2+1

                ; See if we just loaded the last screen.
                ; A already has the MSB of the last screen in it.
                cmp tmp1+1
                bne _next_screen
                lda tmp2        ; Compare the LSB
                cmp tmp1
                bne _next_screen
                bra _done       ; We just did the last screen.

_next_screen:
                ; Put the ending screen back on the data stack.
                lda tmp2+1
                pha
                lda tmp2
                pha

                ; Increment the current screen.
                inc tmp1
                bne +
                inc tmp1+1
*
                ; Put the current screen on the stack to prepare for
                ; the next loop.
                dex
                dex
                lda tmp1
                sta 0,x
                lda tmp1+1
                sta 1,x
                bra _thru_loop
_done:
z_thru:         rts
.scend


; ## TICK ( "name" -- xt ) "Return a word's execution token (xt)"
; ## "'"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Tick"""
.scope
xt_tick:
                jsr xt_parse_name       ; ( -- addr u )

                ; if we got a zero, there was a problem getting the
                ; name of the word
                lda 0,x
                ora 1,x
                bne +

                lda #err_noname
                jmp error
*
                jsr xt_find_name        ; ( addr u -- nt )

                ; If we didn't find the word in the Dictionary, abort
                lda 0,x
                ora 1,x
                bne +

                lda #err_syntax
                jmp error
*
                jsr xt_name_to_int      ; ( nt -- xt )

z_tick:         rts
.scend


; ## TO ( n "name" -- ) or ( "name") "Change a value"
; ## "to"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/TO
        ; Gives a new value to a, uh, VALUE.
        ;
        ; One possible Forth
        ; implementation is  ' >BODY !  but given the problems we have
        ; with >BODY on STC Forths, we do this the hard way. Since
        ; Tali Forth uses the same code for CONSTANTs and VALUEs, you
        ; could use this to redefine a CONSTANT, but that is a no-no.
        ;
        ; Note that the standard has different behaviors for TO depending
        ; on the state (https://forth-standard.org/standard/core/TO).
        ; This makes TO state-dependent (which is bad) and also rather
        ; complex (see the Gforth implementation for comparison). This
        ; word may not be natively compiled and must be immediate. Frankly,
        ; it would have made more sense to have two words for this.
        ; """
.scope
xt_to:
                ; One way or the other, we need the xt of the word after this
                ; one. At this point, we don't know if we are interpreted or
                ; compile, so we don't know if there is a value n on the stack,
                ; so we can't do an underflow check yet
                jsr xt_tick             ; ( [n] xt )

                ; The PFA (DFA in this case) is three bytes down,
                ; after the jump to DOCONST
                lda 0,x                 ; LSB
                clc
                adc #3
                sta tmp1
                lda 1,x                 ; MSB
                adc #0                  ; we just want the carry
                sta tmp1+1

                inx
                inx                     ; ( [n] )

                ; Now it gets ugly. See which state we are in
                lda state
                ora state+1
                beq _interpret

                ; Well, we're compiling. We want to end up with simple
                ; code that just takes the number that is TOS and saves
                ; it in the address of the xt we were just given. So we
                ; want to compile this routine:
                ;
                ;       lda 0,x                 - B5 00
                ;       sta <ADDR_LSB>          - 8D LSB MSB
                ;       lda 1,x                 - B5 01
                ;       sta <ADDR_LSB>          - 8D LSB MSB
                ;       inx                     - E8
                ;       inx                     - E8
                ;
                ; which at least is nice and short. Other than that, we pretty
                ; much have to do this the hard and long way, because with the
                ; LSBs and MSBs, we can't really put the numbers in a data
                ; range and store them with a loop. Sigh.

                ldy #$00                ; Code for LDA 0,X
                lda #$B5
                jsr cmpl_word

                lda #$8D                ; Code for STA abs
                jsr cmpl_a

                ldy tmp1+1              ; MSB goes in Y
                lda tmp1
                jsr cmpl_word

                ldy #$01                ; Code for LDA 1,X
                lda #$B5
                jsr cmpl_word

                lda #$8D                ; Code for STA abs
                jsr cmpl_a

                inc tmp1                ; Calculate MSB
                bne +
                inc tmp1+1
*
                ldy tmp1+1              ; MSB goes in Y
                lda tmp1
                jsr cmpl_word

                ldy #$E8                ; Code for INX
                tya
                jsr cmpl_word

                bra _done

_interpret:
                ; We're interpreting, so we arrive here with n
                ; on the stack. This is an annoying place to put
                ; the underflow check because we can't
                ; automatically strip it out
                jsr underflow_1

                ; We skip over the jump to DOCONST and store the number
                ; in the Program Field Area (PDF, in this case more a
                ; Data Field Area
                lda 0,x
                sta (tmp1)              ; LSB

                ldy #1
                lda 1,x                 ; MSB
                sta (tmp1),y            ; fall through to common

                inx                     ; DROP
                inx
_done:
z_to:           rts
.scend


; ## TO_BODY ( xt -- addr ) "Return a word's Code Field Area (CFA)"
; ## ">body"  auto  ANS core
        ; """https://forth-standard.org/standard/core/toBODY
        ; Given a word's execution token (xt), return the address of the
        ; start of that word's parameter field (PFA). This is defined as the
        ; address that HERE would return right after CREATE.
        ;
        ; This is a
        ; difficult word for STC Forths, because most words don't actually
        ; have a Code Field Area (CFA) to skip. We solve this by having CREATE
        ; add a flag, "has CFA" (HC), in the header so >BODY know to skip
        ; the subroutine jumps to DOVAR, DOCONST, or DODOES
        ; """
.scope
xt_to_body:
                jsr underflow_1

                ; Ideally, xt already points to the CFA. We just need to check
                ; the HC flag for special cases
                jsr xt_dup              ; ( xt xt )
                jsr xt_int_to_name      ; ( xt nt )

                ; The status byte is nt+1
                inc 0,x
                bne +
                inc 1,x
*
                lda (0,x)               ; get status byte
                and #HC
                beq _no_cfa

                ; We've got a DOVAR, DOCONST, DODEFER, DODOES or whatever,
                ; so we add three to xt, which is NOS
                clc
                lda 2,x         ; LSB
                adc #3
                sta 2,x
                lda 3,x         ; MSB
                adc #0          ; we conly care about the carry
                sta 3,x         ; Fall through to _no_cfa
_no_cfa:
                inx             ; get rid of the nt
                inx
_done:
z_to_body:      rts
.scend


; ## TO_IN ( -- addr ) "Return address of the input pointer"
; ## ">in"  auto  ANS core
xt_to_in:
                dex
                dex

                lda #<toin
                sta 0,x
                lda #>toin      ; paranoid, should be zero
                sta 1,x

z_to_in:        rts


; ## TO_NUMBER ( ud addr u -- ud addr u ) "Convert a number"
; ## ">number"  auto  ANS core
        ; """https://forth-standard.org/standard/core/toNUMBER
        ; Convert a string to a double number. Logic here is based on the
        ; routine by Phil Burk of the same name in pForth, see
        ; https://github.com/philburk/pforth/blob/master/fth/numberio.fth
        ; for the original Forth code. We arrive here from NUMBER which has
        ; made sure that we don't have to deal with a sign and we don't have
        ; to deal with a dot as a last character that signalizes double -
        ; this should be a pure number string.
        ;
        ; This routine calles UM*, which uses tmp1, tmp2 and tmp3, so we
        ; cannot access any of those.
        ;
        ; For the math routine, we move the inputs to the scratchpad to
        ; avoid having to fool around with the Data Stack.
        ;
        ;     +-----+-----+-----+-----+-----+-----+-----+-----+
        ;     |   UD-LO   |   UD-HI   |     N     | UD-HI-LO  |
        ;     |           |           |           |           |
        ;     |  S    S+1 | S+2   S+3 | S+4   S+5 | S+6   S+7 |
        ;     +-----+-----+-----+-----+-----+-----+-----+-----+
        ;
        ; The math routine works by converting one character to its
        ; numerical value (N) via DIGIT? and storing it in S+4 for
        ; the moment. We then multiply the UD-HI value with the radix
        ; (from BASE) using UM*, which returns a double-cell result. We
        ; discard the high cell of that result (UD-HI-HI) and store the
        ; low cell (UD-HI-LO) in S+6 for now. -- The second part is
        ; multiplying UD-LO with the radix. The high cell (UD-LO-HI)
        ; gets put in S+2, the low cell (HD-LO-LO) in S. We then use
        ; a version of D+ to add ( S S+2 ) and ( S+4 S+6) together,
        ; storing the result back in S and S+2, before we start another
        ; round with it as the new UD-LO and UD-HI.
        ; """

.scope
xt_to_number:
                jsr underflow_4

                ; Fill the scratchpad. We arrive with ( ud-lo ud-hi addr u ).
                ; After this step, the original ud-lo and ud-hi will still be on
                ; the Data Stack, but will be ignored and later overwritten
                ; If >NUMBER is called by NUMBER, these should be all zeros
                lda 6,x         ; ud-lo LSB
                sta scratch
                lda 7,x         ; ud-lo MSB
                sta scratch+1

                lda 4,x         ; ud-hi LSB
                sta scratch+2
                lda 5,x         ; ud-hi MSB
                sta scratch+3

                ; Push down one on the Data Stack to use TOS for character
                ; conversion ( ud-lo ud-hi addr u x )
                dex
                dex

_loop:
                ; Get one character based on address
                lda (4,x)
                sta 0,x                 ; ( ud-lo ud-hi addr u char )
                stz 1,x                 ; paranoid

                jsr xt_digit_question   ; ( char -- n -1 | char 0 )

                ; This gives us ( ud-lo ud-hi addr u char f | n f ), so we
                ; check the flag. If it is zero, we return what we have and
                ; let the caller (usually NUMBER) complain
                lda 0,x
                bne _digit_ok

                inx
                inx
                bra _done       ; ( ud-lo ud-hi addr u char )

_digit_ok:
                ; Conversion was successful. We arrive here with
                ; ( ud-lo ud-hi addr u n -1 ) and can start the
                ; math routine

                ; Save n so we don't have to fool around with the
                ; Data Stack
                lda 2,x
                sta scratch+4
                lda 3,x
                sta scratch+5

                ; Now multiply ud-hi (the one in the scratchpad, not the
                ; original one on the Data Stack) with the radix from BASE.
                ; We can clobber TOS and NOS because we saved n
                lda scratch+2
                sta 2,x         ; NOS
                lda scratch+3
                sta 3,x

                lda base
                sta 0,x         ; TOS
                stz 1,x         ; now ( ud-lo ud-hi addr u ud-hi base)

                ; UM* returns a double-celled number
                jsr xt_um_star  ; ( ud-lo ud-hi addr u ud-hi-lo ud-hi-hi )

                ; Move ud-hi-lo to safety
                lda 2,x         ; ud-hi-lo
                sta scratch+6
                lda 3,x
                sta scratch+7

                ; Now we multiply ud-lo, overwriting the stack entries
                lda scratch
                sta 2,x
                lda scratch+1
                sta 3,x         ; ( ud-lo ud-hi addr u ud-lo ud-hi-hi )

                lda base
                sta 0,x
                stz 1,x         ; ( ud-lo ud-hi addr u ud-lo base )

                jsr xt_um_star  ; ( ud-lo ud-hi addr u ud-lo-lo ud-lo-hi )

                lda 0,x
                sta scratch+2
                lda 1,x
                sta scratch+3

                lda 2,x
                sta scratch
                lda 3,x
                sta scratch+1

                ; We add ud-lo and n, as well as ud-hi and ud-hi-lo,
                ; both in the scratch pad
                clc
                lda scratch     ; ud-lo LSB
                adc scratch+4   ; n LSB
                sta scratch     ; this is the new ud-lo
                lda scratch+1   ; ud-lo MSB
                adc scratch+5   ; n MSB
                sta scratch+1

                lda scratch+2   ; LSB
                adc scratch+6
                sta scratch+2   ; this is the new ud-hi
                lda scratch+3   ; MSB
                adc scratch+7
                sta scratch+3

                ; Clean up: Get rid of one of the two top elements on
                ; the Data Stack. We don't really care which one
                inx
                inx             ; ( ud-lo ud-hi addr u ud-lo-lo )

                ; One character down. Move address up
                inc 4,x
                bne +
                inc 5,x
*
                ; Decrease counter
                dec 2,x
                bne _loop

_done:
                ; Counter has reached zero or we have an error. In both
                ; cases, we clean up the Data Stack and return. Error gives
                ; us ( ud-lo ud-hi addr u char ), regular end is
                ; ( ud-lo ud-hi addr u ud-lo )
                inx
                inx             ; ( ud-lo ud-hi addr u )

                ; The new ud-lo and ud-hi are still on the scratch pad
                lda scratch     ; new ud-lo
                sta 6,x
                lda scratch+1
                sta 7,x

                lda scratch+2
                sta 4,x
                lda scratch+3
                sta 5,x

z_to_number:    rts
.scend


; ## TO_ORDER ( wid -- ) "Add wordlist at beginning of search order"
; ## ">order"  tested  Gforth search
        ; """https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Word-Lists.html"""
.scope
xt_to_order:
                ; Put the wid on the return stack for now.
                jsr xt_to_r

                ; Get the current search order.
                jsr xt_get_order

                ; Get back the wid and add it to the list.
                jsr xt_r_from
                jsr xt_swap
                jsr xt_one_plus

                ; Set the search order with the new list.
                jsr xt_set_order

z_to_order:     rts
.scend


; ## TO_R ( n -- )(R: -- n) "Push TOS to the Return Stack"
; ## ">r"  auto  ANS core
        ; """https://forth-standard.org/standard/core/toR
        ; This word is handled differently for native and for
        ; subroutine coding, see `COMPILE,`. This is a complile-only
        ; word.
        ; """
xt_to_r:
                ; Save the return address. If this word is natively
                ; coded, this is a complete waste of cycles, but
                ; required for subroutine coding
                pla             ; LSB
                sta tmptos
                ply             ; MSB

                ; --- CUT HERE FOR NATIVE CODING ---

                ; We check for underflow in the second step, so we can
                ; strip off the stack thrashing for native compiling first
                jsr underflow_1

                ; now we can do the actual work
                lda 1,x         ; MSB
                pha
                lda 0,x         ; LSB
                pha

                inx
                inx

                ; --- CUT HERE FOR NATIVE CODING ---

                ; restore return address
                phy             ; MSB
                lda tmptos
                pha             ; LSB

z_to_r:         rts


; ## TRUE ( -- f ) "Push TRUE flag to Data Stack"
; ## "true"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/TRUE"""
xt_true:
                dex
                dex
                lda #$FF
                sta 0,x
                sta 1,x

z_true:         rts


; ## TUCK ( b a -- a b a ) "Copy TOS below NOS"
; ## "tuck"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/TUCK"""
xt_tuck:
                jsr underflow_2

                dex
                dex

                ldy 4,x         ; LSB
                lda 2,x
                sta 4,x
                sty 2,x
                sta 0,x

                ldy 5,x         ; MSB
                lda 3,x
                sta 5,x
                sty 3,x         ; bba
                sta 1,x         ; baa

z_tuck:         rts


; ## TWO ( -- u ) "Push the number 2 to stack"
; ## "2"  auto  Tali Forth
        ;
        ; This code is shared with ASSEMBLER-WORDLIST
xt_assembler_wordlist:
xt_two:
                dex
                dex
                lda #2
                sta 0,x
                stz 1,x

z_assembler_wordlist:
z_two:          rts


; ## TWO_DROP ( n n -- ) "Drop TOS and NOS"
; ## "2drop"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TwoDROP"""
xt_two_drop:
                jsr underflow_2

                inx
                inx
                inx
                inx

z_two_drop:     rts


; ## TWO_DUP ( a b -- a b a b ) "Duplicate first two stack elements"
; ## "2dup"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TwoDUP"""
xt_two_dup:
                jsr underflow_2

                dex
                dex
                dex
                dex

                lda 4,x         ; TOS
                sta 0,x
                lda 5,x
                sta 1,x

                lda 6,x         ; NOS
                sta 2,x
                lda 7,x
                sta 3,x

z_two_dup:      rts


; ## TWO_FETCH ( addr -- n1 n2 ) "Fetch the cell pair n1 n2 stored at addr"
; ## "2@"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TwoFetch
        ; Note n2 stored at addr and n1 in the next cell -- in our case,
        ; the next two bytes. This is equvalent to  `DUP CELL+ @ SWAP @`
        ; """
xt_two_fetch:
                jsr underflow_1

                lda 0,x
                sta tmp1
                ldy 1,x
                sty tmp1+1

                dex             ; reuse one stack element
                dex

                lda (tmp1)      ; copy LSB
                sta 0,x
                ldy #1          ; copy next
                lda (tmp1),y
                sta 1,x
                iny             ; copy next
                lda (tmp1),y
                sta 2,x
                iny             ; copy next
                lda (tmp1),y
                sta 3,x

z_two_fetch:    rts

; ## TWO_OVER ( d1 d2 -- d1 d2 d1 ) "Copy double word NOS to TOS"
; ## "2over"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TwoOVER"""
xt_two_over:
                jsr underflow_4

                dex
                dex
                dex
                dex

                lda 8,x
                sta 0,x

                lda 9,x
                sta 1,x

                lda 10,x
                sta 2,x

                lda 11,x
                sta 3,x

z_two_over:     rts


; ## TWO_R_FETCH ( -- n n ) "Copy top two entries from Return Stack"
; ## "2r@"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/TwoRFetch
        ;
        ; This is R> R> 2DUP >R >R SWAP but we can do it a lot faster in
        ; assembler. We use trickery to access the elements on the Return
        ; Stack instead of pulling the return address first and storing
        ; it somewhere else like for 2R> and 2>R. In this version, we leave
        ; it as Never Native; at some point, we should compare versions to
        ; see if an Always Native version would be better
        ; """
xt_two_r_fetch:
		; make room on the Data Stack
                dex
                dex
                dex
                dex

                ; Get four bytes off of Return Stack. This assumes that
                ; we took a subroutine jump here so the first two entries
                ; are the return address
                txa
                tsx
                phx             ; 65c02 has no TXY, so do it the hard way
                ply
                tax

                ; The Return Stack addreses $0101 and $0102 are occupied by
                ; the return address for this word. This is a whole lot
                ; easier on the 65816
                lda $0103,y     ; LSB of top entry
                sta 0,x
                lda $0104,y     ; MSB of top entry
                sta 1,x
                lda $0105,y     ; LSB of bottom entry
                sta 2,x
                lda $0106,y     ; MSB of top entry
                sta 3,x

z_two_r_fetch:  rts


; ## TWO_R_FROM ( -- n1 n2 ) (R: n1 n2 -- ) "Pull two cells from Return Stack"
; ## "2r>"  auto  ANS core ext
	    ; """https://forth-standard.org/standard/core/TwoRfrom
        ; Pull top two entries from Return Stack.
        ;
        ; Is the same as
        ; R> R> SWAP. As with R>, the problem with the is word is that
        ; the top value on the ReturnStack for a STC Forth is the
        ; return address, which we need to get out of the way first.
        ; Native compile needs to be handled as a special case.
        ; """
xt_two_r_from:
                ; save the return address
                pla                     ; LSB
                sta tmp1
                pla                     ; MSB
                sta tmp1+1

                ; --- CUT HERE FOR NATIVE CODING ---

		; make room on stack
                dex
                dex
                dex
                dex

                ; In theory, we should test for underflow on the Return
                ; Stack. However, given the traffic there with an STC
                ; Forth, that's probably not really useful

                ; now we can access the data
                pla                     ; LSB
                sta 0,x
                pla                     ; MSB
                sta 1,x

                pla                     ; LSB
                sta 2,x
                pla                     ; MSB
                sta 3,x

                ; --- CUT HERE FOR NATIVE CODING ---

                ; restore return address
                lda tmp1+1              ; MSB
                pha
                lda tmp1                ; LSB
                pha

z_two_r_from:   rts


; ## TWO_SLASH ( n -- n ) "Divide TOS by two"
; ## "2/"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TwoDiv"""
xt_two_slash:
                jsr underflow_1

                ; We can't just LSR the LSB and ROR the MSB because that
                ; would do bad things to the sign
                lda 1,x
                asl                     ; save the sign
                ror 1,x
                ror 0,x

z_two_slash:    rts


; ## TWO_STAR ( n -- n ) "Multiply TOS by two"
; ## "2*"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TwoTimes
        ;
        ; Also used for CELLS
        ; """
xt_two_star:
xt_cells:
                jsr underflow_1

                asl 0,x
                rol 1,x
z_cells:
z_two_star:     rts


; ## TWO_STORE ( n1 n2 addr -- ) "Store two numbers at given address"
; ## "2!"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TwoStore
        ; Stores so n2 goes to addr and n1 to the next consecutive cell.
        ; Is equivalent to  `SWAP OVER ! CELL+ !`
        ; """
xt_two_store:
                jsr underflow_3

                lda 0,x
                sta tmp1
                ldy 1,x
                sty tmp1+1

                inx
                inx

                lda 0,x         ; copy MSB
                sta (tmp1)
                lda 1,x         ; copy next
                ldy #1
                sta (tmp1),y
                lda 2,x         ; copy next
                iny
                sta (tmp1),y
                lda 3,x         ; copy MSB
                iny
                sta (tmp1),y

                inx             ; 2DROP
                inx
                inx
                inx

z_two_store:    rts


; ## TWO_SWAP ( n1 n2 n3 n4 -- n3 n4 n1 n1 ) "Exchange two double words"
; ## "2swap"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TwoSWAP"""
xt_two_swap:
                jsr underflow_4

                ; 0 <-> 4
                lda 0,x
                ldy 4,x
                sta 4,x
                sty 0,x

                ; 1 <-> 5
                lda 1,x
                ldy 5,x
                sta 5,x
                sty 1,x

                ; 2 <-> 6
                lda 2,x
                ldy 6,x
                sta 6,x
                sty 2,x

                ; 3 <-> 7
                lda 3,x
                ldy 7,x
                sta 7,x
                sty 3,x

z_two_swap:     rts


; ## TWO_TO_R ( n1 n2 -- )(R: -- n1 n2 "Push top two entries to Return Stack"
; ## "2>r"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/TwotoR
        ; Push top two entries to Return Stack.
        ;
        ; The same as SWAP >R >R
        ; except that if we jumped here, the return address will be in the
        ; way. May not be natively compiled unless we're clever and use
        ; special routines.
        ; """
xt_two_to_r:
                ; save the return address
                pla             ; LSB
                sta tmp1
                pla             ; MSB
                sta tmp1+1

                ; --- CUT HERE FOR NATIVE CODING ---

                jsr underflow_2

                ; now we can move the data
                lda 3,x         ; MSB
                pha
                lda 2,x         ; LSB
                pha

                ; now we can move the data
                lda 1,x         ; MSB
                pha
                lda 0,x         ; LSB
                pha

                inx
                inx
                inx
                inx

                ; --- CUT HERE FOR NATIVE CODING ---

                ; restore return address
                lda tmp1+1      ; MSB
                pha
                lda tmp1        ; LSB
                pha

z_two_to_r:     rts


; ## TWO_CONSTANT (C: d "name" -- ) ( -- d) "Create a constant for a double word"
; ## "2constant"  auto  ANS double
        ; """https://forth-standard.org/standard/double/TwoCONSTANT
        ;
        ; Based on the Forth code
        ; : 2CONSTANT ( D -- )  CREATE SWAP , , DOES> DUP @ SWAP CELL+ @ ;
        ; """
xt_two_constant:
                jsr underflow_2

                jsr xt_create
                jsr xt_swap
                jsr xt_comma
                jsr xt_comma

                jsr does_runtime    ; does> turns into these two routines.
                jsr dodoes

                jsr xt_dup
                jsr xt_fetch
                jsr xt_swap
                jsr xt_cell_plus
                jsr xt_fetch

z_two_constant: rts


; ## TWO_LITERAL (C: d -- ) ( -- d) "Compile a literal double word"
; ## "2literal"  auto  ANS double
        ; """https://forth-standard.org/standard/double/TwoLITERAL"""
        ; Based on the Forth code
        ; : 2LITERAL ( D -- ) SWAP POSTPONE LITERAL POSTPONE LITERAL ; IMMEDIATE
        ; """
xt_two_literal:
                jsr underflow_2 ; double number

                jsr xt_swap
                jsr xt_literal
                jsr xt_literal

z_two_literal:  rts


; ## TWO_VARIABLE ( "name" -- ) "Create a variable for a double word"
; ## "2variable"  auto  ANS double
        ; """https://forth-standard.org/standard/double/TwoVARIABLE
        ; The variable is not initialized to zero.
        ;
        ; This can be realized in Forth as either
        ; CREATE 2 CELLS ALLOT  or just  CREATE 0 , 0 ,
        ; """
xt_two_variable:
                ; We just let CRATE and ALLOT do the heavy lifting
                jsr xt_create

                dex
                dex
                lda #4
                sta 0,x
                stz 1,x

                jsr xt_allot

z_two_variable: rts


; ## TYPE ( addr u -- ) "Print string"
; ## "type"  auto  ANS core
        ; """https://forth-standard.org/standard/core/TYPE
        ; Works through EMIT to allow OUTPUT revectoring.
        ; """
.scope
xt_type:
                jsr underflow_2

                ; Save the starting address into tmp1
                lda 2,x
                sta tmp1
                lda 3,x
                sta tmp1+1
_loop:
                ; done if length is zero
                lda 0,x
                ora 1,x
                beq _done

                ; Send the current character
                lda (tmp1)
                jsr emit_a      ; avoids stack foolery

                ; Move the address along (in tmp1)
                inc tmp1
                bne +
                inc tmp1+1
*
                ; Reduce the count (on the data stack)
                lda 0,x
                bne +
                dec 1,x
*
                dec 0,x

                bra _loop
_done:
                inx
                inx
                inx
                inx

z_type:         rts
.scend


; ## U_DOT ( u -- ) "Print TOS as unsigned number"
; ## "u."  tested  ANS core
        ; """https://forth-standard.org/standard/core/Ud
        ;
        ; This is : U. 0 <# #S #> TYPE SPACE ; in Forth
        ; We use the internal assembler function print_u followed
        ; by a single space
        ; """
xt_u_dot:
                jsr underflow_1

                jsr print_u
                lda #AscSP
                jsr emit_a

z_u_dot:        rts


; ## U_DOT_R ( u u -- ) "Print NOS as unsigned number right-justified with TOS width"
; ## "u.r"  tested  ANS core ext
        ; """https://forth-standard.org/standard/core/UDotR"""
xt_u_dot_r:
                jsr underflow_2

                jsr xt_to_r
                jsr xt_zero
                jsr xt_less_number_sign
                jsr xt_number_sign_s
                jsr xt_number_sign_greater
                jsr xt_r_from
                jsr xt_over
                jsr xt_minus
                jsr xt_spaces
                jsr xt_type

z_u_dot_r:      rts


; ## U_GREATER_THAN ( n m -- f ) "Return true if NOS > TOS (unsigned)"
; ## "u>"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/Umore"""
xt_u_greater_than:
                jsr underflow_2

                lda 0,x
                cmp 2,x
                lda 1,x
                sbc 3,x
                inx
                inx

                lda #0
                adc #$ff
                sta 0,x         ; store flag
                sta 1,x

z_u_greater_than:    rts

; ## U_LESS_THAN ( n m -- f ) "Return true if NOS < TOS (unsigned)"
; ## "u<"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Uless"""
xt_u_less_than:
                jsr underflow_2

                lda 2,x
                cmp 0,x
                lda 3,x
                sbc 1,x
                inx
                inx

                lda #0
                adc #$ff
                sta 0,x         ; store flag
                sta 1,x

z_u_less_than:    rts


; ## UD_DOT ( d -- ) "Print double as unsigned"
; ## "ud."  auto  Tali double
        ;
        ; """Based on the Forth code  : UD. <# #S #> TYPE SPACE ;
        ; """
xt_ud_dot:
                jsr underflow_2 ; double number

                jsr xt_less_number_sign
                jsr xt_number_sign_s
                jsr xt_number_sign_greater
                jsr xt_type
                jsr xt_space

z_ud_dot:        rts


; ## UD_DOT_R ( d u -- ) "Print unsigned double right-justified u wide"
; ## "ud.r"  auto  Tali double
        ;
        ; """Based on the Forth code : UD.R  >R <# #S #> R> OVER - SPACES TYPE ;
        ; """
xt_ud_dot_r:
                jsr underflow_3

                jsr xt_to_r
                jsr xt_less_number_sign
                jsr xt_number_sign_s
                jsr xt_number_sign_greater
                jsr xt_r_from
                jsr xt_over
                jsr xt_minus
                jsr xt_spaces
                jsr xt_type

z_ud_dot_r:      rts


; ## UM_SLASH_MOD ( ud u -- ur u ) "32/16 -> 16 division"
; ## "um/mod"  auto  ANS core
        ; """https://forth-standard.org/standard/core/UMDivMOD
        ; Divide double cell number by single cell number, returning the
        ; quotient as TOS and any remainder as NOS. All numbers are unsigned.
        ; This is the basic division operation all others use. Based on FIG
        ; Forth code, modified by Garth Wilson, see
        ; http://6502.org/source/integers/ummodfix/ummodfix.htm
        ;
        ; This uses tmp1, tmp1+1, and tmptos
        ; """
.scope
xt_um_slash_mod:
                jsr underflow_3

                ; catch division by zero
                lda 0,x
                ora 1,x
                bne _not_zero

                lda #err_divzero
                jmp error

_not_zero:
                ; We loop 17 times
                lda #17
                sta tmptos

_loop:
                ; rotate low cell of dividend one bit left (LSB)
                rol 4,x
                rol 5,x

                ; loop control
                dec tmptos
                beq _done

                ; rotate high cell of dividend one bit left (MSB)
                rol 2,x
                rol 3,x

                stz tmp1        ; store the bit we got from hi cell (MSB)
                rol tmp1

                ; subtract dividend hi cell minus divisor
                sec
                lda 2,x
                sbc 0,x
                sta tmp1+1
                lda 3,x
                sbc 1,x

                tay
                lda tmp1
                sbc #0
                bcc _loop

                ; make result new dividend high cell
                lda tmp1+1
                sta 2,x
                sty 3,x         ; used as temp storage

                bra _loop
_done:
                inx
                inx

                jsr xt_swap

z_um_slash_mod: rts
.scend


; ## UM_STAR ( u u -- ud ) "Multiply 16 x 16 -> 32"
; ## "um*"  auto  ANS core
        ; """https://forth-standard.org/standard/core/UMTimes
        ; Multiply two unsigned 16 bit numbers, producing a 32 bit result.
        ; Old Forth versions such as FIG Forth call this U*
        ;
        ; This is based on modified FIG Forth code by Dr. Jefyll, see
        ; http://forum.6502.org/viewtopic.php?f=9&t=689 for a detailed
        ; discussion.
        ;
        ; We don't use the system scratch pad (SYSPAD) for temp
        ; storage because >NUMBER uses it as well, but instead tmp1 to
        ; tmp3 (tmp1 is N in the original code, tmp1+1 is N+1, etc).
        ;
        ; Consider switching to a table-supported version based on
        ; http://codebase64.org/doku.php?id=base:seriously_fast_multiplication
        ; http://codebase64.org/doku.php?id=magazines:chacking16#d_graphics_for_the_masseslib3d>
        ; http://forum.6502.org/viewtopic.php?p=205#p205
        ; http://forum.6502.org/viewtopic.php?f=9&t=689
        ; """
.scope
xt_um_star:
                jsr underflow_2

                ; to eliminate clc inside the loop, the value at
                ; tmp1 is reduced by 1 in advance
                clc
                lda 0,x         ; copy TOS to tmp2
                sbc #0
                sta tmp2

                lda 1,x
                sbc #0
                bcc _zero       ; is TOS zero?
                sta tmp2+1

                lda #0
                sta tmp1
                stx tmp3        ; tested for exit from outer loop
                dex
                dex

_outer_loop:
                ldy #8          ; counter inner loop
                lsr 4,x         ; think "2,x" then later "3,x"

_inner_loop:
                bcc _no_add
                sta tmp1+1      ; save time, don't CLC
                lda tmp1
                adc tmp2
                sta tmp1
                lda tmp1+1
                adc tmp2+1

_no_add:
                ror
                ror tmp1
                ror 4,x         ; think "2,x" then later "3,x"

                dey
                bne _inner_loop ; go back for one more shift?

                inx
                cpx tmp3
                bne _outer_loop ; go back for eight more shifts?

                ; all done, store high word of result
                sta 1,x
                lda tmp1
                sta 0,x
                bra _done

_zero:
                stz 2,x
                stz 3,x
_done:
z_um_star:      rts
.scend


; ## UNLOOP ( -- )(R: n1 n2 n3 ---) "Drop loop control from Return stack"
; ## "unloop"  auto  ANS core
        ; """https://forth-standard.org/standard/core/UNLOOP
        ;
        ; Note that 6xPLA uses just as many bytes as a loop would
        ; """
xt_unloop:
                ; Drop fudge number (limit/start from DO/?DO off the
                ; return stack
                pla
                pla
                pla
                pla

                ; Now drop the LEAVE address that was below them off
                ; the Return Stack as well
                pla
                pla

z_unloop:       rts


; ## UNTIL (C: dest -- ) ( -- ) "Loop flow control"
; ## "until"  auto  ANS core
        ; """http://forth-standard.org/standard/core/UNTIL"""
xt_until:
                ; Compile a 0BRANCH
                ldy #>zero_branch_runtime
                lda #<zero_branch_runtime
                jsr cmpl_subroutine

                ; The address to loop back to is on the stack.
                ; Just compile it as the destination for the
                ; 0branch.
                jsr xt_comma

z_until:        rts


; ## UNUSED ( -- u ) "Return size of space available to Dictionary"
; ## "unused"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/UNUSED
        ; UNUSED does not include the ACCEPT history buffers. Total RAM
        ; should be HERE + UNUSED + <history buffer size>, the last of which
        ; defaults to $400
        ; """
xt_unused:
                dex
                dex

                lda #<cp_end
                sec
                sbc cp
                sta 0,x

                lda #>cp_end
                sbc cp+1
                sta 1,x

z_unused:       rts


; ## UPDATE ( -- ) "Mark current block as dirty"
; ## "update"  auto  ANS block
        ; """https://forth-standard.org/standard/block/UPDATE"""
xt_update:
                ; Turn on the dirty bit. We can't use TSB here because it only
                ; has Absolute and Direct Pages addressing modes
                ldy #buffstatus_offset
                lda (up),y
                ora #2          ; Turn on dirty flag (bit 2)
                sta (up),y

z_update:       rts


; ## USERADDR ( -- addr ) "Push address of base address of user variables"
; ## "useraddr"  tested  Tali Forth
xt_useraddr:
                dex
                dex
                lda #<up
                sta 0,x
                lda #>up
                sta 1,x

z_useraddr:     rts


; ## VALUE ( n "name" -- ) "Define a value"
; ## "value"  auto  ANS core
        ; """https://forth-standard.org/standard/core/VALUE
        ;
        ; This is a dummy header for the WORDLIST. The actual code is
        ; identical to that of CONSTANT
        ; """


; ## VARIABLE ( "name" -- ) "Define a variable"
; ## "variable"  auto  ANS core
        ; """https://forth-standard.org/standard/core/VARIABLE
        ; There are various Forth definitions for this word, such as
        ; `CREATE 1 CELLS ALLOT`  or  `CREATE 0 ,`  We use a variant of the
        ; second one so the variable is initialized to zero
        ; """
xt_variable:
                ; we let CREATE do the heavy lifting
                jsr xt_create

                ; there is no "STZ (CP)" so we have to do this the hard
                ; way
                lda #0

                sta (cp)
                inc cp
                bne +
                inc cp+1
*
                sta (cp)
                inc cp
                bne +
                inc cp+1
*
                ; Now we need to adjust the length of the complete word by two
                jsr adjust_z

z_variable:     rts


; ## WHILE ( C: dest -- orig dest ) ( x -- ) "Loop flow control"
; ## "while"  auto  ANS core
        ; """http://forth-standard.org/standard/core/WHILE"""
xt_while:
                ; Compile a 0branch
                ldy #>zero_branch_runtime
                lda #<zero_branch_runtime
                jsr cmpl_subroutine

                ; Put the address (here) where the destination
                ; address needs to go so it can be put there later.
                jsr xt_here

                ; Fill in the destination address with 0 for now.
                jsr xt_zero
                jsr xt_comma

                ; Swap the two addresses on the stack.
                jsr xt_swap

z_while:        rts


; ## WITHIN ( n1 n2 n3 -- ) "See if within a range"
; ## "within"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/WITHIN
        ;
        ; This an assembler version of the ANS Forth implementation
        ; at https://forth-standard.org/standard/core/WITHIN which is
        ; OVER - >R - R> U<  note there is an alternative high-level version
        ; ROT TUCK > -ROT > INVERT AND
        ; """"
xt_within:
                jsr underflow_3

                jsr xt_over
                jsr xt_minus
                jsr xt_to_r
                jsr xt_minus
                jsr xt_r_from
                jsr xt_u_less_than

z_within:       rts


; ## WORD ( char "name " -- caddr ) "Parse input stream"
; ## "word"  auto  ANS core
        ; """https://forth-standard.org/standard/core/WORD
        ; Obsolete parsing word included for backwards compatibility only.
        ; Do not use this, use `PARSE` or `PARSE-NAME`. Skips leading delimiters
        ; and copies word to storage area for a maximum size of 255 bytes.
        ; Returns the result as a counted string (requires COUNT to convert
        ; to modern format), and inserts a space after the string. See "Forth
        ; Programmer's Handbook" 3rd edition p. 159 and
        ; http://www.forth200x.org/documents/html/rationale.html#rat:core:PARSE
        ; for discussions of why you shouldn't be using WORD anymore.
        ;
        ; Forth
        ; would be   PARSE DUP BUFFER1 C! OUTPUT 1+ SWAP MOVE BUFFER1
        ; We only allow input of 255 chars. Seriously, use PARSE-NAME.
        ; """
.scope
xt_word:
                jsr underflow_1

                ; Skip over leading delimiters - this is like PARSE-NAME,
                ; but unlike PARSE
                ldy toin                ; >IN
_loop:
                cpy ciblen              ; quit if end of input
                beq _found_char
                lda (cib),y
                cmp 0,x                 ; ASCII of delimiter
                bne _found_char

                iny
                bra _loop
_found_char:
                ; Save index of where word starts
                sty toin

                ; The real work is done by parse
                jsr xt_parse            ; Returns ( addr u )

                ; Convert the modern ( addr u ) string format to obsolete
                ; ( caddr ) format. We just do this in the Dictionary
                lda 0,x
                sta (cp)                ; Save length of string
                pha                     ; Keep copy of length for later

                jsr xt_dup              ; ( addr u u )
                lda cp
                clc
                adc #1
                sta 2,x                 ; LSB of CP
                lda cp+1
                adc #0
                sta 3,x                 ; ( addr cp+1 u )

                jsr xt_move

                ; Return caddr
                dex
                dex
                lda cp
                sta 0,x
                lda cp+1
                sta 1,x

                ; Adjust CP
                pla                     ; length of string
                clc
                adc cp
                sta cp
                lda cp+1
                adc #0                  ; we only need the carry
                sta cp+1
z_word:         rts
.scend

; ## WORDLIST ( -- wid ) "Create new wordlist (from pool of 8)"
; ## "wordlist" auto ANS search
        ; """https://forth-standard.org/standard/search/WORDLIST
        ; See the tutorial on Wordlists and the Search Order for
        ; more information.
        ; """
.scope
xt_wordlist:
                ; Get the current number of wordlists
                ldy #num_wordlists_offset
                lda (up),y      ; This is a byte variable, so only
                                ; the LSB needs to be checked.

                ; See if we are already at the max.
                cmp #max_wordlists
                bne _ok

                ; Print an error message if all wordlists used.
                lda #err_wordlist
                jmp error

_ok:
                inc             ; Increment the wordlist#
                sta (up),y      ; Save it into byte variable #wordlists
                dex             ; and put it on the stack.
                dex
                sta 0,x
                stz 1,x         ; 12 is the max, so upper byte is always zero.

z_wordlist:     rts
.scend


; ## WORDS ( -- ) "Print known words from Dictionary"
; ## "words"  tested  ANS tools
        ; """https://forth-standard.org/standard/tools/WORDS
        ; This is pretty much only used at the command line so we can
        ; be slow and try to save space.
        ; """
.scope
xt_words:
                ; we follow Gforth by starting on the next
                ; line
                jsr xt_cr

                ; We pretty-format the output by inserting a line break
                ; before the end of the line. We can get away with pushing
                ; the counter to the stack because this is usually an
                ; interactive word and speed is not that important
                lda #0
                pha

                ; Set up for traversing the wordlist search order.
                dex                     ; Make room on the stack for
                dex                     ; a dictionary pointer.
                stz tmp3                ; Start at the beginning of
                                        ; the search order.
_wordlist_loop:
                ldy #num_order_offset   ; Check against byte variable #ORDER.
                lda tmp3
                cmp (up),y              ; See if we are done.
                bne _have_wordlist

                ; We ran out of wordlists to search.
                bra _words_done

_have_wordlist:
                ; start with last word in Dictionary
                ; Get the current wordlist id
                clc                     ; Index into byte array SEARCH-ORDER.
                adc #search_order_offset
                tay
                lda (up),y              ; Get the index into array WORDLISTS

                ; Get the DP for that wordlist.
                asl                     ; Turn offset into cells offset.
                clc
                adc #wordlists_offset
                tay
                lda (up),y              ; Save the DP for this wordlist
                sta 0,x                 ; on the stack. ( nt )
                iny
                lda (up),y
                sta 1,x

_loop:
                jsr xt_dup              ; ( nt nt )
                jsr xt_name_to_string   ; ( nt addr u )

                ; Insert line break if we're about to go past the end of the
                ; line
                pla
                clc
                adc 0,x
                inc                     ; don't forget the space between words
                cmp #MAX_LINE_LENGTH    ; usually 79
                bcc +

                jsr xt_cr
                lda 0,x
                inc
*
                pha
                jsr xt_type             ; ( nt )

                lda #AscSP
                jsr emit_a

                ; get next word, which begins two down
                jsr xt_one_plus         ; 1+
                jsr xt_one_plus         ; 1+
                jsr xt_fetch            ; @ ( nt+1 )

                ; if next address is zero, we're done
                lda 0,x
                ora 1,x
                bne _loop

                ; Move on to the next wordlist in the search order.
                inc tmp3
                bra _wordlist_loop

_words_done:
                pla                     ; dump counter

                inx
                inx

z_words:        rts
.scend


; ## WORDSIZE ( nt -- u ) "Get size of word in bytes"
; ## "wordsize"  auto  Tali Forth
        ; """Given an word's name token (nt), return the size of the
        ; word's payload size in bytes (CFA plus PFA) in bytes. Does not
        ; count the final RTS.
        ; """
xt_wordsize:
                jsr underflow_1

                ; We get the start address of the word from its header entry
                ; for the start of the actual code (execution token, xt)
                ; which is four bytes down, and the pointer to the end of the
                ; code (z_word, six bytes down)
                lda 0,x
                sta tmp1
                lda 1,x
                sta tmp1+1

                ldy #6
                lda (tmp1),y    ; LSB of z
                dey
                dey

                sec
                sbc (tmp1),y    ; LSB of xt
                sta 0,x

                ldy #7
                lda (tmp1),y    ; MSB of z
                dey
                dey

                sbc (tmp1),y    ; MSB of xt
                sta 1,x

z_wordsize:     rts


; ## XOR ( n n -- n ) "Logically XOR TOS and NOS"
; ## "xor"  auto  ANS core
        ; """https://forth-standard.org/standard/core/XOR"""
xt_xor:
                jsr underflow_2

                lda 0,x
                eor 2,x
                sta 2,x

                lda 1,x
                eor 3,x
                sta 3,x

                inx
                inx

z_xor:          rts


; ## ZERO ( -- 0 ) "Push 0 to Data Stack"
; ## "0"  auto  Tali Forth
        ; """The disassembler assumes that this routine does not use Y. Note
        ; that CASE and FORTH-WORDLIST use the same routine, as the WD for Forth
        ; is 0."""
xt_case:
xt_forth_wordlist:
xt_zero:
                dex             ; push
                dex
                stz 0,x
                stz 1,x
z_case:
z_forth_wordlist:
z_zero:
                rts


; ## ZERO_EQUAL ( n -- f ) "Check if TOS is zero"
; ## "0="  auto  ANS core
        ; """https://forth-standard.org/standard/core/ZeroEqual"""
.scope
xt_zero_equal:
                jsr underflow_1

                lda 0,x
                ora 1,x
                beq _zero

                ; not a zero, so we need a FALSE flag (0)
                lda #0
                bra _store
_zero:
                ; We have a zero, so we need a TRUE flag (-1)
                lda #$ff
_store:
                sta 0,x
                sta 1,x

z_zero_equal:   rts
.scend


; ## ZERO_GREATER ( n -- f ) "Return a TRUE flag if TOS is positive"
; ## "0>"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/Zeromore"""
.scope
xt_zero_greater:
                jsr underflow_1

                ldy #0          ; Default is FALSE (TOS is negative)

                lda 1,x         ; MSB
                bmi _done       ; TOS is negative, keep FLASE
                ora 0,x
                beq _done       ; TOS is zero, keep FALSE

                dey             ; TOS is postive, make true
_done:
                tya
                sta 0,x
                sta 1,x

z_zero_greater: rts
.scend


; ## ZERO_LESS ( n -- f ) "Return a TRUE flag if TOS negative"
; ## "0<"  auto  ANS core
        ; """https://forth-standard.org/standard/core/Zeroless"""
.scope
xt_zero_less:
                jsr underflow_1

                ldy #0          ; Default is FALSE (TOS positive)

                lda 1,x         ; MSB
                bpl _done       ; TOS is positive, so keep FALSE

                dey             ; TOS is negative, make TRUE
_done:
                tya
                sta 0,x
                sta 1,x

z_zero_less:    rts
.scend


; ## ZERO_UNEQUAL ( m -- f ) "Return TRUE flag if not zero"
; ## "0<>"  auto  ANS core ext
        ; """https://forth-standard.org/standard/core/Zerone"""
.scope
xt_zero_unequal:
                jsr underflow_1

                ldy #0          ; default false

                lda 0,x
                ora 1,x
                beq _got_zero

                dey
_got_zero:
                tya
                sta 0,x
                sta 1,x

z_zero_unequal: rts
.scend


; ==========================================================
; EDITOR words

; This routine is used by both enter-screen and erase-screen
; to get a buffer for the given screen number and set SCR to
; the given screen number.  This word is not in the dictionary.
xt_editor_screen_helper:
                jsr xt_dup
                jsr xt_scr
                jsr xt_store
                jsr xt_buffer
z_editor_screen_helper:
                rts


; ## EDITOR_ENTER_SCREEN ( scr# -- ) "Enter all lines for given screen"
; ## "enter-screen"  auto  Tali Editor
.scope
xt_editor_enter_screen:
                ; Set the variable SCR and get a buffer for the
                ; given screen number.
                jsr xt_editor_screen_helper

                ; Drop the buffer address.
                jsr xt_drop

                ; Overwrite the lines one at a time.
                stz editor1
_prompt_loop:
                ; Put the current line number on the stack.
                dex
                dex
                lda editor1
                sta 0,x
                stz 1,x

                ; Use the O word to prompt for overwrite.
                jsr xt_editor_o

                ; Move on to the next line.
                inc editor1
                lda #16
                cmp editor1
                bne _prompt_loop

z_editor_enter_screen:
                rts
.scend


; ## EDITOR_ERASE_SCREEN ( scr# -- ) "Erase all lines for given screen"
; ## "erase-screen"  tested  Tali Editor
xt_editor_erase_screen:
                ; Set the variable SCR and get a buffer for the
                ; given screen number.
                jsr xt_editor_screen_helper

                ; Put 1024 (chars/screen) on stack.
                dex
                dex
                stz 0,x
                lda #4          ; 4 in MSB makes 1024 ($400).
                sta 1,x

                ; Erase the entire block (fill with spaces).
                jsr xt_blank

                ; Mark buffer as updated.
                jsr xt_update

z_editor_erase_screen:
                rts


; ## EDITOR_EL ( line# -- ) "Erase the given line number"
; ## "el"  tested  Tali Editor
xt_editor_el:
                ; Turn the line number into buffer offset.
                ; This also loads the block into the buffer if it's
                ; not there for some reason.
                jsr xt_editor_line

                ; Put 64 (# of chars/line) on the stack.
                dex
                dex
                lda #64
                sta 0,x
                stz 1,x

                ; Fill with spaces.
                jsr xt_blank

                ; Mark buffer as updated.
                jsr xt_update

z_editor_el:    rts


; ## EDITOR_L ( -- ) "List the current screen"
; ## "l"  tested  Tali Editor
.scope
xt_editor_l:
                ; Load the current screen
                dex             ; Put SCR on the stack.
                dex
                ldy #scr_offset
                lda (up),y
                sta 0,x
                iny
                lda (up),y
                sta 1,x
                jsr xt_block    ; Get the current screen.

                jsr xt_cr

                ; Print the screen number.
                ; We're using sliteral, so we need to set up the
                ; appropriate data structure (see sliteral)
                bra _after_screen_msg

_screen_msg:
                .byte "Screen #"

_after_screen_msg:
                jsr sliteral_runtime
                .word _screen_msg, _after_screen_msg-_screen_msg

                jsr xt_type

                ; Put the screen number and printed size for u.r on the stack.
                jsr xt_scr
                jsr xt_fetch
                dex
                dex
                lda #4          ; four spaces
                sta 0,x
                stz 1,x
                jsr xt_u_dot_r

                ; The address of the buffer is currently on the stack.
                ; Print 64 chars at a time. TYPE uses tmp1, so we'll
                ; keep track of the line number in tmp3.
                stz tmp3

_line_loop:
                jsr xt_cr

                ; Print the line number (2-space fixed width)
                dex
                dex
                dex
                dex
                stz 3,x
                lda tmp3
                sta 2,x
                stz 1,x
                lda #2
                sta 0,x
                jsr xt_u_dot_r
                jsr xt_space

                ; Print one line using the address on the stack.
                jsr xt_dup
                dex
                dex
                lda #64
                sta 0,x
                stz 1,x
                jsr xt_type

                ; Add 64 to the address on the stack to move to the next line.
                clc
                lda #64
                adc 0,x
                sta 0,x
                lda 1,x
                adc #0      ; Add carry
                sta 1,x

                ; Increment the line number (held in tmp3)
                inc tmp3

                ; See if we are done.
                lda tmp3
                cmp #16
                bne _line_loop

                jsr xt_cr
                ; Drop the address on the stack.
                inx
                inx

z_editor_l:            rts
.scend


; ## EDITOR_LINE ( line# -- c-addr ) "Turn a line number into address in current screen"
; ## "line"  tested  Tali Editor
.scope
xt_editor_line:
                jsr underflow_1

                ; Multiply the TOS by 64 (chars/line) to compute offset.
                ldy #6          ; *64 is same as left shift 6 times.
_shift_tos_left:
                asl 0,x         ; Shift TOS to the left
                rol 1,x         ; ROL brings MSb from lower byte.
                dey
                bne _shift_tos_left
                ; Load the current screen into a buffer
                ; and get the buffer address
                jsr xt_scr
                jsr xt_fetch
                jsr xt_block

                ; Add the offset to the buffer base address.
                jsr xt_plus

z_editor_line:  rts
.scend


; ## EDITOR_O ( line# -- ) "Overwrite the given line"
; ## "o"  tested  Tali Editor
xt_editor_o:
                ; Print prompt
                jsr xt_cr
                jsr xt_dup
                jsr xt_two
                jsr xt_u_dot_r
                jsr xt_space
                lda #42         ; ASCII for *
                jsr emit_a
                jsr xt_space

                ; Accept new input (directly into the buffer)
                jsr xt_editor_line
                jsr xt_dup      ; Save a copy of the line address for later.
                dex
                dex
                lda #64         ; chars/line
                sta 0,x
                stz 1,x
                jsr xt_accept

                ; Fill the rest with spaces.
                ; Stack is currently ( line_address numchars_from_accept )
                jsr xt_dup
                jsr xt_not_rote ; -rot
                jsr xt_plus
                dex
                dex
                lda #64         ; chars/line
                sta 0,x
                stz 1,x
                jsr xt_rot
                jsr xt_minus
                jsr xt_blank

                ; Mark buffer as updated.
                jsr xt_update

z_editor_o:     rts

; END
