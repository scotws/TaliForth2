; Disassembler for Tali Forth 2
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 28. Apr 2018
; This version: 03. Jan 2019

; This is the default disassembler for Tali Forth 2. Use by passing
; the address and length of the block of memory to be disassembled:
;
;       disasm ( addr x -- )

; The underflow checking is handled by the word's stub in native_words.asm, see
; there for more information.

; The code is disassembled in Simpler Assembler Notation (SAN), because that
; is, uh, simpler. See the documentation and https://github.com/scotws/SAN for
; more information. Because disassemblers are used interactively with slow
; humans, we don't care that much about speed and put the emphasis at being
; small.

.scope
disassembler:
                jsr xt_cr       ; ( addr u )
_byte_loop:
                ; Print address at start of the line. Note we use whatever
                ; number base the user has
                jsr xt_over     ; ( addr u addr )
                jsr xt_u_dot    ; ( addr u )
                jsr xt_space

                ; We use the opcode value as the offset in the oc_index_table.
                ; We have 256 entries, each two bytes long, so we can't just
                ; use an index with Y. We use tmp2 for this.
                lda #<oc_index_table
                sta tmp2
                lda #>oc_index_table
                sta tmp2+1

                lda (2,x)       ; get opcode that addr points to

                asl             ; multiply by two for offset
                bcc +
                inc tmp2+1      ; we're on second page
*
                tay             ; use Y as the index

                ; Get address of the entry in the opcode table. We put it
                ; in tmp3 and push a copy of it to the stack to be able to
                ; print the opcode later
                lda (tmp2),y    ; LSB
                sta tmp3
                pha

                iny

                lda (tmp2),y    ; MSB
                sta tmp3+1
                pha

                ; The first byte is the "lengths byte" which is coded so
                ; that bits 7 to 6 are the length of the instruction (1 to
                ; 3 bytes) and 2 to 0 are the length of the mnemonic.
                lda (tmp3)
                tay                     ; save copy of lengths byte

                ; Since this is Simpler Assembler Notation (SAN) in a Forth
                ; system, we want to print any operand before we print the
                ; mnemonic ('1000 sta' instead of 'sta 1000'). This allows us
                ; to copy and paste directly from the disassembler to the
                ; assembler.

                ; What happens next depends on the length of the instruction in
                ; bytes:

                ;   1 byte:  OPC          -->          OPC  bit sequence: %01
                ;   2 bytes: OPC LSB      -->    0 LSB OPC  bit sequence: %10
                ;   3 bytes: OPC LSB MSB  -->  MSB LSB OPC  bit sequence: %11

                ; We can distinguish between the first case, where there is
                ; only the mnemonic, and the second and third cases, where we
                ; have an operand. We do this by use of the bit sequence in
                ; bits 7 and 6.
                bpl _no_operand         ; bit 7 clear, single-byte instruction

                ; We have an operand. Prepare the Data Stack
                jsr xt_zero             ; ( addr u 0 ) ZERO does not use Y

                ; Because of the glory of a little endian CPU, we can start
                ; with the next byte regardless if this is a one or two byte
                ; operand, because we'll need the LSB one way or the other.
                ; We have a copy of the opcode on the stack, so we can now move
                ; to the next byte
                inc 4,x
                bne +
                inc 5,x                 ; ( addr+1 u 0 )
*
                lda 2,x
                bne +
                dec 3,x
*
                dec 2,x                 ; ( addr+1 u-1 0 )

                lda (4,x)
                sta 0,x                 ; LSB of operand ( addr+1 u-1 LSB )

                ; We still have a copy of the lengths byte in Y, which we use
                ; to see if we have a one-byte operand (and are done already)
                ; or a two-byte operand
                tya                     ; retrieve copy of lengths byte
                rol                     ; shift bit 6 to bit 7
                bpl _print_operand

                ; We have a three-byte instruction, so we need to get the MSB
                ; of the operand. Move to the next byte
                inc 4,x
                bne +
                inc 5,x                 ; ( addr+2 u-1 LSB )
*
                lda 2,x
                bne +
                dec 3,x
