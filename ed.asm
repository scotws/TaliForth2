; ed6502 - Ed-like line-based editor for Tali Forth 2 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 13. Okt 2018
; This version: 26. Okt 2018

; This is a line-orientated editor for Tali Forth 2 based on the classic
; Unix editor of the same name. It is included because a) I like line
; editors and this is my project, and b) as a very simple editor that
; will work even if there is no vt100 terminal support, just with
; ASCII if needs be. For further information on ed, see
;   https://en.wikipedia.org/wiki/Ed_(text_editor)
;   https://www.gnu.org/software/ed/ed.html
;   https://www.gnu.org/software/ed/manual/ed_manual.html
;   https://sanctum.geek.nz/arabesque/actually-using-ed/

; We'll start editor from Forth with 
;
;       ed ( -- u )
;
; where u is either the number of bytes written or a zero if none
; were written.

; If the first character of the text area is a legal ASCII character,
; we assume that we are being asked to edit an existing text file.
; Otherwise, we assume that the finished text is to be stored there. Ed starts
; at HERE with its working memory, so the user probably wants to make sure that
; the memory is reserved with a word such as BUFFER:

; In the working memory, the text is stored as a simple linked list of line.
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
; for the commands on the Data Stack:
;
;       TOS: parameter 2 (after the comma)
;       NOS: parameter 1 (before the comma)
;
; We also need a pointer to the beginning of the text (first node of the
; list), the number of the current line, a flag for the mode (input or
; command), and a flag to mark if the text has been changed. We have six
; bytes of zero page reserved for any editor to use. Note that this means that
; we can't use two editors at the same time, which won't be a problem until we
; can multitask.
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

                jsr xt_cr

_input_loop: 
                ; Start command loop: Get input from the user. Print one line feed
                ; first

                ; Get input from the user. This routine handles any errors from
                ; refill
                jsr _get_input
                
                ; If we were given an empty line, complain
                ; TODO Actually, we want to advance by one line and print the
                ; new one
                lda ciblen
                ora ciblen+1
                bne _command_mode

                jmp _error

