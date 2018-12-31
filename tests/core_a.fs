\ From: John Hayes S1I
\ Subject: core.fr
\ Date: Mon, 27 Nov 95 13:10

\ Modified by SamCo 2018-05 for testing Tali Forth 2.
\ The main change is lowercasing all of the words as Tali
\ is case sensitive.

\ (C) 1995 JOHNS HOPKINS UNIVERSITY / APPLIED PHYSICS LABORATORY
\ MAY BE DISTRIBUTED FREELY AS LONG AS THIS COPYRIGHT NOTICE REMAINS.
\ VERSION 1.2
\ THIS PROGRAM TESTS THE CORE WORDS OF AN ANS FORTH SYSTEM.
\ THE PROGRAM ASSUMES A TWO'S COMPLEMENT IMPLEMENTATION WHERE
\ THE RANGE OF SIGNED NUMBERS IS -2^(N-1) ... 2^(N-1)-1 AND
\ THE RANGE OF UNSIGNED NUMBERS IS 0 ... 2^(N)-1.
\ I HAVEN'T FIGURED OUT HOW TO TEST KEY, QUIT, ABORT, OR ABORT"...

testing core words
hex

marker core_a_tests

\ ------------------------------------------------------------------------
testing basic assumptions

T{ -> }T     \ Start with clean slate
( test if any bits are set; answer in base 1 )
T{ : bitsset? if 0 0 else 0 then ; -> }T
T{  0 bitsset? -> 0 }T   \ zero is all bits clear
T{  1 bitsset? -> 0 0 }T \ other number have at least one bit
T{ -1 bitsset? -> 0 0 }T

\ ------------------------------------------------------------------------
testing booleans: and invert or xor

T{ 0 0 and -> 0 }T
T{ 0 1 and -> 0 }T
T{ 1 0 and -> 0 }T
T{ 1 1 and -> 1 }T

T{ 0 invert 1 and -> 1 }T
T{ 1 invert 1 and -> 0 }T

0 constant 0s
0 invert constant 1s

T{ 0s invert -> 1s }T
T{ 1s invert -> 0s }T

T{ 0s 0s and -> 0s }T
T{ 0s 1s and -> 0s }T
T{ 1s 0s and -> 0s }T
T{ 1s 1s and -> 1s }T

T{ 0s 0s or -> 0s }T
T{ 0s 1s or -> 1s }T
T{ 1s 0s or -> 1s }T
T{ 1s 1s or -> 1s }T

T{ 0s 0s xor -> 0s }T
T{ 0s 1s xor -> 1s }T
T{ 1s 0s xor -> 1s }T
T{ 1s 1s xor -> 0s }T

\ ------------------------------------------------------------------------
testing 2* 2/ lshift rshift

( we trust 1s, invert, and bitsset?; we will confirm rshift later )
1s 1 rshift invert constant msb
T{ msb bitsset? -> 0 0 }T

T{ 0s 2* -> 0s }T
T{ 1 2* -> 2 }T
T{ 4000 2* -> 8000 }T
T{ 1s 2* 1 xor -> 1s }T
T{ msb 2* -> 0s }T

T{ 0s 2/ -> 0s }T
T{ 1 2/ -> 0 }T
T{ 4000 2/ -> 2000 }T
T{ 1s 2/ -> 1s }T \ msb propogated
T{ 1s 1 xor 2/ -> 1s }T
T{ msb 2/ msb and -> msb }T

T{ 1 0 lshift -> 1 }T
T{ 1 1 lshift -> 2 }T
T{ 1 2 lshift -> 4 }T
T{ 1 f lshift -> 8000 }T \ biggest guaranteed shift
T{ 1s 1 lshift 1 xor -> 1s }T
T{ msb 1 lshift -> 0 }T

