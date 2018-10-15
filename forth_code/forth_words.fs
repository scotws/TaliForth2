\ List of high-level Forth words for Tali Forth 2 for the 65c02
\ Scot W. Stevenson <scot.stevenson@gmail.com>
\ This version: 22. Sep 2018

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

create blkbuffer 1024 allot ( Single 1024 byte buffer )
variable buffblocknum 0 buffblocknum !
variable buffstatus 0 buffstatus ! ( bit 0 = used, bit 1 = dirty )


\ These are the required variables for the BLOCK word set.

variable blk 0 blk !
variable scr 0 scr !


\ These deferred words need to be redirected to the user's versions
\ before any of the BLOCK word set words are used.  Both of these
\ words take ( buffer_address block# -- )
defer BLOCKREAD  ( addr u -- ) 
defer BLOCKWRITE ( addr u -- ) 

\ Provide a good message if the user tries to use block words before
\ updating BLOCKREAD or BLOCKWRITE.
\ TODO: Provide the user a small RAMDRIVE version instead.
: block_words_deferred
    cr ." Please assign deferred words BLOCKREAD and BLOCKWRITE "
    ." to your routines, eg. " cr ." ' myreadroutine IS BLOCKREAD" cr
    abort
;

' block_words_deferred is BLOCKREAD
' block_words_deferred is BLOCKWRITE   
    

: SAVE-BUFFERS ( -- )
    buffstatus @ 3 = if
        ( buffer is in use and dirty - flush buffer to storage )
        blkbuffer buffblocknum @ BLOCKWRITE
        ( mark buffer as clean )
        1 buffstatus !
    then ;
    

: BLOCK ( u -- addr ) ( blocknum -- buffer_addr )
  ( Check for request for the current block )
  dup buffblocknum @ = if   ( check if it's already in the buffer)
  buffstatus @ 1 and if   ( and make sure the buffer is in use )
    drop blkbuffer exit then then
  ( Check if the current block is dirty )
  buffstatus @ 3 = if
    ( buffer is in use and dirty - flush buffer to storage )
    blkbuffer buffblocknum @ BLOCKWRITE
  then
  ( Get the requested block )
  dup buffblocknum !
  blkbuffer swap BLOCKREAD
  ( Mark buffer as in-use and clean )
  1 buffstatus !
  blkbuffer ( return block buffer address ) ;

: UPDATE ( -- ) buffstatus @ 2 or buffstatus ! ;

: BUFFER ( u -- addr ) ( blocknum -- buffer_addr )
    \ Similar to BLOCK, only it doesn't read.
    buffstatus @ 3 = if
        ( buffer is in use and dirty - flush buffer to storage )
        blkbuffer buffblocknum @ BLOCKWRITE
    then
    buffblocknum !
    ( Mark buffer as in-use and clean )
    1 buffstatus !
    blkbuffer ( return block buffer address ) ;
    
: EMPTY-BUFFERS ( -- ) 0 buffstatus ! ;

: FLUSH ( -- ) save-buffers empty-buffers ;

\ Note: LOAD currently works because there is only one buffer.
\ if/when multiple buffers are supported, we'll have to deal
\ with the fact that it might re-load the old block into a
\ different buffer.
decimal
: LOAD ( scr# - )
  BLK @ >R                  ( We only need to save BLK    )
  BLK !                     ( Set BLK to the new block    )
  16 0 do                   ( Evaluate the block          )
    BLK @ block             ( Make sure the block is here )
    i 64 * +                ( Calculate offset to line    )
    ( dup 64 cr type key drop )          ( DEBUG )
    64 (  .s key drop  ) evaluate             ( Evaluate one line at a time )
  loop
  R> dup BLK !              ( Restore the previous block ) 
  ?dup if block drop then ; ( and load it if not 0       )

: THRU ( scr# scr# - ) 1+ swap ?do i load loop ;

\ The standard says to extend EVALUATE to include storing a 0
\ in BLK.  I'm also restoring the previous value when done.
: evaluate blk @ >r 0 blk ! evaluate r> blk ! ;


\ ===============================================================
\ BLOCK Add-ons

\ Provide a word to create a RAM drive with 4 blocks (0-3) in the
\ dictionary.  RAMDRIVE takes the block number and returns the address
\ in ram.  It provides no bounds checking.
: block_init_ramdrive
  s" decimal : ramblocks create 1024 4 * allot does> swap 1024 * + ; 
  ramblocks ramdrive 
  : blockread_ramdrive  ( addr u -- ) ramdrive swap 1024 move ; 
  : blockwrite_ramdrive ( addr u -- ) ramdrive      1024 move ; 
  ' blockread_ramdrive is blockread ' blockwrite_ramdrive is blockwrite 
  0 ramdrive 1024 4 * blank" 
  evaluate                ( Create everything  )
;

\ ===============================================================
        
        
\ Splash strings. We leave these as high-level words because they are
\ generated at the end of the boot process and signal that the other
\ high-level definitions worked (or at least didn't crash)
        cr .( Tali Forth 2 for the 65c02)
        cr .( Version BETA 10. Oct 2018 )
        cr .( Copyright 2014-2018 Scot W. Stevenson)
        cr .( Tali Forth 2 comes with absolutely NO WARRANTY)
        cr .( Type 'bye' to exit) cr
\ END
