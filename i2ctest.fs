\ Set up the VIA for I2C.  I'm using the VIA DDR method.

\ PTA7 is data  
\ PTA0 is clock 

hex
7F01 constant via.porta
7f03 constant via.ddra
\ Make port A an input so the bus starts idle.
: i2c-setup 0 via.porta c! 0 via.ddra c! ;
\ Write on PORTA7 (note that 0 = 1 on the I2C bus for writing)
\ Using the data direction register to control the output.
: >SDA ( f -- ) via.ddra c@ swap if 7F and else 80 or then via.ddra c! ;
\ Read on PORTA7 (reading is active high)
: SDA> ( -- f ) via.porta c@ 80 and if 1 else 0 then ;
\ Clock handling (note that 0 = 1 on the I2C bus)
\ Using the data direction register.
: SCL-0 via.ddra c@ 01 or via.ddra c! ;
: SCL-1 via.ddra c@ FE and via.ddra c! ;
: half ; \ No delay = going as fast as possible.

\ Code from http://www.excamera.com/sphinx/article-forth-i2c.html
\ changed radix to hex - SamCo 2018-08-12
( i2c                                        JCB 10:09 08/15/10)
: i2c-start     \ with SCL high, change SDA from 1 to 0
    1 >SDA half SCL-1 half 0 >SDA half SCL-0 ;
: i2c-stop      \ with SCL high, change SDA from 0 to 1
    0 >SDA half SCL-1 half 1 >SDA half ;

: i2c-rx-bit ( -- b )
    1 >SDA half SCL-1 half SDA> SCL-0 ;
: i2c-tx-bit ( f -- )
    0<> >SDA half SCL-1 half SCL-0 ;

: i2c-tx    ( b -- nak )
    8 0 do dup 80 and i2c-tx-bit 2* loop drop i2c-rx-bit ;

\ : i2c-tx2   ( w -- nak ) \ sends LSB first
\    8 0 do dup 8000 and i2c-tx-bit 2* loop i2c-rx-bit drop
\    8 0 do dup 8000 and i2c-tx-bit 2* loop drop i2c-rx-bit ;

: i2c-rx    ( nak -- b )
    0 8 0 do 2* i2c-rx-bit + loop swap i2c-tx-bit ;

hex
( i2c example usage for 8-bit device         JCB 10:09 08/15/10)

: device ( addr -- ) \ common i2c preamble (address $53 writing)
    i2c-start A6 i2c-tx drop 100 /mod i2c-tx drop i2c-tx drop ;

: device! ( v addr -- ) \ write v to i2c register addr
    device i2c-tx drop i2c-stop ;

: device@ ( addr -- v ) \ read i2c register addr
    device i2c-start A7 i2c-tx drop 1 i2c-rx i2c-stop ;

i2c-setup
\ ===================================================
\ Testing code:
 create blkbuffer 400 allot  
 : showblock cr 400 0 do blkbuffer i + c@ . loop ;
 : makeblock 400 0 do i blkbuffer i + c! loop ;
 : resetblock 400 0 do 0 blkbuffer i + c! loop ;
\ Notes: Takes about 4 seconds to read 1K from the EEPROM.


\ ===================================================
\ 24FC1025 code

\ Because the 24FC1025 has 128K addresses, one of the address bits ends
\ up in the I2C address.  This routine takes a block number and computes
\ the eeprom internal byte address and the i2c address to use.  The
\ i2c address has already been shifted left one bit.  Just add 1 to it for
\ reading (by setting the R/W* bit).
hex
: block2eeprom ( u -- u u ) ( blocknum -- eeprom_address i2c_address ) 
    dup 40 < if
        ( Blocks 0-63[decimal] )
        400 * ( multiply block number by 1024[decimal] )
        A0    ( use $50 [shifted left one place] as I2C address )
    else
        ( Blocks 64-127[decimal] - no limit check )
        40 -  ( subtract 64[decimal] from block number )
        400 * ( multiply block number by 1024[decimal] )
        A8    ( use $54 [shiften left one place] as I2C address )
    then ;

: eeprom-pagewrite ( addr u u -- ) ( buffer_address eeprom_address i2c_address -- )
    dup >r ( save the i2c address for later )
    i2c-start i2c-tx drop ( start the i2c frame using computed i2c address )
    100 /mod i2c-tx drop i2c-tx drop ( send the 16-bit address as two bytes )
    80 0 do ( send the 128[decimal] bytes )
        dup i +     ( compute buffer address )
        c@ i2c-tx drop ( send the byte )
    loop drop i2c-stop ( end the frame )
    r> begin ( recall the i2c address and poll until complete )
        dup
        i2c-start i2c-tx ( start the i2c frame using computed i2c address )
    0= until drop
    i2c-stop
    ;


