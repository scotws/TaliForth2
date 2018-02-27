; Reserved space for user defined Forth words 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 29. Nov 2017
; This version: 26. Feb 2018

; This file is included as a space for the user to include 
; high-level Forth words of their own. The format is the same
; as forth_words.asm - add an extra space in the strings.

; Note that these programs are not necessarily in the public domain,
; see the original sources for details

user_words_start:
        ; SEE gives us information on a Forth word. At some point, this
        ; can be added to the native words to save on size
        .byte ": see parse-name find-name dup 0= abort\" No such name\" "
        .byte "base @ >r  hex  dup cr space .\"  nt: \" u. "
        .byte "dup 4 + @ space .\" xt: \" u. "
        .byte "dup 1+ c@ 1 and if space .\" CO\" then "
        .byte "dup 1+ c@ 2 and if space .\" AN\" then "
        .byte "dup 1+ c@ 4 and if space .\" IM\" then "
        .byte "dup 1+ c@ 8 and if space .\" NN\" then "
        .byte "dup cr space .\" size (decimal): \" decimal wordsize dup . "
        .byte "swap name>int swap hex cr space dump  r> base ! ; "

	; -------------------------------------------------------
        ; WORDS&SIZES prints all known words and the sizes of their codes
        ; in bytes. It can be used to test the effects of different native
        ; compile parameters. When not testing, leave it commented out.
        ; .byte ": words&sizes  latestnt begin dup 0<> while dup name>string "
        ; .byte "type space  dup wordsize u. cr  2 + @ repeat drop ; "

	; -------------------------------------------------------
        ; FIBONACCI from
        ; https://atariwiki.org/wiki/Wiki.jsp?page=Forth%20Benchmark
        ; See also http://cubbi.com/fibonacci/forth.html
        ; TODO replace by a version that prints them one-by-one
        ; .byte ": fib  ( n1 -- n2 ) "
        ; .byte "         dup 2 < if drop 1 exit then "
        ; .byte "         dup 1- recurse "
        ; .byte "         swap 2 - recurse + ; "
        
	; -------------------------------------------------------
        ; FACTORIAL from 
        ; https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Recursion-Tutorial.html
        ; .byte ": fact ( n -- n! ) "
        ; .byte " dup 0> if 
        ; .byte "    dup 1- recurse * else "
        ; .byte "    drop 1 then ; "

	; -------------------------------------------------------
        ; PRIMES from 
        ; https://www.youtube.com/watch?v=V5VGuNTrDL8 (Forth Freak)
        ; .byte " : primes ( n -- ) "
        ; .byte "     2 . 3 .  "
        ; .byte "     2 swap 5 do   "
        ; .byte "          dup dup * i < if 1+ then "
        ; .byte "           1 over 1+ 3 do  "
        ; .byte "                 j i mod 0= if 1- leave then "
        ; .byte "           2 +loop "
        ; .byte "           if i . then "
        ; .byte "     2 +loop "
        ; .byte "   drop ; "
        
	; -------------------------------------------------------
        ; MANDELBROT by Martin Heermance
        ; https://github.com/Martin-H1/Forth-CS-101/blob/master/mandelbrot.fs
        ; http://forum.6502.org/viewtopic.php?f=9&t=3706
        ; https://www.youtube.com/watch?v=fVa3Fx7dwBM
        ; .byte " ( setup constants to remove magic numbers to allow) "
        ; .byte " ( for greater zoom with different scale factors) "
        ; .byte " 20 constant maxiter "
        ; .byte "-39 constant minval "
        ; .byte " 40 constant maxval "
        ; .byte " 20 5 lshift constant rescale "
        ; .byte "rescale 4 * constant s_escape "
        ; .byte " "
        ; .byte "( these variables hold values during the escape calculation ) "
        ; .byte "variable creal "
        ; .byte "variable cimag "
        ; .byte "variable zreal "
        ; .byte "variable zimag "
        ; .byte "variable count "
        ; .byte " "
        ; .byte "( compute squares, but rescale to remove extra scaling factor) "
        ; .byte ": zr_sq zreal @ dup rescale */ ; "
        ; .byte ": zi_sq zimag @ dup rescale */ ; "
        ; .byte " "
        ; .byte "( translate escape count to ascii greyscale )"
        ; .byte ": .char "
        ; .byte "         s\" ..,'~!^:;[/<&?oxox#  \" "
        ; .byte "         drop + 1 "
        ; .byte "         type ; "
        ; .byte " "
        ; .byte "( numbers above 4 will always escape, so compare to a scaled value) "
        ; .byte ": escapes? s_escape > ; "
        ; .byte " "
        ; .byte "( increment count and compare to max iterations) "
        ; .byte ": count_and_test? "
        ; .byte "         count @ 1+ dup count ! "
        ; .byte "         maxiter > ; "
        ; .byte " "
        ; .byte "( stores the row column values from the stack for the escape calculation) "
        ; .byte ": init_vars "
        ; .byte "         5 lshift dup creal ! zreal ! "
        ; .byte "         5 lshift dup cimag ! zimag ! "
        ; .byte "         1 count ! ; "
        ; .byte " "
        ; .byte "( performs a single iteration of the escape calculation) "
        ; .byte ": doescape "
        ; .byte "         zr_sq zi_sq 2dup + "
        ; .byte "         escapes? if "
        ; .byte "         2drop "
        ; .byte "         true "
        ; .byte "         else "
        ; .byte "         - creal @ +   ( leave result on stack ) "
        ; .byte "         zreal @ zimag @ rescale */ 1 lshift "
        ; .byte "         cimag @ + zimag ! "
        ; .byte "         zreal !                   ( store stack item into zreal ) "
        ; .byte "         count_and_test? "
        ; .byte "         then ; "
        ; .byte " "
        ; .byte "( iterates on a single cell to compute its escape factor) "
        ; .byte ": docell "
        ; .byte "         init_vars "
        ; .byte "         begin "
        ; .byte "         doescape "
        ; .byte "         until "
        ; .byte "         count @ "
        ; .byte "         .char ; "
        ; .byte " "
        ; .byte "( for each cell in a row) "
        ; .byte ": dorow "
        ; .byte "         maxval minval do "
        ; .byte "         dup i "
        ; .byte "         docell "
        ; .byte "         loop "
        ; .byte "         drop ; "
        ; .byte " "
        ; .byte "( for each row in the set) "
        ; .byte ": mandelbrot "
        ; .byte "         cr "
        ; .byte "         maxval minval do "
        ; .byte "         i dorow cr "
        ; .byte "         loop ; "
        
        user_words_end:

; END 
