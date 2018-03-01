# Raw Forth flies for Tali Forth 2 for the 65c02  
Scot W. Stevenson <scot.stevenson@gmail.com>   
First version: 27. Feb 2018
This version: 01. Mar 2018

Tali Forth 2 uses a bunch of high-level Forth words that are compiled at
run-time, some defined by the system, some defined by the user. To make it
easier to use them, we can create the original Forth files with `.fs` suffix in
this directory, and then use the `forth_to_ophisbin.py` tool in this directory
to convert them to ASCII versions that have been stripped of all comment. These
can be placed as `.asc` files in the parent folder, from where they are imported
by Ophis with the `.incbin` directive.

For example, given the Forth routine for SEE in `forth_code/user_words.py`:
```
\ -------------------------------------------------------
\ SEE gives us information on a Forth word. At some point, this
\ can be added to the native words to save on size
        : see parse-name find-name dup 0= abort" No such name"
        base @ >r  hex  dup cr space ."  nt: " u.
        dup 4 + @ space ." xt: " u. "
        dup 1+ c@ 1 and if space ." CO " then
        dup 1+ c@ 2 and if space ." AN " then
        dup 1+ c@ 4 and if space ." IM " then
        dup 1+ c@ 8 and if space ." NN " then
        dup cr space ." size (decimal): " decimal wordsize dup .
        swap name>int swap hex cr space dump  r> base ! ;
```
we run the command
```
	python3 forth_to_ophisbin.py -i user_words.py > user_words.asc
```
This produces the output
```
: see parse-name find-name dup 0= abort" No such name" base @ >r hex dup cr
space ." nt: " u. dup 4 + @ space ." xt: " u. " dup 1+ c@ 1 and if space ." CO
" then dup 1+ c@ 2 and if space ." AN " then dup 1+ c@ 4 and if space ." IM "
then dup 1+ c@ 8 and if space ." NN " then dup cr space ." size (decimal): "
decimal wordsize dup . swap name>int swap hex cr space dump r> base ! ; 
```
(In the file, this is all one line with spaces which might have been cut off
here to do formatting). We copy this to the parent directory, and then include
it with the directive `.incbin user_words.asc`

Note that the labels for the user words must be included around this directive
in `taliforth.asm` as in
```
user_words_start:
.incbin user_words.asc
user_words_end:
```

This methode allows testing of the Forth word to be defined with Gforth (though
note that the exampe above will fail because of `wordsize`, a Tali Forth word). 