T{ 1 0 rshift -> 1 }T
T{ 1 1 rshift -> 0 }T
T{ 2 1 rshift -> 1 }T
T{ 4 2 rshift -> 1 }T
T{ 8000 f rshift -> 1 }T \ biggest
T{ msb 1 rshift msb and -> 0 }T  \ rshift zero fills msbs
T{ msb 1 rshift 2* -> msb }T

\ ------------------------------------------------------------------------
testing comparisons: true false 0= 0<> = <> 0< 0> < > u< min max within
0 invert  constant max-uint
0 invert 1 rshift  constant max-int
0 invert 1 rshift invert  constant min-int
0 invert 1 rshift  constant mid-uint
0 invert 1 rshift invert  constant mid-uint+1

0s constant <false>
1s constant <true>

T{ false -> 0 }T
T{ false -> <false> }T

T{ true -> <true> }T
T{ true -> 0 invert }T

T{ 0 0= -> <true> }T
T{ 1 0= -> <false> }T
T{ 2 0= -> <false> }T
T{ -1 0= -> <false> }T
T{ max-uint 0= -> <false> }T
T{ min-int 0= -> <false> }T
T{ max-int 0= -> <false> }T

T{ 0 0<> -> <false> }T
T{ 1 0<> -> <true> }T
T{ 2 0<> -> <true> }T
T{ -1 0<> -> <true> }T
T{ max-uint 0<> -> <true> }T
T{ min-int 0<> -> <true> }T
T{ max-int 0<> -> <true> }T

T{ 0 0 = -> <true> }T
T{ 1 1 = -> <true> }T
T{ -1 -1 = -> <true> }T
T{ 1 0 = -> <false> }T
T{ -1 0 = -> <false> }T
T{ 0 1 = -> <false> }T
T{ 0 -1 = -> <false> }T

T{ 0 0 <> -> <false> }T
T{ 1 1 <> -> <false> }T
T{ -1 -1 <> -> <false> }T
T{ 1 0 <> -> <true> }T
T{ -1 0 <> -> <true> }T
T{ 0 1 <> -> <true> }T
T{ 0 -1 <> -> <true> }T

T{ 0 0< -> <false> }T
T{ -1 0< -> <true> }T
T{ min-int 0< -> <true> }T
T{ 1 0< -> <false> }T
T{ max-int 0< -> <false> }T

T{ 0 0> -> <false> }T
T{ -1 0> -> <false> }T
T{ min-int 0> -> <false> }T
T{ 1 0> -> <true> }T
T{ max-int 0> -> <true> }T

T{ 0 1 < -> <true> }T
T{ 1 2 < -> <true> }T
T{ -1 0 < -> <true> }T
T{ -1 1 < -> <true> }T
T{ min-int 0 < -> <true> }T
T{ min-int max-int < -> <true> }T
T{ 0 max-int < -> <true> }T
T{ 0 0 < -> <false> }T
T{ 1 1 < -> <false> }T
T{ 1 0 < -> <false> }T
T{ 2 1 < -> <false> }T
T{ 0 -1 < -> <false> }T
T{ 1 -1 < -> <false> }T
T{ 0 min-int < -> <false> }T
T{ max-int min-int < -> <false> }T
T{ max-int 0 < -> <false> }T

T{ 0 1 > -> <false> }T
T{ 1 2 > -> <false> }T
T{ -1 0 > -> <false> }T
T{ -1 1 > -> <false> }T
T{ min-int 0 > -> <false> }T
T{ min-int max-int > -> <false> }T
T{ 0 max-int > -> <false> }T
T{ 0 0 > -> <false> }T
T{ 1 1 > -> <false> }T
T{ 1 0 > -> <true> }T
T{ 2 1 > -> <true> }T
T{ 0 -1 > -> <true> }T
T{ 1 -1 > -> <true> }T
T{ 0 min-int > -> <true> }T
T{ max-int min-int > -> <true> }T
T{ max-int 0 > -> <true> }T

