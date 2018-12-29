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
\ testing tali-only words: -leading cleave hexstore

\ -leading: Strip leading whitespace
T{ s" aaa" -leading  s" aaa" compare -> 0 }T   \ No leading spaces
T{ s"  bbb" -leading  s" bbb" compare -> 0 }T  \ one leading space
T{ s"   ccc" -leading  s" ccc" compare -> 0 }T   \ two leading spaces
T{ s\" \tddd" -leading  s" ddd" compare -> 0 }T   \ one leading tab
T{ s\" \t\teee" -leading  s" eee" compare -> 0 }T   \ two leading tabs
T{ s\" \nddd" -leading  s" ddd" compare -> 0 }T   \ one leading LF
T{ s\" \n\neee" -leading  s" eee" compare -> 0 }T   \ two leading LF

\ Cleave: Normal cases. 
T{ : s1 s" " ; -> }T \ case 1: empty string
T{ s1 cleave  s" " compare  -rot  s" " compare -> 0 0 }T
T{ : s1 s" aaa" ; -> }T  \ case 2: one word
T{ s1 cleave  s" aaa" compare  -rot  s" " compare -> 0 0 }T
T{ : s1 s" aaa bbb ccc" ; -> }T  \ case 3: lots of words, single space delimiter
T{ s1 cleave  s" aaa" compare  -rot  s" bbb ccc" compare -> 0 0 }T
T{ : s1 s" bbb  ccc  ddd" ; -> }T  \ case 3a: lots of words, multiple space delimiter
T{ s1 cleave  s" bbb" compare  -rot  s" ccc  ddd" compare -> 0 0 }T
T{ : s1 s\" eee\tfff\tggg" ; -> }T  \ case 3b: lots of words, tab delimter
T{ s1 cleave  s" eee" compare  -rot  s\" fff\tggg" compare -> 0 0 }T
T{ : s1 s\" aaa\nAAA\nqqq" ; -> }T  \ case 3c: lots of words, EOL delimiter
T{ s1 cleave  s" aaa" compare  -rot  s\" AAA\nqqq" compare -> 0 0 }T
T{ : s1 s"  xxx yyy zzz" ; -> }T  \ case 3d: lots of words, start with space delimiter
T{ s1 cleave  s" xxx" compare  -rot  s" yyy zzz" compare -> 0 0 }T

\ Cleave: Pathological cases
T{ : s1 s" aaa bbb ccc " ; -> }T \ case 5: Trailing space is left
T{ s1 cleave  s" aaa" compare  -rot  s" bbb ccc " compare -> 0 0 }T
T{ : s1 s" fff " ; -> }T  \ case 6: Trailing space on single word is empty
T{ s1 cleave  s" fff" compare  -rot  s" " compare -> 0 0 }T
T{ : s1 s"  " ; -> }T  \ case 7: Single space as word is two empty words
T{ s1 cleave  s" " compare  -rot  s" " compare -> 0 0 }T


\ Hexstore: Normal cases

create hs-test 5 allot

decimal
create hs-want-dec  1 c, 2 c, 3 c, 4 c, 5 c, 
T{ s" 1 2 3 4 5" hs-test hexstore  hs-test swap  hs-want-dec 5  compare -> 0 }T
T{ s" 1" hs-test hexstore  hs-test swap  hs-want-dec 1  compare -> 0 }T

hex
create hs-want-hex  0A c, 0B c, 0C c, 0D c, 0E c, 
T{ s" 0A 0B 0C 0D 0E" hs-test hexstore  hs-test swap  hs-want-hex 5  compare -> 0 }T
T{ s" 0A" hs-test hexstore  hs-test swap  hs-want-hex 1  compare -> 0 }T

\ Hexstore: Pathological cases

decimal
T{ s" " hs-test hexstore  hs-test swap  s" " compare -> 0 }T
T{ s" emergency" hs-test hexstore  hs-test swap  s" " compare -> 0 }T
T{ s" emergency induction port" hs-test hexstore  hs-test swap  s" " compare -> 0 }T

