; Disassembler for Tali Forth 2 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 28. Apr 2018
; This version: 17. Dec 2018

; This is the default disassembler for Tali Forth 2. Use by passing
; the address and length of the block of memory to be disassembled:
;
;       disasm ( addr x -- ) 

; The underflow checking is handled by the word's stub in
; native_words.asm, see there for more information.

; The code is disassembled in Simpler Assembler Notation (SAN),
; because that is, uh, simpler. See the documentation for more information.
; Because disassemblers are used interactively with slow humans, we don't
; care that much about speed and put the emphasis at being small.
.scope
disassembler:
_byte_loop:
                ; Print address at start of the line
                jsr xt_cr
                jsr xt_over     ; ( addr u addr ) 
                jsr xt_u_dot
                jsr xt_space

                ; We use the opcode value as the offset in the  oc_index_table.
                ; We have 256 entries, each two bytes large, so we can't just
                ; use an index with y. We use tmp2 for this.
                lda #<oc_index_table
                sta tmp2
                lda #>oc_index_table
                sta tmp2+1

                lda (2,x)
                asl             ; multiply by two for offset
                bcc +
                inc tmp2+1      ; we're on second page, add 
*
                tay

                ; Get address of the entry in the opcode table. We put the
                ; address in tmp3 because that is where print_common expects
                ; it to be
                lda (tmp2),y 
                sta tmp3
                iny
                lda (tmp2),y
                sta tmp3+1

                ; The first byte is the length of the operand, so either
                ; 0, 1, or 2 bytes
                lda (tmp3)
                pha             ; save that for the future

                ; Move to next byte in the opcode table, which is where
                ; the zero-terminated string starts
                inc tmp3
                bne +
                inc tmp3+1
*               
                ; Print the mnemonic
                jsr print_common_no_lf

                ; Houskeeping: Move on to the next byte in memory
                inc 2,x
                bne +
                inc 3,x
*
                jsr xt_one_minus        ; adjust counter

                ; If we're lucky, this is a single-byte instruction and
                ; we are done
                ply
                beq _instruction_done

                ; No such luck, this is an instruction with an operand
                dey
                phy             ; save length again

                jsr xt_space
                jsr xt_dup      ; make room TOS to store byte for printing

                lda (4,x)       ; ( addr u u )
                sta 0,x         ; LSB
                stz 1,x         ; MSB is zero for now

                ; Houskeeping: Go to next byte in memory
                inc 4,x
                bne +
                inc 5,x
*
                ; Decrease counter. We can't just use 1- because we have
                ; the operand to be printed as TOS, not the counter
                lda 2,x
                bne +
                dec 3,x
*
                dec 2,x

                ; If this is a two-byte operand, we need a different
                ; printing format
                pla
                bne _two_byte_operand

                ; Pictured output of one byte number
                jsr xt_zero                     ; 0
                jsr xt_less_number_sign         ; <#
                jsr xt_number_sign              ; #
                jsr xt_number_sign_s            ; #S
                jsr xt_number_sign_greater      ; #>
                jsr xt_type
               
                bra _instruction_done

_two_byte_operand:
                ; Fine. We'll do this the hard way. We still have the
                ; operand to be printed TOS
                lda (4,x)
                sta 1,x         ; keep LSB
 
                ; Pictured output of a two-byte number
                jsr xt_zero
                jsr xt_less_number_sign         ; <#
                jsr xt_number_sign              ; #
                jsr xt_number_sign              ; #
                jsr xt_number_sign              ; #
                jsr xt_number_sign_s            ; #S
                jsr xt_number_sign_greater      ; #>
                jsr xt_type

                ; Housekeeping: Next byte
                inc 2,x
                bne +
                inc 3,x
*
                jsr xt_one_minus

_instruction_done: 
                lda 0,x                 ; All done?
                ora 1,x
                beq _done
                bmi _done               ; catch mid-instruction byte ranges

                jmp _byte_loop          ; out of range for BRA
_done:
                ; Clean up and leave
                jsr xt_cr
                jmp xt_two_drop         ; JSR/RTS

