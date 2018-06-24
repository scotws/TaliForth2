\ ------------------------------------------------------------------------
testing double words: 2constant 2variable d+ d- d. d.r d>s dabs dnegate
decimal

{ 2variable 2v1 -> }
{ 0. 2v1 2! -> }
{ 2v1 2@ -> 0. }
{ -1 -2 2v1 2! -> }
{ 2v1 2@ -> -1 -2 }
{ : cd2 2variable ; -> }
{ cd2 2v2 -> }
{ : cd3 2v2 2! ; -> }
{ -2 -1 cd3 -> }
{ 2v2 2@ -> -2 -1 }
{ 2variable 2v3 immediate 5 6 2v3 2! -> }
{ 2v3 2@ -> 5 6 }

\ Repeats in case we call this test alone
0 constant 0s
0 invert constant 1s
0 invert 1 rshift  constant max-int
0 invert 1 rshift invert  constant min-int

{  0.  5. d+ ->  5. }                         \ small integers 
{ -5.  0. d+ -> -5. } 
{  1.  2. d+ ->  3. } 
{  1. -2. d+ -> -1. } 
{ -1.  2. d+ ->  1. } 
{ -1. -2. d+ -> -3. } 
{ -1.  1. d+ ->  0. }
{  0  0  0  5 d+ ->  0  5 }                  \ mid range integers 
{ -1  5  0  0 d+ -> -1  5 } 
{  0  0  0 -5 d+ ->  0 -5 } 
{  0 -5 -1  0 d+ -> -1 -5 } 
{  0  1  0  2 d+ ->  0  3 } 
{ -1  1  0 -2 d+ -> -1 -1 } 
{  0 -1  0  2 d+ ->  0  1 } 
{  0 -1 -1 -2 d+ -> -1 -3 } 
{ -1 -1  0  1 d+ -> -1  0 }

{ min-int 0 2dup d+ -> 0 1 }
{ min-int s>d min-int 0 d+ -> 0 0 }

{ 1 2 2constant 2c1 -> }
{ 2c1 -> 1 2 }
{ : cd1 2c1 ; -> }
{ cd1 -> 1 2 }
{ : cd2 2constant ; -> }
{ -1 -2 cd2 2c2 -> }
{ 2c2 -> -1 -2 }
{ 4 5 2constant 2c3 immediate 2c3 -> 4 5 }
{ : cd6 2c3 2literal ; cd6 -> 4 5 }

max-int 2/ constant hi-int \ 001...1 
min-int 2/ constant lo-int \ 110...1

1s max-int  2constant max-2int \ 01...1 
0 min-int   2constant min-2int \ 10...0 
max-2int 2/ 2constant hi-2int  \ 001...1 
min-2int 2/ 2constant lo-2int  \ 110...0

{ : cd1 [ max-2int ] 2literal ; -> }
{ cd1 -> max-2int }
{ 2variable 2v4 immediate 5 6 2v4 2! -> }
{ : cd7 2v4 [ 2@ ] 2literal ; cd7 -> 5 6 }
{ : cd8 [ 6 7 ] 2v4 [ 2! ] ; 2v4 2@ -> 6 7 }

{  hi-2int       1. d+ -> 0 hi-int 1+ }     \ large double integers 
{  hi-2int     2dup d+ -> 1s 1- max-int }
{ max-2int min-2int d+ -> -1. }
{ max-2int  lo-2int d+ -> hi-2int }
{  lo-2int     2dup d+ -> min-2int }
{  hi-2int min-2int d+ 1. d+ -> lo-2int }

{  0.  5. d- -> -5. }              \ small integers 
{  5.  0. d- ->  5. } 
{  0. -5. d- ->  5. } 
{  1.  2. d- -> -1. } 
{  1. -2. d- ->  3. } 
{ -1.  2. d- -> -3. } 
{ -1. -2. d- ->  1. } 
{ -1. -1. d- ->  0. } 
{  0  0  0  5 d- ->  0 -5 }        \ mid-range integers 
{ -1  5  0  0 d- -> -1  5 } 
{  0  0 -1 -5 d- ->  1  4 } 
{  0 -5  0  0 d- ->  0 -5 } 
{ -1  1  0  2 d- -> -1 -1 } 
{  0  1 -1 -2 d- ->  1  2 } 
{  0 -1  0  2 d- ->  0 -3 } 
{  0 -1  0 -2 d- ->  0  1 } 
{  0  0  0  1 d- ->  0 -1 }
{ min-int 0 2dup d- -> 0. } 
{ min-int s>d max-int 0 d- -> 1 1s } 

{ max-2int max-2int d- -> 0. }    \ large integers 
{ min-2int min-2int d- -> 0. }
{ max-2int  hi-2int d- -> lo-2int dnegate } 
{  hi-2int  lo-2int d- -> max-2int }
{  lo-2int  hi-2int d- -> min-2int 1. d+ }
{ min-2int min-2int d- -> 0. }
{ min-2int  lo-2int d- -> lo-2int }

( TODO m*/ not implemented ) 

\ max-2int 71 73 m*/ 2constant dbl1 
\ min-2int 73 79 m*/ 2constant dbl2
\ : d>ascii ( d -- caddr u ) 
   \ dup >r <# dabs #s r> sign #>    ( -- caddr1 u ) 
   \ here swap 2dup 2>r chars dup allot move 2r> 
\ ;

\ dbl1 d>ascii 2constant "dbl1" 
\ dbl2 d>ascii 2constant "dbl2"

\ : doubleoutput 
   \ cr ." you should see lines duplicated:" cr 
   \ 5 spaces "dbl1" type cr 
   \ 5 spaces dbl1 d. cr 
   \ 8 spaces "dbl1" dup >r type cr 
   \ 5 spaces dbl1 r> 3 + d.r cr 
   \ 5 spaces "dbl2" type cr 
   \ 5 spaces dbl2 d. cr 
   \ 10 spaces "dbl2" dup >r type cr 
   \ 5 spaces dbl2 r> 5 + d.r cr 
\ ;

\ { doubleoutput -> }

( TODO D0< not implemented yet )
( TODO D0= not implemented yet )
( TODO D2* not implemented yet )
( TODO D2/ not implemented yet )
( TODO D< not implemented yet )
( TODO D= not implemented yet )

{    1234  0 d>s ->  1234   } 
{   -1234 -1 d>s -> -1234   } 
{ max-int  0 d>s -> max-int } 
{ min-int -1 d>s -> min-int }

{       1. dabs -> 1.       } 
{      -1. dabs -> 1.       } 
{ max-2int dabs -> max-2int } 
{ min-2int 1. d+ dabs -> max-2int }

( TODO DMAX not implemented yet )
( TODO DMIN not implemented yet )

{ 0. dnegate -> 0. }
{ 1. dnegate -> -1. }
{ -1. dnegate -> 1. }
{ max-2int dnegate -> min-2int swap 1+ swap }
{ min-2int swap 1+ swap dnegate -> max-2int }

( TODO M*/ not implemented yet )
( TODO M+ not implemented yet )
( TODO 2ROT not implemented yet )
( TODO 2VALUE not implemented yet )
( TODO DU< not implemented yet )


