\ ------------------------------------------------------------------------
testing gforth words: bounds find-name latestxt name>int name>string

\ Test for COLD not implemented

( TODO BOUNDS test missing)
( TODO FIND-NAME test missing)
( TODO LATESTXT test missing)
( TODO NAME>INT test missing)
( TODO NAME>STRING test missing)


\ ------------------------------------------------------------------------
testing tali-only words: always-native bell compile-only digit? int>name latestnt number 0 1 2
testing tali-only words: never-native wordsize
decimal

\ Repeat definitions for standalone testing
0 constant 0s
0 invert constant 1s
0s constant <false>
1s constant <true>

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


\ Test for DIGIT? ( char -- u f | char f )

{ 36 constant max-base } \ ANSI standard says 2 - 36
{ base @  constant orig-base }
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
      dup emit       \ show user what's happening
      dup digit?  ( char  u | char  f ) 
      swap 48 +   ( char  f  u | char ) 
      rot =  ( f f )       \ is number what it's supposed to be?
      and  ( f )           \ conversion was signaled as success?
      and                  \ merge with running tab flag
   loop ; 

: digit_letters ( addr -- f ) 
\ HERE HERE
   ; 


\ All your bases are belong to us
: digit_all ( -- f )
   true
   max-base 1+  2 ?do
      decimal cr ." Testing base " i . ." : " 
      i base !
      digit_numeral and  dup ."  -> " .  \ print status of base to help find errors
   loop ; 


{ digit_all -> <true> }


{ orig-base base ! -> }



( TODO INT>NAME test missing)
( TODO LATESTNT test missing)
( TODO NEVER-NATVE test missing)
( TODO NUMBER test missing)
( TODO WORDSIZE test missing)
( TODO 0 test missing)
( TODO 1 test missing)
( TODO 2 test missing)
