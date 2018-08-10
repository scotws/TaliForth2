; List of Strings for Tali Forth 2
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (for Liara Forth)
; This version: 10. Aug 2018

; This file is included by taliforth.asm 

; STRING TABLE
; Since we can't fit a 16-bit address in a register, we use indexes as offsets
; to tables as error and string numbers. Unused entries are filled with 0000
; TODO convert this setup to the way that error strings are handled
string_table:
        .word s_ok, s_compiled, s_redefined, 0000, s_abc_lower ; 0-4
        .word s_abc_upper                                      ; 5

; GENERAL
; All general strings must be zero-terminated, names start with "s_"
s_ok:           .byte " ok", 0          ; note space at beginning
s_compiled:     .byte " compiled", 0    ; note space at beginning
s_redefined:    .byte "redefined ", 0   ; note space at end


; ALPHABET STRINGS
s_abc_lower: .byte "0123456789abcdefghijklmnopqrstuvwxyz"
s_abc_upper: .byte "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"


; ERROR STRINGS
; All error strings must be zero-terminated, all names start with "es_".
; If the string texts are changed, the test suite must be as well 

.alias err_allot 	   0
.alias err_badsource   	   1
.alias err_compileonly     2
.alias err_defer 	   3
.alias err_divzero 	   4
.alias err_noname      	   5
.alias err_refill  	   6
.alias err_state 	   7
.alias err_syntax 	   8
.alias err_underflow 	   9

error_table:
        .word es_allot, es_badsource, es_compileonly, es_defer  ;  0-3
        .word es_divzero, es_noname, es_refill, es_state        ;  4-7
        .word es_syntax, es_underflow                           ;  8-11

es_allot:        .byte "ALLOT using all available memory", 0 
es_badsource:    .byte "Illegal SOURCE-ID during REFILL", 0
es_compileonly:  .byte "Interpreting a compile-only word", 0
es_defer:        .byte "DEFERed word not defined yet", 0
es_divzero:      .byte "Division by zero", 0
es_noname:       .byte "Parsing failure", 0
es_refill:       .byte "QUIT could not get input (REFILL returned -1)", 0
es_state:        .byte "Already in compile mode", 0
es_syntax:       .byte "Undefined word", 0
es_underflow:    .byte "Stack underflow", 0
