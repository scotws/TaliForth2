; ed6502 - Ed-like line-based editor for Tali Forth 2 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 13. Okt 2018
; This version: 15. Nov 2018

; Ed is a line-orientated editor for Tali Forth 2 based on the classic
; Unix editor of the same name. It is included because a) I like line
; editors and this is my project, so there, and b) as a very simple
; editor that will work even if there is no vt100 terminal support,
; just with ASCII if needs be. For further information on ed, see

;   https://en.wikipedia.org/wiki/Ed_(text_editor)
;   https://www.gnu.org/software/ed/ed.html
;   https://www.gnu.org/software/ed/manual/ed_manual.html
;   https://sanctum.geek.nz/arabesque/actually-using-ed/
;   http://www.psue.uni-hannover.de/wise2017_2018/material/ed.pdf

; We start editor from Forth with 
;
;       ed ( -- addr u )
;
; The return values ( addr u ) are the address and length of the text written.
; If no text was written, u is zero. 

; In the working memory, the text is stored as a simple linked list of lines.
; Each node consists of three 16-bit entries:

;       - pointer to next entry (0 for end of list)
;       - pointer to beginning of string ( addr )
;       - length of string ( u )

; The editor only works in interaction with those slow-human types, so speed
; is not a primary concern. We try to keep the size down instead.

; Where to put variables is a bit of a problem. To convert the numbers, we
; need UM/MOD, which uses the scratchpad, and ACCEPT uses tmp1, tmp2, and
; tmp3 at some point, so we either have to pay very close attention, or we
; do something else. After some experimenting, it seems that the easiest way
; for this sort of hybrid Forth/assembler system is to keep the parameters
; for the commands on the Data Stack in the form of ( para1 para2 ):
;
;       TOS: parameter 2 (after the comma)
;       NOS: parameter 1 (before the comma)
;
; The third and fourth entries on the stack are the ( addr u ) entries the
; text was written to, or u as 0 if nothing was defined. 
;
; We also need a pointer to the beginning of the text (first node of the
; list), the number of the current line, and a flag to mark if the text
; has been changed. We have six bytes of zero page reserved for any editor
; to use. Note that this means that we can't use two editors at the same
; time, which won't be a problem until we can multitask.

.alias ed_head     editor1   ; pointer to first list element (addr) (2 bytes)
.alias ed_cur      editor2   ; current line number (1 is first line) (2 bytes)
.alias ed_changed  editor3   ; flag: $FF if text changed, $00 if not (1 byte)
.alias ed_flag     editor3+1 ; generic flag (used for p vs n printing)

.scope
ed6502:
                ; Start a new empty linked list at HERE. This is also
                ; the current line
                stz ed_head
                stz ed_head+1

                ; The current line is 0, because we start counting at
                ; line 1 for the poor humans
                stz ed_cur
                stz ed_cur+1

                ; At the beginning, nothing is modified
                stz ed_changed

                ; We put zeros as placeholders for the text we've written to
                ; (the "target") on the stack. Because the stack picture is
                ; going to get very confusing very fast, we'll mark them
                ; specially here with "-t" suffixes.
                jsr xt_zero
                jsr xt_zero             ; ( addr-t u-t )

                jsr xt_cr

_input_loop: 
                ; We really don't want to have to write a complete
                ; parser for such a simple editor, so we walk through the
                ; possibilities the hard way. Get input from the user. This
                ; routine handles any errors from REFILL
                jsr _get_input

                ; If we were given an empty line, advance by one line and print
                lda ciblen
                bne _command_mode

                ; We were given an empty line. Advance one line, print it, and
                ; make it the new current line
                dex
                dex                     ; ( addr-t u-t ? )

                lda ed_cur
                sta 0,x
                lda ed_cur+1
                sta 1,x                 ; ( addr-t u-t u )

                jsr xt_one_plus         ; ( addr-t u-t u+1 )
                jsr _is_valid_line
                bcs +
                
                ; New line number is not legal, abort
                jmp _error_1drop
*
                ; We have a legal line number, but we need two entries on
                ; the parameter list - four if you count the target
                ; address - to be able to work with the rest of the program.
                jsr xt_zero             ; ( addr-t u-t u+1 0 )

                jmp _line_number_only_from_external