oc_index_table:

        ; Opcodes 00-0F
        .word oc00, oc01, oc__, oc__, oc__, oc05, oc06, oc__
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
        .word oc60, oc61, oc__, oc__, oc66, oc65, oc66, oc67
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
        
        ; Opcodes a0-aF
        .word oca0, oca1, oca2, oc__, oca4, oca5, oca6, oca7
        .word oca8, oca9, ocaa, oc__, ocac, ocad, ocae, ocaf 

        ; Opcodes b0-bF
        .word ocb0, ocb1, ocb2, oc__, ocb4, ocb5, ocb6, ocb7
        .word ocb8, ocb9, ocba, oc__, ocbc, ocbd, ocbe, ocbf 

        ; Opcodes c0-cF
        .word occ0, occ1, oc__, oc__, occ4, occ5, occ6, occ7
        .word occ8, occ9, occa, oc__, occc, occd, occe, occf 

        ; Opcodes d0-dF
        .word ocd0, ocd1, ocd2, oc__, oc__, ocd5, ocd6, ocd7
        .word ocd8, ocd9, ocda, oc__, oc__, ocdd, ocde, ocdf 
        
        ; Opcodes e0-eF
        .word oce0, oce1, oc__, oc__, oce4, oce5, oce6, oce7
        .word oce8, oce9, ocea, oc__, ocec, oced, ocee, ocef 

        ; Opcodes f0-fF
        .word ocf0, ocf1, ocf2, oc__, oc__, ocf5, ocf6, ocf7
        .word ocf8, ocf9, ocfa, oc__, oc__, ocfd, ocfe, ocff

        
oc_table:
        ; Opcode data table for the disassember, which can also be used by the
        ; assembler. Each entry Starts with a "length byte":
      
        ;       bit 0-1:  Length of instruction in byte (1 to 3 for the 65c02)
        ;       bit 2-4:  Length of the SAN mnemonic in chars (3 to 7)
        ;       bit 5-7:  unused

        ; We keep the length of the instuction in the lower bytes to speed up
        ; the assembly [sic] process by only having to mask all but bits 0-1.
       
        ; To convert the data to a Forth string, mask all but the bits 2-4,
        ; shift that byte right twice, and then use the COUNT word to convert
        ; it to the normal ( addr u ) string format. 
        
        ; To make debugging easier, we list the length of the mnemonic string
        ; and shift it left twice (multiplication by four) during the assembly
        ; process and then add the length of the instruction. The actual
        ; mnemonic string follows after and is not zero terminated.
 
	oc00:	.byte 3*4+2, "brk"              ; enforce the signature byte
	oc01:	.byte 7*4+2, "ora.zxi"
;      (oc02)
;      (oc03)
;      (oc04)
	oc05:	.byte 5*4+2, "ord.z"
	oc06:	.byte 5*4+2, "asl.z"
;      (oc07)
	oc08:	.byte 3*4+1, "php"
	oc09:	.byte 5*4+2, "ora.#"
	oc0a:	.byte 5*4+1, "asl.a"
;      (oc0b)
	oc0c:	.byte 3*4+3, "tsb"
	oc0d:	.byte 3*4+3, "ora"
	oc0e:	.byte 3*4+3, "asl"
	oc0f:	.byte 4*4+3, "bbr0"

	oc10:	.byte 3*4+2, "bpl"
	oc11:	.byte 7*4+2, "ora.ziy"
	oc12:	.byte 6*4+2, "ora.zi"
;      (oc13:)
	oc14:	.byte 5*4+2, "trb.z"
	oc15:	.byte 6*4+2, "ora.zx"
	oc16:	.byte 6*4+2, "asl.zx"
	oc17:	.byte 6*4+2, "rmb1.z"
	oc18:	.byte 3*4+1, "clc"
	oc19:	.byte 5*4+3, "ora.y"
	oc1a:	.byte 5*4+1, "inc.a"
;      (oc1b:)
	oc1c:	.byte 3*4+3, "trb"
	oc1d:	.byte 5*4+3, "ora.x"
