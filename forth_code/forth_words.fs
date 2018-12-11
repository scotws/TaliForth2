\ List of high-level Forth words for Tali Forth 2 for the 65c02
\ Scot W. Stevenson <scot.stevenson@gmail.com>
\ This version: 11. Dec 2018

\ Note version date is not changed for simple update of date
\ string in splash quotes at end of file

\ When changing these words, edit them here and then use the 
\ forth_to_dotbyte.py tool to convert them to the required format
\ for inclusion in Ophis. See forth_words/README.md for details

\ Output and comment. Because it still blows my mind that we can
\ define this stuff this simply 
        : ( [char] ) parse 2drop ; immediate
        : .( [char] ) parse type ; immediate

\ Flow control. Some of these could be realized with CS-ROLL and
\ CS-PICK instead, which seems to be all the rage these days.
        : if postpone 0branch here 0 , ; immediate compile-only
        : then here swap ! ; immediate compile-only
        : else postpone branch here 0 , here rot ! ; immediate compile-only
        : repeat postpone again here swap ! ; immediate compile-only
        : until postpone 0branch , ; immediate compile-only
        : while postpone 0branch here 0 , swap ; immediate compile-only
        : case 0 ; immediate compile-only 
        : of postpone over postpone = postpone if postpone drop ; immediate compile-only 
        : endof postpone else ; immediate compile-only 
        : endcase postpone drop begin ?dup while postpone then repeat ; immediate compile-only 

\ DEFER and friends. Code taken from ANS Forth specification. Some of
\ these will be moved to assembler code in due course
        : defer! >body ! ;
        : defer@ >body @ ;
        : is state @ if postpone ['] postpone defer! else ' defer! then ; immediate
        : action-of state @ if postpone ['] postpone defer@ else ' defer@ then ; immediate

\ Output definitions. Since these usually involve the user, and humans
\ are slow, these can stay high-level for the moment. However, in this
\ state they don't check for underflow. Based on
\ https://github.com/philburk/pforth/blob/master/fth/numberio.fth
        : .r >r dup abs 0 <# #s rot sign #> r> over - spaces type ;
        : ud. <# #s #> type space ;
        : ud.r >r <# #s #> r> over - spaces type ;
        : d. tuck dabs <# #s rot sign #> type space ;
        : d.r >r tuck dabs <# #s rot sign #> r> over - spaces type ;

\ Temporary high-level words. TODO convert these to assembler
        : 2constant ( d -- ) create swap , , does> dup @ swap cell+ @ ;
        : 2literal ( d -- ) swap postpone literal postpone literal ; immediate
        : hexstore ( addr1 u1 addr2 -- u2 )
				\ Save copy of original address to calculate u2
				dup 2>r              ( addr1 u1 ) ( R: addr2 addr2 )
				begin                ( addr1 u1 ) ( R: addr2 addr2 )
            dup 0<> while
					bl cleave        ( addr1 u1 addr3 u3 ) ( R: addr2 addr2 )
					\ Prepare conversion: double 0 for number
					2>r 0. 2r>       ( addr1 u1 0 0 addr3 u3 ) ( R: addr2 addr2 )
					>number          ( addr1 u1 n n addr4 u4 ) ( R: addr2 addr2 )
					\ If u4 is not zero, we have leftover chars and have to do
               \ things differently
               dup 0= if
                   \ -- normal case
                   2drop            ( addr1 u1 n n ) ( R: addr2 addr2 )
                   d>s              ( addr1 u1 n ) ( R: addr2 addr2 )
                   \ Store our value
                   r@               ( addr1 u1 n addr2 ) ( R: addr2 addr2 )
                   c!               ( addr1 u1 ) ( R: addr2 addr2 )
                   \ Increase counter
                   r> 1+ >r         ( addr1 u1 ) ( R: addr2+1 addr2 )
               else         
                   \ -- pathological case
                   2drop 2drop 
               then 
				repeat
				2drop 2r>            ( addr2+n addr2 )
				swap - ;

\ ===============================================================

\ Extended words for the optional Search-Order wordset.
\ These are as provided in the ANS 2012 standard.
: ONLY forth-wordlist 1 set-order ;
: (wordlist) ( wid "<name>" -- ; )
   CREATE ,
   DOES>
     @ >R
     GET-ORDER NIP
     R> SWAP SET-ORDER
;
FORTH-WORDLIST (wordlist) FORTH 
: ALSO ( -- )
   GET-ORDER OVER SWAP 1+ SET-ORDER
;
: PREVIOUS ( -- ) GET-ORDER NIP 1- SET-ORDER ; 
\ This one isn't provided by ANS, but is simple to implement.
: ORDER ( -- ) cr get-order 0 ?do
        dup 0=  if ." FORTH-WORDLIST "  drop    else
        dup 1 = if ." EDITOR-WORDLIST " drop    else
        dup 2 = if ." ASSEMBLER-WORDLIST " drop else
                   . ( just print the number )
        then then then loop ;        

\ ===============================================================

        
\ Splash strings. We leave these as high-level words because they are
\ generated at the end of the boot process and signal that the other
\ high-level definitions worked (or at least didn't crash)
        cr .( Tali Forth 2 for the 65c02)
        cr .( Version BETA 15. Nov 2018 )
        cr .( Copyright 2014-2018 Scot W. Stevenson)
        cr .( Tali Forth 2 comes with absolutely NO WARRANTY)
        cr .( Type 'bye' to exit) cr
\ END
