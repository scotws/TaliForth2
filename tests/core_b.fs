marker core_b_tests
\ Words from core_a.fs, needed by tests below.
0 constant 0s
0 invert constant 1s
0s constant <false>
1s constant <true>
1s 1 rshift invert constant msb
0 invert 1 rshift  constant mid-uint
0 invert 1 rshift invert  constant mid-uint+1

\ ------------------------------------------------------------------------
testing here , @ ! cell+ cells c, c@ c! char+ chars 2@ 2! align aligned +! allot pad unused compile,
decimal
here 1 allot
here
9 allot                     \ Growing by 9 and shrinking
-10 allot                    \ by 10 should bring us back
here                        \ to where we started.
constant 3rda
constant 2nda
constant 1sta
T{ 1sta 2nda u< -> <true> }T  \ here must grow with allot ...
T{ 1sta 1+ -> 2nda }T         \ ... by one address unit
T{ 3rda -> 1sta }T            \ and shrink back to the beginning.
hex

here 1 ,
here 2 ,
constant 2nd
constant 1st
T{ 1st 2nd u< -> <true> }T \ here must grow with allot ...
T{ 1st cell+ -> 2nd }T     \ ... by one cell (test for char+)
T{ 1st 1 cells + -> 2nd }T
T{ 1st @ 2nd @ -> 1 2 }T
T{ 5 1st ! -> }T
T{ 1st @ 2nd @ -> 5 2 }T
T{ 6 2nd ! -> }T
T{ 1st @ 2nd @ -> 5 6 }T
T{ 1st 2@ -> 6 5 }T
T{ 2 1 1st 2! -> }T
T{ 1st 2@ -> 2 1 }T
T{ 1s 1st !  1st @ -> 1s }T  \ can store cell-wide value

here 1 c,
here 2 c,
constant 2ndc
constant 1stc
T{ 1stc 2ndc u< -> <true> }T \ here must grow with allot
T{ 1stc char+ -> 2ndc }T     \ ... by one char
T{ 1stc 1 chars + -> 2ndc }T
T{ 1stc c@ 2ndc c@ -> 1 2 }T
T{ 3 1stc c! -> }T
T{ 1stc c@ 2ndc c@ -> 3 2 }T
T{ 4 2ndc c! -> }T
T{ 1stc c@ 2ndc c@ -> 3 4 }T

align 1 allot here align here 3 cells allot
constant a-addr  constant ua-addr
T{ ua-addr aligned -> a-addr }T
T{ 1 a-addr c!  a-addr c@ -> 1 }T
T{ 1234 a-addr  !  a-addr  @ -> 1234 }T
T{ 123 456 a-addr 2!  a-addr 2@ -> 123 456 }T
T{ 2 a-addr char+ c!  a-addr char+ c@ -> 2 }T
T{ 3 a-addr cell+ c!  a-addr cell+ c@ -> 3 }T
T{ 1234 a-addr cell+ !  a-addr cell+ @ -> 1234 }T
T{ 123 456 a-addr cell+ 2!  a-addr cell+ 2@ -> 123 456 }T

: bits ( x -- u )
   0 swap begin
   dup while 
      dup msb and if
         >r 1+ r> 
      then 2* 
   repeat 
   drop ;

( characters >= 1 au, <= size of cell, >= 8 bits )
T{ 1 chars 1 < -> <false> }T
T{ 1 chars 1 cells > -> <false> }T
( TODO how to find number of bits? )

( cells >= 1 au, integral multiple of char size, >= 16 bits )
T{ 1 cells 1 < -> <false> }T
T{ 1 cells 1 chars mod -> 0 }T
T{ 1s bits 10 < -> <false> }T

T{ 0 1st ! -> }T
T{ 1 1st +! -> }T
T{ 1st @ -> 1 }T
T{ -1 1st +! 1st @ -> 0 }T

( here + unused + buffer size must be total RAM, that is, $7FFF )
T{ pad here - -> FF }T \ PAD must have offset of $FF
T{ here unused + 3FF + -> 7FFF }T

:noname dup + ; constant dup+ 
T{ : q dup+ compile, ; -> }T 
T{ : as [ q ] ; -> }T 
T{ 123 as -> 246 }T

\ ------------------------------------------------------------------------
testing char [char] [ ] bl s" s\"

