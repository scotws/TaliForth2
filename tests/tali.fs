\ ------------------------------------------------------------------------
hex

marker tali_tests


\ Repeat definitions for standalone testing
0 constant 0s
0 invert constant 1s
0s constant <false>
1s constant <true>

\ ------------------------------------------------------------------------
testing gforth words: bounds find-name latestxt name>int name>string
\ Test for COLD not implemented

( TODO LATESTXT test missing)
( TODO NAME>INT test missing)
( TODO NAME>STRING test missing)

\ Test for FIND-NAME assumes that PARSE-NAME has been tested in core.fs
T{ parse-name drop     find-name  0<> -> <true> }T \ need to find any nt
T{ parse-name Chatika  find-name  0=  -> <true> }T \ shouldn't find Tali's drone

T{ hex -> }T
T{ 1000 10 bounds -> 1010 1000 }T
T{ ffff 2 bounds -> 0001 ffff }T  \ BOUNDS wraps on Tali with 16 bit address space
T{ decimal -> }T

\ ------------------------------------------------------------------------
testing tali-only words: always-native bell compile-only digit? int>name latestnt number 0 1 2
testing tali-only words: never-native wordsize
decimal

\ Test for 0BRANCH not implemented
\ Test for BRANCH not implemented
\ Test for DISASM not implemented
\ Test for INPUT not implemented
\ Test for NC-LIMIT not implemented
\ Test for OUTPUT not implemented
\ Test for UF-STRIP not implemented

( TODO ALWAY-NATIVE test missing)
( TODO BELL test missing)
( TODO COMPILE-ONLY test missing)
( TODO INT>NAME test missing)
( TODO LATESTNT test missing)
( TODO NEVER-NATVE test missing)
( TODO WORDSIZE test missing)


\ Nothing is too trivial for testing!
T{ 0 -> 0 }T
T{ 1 -> 1 }T
T{ 2 -> 2 }T


\ Test for DIGIT? ( char -- u f | char f )

T{ 36 constant max-base -> }T \ ANS standard says 2 - 36
T{ base @  constant orig-base -> }T
T{ s" 0123456789" ( addr u ) drop  constant digit_numeral -> }T
T{ s" abcdefghijklmnopqrstuvwxyz" ( addr u ) drop  constant digit_lower -> }T
T{ s" ABCDEFGHIJKLMNOPQRSTUVWXYZ" ( addr u ) drop  constant digit_upper -> }T

\ "/" and ":" are before and after ASCII numbers
\ "@" and "[" are before and after upper case ASCII letters
\ "`" and "{" are before and after lower case ASCII letters
T{ s" /:@[`{"  ( addr u )  drop  constant digit_bad -> }T

: digit_numeral ( -- f )
   true
   base @  10 min  ( don't go outside chars )  0 ?do
      digit_numeral i +  ( addr ) c@ 
      dup emit  \ Show user what is going on
      dup digit?  ( char  u | char  f ) 
      swap 48 ( ASCII "0" ) +   ( char  f  u | char ) 
      rot =  ( f f )       \ is number what it's supposed to be?
      and  ( f )           \ conversion was signaled as success?
      and                  \ merge with running tab flag
   loop ; 

: digit_letters ( -- f ) 
   true
   base @  10 - ( grow index with base)  0 ?do
      digit_lower i + c@  
      dup emit
      dup digit?  
      swap 97 ( ASCII "a" ) 10 -  +
      rot = 
      and and 

      digit_upper i + c@  
      dup emit
      dup digit? 
      swap 65 ( ASCII "A" ) 10 -  +
      rot = 
      and and 
   loop ; 

: digit_oneoff ( -- f ) 
   true 
   7 0 ?do
      digit_bad i + c@
      dup emit
      digit?  ( char 0 ) 
      nip invert 
      and
   loop ;

\ All your bases are belong to us. In theory, we could condense this
\ code further, because Forth, but it would become harder to understand
: digit_all ( -- f )
   true

   max-base 1+  2 ?do
      decimal cr ." Numerals, base " i . ." : " 
      i base !
      digit_numeral and
      dup ."  -> " .  \ print status of base to help find errors
   loop 
   
   decimal cr
   max-base 1+  11 ?do
      decimal cr ." Letters, base " i . ." : " 
      i base !
      digit_letters and
      dup ."  -> " . \ uncomment for debugging
   loop 

   decimal cr
   max-base 1+ 2 ?do
      decimal cr ." One-off chars, base " i . ." : " 
      i base !
      digit_oneoff and
      dup ."  -> " .  \ uncomment for debugging
   loop ;

T{ digit_all -> <true> }T
T{ decimal -> }T


\ TODO find more edge cases for NUMBER
T{ s" 0" number -> 0 }T
T{ s" 10" number -> 10 }T
T{ s" 100" number -> 100 }T
T{ s" 1." number -> 1 0 }T
T{ hex -> }T
T{ s" 0" number -> 0 }T
T{ s" 10" number -> 10 }T
T{ s" ff" number -> FF }T
T{ decimal -> }T

\ ------------------------------------------------------------------------
testing case-insensitivity in Tali using dup

T{ 5 dup -> 5 5 }T
T{ 5 duP -> 5 5 }T
T{ 5 dUp -> 5 5 }T
T{ 5 dUP -> 5 5 }T
T{ 5 Dup -> 5 5 }T
T{ 5 DuP -> 5 5 }T
T{ 5 DUp -> 5 5 }T
T{ 5 DUP -> 5 5 }T

\ Free memory used for these tests
tali_tests