_command_mode:
                ; Set the parameter variables to zero. This is used as a flag
                ; to show we're only dealing with the current line, because there
                ; is no line 0 (we're coding for normal, sane humans, not
                ; silly computer programmers). This means that we have to catch
                ; valid cases of zero parameters (say, 0a) by hand
                jsr xt_zero             ; parameter 1 is NOS ( 0 )
                jsr xt_zero             ; parameter 2 is TOS ( 0 0 )
                
                ; We start off taking care of any parameters. These can be '%'
                ; for the complete text, '$' for the last line, a line number;
                ; or a line number followed by a ',' and then either the '$' for
                ; the last line or another number. (The original Unix ed has
                ; more options, but we're ignoring them for the moment.) In
                ; pseudocode, what we are doing in this stage looks something
                ; like this:

                ;        case char = '.':
                ;              para1 = current line
                ;
                ;        case char = '$':
                ;              para1 = last line
                ;
                ;        case char = '%':
                ;              para1 = 1
                ;              para2 = last line
                ;       
                ;        case number:
                ;              para1 = number
                ;              get next char
                ;       
                ;              if char = ',':
                ;                      get next char
                ;       
                ;                      case char = '$':
                ;                              para2 = last line
                ;
                ;                      case number:
                ;                              para2 = number
                ;
                ;                      else error
                ;              
                ;              else get previous char
                ;
                ;        else error
                ;       
                ;        get next char
                ;        prococess command char

                ; We use the Y register as an offset to the beginning of the
                ; character input buffer (CIB) because we're never going to
                ; have more than 255 characters of input with ed and we don't
                ; want to have to duplicated the complete machinery required
                ; for >IN. In other words, >IN has no meaning for ed. This
                ; means that every jmp to _check_command must have Y in a 
                ; defined state.

                ; Parameter processing could probably be handled more 
                ; efficiently with a loop construct similar to the way the 
                ; commands are taken care of below. We'll revisit this once
                ; ed is feature complete; currently, we are missing a whole
                ; number of parameters, such as ';' and ','.

_prefix_dot:
                ; --- . --- Designate current line for further operations
                lda (cib)
                cmp #$2e                ; ASCII '.'
                bne _prefix_dollar
                
                jsr _have_text

                lda ed_cur
                sta 2,x
                lda ed_cur+1
                sta 3,x                 ; ( addr-t u-t cur 0 ) 

                ; If we were only given a '.', we print the last line and are
                ; done
                lda ciblen
                dec                     ; sets Z if A was 1
                bne +

                ; We know that we have some text and the number of the last
                ; line was provided by _last_line, so in theory we don't have
                ; to check if this is a legal line number. However, we keep one
                ; entry point for the moment and repeat the check further down
                ; out of pure paranoia
                jmp _line_number_only_from_external
*
                ; We have processed the first parameter, and know that we have
                ; more than just a dot here. We now need to see if the next
                ; character is a comma or a command character. To do this, we
                ; need to modify the stack to ( addr-t u-t para1 0 addr u )
                dex
                dex
                dex
                dex

                lda cib
                sta 2,x
                lda cib+1
                sta 3,x

                lda ciblen
                sta 0,x
                lda ciblen+1
                sta 1,x

                jsr xt_one_minus        ; ( addr-t u-t para1 0 addr u-1 )
                jsr xt_swap             ; ( addr-t u-t para1 0 u-1 addr )
                jsr xt_one_plus         ; ( addr-t u-t para1 0 u-1 addr+1 )
                jsr xt_swap             ; ( addr-t u-t para1 0 addr+1 u-1 )
                
                jmp _check_for_para2
                

_prefix_dollar:
                ; --- $ --- Designate last line for further operations
                lda (cib) 
                cmp #'$
                bne _prefix_percent

                jsr _have_text

                inx
                inx                     ; ( addr-t u-t 0 )

                jsr _last_line          ; ( addr-t u-t 0 para1 )
                jsr xt_swap             ; SWAP ( addr-t u-t para1 0 ) 

                ; If we were only given a '$', we print the last line and are
                ; done
                lda ciblen
                dec                     ; sets Z if A was 1
                bne +

                ; We know that we have some text and the number of the last
                ; line was provided by _last_line, so in theory we don't have
                ; to check if this is a legal line number. However, we keep one
                ; entry point for the moment and repeat the check further down
                ; out of pure paranoia
                jmp _line_number_only_from_external
*
                ; We are one character into the input buffer CIB, so we advace
                ; Y as the index accordingly 
                ldy #01

                jmp _check_command


_prefix_percent:
                ; --- % --- Designate whole text for futher operations
                lda (cib)
                cmp #$25                ; ASCII '%'
                beq _whole_text
                cmp #$2c                ; ASCII ','
                bne _prefix_number

_whole_text:
                ; If there is no text yet, print an error
                jsr _have_text

                ; So we have at least one line of text. The first parameter
                ; is therefore line one, the second the last line
                lda #01
                sta 2,x                 ; LSB of NOS is para 1
                stz 3,x                 ; ( addr-t u-t para1 0 )

                ; Get the number (not the address) of the last line and
                ; store it as the second parameter
                inx
                inx                     ; DROP ( addr-t u-t para1 )
                jsr _last_line          ; ( addr-t u-t para1 para2 )
                
                ; We are one character into the input buffer CIB, so we advance
                ; Y as the index accordingly 
                ldy #01

                jmp _check_command

_prefix_number:
                ; --- <NUM> --- Check if we have been given a number. We use
                ; the built-in Forth routines for this, which involves
                ; calling >NUMBER, which calls UM*, which uses tmp1, tmp2,
                ; and tmp3. We arrive here with ( addr-t u-t 0 0 ), which doesn't
                ; help us at all because the string we are looking at is in
                ; ( cib ciblen )

                ; TODO figure out what happens if BASE is not 10

                ; Set up >NUMBER using CIB and CIBLEN as the location of the
                ; string to check. First, though, add the "accumulator" as
                ; a double number
                jsr xt_zero
                jsr xt_zero             ; ( addr-t u-t 0 0 0 0 )

                dex                     
                dex
                dex
                dex                     ; ( addr-t u-t 0 0 0 0 ? ? )

                lda cib
                sta 2,x
                lda cib+1
                sta 3,x                 ; ( addr-t u-t 0 0 0 0 cib ? )

                lda ciblen
                sta 0,x
                lda ciblen+1
                sta 1,x                 ; ( addr-t u-t 0 0 0 0 cib ciblen )

                jsr xt_to_number        ; ( addr-t u-t 0 0 ud addr2 u2 ) 

                ; If we converted all the characters in the string (u2 is
                ; zero), then the user just gave us a line number to
                ; jump to and nothing else
                lda 0,x
                ora 1,x
                bne _have_unconverted_chars

                ; We must have a line number and nothing else. Make this
                ; the current line number and print the line. Remember at
                ; this point, the line number still could be a zero
                inx
                inx
                inx
                inx                     ; 2DROP ( addr-t u-t 0 0 ud )

                jsr xt_d_to_s           ; D>S ( addr-t u-t 0 0 u )
                jsr xt_not_rote         ; -ROT ( addr-t u-t u 0 0 )

                inx
                inx                     ; ( addr-t u-t u 0 )       ; drop through

_line_number_only_from_external:
                jsr xt_swap             ; ( addr-t u-t 0 u )

                jsr _is_valid_line
                bcs +

                ; This is not a valid line number, so we bail
                jmp _error_2drop
*
                ; Legal line number, so make it the current number
                jsr xt_swap             ; ( addr-t u-t u 0 ) 
                jsr _para1_to_cur

                jmp _cmd_p_from_external

_have_unconverted_chars:
                ; We have some unconverted characters left. If none of the
                ; characters were converted, we probably just got a
                ; command character and need to skip the rest of the prefix
                ; processing. In this case, the number of unconverted
                ; characters is equal to the length of the string.

                ; TODO Deal with '+' and '-' as instructions
 
                jsr xt_dup              ; ( addr-t u-t 0 0 ud addr2 u2 u2 )
                
                dex
                dex                     ; ( addr-t u-t 0 0 ud addr2 u2 u2 ? )
                lda ciblen
                sta 0,x
                lda ciblen+1
                sta 1,x                 ; ( addr-t u-t 0 0 ud addr2 u2 u2 ciblen )

                jsr xt_equal            ; ( addr-t u-t 0 0 ud addr2 u2 f )

                lda 0,x
                ora 1,x
                beq _no_command_yet

                ; The length of the input string is equal to the length of
                ; the unprocessed string that >NUMBER returned. Put 
                ; differently, the first character isn't a number. We know that
                ; it isn't '$' or '%' either, so we assume that it's a command
                ; character. 

                ; Clear up the stack and process that command character
                txa
                clc
                adc #10
                tax                     ; ( addr-t u-t 0 0 )

                ; If we weren't given a number, this means we didn't explicitly
                ; get a 0 either. We make the line to work with the current
                ; line
                lda ed_cur
                sta 2,x
                lda ed_cur+1
                sta 3,x                 ; ( addr-t u-t cur 0 )

                ; We don't have any offset, so we go with Y as zero
                ldy #00

                jmp _check_command
                
_no_command_yet:
                ; There actually seems to be a parameter number present.
                ; Save the number we converted as the first parameter. We
                ; arrive here with ( addr-t u-t 0 0 ud addr2 u2 f ) from 
                ; >NUMBER. To avoid too long stack comments, we leave the
                ; target addresses out in this next code segment.
                inx
                inx                     ; ( ... 0 0 ud addr2 u2 )

                jsr xt_to_r             ; >R ( ... 0 0 ud addr2 ) (R: u2)
                jsr xt_not_rote         ; -ROT ( ... 0 0 addr2 ud ) (R: u2) 
                jsr xt_d_to_s           ; D>S  ( ... 0 0 addr2 para1 ) (R: u2)

                lda 0,x                 ; LSB
                sta 6,x
                lda 1,x                 ; MSB
                sta 7,x                 ; ( ... para1 0 addr2 para1 ) (R: u2)

                inx
                inx                     ; ( addr-t u-t para1 0 addr2 ) (R: u2)
                jsr xt_r_from           ; R> ( addr-t u-t para1 0 addr2 u2 )

_check_for_para2:
                ; That was the first parameter. If the next character is
                ; a comma, then there is a second parameter (another number
                ; or '$'). Otherwise we expect a command. This is the entry
                ; point if the first character was a dot (eg '.,3p')
                lda (2,x)

                cmp #$2c                ; ASCII code for ',' (comma)
                beq _got_comma

                ; It's not a comma, so it's going to be a command character.
                ; We need to figure out how many digits our number has so
                ; we can adjust Y as the offset. We don't have to do this with
                ; 16 bit because no input string is going to be that long
                sec
                lda ciblen
                sbc 0,x
                tay

                ; Remove the leftover stuff from >NUMBER
                inx
                inx
                inx
                inx                     ; 2DROP ( addr-t u-t para1 0 )

                jmp _check_command

_got_comma:
                ; It's a comma, so we have a second parameter. The next
                ; character can either be '$' to signal the end of the text
                ; or another number. First, though, move to that next char
                inc 2,x
                bne +
                inc 3,x                 ; ( addr-t u-t para1 0 addr2+1 u2 )
*
                lda 1,x
                beq +
                dec 1,x
*
                dec 0,x                 ; ( addr-t u-t para1 0 addr2+1 u2-1 )

                ; See if this is an end-of-line '$'
                lda (2,x)
                cmp #$24                ; ASCII for '$'
                bne _para2_not_dollar

                ; It's a dollar sign, which means para2 is the number
                ; of the last line of the text. 

                ; Now we need to adjust Y as the offset. We assume that
                ; no command line will be longer than 255 characters in ed so we
                ; can get away with just looking at the LSB
                sec
                lda ciblen
                sbc 2,x
                tay

                ; However, we need to move Y up by one because we were on the
                ; '$' and not on the character after that
                iny
                phy

                ; Dump all the stuff from >NUMBER off the stack. This saves
                ; one byte compared to six INX instructions
                txa
                clc
                adc #06
                tax                     ; ( addr-t u-t para1 ) 
               
                jsr _last_line          ; ( addr-t u-t para1 para2 )

                ply

                jmp _check_command

_para2_not_dollar:
                ; It's not a dollar sign, so it is either another number or
                ; an error. We try for a number first. We arrive here
                ; with ( para1 0 addr2+1 u2-1 ), which u2-1 pointing to the
                ; first mystery character after the comma. Again, we skip
                ; the ( addr-t u-t at the beginning of the stack comment here.
                jsr xt_to_r             ; >R ( ... para1 0 addr2+1 ) (R: u2-1)
                jsr xt_zero             ; 0 ( ... para1 0 addr2+1 0 ) (R: u2-1)
                jsr xt_zero             ; 0 ( ... para1 0 addr2+1 0 0 ) (R: u2-1)
                jsr xt_rot              ; ROT ( ... para1 0 0 0 addr2+1 ) (R: u2-1)
                jsr xt_r_from           ; R> ( ... para1 0 0 0 addr2+1 u2-1)

                ; We'll need a copy of the length of the rest of the string to
                ; see if we've actually done any work
                jsr xt_dup              ; DUP ( ... para1 0 0 0 addr2+1 u2-1 u2-1)
                jsr xt_to_r             ; >R ( ... para1 0 0 0 addr2+1 u2-1 ) (R: u2-1)

                jsr xt_to_number        ; >NUMBER ( ... para1 0 ud addr3 u3 ) (R: u2-1)

                ; If the original string and the leftover string have the same
                ; length, then nothing was converted and we have an error
                jsr xt_dup              ; DUP ( ... para1 0 ud addr3 u3 u3 ) (R: u2-1)
                jsr xt_r_from           ; R> ( ... para1 0 ud addr3 u3 u3 u2-1 )
                jsr xt_equal            ; = ( ... para1 0 ud addr3 u3 f )

                lda 0,x
                ora 1,x
                beq _second_number

                ; The strings are the same length, so nothing was converted, so
                ; we have an error. We have to get all that stuff off the
                ; stack first
                txa
                clc
                adc #12
                tax                     ; back to ( addr-t u-t ) 

                jmp _error

_second_number:
                ; We have a second number, so we add it to para2. We arrive here
                ; with ( para1 0 ud addr3 u3 f )
                inx
                inx                     ; ( addr-t u-t para1 0 ud addr3 u3 )

                ; Calculate the offset for Y
                sec
                lda ciblen
                sbc 0,x                 
                pha

                ; Clean up the stack
                jsr xt_two_drop         ; 2DROP ( addr-t u-t para1 0 ud )
                jsr xt_d_to_s           ; D>S  ( addr-t u-t para1 0 para2 )
                jsr xt_nip              ; NIP ( addr-t u-t para1 para2 )

                ply

                ; fall through to _check_command

_check_command:
                ; At this point, we assume that we have handled any parameters
                ; which are now in their place on the stack, which must have
                ; the format ( para1 para2 ). Also, any offset to CIB
                ; is going to be in Y. 

                ; If the first parameter is 0, make the current line
                ; number the first parameter. 
                lda 2,x
                ora 3,x
                bne +

                jsr _para1_to_cur

*
                ; TODO TEST ---------------------------------
                ; TEST : Print parameters

                ; Skip over this for the moment
                bra +

                phy                     ; save the offset

                lda #$28
                jsr emit_a

                jsr xt_swap             ; ( addr-t u-t para2 para1 )
                jsr xt_dup
                jsr xt_u_dot

                jsr xt_swap             ; ( addr-t u-t para1 para2 )
                jsr xt_dup
                jsr xt_u_dot

                ; Print Y as offset to CIB
                lda #'y
                jsr emit_a

                pla                     ; pull the offset
                pha                     ; save offset again

                jsr byte_to_ascii
                jsr xt_space

                ; Print current line
                lda #'c
                jsr emit_a

                lda ed_cur              ; don't need MSB for testing
                jsr byte_to_ascii

                lda #$29 
                jsr emit_a

                ply                     ; Restore the offset

*

                ; TODO TEST ---------------------------------

                ; Command character checking works by comparing the char
                ; we have at CIB+Y with a list of legal characters. The
                ; index in the list is the index of the command's routine
                ; in a jump table. The list itself is zero-terminated,
                ; which is okay because we've taken care of any legal
                ; parameters.
                lda (cib),y             ; get mystery char from input
                sta tmp1

                ; We're going to need X for the jump table, so it has to
                ; take a break from being the Data Stack Pointer (DSP)
                phx
                ldx #00
_cmd_loop:
                lda ed_cmd_list,x
                beq _illegal_command    ; zero marks end of list
                cmp tmp1
                beq _found_cmd

                ; No match, next char
                inx
                bra _cmd_loop

_illegal_command:
                ; Whatever the user gave us, we don't recognize it
                plx

                jmp _error_2drop

_found_cmd:
                ; We have a command match. Because this is the 65c02 and not
                ; the 65816, we can only use JMP (addr,x) and not a subroutine
                ; jump. That sucks.
                txa                     
                asl
                tax                     ; X * 2 for table

                ; Note we're jumping with the DSP still on the stack, so each
                ; command routine has to pull it into X the very first thing
                jmp (ed_cmd_table,x)

_next_command:

                ; Clean up the stack and return to the input loop. We
                ; arrive here with ( addr-t u-t para1 para2 ). The called
                ; command routines have taken care of putting the DSP (that's
                ; X) back the way it should be
                inx
                inx
                inx
                inx                     ; ( addr-t u-t ) Fall through 

_next_command_empty:

                jmp _input_loop
                
_all_done:
                ; We have to clear out the input buffer or else the Forth main
                ; main loop will react to the last input command
                stz ciblen
                stz ciblen+1
                
                ; Clean up the stack.
                jsr xt_two_drop                 ; 2DROP ( addr-t u-t )

                rts


; === COMMAND ROUTINES ====

; We enter all command subroutines with ( para1 para2 ) and the
; DSP still on the Return Stack. This means that the first oder of business
; is to restore the DSP. At this point, we don't need the offset in Y anymore.

; There is potential to rewrite many of the command routines with an
; abstract construct in the form of (pseudocode):
;
;       f = cmd  # command such as d, p, n, as a function
;       map f range(para1, para2)
; 
; That is, have one routine with a looping structure and pass the actual
; work as a function. However, this is 8-bit assembler and not, say,
; Haskell, so that abstraction will wait for a future round of refracturing
; when we have everything complete and working.


; -------------------------
_cmd_a:
        ; a -- Add text after current/given line. If no line is given, we use
        ; the current line. We accept the number '0' and then start adding at
        ; the very beginning. The second parameter is always ignored. This
        ; routine is used by i as well.

                plx
_entry_cmd_i:
                ; We don't care about para2, because a just adds stuff starting
                ; the line we were given
                inx
                inx                     ;  DROP ( addr-t u-t para1 )

                jsr _num_to_addr        ;  ( addr-t u-t addr1 ) 
                jsr xt_cr

_next_string_loop:
                ; This is where we land when we are continuing in with another
                ; string after the first one. ( addr-t u-t addr1 )
                jsr _get_input

                ; If there is only one character and that character is a
                ; dot, we're done with adding text and switch back to command
                ; mode
                lda (cib)
                cmp #$2e                ; ASCII for '.'
                bne _add_line

                ; So it's a dot, but that the only character in the line?
                ; We want the length to be 0001
                ldy ciblen
                cpy #01
                bne _add_line
                ldy ciblen+1
                bne _add_line

                ; Yes, it is a dot, so we're done adding lines. 
                inx
                inx

                jsr xt_cr

                jmp _input_loop
               
_add_line:
                ; Break the linked list so we can insert another node
                jsr xt_dup              ; DUP ( addr-t u-t addr1 addr1 )
                jsr xt_here             ; HERE ( addr-t u-t addr1 addr1 here )
                jsr xt_swap             ; SWAP ( addr-t u-t addr1 here addr1 )
                jsr xt_fetch            ; @  ( addr-t u-t addr1 here addr2 )
                jsr xt_comma            ; ,  ( addr-t u-t addr1 here ) 

                ; We're going to need that HERE for the next line if more
                ; than one line is added. This is a good time to save it on
                ; the stack
                jsr xt_tuck             ; TUCK ( addr-t u-t here addr1 here )

                ; We have now saved the link to the next node at HERE, which is
                ; where the CP was pointing. CP has now been advanced by one cell,
                ; but we still have the original as HERE on the stack. That 
                ; address now has to go where addr2 was before. 
                jsr xt_swap             ; SWAP ( addr-t u-t here here addr1 )
                jsr xt_store            ; ! ( addr-t u-t here )

                ; Thus concludes the mucking about with node links. Now we have
                ; to create a new header. The CP we access with HERE points to
                ; the cell after the new node address, which is where we want
                ; to put ( ) for the new string
                jsr xt_here             ; HERE ( addr-t u-t here here2)

                ; Reserve two cells (four bytes on the 65c02) for the ( addr u )
                ; of the new string
                lda cp
                clc
                adc #04
                sta cp
                bcc +
                inc cp+1
*
                ; HERE now points to after the new header. Since we're really
                ; going to add something, we can increase the current line
                ; number
                inc ed_cur
                bne +
                inc ed_cur+1
*
                ; We have the new line sitting in ( cib ciblin ) and need to
                ; 1) move it somewhere safe and 2) get ready for the next
                ; line. We arrive here with ( here here2 ), where here2 
                ; is where the new string needs to be. The MOVE command we're
                ; going to use has the format ( addr1 addr2 u )

                jsr xt_here     ; HERE ( addr-t u-t here here2 here3 )
                jsr xt_dup      ; DUP ( addr-t u-t here here2 here3 here3 )

                dex
                dex             ; ( addr-t u-t here here2 here3 here3 ? )
                lda cib
                sta 0,x
                lda cib+1
                sta 1,x         ; ( addr-t u-t here here2 here3 here3 cib )

                jsr xt_swap     ; SWAP ( addr-t u-t here here2 here3 cib here3 )

                dex
                dex             ; ( addr-t u-t here here2 here3 cib here3 ? )
                lda ciblen
                sta 0,x
                lda ciblen+1
                sta 1,x         ; ( addr-t u-t here here2 here3 cib here3 ciblen )

                jsr xt_move     ; ( addr-t u-t here here2 here3 )

                ; We need to adjust CP be the length of the string
                clc
                lda cp
                adc ciblen
                sta cp
                bcc +
                lda cp+1
                adc ciblen+1
                sta cp+1