T{ 0 1 u< -> <true> }T
T{ 1 2 u< -> <true> }T
T{ 0 mid-uint u< -> <true> }T
T{ 0 max-uint u< -> <true> }T
T{ mid-uint max-uint u< -> <true> }T
T{ 0 0 u< -> <false> }T
T{ 1 1 u< -> <false> }T
T{ 1 0 u< -> <false> }T
T{ 2 1 u< -> <false> }T
T{ mid-uint 0 u< -> <false> }T
T{ max-uint 0 u< -> <false> }T
T{ max-uint mid-uint u< -> <false> }T

T{ 1 0 u> -> <true> }T
T{ 2 1 u> -> <true> }T
T{ mid-uint 0 u> -> <true> }T
T{ max-uint 0 u> -> <true> }T
T{ max-uint mid-uint u> -> <true> }T
T{ 0 0 u> -> <false> }T
T{ 1 1 u> -> <false> }T
T{ 0 1 u> -> <false> }T
T{ 1 2 u> -> <false> }T
T{ 0 mid-uint u> -> <false> }T
T{ 0 max-uint u> -> <false> }T
T{ mid-uint max-uint u> -> <false> }T

T{ 0 1 min -> 0 }T
T{ 1 2 min -> 1 }T
T{ -1 0 min -> -1 }T
T{ -1 1 min -> -1 }T
T{ min-int 0 min -> min-int }T
T{ min-int max-int min -> min-int }T
T{ 0 max-int min -> 0 }T
T{ 0 0 min -> 0 }T
T{ 1 1 min -> 1 }T
T{ 1 0 min -> 0 }T
T{ 2 1 min -> 1 }T
T{ 0 -1 min -> -1 }T
T{ 1 -1 min -> -1 }T
T{ 0 min-int min -> min-int }T
T{ max-int min-int min -> min-int }T
T{ max-int 0 min -> 0 }T

T{ 0 1 max -> 1 }T
T{ 1 2 max -> 2 }T
T{ -1 0 max -> 0 }T
T{ -1 1 max -> 1 }T
T{ min-int 0 max -> 0 }T
T{ min-int max-int max -> max-int }T
T{ 0 max-int max -> max-int }T
T{ 0 0 max -> 0 }T
T{ 1 1 max -> 1 }T
T{ 1 0 max -> 1 }T
T{ 2 1 max -> 2 }T
T{ 0 -1 max -> 0 }T
T{ 1 -1 max -> 1 }T
T{ 0 min-int max -> 0 }T
T{ max-int min-int max -> max-int }T
T{ max-int 0 max -> max-int }T

T{ 1 2 4 within -> <false> }T
T{ 2 2 4 within -> <true> }T
T{ 3 2 4 within -> <true> }T
T{ 4 2 4 within -> <false> }T
T{ 5 2 4 within -> <false> }T

T{ 0 2 4 within -> <false> }T
T{ 1 0 4 within -> <true> }T
T{ 0 0 4 within -> <true> }T
T{ 4 0 4 within -> <false> }T
T{ 5 0 4 within -> <false> }T

T{ -1 -3 -1 within -> <false> }T
T{ -2 -3 -1 within -> <true> }T
T{ -3 -3 -1 within -> <true> }T
T{ -4 -3 -1 within -> <false> }T

T{ -2 -2 0 within -> <true> }T
T{ -1 -2 0 within -> <true> }T
T{ 0 -2 0 within -> <false> }T
T{ 1 -2 0 within -> <false> }T

T{ 0 min-int max-int within -> <true> }T
T{ 1 min-int max-int within -> <true> }T
T{ -1 min-int max-int within -> <true> }T
T{ min-int min-int max-int within -> <true> }T
T{ max-int min-int max-int within -> <false> }T

\ ------------------------------------------------------------------------
testing stack ops: 2drop 2dup 2over 2swap ?dup depth drop dup nip over rot -rot 
testing stack ops: swap tuck pick

