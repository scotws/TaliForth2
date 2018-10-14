\ ------------------------------------------------------------------------
testing block words: LOAD THRU BUFFER BLOCK UPDATE FLUSH

marker block_tests

\ Bring in the 4-block ram drive
{ block_init_ramdrive -> }

\ Put a string into the first block.
{ : teststring s" ( TEST )" ; -> }
{ : teststringlength teststring swap drop ; -> }

\ The word BLOCK halts talitest and I'm not sure why.
\ It works fine in py65mon.
\ { teststring 0 block swap move update flush -> }

\ See if it's in the ramdrive.
\ { 0 ramdrive teststringlength teststring compare -> 0 }






block_tests