*
                ; The string is now moved safely out of the input buffer to the
                ; main memory at ( here3 ciblin ). Now we have to fix that
                ; fact in the header. We start with the address.
                jsr xt_over             ; OVER ( addr-t u-t here here2 here3 here2 )
                jsr xt_store            ; ! ( addr-t u-t here here2 )

                jsr xt_one_plus         ; 1+
                jsr xt_one_plus         ; 1+ ( addr-t u-t here here2+2 )
                jsr xt_dup              ; DUP ( addr-t u-t here here2+2 here2+2 )

                lda ciblen
                sta 2,x
                lda ciblen+1
                sta 3,x                 ; ( addr-t u-t here ciblen here2+2 )

                jsr xt_store            ; ! ( addr-t u-t here ) 
                
                ; The string is stored and the new node is full. Time to set the
                ; changed flag
                lda #$FF
                sta ed_changed

                ; Add a line feed for visuals
                jsr xt_cr

                ; Remeber that original HERE we've been dragging along all the
                ; time? Now we find out why. We return to the loop to pick up
                ; the next input

                jmp _next_string_loop

; -------------------------
_cmd_d:
        ; d -- Delete one or more lines. This might have to be
        ; coded as a subroutine because other commands such
        ; as 'c' might be easier to implement that way. Note that a lot of
        ; this code is very similar to the loop for 'p'. Once this is
        ; all working, we should consider a common, higher level
        ; structure. We arrive here with ( addr-t u-t para1 para2 )
        
                plx 

                jsr _have_text

                ; We don't accept '0d'
                lda 2,x
                ora 3,x
                bne +

                jmp _error_2drop
