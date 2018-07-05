\ ------------------------------------------------------------------------
testing cycle counts

\ These tests time the number of cylcles each word takes to run for a
\ given input.  These tests only work with the talitest.py script
\ which has handlers watching for the reading of the special addresses
\ $F002 and $F003 that calculate the number of cycles between reading
\ from the special addresses.  The cycles elapsed can then be read
\ from the virtual memory location $FF00 (as a double word)


\ The test access words
hex
\ begin_cycles direct byte compiled into ram.
\ lda $f002
\ rts
: begin_cycles [ AD c, 02 c, F0 c, 60 c, ] ;
\ end_cycles direct byte compiled into ram.
\ lda $f003
\ rts
: end_cycles [ AD c, 03 c, F0 c, 60 c, ] ;

\ The location of the result
FF00 constant cycles

\ Forth versions
\ : begin_cycles F002 c@ drop ;
\ : end_cycles F003 c@ drop ;

\ Determine the overhead of the testing words themselves.
: cycles_overhead_test begin_cycles end_cycles ;
2variable cycles_overhead
cycles_overhead_test cycles 2@ cycles_overhead 2!
cycles_overhead 2@ decimal ud.

\ Print the number of cycles (in decimal) with the overhead removed.
: print_cycles base @ decimal cycles 2@ cycles_overhead 2@ d- ud. base ! ;
\ Test a word.  ok
: cycles_/ 1234 7 begin_cycles / end_cycles ;
cycles_/ print_cycles

\ Test a word with lookup overhead.
begin_cycles end_cycles ( overhead ) print_cycles
1234 7 begin_cycles / end_cycles ( actual test ) print_cycles

\ Test what should be a very small word.
: cycles_drop 5 begin_cycles drop end_cycles ;
cycles_drop print_cycles
