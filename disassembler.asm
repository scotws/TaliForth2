; Disassembler for Tali Forth 2 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 28. Apr 2018
; This version: 16. May 2018

; This is the default disassembler for Tali Forth 2. To install your own,
; replace it with code that has a label "disassembler" below and takes
; the address and length of the block of memory to be disassembled as
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
                ; We arrive here with ( addr u ) on the stack. 
                ; The output is in hex. Since we don't know what base
                ; the user was using before, we save it
                lda base
                pha
                jsr xt_hex
_byte_loop:
                ; Print address at start of the line
                jsr xt_cr
                jsr xt_over     ; ( addr u addr ) 
                jsr xt_u_dot
                jsr xt_space

                ; We use the opcode value as the offset in the  oc_jump_table.
                ; We have 256 entries, each two bytes large, so we can't just
                ; use an index with y. We use tmp2 for this.
                lda #<oc_jump_table
                sta tmp2
                lda #>oc_jump_table
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
                pla
                sta base
                jsr xt_cr
                jmp xt_two_drop         ; JSR/RTS

; The opcode table constists of the length of the operand in bytes,
; the string of the mnemonic, and a 0 that terminates the string. Where the
; 65c02 has no instructions, the string "?" is used
oc_jump_table:
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
        .word occ8, occ9, occa, occb, occc, occd, occe, occf 

        ; Opcodes d0-dF
        .word ocd0, ocd1, ocd2, oc__, oc__, ocd5, ocd6, ocd7
        .word ocd8, ocd9, ocda, ocdb, oc__, ocdd, ocde, ocdf 
        
        ; Opcodes e0-eF
        .word oce0, oce1, oc__, oc__, oce4, oce5, oce6, oce7
        .word oce8, oce9, ocea, oc__, ocec, oced, ocee, ocef 

        ; Opcodes f0-fF
        .word ocf0, ocf1, ocf2, oc__, oc__, ocf5, ocf6, ocf7
        .word ocf8, ocf9, ocfa, oc__, oc__, ocfd, ocfe, ocff

oc__:           
        .byte 0, "?", 0
        
oc_table:
        oc00:   .byte 0, "brk", 0
        oc01:   .byte 1, "ora.dxi", 0
;      (oc02)
;      (oc03)
;      (oc04)
        oc05:   .byte 1, "ord.d", 0
        oc06:   .byte 1, "asl.d", 0
;      (oc07)
        oc08:   .byte 0, "php", 0
        oc09:   .byte 1, "ora.#", 0
        oc0a:   .byte 0, "asl.a", 0
;      (oc0b)
        oc0c:   .byte 2, "tsb", 0
        oc0d:   .byte 2, "ora", 0
        oc0e:   .byte 2, "asl", 0
        oc0f:   .byte 2, "bbr0", 0

        oc10:   .byte 1, "bpl", 0
        oc11:   .byte 1, "ora.ziy", 0
        oc12:   .byte 1, "ora.zi", 0
;      (oc13:)
        oc14:   .byte 1, "trb.z", 0
        oc15:   .byte 1, "ora.zx", 0
        oc16:   .byte 1, "asl.zx", 0
        oc17:   .byte 1, "rmb1.z", 0
        oc18:   .byte 0, "clc", 0
        oc19:   .byte 2, "ora.y", 0
        oc1a:   .byte 0, "inc.a", 0
;      (oc1b:)
        oc1c:   .byte 2, "trb", 0
        oc1d:   .byte 2, "ora.x", 0
;      (oc1e:)
        oc1f:   .byte 2, "asl.x", 0

        oc20:   .byte 2, "jsr", 0
        oc21:   .byte 1, "and.zxi", 0
;      (oc22:)
;      (oc23:)
        oc24:   .byte 1, "bit.z", 0
        oc25:   .byte 1, "and.z", 0
        oc26:   .byte 1, "rol.z", 0
        oc27:   .byte 1, "rmb2.z", 0
        oc28:   .byte 0, "plp", 0
        oc29:   .byte 1, "and.#", 0
        oc2a:   .byte 0, "rol.a", 0
;      (oc2b:)
        oc2c:   .byte 2, "bit", 0
        oc2d:   .byte 2, "and.", 0
        oc2e:   .byte 2, "rol", 0
        oc2f:   .byte 2, "bbr2", 0

        oc30:   .byte 1, "bmi", 0
        oc31:   .byte 1, "and.ziy", 0
        oc32:   .byte 1, "and.zi", 0
;      (oc33:)
        oc34:   .byte 1, "bit.zxi", 0
        oc35:   .byte 1, "and.zx", 0
        oc36:   .byte 1, "rol.zx", 0
        oc37:   .byte 1, "rmb3.z", 0
        oc38:   .byte 0, "sec", 0
        oc39:   .byte 2, "and.y", 0
        oc3a:   .byte 0, "dec.a", 0
