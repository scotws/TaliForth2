\ List of high-level Forth words for Tali Forth 2 for the 65c02
\ Scot W. Stevenson <scot.stevenson@gmail.com>
\ This version: 24. Okt 2018

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
        : u.r >r 0 <# #s #> r> over - spaces type ;
        : .r >r dup abs 0 <# #s rot sign #> r> over - spaces type ;
        : ud. <# #s #> type space ;
        : ud.r >r <# #s #> r> over - spaces type ;
        : d. tuck dabs <# #s rot sign #> type space ;
        : d.r >r tuck dabs <# #s rot sign #> r> over - spaces type ;

\ Temporary high-level words. TODO convert these to assembler
        : 2constant ( d -- ) create swap , , does> dup @ swap cell+ @ ;
        : 2literal ( d -- ) swap postpone literal postpone literal ; immediate


\ ===============================================================
\ Support for the optional BLOCK word set
decimal

\ This code allots one single buffer in the dictionary.
\ TODO: In the future, allow the user to specify how many buffers they
\ want and allocate them at the end of available RAM.

\ This is reference ANS implementation for buffer:.        
: buffer: ( u "<name> -- ; -- addr )  create allot ;

1024 buffer: blkbuffer ( Single 1024 byte buffer )
variable buffblocknum  0 buffblocknum !
variable buffstatus  0 buffstatus ! ( bit 0 = used, bit 1 = dirty )

\ These are the required variables for the BLOCK word set.
variable blk  0 blk !
variable scr  0 scr !

\ These deferred words need to be redirected to the user's versions
\ before any of the BLOCK word set words are used.  Both of these
\ words take ( buffer_address block# -- )
defer block-read  ( addr u -- ) 
defer block-write ( addr u -- ) 

\ Provide a good message if the user tries to use block words before
\ updating BLOCK-READ or BLOCK-WRITE.
\ TODO: Provide the user a small RAMDRIVE version instead.
: block-words-deferred
    cr ." Please assign deferred words BLOCK-READ and BLOCK-WRITE "
    ." to your routines, eg. " 
    cr ." ' myreadroutine IS BLOCK-READ" cr
    abort
;

' block-words-deferred is block-read
' block-words-deferred is block-write   
    

: save-buffers ( -- )
    buffstatus @ 3 = if
        ( buffer is in use and dirty - flush buffer to storage )
        blkbuffer buffblocknum @ block-write
        ( mark buffer as clean )
        1 buffstatus !
    then ;

: block ( u -- addr ) ( blocknum -- buffer_addr )
  ( Check for request for the current block )
  dup buffblocknum @ = if    ( Check if it's already in the buffer)
      buffstatus @ 1 and if  ( and make sure the buffer is in use )
          ( It's already in the buffer )
          drop blkbuffer exit
      then
  then
  ( Check if the current block is in use and dirty )
  buffstatus @ 3 = if
    ( buffer is in use and dirty - flush buffer to storage )
    blkbuffer buffblocknum @ block-write
  then
  ( Get the requested block )
  dup buffblocknum !
  blkbuffer swap block-read
  ( Mark buffer as in-use and clean )
  1 buffstatus !
  blkbuffer ( return block buffer address ) ;

: update ( -- ) buffstatus @ 2 or buffstatus ! ;

: buffer ( u -- addr ) ( blocknum -- buffer_addr )
    \ Similar to BLOCK, only it doesn't read.
    buffstatus @ 3 = if
        ( buffer is in use and dirty - flush buffer to storage )
        blkbuffer buffblocknum @ block-write
    then
    buffblocknum !
    ( Mark buffer as in-use and clean )
    1 buffstatus !
    blkbuffer ( return block buffer address ) ;
    
: empty-buffers ( -- ) 0 buffstatus ! ;

: flush ( -- ) save-buffers empty-buffers ;

\ Note: LOAD currently works because there is only one buffer.
\ if/when multiple buffers are supported, we'll have to deal
\ with the fact that it might re-load the old block into a
\ different buffer.
: load ( scr# - )
  blk @ >r                  ( We only need to save BLK     )
                            ( - evaluate saves the rest    )
  dup blk !                 ( Set BLK to the new block     )
    
  block                     ( Load the block into a buffer )
  1024 evaluate             ( Evaluate the entire block    )

  r> dup blk !              ( Restore the previous block   ) 
  ?dup if block drop then ; ( and read it back in if not 0 )

: thru ( scr# scr# - ) 1+ swap ?do i load loop ;

\ The standard says to extend EVALUATE to include storing a 0
\ in BLK.  I'm also restoring the previous value when done.
: evaluate blk @ >r 0 blk ! evaluate r> blk ! ;

\ ===============================================================
\ List ( beginnings of editor )
( Simple Editor for screens /blocks )

( List the current screen)
: L  ( - )
    scr @ block                  ( Load the screen         )
    cr ." Screen #" scr @ 4 u.r  ( Print the screen number )
    16 0 do
        cr i 2 u.r space         ( Print the line number   )
        dup i 64 * + 64 type     ( Print the line          )
    loop cr drop ;

( List a given screen )
: list  ( scr# - )
    scr ! ( Save the screen number )
    L ;   ( Print the screen       )

\ ===============================================================
\ BLOCK Add-ons

\ Provide a word to create a RAM drive, with the given number of
\ blocks, in the dictionary along with setting up the block words to
\ use it.  The read/write routines do not provide bounds checking.
\ Expected use: 4 block-ramdrive-init ( to create blocks 0-3 )

: block-ramdrive-init ( u -- )
s" decimal
  1024 * ( Calculate how many bytes are needed for numblocks blocks )
  dup    ( Save a copy for formatting it at the end )  
  buffer: ramdrive ( Create ramdrive )
  ( These routines just copy between the buffer and the ramdrive blocks )  
  : block-read-ramdrive  ( addr u -- ) 
      ramdrive swap 1024 * + swap 1024 move ; 
  : block-write-ramdrive ( addr u -- ) 
      ramdrive swap 1024 * +      1024 move ; 
  ' block-read-ramdrive  is block-read 
  ' block-write-ramdrive is block-write 
  ramdrive swap blank" ( Format with spaces using the calculated size )
  evaluate  ( Create everything )
;

\ ===============================================================
        
        
\ Splash strings. We leave these as high-level words because they are
\ generated at the end of the boot process and signal that the other
\ high-level definitions worked (or at least didn't crash)
        cr .( Tali Forth 2 for the 65c02)
        cr .( Version BETA 03. Nov 2018 )
        cr .( Copyright 2014-2018 Scot W. Stevenson)
        cr .( Tali Forth 2 comes with absolutely NO WARRANTY)
        cr .( Type 'bye' to exit) cr
\ END
