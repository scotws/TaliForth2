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
{ parse-name drop     find-name  0<> -> <true> } \ need to find any nt
{ parse-name Chatika  find-name  0=  -> <true> } \ shouldn't find Tali's drone

{ hex -> }
{ 1000 10 bounds -> 1010 1000 }
{ ffff 2 bounds -> 0001 ffff }  \ BOUNDS wraps on Tali with 16 bit address space
{ decimal -> }

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
{ 0 -> 0 }
{ 1 -> 1 }
{ 2 -> 2 }


\ Test for DIGIT? ( char -- u f | char f )

{ 36 constant max-base -> } \ ANS standard says 2 - 36
{ base @  constant orig-base -> }
{ s" 0123456789" ( addr u ) drop  constant digit_numeral -> }
{ s" abcdefghijklmnopqrstuvwxyz" ( addr u ) drop  constant digit_lower -> }
{ s" ABCDEFGHIJKLMNOPQRSTUVWXYZ" ( addr u ) drop  constant digit_upper -> }

\ "/" and ":" are before and after ASCII numbers
\ "@" and "[" are before and after upper case ASCII letters
\ "`" and "{" are before and after lower case ASCII letters
{ s" /:@[`{"  ( addr u )  drop  constant digit_bad -> }

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

{ digit_all -> <true> }
{ decimal -> }


\ TODO find more edge cases for NUMBER
{ s" 0" number -> 0 }
{ s" 10" number -> 10 }
{ s" 100" number -> 100 }
{ s" 1." number -> 1 0 }
{ hex -> }
{ s" 0" number -> 0 }
{ s" 10" number -> 10 }
{ s" ff" number -> FF }
{ decimal -> }

