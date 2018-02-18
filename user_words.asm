; Reserved space for user defined Forth words 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 29. Nov 2017
; This version: 18. Feb 2018

; This file is included as a space for the user to include 
; high-level Forth words of their own. The format is the same
; as forth_words.asm - add an extra space in the strings.

user_words_start:
        ; WORDS&SIZES prints all known words and the sizes of their codes
        ; in bytes. It can be used to test the effects of different native
        ; compile parameters. When not testing, leave it commented out.
        ; .byte ": words&sizes  latestnt begin dup 0<> while dup name>string "
        ; .byte "type space  dup wordsize u. cr  2 + @ repeat drop ; "
user_words_end:

; END 