create hs-want-dec-path  01 c, 02 c,
T{ s" 01 HONK! 02" hs-test hexstore  hs-test swap  hs-want-dec-path 2 compare -> 0 }T
T{ s" HONK! 01 02" hs-test hexstore  hs-test swap  hs-want-dec-path 2 compare -> 0 }T
T{ s" 01 02 HONK!" hs-test hexstore  hs-test swap  hs-want-dec-path 2 compare -> 0 }T

\ ------------------------------------------------------------------------
testing tali-only words: always-native bell compile-only digit? int>name
testing tali-only words: latestnt latestxt number 0 1 2
testing tali-only words: allow-native never-native wordsize nc-limit
decimal

\ Test for 0BRANCH not implemented
\ Test for BRANCH not implemented
\ Test for DISASM not implemented
\ Test for INPUT not implemented
\ Test for OUTPUT not implemented
\ Test for UF-STRIP not implemented

( TODO BELL test missing)
( TODO COMPILE-ONLY test missing)

\ Test int>name, latestnt, latestxt, and wordsize
: one 1 ;
T{ ' one int>name wordsize    -> 8 }T
T{ latestxt int>name wordsize -> 8 }T
T{ latestnt wordsize          -> 8 }T

\ One should have been created with NN flag, so it should be compiled
\ as a JSR when used (3-bytes).
: one-a one ;
T{ ' one-a int>name wordsize -> 3 }T

\ Test allow-native
: two 1 1 ; allow-native
\ This should just barely prevent two from being natively compiled.
15 nc-limit !
: two-a two ;
\ This should just barely allow two to be natively compiled.
16 nc-limit !
: two-b two ;

T{ ' two   int>name wordsize -> 16 }T
T{ ' two-a int>name wordsize ->  3 }T
T{ ' two-b int>name wordsize -> 16 }T

\ Test always-native.
: three 2 1 ; always-native
\ Three should always natively compile regardless of nc-limit.
15 nc-limit !
: three-a three ;
16 nc-limit !
: three-b three ;

T{ ' three   int>name wordsize -> 16 }T
T{ ' three-a int>name wordsize -> 16 }T
T{ ' three-b int>name wordsize -> 16 }T
\ Sneak in extra tests for latestnt and latestxt.
T{ latestnt wordsize           -> 16 }T
T{ latestxt int>name wordsize  -> 16 }T


\ Test never-native.
\ Because NN is the default, we have to switch to one of the other modes first.
: four 2 2 ; always-native never-native
\ Four should never natively compile regardless of nc-limit.
\ It will always be a JSR when used in another word.
15 nc-limit !
: four-a four ;
16 nc-limit !
: four-b four ;

T{ ' four   int>name wordsize -> 16 }T
T{ ' four-a int>name wordsize ->  3 }T
T{ ' four-b int>name wordsize ->  3 }T
\ Sneak in extra tests for latestnt and latestxt.
T{ latestnt wordsize          ->  3 }T
T{ latestxt int>name wordsize ->  3 }T

\ Nothing is too trivial for testing!
T{ 0 -> 0 }T
T{ 1 -> 1 }T
T{ 2 -> 2 }T
\ Slightly less trivial...
T{ 0 -> 5 5 - }T
T{ 1 -> 5 4 - }T
T{ 2 -> 5 3 - }T

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

\ ------------------------------------------------------------------------
testing tali-only words: execute-parsing

T{ s" 0" ' parse-name execute-parsing evaluate -> 0 }T    \ built-in word
T{ s" 10" ' parse-name execute-parsing evaluate -> 10 }T  \ number

\ Test with delimiter other than a space
T{ char +  s" 0+" ' parse execute-parsing evaluate -> 0 }T

\ We can use EXECUTE-PARSING to define variable names at runtime
T{ s" myvar" ' variable execute-parsing -> }T
T{ 2 myvar !  myvar @  -> 2 }T

\ Free memory used for these tests
tali_tests