*
                ; At least the first line is valid. Most common case is one
                ; line.
                lda 0,x
                ora 1,x
                bne +

                ; The second parameter is a zero, so delete one line
                jsr xt_over             ; ( addr-t u-t para1 0 para1 )
                jsr _cmd_d_common       ; ( addr-t u-t para1 0 )

                ; TODO set change flag, deal with current line
                bra _cmd_d_done

*
                ; We have been given a range. Make sure that the second
                ; parameter is legal. We arrive here with ( addr-t u-t para1 para2 )
                jsr _is_valid_line      ; result is in C flag
                bcs _cmd_d_loop

                ; para2 is not valid. Complain and abort
                jmp _error_2drop
_cmd_d_loop:
                ; Seems to be a legal range. Walk through and delete
                ; If para1 is larger than para2, we're
                ; done. Note that Unix ed throws an error if we start out
                ; that way, we might do that in future as well. This is not
                ; the same code as for 'p', because we have to delete from
                ; the back
                jsr xt_two_dup          ; 2DUP ( addr-t u-t para1 para2 para1 para2 )
                jsr xt_greater_than     ; > ( addr-t u-t para1 para2 f )

                lda 0,x
                ora 1,x
                bne _cmd_d_done_with_flag

                ; Para2 is still larger or the same size as para1, so we
                ; continue
                inx
                inx                     ; Get rid of the flag from >

                jsr xt_dup              ; ( addr-t u-t para1 para2 para2 )
                jsr _cmd_d_common       ; ( addr-t u-t para1 para2 )
                jsr xt_one_minus        ; ( addr-t u-t para1 para2-1 )

                bra _cmd_d_loop

