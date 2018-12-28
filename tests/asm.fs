\ ------------------------------------------------------------------------
testing assembler words

marker asm-tests 
assembler-wordlist >order
assembler-wordlist set-current
hex

\ Test code length and correct operand insertion
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
   \ cr dup 3 dump cr   \ Manual check, insert if paranoia attacks
   1+             ( u-want here0+1 ) \ Skip opcode
   @              ( u-want u-have )
   =              ( f ) 
;

\ Test correct operand for two-byte instructions. Note there is little
\ difference between this code and little-endian? at the moment. However, this
\ routine here will have to modified for branch instructions at a later date.
: correct-operand? ( u-want addr u -- f )
   here -rot      ( u-want here0 addr u )
   evaluate       ( u-want here0 )
   1+             ( u-want here0+1 )
   c@             ( u-want u-got )
   =              ( f )
; 

\ Make lookups of these numbers faster.  They won't have to fall through
\ to NUMBER and they will be at beginning of dictionary.
: 12 12 ;
: 1122 1122 ;
: 3 3 ;

\ --------------------------------------------------------------------------

\ Testing pseudo-instructions
T{ here  0a lda.# push-a rts  execute -> 0a }T

\ Testing a two-byte instruction for correct operand handling
T{ 12 s" 12 lda.#" correct-operand? -> true }T

\ Testing a three-byte instruction for little endian handling
T{ 1122 s" 1122 sta" little-endian? -> true }T

\ Testing all assembler instructions: Opcode and length
T{ 069 2 s" 12 adc.#" opcode-test -> true true }T
T{ 07D 3 s" 1122 adc.x" opcode-test -> true true }T
T{ 079 3 s" 1122 adc.y" opcode-test -> true true }T
T{ 065 2 s" 12 adc.z" opcode-test -> true true }T
T{ 072 2 s" 12 adc.zi" opcode-test -> true true }T
T{ 071 2 s" 12 adc.ziy" opcode-test -> true true }T
T{ 075 2 s" 12 adc.zx" opcode-test -> true true }T
T{ 061 2 s" 12 adc.zxi" opcode-test -> true true }T
T{ 02D 3 s" 1122 and." opcode-test -> true true }T
T{ 029 2 s" 12 and.#" opcode-test -> true true }T
T{ 03D 3 s" 1122 and.x" opcode-test -> true true }T
T{ 039 3 s" 1122 and.y" opcode-test -> true true }T
T{ 025 2 s" 12 and.z" opcode-test -> true true }T
T{ 032 2 s" 12 and.zi" opcode-test -> true true }T
T{ 031 2 s" 12 and.ziy" opcode-test -> true true }T
T{ 035 2 s" 12 and.zx" opcode-test -> true true }T
T{ 021 2 s" 12 and.zxi" opcode-test -> true true }T
T{ 00E 3 s" 1122 asl" opcode-test -> true true }T
T{ 00A 1 s" asl.a" opcode-test -> true true }T
T{ 01E 3 s" 1122 asl.x" opcode-test -> true true }T
T{ 006 2 s" 12 asl.z" opcode-test -> true true }T
T{ 016 2 s" 12 asl.zx" opcode-test -> true true }T
T{ 090 2 s" 12 bcc" opcode-test -> true true }T
T{ 0B0 2 s" 12 bcs" opcode-test -> true true }T
T{ 0F0 2 s" 12 beq" opcode-test -> true true }T
T{ 02C 3 s" 1122 bit" opcode-test -> true true }T
T{ 089 2 s" 12 bit.#" opcode-test -> true true }T
T{ 03C 3 s" 1122 bit.x" opcode-test -> true true }T
T{ 024 2 s" 12 bit.z" opcode-test -> true true }T
T{ 034 2 s" 12 bit.zx" opcode-test -> true true }T
T{ 030 2 s" 12 bmi" opcode-test -> true true }T
T{ 0D0 2 s" 12 bne" opcode-test -> true true }T
T{ 010 2 s" 12 bpl" opcode-test -> true true }T
T{ 080 2 s" 12 bra" opcode-test -> true true }T
T{ 000 2 s" 12 brk" opcode-test -> true true }T
T{ 050 2 s" 12 bvc" opcode-test -> true true }T
T{ 070 2 s" 12 bvs" opcode-test -> true true }T
T{ 018 1 s" clc" opcode-test -> true true }T
T{ 0D8 1 s" cld" opcode-test -> true true }T
T{ 058 1 s" cli" opcode-test -> true true }T
T{ 0B8 1 s" clv" opcode-test -> true true }T
T{ 0CD 3 s" 1122 cmp" opcode-test -> true true }T
T{ 0C9 2 s" 12 cmp.#" opcode-test -> true true }T
T{ 0DD 3 s" 1122 cmp.x" opcode-test -> true true }T
T{ 0D9 3 s" 1122 cmp.y" opcode-test -> true true }T
T{ 0C5 2 s" 12 cmp.z" opcode-test -> true true }T
T{ 0D2 2 s" 12 cmp.zi" opcode-test -> true true }T
T{ 0D1 2 s" 12 cmp.ziy" opcode-test -> true true }T
T{ 0D5 2 s" 12 cmp.zx" opcode-test -> true true }T
T{ 0C1 2 s" 12 cmp.zxi" opcode-test -> true true }T
T{ 0EC 3 s" 1122 cpx" opcode-test -> true true }T
T{ 0E0 2 s" 12 cpx.#" opcode-test -> true true }T
T{ 0E4 2 s" 12 cpx.z" opcode-test -> true true }T
T{ 0CC 3 s" 1122 cpy" opcode-test -> true true }T
T{ 0C0 2 s" 12 cpy.#" opcode-test -> true true }T
T{ 0C4 2 s" 12 cpy.z" opcode-test -> true true }T
T{ 0CE 3 s" 1122 dec" opcode-test -> true true }T
T{ 03A 1 s" dec.a" opcode-test -> true true }T
T{ 0DE 3 s" 1122 dec.x" opcode-test -> true true }T
T{ 0C6 2 s" 12 dec.z" opcode-test -> true true }T
T{ 0D6 2 s" 12 dec.zx" opcode-test -> true true }T
T{ 0CA 1 s" dex" opcode-test -> true true }T
T{ 088 1 s" dey" opcode-test -> true true }T
T{ 04D 3 s" 1122 eor" opcode-test -> true true }T
T{ 049 2 s" 12 eor.#" opcode-test -> true true }T
T{ 05D 3 s" 1122 eor.x" opcode-test -> true true }T
T{ 059 3 s" 1122 eor.y" opcode-test -> true true }T
T{ 045 2 s" 12 eor.z" opcode-test -> true true }T
T{ 052 2 s" 12 eor.zi" opcode-test -> true true }T
T{ 051 2 s" 12 eor.ziy" opcode-test -> true true }T
T{ 055 2 s" 12 eor.zx" opcode-test -> true true }T
T{ 041 2 s" 12 eor.zxi" opcode-test -> true true }T
T{ 0EE 3 s" 1122 inc" opcode-test -> true true }T
T{ 01A 1 s" inc.a" opcode-test -> true true }T
T{ 0FE 3 s" 1122 inc.x" opcode-test -> true true }T
T{ 0E6 2 s" 12 inc.z" opcode-test -> true true }T
T{ 0F6 2 s" 12 inc.zx" opcode-test -> true true }T
T{ 0E8 1 s" inx" opcode-test -> true true }T
T{ 0C8 1 s" iny" opcode-test -> true true }T
T{ 04C 3 s" 1122 jmp" opcode-test -> true true }T
T{ 06C 3 s" 1122 jmp.i" opcode-test -> true true }T
T{ 07C 3 s" 1122 jmp.xi" opcode-test -> true true }T
T{ 020 3 s" 1122 jsr" opcode-test -> true true }T
T{ 0AD 3 s" 1122 lda" opcode-test -> true true }T
T{ 0A9 2 s" 12 lda.#" opcode-test -> true true }T
T{ 0BD 3 s" 1122 lda.x" opcode-test -> true true }T
T{ 0B9 3 s" 1122 lda.y" opcode-test -> true true }T
T{ 0A5 2 s" 12 lda.z" opcode-test -> true true }T
T{ 0B2 2 s" 12 lda.zi" opcode-test -> true true }T
T{ 0B1 2 s" 12 lda.ziy" opcode-test -> true true }T
T{ 0B5 2 s" 12 lda.zx" opcode-test -> true true }T
T{ 0A1 2 s" 12 lda.zxi" opcode-test -> true true }T
T{ 0AE 3 s" 1122 ldx" opcode-test -> true true }T
T{ 0A2 2 s" 12 ldx.#" opcode-test -> true true }T
T{ 0BE 3 s" 1122 ldx.y" opcode-test -> true true }T
T{ 0A6 2 s" 12 ldx.z" opcode-test -> true true }T
T{ 0B6 2 s" 12 ldx.zy" opcode-test -> true true }T
T{ 0AC 3 s" 1122 ldy" opcode-test -> true true }T
T{ 0A0 2 s" 12 ldy.#" opcode-test -> true true }T
T{ 0BC 3 s" 1122 ldy.x" opcode-test -> true true }T
T{ 0A4 2 s" 12 ldy.z" opcode-test -> true true }T
T{ 0B4 2 s" 12 ldy.zx" opcode-test -> true true }T
T{ 04E 3 s" 1122 lsr" opcode-test -> true true }T
T{ 04A 1 s" lsr.a" opcode-test -> true true }T
T{ 05E 3 s" 1122 lsr.x" opcode-test -> true true }T
T{ 046 2 s" 12 lsr.z" opcode-test -> true true }T
T{ 056 2 s" 12 lsr.zx" opcode-test -> true true }T
T{ 0EA 1 s" nop" opcode-test -> true true }T
T{ 00D 3 s" 1122 ora" opcode-test -> true true }T
T{ 009 2 s" 12 ora.#" opcode-test -> true true }T
T{ 01D 3 s" 1122 ora.x" opcode-test -> true true }T
T{ 019 3 s" 1122 ora.y" opcode-test -> true true }T
T{ 005 2 s" 12 ora.z" opcode-test -> true true }T
T{ 012 2 s" 12 ora.zi" opcode-test -> true true }T
T{ 011 2 s" 12 ora.ziy" opcode-test -> true true }T
T{ 015 2 s" 12 ora.zx" opcode-test -> true true }T
T{ 001 2 s" 12 ora.zxi" opcode-test -> true true }T
T{ 048 1 s" pha" opcode-test -> true true }T
T{ 008 1 s" php" opcode-test -> true true }T
T{ 0DA 1 s" phx" opcode-test -> true true }T
T{ 05A 1 s" phy" opcode-test -> true true }T
T{ 068 1 s" pla" opcode-test -> true true }T
T{ 028 1 s" plp" opcode-test -> true true }T
T{ 0FA 1 s" plx" opcode-test -> true true }T
T{ 07A 1 s" ply" opcode-test -> true true }T
T{ 02E 3 s" 1122 rol" opcode-test -> true true }T
T{ 02A 1 s" rol.a" opcode-test -> true true }T
T{ 03E 3 s" 1122 rol.x" opcode-test -> true true }T
T{ 026 2 s" 12 rol.z" opcode-test -> true true }T
T{ 036 2 s" 12 rol.zx" opcode-test -> true true }T
T{ 06E 3 s" 1122 ror" opcode-test -> true true }T
T{ 06A 1 s" ror.a" opcode-test -> true true }T
T{ 07E 3 s" 1122 ror.x" opcode-test -> true true }T
T{ 066 2 s" 12 ror.z" opcode-test -> true true }T
T{ 076 2 s" 12 ror.zx" opcode-test -> true true }T
T{ 040 1 s" rti" opcode-test -> true true }T
T{ 060 1 s" rts" opcode-test -> true true }T
T{ 0ED 3 s" 1122 sbc" opcode-test -> true true }T
T{ 0E9 2 s" 12 sbc.#" opcode-test -> true true }T
T{ 0FD 3 s" 1122 sbc.x" opcode-test -> true true }T
T{ 0F9 3 s" 1122 sbc.y" opcode-test -> true true }T
T{ 0E5 2 s" 12 sbc.z" opcode-test -> true true }T
T{ 0F2 2 s" 12 sbc.zi" opcode-test -> true true }T
T{ 0F1 2 s" 12 sbc.ziy" opcode-test -> true true }T
T{ 0F5 2 s" 12 sbc.zx" opcode-test -> true true }T
T{ 0E1 2 s" 12 sbc.zxi" opcode-test -> true true }T
T{ 038 1 s" sec" opcode-test -> true true }T
T{ 0F8 1 s" sed" opcode-test -> true true }T
T{ 078 1 s" sei" opcode-test -> true true }T
T{ 08D 3 s" 1122 sta" opcode-test -> true true }T
T{ 09D 3 s" 1122 sta.x" opcode-test -> true true }T
T{ 099 3 s" 1122 sta.y" opcode-test -> true true }T
T{ 085 2 s" 12 sta.z" opcode-test -> true true }T
T{ 092 2 s" 12 sta.zi" opcode-test -> true true }T
T{ 091 2 s" 12 sta.ziy" opcode-test -> true true }T
T{ 095 2 s" 12 sta.zx" opcode-test -> true true }T
T{ 081 2 s" 12 sta.zxi" opcode-test -> true true }T
T{ 08E 3 s" 1122 stx" opcode-test -> true true }T
T{ 086 2 s" 12 stx.z" opcode-test -> true true }T
T{ 096 2 s" 12 stx.zy" opcode-test -> true true }T
T{ 08C 3 s" 1122 sty" opcode-test -> true true }T
T{ 084 2 s" 12 sty.z" opcode-test -> true true }T
T{ 094 2 s" 12 sty.zx" opcode-test -> true true }T
T{ 09C 3 s" 1122 stz" opcode-test -> true true }T
T{ 09E 3 s" 1122 stz.x" opcode-test -> true true }T
T{ 064 2 s" 12 stz.z" opcode-test -> true true }T
T{ 074 2 s" 12 stz.zx" opcode-test -> true true }T
T{ 0AA 1 s" tax" opcode-test -> true true }T
T{ 0A8 1 s" tay" opcode-test -> true true }T
T{ 01C 3 s" 1122 trb" opcode-test -> true true }T
T{ 014 2 s" 12 trb.z" opcode-test -> true true }T
T{ 00C 3 s" 1122 tsb" opcode-test -> true true }T
T{ 004 2 s" 12 tsb.z" opcode-test -> true true }T
T{ 0BA 1 s" tsx" opcode-test -> true true }T
T{ 08A 1 s" txa" opcode-test -> true true }T
T{ 09A 1 s" txs" opcode-test -> true true }T
T{ 098 1 s" tya" opcode-test -> true true }T

\ Testing directives

\ Return to original state
previous
decimal ( only forth definitions ) 
asm-tests
