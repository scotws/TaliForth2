\ ------------------------------------------------------------------------
testing search-order words: get-order set-order get-current set-current
testing wordlist definitions forth-wordlist search-wordlist find

decimal
marker search_tests

\ Set the wordlists to a known state to start.
forth-wordlist 1 set-order
forth-wordlist set-current

\ Define two word list (wid) variables used by the tests.
VARIABLE wid1
VARIABLE wid2

\ In order to test the search order it in necessary to remember the
\ existing search order before modifying it. The existing search order
\ is saved and the get-orderlist defined to access it.

: save-orderlist ( widn ... wid1 n -- )
   DUP , 0 ?DO , LOOP
;

CREATE order-list
T{ GET-ORDER save-orderlist -> }T

: get-orderlist ( -- widn ... wid1 n )
   order-list DUP @ CELLS	   ( -- ad n )
   OVER +	                      ( -- AD AD' )
   ?DO I @ -1 CELLS +LOOP    ( -- )
;

\ FORTH-WORDLIST test
T{ FORTH-WORDLIST wid1 ! -> }T

\ SET-ORDER tests
T{ GET-ORDER OVER      -> GET-ORDER wid1 @ }T
T{ GET-ORDER SET-ORDER -> }T
T{ GET-ORDER           -> get-orderlist }T T{ get-orderlist DROP get-orderList 2* SET-ORDER -> }T
T{ GET-ORDER -> get-orderlist DROP get-orderList 2* }T
T{ get-orderlist SET-ORDER GET-ORDER -> get-orderlist }T

: so2a GET-ORDER get-orderlist SET-ORDER ;
: so2 0 SET-ORDER so2a ;

T{ so2 -> 0 }T	    \ 0 SET-ORDER leaves an empty search order

: so3 -1 SET-ORDER so2a ;
: so4 ONLY so2a ;

T{ so3 -> so4 }T	   \ -1 SET-ORDER is the same as ONLY

\ ALSO test   Note: Modified from ANS test to restore FORTH wordlist
T{ ALSO GET-ORDER ONLY FORTH -> get-orderlist OVER SWAP 1+ }T

\ ONLY tests
T{ ONLY FORTH GET-ORDER -> get-orderlist }T

: so1 SET-ORDER ; \ In case it is unavailable in the forth wordlist

T{ ONLY FORTH-WORDLIST 1 SET-ORDER get-orderlist so1 -> }T
T{ GET-ORDER -> get-orderlist }T

\ SET-CURRENT, GET-CURRENT, and WORDLIST tests

T{ GET-CURRENT -> wid1 @ }T

T{ WORDLIST wid2 ! -> }T
T{ wid2 @ SET-CURRENT -> }T
T{ GET-CURRENT -> wid2 @ }T

T{ wid1 @ SET-CURRENT -> }T

\ DEFINITIONS tests

T{ ONLY FORTH DEFINITIONS -> }T
T{ GET-CURRENT -> FORTH-WORDLIST }T

T{ GET-ORDER wid2 @ SWAP 1+ SET-ORDER DEFINITIONS GET-CURRENT
-> wid2 @ }T
T{ GET-ORDER -> get-orderlist wid2 @ SWAP 1+ }T
T{ PREVIOUS GET-ORDER -> get-orderlist }T
T{ DEFINITIONS GET-CURRENT -> FORTH-WORDLIST }T

: alsowid2 ALSO GET-ORDER wid2 @ ROT DROP SWAP SET-ORDER ;
alsowid2
: w1 1234 ;
DEFINITIONS : w1 -9876 ; IMMEDIATE

ONLY FORTH
T{ w1 -> 1234 }T
DEFINITIONS
T{ w1 -> 1234 }T
alsowid2
T{ w1 -> -9876 }T
DEFINITIONS T{ w1 -> -9876 }T

ONLY FORTH DEFINITIONS
: so5 DUP IF SWAP EXECUTE THEN ;

T{ S" w1" wid1 @ SEARCH-WORDLIST so5 -> -1  1234 }T
T{ S" w1" wid2 @ SEARCH-WORDLIST so5 ->  1 -9876 }T

\ : c"w1" C" w1" ;
\ We don't have C" so the above has been modified to use s\" instead.
: c"w1" s\" \x02w1" drop ; ( dropping the length, as it's in the string )
T{ alsowid2 c"w1" FIND so5 ->  1 -9876 }T
T{ PREVIOUS c"w1" FIND so5 -> -1  1234 }T

\ SEARCH-WORDLIST tests
ONLY FORTH DEFINITIONS
VARIABLE xt ' DUP xt !
VARIABLE xti ' .( xti ! \ Immediate word

T{ S" DUP" wid1 @ SEARCH-WORDLIST -> xt  @ -1 }T
T{ S" .("  wid1 @ SEARCH-WORDLIST -> xti @  1 }T
T{ S" DUP" wid2 @ SEARCH-WORDLIST ->        0 }T

\ FIND tests
\ FIND needs counted strings (first byte is count)
\ Tali doesn't have C", so we'll use s\" to make them.
: c"dup" s\" \x03DUP" drop ;
: c".(" s\" \x02.(" drop ;
: c"x" s\" \x0Cunknown word" drop ;

T{ c"dup" FIND -> xt  @ -1 }T
T{ c".("  FIND -> xti @  1 }T
T{ c"x"   FIND -> c"x"   0 }T


search_tests