;      (oc3b:)
        oc3c:   .byte 2, "bit.x", 0
        oc3d:   .byte 2, "and.x", 0
        oc3e:   .byte 2, "rol.x", 0
        oc3f:   .byte 2, "bbr3", 0

        oc40:   .byte 0, "rti", 0
        oc41:   .byte 1, "eor.zxi", 0
;      (oc42:)
;      (oc43:)
;      (oc44:)
        oc45:   .byte 1, "eor.z", 0
        oc46:   .byte 1, "lsr.z", 0
        oc47:   .byte 1, "rbm4.z", 0
        oc48:   .byte 0, "pha", 0
        oc49:   .byte 1, "eor.#", 0
        oc4a:   .byte 0, "lsr.a", 0
;      (oc4b:)
        oc4c:   .byte 2, "jmp", 0
        oc4d:   .byte 2, "eor", 0
        oc4e:   .byte 2, "lsr", 0
        oc4f:   .byte 2, "bbr4", 0

        oc50:   .byte 1, "bvc", 0
        oc51:   .byte 1, "eor.ziy", 0
        oc52:   .byte 1, "eor.zi", 0
;      (oc53:)
;      (oc54:)
        oc55:   .byte 1, "eor.zx", 0
        oc56:   .byte 1, "lsr.zx", 0
        oc57:   .byte 1, "rbm5.z", 0
        oc58:   .byte 0, "cli", 0
        oc59:   .byte 2, "eor.y", 0
        oc5a:   .byte 0, "phy", 0
;      (oc5b:)
;      (oc5c:)
        oc5d:   .byte 2, "eor.x", 0
        oc5e:   .byte 2, "lsr.x", 0
        oc5f:   .byte 2, "bbr5", 0

        oc60:   .byte 0, "rts", 0
        oc61:   .byte 1, "adc.zxi", 0
;      (oc62:)
;      (oc63:)
        oc64:   .byte 1, "stz.z", 0
        oc65:   .byte 1, "adc.z", 0
        oc66:   .byte 1, "ror.z", 0
        oc67:   .byte 1, "rmb6.z", 0
        oc68:   .byte 0, "pla", 0
        oc69:   .byte 1, "adc.#", 0
        oc6a:   .byte 0, "ror.a", 0
;      (oc6b:)
        oc6c:   .byte 2, "jmp.i", 0
        oc6d:   .byte 2, "adc", 0
        oc6e:   .byte 2, "ror", 0
        oc6f:   .byte 2, "bbr6", 0

        oc70:   .byte 1, "bvs", 0
        oc71:   .byte 1, "adc.ziy", 0
        oc72:   .byte 1, "adc.zi", 0
;      (oc73:)
        oc74:   .byte 1, "stz.zx", 0
        oc75:   .byte 1, "adc.zx", 0
        oc76:   .byte 1, "ror.zx", 0
        oc77:   .byte 1, "rmb7.z", 0
        oc78:   .byte 0, "sei", 0
        oc79:   .byte 2, "adc.y", 0
        oc7a:   .byte 0, "ply", 0
;      (oc7b:)
        oc7c:   .byte 2, "jmp.xi", 0
        oc7d:   .byte 2, "adc.x", 0
        oc7e:   .byte 2, "ror.x", 0
        oc7f:   .byte 2, "bbr7", 0

        oc80:   .byte 1, "bra", 0
        oc81:   .byte 1, "sta.zxi", 0
;      (oc82:)
;      (oc83:)
        oc84:   .byte 1, "sty.z", 0
        oc85:   .byte 1, "sta.z", 0
        oc86:   .byte 1, "stx.z", 0
;      (oc87:)
        oc88:   .byte 0, "dey", 0
        oc89:   .byte 1, "bit.#", 0
        oc8a:   .byte 0, "txa", 0
;      (oc8b:)
        oc8c:   .byte 2, "sty", 0
        oc8d:   .byte 2, "sta", 0
        oc8e:   .byte 2, "stx", 0
        oc8f:   .byte 2, "bbs0", 0

        oc90:   .byte 1, "bcc", 0
        oc91:   .byte 1, "sta.ziy", 0
        oc92:   .byte 1, "sta.zi", 0
;      (oc93:)
        oc94:   .byte 1, "sty.zx", 0
        oc95:   .byte 1, "sty.zx", 0
        oc96:   .byte 1, "stx.zy", 0
        oc97:   .byte 1, "smb1.z", 0
        oc98:   .byte 0, "tya", 0
        oc99:   .byte 2, "sta.y", 0
        oc9a:   .byte 0, "txs", 0
;      (oc9b:)
        oc9c:   .byte 2, "stz", 0
        oc9d:   .byte 2, "sta.x", 0
        oc9e:   .byte 2, "stz.x", 0
        oc9f:   .byte 2, "bbs1", 0

        oca0:   .byte 1, "ldy.#", 0
        oca1:   .byte 1, "lda.zxi", 0
        oca2:   .byte 1, "ldx.#", 0