;      (oc1e:)
	oc1f:	.byte 5*4+3, "asl.x"

	oc20:	.byte 3*4+3, "jsr"
	oc21:	.byte 7*4+2, "and.zxi"
;      (oc22:)
;      (oc23:)
	oc24:	.byte 5*4+2, "bit.z"
	oc25:	.byte 5*4+2, "and.z"
	oc26:	.byte 5*4+2, "rol.z"
	oc27:	.byte 6*4+2, "rmb2.z"
	oc28:	.byte 3*4+1, "plp"
	oc29:	.byte 5*4+2, "and.#"
	oc2a:	.byte 5*4+1, "rol.a"
;      (oc2b:)
	oc2c:	.byte 3*4+3, "bit"
	oc2d:	.byte 4*4+3, "and."
	oc2e:	.byte 3*4+3, "rol"
	oc2f:	.byte 4*4+3, "bbr2"

	oc30:	.byte 3*4+2, "bmi"
	oc31:	.byte 7*4+2, "and.ziy"
	oc32:	.byte 6*4+2, "and.zi"
;      (oc33:)
	oc34:	.byte 7*4+2, "bit.zxi"
	oc35:	.byte 6*4+2, "and.zx"
	oc36:	.byte 6*4+2, "rol.zx"
	oc37:	.byte 6*4+2, "rmb3.z"
	oc38:	.byte 3*4+1, "sec"
	oc39:	.byte 5*4+3, "and.y"
	oc3a:	.byte 5*4+1, "dec.a"
;      (oc3b:)
	oc3c:	.byte 5*4+3, "bit.x"
	oc3d:	.byte 5*4+3, "and.x"
	oc3e:	.byte 5*4+3, "rol.x"
	oc3f:	.byte 4*4+3, "bbr3"

	oc40:	.byte 3*4+1, "rti"
	oc41:	.byte 7*4+2, "eor.zxi"
;      (oc42:)
;      (oc43:)
;      (oc44:)
	oc45:	.byte 5*4+2, "eor.z"
	oc46:	.byte 5*4+2, "lsr.z"
	oc47:	.byte 6*4+2, "rbm4.z"
	oc48:	.byte 3*4+1, "pha"
	oc49:	.byte 5*4+2, "eor.#"
	oc4a:	.byte 5*4+1, "lsr.a"
;      (oc4b:)
	oc4c:	.byte 3*4+3, "jmp"
	oc4d:	.byte 3*4+3, "eor"
	oc4e:	.byte 3*4+3, "lsr"
	oc4f:	.byte 4*4+3, "bbr4"

	oc50:	.byte 3*4+2, "bvc"
	oc51:	.byte 7*4+2, "eor.ziy"
	oc52:	.byte 6*4+2, "eor.zi"
;      (oc53:)
;      (oc54:)
	oc55:	.byte 6*4+2, "eor.zx"
	oc56:	.byte 6*4+2, "lsr.zx"
	oc57:	.byte 6*4+2, "rbm5.z"
	oc58:	.byte 3*4+1, "cli"
	oc59:	.byte 5*4+3, "eor.y"
	oc5a:	.byte 3*4+1, "phy"
;      (oc5b:)
;      (oc5c:)
	oc5d:	.byte 5*4+3, "eor.x"
	oc5e:	.byte 5*4+3, "lsr.x"
	oc5f:	.byte 4*4+3, "bbr5"

	oc60:	.byte 3*4+1, "rts"
	oc61:	.byte 7*4+2, "adc.zxi"
;      (oc62:)
;      (oc63:)
	oc64:	.byte 5*4+2, "stz.z"
	oc65:	.byte 5*4+2, "adc.z"
	oc66:	.byte 5*4+2, "ror.z"
	oc67:	.byte 6*4+2, "rmb6.z"
	oc68:	.byte 3*4+1, "pla"
	oc69:	.byte 5*4+2, "adc.#"
	oc6a:	.byte 5*4+1, "ror.a"
