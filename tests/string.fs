\ ------------------------------------------------------------------------
testing string words: /string -trailing blank sliteral
decimal

marker string_tests


\ Note the sequence of tests is fixed by https://forth-standard.org/standard/testsuite

T{ : s1 s" abcdefghijklmnopqrstuvwxyz" ; -> }T
 
T{ s1  5 /string -> s1 swap 5 + swap 5 - }T
T{ s1 10 /string -4 /string -> s1 6 /string }T
T{ s1  0 /string -> s1 }T

T{ : s2 s" abc"   ; -> }T
T{ : s3 s" jklmn" ; -> }T
T{ : s4 s" z"     ; -> }T
T{ : s5 s" mnoq"  ; -> }T
T{ : s6 s" 12345" ; -> }T
T{ : s7 s" "      ; -> }T

T{ s1 s2 search -> s1 -1 ( <true> )  }T  
T{ s1 s3 search -> s1  9 /string -1 ( <true> )  }T
T{ s1 s4 search -> s1 25 /string -1 ( <true> ) }T
T{ s1 s5 search -> s1 0 ( <false> ) }T
T{ s1 s6 search -> s1 0 ( <false> ) }T
T{ s1 s7 search -> s1 -1 ( <true> ) }T 

T{ :  s8 s" abc  " ; -> }T
T{ :  s9 s"      " ; -> }T
T{ : s10 s"    a " ; -> }T

T{  s1 -trailing -> s1 }T        \ "abcdefghijklmnopqrstuvwxyz"
T{  s8 -trailing -> s8 2 - }T    \ "abc "
T{  s7 -trailing -> s7 }T        \ " "
T{  s9 -trailing -> s9 drop 0 }T \ " "
T{ s10 -trailing -> s10 1- }T    \ " a "

T{ s1        s1 compare ->  0  }T
T{ s1  pad swap cmove   ->     }T    \ copy s1 to PAD
T{ s1  pad over compare ->  0  }T
T{ s1     pad 6 compare ->  1  }T
T{ pad 10    s1 compare -> -1  }T
T{ s1     pad 0 compare ->  1  }T
T{ pad  0    s1 compare -> -1  }T
T{ s1        s6 compare ->  1  }T
T{ s6        s1 compare -> -1  }T

: "abdde" s" abdde" ;
: "abbde" s" abbde" ;
: "abcdf" s" abcdf" ;
: "abcdee" s" abcdee" ;

T{ s1 "abdde"  compare -> -1 }T
T{ s1 "abbde"  compare ->  1 }T
T{ s1 "abcdf"  compare -> -1 }T
T{ s1 "abcdee" compare ->  1 }T

: s11 s" 0abc" ;
: s12 s" 0aBc" ;

T{ s11 s12 compare ->  1 }T
T{ s12 s11 compare -> -1 }T

: s13 s" aaaaa      a" ;       \ six spaces

T{ pad 25 char a fill -> }T      \ fill PAD with 25 'a's
T{ pad 5 chars + 6 blank -> }T   \ put 6 spaced from character 5
T{ pad 12 s13 compare -> 0 }T    \ PAD should now be same as s13 TODO

( CMOVE and CMOVE> are kept together with MOVE )

T{ : s14 [ s1 ] sliteral ; -> }T 
T{ s1 s14 compare -> 0 }T
T{ s1 s14 rot = rot rot = -> -1 ( <true> ) 0 ( <false> ) }T

( TODO REPLACES not implemented yet )
( TODO SUBSTITUTE not implemented yet )
( TODO UNESCAPE not implemented yet )


\ Tests for long strings
\ ------------------------------------------------------------------------
testing long strings

\ These are Tali-specific tests, the ANSI test suite has nothing like this.

\ Test strings longer than 255 chars (important for 8-bit systems)
\ 516 character string
: s14 s" test                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                " ;
T{ s14 swap drop -> 516 }T
T{ s14 -trailing -> s14 drop 4 }T

: s15 ." abcdefghijklmnopqrstuvwxyz1abcdefghijklmnopqrstuvwxyz2abcdefghijklmnopqrstuvwxyz3abcdefghijklmnopqrstuvwxyz4abcdefghijklmnopqrstuvwxyz5abcdefghijklmnopqrstuvwxyz6abcdefghijklmnopqrstuvwxyz7abcdefghijklmnopqrstuvwxyz8abcdefghijklmnopqrstuvwxyz9abcdefghijklmnopqrstuvwxyz10abcdefghijklmnopqrstuvwxyz11abcdefghijklmnopqrstuvwxyz12abcdefghijklmnopqrstuvwxyz13abcdefghijklmnopqrstuvwxyz14abcdefghijklmnopqrstuvwxyz15abcdefghijklmnopqrstuvwxyz16abcdefghijklmnopqrstuvwxyz17abcdefghijklmnopqrstuvwxyz18abcdefghijklmnopqrstuvwxyz19abcdefghijklmnopqrstuvwxyz20" ;
\ This should output the alphabet 20 times.
T{ s15 -> }T

\ Free memory used for these tests
string_tests