_command_mode:
                ; We're in command mode, so we have to parse the input
                ; string. We really don't want to have to write a complete
                ; parser for such a simple editor, so we walk through the
                ; possibilities the hard way.

                ; Set the parameter variables to zero. This is used as a flag
                ; to show we're only dealing with the current line, because there
                ; is no line 0 (we're coding for normal, sane humans, not
                ; silly computer programmers)
                jsr xt_zero             ; parameter 1 is NOS ( 0 )
                jsr xt_zero             ; parameter 2 is TOS ( 0 0 )
                
                ; We start off taking care of any parameters. These can be '%'
                ; for the complete text, '$' for the last line, a line number;
                ; or a line number followed by a ',' and then either the '$' for
                ; the last line or another number. (The original Unix ed has
                ; more options, but we're ignoring them for the moment.) In
                ; pseudocode, what we are doing in this stage looks something
                ; like this:

                ;        if char = '%':
                ;              para1 = 1
                ;              para2 = end_of_text
                ;       
                ;        elif char = '$':
                ;              para1 = end_of_text
                ;       
                ;        elif number:
                ;              para1 = number
                ;              next_char
                ;       
                ;              if char = ',':
                ;                      next_char
                ;       
                ;                      if char = '$':
                ;                              para2 = end_of_text
                ;                      elif number:
                ;                              para2 = number
                ;                      else error
                ;              
                ;              else prev_char
                ;       
                ;        next_char
                ;        proc_command

                ; We use the Y register as an offset to the beginning of the
                ; character input buffer (CIB) because we're never going to
                ; have more than 255 characters of input with ed and we don't
                ; want to have to duplicated the complete machinery required
                ; for >IN. In other words, >IN has no meaning for ed. This
                ; means that every jmp to _check_command must have Y in a 
                ; defined state.

_prefix_percent:
                ; --- % --- Designate whole text for futher operations
                lda (cib)
                cmp #$25                ; ASCII '%'
                bne _prefix_dollar

                ; If there is no text yet, print an error
                jsr _have_text

                ; So we have at least one line of text. The first parameter
                ; is therefore line one, the second the last line
                lda #01
                sta 2,x                 ; LSB of NOS is para 1
                stz 3,x                 ; ( para1 0 )

                ; Get the number (not the address) of the last line and
                ; store it as the second parameter
                inx
                inx                     ; DROP ( para1 )
                jsr _last_line          ; ( para1 para2 )
                
                ; We are one character into the input buffer CIB, so we advace
                ; Y as the index accordingly 
                ldy #01

                jmp _check_command

_prefix_dollar:
                ; --- $ --- Designate last line for further operations
                lda (cib) 
                cmp #'$
                bne _prefix_number

                jsr _have_text

                inx
                inx                     ; ( 0 )

                jsr _last_line          ; ( 0 para1 )
                jsr xt_swap             ; SWAP ( para1 0 ) 

                ; We are one character into the input buffer CIB, so we advace
                ; Y as the index accordingly 
                ldy #01

                jmp _check_command

_prefix_number:
                ; --- <NUM> --- Check if we have been given a number. We use
                ; the built-in Forth routines for this, which involves
                ; calling >NUMBER, which calls UM*, which uses tmp1, tmp2,
                ; and tmp3. We arrive here with ( 0 0 ), which doesn't
                ; help us at all because the string we are looking at is in
                ; ( cib ciblen )

                ; TODO figure out what happens if BASE is not 10

                ; Set up >NUMBER using CIB and CIBLEN as the location of the
                ; string to check. First, though, add the "accumulator" as
                ; a double number
                jsr xt_zero
                jsr xt_zero             ; ( 0 0 0 0 )
                
                dex                     
                dex
                dex
                dex                     ; ( 0 0 0 0 ? ? )

                lda cib
                sta 2,x
                lda cib+1
                sta 3,x                 ; ( 0 0 0 0 cib ? )

                lda ciblen
                sta 0,x
                lda ciblen+1
                sta 1,x                 ; ( 0 0 0 0 cib ciblen )

                jsr xt_to_number        ; ( 0 0 ud addr2 u2 ) 

                ; If we converted all the characters in the string (u2 is
                ; zero), then the user just gave us a line number to
                ; jump to and nothing else.
                lda 0,x
                ora 1,x
                bne +

                ; We must have a line number. Make this the current line
                ; number and print the line
                inx
                inx
                inx
                inx                     ; 2DROP ( 0 0 ud )

                jsr xt_d_to_s           ; D>S ( 0 0 u )
                jsr xt_not_rote         ; -ROT ( u 0 0 )

                inx
                inx                     ; ( u 0 )

                jmp _cmd_p_common

*
                ; We have some unconverted characters left. If none of the
                ; characters were converted, we probably just got a
                ; command character and need to skip the rest of the prefix
                ; processing. In this case, the number of unconverted
                ; characters is equal to the length of the string.

                ; TODO Deal with ' ', <CR>, '+' and '-' as instructions
 
                jsr xt_dup              ; ( 0 0 ud addr2 u2 u2 )
                
                dex
                dex                     ; ( 0 0 ud addr2 u2 u2 ? )
                lda ciblen
                sta 0,x
                lda ciblen+1
                sta 1,x                 ; ( 0 0 ud addr2 u2 u2 ciblen )

                jsr xt_equal            ; ( 0 0 ud addr2 u2 f )

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
                tax                     ; ( 0 0 )

                ; We don't have any offset, so we go with Y as zero
                ldy #00

                jmp _check_command
                
_no_command_yet:
                ; There actually seems to be a parameter number present.
                ; Save the number we converted as the first parameter. We
                ; arrive here with ( 0 0 ud addr2 u2 f ) from >NUMBER
                inx
                inx                     ; ( 0 0 ud addr2 u2 )

                jsr xt_to_r             ; >R ( 0 0 ud addr2 ) (R: u2)
                jsr xt_not_rote         ; -ROT ( 0 0 addr2 ud ) (R: u2) 
                jsr xt_d_to_s           ; D>S  ( 0 0 addr2 para1 ) (R: u2)

                lda 0,x                 ; LSB
                sta 6,x
                lda 1,x                 ; MSB
                sta 7,x                 ; ( para1 0 addr2 para1 ) (R: u2)

                inx
                inx                     ; ( para1 0 addr2 ) (R: u2)
                jsr xt_r_from           ; R> ( para1 0 addr2 u2 )

                ; That was the first parameter. If the next character is
                ; a comma, then there is a second parameter (another number
                ; or '$'). Otherwise we expect a command
                lda (2,x)
                cmp #$2c                ; ASCII code for ',' (comma)
                bne +

                ; It's not a comma, so it's going to be a command character.
                ; We need to figure out how many digits our number has so
                ; we can adjust Y as the offset. We don't have to do this with
                ; 16 bit because no input string is going to be that long
                sec
                lda ciblen
                sbc 0,x
                tay
                
                jmp _check_command
*
                ; It's a comma, so we have a second parameter. The next
                ; character can either be '$' to signal the end of the text
                ; or another number. First, move to that next char
                inc 2,x
                bne +
                inc 3,x                 ; ( para1 0 addr2+1 u2 )
*
                lda 1,x
                bne +
                dec 1,x
*
                dec 0,x                 ; (para1 0 addr2+1 u2-1 )

                ; See if it's a '$'
                lda (2,x)
                cmp #$24                ; ASCII for '$'
                bne _para2_not_dollar

                ; It's a dollar sign, which means para2 is the number
                ; of the last line of the text
                jsr _last_line          ; ( para1 0 addr2+1 u2-1 para2 )

                lda 0,x 
                sta 4,x
                lda 1,x
                sta 5,x                 ; ( para1 para2 addr2+1 u2-1 para2 )

                inx
                inx                     ; ( para1 para2 addr2+1 u2-1 )
                
                ; TODO handle offset and Y 

                jmp _check_command

_para2_not_dollar:
                ; It's not a dollar sign, so it is either another number or
                ; an error. We try for a number first. We arrive here
                ; with ( para1 0 addr2+1 u2-1 )
                
                ; Set up >NUMBER (again)
                jsr xt_to_r             ; >R ( para1 0 addr2+1 ) (R: u2-1)
                jsr xt_zero             ; 0 ( para1 0 addr2+1 0 ) (R: u2-1)
                jsr xt_zero             ; 0 ( para1 0 addr2+1 0 0 ) (R: u2-1)
                jsr xt_rot              ; ROT ( para1 0 0 0 addr2+1 ) (R: u2-1)
                jsr xt_r_from           ; R> ( para1 0 0 0 addr2+1 u2-1)

                ; We'll need a copy of the lenght of the rest of the string to
                ; see if we've actually done any work
                jsr xt_dup              ; DUP ( para1 0 0 0 addr2+1 u2-1 u2-1)
                jsr xt_to_r             ; >R ( para1 0 0 0 addr2+1 u2-1 ) (R: u2-1)
                
                jsr xt_to_number        ; >NUMBER ( para1 0 ud addr3 u3 ) (R: u2-1)

                ; If the original string and the leftover string have the same
                ; length, then nothing was converted and we have an error
                jsr xt_dup              ; DUP ( para1 0 ud addr3 u3 u3 ) (R: u2-1)
                jsr xt_r_from           ; R> ( para1 0 ud addr3 u3 u3 u2-1 )
                jsr xt_equal            ; = ( para1 0 ud addr3 u3 f )

                lda 0,x
                ora 1,x
                beq _second_number

                ; The strings are the same length, so nothing was converted, so
                ; we have an error. We have to get all that stuff off the
                ; stack first
                txa
                clc
                adc #12
                tax                     ; back to ( ) 

                jmp _error

_second_number:
                ; We have a second number, so we add it to para2. We arrive here
                ; with ( para1 0 ud addr3 u3 f )
                inx
                inx                     ; ( para1 0 ud addr3 u3 )

                ; TODO figure out offset in Y

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

                lda ed_cur
                sta 2,x
                lda ed_cur+1
                sta 3,x
*
                ; TODO TEST ---------------------------------
                ; TEST : Print parameters

                ; Skip over this for the moment
                bra +

                phy                     ; save the offset

                lda #$28
                jsr emit_a

                jsr xt_swap             ; ( para2 para1 )
                jsr xt_dup
                jsr xt_u_dot

                jsr xt_swap             ; ( para1 para2 )
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
                pla                     ; this is the DSP
                clc
                adc #04
                tax                     ; ( ) 

                jmp _error

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
                

; === COMMAND ROUTINES ====

; We enter all command subroutines with ( para1 para2 ) and the
; DSP still on the Return Stack. This means that the first oder of business
; is to restore the DSP. At this point, we don't need the offset in Y anymore.

; -------------------------
_cmd_a:
                ; --- a --- Add text after current/given line --- 
                
                ; Switch to import mode and add text after given line. If no
                ; line is given, we use the current line. We accept the number
                ; '0' and then start adding at the very beginning. The second
                ; parameter is ignored.

                plx

_entry_cmd_i:
                ; We don't care about para2, because a just adds stuff starting
                ; the line we were given
                inx
                inx                     ;  DROP ( para1 )

                jsr _num_to_addr        ;  ( addr1 ) 
                jsr xt_cr

_next_string_loop:
                ; This is where we land when we are continuing in with another
                ; string after the first one. ( addr1 )
                
                ; Break the linked list so we can insert another node
                jsr xt_dup              ; DUP ( addr1 addr1 )
                jsr xt_here             ; HERE ( addr1 addr1 here )
                jsr xt_swap             ; SWAP ( addr1 here addr1 )
                jsr xt_fetch            ; @  ( addr1 here addr2 )
                jsr xt_comma            ; ,  ( addr1 here ) 

                ; We're going to need that HERE for the next line if more
                ; than one line is added. This is a good time to save it on
                ; the stack
                jsr xt_tuck             ; TUCK ( here addr1 here )

                ; We have now saved the link to the next node at HERE, which is
                ; where the CP was pointing. CP has now been advanced by one cell,
                ; but we still have the original as HERE on the stack. That 
                ; address now has to go where addr2 was before. 
                jsr xt_swap             ; SWAP ( here here addr1 )
                jsr xt_store            ; ! ( here )

                ; Thus concludes the mucking about with node links. Now we have
                ; to create a new header. The CP we access with HERE points to
                ; the cell after the new node address, which is where we want
                ; to put ( ) for the new string
                jsr xt_here             ; HERE ( here here2)

                ; We can start accepting a string
                jsr _get_input          ; ( here here2 )
                
                ; If there is only one character and that character is a
                ; dot, we're done with adding text and switch back to command
                ; mode
                lda (cib)
                cmp #$2e                ; ASCII for '.'
                bne _read_new_line

                ; So it's a dot, but that the only character in the line?
                ; We want the length to be 0001
                ldy ciblen
                cpy #01
                bne _read_new_line
                ldy ciblen+1
                bne _read_new_line

                ; Yes, it is a dot, so we're done adding lines. Clean up
                ; and return to command mode. Drop all the HERE stuff from the
                ; stack 
                inx
                inx
                inx
                inx                     ; ( )

                jsr xt_cr

                jmp _input_loop

_read_new_line:
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

                jsr xt_here             ; HERE ( here here2 here3 )
                jsr xt_dup              ; DUP ( here here2 here3 here3 )

                dex
                dex                     ; ( here here2 here3 here3 ? )
                lda cib
                sta 0,x
                lda cib+1
                sta 1,x                 ; ( here here2 here3 here3 cib )

                jsr xt_swap             ; SWAP ( here here2 here3 cib here3 )

                dex
                dex                     ; ( here here2 here3 cib here3 ? )
                lda ciblen
                sta 0,x
                lda ciblen+1
                sta 1,x                 ; ( here here2 here3 cib here3 ciblen )

                jsr xt_move             ; ( here here2 here3 )

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
                jsr xt_over             ; OVER ( here here2 here3 here2 )
                jsr xt_store            ; ! ( here here2 )

                jsr xt_one_plus         ; 1+
                jsr xt_one_plus         ; 1+ ( here here2+2 )
                jsr xt_dup              ; DUP ( here here2+2 here2+2 )

                lda ciblen
                sta 2,x
                lda ciblen+1
                sta 3,x                 ; ( here ciblen here2+2 )

                jsr xt_store            ; ! ( here ) 
                
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
_cmd_c:
                ; --- c --- Change a line ---

                plx

                jsr _have_text

                ; TODO change lines

                lda #$28
                jsr emit_a
                lda #'c
                jsr emit_a
                lda #'l
                jsr emit_a
                lda #$29
                jsr emit_a

                lda #$FF
                sta ed_changed

                jmp _next_command

; -------------------------
_cmd_d:
                ; --- d --- delete a line ---

                plx 

                jsr _have_text

                ; TODO delete the line
                lda #$28
                jsr emit_a
                lda #'d
                jsr emit_a
                lda #'l
                jsr emit_a
                lda #$29
                jsr emit_a

                jmp _next_command

; -------------------------
_cmd_equ:
                ; --- = --- Print current line number ---
                
       

                plx

                ; If there is no text, = prints the number zero, not an
                ; error as one might assume
                lda (ed_head)
                ldy #01
                ora (ed_head),y

                bne +
 
                ; No text, print a zero
                lda #'0
                jsr emit_a

                bra _cmd_equ_done
*
                ; Text not empty, print the real line number
                dex
                dex                     ; ( para1 para2 ? )
                lda ed_cur
                sta 0,x
                lda ed_cur+1
                sta 1,x                 ; ( para1 para2 cur )

                jsr xt_dot              ; ( para1 para2 )
               
                                        ; fall through to _cmd_equ_done
_cmd_equ_done:
                jmp _next_command


; -------------------------
_cmd_i:
                ; --- i --- Add text before current line ---

                plx

                ; Make the previous line the new current line, so we can
                ; use the routine for a for i
                jsr xt_swap             ; ( para2 para1 )
                jsr xt_one_minus        ; ( para2 para1-1 )
                jsr xt_zero             ; ( para2 para1-1 0 )
                jsr xt_max              ; ( para2 para1-1 | 0 )
                jsr xt_swap             ; ( para1 para2 )
                
                jmp _entry_cmd_i

; -------------------------
_cmd_j:
                ; --- j --- Join two lines ---
                plx
                ; TODO make sure we have at least two lines

                ; TODO join the lines
                lda #'j
                jsr emit_a
                lda #'l
                jsr emit_a

                lda #$FF
                sta ed_changed

                jmp _next_command

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
                jsr xt_over             ; ( para1 para2 para1 )
                jsr _cmd_p_common       ; ( para1 para2 )

                bra _cmd_p_all_done

_cmd_p_loop:
                ; We are being asked to print more than one line, which
                ; is a bit tricker. If para1 is larger than para2, we're
                ; done. Note that Unix ed throws an error if we start out
                ; that way, we might do that in future as well
                jsr xt_two_dup          ; 2DUP ( para1 para2 para1 para2 )
                jsr xt_greater_than     ; > ( para1 para2 f )

                lda 0,x
                ora 1,x
                bne _cmd_p_done

                ; Para2 is still larger or the same size as para1, so we
                ; continue
                inx
                inx                     ; Get rid of the flag from >
                jsr xt_over             ; ( para1 para2 para1 )
                jsr _cmd_p_common       ; ( para1 para2 )

                inc 2,x
                bne +
                inc 3,x
*
                bra _cmd_p_loop

_cmd_p_done:
                ; We arrive here with ( para1 para2 f )
                inx
                inx                     ; fall through to _cmp_p_all_done
_cmd_p_all_done:
                jmp _next_command


_cmd_p_common:
        ; Internal subroutine to print a single line when given the line number
        ; TOS. Consumes TOS. Used by both n and p. We arrive here with ( para1 )
        ; as the line number
                
                ; See if we're coming from p (no line numbers, ed_flag is zero)
                ; or from n (line numbers and a TAB, ed_flag is $FF)
                lda ed_flag
                beq +

                ; This is coming from n. Print the line number followed
                ; by a tab
                jsr xt_dup              ; DUP ( para1 para1 )
                jsr xt_u_dot            ; U. ( para1 )

                lda #$09                 ; ASCII for Tab
                jsr emit_a
*
                ; Common to both n and p: Print the line itself
                jsr _num_to_addr        ; ( addr )
                jsr _print_addr 

                rts


; -------------------------
_cmd_q:
        ; q -- Quit if all work as been saved, complain otherwise
                
                plx 

                lda ed_changed
                beq +
                jmp _error
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
_cmd_r:
                ; --- r --- Read lines ---

                plx

                ; TODO read lines
                lda #'r
                jsr emit_a
                lda #'t
                jsr emit_a

                lda #$FF
                sta ed_changed

                bra _next_command


; -------------------------
_cmd_w:
                ; --- w --- Write text ---

                plx 

                jsr _have_text

                ; TODO make sure we write the string with a CR at the end

                ; TODO write lines
                lda #'w
                jsr emit_a
                lda #'t
                jsr emit_a

                ; Reset the changed flag
                stz ed_changed

                bra _next_command        ; TODO See about fallthrough

; -------------------------
_next_command:
                ; Clean up the stack and return to the input loop. We
                ; arrive here with ( para1 para2 )
                inx
                inx
                inx
                inx

                jmp _input_loop

                
_all_done:
                ; We have to clear out the input buffer or else the Forth main
                ; main loop will react to the last input command
                stz ciblen
                stz ciblen+1

                ; TODO clean up the stack

                ; TODO we leave here with ( -- 0 ) for the moment this
                ; is just zero 
                jsr xt_zero

                rts


; === ERROR HANDLING ===

_error_2drop:
                ; Lots of times we'll have para1 and para2 on the stack when an
                ; error occurs, so we drop stuff here
                inx
                inx
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

                jmp _input_loop         ; this provides the second CR


; === HELPER FUNCTIONS ===

; -----------------------------
_get_input:
        ; Use REFILL to get input from the user, which is left in
        ; ( cib ciblen ) as usual.
                jsr xt_refill           ;  ( f )

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

                inx
                inx

                jmp _error
*
                ; Drop the flag
                inx                     
                inx

                rts

; -----------------------------
_have_text:
        ; See if we have any lines at all. If not, abort with an error.
        
                lda (ed_head)
                ldy #01
                ora (ed_head),y
                bne +

                ; We don't have any lines. Clean up the return stack and throw
                ; an error
                ply
                ply
                bra _error
*
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
                ; Actually, this goes one step too far. We should do this
                ; better, but for the moment we're going work with this
                lda tmp1
                bne +
                dec tmp1+1
*
                dec tmp1

                lda tmp1
                sta 0,x
                lda tmp1+1
                sta 1,x                 ; ( u ) 

                rts


; -----------------------------
_num_to_addr:
        ; Given a line number as TOS, replace it by the address of the node,
        ; or 0000 if a failure. We assume here that the line number is not
        ; going to be zero, and that we actually have lines

                ; We'll do stuff on the stack
                dex
                dex                     ; ( u ? )

                ; Start with the header of the linked list
                lda #<ed_head
                sta 0,x
                lda #>ed_head
                sta 1,x                 ; ( u addr )

                ; Special case: If the line number is zero, we start off with
                ; the address of the header
                lda 2,x
                ora 3,x
                bne _num_to_addr_loop

                ; It's zero, so we're already good
                jsr xt_nip              ; ( addr )
                bra _num_to_addr_list_ended

_num_to_addr_loop:
                ; Get the first line
                jsr xt_fetch            ; @ ( u addr1 )

                ; If that's zero, we're at the end of the list and it's over
                lda 0,x
                ora 1,x
                bne +
 
                jsr xt_nip              ; NIP ( 0 ) 
                bra _num_to_addr_list_ended
*
                ; It's not zero. See if this is the nth element we're looking
                ; for
                jsr xt_swap             ; SWAP ( addr1 u )
                jsr xt_one_minus        ; 1- ( addr1 u-1 )

                lda 0,x
                ora 1,x
                beq _num_to_addr_done

                ; Not zero yet, try again
                jsr xt_swap             ; SWAP ( u-1 addr1 )

                bra _num_to_addr_loop
                
_num_to_addr_done:
                ; We arrive here with ( addr u )
                inx
                inx                     ; ( addr )

_num_to_addr_list_ended:

                rts

; -----------------------------
_print_addr:
        ; Given the address of a node TOS, print the string it comes with.
        ; Assumes we have made sure that this address exists. It would be
        ; nice to put the CR at the beginning, but that doesn't work with
        ; the n commands, so at the end it goes
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

ed_cmd_list:    .byte "aidpn=jwrqQ0"

ed_cmd_table:
                .word _cmd_a, _cmd_i, _cmd_d, _cmd_p, _cmd_n, _cmd_equ
                .word _cmd_j, _cmd_w, _cmd_r, _cmd_q, _cmd_qq

.scend
ed6502_end:     ; Used to calculate size of editor code