;      (oc6b:)
	oc6c:	.byte 5*4+3, "jmp.i"
	oc6d:	.byte 3*4+3, "adc"
	oc6e:	.byte 3*4+3, "ror"
	oc6f:	.byte 4*4+3, "bbr6"

	oc70:	.byte 3*4+2, "bvs"
	oc71:	.byte 7*4+2, "adc.ziy"
	oc72:	.byte 6*4+2, "adc.zi"
;      (oc73:)
	oc74:	.byte 6*4+2, "stz.zx"
	oc75:	.byte 6*4+2, "adc.zx"
	oc76:	.byte 6*4+2, "ror.zx"
	oc77:	.byte 6*4+2, "rmb7.z"
	oc78:	.byte 3*4+1, "sei"
	oc79:	.byte 5*4+3, "adc.y"
	oc7a:	.byte 3*4+1, "ply"
;      (oc7b:)
	oc7c:	.byte 6*4+3, "jmp.xi"
	oc7d:	.byte 5*4+3, "adc.x"
	oc7e:	.byte 5*4+3, "ror.x"
	oc7f:	.byte 4*4+3, "bbr7"

	oc80:	.byte 3*4+2, "bra"
	oc81:	.byte 7*4+2, "sta.zxi"
;      (oc82:)
;      (oc83:)
	oc84:	.byte 5*4+2, "sty.z"
	oc85:	.byte 5*4+2, "sta.z"
	oc86:	.byte 5*4+2, "stx.z"
;      (oc87:)
	oc88:	.byte 3*4+1, "dey"
	oc89:	.byte 5*4+2, "bit.#"
	oc8a:	.byte 3*4+1, "txa"
;      (oc8b:)
	oc8c:	.byte 3*4+3, "sty"
	oc8d:	.byte 3*4+3, "sta"
	oc8e:	.byte 3*4+3, "stx"
	oc8f:	.byte 4*4+3, "bbs0"

	oc90:	.byte 3*4+2, "bcc"
	oc91:	.byte 7*4+2, "sta.ziy"
	oc92:	.byte 6*4+2, "sta.zi"
;      (oc93:)
	oc94:	.byte 6*4+2, "sty.zx"
	oc95:	.byte 6*4+2, "sta.zx"
	oc96:	.byte 6*4+2, "stx.zy"
	oc97:	.byte 6*4+2, "smb1.z"
	oc98:	.byte 3*4+1, "tya"
	oc99:	.byte 5*4+3, "sta.y"
	oc9a:	.byte 3*4+1, "txs"
;      (oc9b:)
	oc9c:	.byte 3*4+3, "stz"
	oc9d:	.byte 5*4+3, "sta.x"
	oc9e:	.byte 5*4+3, "stz.x"
	oc9f:	.byte 4*4+3, "bbs1"

	oca0:	.byte 5*4+2, "ldy.#"
	oca1:	.byte 7*4+2, "lda.zxi"
	oca2:	.byte 5*4+2, "ldx.#"
;      (oca3:)
	oca4:	.byte 5*4+2, "ldy.z"
	oca5:	.byte 5*4+2, "lda.z"
	oca6:	.byte 5*4+2, "ldx.z"
	oca7:	.byte 6*4+2, "smb2.z"
	oca8:	.byte 3*4+1, "tay"
	oca9:	.byte 5*4+2, "lda.#"
	ocaa:	.byte 3*4+1, "tax"
;      (ocab:)
	ocac:	.byte 3*4+3, "ldy"
	ocad:	.byte 3*4+3, "lda"
	ocae:	.byte 3*4+3, "ldx"
	ocaf:	.byte 4*4+3, "bbs2"

	ocb0:	.byte 3*4+2, "bcs"
	ocb1:	.byte 7*4+2, "lda.ziy"
	ocb2:	.byte 6*4+2, "lda.zi"