_cmd_d_done_with_flag:
                inx                     ; ( addr-t u-t para1 para2 )
                inx                     
                
                ; The current line is set to the first line minus
                ; one. Since we don't accept '0d', this at least
                ; hast to be one
                lda 2,x
                bne +
                dec 3,x
*       
                dec 2,x

                lda 2,x
                sta ed_cur
                lda 3,x
                sta ed_cur+1            ; drop through to _cmd_d_done

_cmd_d_done:
                ; We did something, so set changed flag
                lda #$FF
                sta ed_changed

                jsr xt_cr

                jmp _next_command

_cmd_d_common:
        ; Internal subroutine to delete a single line when given the line
        ; number TOS. Consumes TOS. What we do is take the link to the next
        ; node and put it in the previous node. The caller is responsible
        ; for setting ed_changed. We arrive here with ( u )

                jsr xt_dup              ; DUP ( addr-t u-t u u )
                jsr _num_to_addr        ; ( addr-t u-t u addr ) 
                jsr xt_fetch            ; ( addr-t u-t u addr1 ) 
                jsr xt_swap             ; SWAP ( addr-t u-t addr1 u )
                jsr xt_one_minus        ; 1- ( addr-t u-t addr1 u-1 )
                jsr _num_to_addr        ; ( addr-t u-t addr1 addr-1 )
                jsr xt_store            ; ! ( addr-t u-t ) 

                rts

; -------------------------
_cmd_e: 
        ; e -- Load memory area into buffer for editing, replacing old buffer
        ; Will destroy contents of current buffer if present. Use an address
        ; and length pair separated by a comma to load a block from memory,
        ; such as "5000,100e".
        ; TODO consider a plain "e" will load from the ( addr u ) combination
        ; that was at the top of the stack when ed was started
        
                plx

                lda #'e
                jsr emit_a

                jmp _next_command
        

; -------------------------
_cmd_equ:

        ; = --- Print the given line number or the current line
        ; number if no value is given. Note that Unix ed prints
        ; the second value if given "1,2", but we print the first
                
                plx

                jsr xt_over             ; ( addr-t u-t para1 para2 para1)

                ; TODO see if valid input

                jsr xt_u_dot            ; ( addr-t u-t para1 para2 )
                jsr xt_cr

                jmp _next_command


; -------------------------
_cmd_f: 
        ; f -- Print the address that a write command ("w") will go to. In
        ; theory, we could pass a parameter, but our current setup gets us
        ; into trouble because if there is no parameter given, we have
        ; inserted the current line into para1.
        
                plx

                jsr xt_cr

                ; Print the address buried at the fourth position of the stack:
                ; We arrive here with ( addr-t u-t 0 0 )
                jsr xt_to_r             ; ( addr-t u-t 0 ) ( R: 0 )
                jsr xt_rot              ; ( u-t 0 addr-t ) ( R: 0 )
                jsr xt_dup              ; ( u-t 0 addr-t addr-t ) ( R: 0 )
                jsr xt_u_dot            ; ( u-t 0 addr-t ) ( R: 0 )
                jsr xt_not_rote         ; ( addr-t u-t 0 ) ( R: 0 )
                jsr xt_r_from           ; ( addr-t u-t 0 0 )
                jsr xt_cr

                jmp _next_command


; -------------------------
_cmd_i:
        ; i --- Add text before current line. This is currently
        ; based on 'a'.

                plx

                ; Make the previous line the new current line, so we can
                ; use the routine for a for i
                jsr xt_swap             ; ( addr-t u-t para2 para1 )

                ; While we're here, make sure para1 is a valid line
                jsr _is_valid_line
                bcs +

                ; Nope, not valid. Error and out
                jmp _error_2drop
*
                jsr xt_one_minus        ; ( addr-t u-t para2 para1-1 )
                jsr xt_zero             ; ( addr-t u-t para2 para1-1 0 )
                jsr xt_max              ; ( addr-t u-t para2 para1-1 | 0 )
                jsr xt_swap             ; ( addr-t u-t para1 para2 )
                
                jmp _entry_cmd_i


; -------------------------
_cmd_n:
        ; n -- Print lines with a line number. We just set a flag here and
        ; let p do all the heavy work.

                plx

                lda #$ff
                sta ed_flag
                bra _entry_from_cmd_n


; -------------------------
_cmd_p:
        ; p -- Print lines without line numbers. This routine is also used
        ; by n, the difference is in a flag. Note that this routine is
        ; able to handle line numbers greater than 255 even though it's
        ; hard to believe somebody would actually use this editor for anything
        ; that long. I'm really sure Leo Tolstoy would not have managed "War
        ; and Peace" on a 6502.

                plx 

_cmd_p_from_external:
                ; This is coming from p, the variant without line numbers. We
                ; set the ed_flag to zero to mark this. n enters below this
                ; with ed_flag set to $FF
                stz ed_flag

_entry_from_cmd_n:
                ; Abort if we don't have any text
                jsr _have_text

                jsr xt_cr

                ; We can't print line 0, no matter how hard we try
                lda 2,x
                ora 3,x
                bne +

                jmp _error_2drop
*
                ; We now know that there is some number in para1. The most
                ; common case is that para2 is zero and we're being asked to
                ; print a single line
                lda 0,x
                ora 1,x
                bne _cmd_p_loop

                ; Print a single line and be done with it. We could use
                ; DROP here and leave immediately but we want this routine
                ; to have a single exit at the bottom.
                jsr xt_over             ; ( addr-t u-t para1 para2 para1 )
                jsr _cmd_p_common       ; ( addr-t u-t para1 para2 )

                bra _cmd_p_all_done

_cmd_p_loop:
                ; We are being asked to print more than one line, which
                ; is a bit trickier. If para1 is larger than para2, we're
                ; done. Note that Unix ed throws an error if we start out
                ; that way, we might do that in future as well
                jsr xt_two_dup          ; 2DUP ( addr-t u-t para1 para2 para1 para2 )
                jsr xt_greater_than     ; > ( addr-t u-t para1 para2 f )

                lda 0,x
                ora 1,x
                bne _cmd_p_done

                ; Para2 is still larger or the same size as para1, so we
                ; continue
                inx
                inx                     ; Get rid of the flag from >
                jsr xt_over             ; ( addr-t u-t para1 para2 para1 )
                jsr _cmd_p_common       ; ( addr-t u-t para1 para2 )

                inc 2,x
                bne +
                inc 3,x
*
                bra _cmd_p_loop

_cmd_p_done:
                ; We arrive here with ( addr-t u-t para1 para2 f )
                inx
                inx                     ; fall through to _cmp_p_all_done
_cmd_p_all_done:
                jmp _next_command


_cmd_p_common:
        ; Internal subroutine to print a single line when given the line number
        ; TOS. Consumes TOS. Used by both n and p. We arrive here with ( addr-t u-t para1 )
        ; as the line number
                
                ; See if we're coming from p (no line numbers, ed_flag is zero)
                ; or from n (line numbers and a TAB, ed_flag is $FF)
                lda ed_flag
                beq +

                ; This is coming from n. Print the line number followed
                ; by a tab
                jsr xt_dup              ; DUP ( addr-t u-t para1 para1 )
                jsr xt_u_dot            ; U. ( addr-t u-t para1 )

                lda #$09                 ; ASCII for Tab
                jsr emit_a
*
                ; Common to both n and p: Print the line itself
                jsr _num_to_addr        ; ( addr-t u-t addr )
                jsr _print_addr 

                rts


; -------------------------
_cmd_q:
        ; q -- Quit if all work as been saved, complain otherwise
                
                plx 

                lda ed_changed
                beq +
                jmp _error_2drop
*
                jmp _all_done            ; can't fall thru because of PLX


; -------------------------
_cmd_qq:
        ; Q -- Quit unconditionally, dumping any work that is unsaved
        ; without any warning. We can't just jump to all done because
        ; of the PLX, which is cleaner to keep here.

                plx 

                jmp _all_done