;      (oca3:)
        oca4:   .byte 1, "ldy.z", 0
        oca5:   .byte 1, "lda.z", 0
        oca6:   .byte 1, "ldx.z", 0
        oca7:   .byte 1, "smb2.z", 0
        oca8:   .byte 0, "tay", 0
        oca9:   .byte 1, "lda.#", 0
        ocaa:   .byte 0, "tax", 0
;      (ocab:)
        ocac:   .byte 2, "ldy", 0
        ocad:   .byte 2, "lda", 0
        ocae:   .byte 2, "ldx", 0
        ocaf:   .byte 2, "bbs2", 0

        ocb0:   .byte 1, "bcs", 0
        ocb1:   .byte 1, "lda.ziy", 0
        ocb2:   .byte 1, "lda.zi", 0
;      (ocb3:)
        ocb4:   .byte 1, "ldy.zx", 0
        ocb5:   .byte 1, "lda.zx", 0
        ocb6:   .byte 1, "ldx.zy", 0
        ocb7:   .byte 1, "smb3.z", 0
        ocb8:   .byte 0, "clv", 0
        ocb9:   .byte 2, "lda.y", 0
        ocba:   .byte 0, "tsx", 0
;      (ocbb:)
        ocbc:   .byte 2, "ldy.x", 0
        ocbd:   .byte 2, "lda.x", 0
        ocbe:   .byte 2, "ldx.y", 0
        ocbf:   .byte 2, "bbs4", 0

        occ0:   .byte 1, "cpy.#", 0
        occ1:   .byte 1, "cmp.zxi", 0
;      (occ2:)
;      (occ3:)
        occ4:   .byte 1, "cpy.z", 0
        occ5:   .byte 1, "cmp.z", 0
        occ6:   .byte 1, "dec.z", 0
        occ7:   .byte 1, "smb4.z", 0
        occ8:   .byte 0, "iny", 0
        occ9:   .byte 1, "cmp.#", 0
        occa:   .byte 0, "dex", 0
        occb:   .byte 0, "stp", 0
        occc:   .byte 2, "cpy", 0
        occd:   .byte 2, "cmp", 0
        occe:   .byte 2, "dec", 0
        occf:   .byte 2, "bbs4", 0

        ocd0:   .byte 1, "bne", 0
        ocd1:   .byte 1, "cmp.ziy", 0
        ocd2:   .byte 1, "cmp.zi", 0
;      (ocd3:)
;      (ocd4:)
        ocd5:   .byte 1, "cmp.zx", 0
        ocd6:   .byte 1, "dec.zx", 0
        ocd7:   .byte 1, "smb5.z", 0
        ocd8:   .byte 0, "cld", 0
        ocd9:   .byte 2, "cmp.y", 0
        ocda:   .byte 0, "phx", 0
        ocdb:   .byte 0, "wai", 0
;      (ocdc:)
        ocdd:   .byte 2, "cmp.x", 0
        ocde:   .byte 2, "dec.x", 0
        ocdf:   .byte 2, "bbs5", 0

        oce0:   .byte 1, "cpx.#", 0
        oce1:   .byte 1, "sbc.zxi", 0
;      (oce2:)
;      (oce3:)
        oce4:   .byte 1, "cpx.z", 0
        oce5:   .byte 1, "sbc.z", 0
        oce6:   .byte 1, "inc.z", 0
        oce7:   .byte 1, "smb6.z", 0
        oce8:   .byte 0, "inx", 0
        oce9:   .byte 1, "sbc.#", 0
        ocea:   .byte 0, "nop", 0
;      (oceb:)
        ocec:   .byte 2, "cpx", 0
        oced:   .byte 2, "sbc", 0
        ocee:   .byte 2, "inc", 0
        ocef:   .byte 2, "bbs6", 0

        ocf0:   .byte 1, "beq", 0
        ocf1:   .byte 1, "sbc.ziy", 0
        ocf2:   .byte 1, "sbc.zi", 0
;      (ocf3:)
;      (ocf4:)
        ocf5:   .byte 1, "sbc.zx", 0
        ocf6:   .byte 1, "inc.zx", 0
        ocf7:   .byte 1, "smb7.z", 0
        ocf8:   .byte 0, "sed", 0
        ocf9:   .byte 2, "sbc.y", 0
        ocfa:   .byte 0, "plx", 0
;      (ocfb:)
;      (ocfc:)
        ocfd:   .byte 2, "sbc.x", 0
        ocfe:   .byte 2, "inc.x", 0
        ocff:   .byte 2, "bbs7", 0

.scend

; used to figure out size of assembled disassembler code
disassembler_end:
