\ List of high-level Forth words for Tali Forth 2 for the 65c02
\ This version: 21. Dec 2018

\ Version date is not changed for simple update of date
\ string in splash quotes at end of file

\ When changing these words, edit them here and then use the 
\ forth_to_ophisbin.py tool to convert them to the required format
\ for inclusion in Ophis. This will be done automatically when "make"
\ is run from the top level. See forth_words/README.md for details

\ ===============================================================

\ Extended words for the optional Search-Order wordset.
\ This one isn't provided by ANS, but is simple to implement.
\ Print wordlist name, or number if name not known.
: .wid ( wid -- )
        dup 0=  if ." FORTH "  drop    else
        dup 1 = if ." EDITOR " drop    else
        dup 2 = if ." ASSEMBLER " drop else
        dup 3 = if ." ROOT " drop      else        
                   . ( just print the number )
        then then then then ;

: ORDER ( -- )
        cr get-order 0 ?do .wid loop
        space space get-current .wid ;        

\ ===============================================================

        
\ Splash strings. We leave these as high-level words because they are
\ generated at the end of the boot process and signal that the other
\ high-level definitions worked (or at least didn't crash)
        cr .( Tali Forth 2 for the 65c02)
        cr .( Version BETA 24. Dec 2018 )
        cr .( Copyright 2014-2018 Scot W. Stevenson)
        cr .( Tali Forth 2 comes with absolutely NO WARRANTY)
        cr .( Type 'bye' to exit) cr
\ END
