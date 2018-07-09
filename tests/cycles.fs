\ ------------------------------------------------------------------------
testing cycle counts

\ These tests time the number of cylcles each word takes to run for a
\ given input.  These tests only work with the talitest.py script
\ which has handlers watching for the reading of the special addresses
\ $F002 and $F003 that calculate the number of cycles between reading
\ from the special addresses.  The cycles elapsed can then be read
\ from the virtual memory location $FF00 (as a double word)

hex

\ The location of the result
FF00 constant cycles

\ direct byte compiled
\  lda $f002
\  lda $f003
: cycles_overhead [ AD c, 02 c, F0 c, AD c, 03 c, F0 c, ] cycles 2@ ;

\ direct byte compiled
\  lda $F002
\  jsr (xt on stack goes here)
\  lda $f002
\ then forth code to fetch and print results.
: cycle_test_runtime
    [ AD c, 02 c, F0 c,    \ lda $F002
      20 c,  0000 ,        \ jsr (address to be filled in)
      AD c, 03 c, F0 c, ]  \ lda $F003
    cycles 2@              \ fetch result
    cycles_overhead d-     \ subtract overhead
    ." CYCLES: "
    \ d.r isn't available
    2dup 2710 ( 10000) sm/rem swap drop 0= if bl emit then
    2dup  3e8 (  1000) sm/rem swap drop 0= if bl emit then
    2dup   64 (   100) sm/rem swap drop 0= if bl emit then
    2dup    A (    10) sm/rem swap drop 0= if bl emit then
    ud.   \ print results
;

\ cycle_test updates the address of the given xt in cycle_test_runtime
\ then it runs the test.

\ To test a word, put any arguments it needs on the stack, use tick
\ (') on the word to get it's execution token (xt) and then put
\ cycle_test, then any stack cleanup.
\ eg. 5 ' dup cycle_test 2drop
: cycle_test ( xt -- )
    [ ' cycle_test_runtime 4 + ] literal ! cycle_test_runtime ;

decimal
\ In all of these tests, a 5 is usually just a dummy input for the
\ word to work with.

\ skipping cold
\ skipping abort
\ skipping quit
\ skipping abort"
5 ' abs cycle_test drop
\ accept is a little weird as it needs some input on its own line.
pad 20 ' accept cycle_test
some text
drop
\ accept test complete
           ' align         cycle_test       
5          ' aligned       cycle_test drop  
5          ' allot         cycle_test       
: aword ;  ' always-native cycle_test       
5 5        ' and           cycle_test drop  
\ skipping at-xy
           ' \             cycle_test       
\ not sure if \ starts on this line
           ' base          cycle_test drop  
\ skipping begin
           ' bell          cycle_test       
           ' bl            cycle_test drop  
5 5        ' bounds        cycle_test 2drop 
\ skipping [char]
\ skipping [']
\ skipping branch
\ skipping bye
5          ' c,            cycle_test       
5          ' c@            cycle_test drop  
5 here     ' c!            cycle_test       
5 5        ' cell+         cycle_test drop  
5          ' cells         cycle_test drop  
           ' char          cycle_test w drop
5 5        ' char+         cycle_test drop  
5          ' chars         cycle_test drop  
pad here 5 ' cmove         cycle_test       
pad here 5 ' cmove>        cycle_test       
           ' :             cycle_test wrd ; 
           ' :noname       cycle_test ; drop
5          ' ,             cycle_test       
' aword    ' compile,      cycle_test       

5 ' drop    cycle_test

5 ' dup cycle_test 2drop

s" drop" ' find-name cycle_test
s" aword" ' find-name cycle_test