*
                dec 2,x                 ; ( addr+2 u-2 LSB )

                lda (4,x)
                sta 1,x                 ; MSB of operand ( addr+2 u-2 opr )

                ; fall through to _print_operand

_print_operand:

                ; We arrive here with the lengths byte in Y, the address of the
                ; opcode table entry for the instruction on the stack ( addr+n
                ; u-n opr). We want the output to be nicely formatted in
                ; columns, so we use U.R. The maximal width of the number in
                ; decimal on an 16-bit addressed machine is five characters
                dex
                dex
                lda #5
                sta 0,x
                stz 1,x                 ; ( addr+n u-n opr 5 )

                jsr xt_u_dot_r          ; U.R ( addr+n u-n )

                bra _print_mnemonic

_no_operand:
                ; We arrive here with the opcode table address on the stack,
                ; the lengths byte in Y and ( addr u ). Since we want to have
                ; a nicely formatted output, we need to indent the mnemonic by
                ; five spaces.
                dex
                dex
                lda #5
                sta 0,x
                stz 1,x                 ; ( addr u 5 )

                jsr xt_spaces           ; ( addr u )

                ; fall through to _print_mnemonic

_print_mnemonic:
                ; We arrive here with the opcode table address on the stack and
                ; ( addr u | addr+n u-n ). Time to print the mnemonic.
                jsr xt_space

                dex
                dex                     ; ( addr u ? )
                pla                     ; MSB
                sta 1,x                 ; ( addr u MSB )
                pla                     ; LSB
                sta 0,x                 ; ( addr u addr-o )

                jsr xt_count            ; ( addr u addr-o u-o )

                ; The length of the mnemnonic string is in bits 2 to 0
                stz 1,x                 ; paranoid
                lda 0,x
                and #%00000111          ; ( addr u addr-o u-o )
                sta 0,x

                jsr xt_type             ; ( addr u )
                jsr xt_cr

                ; Housekeeping: Next byte
                inc 2,x
                bne +
                inc 3,x                 ; ( addr+1 u )
*
                jsr xt_one_minus        ; ( addr+1 u-1 )

                lda 0,x                 ; All done?
                ora 1,x
                beq _done

                lda 1,x                 ; Catch mid-instruction ranges
                bmi _done

                jmp _byte_loop          ; out of range for BRA
_done:
                ; Clean up and leave
                jmp xt_two_drop         ; JSR/RTS
.scend

