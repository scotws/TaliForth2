; High-level Forth word routines
; Tali Forth 2 for the 65c02
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 01. Apr 2016 (Liara Forth)
; This version: 26. Feb 2018

; These words are too complicated (at the moment) or would be too long
; to be included as assembler code. So at startup, we have the basic
; Forth system add them to the Dictionary the hard way. This increases
; start-up time but makes it easier to work with the code. Also, these
; do double-duty as built-in systems tests: If you see the boot strings
; defined at the end, the basic structure is up and running.

; The following strings should not be zero-terminated and do not need
; CR/LF at the end. They do, however, require a trailing space.

high_level_start:
        ; Output and comment. Because it still blows my mind that we can
        ; define this stuff this simply 
        .byte ": ( [char] ) parse 2drop ; immediate "
        .byte ": .( [char] ) parse type ; immediate "

        ; Flow control. Some of these could be realized with CS-ROLL and
        ; CS-PICK instead, which seems to be all the rage these days.
        .byte ": if postpone 0branch here 0 , ; immediate compile-only "
        .byte ": then here swap ! ; immediate compile-only "
        .byte ": else postpone branch here 0 , here rot ! ; immediate compile-only "
        .byte ": repeat postpone again here swap ! ; immediate compile-only "
        .byte ": until postpone 0branch , ; immediate compile-only "
        .byte ": while postpone 0branch here 0 , swap ; immediate compile-only "

        ; DEFER and friends. Code taken from ANSI Forth specification. Some of
        ; these will be moved to assembler code in due course
        .byte ": defer! >body ! ; "
        .byte ": defer@ >body @ ; "
        .byte ": is state @ if postpone ['] postpone defer! else ' defer! then ; immediate "
        .byte ": action-of state @ if postpone ['] postpone defer@ else ' defer@ then ; immediate "

        ; High level math definitions. The should be moved to actual 65c02 code
        ; for speed at some point. Note we use SM/REM instead of FM/MOD for most
        ; stuff
        .byte ": / >r s>d r> sm/rem swap drop ; "
        .byte ": /mod >r s>d r> sm/rem ; "
        .byte ": mod /mod drop ; "
        .byte ": */ >r m* r> sm/rem swap drop ; "
        .byte ": */mod >r m* r> sm/rem ; "

        ; Output definitions. Since these usually involve the user, and humans
        ; are slow, these can stay high-level for the moment. However, in this
        ; state they don't check for underflow. Based on
        ; https://github.com/philburk/pforth/blob/master/fth/numberio.fth
        .byte ": u. 0 <# #s #> type space ; "
        .byte ": u.r >r 0 <# #s #> r> over - spaces type ; "
        .byte ": .r >r dup abs 0 <# #s rot sign #> r> over - spaces type ; "
        .byte ": ud. <# #s #> type space ; "
        .byte ": ud.r >r <# #s #> r> over - spaces type ; "
        .byte ": d. tuck dabs <# #s rot sign #> type space ; "
        .byte ": d.r >r tuck dabs <# #s rot sign #> r> over - spaces type ; "

        ; Temporary high-level words. TODO convert these to assembler
        .byte ": to ( n -- 'name') ' >body ! ; "
        .byte ": within ( n1 n2 n3 -- f ) rot tuck > -rot > invert and ; "
        .byte ": /string ( addr u n -- addr u ) rot over + rot rot - ; "

        ; Splash strings. We leave these as high-level words because they are
        ; generated at the end of the boot process and signal that the other
        ; high-level definitions worked (or at least didn't crash)
        .byte ".( Tali Forth 2 for the 65c02) "
        .byte "cr .( Version ALPHA 26. Feb 2018) "
        .byte "cr .( Copyright 2014-2018 Scot W. Stevenson) "
        .byte "cr .( Tali Forth 2 comes with absolutely NO WARRANTY) "
        .byte "cr .( Type 'bye' to exit) cr "

high_level_end:

; END
