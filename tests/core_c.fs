marker core_c_tests
\ Words from core_a.fs, needed by tests below.
0 constant 0s
0 invert constant 1s
0s constant <false>
1s constant <true>
0 invert  constant max-uint
0 invert 1 rshift  constant max-int
0 invert 1 rshift invert  constant min-int
\ ------------------------------------------------------------------------
testing source >in word
hex
: gs1 s" source" 2dup evaluate 
       >r swap >r = r> r> = ;
T{ gs1 -> <true> <true> }T

variable scans
: rescan?  -1 scans +!
   scans @ if
      0 >in !
   then ;

T{ 2 scans !  
345 rescan?  
-> 345 345 }T

: gs2  5 scans ! s" 123 rescan?" evaluate ;
T{ gs2 -> 123 123 123 123 123 }T

: gs3 word count swap c@ ;
T{ bl gs3 hello -> 5 char h }T
T{ char " gs3 goodbye" -> 7 char g }T
T{ bl gs3 
drop -> 0 }T \ blank line return zero-length string

: gs4 source >in ! drop ;
T{ gs4 123 456 
-> }T

\ ------------------------------------------------------------------------
testing <# # #s #> hold sign base >number hex decimal
hex

\ compare two strings.
: s=  ( addr1 c1 addr2 c2 -- t/f ) 
   >r swap r@ = if \ make sure strings have same length
      r> ?dup if   \ if non-empty strings
         0 do
            over c@ over c@ - if
               2drop <false> unloop exit
            then
            swap char+ swap char+
         loop
      then
      2drop <true> \ if we get here, strings match
   else
      r> drop 2drop <false>  \ lengths mismatch
   then ;

: gp1  <# 41 hold 42 hold 0 0 #> s" BA" s= ;
T{ gp1 -> <true> }T

: gp2  <# -1 sign 0 sign -1 sign 0 0 #> s" --" s= ;
T{ gp2 -> <true> }T

: gp3  <# 1 0 # # #> s" 01" s= ;
T{ gp3 -> <true> }T

: gp4  <# 1 0 #s #> s" 1" s= ;
T{ gp4 -> <true> }T

24 constant max-base   \ base 2 .. 36
max-base .( max-base post def: ) . cr  ( TODO TEST )
: count-bits
   0 0 invert 
   begin 
      dup while
      >r 1+ r> 2* 
   repeat 
   drop ;

count-bits 2* constant #bits-ud  \ number of bits in ud

: gp5
   base @ <true>
   max-base 1+ 2 do   \ for each possible base
      i base !    \ tbd: assumes base works
      i 0 <# #s #> s" 10" s= and
   loop
   swap base ! ;
T{ gp5 -> <true> }T

: gp6
   base @ >r  2 base !
   max-uint max-uint <# #s #>  \ maximum ud to binary
   r> base !    \ s: c-addr u
   dup #bits-ud = swap
   0 do     \ s: c-addr flag
      over c@ [char] 1 = and  \ all ones
      >r char+ r>
   loop swap drop ;
T{ gp6 -> <true> }T


\ Split up long testing word from ANS Forth in two parts
\ to figure out what is wrong

\ Test the numbers 0 to 15 in max-base
: gp7-1
   base @ >r  
   max-base base !
   <true>

   a 0 do
      i 0 <# #s #>
      1 = swap c@ i 30 + = and and
   loop
   
   r> base ! ;

T{ gp7-1 -> <true> }T

\ Test the numbers 16 to max-base in max-base
: gp7-2
   base @ >r  
   max-base base !
   <true>

   max-base a do
      i 0 <# #s #>
      2dup type cr ( TODO TEST )
      1 = swap c@ 41 i a - + = and and
      .s cr ( TODO TEST )
   loop

   r> base ! ;

T{ gp7-2 -> <true> }T

\ >number tests
create gn-buf 0 c,
: gn-string gn-buf 1 ;
: gn-consumed gn-buf char+ 0 ;
: gn'  [char] ' word char+ c@ gn-buf c!  gn-string ;

T{ 0 0 gn' 0' >number -> 0 0 gn-consumed }T
T{ 0 0 gn' 1' >number -> 1 0 gn-consumed }T
T{ 1 0 gn' 1' >number -> base @ 1+ 0 gn-consumed }T
T{ 0 0 gn' -' >number -> 0 0 gn-string }T \ should fail to convert these
T{ 0 0 gn' +' >number -> 0 0 gn-string }T
T{ 0 0 gn' .' >number -> 0 0 gn-string }T

: >number-based  base @ >r base ! >number r> base ! ;

T{ 0 0 gn' 2' 10 >number-based -> 2 0 gn-consumed }T
T{ 0 0 gn' 2'  2 >number-based -> 0 0 gn-string }T
T{ 0 0 gn' f' 10 >number-based -> f 0 gn-consumed }T
T{ 0 0 gn' g' 10 >number-based -> 0 0 gn-string }T
T{ 0 0 gn' g' max-base >number-based -> 10 0 gn-consumed }T
T{ 0 0 gn' z' max-base >number-based -> 23 0 gn-consumed }T