T{ 1 2 2drop -> }T
T{ 1 2 2dup -> 1 2 1 2 }T
T{ 1 2 3 4 2over -> 1 2 3 4 1 2 }T
T{ 1 2 3 4 2swap -> 3 4 1 2 }T
T{ 0 ?dup -> 0 }T
T{ 1 ?dup -> 1 1 }T
T{ -1 ?dup -> -1 -1 }T
T{ depth -> 0 }T
T{ 0 depth -> 0 1 }T
T{ 0 1 depth -> 0 1 2 }T
T{ 0 drop -> }T
T{ 1 2 drop -> 1 }T
T{ 1 dup -> 1 1 }T
T{ 1 2 nip -> 2 }T
T{ 1 2 over -> 1 2 1 }T
T{ 1 2 3 rot -> 2 3 1 }T
T{ 1 2 3 -rot -> 3 1 2 }T
T{ 1 2 swap -> 2 1 }T

\ There is no formal ANS test for TUCK, this added 01. July 2018
T{ 2 1 tuck -> 1 2 1 }T

\ There is no formal ANS test for PICK, this added 01. July 2018
\ Note that ANS's PICK is different from FIG Forth PICK
T{ 1      0 pick -> 1 1 }T    \ Defined by standard: 0 PICK is same as DUP
T{ 1 2    1 pick -> 1 2 1 }T  \ Defined by standard: 1 PICK is same as OVER
T{ 1 2 3  2 pick -> 1 2 3 1 }T

\ ------------------------------------------------------------------------
testing >r r> r@ 2>r 2r> 2r@

T{ : gr1 >r r> ; -> }T
T{ : gr2 >r r@ r> drop ; -> }T
T{ 123 gr1 -> 123 }T
T{ 123 gr2 -> 123 }T
T{ 1s gr1 -> 1s }T \ return stack holds cells

\ There are no official ANS tests for 2>R, 2R>, or 2R@, added 22. June 2018
T{ : gr3 2>r 2r> ; -> }T
T{ : gr4 2>r 2r@ 2r> 2drop ; -> }T
T{ : gr5 2>r r> r> ; }T \ must reverse sequence, as 2r> is not r> r> 
T{ 123. gr3 -> 123. }T
T{ 123. gr4 -> 123. }T
T{ 123. gr5 -> 0 123 }T

\ ------------------------------------------------------------------------
testing add/subtract: + - 1+ 1- abs negate 

T{ 0 5 + -> 5 }T
T{ 5 0 + -> 5 }T
T{ 0 -5 + -> -5 }T
T{ -5 0 + -> -5 }T
T{ 1 2 + -> 3 }T
T{ 1 -2 + -> -1 }T
T{ -1 2 + -> 1 }T
T{ -1 -2 + -> -3 }T
T{ -1 1 + -> 0 }T
T{ mid-uint 1 + -> mid-uint+1 }T

T{ 0 5 - -> -5 }T
T{ 5 0 - -> 5 }T
T{ 0 -5 - -> 5 }T
T{ -5 0 - -> -5 }T
T{ 1 2 - -> -1 }T
T{ 1 -2 - -> 3 }T
T{ -1 2 - -> -3 }T
T{ -1 -2 - -> 1 }T
T{ 0 1 - -> -1 }T
T{ mid-uint+1 1 - -> mid-uint }T

T{ 0 1+ -> 1 }T
T{ -1 1+ -> 0 }T
T{ 1 1+ -> 2 }T
T{ mid-uint 1+ -> mid-uint+1 }T

T{ 2 1- -> 1 }T
T{ 1 1- -> 0 }T
T{ 0 1- -> -1 }T
T{ mid-uint+1 1- -> mid-uint }T

T{ 0 negate -> 0 }T
T{ 1 negate -> -1 }T
T{ -1 negate -> 1 }T
T{ 2 negate -> -2 }T
T{ -2 negate -> 2 }T

T{ 0 abs -> 0 }T
T{ 1 abs -> 1 }T
T{ -1 abs -> 1 }T
T{ min-int abs -> mid-uint+1 }T