; =========================================================
oc_index_table:
        ; Lookup table for the instruction data (length of instruction in
        ; bytes, length of mnemonic in bytes, mnemonic string). This is used by
        ; the assembler as well.

        ; Opcodes 00-0F
        .word oc00, oc01, oc__, oc__, oc04, oc05, oc06, oc__
        .word oc08, oc09, oc0a, oc__, oc0c, oc0d, oc0e, oc0f

        ; Opcodes 10-1F
        .word oc10, oc11, oc12, oc__, oc14, oc15, oc16, oc17
        .word oc18, oc19, oc1a, oc__, oc1c, oc1d, oc__, oc1f

        ; Opcodes 20-2F
        .word oc20, oc21, oc__, oc__, oc24, oc25, oc26, oc27
        .word oc28, oc29, oc2a, oc__, oc2c, oc2d, oc2e, oc2f

        ; Opcodes 30-3F
        .word oc30, oc31, oc32, oc__, oc34, oc35, oc36, oc37
        .word oc38, oc39, oc3a, oc__, oc3c, oc3d, oc3e, oc0f

        ; Opcodes 40-4F
        .word oc40, oc41, oc__, oc__, oc__, oc45, oc46, oc47
        .word oc48, oc49, oc4a, oc__, oc4c, oc4d, oc4e, oc4f

        ; Opcodes 50-5F
        .word oc50, oc51, oc52, oc__, oc__, oc55, oc56, oc57
        .word oc58, oc59, oc5a, oc__, oc__, oc__, oc5e, oc5f

        ; Opcodes 60-6F
        .word oc60, oc61, oc__, oc__, oc64, oc65, oc66, oc67
        .word oc68, oc69, oc6a, oc__, oc6c, oc6d, oc6e, oc6f

        ; Opcodes 70-7F
        .word oc70, oc71, oc72, oc__, oc74, oc75, oc76, oc77
        .word oc78, oc79, oc7a, oc__, oc7c, oc7d, oc7e, oc7f

        ; Opcodes 80-8F
        .word oc80, oc81, oc__, oc__, oc84, oc85, oc86, oc__
        .word oc88, oc89, oc8a, oc__, oc8c, oc8d, oc8e, oc8f

        ; Opcodes 90-9F
        .word oc90, oc91, oc92, oc__, oc94, oc95, oc96, oc97
        .word oc98, oc99, oc9a, oc__, oc9c, oc9d, oc9e, oc9f

        ; Opcodes A0-AF
        .word oca0, oca1, oca2, oc__, oca4, oca5, oca6, oca7
        .word oca8, oca9, ocaa, oc__, ocac, ocad, ocae, ocaf

        ; Opcodes B0-BF
        .word ocb0, ocb1, ocb2, oc__, ocb4, ocb5, ocb6, ocb7
        .word ocb8, ocb9, ocba, oc__, ocbc, ocbd, ocbe, ocbf

        ; Opcodes C0-CF
        .word occ0, occ1, oc__, oc__, occ4, occ5, occ6, occ7
        .word occ8, occ9, occa, oc__, occc, occd, occe, occf

        ; Opcodes D0-DF
        .word ocd0, ocd1, ocd2, oc__, oc__, ocd5, ocd6, ocd7
        .word ocd8, ocd9, ocda, oc__, oc__, ocdd, ocde, ocdf

        ; Opcodes E0-EF
        .word oce0, oce1, oc__, oc__, oce4, oce5, oce6, oce7
        .word oce8, oce9, ocea, oc__, ocec, oced, ocee, ocef

        ; Opcodes F0-FF
        .word ocf0, ocf1, ocf2, oc__, oc__, ocf5, ocf6, ocf7
        .word ocf8, ocf9, ocfa, oc__, oc__, ocfd, ocfe, ocff


; =========================================================
oc_table:
        ; Opcode data table for the disassember, which is also used by the
        ; assembler. Each entry starts with a "lengths byte":

        ;       bit 7-6:  Length of instruction in bytes (1 to 3 for the 65c02)
        ;       bit 5-3:  unused
        ;       bit 2-0:  Length of mnemonic in chars (3 to 7)

        ; To convert a line in this table to a Forth string of the mnemonic,
        ; use the COUNT word on the address of the lengths byte to get
        ; ( addr u ) and then mask all but the bits 2-0 of the TOS.

        ; To make debugging easier, we keep the raw numbers for the lengths of
        ; the instruction and mnemonicis and let the assembler do the math
        ; required to shift and add. The actual mnemonic string follows after
        ; and is not zero terminated because we have the length in bits 2 to 0.

	oc00:	.byte 2*64+3, "brk"              ; enforce the signature byte
	oc01:	.byte 2*64+7, "ora.zxi"
;      (oc02)
;      (oc03)
        oc04:   .byte 2*64+5, "tsb.z"
	oc05:	.byte 2*64+5, "ord.z"
	oc06:	.byte 2*64+5, "asl.z"
;      (oc07)
	oc08:	.byte 1*64+3, "php"
	oc09:	.byte 2*64+5, "ora.#"
	oc0a:	.byte 1*64+5, "asl.a"
;      (oc0b)
	oc0c:	.byte 3*64+3, "tsb"
	oc0d:	.byte 3*64+3, "ora"
	oc0e:	.byte 3*64+3, "asl"
	oc0f:	.byte 3*64+4, "bbr0"

	oc10:	.byte 2*64+3, "bpl"
	oc11:	.byte 2*64+7, "ora.ziy"
	oc12:	.byte 2*64+6, "ora.zi"
;      (oc13:)
	oc14:	.byte 2*64+5, "trb.z"
	oc15:	.byte 2*64+6, "ora.zx"
	oc16:	.byte 2*64+6, "asl.zx"
	oc17:	.byte 2*64+6, "rmb1.z"
	oc18:	.byte 1*64+3, "clc"
	oc19:	.byte 3*64+5, "ora.y"
	oc1a:	.byte 1*64+5, "inc.a"
