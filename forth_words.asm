; High-level Forth word routines
; Tali Forth 2 for the 65c02
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 07. Feb 2018

; These words are too complicated (at the moment) or would be too long
; to be included as assembler code. So at startup, we have the basic
; Forth system add them to the Dictionary the hard way. This increases
; start-up time but makes it easier to work with the code. Also, these
; function as built-in systems tests.

; The following strings should not be zero-terminated and do not need
; CR/LF at the end. They do, however, require a space at the end.

high_level_start:
        ; Output and comment. Because it still blows my mind that we can
        ; define this stuff this simply 
        .byte ": ( [char] ) parse 2drop ; immediate "
        .byte ": .( [char] ) parse type ; immediate "

        ; Flow control. Some of these could be realized with CS-ROLL and
        ; CS-PICK instead, which seems to be all the rage these days.
;       .byte ": if postpone 0branch here 0 , ; immediate compile-only "
;       .byte ": then here swap ! ; immediate compile-only "
;       .byte ": else postpone branch here 0 , here rot ! ; immediate compile-only "
;       .byte ": repeat postpone again here swap ! ; immediate compile-only "
;       .byte ": until postpone 0branch , ; immediate compile-only "
;       .byte ": while postpone 0branch here 0 , swap ; immediate compile-only "

        ; DEFER and friends. Code taken from ANSI Forth specification. Many of
        ; these will be moved to assembler code in due course
;       .byte ": defer! >body ! ; "
;       .byte ": defer@ >body @ ; "
;       .byte ": is state @ if postpone ['] postpone defer! else ' defer! then ; immediate "
;       .byte ": action-of state @ if postpone ['] postpone defer@ else ' defer@ then ; immediate "

        ; High level math definitions. The should be moved to actual 65c02 code
        ; for speed at some point. Note we use SM/REM instead of FM/MOD for most
        ; stuff
;       .byte ": / >r s>d r> sm/rem swap drop ; "
;       .byte ": /mod >r s>d r> sm/rem ; "
;       .byte ": mod /mod drop ; "
;       .byte ": */ >r m* r> sm/rem swap drop ; "
;       .byte ": */mod >r m* r> sm/rem ; "

        ; Output definitions. Since these usually involve the user, and humans
        ; are slow, these can stay high-level for the moment. Based on
        ; https://github.com/philburk/pforth/blob/master/fth/numberio.fth
        ; . (DOT) and U. are hard-coded because there are used by other words
;       .byte ": u.r >r 0 <# #s #> r> over - spaces type ; "
;       .byte ": .r >r dup abs 0 <# #s rot sign #> r> over - spaces type ; "
;       .byte ": ud. <# #s #> type space ; "
;       .byte ": ud.r >r <# #s #> r> over - spaces type ; "
;       .byte ": d. tuck dabs <# #s rot sign #> type space ; "
;       .byte ": d.r >r tuck dabs <# #s rot sign #> r> over - spaces type ; "

        ; Temporary high-level words. Convert these to assembler.
;       .byte ": within ( n1 n2 n3 -- f ) rot tuck > -rot > invert and ; "

        ; DUMP. A longish word we'll want to modify for a while until we are
        ; happy with the format
;       .byte ": dump ( addr u -- ) bounds ?do cr i 4 u.r space "
;       .byte "16 0 do i j + c@ 0 <# # #s #> type space loop 16 +loop ; "   

        ; SEE. A longish word we'll want to modify for a while until we are
        ; happy with the format. Then replace it by code because this is just
        ; far too long.
;       .byte ": see parse-name find-name dup 0= abort", 34, " No such name", 34, " "
;       .byte "base @ >r  hex  dup cr space .", 34, " nt: ", 34, " . "
;       .byte "dup 4 + @ space .", 34, " xt: ", 34, " . "
;       .byte "dup 1+ c@ 1 and if space .", 34, " CO", 34, " then "
;       .byte "dup 1+ c@ 2 and if space .", 34, " AN", 34, " then "
;       .byte "dup 1+ c@ 4 and if space .", 34, " IM", 34, " then "
;       .byte "dup 1+ c@ 8 and if space .", 34, " NN", 34, " then "
;       .byte "dup cr space .", 34, " size (decimal): ", 34, " decimal wordsize dup . "
;       .byte "swap name>int swap hex cr space dump  r> base ! ; "

        ; Splash strings. We leave these as high-level words because they are
        ; generated at the end of the boot process and signal that the other
        ; high-level definitions worked (or at least didn't crash)
        .byte ".( Tali Forth 2 for the 65c02) "
        .byte "cr .( Version PRE-ALPHA 10. Feb 2018) "
        .byte "cr .( Scot W. Stevenson <scot.stevenson@gmail.com>) "
        .byte "cr .( Tali Forth 2 comes with absolutely NO WARRANTY) "
        .byte "cr .( Type 'bye' to exit) cr"

high_level_end:

; END
