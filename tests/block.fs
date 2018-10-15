\ ------------------------------------------------------------------------
testing block words: BLK SCR LOAD THRU BUFFER BLOCK UPDATE FLUSH

marker block_tests

\ Bring in the 4-block ram drive
{ block_init_ramdrive -> }

\ Put a string into the first block.
{ : teststring s" Testing Blocks!" ; -> }
{ : teststringlength teststring swap drop ; -> }
{ teststring 0 block swap move update flush -> }

\ See if it's in the ramdrive.
{ 0 ramdrive teststringlength teststring compare -> 0 }

\ We don't have an official editor yet, so bring in just
\ enough to create some basic screens.
decimal
( List the current screen)
: L  ( - ) 
    scr @ block                  ( Load the screen )
    cr ." Screen #" scr @ 4 u.r  ( Print the screen number )
    16 0 do
        cr i 2 u.r space       ( Print the line number )
        dup i 64 * + 64 type     ( Print the line )
    loop cr drop ;

( List a given screen )
: list  ( scr# - )
    scr ! ( Save the screen number)
    L ;   ( Print the screen )

( Editor, continued )
( line provides the address, in the buffer, of the given line )
: line  ( line# - c-addr)
    64 *        ( Convert line number to # characters offset )
    scr @ block ( Get the buffer address for that block )
    + ;         ( Add the offset )

: E ( line# - ) ( Erase the given line number with spaces )
    line 64 blank update ;

: O     ( line# - ) ( Overwrite line with new text )
    dup E                    ( Erase existing text on line )
    cr dup 2 u.r ."  * " line 64 accept drop update ;

( Editor, continued )
: enter-screen ( scr# - )
  dup scr ! buffer drop
  16 0 do i o loop ;
: erase-screen ( scr# - )
  dup scr ! buffer 1024 blank update ;


{ 0 erase-screen flush -> }

\ Make sure the test string from before is gone by looking for space
\ as the beginning of the ramdrive.
{ s"           " 0 ramdrive 10 compare -> 0 }

\ Enter screens for testing LOAD and THRU
1 enter-screen
( Test screen 1 )
( 1 ) variable testvalue
( 2 ) testvalue 5 !
( 3 ) variable blkinscreen
( 4 ) blk @ blkinscreen !
( 5 ) variable blkinstring
( 6 ) s" blk @ blkinstring !" evaluate
( 7 ) variable blkinscreenA
( 8 ) blk @ blkinscreenA !
( 9 )
( 10 )
( 11 )
( 12 )
( 13 )
( 14 )
( 15 )

\ Load screen 1 and then check for the expected side effects.
{ 1 load -> }

\ BLK should be 0 while in the string and 1 while in the rest of the block.
{ blkinscreen @  -> 1 }
{ blkinstring @  -> 0 }
{ blkinscreenA @ -> 1 }

2 enter-screen
( Test screen 2 )
( 1 ) ( Test loading another screen )
( 2 ) variable shouldbe19 ( when "2 3 thru" is run)
( 3 ) 5 shouldbe19 !
( 4 ) variable blkinscreenB
( 5 ) blk @ blkinscreenB ! ( should be 2 )
( 6 ) 3 load
( 7 ) blk @ constant blkinscreenD ( try a different method )
( 8 )
( 9 )
( 10 )
( 11 )
( 12 )
( 13 )
( 14 )
( 15 ) 

3 enter-screen
( Test screen 2 )
( 1 ) 
( 2 ) 
( 3 ) shouldbe19 @ 7 + shouldbe19 !
( 4 ) 
( 5 ) 
( 6 ) 
( 7 ) 
( 8 )
( 9 )
( 10 )
( 11 )
( 12 )
( 13 )
( 14 ) ( blkinscreen4 should be 3 because we are on screen 3 )
( 15 ) ( testing the last line )     blk @ constant blkinscreenC

{ 2 list -> }
{ scr @ -> 2 } \ Screen 2 is the last one we listed.

\ Load screens 2 and 3 with THRU and check for side effects.
\ shouldbe19 should be 5 + 7 + 7 because screen 2 loads screen 3.
{ 2 3 thru -> }

{ blkinscreenB @ -> 2  } \ Note: blkinscreen3 is a variable.
{ blkinscreenC   -> 3  } \ Note: blkinscreen4 is a constant.
{ blkinscreenD   -> 2  } \ Note: blkinscreen5 is a constant.
{ shouldbe19 @   -> 19 }

\ Release all of the memory used.
block_tests
