hex
\ poking lda from timing addresses followed by rts.
: begin_cycles [ AD c, 02 c, f0 c, 60 c, ] ;
: end_cycles   [ AD c, 03 c, f0 c, 60 c, ] ;

\ Determine the overhead of the testing words themselves.
: cycles_overhead begin_cycles end_cycles ;
cycles_overhead

\ Test a word.  ok
: cycles_/ 1234 7 begin_cycles / end_cycles ;
cycles_/

\ Test a word with lookup overhead.
begin_cycles end_cycles ( overhead )
1234 7 begin_cycles / end_cycles ( actual test )
\ Test what should be a very small word.
: cycles_drop 5 begin_cycles drop end_cycles ;
cycles_drop
