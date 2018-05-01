\ Temporary storage for new words 
\ Scot W. Stevenson <scot.stevenson@gmail.com>
\ First version: 12. Mar 2018
\ This version: 12. Mar 2018

( Source pforth ) 

\ -------------------------------------------

: compare   ( c-addr1 u1 c-addr2 u2 -- n )
   rot 2swap 2over min               \ no. of characters to check
   dup 0> if                         \ if strings not both length 0
      0 do                           \ for each character
         over c@  over c@            \ get the characters
         <> if                       \ if they're unequal
            c@ swap  c@              \ retrieve the characters
            < 2* invert              \ construct the return code
            nip nip unloop exit      \ and exit
         then
         char+ swap  char+ swap      \ increment addresses
      loop
      2drop                          \ get rid of addresses
      2dup <> -rot < 2* invert and   \ construct return code
   else                              \ if strings are both length 0
      2drop 2drop                    \ leave 0
   then ;

\ -------------------------------------------

: search   ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 f )
   rot 2dup                          \ copy lengths
   over swap u>  swap 0=  or if      \ if u2>u1 or u2=0
      nip nip  false exit            \ exit with false flag
   then
   -rot 2over                        \ save c-addr1 u1
   2swap tuck 2>r                    \ save c-addr2 u2
   - 1+ over +  swap                 \ make c-addr1 c-addr1+u1-u2
   2r> 2swap                         \ retrieve c-addr2 u2
   do
      2dup i over compare 0= if      \ if we find the string
         2drop +  i tuck -           \ calculate c-addr3 u3
         true unloop exit            \ exit with true flag
      then
   loop
   2drop false ;                     \ leave c-addr1 u1 false

 
