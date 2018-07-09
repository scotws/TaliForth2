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
    ." CYCLES: "  ud. cr   \ print results
;

\ cycle_test updates the address of the given xt in cycle_test_runtime
\ then it runs the test.
: cycle_test ( xt -- )
    [ ' cycle_test_runtime 4 + ] literal ! cycle_test_runtime ;

decimal
5 ' drop cycle_test

5 ' dup cycle_test 2drop

s" drop" ' find-name cycle_test
s" cycle_test" ' find-name cycle_test