;      (ocb3:)
	ocb4:	.byte 6*4+2, "ldy.zx"
	ocb5:	.byte 6*4+2, "lda.zx"
	ocb6:	.byte 6*4+2, "ldx.zy"
	ocb7:	.byte 6*4+2, "smb3.z"
	ocb8:	.byte 3*4+1, "clv"
	ocb9:	.byte 5*4+3, "lda.y"
	ocba:	.byte 3*4+1, "tsx"
;      (ocbb:)
	ocbc:	.byte 5*4+3, "ldy.x"
	ocbd:	.byte 5*4+3, "lda.x"
	ocbe:	.byte 5*4+3, "ldx.y"
	ocbf:	.byte 4*4+3, "bbs4"

	occ0:	.byte 5*4+2, "cpy.#"
	occ1:	.byte 7*4+2, "cmp.zxi"
;      (occ2:)
;      (occ3:)
	occ4:	.byte 5*4+2, "cpy.z"
	occ5:	.byte 5*4+2, "cmp.z"
	occ6:	.byte 5*4+2, "dec.z"
	occ7:	.byte 6*4+2, "smb4.z"
	occ8:	.byte 3*4+1, "iny"
	occ9:	.byte 5*4+2, "cmp.#"
	occa:	.byte 3*4+1, "dex"
;      (occb:)
	occc:	.byte 3*4+3, "cpy"
	occd:	.byte 3*4+3, "cmp"
	occe:	.byte 3*4+3, "dec"
	occf:	.byte 4*4+3, "bbs4"

	ocd0:	.byte 3*4+2, "bne"
	ocd1:	.byte 7*4+2, "cmp.ziy"
	ocd2:	.byte 6*4+2, "cmp.zi"
;      (ocd3:)
;      (ocd4:)
	ocd5:	.byte 6*4+2, "cmp.zx"
	ocd6:	.byte 6*4+2, "dec.zx"
	ocd7:	.byte 6*4+2, "smb5.z"
	ocd8:	.byte 3*4+1, "cld"
	ocd9:	.byte 5*4+3, "cmp.y"
	ocda:	.byte 3*4+1, "phx"
;      (ocdb:)
;      (ocdc:)
	ocdd:	.byte 5*4+3, "cmp.x"
	ocde:	.byte 5*4+3, "dec.x"
	ocdf:	.byte 4*4+3, "bbs5"

	oce0:	.byte 5*4+2, "cpx.#"
	oce1:	.byte 7*4+2, "sbc.zxi"
;      (oce2:)
;      (oce3:)
	oce4:	.byte 5*4+2, "cpx.z"
	oce5:	.byte 5*4+2, "sbc.z"
	oce6:	.byte 5*4+2, "inc.z"
	oce7:	.byte 6*4+2, "smb6.z"
	oce8:	.byte 3*4+1, "inx"
	oce9:	.byte 5*4+2, "sbc.#"
	ocea:	.byte 3*4+1, "nop"
;      (oceb:)
	ocec:	.byte 3*4+3, "cpx"
	oced:	.byte 3*4+3, "sbc"
	ocee:	.byte 3*4+3, "inc"
	ocef:	.byte 4*4+3, "bbs6"

	ocf0:	.byte 3*4+2, "beq"
	ocf1:	.byte 7*4+2, "sbc.ziy"
	ocf2:	.byte 6*4+2, "sbc.zi"
;      (ocf3:)
;      (ocf4:)
	ocf5:	.byte 6*4+2, "sbc.zx"
	ocf6:	.byte 6*4+2, "inc.zx"
	ocf7:	.byte 6*4+2, "smb7.z"
	ocf8:	.byte 3*4+1, "sed"
	ocf9:	.byte 5*4+3, "sbc.y"
	ocfa:	.byte 3*4+1, "plx"
;      (ocfb:)
;      (ocfc:)
	ocfd:	.byte 5*4+3, "sbc.x"
	ocfe:	.byte 5*4+3, "inc.x"
	ocff:	.byte 4*4+3, "bbs7"

        ; Common routine for opcodes that are not supported by the 65c02
	oc__:	.byte 1*4+0, "?"

.scend

; used to figure out size of assembled disassembler code
disassembler_end:
