; Assembler for Tali Forth 2 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 07. Nov 2014 (as tasm65c02)
; This version: 13. Dez 2018

; This is the built-in assembler for Tali Forth 2. Once the assembler wordlist
; is established, the opcodes are available as normal Forth words. The format
; is Simpler Assembler Notation (SAN) which separates the opcode completely
; from the operand. In this case, the operand is entered before the opcode in
; the normal postfix Forth notation (for example, "2000 lda.#"). See the
; assembler documenation in the manual for more detail. SAN itself is discussed
; at https://github.com/scotws/SAN.
;
; The code here was originally used in A Typist's Assembler for the 65c02
; (tasm65c02), see https://github.com/scotws/tasm65c02 for the standalone
; version.

; ==========================================================
; MNEMONICS

; The assembler instructions are realized as individual Forth words with
; entries in the assembler wordlist (see header.asm). They perform a subroutine
; jump (explicitly not an absolute jump) to asm_common, where the address
; stored on the return stack is used to collect the opcode of the instruction
; and its total length in bytes (1 to 3).

; The routines are organized alphabetically by SAN mnemonic, not by opcode.

; TODO decide if we need underflow checking for instructions with operands

xt_asm_nop:      
                jsr asm_common
                .byte $EA, 1
z_asm_nop:


xt_asm_lda_h:   ; lda.# / LDA #$nn
                jsr asm_common
                .byte $A9, 2
z_asm_lda_h:


xt_asm_ldx_h:   ; ldx.# / LDX #$nn
                jsr asm_common
                .byte $A2, 2
z_asm_ldx_h:


; ==========================================================
; PSEUDO-INSTRUCTIONS

xt_asm_push_a:
        ; """push-a puts the content of the 65c02 Accumulator on the Forth
        ; data stack as the TOS.
        ; """
                dex
                dex
                sta 0,x
                stz 1,x

z_asm_push_a:
                rts


; ==========================================================
; ASSEMBLER ROUTINES

asm_common:
.scope
        ; """Common routine for all opcodes. Assumes we arrive here via
        ; a subroutine jump so we can use the address on the Return Stack to
        ; get the opcode of the instruction and its length in bytes. See the
        ; comments in the section on mnemonics above for more details. Uses
        ; tmp1.
        ; """
                ; Get the address off the Return Stack
                pla             ; LSB
                sta tmp1
                pla             ; MSB
                sta tmp1+1

                ; First byte stored is the opcode, the second the number of
                ; bytes. We use an offset of 1 because of the way that the
                ; 65c02 stores the return address of a subroutine jump
                ldy #1
                lda (tmp1),y

                ; Compile opcode. We don't have to check if this is a legal
                ; opcode because we only arrive here from the Dictionary
                ; assembler routines 
                jsr cmpl_a

                ; Get the length of the instruction, which must be 1, 2, or
                ; 3 on the 65c02.
                iny
                lda (tmp1),y

                cmp #1          ; One byte means no operand, we're done
                beq _done

                ; If we have an operand, it means that one way or another we
                ; will be compiling the LSB byte of TOS
                tay             ; Save length for later
                lda 0,x
                jsr cmpl_a      ; does not use Y

                tya
                cmp #2
                beq _done_drop

                ; If we arrive here, the only legal length in bytes is 3. As
                ; with the opcode, we don't perform any checks because we came
                ; here from the Dictionary call for the assembler instruction
                ; and trust our test suite
                lda 1,x         ; MSB
                jsr cmpl_a      ; Fall through to _done_drop

_done_drop:
                inx
                inx             ; Fall through to _done
_done:
                rts             ; Returns to original caller
.scend        

; END
