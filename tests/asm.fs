\ ------------------------------------------------------------------------
testing assembler words

marker asm-tests 

\ Add assembler wordlist. This currently kills <true>
forth-wordlist assembler-wordlist 2 set-order


: opcode-test ( opc len addr u -- f )
   here        ( opc len addr u here0 )
   dup >r      ( opc len addr u here0 ) ( R: here0 )
   -rot        ( opc len here0 addr u ) ( R: here0 )
   evaluate    ( opc len here0 ) ( R: here0 )

   \ See if length is correct
   here swap -    ( opc len n ) ( R: here0 )
   =              ( opc f ) ( R: here0 )
   swap           ( f opc ) ( R: here0 )

   \ See if opcode is correct. We can't use AND for the last step because that
   \ is replaced by the assembler instruction of the same name
   r> c@          ( f opc c )
   =              ( f f ) 
;

\ Test for little endian behavior with three-byte instructions
\ For instance, 'sta 1122' must become 8D 22 11. Note that Tali stores the cell
\ values little-endian as well, which makes this test confusing at first glance.
\ Insert  CR DUP 3 DUMP CR  after EVALUTE to convince yourself that this is okay
: little-endian? ( u-want addr u -- f )
   here -rot      ( u-want here0 addr u )
   evaluate       ( u-want here0 )
   \ cr dup 3 dump cr   \ Manual check for paranoia
   1+             ( u-want here0+1 ) \ Skip opcode
   @              ( u-want u-have )
   =              ( f ) 
;

\ Testing all assembler instructions: Opcode and length
T{ 0ea 1 s" nop" opcode-test -> -1 -1 }T
T{ 0a9 2 s" 0ff lda.#" opcode-test -> -1 -1 }T

\ Testing all three-byte instructions: Little endian
T{ 1122 s" 1122 sta" little-endian? -> -1 }T


\ Testing pseudo-instructions
T{ here  0a lda.# push-a  execute -> 0a }T


\ Testing directives
\ TODO currently no directives available


\ Return to original state
decimal  only  asm-tests
