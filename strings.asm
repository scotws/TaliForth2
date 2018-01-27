; List of Strings for Tali Forth 2
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (for Liara Forth)
; This version: 27. Jan 2017

; This file is included by taliforth.asm 

; STRING TABLE
; Since we can't fit a 16-bit address in a register as with Liara Forth,
; we use indexes as offsets to tables as error and string numbers
string_table:
        .word s_ok, s_compiled, vt100_page, vt100_home, s_abc_lower ; 0-4
        .word s_abc_upper                                           ; 5

; GENERAL
; All general strings must be zero-terminated, names start with "s_"
s_ok:        .byte " ok", 0             ; note space at beginning
s_compiled:  .byte " compiled", 0


; ANSI VT-100 SEQUENCES
vt100_page: .byte 27, "[2J", 0       ; clear screen
vt100_home: .byte 27, "[H", 0        ; cursor home


; ALPHABET STRINGS
; Leave alphastr as the last entry in the source code to make it easier to
; see where this section ends. This may be a zero-terminated string
; TODO see if we need these at all
s_abc_lower: .byte "0123456789abcdefghijklmnopqrstuvwyz"
s_abc_upper: .byte "0123456789ABCDEFGHIJKLMNOPQRSTUVWYZ"


; ERROR STRINGS
; All error strings must be zero-terminated, names start with "es_"

error_table:
        .word es_allot, es_componly, es_defer, es_divzero, es_error   ;  0-4
        .word es_intonly, es_noname, es_radix, es_refill1, es_refill2 ;  5-9
        .word es_state, es_underflow, es_syntax                       ; 10-12

es_allot:     .byte "ALLOT using all available memory", 0 
es_componly:  .byte "Interpreting a compile-only word", 0
es_defer:     .byte "DEFERed word not defined yet", 0
es_divzero:   .byte "Division by zero", 0
es_error:     .byte ">>>Error<<<", 0
es_intonly:   .byte "Not in interpret mode", 0
es_noname:    .byte "Parsing failure", 0
es_radix:     .byte "Digit larger than base", 0
es_refill1:   .byte "QUIT could not get input (REFILL returned -1)", 0
es_refill2:   .byte "Illegal SOURCE-ID during REFILL", 0
es_state:     .byte "Already in compile mode", 0
es_underflow: .byte "Stack underflow", 0
es_syntax:    .byte "Undefined word", 0