\ ------------------------------------------------------------------------
testing multiply: s>d * m* um*

T{ 0 s>d -> 0 0 }T
T{ 1 s>d -> 1 0 }T
T{ 2 s>d -> 2 0 }T
T{ -1 s>d -> -1 -1 }T
T{ -2 s>d -> -2 -1 }T
T{ min-int s>d -> min-int -1 }T
T{ max-int s>d -> max-int 0 }T

T{ 0 0 m* -> 0 s>d }T
T{ 0 1 m* -> 0 s>d }T
T{ 1 0 m* -> 0 s>d }T
T{ 1 2 m* -> 2 s>d }T
T{ 2 1 m* -> 2 s>d }T
T{ 3 3 m* -> 9 s>d }T
T{ -3 3 m* -> -9 s>d }T
T{ 3 -3 m* -> -9 s>d }T
T{ -3 -3 m* -> 9 s>d }T
T{ 0 min-int m* -> 0 s>d }T
T{ 1 min-int m* -> min-int s>d }T
T{ 2 min-int m* -> 0 1s }T
T{ 0 max-int m* -> 0 s>d }T
T{ 1 max-int m* -> max-int s>d }T
T{ 2 max-int m* -> max-int 1 lshift 0 }T
T{ min-int min-int m* -> 0 msb 1 rshift }T
T{ max-int min-int m* -> msb msb 2/ }T
T{ max-int max-int m* -> 1 msb 2/ invert }T

T{ 0 0 * -> 0 }T \ test identities
T{ 0 1 * -> 0 }T
T{ 1 0 * -> 0 }T
T{ 1 2 * -> 2 }T
T{ 2 1 * -> 2 }T
T{ 3 3 * -> 9 }T
T{ -3 3 * -> -9 }T
T{ 3 -3 * -> -9 }T
T{ -3 -3 * -> 9 }T

T{ mid-uint+1 1 rshift 2 * -> mid-uint+1 }T
T{ mid-uint+1 2 rshift 4 * -> mid-uint+1 }T
T{ mid-uint+1 1 rshift mid-uint+1 or 2 * -> mid-uint+1 }T

T{ 0 0 um* -> 0 0 }T
T{ 0 1 um* -> 0 0 }T
T{ 1 0 um* -> 0 0 }T
T{ 1 2 um* -> 2 0 }T
T{ 2 1 um* -> 2 0 }T
T{ 3 3 um* -> 9 0 }T

T{ mid-uint+1 1 rshift 2 um* -> mid-uint+1 0 }T
T{ mid-uint+1 2 um* -> 0 1 }T
T{ mid-uint+1 4 um* -> 0 2 }T
T{ 1s 2 um* -> 1s 1 lshift 1 }T
T{ max-uint max-uint um* -> 1 1 invert }T

\ ------------------------------------------------------------------------
testing divide: fm/mod sm/rem um/mod */ */mod / /mod mod

T{ 0 s>d 1 fm/mod -> 0 0 }T
T{ 1 s>d 1 fm/mod -> 0 1 }T
T{ 2 s>d 1 fm/mod -> 0 2 }T
T{ -1 s>d 1 fm/mod -> 0 -1 }T
T{ -2 s>d 1 fm/mod -> 0 -2 }T
T{ 0 s>d -1 fm/mod -> 0 0 }T
T{ 1 s>d -1 fm/mod -> 0 -1 }T
T{ 2 s>d -1 fm/mod -> 0 -2 }T
T{ -1 s>d -1 fm/mod -> 0 1 }T
T{ -2 s>d -1 fm/mod -> 0 2 }T
T{ 2 s>d 2 fm/mod -> 0 1 }T
T{ -1 s>d -1 fm/mod -> 0 1 }T
T{ -2 s>d -2 fm/mod -> 0 1 }T
T{  7 s>d  3 fm/mod -> 1 2 }T
T{  7 s>d -3 fm/mod -> -2 -3 }T
T{ -7 s>d  3 fm/mod -> 2 -3 }T
T{ -7 s>d -3 fm/mod -> -1 2 }T
T{ max-int s>d 1 fm/mod -> 0 max-int }T
T{ min-int s>d 1 fm/mod -> 0 min-int }T
T{ max-int s>d max-int fm/mod -> 0 1 }T
T{ min-int s>d min-int fm/mod -> 0 1 }T
T{ 1s 1 4 fm/mod -> 3 max-int }T
T{ 1 min-int m* 1 fm/mod -> 0 min-int }T
T{ 1 min-int m* min-int fm/mod -> 0 1 }T
T{ 2 min-int m* 2 fm/mod -> 0 min-int }T
T{ 2 min-int m* min-int fm/mod -> 0 2 }T
T{ 1 max-int m* 1 fm/mod -> 0 max-int }T
T{ 1 max-int m* max-int fm/mod -> 0 1 }T
T{ 2 max-int m* 2 fm/mod -> 0 max-int }T
T{ 2 max-int m* max-int fm/mod -> 0 2 }T
T{ min-int min-int m* min-int fm/mod -> 0 min-int }T
T{ min-int max-int m* min-int fm/mod -> 0 max-int }T
T{ min-int max-int m* max-int fm/mod -> 0 min-int }T
T{ max-int max-int m* max-int fm/mod -> 0 max-int }T

T{ 0 s>d 1 sm/rem -> 0 0 }T
T{ 1 s>d 1 sm/rem -> 0 1 }T
T{ 2 s>d 1 sm/rem -> 0 2 }T
T{ -1 s>d 1 sm/rem -> 0 -1 }T
T{ -2 s>d 1 sm/rem -> 0 -2 }T
T{ 0 s>d -1 sm/rem -> 0 0 }T
T{ 1 s>d -1 sm/rem -> 0 -1 }T
T{ 2 s>d -1 sm/rem -> 0 -2 }T
T{ -1 s>d -1 sm/rem -> 0 1 }T
T{ -2 s>d -1 sm/rem -> 0 2 }T
T{ 2 s>d 2 sm/rem -> 0 1 }T
T{ -1 s>d -1 sm/rem -> 0 1 }T
T{ -2 s>d -2 sm/rem -> 0 1 }T
T{  7 s>d  3 sm/rem -> 1 2 }T
T{  7 s>d -3 sm/rem -> 1 -2 }T
T{ -7 s>d  3 sm/rem -> -1 -2 }T
T{ -7 s>d -3 sm/rem -> -1 2 }T
T{ max-int s>d 1 sm/rem -> 0 max-int }T
T{ min-int s>d 1 sm/rem -> 0 min-int }T
T{ max-int s>d max-int sm/rem -> 0 1 }T
T{ min-int s>d min-int sm/rem -> 0 1 }T
T{ 1s 1 4 sm/rem -> 3 max-int }T
T{ 2 min-int m* 2 sm/rem -> 0 min-int }T
T{ 2 min-int m* min-int sm/rem -> 0 2 }T
T{ 2 max-int m* 2 sm/rem -> 0 max-int }T
T{ 2 max-int m* max-int sm/rem -> 0 2 }T
T{ min-int min-int m* min-int sm/rem -> 0 min-int }T
T{ min-int max-int m* min-int sm/rem -> 0 max-int }T
T{ min-int max-int m* max-int sm/rem -> 0 min-int }T
T{ max-int max-int m* max-int sm/rem -> 0 max-int }T

T{ 0 0 1 um/mod -> 0 0 }T
T{ 1 0 1 um/mod -> 0 1 }T
T{ 1 0 2 um/mod -> 1 0 }T
T{ 3 0 2 um/mod -> 1 1 }T
T{ max-uint 2 um* 2 um/mod -> 0 max-uint }T
T{ max-uint 2 um* max-uint um/mod -> 0 2 }T
T{ max-uint max-uint um* max-uint um/mod -> 0 max-uint }T