; -------------------------
_cmd_w:
        ; w --- Write text to system memory. In contrast to the Unix ed word,
        ; we provide the address before the command, such as "2000w".
        ; Currently, we can only enter the address in decimal. Note that ed
        ; will let us write the text absolutely anywhere, so there is good
        ; change to mess up your system royally if you pick the wrong
        ; address.

                plx 

                jsr _have_text

                ; We don't care about the second parameter, the first
                ; one must be an address. There is actually no way to test
                ; if this is an address because any number could be a
                ; 16-bit address. Anyway, we overwrite para2 with the address
                ; where the pointer to the first entry in the list is kept.
                lda #<ed_head
                sta 0,x
                lda #>ed_head
                sta 1,x                 ; ( addr-t u-t addr-t addr-h )

                ; We need to keep a copy of the original target address to
                ; calculate how many chars (including carriage returns) we
                ; saved at the end of this routine
                jsr xt_over             ; OVER ( addr-t u-t addr-t addr-h addr-t )
                jsr xt_to_r             ; >R ( addr-t u-t addr-t addr-h ) ( R: addr-t )

_cmd_w_loop:
                jsr xt_fetch            ; @ ( addr-t u-t addr-t addr1 ) ( R: addr-t )

                ; If we're at the end of the list, quit. For the next block of text,
                ; we ignore the ( addr-t u-t ) at the beginning
                lda 0,x 
                ora 1,x
                beq _cmd_w_eol

                jsr xt_two_dup          ; 2DUP ( addr-t addr-1 addr-t addr-1 ) ( R: addr-t addr-1 addr-t )
                jsr xt_two_to_r         ; 2>R  ( addr-t addr-1 ) (R: ... ) 

                                ; Get the address and length of the string from the header
                ; of this node
                jsr xt_one_plus         ; 1+ ( addr-t addr1+1 ) (R: ... ) 
                jsr xt_one_plus         ; 1+ ( addr-t addr1+2 ) (R: ... ) 
                jsr xt_dup              ; DUP ( addr-t addr1+2 addr1+2 ) ( R: ... ) 
                jsr xt_fetch            ; @ ( addr-t addr1+2 addr-s ) ( R: ... ) 
                jsr xt_swap             ; SWAP ( addr-t addr-s addr1+2 ) ( R: ... ) 
                jsr xt_one_plus         ; 1+ ( addr-t addr-s addr1+1 ) (R: ... ) 
                jsr xt_one_plus         ; 1+ ( addr-t addr-s addr1+2 ) (R: ... ) 
                jsr xt_fetch            ; @ ( addr-t addr-s u-s ) ( R: ... ) 
                jsr xt_not_rote         ; -ROT ( u-s addr-t addr-s ) ( R: ... ) 
                jsr xt_swap             ; SWAP ( u-s addr-s addr-t ) ( R: ... ) 
                jsr xt_rot              ; ROT (addr-s addr-t u-s ) ( R: ... ) 

                ; We need a copy of the string length u-s to adjust the pointer
                ; to the store area later
                jsr xt_dup              ; DUP (addr-s addr-t u-s u-s ) ( R: ... ) 
                jsr xt_to_r             ; >R (addr-s addr-t u-s ) ( R: ... u-s ) 

                jsr xt_move             ; MOVE ( )( R: addr-t addr-1 addr-t )

                ; Calculate the position of the next string in the save area.
                ; What we don't do is remember the length of the individual
                ; strings; instead at the end we will subtract addresses to
                ; get the length of the string
                jsr xt_r_from           ; R> ( u-s )  ( R: addr-t addr-h addr-t )
                jsr xt_two_r_from       ; 2R> ( u-s addr-t addr-h ) ( R: addr-t )
                jsr xt_not_rote         ; -ROT ( addr-h u-s addr-t ) ( R: addr-t )
                jsr xt_plus             ; + ( addr-h addr-t1 ) ( R: addr-t )

                ; But wait, our strings are terminated by Line Feeds in
                ; memory, so we need to add one
                jsr xt_dup              ; DUP ( addr-h addr-t1 addr-t1 ) ( R: addr-t )
                dex
                dex                     ; ( addr-h addr-t1 addr-t1 ? ) ( R: addr-t )
                lda #AscLF              ; ASCII for LF
                sta 0,x
                stz 1,x                 ; ( addr-h addr-t1 addr-t1 c ) ( R: addr-t )
                jsr xt_swap             ; SWAP ( addr-h addr-t1 c addr-t1 ) ( R: addr-t )
                jsr xt_store            ; ! ( addr-h addr-t1 ) ( R: addr-t )
                jsr xt_one_plus         ; 1+ ( addr-h addr-t1+1 ) ( R: addr-t )

                ; Now we can handle the next line
                jsr xt_swap             ; SWAP ( addr-t1+1 addr-h ) ( R: addr-t )

                bra _cmd_w_loop

_cmd_w_eol:
                ; We're at the end of the text buffer and arrive here with
                ; ( addr-tn addr-n ) ( R: addr-t ) All we have to do now is
                ; print the number of characters saved
                jsr xt_swap             ; SWAP ( addr-t u-t addr-n addr-tn ) ( R: addr-t ) 
                jsr xt_r_from           ; R> ( addr-t u-t addr-n addr-tn addr-t ) 
                jsr xt_minus            ; - ( addr-t u-t addr-n u ) 
                jsr xt_dup              ; DUP ( addr-t u-t addr-n u u ) 

                ; Unix ed puts the number of characters on a new line, so we
                ; do as well
                jsr xt_cr
                jsr xt_u_dot            ; U. ( addr-t u-t addr-n u ) 
                jsr xt_cr

                ; Reset the changed flag
                stz ed_changed

                jmp _next_command


; === ERROR HANDLING ===

_error_2drop:
                ; Lots of times we'll have para1 and para2 on the stack when an
                ; error occurs, so we drop stuff here
                inx
                inx                     ; drop through to _error_1drop
_error_1drop:
                inx
                inx                     ; drop through to error
_error:
                ; Error handling with ed is seriously primitive: We print a question
                ; mark and go back to the loop. Any code calling this routine must
                ; clean up the stack itself: We expect it to be empty. Note that
                ; ed currently does not support reporting the type of error on
                ; demand like Unix ed
                jsr xt_cr

                lda #'?
                jsr emit_a

                jsr xt_cr

                jmp _input_loop


; === HELPER FUNCTIONS ===

