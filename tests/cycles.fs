\ ------------------------------------------------------------------------
testing cycle counts

\ These tests time the number of cylcles each word takes to run for a
\ given input.  These tests only work with the talitest.py script
\ which has handlers watching for the reading of the special addresses
\ $F006 and $F007; they calculate the number of cycles between reading
\ from the special addresses.  The cycles elapsed can then be read
\ from the virtual memory location $F008 (as a double word)

\ Take care when editing this file as the whitespace on the ends of lines is
\ desired to keep the CYCLE: counts lined up.

hex

\ The location of the result
F008 constant cycles

\ direct byte compiled
\  lda $f006
\  lda $f007
: cycles_overhead [ AD c, 06 c, F0 c, AD c, 07 c, F0 c, ] cycles 2@ ;

\ direct byte compiled
\  lda $F006
\  jsr (xt on stack goes here)
\  lda $f007
\ then forth code to fetch and print results.
: cycle_test_runtime
    [ AD c, 06 c, F0 c,    \ lda $F006
      20 c,  0000 ,        \ jsr (address to be filled in)
      AD c, 07 c, F0 c, ]  \ lda $F007
    cycles 2@              \ fetch result
    cycles_overhead d-     \ subtract overhead
    ." CYCLES: " 6 ud.r    \ print results
;

\ cycle_test updates the address of the given xt in cycle_test_runtime
\ then it runs the test.