;      (oc1b:)
	oc1c:	.byte 3*64+3, "trb"
	oc1d:	.byte 3*64+5, "ora.x"
;      (oc1e:)
	oc1f:	.byte 3*64+5, "asl.x"

	oc20:	.byte 3*64+3, "jsr"
	oc21:	.byte 2*64+7, "and.zxi"
;      (oc22:)
;      (oc23:)
	oc24:	.byte 2*64+5, "bit.z"
	oc25:	.byte 2*64+5, "and.z"
	oc26:	.byte 2*64+5, "rol.z"
	oc27:	.byte 2*64+6, "rmb2.z"
	oc28:	.byte 1*64+3, "plp"
	oc29:	.byte 2*64+5, "and.#"
	oc2a:	.byte 1*64+5, "rol.a"
;      (oc2b:)
	oc2c:	.byte 3*64+3, "bit"
	oc2d:	.byte 3*64+4, "and."
	oc2e:	.byte 3*64+3, "rol"
	oc2f:	.byte 3*64+4, "bbr2"

	oc30:	.byte 2*64+3, "bmi"
	oc31:	.byte 2*64+7, "and.ziy"
	oc32:	.byte 2*64+6, "and.zi"
;      (oc33:)
	oc34:	.byte 2*64+7, "bit.zxi"
	oc35:	.byte 2*64+6, "and.zx"
	oc36:	.byte 2*64+6, "rol.zx"
	oc37:	.byte 2*64+6, "rmb3.z"
	oc38:	.byte 1*64+3, "sec"
	oc39:	.byte 3*64+5, "and.y"
	oc3a:	.byte 1*64+5, "dec.a"
;      (oc3b:)
	oc3c:	.byte 3*64+5, "bit.x"
	oc3d:	.byte 3*64+5, "and.x"
	oc3e:	.byte 3*64+5, "rol.x"
	oc3f:	.byte 3*64+4, "bbr3"

	oc40:	.byte 1*64+3, "rti"
	oc41:	.byte 2*64+7, "eor.zxi"
;      (oc42:)
;      (oc43:)
;      (oc44:)
	oc45:	.byte 2*64+5, "eor.z"
	oc46:	.byte 2*64+5, "lsr.z"
	oc47:	.byte 2*64+6, "rbm4.z"
	oc48:	.byte 1*64+3, "pha"
	oc49:	.byte 2*64+5, "eor.#"
	oc4a:	.byte 1*64+5, "lsr.a"
;      (oc4b:)
	oc4c:	.byte 3*64+3, "jmp"
	oc4d:	.byte 3*64+3, "eor"
	oc4e:	.byte 3*64+3, "lsr"
	oc4f:	.byte 3*64+4, "bbr4"

	oc50:	.byte 2*64+3, "bvc"
	oc51:	.byte 2*64+7, "eor.ziy"
	oc52:	.byte 2*64+6, "eor.zi"
;      (oc53:)
;      (oc54:)
	oc55:	.byte 2*64+6, "eor.zx"
	oc56:	.byte 2*64+6, "lsr.zx"
	oc57:	.byte 2*64+6, "rbm5.z"
	oc58:	.byte 1*64+3, "cli"
	oc59:	.byte 3*64+5, "eor.y"
	oc5a:	.byte 1*64+3, "phy"
;      (oc5b:)
;      (oc5c:)
	oc5d:	.byte 3*64+5, "eor.x"
	oc5e:	.byte 3*64+5, "lsr.x"
	oc5f:	.byte 3*64+4, "bbr5"

	oc60:	.byte 1*64+3, "rts"
	oc61:	.byte 2*64+7, "adc.zxi"
;      (oc62:)
;      (oc63:)
	oc64:	.byte 2*64+5, "stz.z"
	oc65:	.byte 2*64+5, "adc.z"
	oc66:	.byte 2*64+5, "ror.z"
	oc67:	.byte 2*64+6, "rmb6.z"
	oc68:	.byte 1*64+3, "pla"
	oc69:	.byte 2*64+5, "adc.#"
	oc6a:	.byte 1*64+5, "ror.a"