\ ud should equal ud' and len should be zero.
: gn1  ( ud base -- ud' len ) 
   base @ >r base !
   <# #s #>
   0 0 2swap >number swap drop  \ return length only
   r> base ! ;

T{ 0 0 2 gn1 -> 0 0 0 }T
T{ max-uint 0 2 gn1 -> max-uint 0 0 }T
T{ max-uint dup 2 gn1 -> max-uint dup 0 }T

T{ 0 0 max-base gn1 -> 0 0 0 }T
T{ max-uint 0 max-base gn1 -> max-uint 0 0 }T
T{ max-uint dup max-base gn1 -> max-uint dup 0 }T

: gn2 ( -- 16 10 )
   base @ >r  hex base @  decimal base @  r> base ! ;

T{ gn2 -> 10 a }T

\ ------------------------------------------------------------------------
testing action-of defer defer! defer@ is

T{ defer defer1 -> }T
T{ : action-defer1 action-of defer1 ; -> }T
T{ ' * ' defer1 defer! ->   }T
T{          2 3 defer1 -> 6 }T
T{ action-of defer1 -> ' * }T 
T{    action-defer1 -> ' * }T

T{ ' + is defer1 ->   }T
T{    1 2 defer1 -> 3 }T 
T{ action-of defer1 -> ' + }T
T{    action-defer1 -> ' + }T

T{ defer defer2 ->   }T 
T{ ' * ' defer2 defer! -> }T
T{   2 3 defer2 -> 6 }T
T{ ' + is defer2 ->   }T
T{    1 2 defer2 -> 3 }T

T{ defer defer3 -> }T
T{ ' * ' defer3 defer! -> }T
T{ 2 3 defer3 -> 6 }T
T{ ' + ' defer3 defer! -> }T
T{ 1 2 defer3 -> 3 }T

T{ defer defer4 -> }T
T{ ' * ' defer4 defer! -> }T
T{ 2 3 defer4 -> 6 }T
T{ ' defer4 defer@ -> ' * }T

T{ ' + is defer4 -> }T 
T{ 1 2 defer4 -> 3 }T 
T{ ' defer4 defer@ -> ' + }T

T{ defer defer5 -> }T
T{ : is-defer5 is defer5 ; -> }T
T{ ' * is defer5 -> }T
T{ 2 3 defer5 -> 6 }T
T{ ' + is-defer5 -> }T 
T{ 1 2 defer5 -> 3 }T

\ ------------------------------------------------------------------------
testing fill move

create fbuf 00 c, 00 c, 00 c,
create sbuf 12 c, 34 c, 56 c,
: seebuf fbuf c@  fbuf char+ c@  fbuf char+ char+ c@ ;

T{ fbuf 0 20 fill -> }T
T{ seebuf -> 00 00 00 }T

T{ fbuf 1 20 fill -> }T
T{ seebuf -> 20 00 00 }T

T{ fbuf 3 20 fill -> }T
T{ seebuf -> 20 20 20 }T

T{ fbuf fbuf 3 chars move -> }T  \ bizarre special case
T{ seebuf -> 20 20 20 }T

T{ sbuf fbuf 0 chars move -> }T
T{ seebuf -> 20 20 20 }T

T{ sbuf fbuf 1 chars move -> }T
T{ seebuf -> 12 20 20 }T

T{ sbuf fbuf 3 chars move -> }T
T{ seebuf -> 12 34 56 }T

T{ fbuf fbuf char+ 2 chars move -> }T
T{ seebuf -> 12 12 34 }T

T{ fbuf char+ fbuf 2 chars move -> }T
T{ seebuf -> 12 34 34 }T

\ CMOVE and CMOVE> propogation tests taken from 
\ https://forth-standard.org/standard/string/CMOVE and .../CMOVEtop
decimal
create cmbuf  97 c, 98 c, 99 c, 100 c, \ "abcd"
: seecmbuf  cmbuf c@  cmbuf char+ c@  cmbuf char+ char+ c@  cmbuf char+ char+ char+ c@ ;
T{ cmbuf dup char+ 3 cmove -> }T
T{ seecmbuf -> 97 97 97 97 }T \ "aaaa"

create cmubuf  97 c, 98 c, 99 c, 100 c, \ "abcd"
: seecmubuf  cmubuf c@  cmubuf char+ c@  cmubuf char+ char+ c@  cmubuf char+ char+ char+ c@ ;
T{ cmubuf dup char+ swap 3 cmove> -> }T
T{ seecmubuf -> 100 100 100 100 }T \ "dddd"

\ ------------------------------------------------------------------------
testing output: . ." cr emit space spaces type u.
hex

: output-test
   ." you should see the standard graphic characters:" cr
   41 bl do i emit loop cr
   61 41 do i emit loop cr
   7f 61 do i emit loop cr
   ." you should see 0-9 separated by a space:" cr
   9 1+ 0 do i . loop cr
   ." you should see 0-9 (with no spaces):" cr
   [char] 9 1+ [char] 0 do i 0 spaces emit loop cr
   ." you should see a-g separated by a space:" cr
   [char] g 1+ [char] a do i emit space loop cr
   ." you should see 0-5 separated by two spaces:" cr
   5 1+ 0 do i [char] 0 + emit 2 spaces loop cr
   ." you should see two separate lines:" cr
   s" line 1" type cr s" line 2" type cr
   ." you should see the number ranges of signed and unsigned numbers:" cr
   ."   signed: " min-int . max-int . cr
   ." unsigned: " 0 u. max-uint u. cr
;

T{ output-test -> }T

\ ------------------------------------------------------------------------
testing parse-name marker erase

\ Careful editing these, whitespace is significant
T{ parse-name abcd s" abcd" s= -> <true> }T 
T{ parse-name   abcde   s" abcde" s= -> <true> }T \ test empty parse area 
T{ parse-name  abcde s" abcde" s= -> <true> }T \ test TABS instead of spaces
T{ parse-name 
   nip -> 0 }T    \ empty line 
T{ parse-name    
   nip -> 0 }T    \ line with white space
T{ : parse-name-test ( "name1" "name2" -- n ) 
   parse-name parse-name s= ; -> }T
T{ parse-name-test abcd abcd -> <true> }T 
T{ parse-name-test  abcd   abcd   -> <true> }T 
T{ parse-name-test abcde abcdf -> <false> }T 
T{ parse-name-test abcdf abcde -> <false> }T 
T{ parse-name-test abcde abcde 
    -> <true> }T 
T{ parse-name-test abcde abcde  
    -> <true> }T    \ line with white space

\ There is no official ANS test for MARKER, added 22. June 2018
\ TODO There is currently no test for FIND-NAME, taking it on faith here
T{ variable marker_size -> }T
T{ unused marker_size ! -> }T
T{ marker quarian -> }T
: marker_test ." Bosh'tet!" ;
T{ marker_test -> }T \ should print "Bosh'tet!"
T{ quarian -> }T 
T{ parse-name marker_test find-name -> 0 }T 
T{ marker_size @ unused = -> <true> }T

\ There is no official ANS test of ERASE, added 01. July 2018
T{ create erase_test -> }T
T{ 9 c, 1 c, 2 c, 3 c, 9 c, -> }T
T{ erase_test 1+ 3 erase -> }T  \ Erase bytes between 9 
T{ erase_test            c@ 9 = -> <true> }T
T{ erase_test 1 chars +  c@ 0 = -> <true> }T
T{ erase_test 2 chars +  c@ 0 = -> <true> }T
T{ erase_test 3 chars +  c@ 0 = -> <true> }T
T{ erase_test 4 chars +  c@ 9 = -> <true> }T


\ ------------------------------------------------------------------------
testing environment

\ This is from the ANS Forth specification at 
\ https://forth-standard.org/standard/core/ENVIRONMENTq but the first
\ test is commented out because it doesn't seem to make sense
\ T{ s" x:deferred" environment? dup 0= xor invert -> <true>  }T ( Huh? Why true? )
T{ s" x:notfound" environment? dup 0= xor invert -> <false> }T

\ These were added for Tali Forth 10. Aug 2018
hex
T{ s" /COUNTED-STRING"    environment? ->    7FFF <true> }T
T{ s" /HOLD"              environment? ->      FF <true> }T
T{ s" /PAD"               environment? ->      54 <true> }T
T{ s" ADDRESS-UNIT-BITS"  environment? ->       8 <true> }T
T{ s" FLOORED"            environment? -> <false> <true> }T
T{ s" MAX-CHAR"           environment? ->      FF <true> }T
T{ s" MAX-N"              environment? ->    7FFF <true> }T
T{ s" MAX-U"              environment? ->    FFFF <true> }T
T{ s" RETURN-STACK-CELLS" environment? ->      80 <true> }T
T{ s" STACK-CELLS"        environment? ->      20 <true> }T
T{ s" WORDLISTS"          environment? ->       9 <true> }T

T{ s" MAX-D"  environment? -> 7FFFFFFF. <true> }T 
T{ s" MAX-UD" environment? -> FFFFFFFF. <true> }T
decimal

\ ------------------------------------------------------------------------
testing input: accept

create abuf 80 chars allot

: accept-test
   cr ." please type up to 80 characters:" cr
   abuf 80 accept
   dup 
   cr ." received: " [char] " emit
   abuf swap type [char] " emit cr
;

\ The text for accept (below the test) is 29 characters long.
T{ accept-test -> 29 }T
Here is some text for accept.

\ ------------------------------------------------------------------------
testing dictionary search rules

T{ : gdx   123 ; : gdx   gdx 234 ; -> }T
T{ gdx -> 123 234 }T

hex
\ Free memory used for these tests
core_c_tests

