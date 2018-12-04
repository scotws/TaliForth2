; List of Strings for Tali Forth 2
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (for Liara Forth)
; This version: 10. Oct 2018

; This file is included by taliforth.asm 

; ## GENERAL STRINGS
; All general strings must be zero-terminated, names start with "s_", 
; aliases with "str_"

.alias str_ok           0
.alias str_compile      1
.alias str_redefined    2
; .alias UNUSED         3
.alias str_abc_lower    4
.alias str_abc_upper    5

; Since we can't fit a 16-bit address in a register, we use indexes as offsets
; to tables as error and string numbers. Unused entries are filled with 0000
string_table:
        .word s_ok, s_compiled, s_redefined, 0000, s_abc_lower ; 0-4
        .word s_abc_upper                                      ; 5

s_ok:           .byte " ok", 0          ; note space at beginning
s_compiled:     .byte " compiled", 0    ; note space at beginning
s_redefined:    .byte "redefined ", 0   ; note space at end

s_abc_lower: .byte "0123456789abcdefghijklmnopqrstuvwxyz"
s_abc_upper: .byte "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"


; ## ERROR STRINGS
; All error strings must be zero-terminated, all names start with "es_",
; aliases with "err_" 
; NOTE: If the string texts are changed, the test suite must be as well 

.alias err_allot           0
.alias err_badsource       1
.alias err_compileonly     2
.alias err_defer           3
.alias err_divzero         4
.alias err_noname          5
.alias err_refill          6
.alias err_state           7
.alias err_syntax          8
.alias err_underflow       9
.alias err_negallot        10
.alias err_wordlist        11                

error_table:
        .word es_allot, es_badsource, es_compileonly, es_defer  ;  0-3
        .word es_divzero, es_noname, es_refill, es_state        ;  4-7
        .word es_syntax, es_underflow, es_negallot, es_wordlist ;  8-11

es_allot:       .byte "ALLOT using all available memory", 0 
es_badsource:   .byte "Illegal SOURCE-ID during REFILL", 0
es_compileonly: .byte "Interpreting a compile-only word", 0
es_defer:       .byte "DEFERed word not defined yet", 0
es_divzero:     .byte "Division by zero", 0
es_noname:      .byte "Parsing failure", 0
es_refill:      .byte "QUIT could not get input (REFILL returned -1)", 0
es_state:       .byte "Already in compile mode", 0
es_syntax:      .byte "Undefined word", 0
es_underflow:   .byte "Stack underflow", 0
es_negallot:    .byte "Max memory freed with ALLOT", 0
es_wordlist:    .byte "No wordlists available", 0

; ## ENVIRONMENT STRINGS

; These are used by the ENVIRONMENT? word and stored in the old string
; format: Length byte first, then the string itself that is not rpt. not
; zero-terminated. Note these are uppercase by ANS defintion.
; All start with "envs_". 

; These return a single-cell number
envs_cs:        .byte 15, "/COUNTED-STRING"
envs_hold:      .byte 5, "/HOLD"
envs_pad:       .byte 4, "/PAD"
envs_aub:       .byte 17, "ADDRESS-UNIT-BITS"
envs_floored:   .byte 7, "FLOORED"
envs_max_char:  .byte 8, "MAX-CHAR"
envs_max_n:     .byte 5, "MAX-N"
envs_max_u:     .byte 5, "MAX-U"
envs_rsc:       .byte 18, "RETURN-STACK-CELLS"
envs_sc:        .byte 11, "STACK-CELLS"
envs_wl:        .byte 9, "WORDLISTS"
; These return a double-cell number
envs_max_d:     .byte 5, "MAX-D"
envs_max_ud:    .byte 6, "MAX-UD"