_get_input:
        ; Use REFILL to get input from the user, which is left in
        ; ( cib ciblen ) as usual.
                jsr xt_refill           ;  ( addr-t u-t f )

                ; If something went wrong while getting the user input, print
                ; a question mark and try again. No fancy error messages
                ; for ed!
                lda 0,x
                ora 1,x
                bne +

                ; Whatever went wrong, we can't handle it here anyway. We
                ; clear the return stack, dump the error flag and call
                ; a normal error
                ply
                ply

                jmp _error_1drop
*
                ; Drop the flag
                inx                     
                inx

                rts

; -----------------------------
_have_text:
        ; See if we have any lines at all. If not, abort with an error.
                lda ed_head
                ora ed_head+1
                bne +

                ; We don't have any lines. Clean up the return stack and throw
                ; an error
                ply
                ply
                bra _error
*
                rts


; -----------------------------
_is_valid_line:
        ; See if the line number in TOS is valid. If yes, returns the carry
        ; flag set ("true"), otherwise cleared ("false"). Does not change
        ; the value of TOS. Line numbers must be 0 < number <= last_line.
        ; This routine calls _last_line.
        sec                             ; default is legal line number

        ; First, see if we have a zero
        lda 0,x
        ora 1,x
        beq _is_valid_line_nope_zero    ; ( n )

        ; Not a zero. Now see if we're beyond the last line
        jsr xt_dup                      ; DUP ( n n )
        jsr _last_line                  ; ( n n last )
        jsr xt_swap                     ; SWAP ( n last n )
        jsr xt_less_than                ; < ( n f )

        lda 0,x                         ; 0 flag is good
        ora 1,x
        bne _is_valid_line_too_small

        ; We're good, clean up and leave
        inx
        inx                             ; DROP flag ( n )

        sec                             ; Who knows what's happened to C by now
        bra _is_valid_line_done         ; only one exit from this routine

_is_valid_line_too_small:
        inx
        inx                             ; drop through to _is_valid_line_zero

_is_valid_line_nope_zero:
        clc                             ; drop through to _is_valid_line_done

_is_valid_line_done:
        rts


; -----------------------------
_last_line:
        ; Calculate the number of the last line (not its address) and return
        ; it TOS. Note this shares code with _num_to_addr

                ; Set counter to zero
                stz tmp1
                stz tmp1+1

                dex
                dex                     ; ( ? )
        
                lda #<ed_head
                sta 0,x
                lda #>ed_head
                sta 1,x                 ; ( addr )

_last_line_loop:
                jsr xt_fetch            ; ( addr | 0 )

                ; If that's over, we're at the end of the list and we're done
                lda 0,x
                ora 1,x
                beq _last_line_done

                ; Not done. Increase counter and continue
                inc tmp1
                bne +
                inc tmp1+1
*
                bra _last_line_loop
 
_last_line_done:
                lda tmp1
                sta 0,x
                lda tmp1+1
                sta 1,x                 ; ( u ) 

                rts


; -----------------------------
_num_to_addr:
        ; Given a line number as TOS, replace it by the address of the node.
        ; If the line number is zero, we return the address of the header
        ; node. If the line number is beyond the last line, we return a
        ; zero, though we're assuming the user will check for a legal 
        ; line number before calling this routine

                ; One way or another we're going to start with the 
                ; address of the pointer to the head of the list
                dex
                dex                     ; ( u ? )
        
                lda #<ed_head
                sta 0,x
                lda #>ed_head
                sta 1,x                 ; ( u addr-h )

                ; Handle the case where the line number is zero.
                lda 2,x
                ora 3,x
                bne _num_to_addr_loop

                ; It's zero, so we're already done
                jsr xt_nip              ; ( addr-h )
                bra _num_to_addr_done

_num_to_addr_loop:
                ; Get the first line
                jsr xt_fetch            ; @ ( u addr1 )

                ; If that's zero, we're at the end of the list and it's over
                lda 0,x
                ora 1,x
                bne +
 
                jsr xt_nip              ; NIP ( addr1 ) 
                bra _num_to_addr_done
*
                ; It's not zero. See if this is the nth element we're looking
                ; for
                jsr xt_swap             ; SWAP ( addr1 u )
                jsr xt_one_minus        ; 1- ( addr1 u-1 )

                lda 0,x
                ora 1,x
                beq _num_to_addr_finished

                ; Not zero yet, try again
                jsr xt_swap             ; SWAP ( u-1 addr1 )

                bra _num_to_addr_loop
                
_num_to_addr_finished:
                ; We arrive here with ( addr u )
                inx
                inx                     ; ( addr )

_num_to_addr_done:
                rts

; -----------------------------
_para1_to_cur:
        ; Switch the current line number to whatever the first parameter
        ; is. We do this a lot so this routine saves a few bytes
                lda 2,x
                sta ed_cur
                lda 3,x
                sta ed_cur+1

                rts

; -----------------------------
_print_addr:
        ; Given the address of a node TOS, print the string it comes with.
        ; Assumes we have made sure that this address exists. It would be
        ; nice to put the CR at the beginning, but that doesn't work with
        ; the n commands, so at the end it goes. Consumes TOS.
                jsr xt_one_plus
                jsr xt_one_plus         ; ( addr+2 )

                jsr xt_dup              ; ( addr+2 addr+2 )

                jsr xt_one_plus
                jsr xt_one_plus         ; ( addr+2 addr+4 )

                jsr xt_fetch            ; ( addr+2 u-s )
                jsr xt_swap             ; ( u-s addr+2 )
                jsr xt_fetch            ; ( u-s addr-s )

                jsr xt_swap             ; ( addr-s u-s )
                jsr xt_type
                jsr xt_cr

                rts

; === COMMAND TABLES ===

; The commands are all one character and kept in a 0-terminated string that is
; walked by a loop. Their index corresponds to the index of their routine's
; address in the jump table. To add a new command, add it's letter at the
; correct position in the command list and the routine's address in the command
; jump table. Oh, and add the routine as well. Capital letters such as 'Q' are
; coded in their routine's address as double letters ('_cmd_qq').

ed_cmd_list:    .byte "aefidpn=wqQ", 0

ed_cmd_table:
                .word _cmd_a, _cmd_e, _cmd_f, _cmd_i, _cmd_d, _cmd_p, _cmd_n
                .word _cmd_equ, _cmd_w, _cmd_q, _cmd_qq

.scend
ed6502_end:     ; Used to calculate size of editor code