: iffloored
   [ -3 2 / -2 = invert ] literal if postpone \ then ;
: ifsym
   [ -3 2 / -1 = invert ] literal if postpone \ then ;

\ the system might do either floored or symmetric division.
\ since we have already tested m*, fm/mod, and sm/rem we can use them in test.
iffloored : t/mod  >r s>d r> fm/mod ;
iffloored : t/     t/mod swap drop ;
iffloored : tmod   t/mod drop ;
iffloored : t*/mod >r m* r> fm/mod ;
iffloored : t*/    t*/mod swap drop ;
ifsym     : t/mod  >r s>d r> sm/rem ;
ifsym     : t/     t/mod swap drop ;
ifsym     : tmod   t/mod drop ;
ifsym     : t*/mod >r m* r> sm/rem ;
ifsym     : t*/    t*/mod swap drop ;

T{ 0 1 /mod -> 0 1 t/mod }T
T{ 1 1 /mod -> 1 1 t/mod }T
T{ 2 1 /mod -> 2 1 t/mod }T
T{ -1 1 /mod -> -1 1 t/mod }T
T{ -2 1 /mod -> -2 1 t/mod }T
T{ 0 -1 /mod -> 0 -1 t/mod }T
T{ 1 -1 /mod -> 1 -1 t/mod }T
T{ 2 -1 /mod -> 2 -1 t/mod }T
T{ -1 -1 /mod -> -1 -1 t/mod }T
T{ -2 -1 /mod -> -2 -1 t/mod }T
T{ 2 2 /mod -> 2 2 t/mod }T
T{ -1 -1 /mod -> -1 -1 t/mod }T
T{ -2 -2 /mod -> -2 -2 t/mod }T
T{ 7 3 /mod -> 7 3 t/mod }T
T{ 7 -3 /mod -> 7 -3 t/mod }T
T{ -7 3 /mod -> -7 3 t/mod }T
T{ -7 -3 /mod -> -7 -3 t/mod }T
T{ max-int 1 /mod -> max-int 1 t/mod }T
T{ min-int 1 /mod -> min-int 1 t/mod }T
T{ max-int max-int /mod -> max-int max-int t/mod }T
T{ min-int min-int /mod -> min-int min-int t/mod }T

T{ 0 1 / -> 0 1 t/ }T
T{ 1 1 / -> 1 1 t/ }T
T{ 2 1 / -> 2 1 t/ }T
T{ -1 1 / -> -1 1 t/ }T
T{ -2 1 / -> -2 1 t/ }T
T{ 0 -1 / -> 0 -1 t/ }T
T{ 1 -1 / -> 1 -1 t/ }T
T{ 2 -1 / -> 2 -1 t/ }T
T{ -1 -1 / -> -1 -1 t/ }T
T{ -2 -1 / -> -2 -1 t/ }T
T{ 2 2 / -> 2 2 t/ }T
T{ -1 -1 / -> -1 -1 t/ }T
T{ -2 -2 / -> -2 -2 t/ }T
T{ 7 3 / -> 7 3 t/ }T
T{ 7 -3 / -> 7 -3 t/ }T
T{ -7 3 / -> -7 3 t/ }T
T{ -7 -3 / -> -7 -3 t/ }T
T{ max-int 1 / -> max-int 1 t/ }T
T{ min-int 1 / -> min-int 1 t/ }T
T{ max-int max-int / -> max-int max-int t/ }T
T{ min-int min-int / -> min-int min-int t/ }T