;      (oc6b:)
	oc6c:	.byte 3*64+5, "jmp.i"
	oc6d:	.byte 3*64+3, "adc"
	oc6e:	.byte 3*64+3, "ror"
	oc6f:	.byte 3*64+4, "bbr6"

	oc70:	.byte 2*64+3, "bvs"
	oc71:	.byte 2*64+7, "adc.ziy"
	oc72:	.byte 2*64+6, "adc.zi"
;      (oc73:)
	oc74:	.byte 2*64+6, "stz.zx"
	oc75:	.byte 2*64+6, "adc.zx"
	oc76:	.byte 2*64+6, "ror.zx"
	oc77:	.byte 2*64+6, "rmb7.z"
	oc78:	.byte 1*64+3, "sei"
	oc79:	.byte 3*64+5, "adc.y"
	oc7a:	.byte 1*64+3, "ply"
;      (oc7b:)
	oc7c:	.byte 3*64+6, "jmp.xi"
	oc7d:	.byte 3*64+5, "adc.x"
	oc7e:	.byte 3*64+5, "ror.x"
	oc7f:	.byte 3*64+4, "bbr7"

	oc80:	.byte 2*64+3, "bra"
	oc81:	.byte 2*64+7, "sta.zxi"
;      (oc82:)
;      (oc83:)
	oc84:	.byte 2*64+5, "sty.z"
	oc85:	.byte 2*64+5, "sta.z"
	oc86:	.byte 2*64+5, "stx.z"
;      (oc87:)
	oc88:	.byte 1*64+3, "dey"
	oc89:	.byte 2*64+5, "bit.#"
	oc8a:	.byte 1*64+3, "txa"
;      (oc8b:)
	oc8c:	.byte 3*64+3, "sty"
	oc8d:	.byte 3*64+3, "sta"
	oc8e:	.byte 3*64+3, "stx"
	oc8f:	.byte 3*64+4, "bbs0"

	oc90:	.byte 2*64+3, "bcc"
	oc91:	.byte 2*64+7, "sta.ziy"
	oc92:	.byte 2*64+6, "sta.zi"
;      (oc93:)
	oc94:	.byte 2*64+6, "sty.zx"
	oc95:	.byte 2*64+6, "sta.zx"
	oc96:	.byte 2*64+6, "stx.zy"
	oc97:	.byte 2*64+6, "smb1.z"
	oc98:	.byte 1*64+3, "tya"
	oc99:	.byte 3*64+5, "sta.y"
	oc9a:	.byte 1*64+3, "txs"
;      (oc9b:)
	oc9c:	.byte 3*64+3, "stz"
	oc9d:	.byte 3*64+5, "sta.x"
	oc9e:	.byte 3*64+5, "stz.x"
	oc9f:	.byte 3*64+4, "bbs1"

	oca0:	.byte 2*64+5, "ldy.#"
	oca1:	.byte 2*64+7, "lda.zxi"
	oca2:	.byte 2*64+5, "ldx.#"
;      (oca3:)
	oca4:	.byte 2*64+5, "ldy.z"
	oca5:	.byte 2*64+5, "lda.z"
	oca6:	.byte 2*64+5, "ldx.z"
	oca7:	.byte 2*64+6, "smb2.z"
	oca8:	.byte 1*64+3, "tay"
	oca9:	.byte 2*64+5, "lda.#"
	ocaa:	.byte 1*64+3, "tax"
;      (ocab:)
	ocac:	.byte 3*64+3, "ldy"
	ocad:	.byte 3*64+3, "lda"
	ocae:	.byte 3*64+3, "ldx"
	ocaf:	.byte 3*64+4, "bbs2"

	ocb0:	.byte 2*64+3, "bcs"
	ocb1:	.byte 2*64+7, "lda.ziy"
	ocb2:	.byte 2*64+6, "lda.zi"
