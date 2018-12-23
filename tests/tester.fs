\ From: John Hayes S1I
\ Subject: tester.fr
\ Date: Mon, 27 Nov 95 13:10:09 PST  

\ Modified by SamCo 2018-05 for testing Tali Forth 2.
\ The main change is lowercasing all of the words as Tali
\ is case sensitive, as well as replacing tabs with spaces.
\ A word to display the actual (erroneous) results was also added.
\ Modified by SamCo 2018-10 to facilitate using standard ANS tests.
\ The testing words were changed from { and } to T{ and }T to
\ match the testing words currently being used by ANS standard tests.

\ (C) 1995 JOHNS HOPKINS UNIVERSITY / APPLIED PHYSICS LABORATORY
\ MAY BE DISTRIBUTED FREELY AS LONG AS THIS COPYRIGHT NOTICE REMAINS.
hex

\ Set the following flag to true for more verbose output; this may allow you to
\ tell which test caused your system to hang. With Tali Forth, this is useless
\ because the Python script echoes all the output anyway.
variable verbose  false verbose !

variable actual-depth   \ stack record
create actual-results  20 cells allot


\ Empty stack: handles underflowed stack too
: empty-stack ( ... -- ) 
   depth ?dup if 
      dup 0< if 
         negate 0 do 0 loop 
      else 
         0 do drop loop 
      then 
   then ;

\ Print the previous test's actual results. Added by SamCo 2018-05 
: show-results ( -- ) 
   s"  ACTUAL RESULT: { " type
   actual-depth @ 0 ?do
      actual-results 
      actual-depth @ i - 1- \ Print them in reverse order to match test.
      cells + @ .
   loop
   s" }" type ;

\ Display an error message followed by the line that had the error
: error  \ ( C-ADDR U -- ) 
   type source type \ display line corresponding to error
   empty-stack      \ throw away every thing else
   show-results ;   \ added by SamCo to show what actually happened

\ Syntactic sugar
: T{  ( -- ) ;

\ Record depth and content of stack
: ->  ( ... -- ) 
   depth dup actual-depth !  \ record depth
   ?dup if                   \ if there is something on stack ...
      0 do 
         actual-results i cells + ! 
      loop                   \ ... save it
   then ;

\ Compare stack (expected) contents with saved (actual) contents
: }T  ( ... -- ) 
   depth actual-depth @ = if     \ if depths match
      depth ?dup if              \ if there is something on the stack
         0 do                    \ for each stack item
            actual-results i cells + @  \ compare actual with expected
            <> if 
               s" INCORRECT RESULT: " error leave 
            then
         loop
      then
   else                          \ depth mismatch
      s" WRONG NUMBER OF RESULTS: " error
   then ;

\ Talking comment
: testing ( -- ) 
   source verbose @ if 
      dup >r type cr r> >in !
   else >in ! drop
   then ;
