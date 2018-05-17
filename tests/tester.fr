\ From: John Hayes S1I
\ Subject: tester.fr
\ Date: Mon, 27 Nov 95 13:10:09 PST  

\ Modified by SamCo 2018-05 for testing Tali Forth 2.
\ The main change is lowercasing all of the words as Tali
\ is case sensitive, as well as replacing tabs with spaces.

\ (C) 1995 JOHNS HOPKINS UNIVERSITY / APPLIED PHYSICS LABORATORY
\ MAY BE DISTRIBUTED FREELY AS LONG AS THIS COPYRIGHT NOTICE REMAINS.
\ VERSION 1.1
hex

\ SET THE FOLLOWING FLAG TO TRUE FOR MORE VERBOSE OUTPUT; THIS MAY
\ ALLOW YOU TO TELL WHICH TEST CAUSED YOUR SYSTEM TO HANG.
variable verbose
   false verbose !

: empty-stack \ ( ... -- ) EMPTY STACK: HANDLES UNDERFLOWED STACK TOO.
   depth ?dup if dup 0< if negate 0 do 0 loop else 0 do drop loop then then ;

: error  \ ( C-ADDR U -- ) DISPLAY AN ERROR MESSAGE FOLLOWED BY
  \ THE LINE THAT HAD THE ERROR.
   type source type \ CR   \ DISPLAY LINE CORRESPONDING TO ERROR
   empty-stack    \ THROW AWAY EVERY THING ELSE
;

variable actual-depth   \ STACK RECORD
create actual-results 20 cells allot

: {  \ ( -- ) SYNTACTIC SUGAR.
   ;

: ->  \ ( ... -- ) RECORD DEPTH AND CONTENT OF STACK.
   depth dup actual-depth !  \ RECORD DEPTH
   ?dup if    \ IF THERE IS SOMETHING ON STACK
      0 do actual-results i cells + ! loop \ SAVE THEM
   then ;

: }  \ ( ... -- ) COMPARE STACK (EXPECTED) CONTENTS WITH SAVED
  \ (ACTUAL) CONTENTS.
   depth actual-depth @ = if  \ IF DEPTHS MATCH
      depth ?dup if   \ IF THERE IS SOMETHING ON THE STACK
         0 do    \ FOR EACH STACK ITEM
     actual-results i cells + @ \ COMPARE ACTUAL WITH EXPECTED
     <> if s" INCORRECT RESULT: " error leave then
  loop
      then
   else     \ DEPTH MISMATCH
      s" WRONG NUMBER OF RESULTS: " error
   then ;

: testing \ ( -- ) TALKING COMMENT.
   source verbose @
   if dup >r type cr r> >in !
   else >in ! drop
   then ;