;      (ocb3:)
	ocb4:	.byte 2*64+6, "ldy.zx"
	ocb5:	.byte 2*64+6, "lda.zx"
	ocb6:	.byte 2*64+6, "ldx.zy"
	ocb7:	.byte 2*64+6, "smb3.z"
	ocb8:	.byte 1*64+3, "clv"
	ocb9:	.byte 3*64+5, "lda.y"
	ocba:	.byte 1*64+3, "tsx"
;      (ocbb:)
	ocbc:	.byte 3*64+5, "ldy.x"
	ocbd:	.byte 3*64+5, "lda.x"
	ocbe:	.byte 3*64+5, "ldx.y"
	ocbf:	.byte 3*64+4, "bbs4"

	occ0:	.byte 2*64+5, "cpy.#"
	occ1:	.byte 2*64+7, "cmp.zxi"
;      (occ2:)
;      (occ3:)
	occ4:	.byte 2*64+5, "cpy.z"
	occ5:	.byte 2*64+5, "cmp.z"
	occ6:	.byte 2*64+5, "dec.z"
	occ7:	.byte 2*64+6, "smb4.z"
	occ8:	.byte 1*64+3, "iny"
	occ9:	.byte 2*64+5, "cmp.#"
	occa:	.byte 1*64+3, "dex"
;      (occb:)
	occc:	.byte 3*64+3, "cpy"
	occd:	.byte 3*64+3, "cmp"
	occe:	.byte 3*64+3, "dec"
	occf:	.byte 3*64+4, "bbs4"

	ocd0:	.byte 2*64+3, "bne"
	ocd1:	.byte 2*64+7, "cmp.ziy"
	ocd2:	.byte 2*64+6, "cmp.zi"
;      (ocd3:)
;      (ocd4:)
	ocd5:	.byte 2*64+6, "cmp.zx"
	ocd6:	.byte 2*64+6, "dec.zx"
	ocd7:	.byte 2*64+6, "smb5.z"
	ocd8:	.byte 1*64+3, "cld"
	ocd9:	.byte 3*64+5, "cmp.y"
	ocda:	.byte 1*64+3, "phx"
;      (ocdb:)
;      (ocdc:)
	ocdd:	.byte 3*64+5, "cmp.x"
	ocde:	.byte 3*64+5, "dec.x"
	ocdf:	.byte 3*64+4, "bbs5"

	oce0:	.byte 2*64+5, "cpx.#"
	oce1:	.byte 2*64+7, "sbc.zxi"
;      (oce2:)
;      (oce3:)
	oce4:	.byte 2*64+5, "cpx.z"
	oce5:	.byte 2*64+5, "sbc.z"
	oce6:	.byte 2*64+5, "inc.z"
	oce7:	.byte 2*64+6, "smb6.z"
	oce8:	.byte 1*64+3, "inx"
	oce9:	.byte 2*64+5, "sbc.#"
	ocea:	.byte 1*64+3, "nop"
;      (oceb:)
	ocec:	.byte 3*64+3, "cpx"
	oced:	.byte 3*64+3, "sbc"
	ocee:	.byte 3*64+3, "inc"
	ocef:	.byte 3*64+4, "bbs6"

	ocf0:	.byte 2*64+3, "beq"
	ocf1:	.byte 2*64+7, "sbc.ziy"
	ocf2:	.byte 2*64+6, "sbc.zi"
;      (ocf3:)
;      (ocf4:)
	ocf5:	.byte 2*64+6, "sbc.zx"
	ocf6:	.byte 2*64+6, "inc.zx"
	ocf7:	.byte 2*64+6, "smb7.z"
	ocf8:	.byte 1*64+3, "sed"
	ocf9:	.byte 3*64+5, "sbc.y"
	ocfa:	.byte 1*64+3, "plx"
;      (ocfb:)
;      (ocfc:)
	ocfd:	.byte 3*64+5, "sbc.x"
	ocfe:	.byte 3*64+5, "inc.x"
	ocff:	.byte 3*64+4, "bbs7"

        ; Common routine for opcodes that are not supported by the 65c02
	oc__:	.byte 1, "?"

; used to calculate size of assembled disassembler code
disassembler_end:
