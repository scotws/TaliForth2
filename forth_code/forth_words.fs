\ List of high-level Forth words for Tali Forth 2 for the 65c02
\ This version: 24. Jan 2020

\ Version date is not changed for simple update of date
\ string in splash quotes at end of file

\ When changing these words, edit them here and then use the 
\ forth_to_ophisbin.py tool to convert them to the required format
\ for inclusion in Ophis. This will be done automatically when "make"
\ is run from the top level. See forth_words/README.md for details

\ ===============================================================

\ (There are currently no high-level Forth words defined)

\ ===============================================================
        
\ Splash strings. We leave these as high-level words because they are
\ generated at the end of the boot process and signal that the other
\ high-level definitions worked (or at least didn't crash)

        cr .( Tali Forth 2 for the 65c02)
        cr .( Version 1.0  24. Jan 2020 )
        cr .( Copyright 2014-2020 Scot W. Stevenson)
        cr .( Tali Forth 2 comes with absolutely NO WARRANTY)
        cr .( Type 'bye' to exit) cr

\ END
