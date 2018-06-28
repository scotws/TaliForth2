; List of Strings for Tali Forth 2
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (for Liara Forth)
; This version: 29. Jun 2018

; This file is included by taliforth.asm 

; STRING TABLE
; Since we can't fit a 16-bit address in a register, we use indexes as offsets
; to tables as error and string numbers. Unused entries are filled with 0000
string_table:
        .word s_ok, s_compiled, 0000, 0000, s_abc_lower ; 0-4
        .word s_abc_upper                               ; 5

; GENERAL
; All general strings must be zero-terminated, names start with "s_"
s_ok:           .byte " ok", 0          ; note space at beginning
s_compiled:     .byte " compiled", 0    ; note space at beginning


; ALPHABET STRINGS
s_abc_lower: .byte "0123456789abcdefghijklmnopqrstuvwxyz"
s_abc_upper: .byte "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"


; ERROR STRINGS
; All error strings must be zero-terminated, all names start with "es_".
; If these strings are changed, the test suite must be  
; TODO renumber once we have all errors figured out

.alias err_allot 	0
.alias err_compileonly  1
.alias err_defer 	2
.alias err_divzero 	3
; .alias UNUSED		4
.alias err_intonly 	5	; TODO CHECK IF UNUSED
.alias err_noname      	6
.alias err_radix 	7	; TODO CHECK IF UNUSED
.alias err_refill  	8
.alias err_badsource   	9
.alias err_state 	10
.alias err_underflow 	11
.alias err_syntax 	12
.alias err_noxt 	13
.alias err_out_of_range 14
.alias err_no_such_name 15

error_table:
        .word es_allot, es_componly, es_defer, es_divzero, 0000         ;  0-4
        .word es_intonly, es_noname, es_radix, es_refill, es_badsource ;  5-9
        .word es_state, es_underflow, es_syntax, es_noxt                ; 10-13

es_allot:      .byte "ALLOT using all available memory", 0 
es_badsource:  .byte "Illegal SOURCE-ID during REFILL", 0
es_componly:   .byte "Interpreting a compile-only word", 0
es_defer:      .byte "DEFERed word not defined yet", 0
es_divzero:    .byte "Division by zero", 0
es_intonly:    .byte "Not in interpret mode", 0
es_noname:     .byte "Parsing failure", 0
es_noxt:       .byte "No such xt found in Dictionary", 0
es_radix:      .byte "Digit larger than base", 0
es_refill:     .byte "QUIT could not get input (REFILL returned -1)", 0
es_state:      .byte "Already in compile mode", 0
es_syntax:     .byte "Undefined word", 0
es_underflow:  .byte "Stack underflow", 0
