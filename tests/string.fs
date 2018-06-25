\ ------------------------------------------------------------------------
testing string words: /string -trailing blank sliteral
decimal

\ Note the sequence of tests is fixed by https://forth-standard.org/standard/testsuite

{ : s1 s" abcdefghijklmnopqrstuvwxyz" ; -> }
 
{ s1  5 /string -> s1 swap 5 + swap 5 - }
{ s1 10 /string -4 /string -> s1 6 /string }
{ s1  0 /string -> s1 }

{ : s2 s" abc"   ; -> }
{ : s3 s" jklmn" ; -> }
{ : s4 s" z"     ; -> }
{ : s5 s" mnoq"  ; -> }
{ : s6 s" 12345" ; -> }
{ : s7 s" "      ; -> }

( TODO SEARCH not implemented )
\ { s1 s2 search -> s1 <true>  }  
\ { s1 s3 search -> s1  9 /string <true>  }
\ { s1 s4 search -> s1 25 /string <true>  }
\ { s1 s5 search -> s1 <false> }
\ { s1 s6 search -> s1 <false> }
\ { s1 s7 search -> s1 <true>  } 

{ :  s8 s" abc  " ; -> }
{ :  s9 s"      " ; -> }
{ : s10 s"    a " ; -> }

{  s1 -trailing -> s1 }        \ "abcdefghijklmnopqrstuvwxyz"
{  s8 -trailing -> s8 2 - }    \ "abc "
{  s7 -trailing -> s7 }        \ " "
{  s9 -trailing -> s9 drop 0 } \ " "
{ s10 -trailing -> s10 1- }    \ " a "

( TODO COMPARE not implemented )
\ { s1        s1 compare ->  0  }
\ { s1  pad swap cmove   ->     }    \ copy s1 to PAD
\ { s1  pad over compare ->  0  }
\ { s1     pad 6 compare ->  1  }
\ { pad 10    s1 compare -> -1  }
\ { s1     pad 0 compare ->  1  }
\ { pad  0    s1 compare -> -1  }
\ { s1        s6 compare ->  1  }
\ { s6        s1 compare -> -1  }

\ : "abdde" s" abdde" ;
\ : "abbde" s" abbde" ;
\ : "abcdf" s" abcdf" ;
\ : "abcdee" s" abcdee" ;

\ { s1 "abdde"  compare -> -1 }
\ { s1 "abbde"  compare ->  1 }
\ { s1 "abcdf"  compare -> -1 }
\ { s1 "abcdee" compare ->  1 }

: s11 s" 0abc" ;
: s12 s" 0aBc" ;

\ { s11 s12 compare ->  1 }
\ { s12 s11 compare -> -1 }

: s13 s" aaaaa a" ;            \ six spaces

{ pad 25 char a fill -> }      \ fill PAD with 25 'a's
{ pad 5 chars + 6 blank -> }   \ put 6 spaced from character 5
\ { pad 12 s13 compare -> 0 }    \ PAD should now be same as s13 TODO

( CMOVE and CMOVE> are kept together with MOVE )

( TODO SLITERAL test not implemented yet because it requires COMPARE) 
\ { : s14 [ s1 ] sliteral ; -> } 
\ { s1 s14 compare -> 0 }
\ { s1 s14 rot = rot rot = -> <true> <false> }

( TODO REPLACES not implemented yet )
( TODO SUBSTITUTE not implemented yet )
( TODO UNESCAPE not implemented yet )

\ Tests for long strings are currently in their own file
