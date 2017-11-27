; Definitions for Tali Forth 2
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 27. Nov 2017

; This file is included by taliforth.asm

; I/O facilities are handled in the separate kernel files because of their
; hardware dependencies. See docs/memorymap.txt for a discussion of Tali's
; memory layout.


; MEMORY MAP OF RAM

; Drawing is not only very ugly, but also not to scale. See docs/memorymap.txt
; for the complete memory map


;    $0000  +-------------------+  ram_start, zpage, user0
;           |  User varliables  |
;           +-------------------+  
;           |                   |
;           |                   |
;           +~~~~~~~~~~~~~~~~~~~+  <-- dsp
;           |                   |
;           |  ^  Data Stack    |  
;           |  |                |
;    $0078  +-------------------+  dsp0, stack
;           |                   |
;           |   (Reserved for   |
;           |      kernel)      |
;           |                   |
;    $0100  +-------------------+  
;           |                   |
;           |  ^  Return Stack  |  <-- rsp 
;           |  |                |
;    $0200  +-------------------+  rsp0, buffer, buffer0
;           |  |                |
;           |  v  Input Buffer  |
;           |                   |
;    $0280  +-------------------+ buffer1
;           |                   |
;           |  (unused buffer)  |
;           |                   |
;    $0300  +-------------------+  cp0
;           |  |                |
;           |  v  Dictionary    |
;           |       (RAM)       |
;           |                   |
;   (...)   ~~~~~~~~~~~~~~~~~~~~~  <-- cp
;           |                   |
;           |                   |
;    $7fff  +-------------------+  ram_end, code0-1


; HARD PHYSICAL ADDRESSES

; Some of these are somewhat silly for the 65c02, where for example
; the location of the Zero Page is fixed by hardware. However, we keep
; these for easier comparisons with Liara Forth's structure and to 
; help people new to these things. Note that on Liara Forth, some of 
; these are soft addresses, not hard addresses

.alias ram_start $0000       ; start of installed 32 KiB of RAM
.alias ram_end   $8000-1     ; end of installed RAM
.alias zpage     ram_start   ; begin of Zero Page ($0000-$00ff)
.alias stack     $0100       ; begin of Return Stack ($0100-$01ff)


; SOFT PHYSICAL ADDRESSES

; Tali currently doesn't have separate user variables for multitasking. To
; prepare for this, though, we've already named the location of the user
; variables user0. The two buffers are reserved for futher use, at the moment
; buffer0 is used for input and buffer1 for temporary use during the WORD
; word (TODO check this)

.alias user0     zpage          ; user and system variables
.alias dsp0      $78            ; initial Data Stack Pointer, see docs/stack.md
.alias rsp0      $ff            ; initial Return Stack Pointer (65c02 stack)
.alias bsize     $80            ; size of input/output buffers
.alias buffer0   stack+$100     ; input buffer ($0200-$027f)
.alias buffer1   buffer0+bsize  ; temporary buffer area ($0280-$02ff)
.alias cp0       buffer1+bsize  ; Dictionary starts after last buffer
.alias cp_end    code0-1        ; Last RAM byte available
.alias padoffset $ff            ; offset from CP to PAD (holds number strings)


; ZERO PAGE ADDRESSES/VARIABLES

; These are as close to the definitions in Liara Forth as possible.
; They are kept at the top of Zero Page, with the most important variables
; at the top because the Data Stack grows towards this area from dsp0: If
; there is an overflow, the lower, less important variables will be
; clobbered first, giving the system a chance to recover. In other words,
; they are part of the floodplain.

.alias cp        user0+0  ; Compiler Pointer
.alias dp        user0+2  ; Dictionary Pointer
.alias workword  user0+4  ; nt (not xt!) of word being compiled
.alias insrc     user0+6  ; input Source for SOURCE-ID
.alias cib       user0+8  ; address of current input buffer
.alias ciblen    user0+10  ; length of current input buffer
.alias toin      user0+12  ; pointer to CIB (>IN in Forth)
.alias output    user0+14  ; vector for EMIT
.alias input     user0+16  ; vector for KEY
.alias havekey   user0+18  ; vector for KEY?
.alias state     user0+20  ; STATE: -1 compile, 0 interpret
.alias base      user0+22  ; radix for number conversion, default 10
.alias nc_limit  user0+24  ; limit for Native Compile size
.alias tmpbranch user0+26  ; temp storage for 0BRANCH, BRANCH only
.alias tmp1      user0+28  ; temporary storage
.alias tmp2      user0+30  ; temporary storage
.alias tmp3      user0+32  ; temporary storage
.alias tmpdsp    user0+34  ; temporary DSP (X) storage
.alias tmptos    user0+36  ; temporary TOS storage
.alias tohold    user0+38  ; pointer for formatted output 
.alias scratch   user0+40  ; 8 byte scratchpad (see UM/MOD)


; ASCII CHARACTERS

.alias AscCC   $03  ; break (CNTR-c)
.alias AscBELL $07  ; bell sound
.alias AscBS   $08  ; backspace 
.alias AscLF   $0a  ; line feed
.alias AscCR   $0d  ; carriage return
.alias AscCN   $0e  ; CNTR-n (for "next command" in CLI)
.alias AscCP   $10  ; CNTR-p (for "previous command" in CLI)
.alias AscESC  $1b  ; escape
.alias AscSP   $20  ; space
.alias AscDEL  $7f  ; delete


; DICTIONARY FLAGS

; The first four bits are currently unused

.alias CO 1  ; Compile Only
.alias AN 2  ; Always Native Compile
.alias IM 4  ; Immediate Word
.alias NN 8  ; Never Native Compile

; END