T{ bl -> 20 }T
T{ char X -> 58 }T
T{ char HELLO -> 48 }T
T{ : gc1 [char] X ; -> }T
T{ : gc2 [char] HELLO ; -> }T
T{ gc1 -> 58 }T
T{ gc2 -> 48 }T
T{ : gc3 [ gc1 ] literal ; -> }T
T{ gc3 -> 58 }T
T{ : gc4 s" XY" ; -> }T
T{ gc4 swap drop -> 2 }T
T{ gc4 drop dup c@ swap char+ c@ -> 58 59 }T

\ Test s\"
decimal
create result
 7 c, ( \a )
 8 c, ( \b )
27 c, ( \e )
12 c, ( \f )
10 c, ( \l )
13 c, 10 c, ( \m )
10 c, ( \n - Tali does just a linefeed for \n )
34 c, ( \q )
13 c, ( \r )
 9 c, ( \t )
11 c, ( \v )
 0 c, ( \z )
34 c, ( \" )
65 c, ( \x41 )
92 c, ( \\ )

T{ result here result - 2dup dump ( Make a string out of result )
   s\" \a\b\e\f\l\m\n\q\r\t\v\z\"\x41\\" 2dup dump compare -> 0 }T
hex

\ ------------------------------------------------------------------------
testing ' ['] find execute immediate count literal postpone state

T{ : gt1 123 ; -> }T
T{ ' gt1 execute -> 123 }T
T{ : gt2 ['] gt1 ; immediate -> }T
T{ gt2 execute -> 123 }T
here 3 c, char g c, char t c, char 1 c, constant gt1string
here 3 c, char g c, char t c, char 2 c, constant gt2string
T{ gt1string find -> ' gt1 -1 }T
T{ gt2string find -> ' gt2 1 }T
( TODO how to search for non-existent word? )
T{ : gt3 gt2 literal ; -> }T
T{ gt3 -> ' gt1 }T
T{ gt1string count -> gt1string char+ 3 }T

T{ : gt4 postpone gt1 ; immediate -> }T
T{ : gt5 gt4 ; -> }T
T{ gt5 -> 123 }T
T{ : gt6 345 ; immediate -> }T
T{ : gt7 postpone gt6 ; -> }T
T{ gt7 -> 345 }T

T{ : gt8 state @ ; immediate -> }T
T{ gt8 -> 0 }T
T{ : gt9 gt8 literal ; -> }T
T{ gt9 0= -> <false> }T

\ ------------------------------------------------------------------------
testing if else then begin while repeat until recurse

T{ : gi1 if 123 then ; -> }T
T{ : gi2 if 123 else 234 then ; -> }T
T{ 0 gi1 -> }T
T{ 1 gi1 -> 123 }T
T{ -1 gi1 -> 123 }T
T{ 0 gi2 -> 234 }T
T{ 1 gi2 -> 123 }T
T{ -1 gi1 -> 123 }T

T{ : gi3 begin dup 5 < while dup 1+ repeat ; -> }T
T{ 0 gi3 -> 0 1 2 3 4 5 }T
T{ 4 gi3 -> 4 5 }T
T{ 5 gi3 -> 5 }T
T{ 6 gi3 -> 6 }T

T{ : gi4 begin dup 1+ dup 5 > until ; -> }T
T{ 3 gi4 -> 3 4 5 6 }T
T{ 5 gi4 -> 5 6 }T
T{ 6 gi4 -> 6 7 }T

T{ : gi5 begin dup 2 > while dup 5 < while dup 1+ repeat 123 else 345 then ; -> }T
T{ 1 gi5 -> 1 345 }T
T{ 2 gi5 -> 2 345 }T
T{ 3 gi5 -> 3 4 5 123 }T
T{ 4 gi5 -> 4 5 123 }T
T{ 5 gi5 -> 5 123 }T

T{ : gi6 ( n -- 0,1,..n ) dup if dup >r 1- recurse r> then ; -> }T
T{ 0 gi6 -> 0 }T
T{ 1 gi6 -> 0 1 }T
T{ 2 gi6 -> 0 1 2 }T
T{ 3 gi6 -> 0 1 2 3 }T
T{ 4 gi6 -> 0 1 2 3 4 }T

decimal
T{ :noname ( n -- 0, 1, .., n ) 
     dup if dup >r 1- recurse r> then 
   ; 
   constant rn1 -> }T
T{ 0 rn1 execute -> 0 }T
T{ 4 rn1 execute -> 0 1 2 3 4 }T

:noname ( n -- n1 )
   1- dup
   case 0 of exit endof
     1 of 11 swap recurse endof
     2 of 22 swap recurse endof
     3 of 33 swap recurse endof
     drop abs recurse exit
   endcase
; constant rn2

T{  1 rn2 execute -> 0 }T
T{  2 rn2 execute -> 11 0 }T
T{  4 rn2 execute -> 33 22 11 0 }T
T{ 25 rn2 execute -> 33 22 11 0 }T
hex

\ ------------------------------------------------------------------------
testing case of endof endcase

: cs1 case 
   1 of 111 endof
   2 of 222 endof
   3 of 333 endof
   4 of 444 endof
   5 of 555 endof
   6 of 666 endof
   7 of 777 endof
   >r 999 r>
   endcase
;

T{ 1 cs1 -> 111 }T
T{ 2 cs1 -> 222 }T
T{ 3 cs1 -> 333 }T
T{ 4 cs1 -> 444 }T
T{ 5 cs1 -> 555 }T
T{ 6 cs1 -> 666 }T
T{ 7 cs1 -> 777 }T
T{ 8 cs1 -> 999 }T \ default

: cs2 >r case

   -1 of case r@ 1 of 100 endof
                2 of 200 endof
                >r -300 r>
        endcase
     endof
   -2 of case r@ 1 of -99 endof
                >r -199 r>
        endcase
     endof
     >r 299 r>
   endcase r> drop ;

T{ -1 1 cs2 ->  100 }T
T{ -1 2 cs2 ->  200 }T
T{ -1 3 cs2 -> -300 }T
T{ -2 1 cs2 ->  -99 }T
T{ -2 2 cs2 -> -199 }T
T{  0 2 cs2 ->  299 }T

\ ------------------------------------------------------------------------
testing do loop +loop i j unloop leave exit ?do

T{ : gd1 do i loop ; -> }T
T{ 4 1 gd1 -> 1 2 3 }T
T{ 2 -1 gd1 -> -1 0 1 }T
T{ mid-uint+1 mid-uint gd1 -> mid-uint }T

T{ : gd2 do i -1 +loop ; -> }T
T{ 1 4 gd2 -> 4 3 2 1 }T
T{ -1 2 gd2 -> 2 1 0 -1 }T
T{ mid-uint mid-uint+1 gd2 -> mid-uint+1 mid-uint }T

T{ : gd3 do 1 0 do j loop loop ; -> }T
T{ 4 1 gd3 -> 1 2 3 }T
T{ 2 -1 gd3 -> -1 0 1 }T
T{ mid-uint+1 mid-uint gd3 -> mid-uint }T

T{ : gd4 do 1 0 do j loop -1 +loop ; -> }T
T{ 1 4 gd4 -> 4 3 2 1 }T
T{ -1 2 gd4 -> 2 1 0 -1 }T
T{ mid-uint mid-uint+1 gd4 -> mid-uint+1 mid-uint }T

T{ : gd5 123 swap 0 do i 4 > if drop 234 leave then loop ; -> }T
T{ 1 gd5 -> 123 }T
T{ 5 gd5 -> 123 }T
T{ 6 gd5 -> 234 }T

T{ : gd6  ( pat: T{0 0}T,T{0 0}TT{1 0}TT{1 1}T,T{0 0}TT{1 0}TT{1 1}TT{2 0}TT{2 1}TT{2 2}T )
   0 swap 0 do
      i 1+ 0 do i j + 3 = if i unloop i unloop exit then 1+ loop
    loop ; -> }T
T{ 1 gd6 -> 1 }T
T{ 2 gd6 -> 3 }T
T{ 3 gd6 -> 4 1 2 }T

: qd ?do i loop ; 
T{   789   789 qd -> }T 
T{ -9876 -9876 qd -> }T 
T{     5     0 qd -> 0 1 2 3 4 }T

: qd1 ?do i 10 +loop ; 
T{ 50 1 qd1 -> 1 11 21 31 41 }T 
T{ 50 0 qd1 -> 0 10 20 30 40 }T

: qd2 ?do i 3 > if leave else i then loop ; 
T{ 5 -1 qd2 -> -1 0 1 2 3 }T

: qd3 ?do i 1 +loop ; 
T{ 4  4 qd3 -> }T 
T{ 4  1 qd3 ->  1 2 3 }T
T{ 2 -1 qd3 -> -1 0 1 }T

: qd4 ?do i -1 +loop ; 
T{  4 4 qd4 -> }T
T{  1 4 qd4 -> 4 3 2  1 }T 
T{ -1 2 qd4 -> 2 1 0 -1 }T

: qd5 ?do i -10 +loop ; 
T{   1 50 qd5 -> 50 40 30 20 10   }T 
T{   0 50 qd5 -> 50 40 30 20 10 0 }T 
T{ -25 10 qd5 -> 10 0 -10 -20     }T

variable qditerations 
variable qdincrement

: qd6 ( limit start increment -- )    qdincrement ! 
   0 qditerations ! 
   ?do 
     1 qditerations +! 
     i 
     qditerations @ 6 = if leave then 
     qdincrement @ 
   +loop qditerations @ 
;

T{  4  4 -1 qd6 ->                   0  }T 
T{  1  4 -1 qd6 ->  4  3  2  1       4  }T 
T{  4  1 -1 qd6 ->  1  0 -1 -2 -3 -4 6  }T 
T{  4  1  0 qd6 ->  1  1  1  1  1  1 6  }T 
T{  0  0  0 qd6 ->                   0  }T 
T{  1  4  0 qd6 ->  4  4  4  4  4  4 6  }T 
T{  1  4  1 qd6 ->  4  5  6  7  8  9 6  }T 
T{  4  1  1 qd6 ->  1  2  3          3  }T 
T{  4  4  1 qd6 ->                   0  }T 
T{  2 -1 -1 qd6 -> -1 -2 -3 -4 -5 -6 6  }T 
T{ -1  2 -1 qd6 ->  2  1  0 -1       4  }T 
T{  2 -1  0 qd6 -> -1 -1 -1 -1 -1 -1 6  }T 
T{ -1  2  0 qd6 ->  2  2  2  2  2  2 6  }T 
T{ -1  2  1 qd6 ->  2  3  4  5  6  7 6  }T 
T{  2 -1  1 qd6 -> -1  0  1          3  }T

\ ------------------------------------------------------------------------
testing defining words: : ; constant variable create does> >body value to

T{ 123 constant x123 -> }T
T{ x123 -> 123 }T
T{ : equ constant ; -> }T
T{ x123 equ y123 -> }T
T{ y123 -> 123 }T

T{ variable v1 -> }T
T{ 123 v1 ! -> }T
T{ v1 @ -> 123 }T

T{ : nop : postpone ; ; -> }T
T{ nop nop1 nop nop2 -> }T
T{ nop1 -> }T
T{ nop2 -> }T

T{ : does1 does> @ 1 + ; -> }T
T{ : does2 does> @ 2 + ; -> }T
T{ create cr1 -> }T
T{ cr1 -> here }T
T{ ' cr1 >body -> here }T
T{ 1 , -> }T
T{ cr1 @ -> 1 }T
T{ does1 -> }T
T{ cr1 -> 2 }T
T{ does2 -> }T
T{ cr1 -> 3 }T

\ The following test is not part of the original suite, but belongs
\ to the "weird:" test following it. See discussion at
\ https://github.com/scotws/TaliForth2/issues/61
T{ : odd: create does> 1 + ; -> }T
T{ odd: o1 -> }T
T{ ' o1 >body -> here }T
T{ o1 -> here 1 + }T

T{ : weird: create does> 1 + does> 2 + ; -> }T
T{ weird: w1 -> }T
T{ ' w1 >body -> here }T
T{ w1 -> here 1 + }T
T{ w1 -> here 2 + }T

T{  111 value v1 -> }T
T{ -999 value v2 -> }T
T{ v1 ->  111 }T
T{ v2 -> -999 }T 
T{ 222 to v1 -> }T 
T{ v1 -> 222 }T
T{ : vd1 v1 ; -> }T
T{ vd1 -> 222 }T

T{ : vd2 to v2 ; -> }T
T{ v2 -> -999 }T
T{ -333 vd2 -> }T
T{ v2 -> -333 }T
T{ v1 ->  222 }T

\ ------------------------------------------------------------------------
testing evaluate

: ge1 s" 123" ; immediate
: ge2 s" 123 1+" ; immediate
: ge3 s" : ge4 345 ;" ;
: ge5 evaluate ; immediate

T{ ge1 evaluate -> 123 }T \ test evaluate in interp. state
T{ ge2 evaluate -> 124 }T
T{ ge3 evaluate -> }T
T{ ge4 -> 345 }T

T{ : ge6 ge1 ge5 ; -> }T  \ test evaluate in compile state
T{ ge6 -> 123 }T
T{ : ge7 ge2 ge5 ; -> }T
T{ ge7 -> 124 }T

core_b_tests