: eeprom-blockwrite ( addr u -- ) ( buffer_address blocknum -- )
    ( Write the entire block buffer one eeprom page [128 bytes] at a time )
    8 0 do
        over i 80 * +      ( offset by eeprom pages into block buffer )
        over block2eeprom
        swap i 80 * + swap ( offset by eeprom pages into eeprom )
        eeprom-pagewrite
    loop
    2drop ;

: eeprom-blockread ( addr u -- ) ( buffer_address blocknum -- )
    block2eeprom dup
    i2c-start i2c-tx drop ( start the i2c frame using computed i2c address )
    swap ( move the eeprom internal address to TOS )
    100 /mod i2c-tx drop i2c-tx drop ( send the 16-bit address as two bytes )
    i2c-start 1+ i2c-tx drop ( send I2C address again with R/W* bit set )
    3FF 0 do ( loop though all but the last byte )
        0 i2c-rx over i + c! 
    loop
    \ Read last byte with NAK to stop.
    1 i2c-rx over 3FF + c! i2c-stop drop ;
        
    
    
\ ====================================================
\ Fourth BLOCK words
hex
create blkbuffer 400 allot
variable buffblocknum 0 buffblocknum !
variable buffstatus 0 buffstatus ! ( bit 0 = used, bit 1 = dirty )
variable blk 0 blk !
variable scr 0 scr !



: SAVE-BUFFERS ( -- )
    buffstatus @ 3 = if
        ( buffer is in use and dirty - flush buffer to storage )
        blkbuffer buffblocknum @ eeprom-blockwrite
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
    blkbuffer buffblocknum @ eeprom-blockwrite
  then
  ( Get the requested block )
  dup buffblocknum !
  blkbuffer swap eeprom-blockread
  ( Mark buffer as in-use and clean )
  1 buffstatus !
  blkbuffer ( return block buffer address ) ;

: UPDATE buffstatus @ 2 or buffstatus ! ;

: BUFFER ( u -- addr ) ( blocknum -- buffer_addr )
    \ Similar to BLOCK, only it doesn't read.
    buffstatus @ 3 = if
        ( buffer is in use and dirty - flush buffer to storage )
        blkbuffer buffblocknum @ eeprom-blockwrite
    then
    buffblocknum !
    ( Mark buffer as in-use and clean )
    1 buffstatus !
    blkbuffer ( return block buffer address ) ;
    
: EMPTY-BUFFERS 0 buffstatus ! ;

: FLUSH save-buffers empty-buffers ;

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

\ Older version that attempts to load entire block.
\ : LOAD ( scr# - )
\    BLK @ >R
\    dup BLK !
\    block 1024 evaluate
\    R> dup BLK !
\    ?dup if block drop then ;

: THRU ( scr# scr# - ) 1+ swap ?do i load loop ;

\ The standard says to extend EVALUATE to include storing a 0
\ in BLK.  I'm also restoring the previous value when done.
 : EVALUATE BLK @ >R 0 BLK ! EVALUATE R> BLK ! ;


\ ----------------------------
( Simple Editor for screens /blocks )
decimal
: L  ( - )
    scr @ block                  ( Load the screen )
    cr ." Screen #" scr @ 4 u.r  ( Print the screen number )
    16 0 do
        cr i 2 u.r space       ( Print the line number )
        dup i 64 * + 64 type     ( Print the line )
    loop cr drop ;

: list  ( scr# - )
    scr ! ( Save the screen number)
    L ;       ( Print the screen )

( Editor, continued )
( line provides the address, in the buffer, of the given line )
: line  ( line# - c-addr)
    64 *        ( Convert line number to # characters offset )
    scr @ block ( Get the buffer address for that block )
    + ;         ( Add the offset )

: E ( line# - ) ( Erase the given line number with spaces )
    line 64 blank update ;

: O     ( line# - )
    dup E                    ( Erase existing text on line )
    cr dup . ."  * " line 64 accept drop update ;

( Editor, continued )
: enter-screen ( scr# - )
  dup scr ! buffer drop
  16 0 do i o loop ;
: erase-screen ( scr# - )
  dup scr ! buffer 1024 blank update ;

    

