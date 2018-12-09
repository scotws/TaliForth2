; Definitions for Tali Forth 2
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 24. Oct 2018

; This file is included by taliforth.asm. These are the general
; definitions; platform-specific definitions such as the
; memory map are kept in the platfrom folder.


; ZERO PAGE ADDRESSES/VARIABLES

; These are as close to the definitions in Liara Forth as possible.
; They are kept at the top of Zero Page, with the most important variables
; at the top because the Data Stack grows towards this area from dsp0: If
; there is an overflow, the lower, less important variables will be
; clobbered first, giving the system a chance to recover. In other words,
; they are part of the floodplain.

.alias cp        user0+0  ; Compiler Pointer
.alias dp        user0+2  ; Dictionary Pointer
.alias workword  user0+4  ; nt (not xt!) of word being compiled, except in
                          ; a :NONAME declared word (see status)
.alias insrc     user0+6  ; input Source for SOURCE-ID
.alias cib       user0+8  ; address of current input buffer
.alias ciblen    user0+10  ; length of current input buffer
.alias toin      user0+12  ; pointer to CIB (>IN in Forth)
.alias ip        user0+14  ; Instruction Pointer (current xt)
.alias output    user0+16  ; vector for EMIT
.alias input     user0+18  ; vector for KEY
.alias havekey   user0+20  ; vector for KEY?
.alias state     user0+22  ; STATE: -1 compile, 0 interpret
.alias base      user0+24  ; number radix, default 10
.alias nc_limit  user0+26  ; limit for Native Compile size
.alias uf_strip  user0+28  ; flag to strip underflow detection code
.alias tmpbranch user0+30  ; temp storage for 0BRANCH, BRANCH only
.alias tmp1      user0+32  ; temporary storage
.alias tmp2      user0+34  ; temporary storage
.alias tmp3      user0+36  ; temporary storage (especially for print)
.alias tmpdsp    user0+38  ; temporary DSP (X) storage (two bytes)
.alias tmptos    user0+40  ; temporary TOS storage
.alias editor1   user0+42  ; temporary for editors
.alias editor2   user0+44  ; temporary for editors
.alias editor3   user0+46  ; temporary for editors
.alias tohold    user0+48  ; pointer for formatted output 
.alias scratch   user0+50  ; 8 byte scratchpad (see UM/MOD)
.alias status    user0+58  ; internal status information
                           ; (used by : :NONAME ; ACCEPT)
                           ; Bit 6 = 1 for normal ":" definitions
                           ;         WORKWORD contains nt of word being compiled
                           ;       = 0 for :NONAME definitions
                           ;         WORKWORD contains xt of word being compiled
                           ; Bit 5 = 1 for NUMBER returning a double word
                           ;       = 0 for NUMBER returning a single word
                           ; Bit 3 = 1 makes CTRL-n recall current history
                           ;       = 0 CTRL-n recalls previous history
                           ; Bit 2 = Current history buffer msb
                           ; Bit 1 = Current history buffer (0-7, wraps)
                           ; Bit 0 = Current history buffer lsb
                           ; status+1 is used by ACCEPT to hold history lengths.
        
.alias up        user0+60  ; User Pointer (Address of user variables)
; Block variables                
.alias blk_offset 0        ; BLK : UP + 0
.alias scr_offset 2        ; SCR : UP + 2
; Wordlists                
.alias current_offset 4    ; CURRENT : UP + 4 (Compilation wordlist)
.alias num_wordlists_offset 6
                           ; #WORDLISTS : UP + 6
.alias wordlists_offset 8  ; WORDLISTS : UP + 8 to UP + 29
                           ;             (FORTH, EDITOR, ASSEMBLER, +8 more)
.alias num_order_offset 30 ; #ORDER : UP + 30
                           ;          (Number of wordlists in search order)
.alias search_order_offset 32
                           ; SEARCH-ORDER : UP + 32 to UP + 47
.alias max_wordlists 11
; Buffer variables
.alias blkbuffer_offset    48   ; Address of buffer
.alias buffblocknum_offset 50   ; Block number current in buffer
.alias buffstatus_offset   52   ; Status of buffer (bit 0 = used, bit 1 = dirty)
; Block I/O vectors
.alias blockread_offset    54   ; Vector to block reading routine
.alias blockwrite_offset   56   ; Vector to block writing routine        
                
; Bytes used for variables: 62 ($0000-$003D) 
; First usable Data Stack location: $003E (decimal 62) 
; Bytes avaible for Data Stack: 128-62 = 66 --> 33 16-bit cells

.alias dsp0      $78            ; initial Data Stack Pointer, see docs/stack.md

; ASCII CHARACTERS

.alias AscCC   $03  ; break (CTRL-c)
.alias AscBELL $07  ; bell sound
.alias AscBS   $08  ; backspace 
.alias AscLF   $0a  ; line feed
.alias AscCR   $0d  ; carriage return
.alias AscESC  $1b  ; escape
.alias AscSP   $20  ; space
.alias AscDEL  $7f  ; delete (CTRL-h)
.alias AscCP   $10  ; CTRL-p (used to recall previous input history)
.alias AscCN   $0e  ; CTRL-n (used to recall next input history)
    

; DICTIONARY FLAGS

; The first three bits are currently unused

.alias CO 1  ; Compile Only
.alias AN 2  ; Always Native Compile
.alias IM 4  ; Immediate Word
.alias NN 8  ; Never Native Compile
.alias UF 16 ; Includes Underflow Check (RESERVED)
.alias HC 32 ; Word has Code Field Area (CFA)


; VARIOUS

.alias MAX_LINE_LENGTH  79      ; assumes 80 character lines

; END