T{ 0 1 mod -> 0 1 tmod }T
T{ 1 1 mod -> 1 1 tmod }T
T{ 2 1 mod -> 2 1 tmod }T
T{ -1 1 mod -> -1 1 tmod }T
T{ -2 1 mod -> -2 1 tmod }T
T{ 0 -1 mod -> 0 -1 tmod }T
T{ 1 -1 mod -> 1 -1 tmod }T
T{ 2 -1 mod -> 2 -1 tmod }T
T{ -1 -1 mod -> -1 -1 tmod }T
T{ -2 -1 mod -> -2 -1 tmod }T
T{ 2 2 mod -> 2 2 tmod }T
T{ -1 -1 mod -> -1 -1 tmod }T
T{ -2 -2 mod -> -2 -2 tmod }T
T{ 7 3 mod -> 7 3 tmod }T
T{ 7 -3 mod -> 7 -3 tmod }T
T{ -7 3 mod -> -7 3 tmod }T
T{ -7 -3 mod -> -7 -3 tmod }T
T{ max-int 1 mod -> max-int 1 tmod }T
T{ min-int 1 mod -> min-int 1 tmod }T
T{ max-int max-int mod -> max-int max-int tmod }T
T{ min-int min-int mod -> min-int min-int tmod }T

T{ 0 2 1 */ -> 0 2 1 t*/ }T
T{ 1 2 1 */ -> 1 2 1 t*/ }T
T{ 2 2 1 */ -> 2 2 1 t*/ }T
T{ -1 2 1 */ -> -1 2 1 t*/ }T
T{ -2 2 1 */ -> -2 2 1 t*/ }T
T{ 0 2 -1 */ -> 0 2 -1 t*/ }T
T{ 1 2 -1 */ -> 1 2 -1 t*/ }T
T{ 2 2 -1 */ -> 2 2 -1 t*/ }T
T{ -1 2 -1 */ -> -1 2 -1 t*/ }T
T{ -2 2 -1 */ -> -2 2 -1 t*/ }T
T{ 2 2 2 */ -> 2 2 2 t*/ }T
T{ -1 2 -1 */ -> -1 2 -1 t*/ }T
T{ -2 2 -2 */ -> -2 2 -2 t*/ }T
T{ 7 2 3 */ -> 7 2 3 t*/ }T
T{ 7 2 -3 */ -> 7 2 -3 t*/ }T
T{ -7 2 3 */ -> -7 2 3 t*/ }T
T{ -7 2 -3 */ -> -7 2 -3 t*/ }T
T{ max-int 2 max-int */ -> max-int 2 max-int t*/ }T
T{ min-int 2 min-int */ -> min-int 2 min-int t*/ }T

T{ 0 2 1 */mod -> 0 2 1 t*/mod }T
T{ 1 2 1 */mod -> 1 2 1 t*/mod }T
T{ 2 2 1 */mod -> 2 2 1 t*/mod }T
T{ -1 2 1 */mod -> -1 2 1 t*/mod }T
T{ -2 2 1 */mod -> -2 2 1 t*/mod }T
T{ 0 2 -1 */mod -> 0 2 -1 t*/mod }T
T{ 1 2 -1 */mod -> 1 2 -1 t*/mod }T
T{ 2 2 -1 */mod -> 2 2 -1 t*/mod }T
T{ -1 2 -1 */mod -> -1 2 -1 t*/mod }T
T{ -2 2 -1 */mod -> -2 2 -1 t*/mod }T
T{ 2 2 2 */mod -> 2 2 2 t*/mod }T
T{ -1 2 -1 */mod -> -1 2 -1 t*/mod }T
T{ -2 2 -2 */mod -> -2 2 -2 t*/mod }T
T{ 7 2 3 */mod -> 7 2 3 t*/mod }T
T{ 7 2 -3 */mod -> 7 2 -3 t*/mod }T
T{ -7 2 3 */mod -> -7 2 3 t*/mod }T
T{ -7 2 -3 */mod -> -7 2 -3 t*/mod }T
T{ max-int 2 max-int */mod -> max-int 2 max-int t*/mod }T
T{ min-int 2 min-int */mod -> min-int 2 min-int t*/mod }T

core_a_tests
