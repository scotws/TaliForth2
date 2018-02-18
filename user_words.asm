; Reserved space for user defined Forth words 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 29. Nov 2017
; This version: 18. Feb 2018

; This file is included as a space for the user to include 
; high-level Forth words of their own. The format is the same
; as forth_words.asm - add an extra space in the strings.

user_words_start:
        .byte ".( No user words defined ) cr "
user_words_end:

; END 