\ To test a word, put any arguments it needs on the stack, use tick
\ (') on the word to get it's execution token (xt) and then put
\ cycle_test, then any stack cleanup.
\ eg. 5 ' dup cycle_test 2drop
: cycle_test ( xt -- )
    [ ' cycle_test_runtime 4 + ] literal ! cycle_test_runtime ;

\ Some test leave lots of stuff on the stack.
\ These words help clean up the mess.
: 4drop 2drop 2drop ;
: 6drop 2drop 2drop 2drop ;

variable myvar
5 myvar !

decimal
\ In all of these tests, a 5 is usually just a dummy input for the
\ word to work with.

\ skipping     cold
\ skipping     abort
\ skipping     quit
\ skipping     abort"
5            ' abs           cycle_test drop      
pad 20       ' accept        cycle_test
some text 
drop \ accept test complete
             ' align         cycle_test           
5            ' aligned       cycle_test drop      
5            ' allot         cycle_test           
: aword ;    ' always-native cycle_test           
5 5          ' and           cycle_test drop      
\ skipping     at-xy
             ' \             cycle_test           
             ' base          cycle_test drop      
\ skipping     begin
             ' bell          cycle_test           
             ' bl            cycle_test drop      
here 5       ' blank         cycle_test           
5 5          ' bounds        cycle_test 2drop     
\ skipping     [char]
\ skipping     [']
\ skipping     branch
\ skipping     bye
5            ' c,            cycle_test           
5            ' c@            cycle_test drop      
5 here       ' c!            cycle_test           
5            ' cell+         cycle_test drop      
5            ' cells         cycle_test drop      
             ' char          cycle_test w drop    
5            ' char+         cycle_test drop      
5            ' chars         cycle_test drop      
pad here 5   ' cmove         cycle_test           
pad here 5   ' cmove>        cycle_test           
             ' :             cycle_test wrd ;     
             ' :noname       cycle_test ; drop    
5            ' ,             cycle_test           
' aword      ' compile,      cycle_test           
: bword ;    ' compile-only  cycle_test           
5            ' constant      cycle_test mycnst    
here         ' count         cycle_test 2drop     
\ skipping     cr
\ skipping     create
5. 5.        ' d-            cycle_test 2drop     
5. 5.        ' d+            cycle_test 2drop     
5.           ' d>s           cycle_test drop      
-5.          ' dabs          cycle_test 2drop     
             ' decimal       cycle_test           
\ skipping     defer
             ' depth         cycle_test drop      
char w       ' digit?        cycle_test 2drop     
\ skipping     disasm
5.           ' dnegate       cycle_test 2drop     
\ skipping     ?do
\ skipping     do
\ skipping     does
\ skipping     .
\ skipping     ."
             ' s"            cycle_test " 2drop   
5            ' drop          cycle_test           
\ skipping     dump
5            ' dup           cycle_test 2drop     
42           ' emit          cycle_test          
5 5          ' =             cycle_test drop      
here 5       ' erase         cycle_test           
here 5 5     ' fill          cycle_test           
s" 5"        ' evaluate      cycle_test drop      
5 ' drop     ' execute       cycle_test           
\ skipping     exit
             ' false         cycle_test drop      
here         ' @             cycle_test drop      
\ making counted string for find
here 5 c, char a c, char w c, char o c,
char r c, char d c,
             ' find          cycle_test 2drop     
s" aword"    ' find-name     cycle_test drop      
5. 5         ' fm/mod        cycle_test 2drop     
5 5          ' >             cycle_test drop      
             ' here          cycle_test drop      
             ' hex           cycle_test decimal   
\ skipping     hold
\ skipping     i
: cword ;    ' immediate     cycle_test           
             ' input         cycle_test drop      
' dup        ' int>name      cycle_test drop      
5            ' invert        cycle_test drop      
\ skipping     j
             ' key           cycle_test drop      

             ' latestnt      cycle_test drop      
             ' latestxt      cycle_test drop      
\ skipping     leave
\ skipping     [
\ skipping     <#
5 5          ' <             cycle_test drop      
\ skipping     literal
\ skipping     loop
\ skipping     +loop
5 5          ' lshift        cycle_test drop      
5 5          ' m*            cycle_test 2drop     
             ' marker        cycle_test marka     
             ' marka         cycle_test           
5 5          ' max           cycle_test drop      
5 5          ' min           cycle_test drop      
5 5          ' -             cycle_test drop      
s" txt   "   ' -trailing     cycle_test 2drop     
here s" a"   ' move          cycle_test           
' + int>name ' name>int      cycle_test drop      
' + int>name ' name>string   cycle_test 2drop     
             ' nc-limit      cycle_test drop      
5            ' negate        cycle_test drop      
: dword ;    ' never-native  cycle_test           
5 5          ' nip           cycle_test drop      
5 5          ' <>            cycle_test drop      
5 5 5        ' -rot          cycle_test 2drop drop
s" 5"        ' number        cycle_test drop      
\ skipping     #
\ skipping     #>
\ skipping     #s
             ' 1             cycle_test drop      
5            ' 1+            cycle_test drop      
5            ' 1-            cycle_test drop      
5 5          ' or            cycle_test drop      
             ' output        cycle_test drop      
5 5          ' over          cycle_test 2drop drop
             ' pad           cycle_test drop      
\ skipping     page
             ' parse-name    cycle_test a 2drop   
char "       ' parse         cycle_test " 2drop   
5 0          ' pick          cycle_test 2drop     
5 5          ' +             cycle_test drop      
5 here       ' +!            cycle_test           
\ skipping     postpone
myvar        ' ?             cycle_test         
5            ' ?dup          cycle_test 2drop     
\ skipping     r>
\ skipping     recurse
             ' refill        cycle_test          

drop \ refill
\ skipping     ]
5 5 5        ' rot           cycle_test 2drop drop
5 5          ' rshift        cycle_test drop      
             ' s"            cycle_test " 2drop   
5            ' s>d           cycle_test 2drop     
\ skipping     ;
\ skipping     sign
s" abc" 1    ' /string       cycle_test 2drop     
\ skipping     sliteral
5. 5         ' sm/rem        cycle_test 2drop     
             ' source        cycle_test 2drop     
             ' source-id     cycle_test drop      
             ' space         cycle_test          
1            ' spaces        cycle_test          
5 5          ' *             cycle_test drop      
             ' state         cycle_test drop      
5 here       ' !             cycle_test           
5 5          ' swap          cycle_test 2drop     
             ' '             cycle_test aword drop
\ postponing   to ( see value )
' aword      ' >body         cycle_test drop      
             ' >in           cycle_test drop      
0. s" 55"    ' >number       cycle_test 4drop     
\ skipping     >r
             ' true          cycle_test drop      
5 5          ' tuck          cycle_test 2drop drop
             ' 2             cycle_test drop      
5 5          ' 2drop         cycle_test           
5 5          ' 2dup          cycle_test 4drop     
here         ' 2@            cycle_test 2drop     
5 5 5 5      ' 2over         cycle_test 6drop     
\ skipping     2r@
\ skipping     2r>
5            ' 2/            cycle_test drop      
5            ' 2*            cycle_test drop      
5. here      ' 2!            cycle_test           
5 5 5 5      ' 2swap         cycle_test 4drop     
\ skipping     2>r
             ' 2variable     cycle_test eword     
             ' eword         cycle_test drop      
s" *"        ' type          cycle_test          
5            ' u.            cycle_test         
5 5          ' u>            cycle_test drop      
5 5          ' u<            cycle_test drop      
             ' strip-underflow   cycle_test drop      
5. 5         ' um/mod        cycle_test 2drop     
5 5          ' um*           cycle_test 2drop     
\ skipping     unloop
             ' unused        cycle_test drop      
5            ' value         cycle_test fword     
             ' fword         cycle_test drop      
5            ' to            cycle_test fword     
             ' variable      cycle_test gword     
             ' gword         cycle_test drop      
char "       ' word          cycle_test "txt" drop
\ skipping     words
' aword      ' wordsize      cycle_test drop      
5 5          ' xor           cycle_test drop      
             ' 0             cycle_test drop      
\ skipping     0branch
5            ' 0=            cycle_test drop      
5            ' 0>            cycle_test drop      
5            ' 0<            cycle_test drop      
5            ' 0<>           cycle_test drop      

