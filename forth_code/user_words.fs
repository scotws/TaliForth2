\ List of optional Forth words for Tali Forth 2 for the 65c02
\ Scot W. Stevenson <scot.stevenson@gmail.com>
\ This version: 18. Dec 2018

\ When changing these words, edit them here and then use the 
\ forth_to_ophisbin.py tool to convert them to the required format
\ for inclusion in Ophis. This is handled automatically by "make"
\ when run from the top level. See forth_words/README.md for details

\ Note that these programs are not necessarily in the public domain,
\ see the original sources for details

\ -------------------------------------------------------
\ WORDS&SIZES prints all known words and the sizes of their codes
\ in bytes. It can be used to test the effects of different native
\ compile parameters
        \ : words&sizes  latestnt begin dup 0<> while dup name>string
        \ type space  dup wordsize u. cr  2 + @ repeat drop ;

\ -------------------------------------------------------
\ FIBONACCI, contributed by leepivonka at
\ http://forum.6502.org/viewtopic.php?f=9&t=2926&start=90#p58899
\ Prints fibonacci numbers up to and including 28657
         \ : fib ( -- ) 0 1 begin dup . swap over + dup 0< until 2drop ;
        
\ -------------------------------------------------------
\ FACTORIAL from 
\ https://www.complang.tuwien.ac.at/forth/gforth/Docs-html/Recursion-Tutorial.html
        \ : fact ( n -- n! )
        \  dup 0> if
        \     dup 1- recurse * else
        \     drop 1 then ;

\ -------------------------------------------------------
\ PRIMES from 
\ https://www.youtube.com/watch?v=V5VGuNTrDL8 (Forth Freak)
        \  : primes ( n -- )
        \      2 . 3 .
        \      2 swap 5 do
        \           dup dup * i < if 1+ then
        \            1 over 1+ 3 do
        \                  j i mod 0= if 1- leave then
        \            2 +loop
        \            if i . then
        \      2 +loop
        \    drop ;
        
\ -------------------------------------------------------
\ MANDELBROT by Martin Heermance
\ https://github.com/Martin-H1/Forth-CS-101/blob/master/mandelbrot.fs
\ http://forum.6502.org/viewtopic.php?f=9&t=3706
\ https://www.youtube.com/watch?v=fVa3Fx7dwBM
        \  setup constants to remove magic numbers to allow
        \  for greater zoom with different scale factors
        \  20 constant maxiter "
        \ -39 constant minval "
        \  40 constant maxval "
        \  20 5 lshift constant rescale "
        \ rescale 4 * constant s_escape "
        \  "
        \ ( these variables hold values during the escape calculation ) "
        \ variable creal "
        \ variable cimag "
        \ variable zreal "
        \ variable zimag "
        \ variable count "
        \  "
        \ ( compute squares, but rescale to remove extra scaling factor) "
        \ : zr_sq zreal @ dup rescale */ ; "
        \ : zi_sq zimag @ dup rescale */ ; "
        \  "
        \ ( translate escape count to ascii greyscale )"
        \ : .char "
        \          s\" ..,'~!^:;[/<&?oxox#  \" "
        \          drop + 1 "
        \          type ; "
        \  "
        \ ( numbers above 4 will always escape, so compare to a scaled value) "
        \ : escapes? s_escape > ; "
        \  "
        \ ( increment count and compare to max iterations) "
        \ : count_and_test? "
        \          count @ 1+ dup count ! "
        \          maxiter > ; "
        \  "
        \ ( stores the row column values from the stack for the escape calculation) "
        \ : init_vars "
        \          5 lshift dup creal ! zreal ! "
        \          5 lshift dup cimag ! zimag ! "
        \          1 count ! ; "
        \  "
        \ ( performs a single iteration of the escape calculation) "
        \ : doescape "
        \          zr_sq zi_sq 2dup + "
        \          escapes? if "
        \          2drop "
        \          true "
        \          else "
        \          - creal @ +   ( leave result on stack ) "
        \          zreal @ zimag @ rescale */ 1 lshift "
        \          cimag @ + zimag ! "
        \          zreal !                   ( store stack item into zreal ) "
        \          count_and_test? "
        \          then ; "
        \  "
        \ ( iterates on a single cell to compute its escape factor) "
        \ : docell "
        \          init_vars "
        \          begin "
        \          doescape "
        \          until "
        \          count @ "
        \          .char ; "
        \  "
        \ ( for each cell in a row) "
        \ : dorow "
        \          maxval minval do "
        \          dup i "
        \          docell "
        \          loop "
        \          drop ; "
        \  "
        \ ( for each row in the set) "
        \ : mandelbrot "
        \          cr "
        \          maxval minval do "
        \          i dorow cr "
        \          loop ; "
        
\ END 
