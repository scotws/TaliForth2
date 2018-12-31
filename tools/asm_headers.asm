nt_asm_adc_h:
		.byte 5, IM
		.word 0000
		.word xt_asm_adc_h, z_asm_adc_h
		.byte "adc.#"

nt_asm_adc_x:
		.byte 5, IM
		.word nt_asm_adc_h
		.word xt_asm_adc_x, z_asm_adc_x
		.byte "adc.x"

nt_asm_adc_y:
		.byte 5, IM
		.word nt_asm_adc_x
		.word xt_asm_adc_y, z_asm_adc_y
		.byte "adc.y"

nt_asm_adc_z:
		.byte 5, IM
		.word nt_asm_adc_y
		.word xt_asm_adc_z, z_asm_adc_z
		.byte "adc.z"

nt_asm_adc_zi:
		.byte 6, IM
		.word nt_asm_adc_z
		.word xt_asm_adc_zi, z_asm_adc_zi
		.byte "adc.zi"

nt_asm_adc_ziy:
		.byte 7, IM
		.word nt_asm_adc_zi
		.word xt_asm_adc_ziy, z_asm_adc_ziy
		.byte "adc.ziy"

nt_asm_adc_zx:
		.byte 6, IM
		.word nt_asm_adc_ziy
		.word xt_asm_adc_zx, z_asm_adc_zx
		.byte "adc.zx"

nt_asm_adc_zxi:
		.byte 7, IM
		.word nt_asm_adc_zx
		.word xt_asm_adc_zxi, z_asm_adc_zxi
		.byte "adc.zxi"

nt_asm_and:     ; not "and" because of conflicts with Forth word
		.byte 4, IM
		.word nt_asm_adc_zxi
		.word xt_asm_and, z_asm_and
		.byte "and."

nt_asm_and_h:
		.byte 5, IM
		.word nt_asm_and
		.word xt_asm_and_h, z_asm_and_h
		.byte "and.#"

nt_asm_and_x:
		.byte 5, IM
		.word nt_asm_and_h
		.word xt_asm_and_x, z_asm_and_x
		.byte "and.x"

nt_asm_and_y:
		.byte 5, IM
		.word nt_asm_and_x
		.word xt_asm_and_y, z_asm_and_y
		.byte "and.y"

nt_asm_and_z:
		.byte 5, IM
		.word nt_asm_and_y
		.word xt_asm_and_z, z_asm_and_z
		.byte "and.z"

nt_asm_and_zi:
		.byte 6, IM
		.word nt_asm_and_z
		.word xt_asm_and_zi, z_asm_and_zi
		.byte "and.zi"

nt_asm_and_ziy:
		.byte 7, IM
		.word nt_asm_and_zi
		.word xt_asm_and_ziy, z_asm_and_ziy
		.byte "and.ziy"

nt_asm_and_zx:
		.byte 6, IM
		.word nt_asm_and_ziy
		.word xt_asm_and_zx, z_asm_and_zx
		.byte "and.zx"

nt_asm_and_zxi:
		.byte 7, IM
		.word nt_asm_and_zx
		.word xt_asm_and_zxi, z_asm_and_zxi
		.byte "and.zxi"

nt_asm_asl:
		.byte 3, IM
		.word nt_asm_and_zxi
		.word xt_asm_asl, z_asm_asl
		.byte "asl"

nt_asm_asl_a:
		.byte 5, IM
		.word nt_asm_asl
		.word xt_asm_asl_a, z_asm_asl_a
		.byte "asl.a"

nt_asm_asl_x:
		.byte 5, IM
		.word nt_asm_asl_a
		.word xt_asm_asl_x, z_asm_asl_x
		.byte "asl.x"

nt_asm_asl_z:
		.byte 5, IM
		.word nt_asm_asl_x
		.word xt_asm_asl_z, z_asm_asl_z
		.byte "asl.z"

nt_asm_asl_zx:
		.byte 6, IM
		.word nt_asm_asl_z
		.word xt_asm_asl_zx, z_asm_asl_zx
		.byte "asl.zx"

nt_asm_bcc:
		.byte 3, IM
		.word nt_asm_asl_zx
		.word xt_asm_bcc, z_asm_bcc
		.byte "bcc"

nt_asm_bcs:
		.byte 3, IM
		.word nt_asm_bcc
		.word xt_asm_bcs, z_asm_bcs
		.byte "bcs"

nt_asm_beq:
		.byte 3, IM
		.word nt_asm_bcs
		.word xt_asm_beq, z_asm_beq
		.byte "beq"

nt_asm_bit:
		.byte 3, IM
		.word nt_asm_beq
		.word xt_asm_bit, z_asm_bit
		.byte "bit"

nt_asm_bit_h:
		.byte 5, IM
		.word nt_asm_bit
		.word xt_asm_bit_h, z_asm_bit_h
		.byte "bit.#"

nt_asm_bit_x:
		.byte 5, IM
		.word nt_asm_bit_h
		.word xt_asm_bit_x, z_asm_bit_x
		.byte "bit.x"

nt_asm_bit_z:
		.byte 5, IM
		.word nt_asm_bit_x
		.word xt_asm_bit_z, z_asm_bit_z
		.byte "bit.z"

nt_asm_bit_zx:
		.byte 6, IM
		.word nt_asm_bit_z
		.word xt_asm_bit_zx, z_asm_bit_zx
		.byte "bit.zx"

nt_asm_bmi:
		.byte 3, IM
		.word nt_asm_bit_zx
		.word xt_asm_bmi, z_asm_bmi
		.byte "bmi"

nt_asm_bne:
		.byte 3, IM
		.word nt_asm_bmi
		.word xt_asm_bne, z_asm_bne
		.byte "bne"

nt_asm_bpl:
		.byte 3, IM
		.word nt_asm_bne
		.word xt_asm_bpl, z_asm_bpl
		.byte "bpl"

nt_asm_bra:
		.byte 3, IM
		.word nt_asm_bpl
		.word xt_asm_bra, z_asm_bra
		.byte "bra"

nt_asm_brk:
		.byte 3, IM
		.word nt_asm_bra
		.word xt_asm_brk, z_asm_brk
		.byte "brk"

nt_asm_bvc:
		.byte 3, IM
		.word nt_asm_brk
		.word xt_asm_bvc, z_asm_bvc
		.byte "bvc"

nt_asm_bvs:
		.byte 3, IM
		.word nt_asm_bvc
		.word xt_asm_bvs, z_asm_bvs
		.byte "bvs"

nt_asm_clc:
		.byte 3, IM
		.word nt_asm_bvs
		.word xt_asm_clc, z_asm_clc
		.byte "clc"

nt_asm_cld:
		.byte 3, IM
		.word nt_asm_clc
		.word xt_asm_cld, z_asm_cld
		.byte "cld"

nt_asm_cli:
		.byte 3, IM
		.word nt_asm_cld
		.word xt_asm_cli, z_asm_cli
		.byte "cli"

nt_asm_clv:
		.byte 3, IM
		.word nt_asm_cli
		.word xt_asm_clv, z_asm_clv
		.byte "clv"

nt_asm_cmp:
		.byte 3, IM
		.word nt_asm_clv
		.word xt_asm_cmp, z_asm_cmp
		.byte "cmp"

nt_asm_cmp_h:
		.byte 5, IM
		.word nt_asm_cmp
		.word xt_asm_cmp_h, z_asm_cmp_h
		.byte "cmp.#"

nt_asm_cmp_x:
		.byte 5, IM
		.word nt_asm_cmp_h
		.word xt_asm_cmp_x, z_asm_cmp_x
		.byte "cmp.x"

nt_asm_cmp_y:
		.byte 5, IM
		.word nt_asm_cmp_x
		.word xt_asm_cmp_y, z_asm_cmp_y
		.byte "cmp.y"

nt_asm_cmp_z:
		.byte 5, IM
		.word nt_asm_cmp_y
		.word xt_asm_cmp_z, z_asm_cmp_z
		.byte "cmp.z"

nt_asm_cmp_zi:
		.byte 6, IM
		.word nt_asm_cmp_z
		.word xt_asm_cmp_zi, z_asm_cmp_zi
		.byte "cmp.zi"

nt_asm_cmp_ziy:
		.byte 7, IM
		.word nt_asm_cmp_zi
		.word xt_asm_cmp_ziy, z_asm_cmp_ziy
		.byte "cmp.ziy"

nt_asm_cmp_zx:
		.byte 6, IM
		.word nt_asm_cmp_ziy
		.word xt_asm_cmp_zx, z_asm_cmp_zx
		.byte "cmp.zx"

nt_asm_cmp_zxi:
		.byte 7, IM
		.word nt_asm_cmp_zx
		.word xt_asm_cmp_zxi, z_asm_cmp_zxi
		.byte "cmp.zxi"

nt_asm_cpx:
		.byte 3, IM
		.word nt_asm_cmp_zxi
		.word xt_asm_cpx, z_asm_cpx
		.byte "cpx"

nt_asm_cpx_h:
		.byte 5, IM
		.word nt_asm_cpx
		.word xt_asm_cpx_h, z_asm_cpx_h
		.byte "cpx.#"

nt_asm_cpx_z:
		.byte 5, IM
		.word nt_asm_cpx_h
		.word xt_asm_cpx_z, z_asm_cpx_z
		.byte "cpx.z"

nt_asm_cpy:
		.byte 3, IM
		.word nt_asm_cpx_z
		.word xt_asm_cpy, z_asm_cpy
		.byte "cpy"

nt_asm_cpy_h:
		.byte 5, IM
		.word nt_asm_cpy
		.word xt_asm_cpy_h, z_asm_cpy_h
		.byte "cpy.#"

nt_asm_cpy_z:
		.byte 5, IM
		.word nt_asm_cpy_h
		.word xt_asm_cpy_z, z_asm_cpy_z
		.byte "cpy.z"

nt_asm_dec:
		.byte 3, IM
		.word nt_asm_cpy_z
		.word xt_asm_dec, z_asm_dec
		.byte "dec"

nt_asm_dec_a:
		.byte 5, IM
		.word nt_asm_dec
		.word xt_asm_dec_a, z_asm_dec_a
		.byte "dec.a"

nt_asm_dec_x:
		.byte 5, IM
		.word nt_asm_dec_a
		.word xt_asm_dec_x, z_asm_dec_x
		.byte "dec.x"

nt_asm_dec_z:
		.byte 5, IM
		.word nt_asm_dec_x
		.word xt_asm_dec_z, z_asm_dec_z
		.byte "dec.z"

nt_asm_dec_zx:
		.byte 6, IM
		.word nt_asm_dec_z
		.word xt_asm_dec_zx, z_asm_dec_zx
		.byte "dec.zx"

nt_asm_dex:
		.byte 3, IM
		.word nt_asm_dec_zx
		.word xt_asm_dex, z_asm_dex
		.byte "dex"

nt_asm_dey:
		.byte 3, IM
		.word nt_asm_dex
		.word xt_asm_dey, z_asm_dey
		.byte "dey"

nt_asm_eor:
		.byte 3, IM
		.word nt_asm_dey
		.word xt_asm_eor, z_asm_eor
		.byte "eor"

nt_asm_eor_h:
		.byte 5, IM
		.word nt_asm_eor
		.word xt_asm_eor_h, z_asm_eor_h
		.byte "eor.#"

nt_asm_eor_x:
		.byte 5, IM
		.word nt_asm_eor_h
		.word xt_asm_eor_x, z_asm_eor_x
		.byte "eor.x"

nt_asm_eor_y:
		.byte 5, IM
		.word nt_asm_eor_x
		.word xt_asm_eor_y, z_asm_eor_y
		.byte "eor.y"

nt_asm_eor_z:
		.byte 5, IM
		.word nt_asm_eor_y
		.word xt_asm_eor_z, z_asm_eor_z
		.byte "eor.z"

nt_asm_eor_zi:
		.byte 6, IM
		.word nt_asm_eor_z
		.word xt_asm_eor_zi, z_asm_eor_zi
		.byte "eor.zi"

nt_asm_eor_ziy:
		.byte 7, IM
		.word nt_asm_eor_zi
		.word xt_asm_eor_ziy, z_asm_eor_ziy
		.byte "eor.ziy"

nt_asm_eor_zx:
		.byte 6, IM
		.word nt_asm_eor_ziy
		.word xt_asm_eor_zx, z_asm_eor_zx
		.byte "eor.zx"

nt_asm_eor_zxi:
		.byte 7, IM
		.word nt_asm_eor_zx
		.word xt_asm_eor_zxi, z_asm_eor_zxi
		.byte "eor.zxi"

nt_asm_inc:
		.byte 3, IM
		.word nt_asm_eor_zxi
		.word xt_asm_inc, z_asm_inc
		.byte "inc"

nt_asm_inc_a:
		.byte 5, IM
		.word nt_asm_inc
		.word xt_asm_inc_a, z_asm_inc_a
		.byte "inc.a"

nt_asm_inc_x:
		.byte 5, IM
		.word nt_asm_inc_a
		.word xt_asm_inc_x, z_asm_inc_x
		.byte "inc.x"

nt_asm_inc_z:
		.byte 5, IM
		.word nt_asm_inc_x
		.word xt_asm_inc_z, z_asm_inc_z
		.byte "inc.z"

nt_asm_inc_zx:
		.byte 6, IM
		.word nt_asm_inc_z
		.word xt_asm_inc_zx, z_asm_inc_zx
		.byte "inc.zx"

nt_asm_inx:
		.byte 3, IM
		.word nt_asm_inc_zx
		.word xt_asm_inx, z_asm_inx
		.byte "inx"

nt_asm_iny:
		.byte 3, IM
		.word nt_asm_inx
		.word xt_asm_iny, z_asm_iny
		.byte "iny"

nt_asm_jmp:
		.byte 3, IM
		.word nt_asm_iny
		.word xt_asm_jmp, z_asm_jmp
		.byte "jmp"

nt_asm_jmp_i:
		.byte 5, IM
		.word nt_asm_jmp
		.word xt_asm_jmp_i, z_asm_jmp_i
		.byte "jmp.i"

nt_asm_jmp_xi:
		.byte 6, IM
		.word nt_asm_jmp_i
		.word xt_asm_jmp_xi, z_asm_jmp_xi
		.byte "jmp.xi"

nt_asm_jsr:
		.byte 3, IM
		.word nt_asm_jmp_xi
		.word xt_asm_jsr, z_asm_jsr
		.byte "jsr"

nt_asm_lda:
		.byte 3, IM
		.word nt_asm_jsr
		.word xt_asm_lda, z_asm_lda
		.byte "lda"

nt_asm_lda_h:
		.byte 5, IM
		.word nt_asm_lda
		.word xt_asm_lda_h, z_asm_lda_h
		.byte "lda.#"

nt_asm_lda_x:
		.byte 5, IM
		.word nt_asm_lda_h
		.word xt_asm_lda_x, z_asm_lda_x
		.byte "lda.x"

nt_asm_lda_y:
		.byte 5, IM
		.word nt_asm_lda_x
		.word xt_asm_lda_y, z_asm_lda_y
		.byte "lda.y"

nt_asm_lda_z:
		.byte 5, IM
		.word nt_asm_lda_y
		.word xt_asm_lda_z, z_asm_lda_z
		.byte "lda.z"

nt_asm_lda_zi:
		.byte 6, IM
		.word nt_asm_lda_z
		.word xt_asm_lda_zi, z_asm_lda_zi
		.byte "lda.zi"

nt_asm_lda_ziy:
		.byte 7, IM
		.word nt_asm_lda_zi
		.word xt_asm_lda_ziy, z_asm_lda_ziy
		.byte "lda.ziy"

nt_asm_lda_zx:
		.byte 6, IM
		.word nt_asm_lda_ziy
		.word xt_asm_lda_zx, z_asm_lda_zx
		.byte "lda.zx"

nt_asm_lda_zxi:
		.byte 7, IM
		.word nt_asm_lda_zx
		.word xt_asm_lda_zxi, z_asm_lda_zxi
		.byte "lda.zxi"

nt_asm_ldx:
		.byte 3, IM
		.word nt_asm_lda_zxi
		.word xt_asm_ldx, z_asm_ldx
		.byte "ldx"

nt_asm_ldx_h:
		.byte 5, IM
		.word nt_asm_ldx
		.word xt_asm_ldx_h, z_asm_ldx_h
		.byte "ldx.#"

nt_asm_ldx_y:
		.byte 5, IM
		.word nt_asm_ldx_h
		.word xt_asm_ldx_y, z_asm_ldx_y
		.byte "ldx.y"

nt_asm_ldx_z:
		.byte 5, IM
		.word nt_asm_ldx_y
		.word xt_asm_ldx_z, z_asm_ldx_z
		.byte "ldx.z"

nt_asm_ldx_zy:
		.byte 6, IM
		.word nt_asm_ldx_z
		.word xt_asm_ldx_zy, z_asm_ldx_zy
		.byte "ldx.zy"

nt_asm_ldy:
		.byte 3, IM
		.word nt_asm_ldx_zy
		.word xt_asm_ldy, z_asm_ldy
		.byte "ldy"

nt_asm_ldy_h:
		.byte 5, IM
		.word nt_asm_ldy
		.word xt_asm_ldy_h, z_asm_ldy_h
		.byte "ldy.#"

nt_asm_ldy_x:
		.byte 5, IM
		.word nt_asm_ldy_h
		.word xt_asm_ldy_x, z_asm_ldy_x
		.byte "ldy.x"

nt_asm_ldy_z:
		.byte 5, IM
		.word nt_asm_ldy_x
		.word xt_asm_ldy_z, z_asm_ldy_z
		.byte "ldy.z"

nt_asm_ldy_zx:
		.byte 6, IM
		.word nt_asm_ldy_z
		.word xt_asm_ldy_zx, z_asm_ldy_zx
		.byte "ldy.zx"

nt_asm_lsr:
		.byte 3, IM
		.word nt_asm_ldy_zx
		.word xt_asm_lsr, z_asm_lsr
		.byte "lsr"

nt_asm_lsr_a:
		.byte 5, IM
		.word nt_asm_lsr
		.word xt_asm_lsr_a, z_asm_lsr_a
		.byte "lsr.a"

nt_asm_lsr_x:
		.byte 5, IM
		.word nt_asm_lsr_a
		.word xt_asm_lsr_x, z_asm_lsr_x
		.byte "lsr.x"

nt_asm_lsr_z:
		.byte 5, IM
		.word nt_asm_lsr_x
		.word xt_asm_lsr_z, z_asm_lsr_z
		.byte "lsr.z"

nt_asm_lsr_zx:
		.byte 6, IM
		.word nt_asm_lsr_z
		.word xt_asm_lsr_zx, z_asm_lsr_zx
		.byte "lsr.zx"

nt_asm_nop:
		.byte 3, IM
		.word nt_asm_lsr_zx
		.word xt_asm_nop, z_asm_nop
		.byte "nop"

nt_asm_ora:
		.byte 3, IM
		.word nt_asm_nop
		.word xt_asm_ora, z_asm_ora
		.byte "ora"

nt_asm_ora_h:
		.byte 5, IM
		.word nt_asm_ora
		.word xt_asm_ora_h, z_asm_ora_h
		.byte "ora.#"

nt_asm_ora_x:
		.byte 5, IM
		.word nt_asm_ora_h
		.word xt_asm_ora_x, z_asm_ora_x
		.byte "ora.x"

nt_asm_ora_y:
		.byte 5, IM
		.word nt_asm_ora_x
		.word xt_asm_ora_y, z_asm_ora_y
		.byte "ora.y"

nt_asm_ora_z:
		.byte 5, IM
		.word nt_asm_ora_y
		.word xt_asm_ora_z, z_asm_ora_z
		.byte "ora.z"

nt_asm_ora_zi:
		.byte 6, IM
		.word nt_asm_ora_z
		.word xt_asm_ora_zi, z_asm_ora_zi
		.byte "ora.zi"

nt_asm_ora_ziy:
		.byte 7, IM
		.word nt_asm_ora_zi
		.word xt_asm_ora_ziy, z_asm_ora_ziy
		.byte "ora.ziy"

nt_asm_ora_zx:
		.byte 6, IM
		.word nt_asm_ora_ziy
		.word xt_asm_ora_zx, z_asm_ora_zx
		.byte "ora.zx"

nt_asm_ora_zxi:
		.byte 7, IM
		.word nt_asm_ora_zx
		.word xt_asm_ora_zxi, z_asm_ora_zxi
		.byte "ora.zxi"

nt_asm_pha:
		.byte 3, IM
		.word nt_asm_ora_zxi
		.word xt_asm_pha, z_asm_pha
		.byte "pha"

nt_asm_php:
		.byte 3, IM
		.word nt_asm_pha
		.word xt_asm_php, z_asm_php
		.byte "php"

nt_asm_phx:
		.byte 3, IM
		.word nt_asm_php
		.word xt_asm_phx, z_asm_phx
		.byte "phx"

nt_asm_phy:
		.byte 3, IM
		.word nt_asm_phx
		.word xt_asm_phy, z_asm_phy
		.byte "phy"

nt_asm_pla:
		.byte 3, IM
		.word nt_asm_phy
		.word xt_asm_pla, z_asm_pla
		.byte "pla"

nt_asm_plp:
		.byte 3, IM
		.word nt_asm_pla
		.word xt_asm_plp, z_asm_plp
		.byte "plp"

nt_asm_plx:
		.byte 3, IM
		.word nt_asm_plp
		.word xt_asm_plx, z_asm_plx
		.byte "plx"

nt_asm_ply:
		.byte 3, IM
		.word nt_asm_plx
		.word xt_asm_ply, z_asm_ply
		.byte "ply"

nt_asm_rol:
		.byte 3, IM
		.word nt_asm_ply
		.word xt_asm_rol, z_asm_rol
		.byte "rol"

nt_asm_rol_a:
		.byte 5, IM
		.word nt_asm_rol
		.word xt_asm_rol_a, z_asm_rol_a
		.byte "rol.a"

nt_asm_rol_x:
		.byte 5, IM
		.word nt_asm_rol_a
		.word xt_asm_rol_x, z_asm_rol_x
		.byte "rol.x"

nt_asm_rol_z:
		.byte 5, IM
		.word nt_asm_rol_x
		.word xt_asm_rol_z, z_asm_rol_z
		.byte "rol.z"

nt_asm_rol_zx:
		.byte 6, IM
		.word nt_asm_rol_z
		.word xt_asm_rol_zx, z_asm_rol_zx
		.byte "rol.zx"

nt_asm_ror:
		.byte 3, IM
		.word nt_asm_rol_zx
		.word xt_asm_ror, z_asm_ror
		.byte "ror"

nt_asm_ror_a:
		.byte 5, IM
		.word nt_asm_ror
		.word xt_asm_ror_a, z_asm_ror_a
		.byte "ror.a"

nt_asm_ror_x:
		.byte 5, IM
		.word nt_asm_ror_a
		.word xt_asm_ror_x, z_asm_ror_x
		.byte "ror.x"

nt_asm_ror_z:
		.byte 5, IM
		.word nt_asm_ror_x
		.word xt_asm_ror_z, z_asm_ror_z
		.byte "ror.z"

nt_asm_ror_zx:
		.byte 6, IM
		.word nt_asm_ror_z
		.word xt_asm_ror_zx, z_asm_ror_zx
		.byte "ror.zx"

nt_asm_rti:
		.byte 3, IM
		.word nt_asm_ror_zx
		.word xt_asm_rti, z_asm_rti
		.byte "rti"

nt_asm_rts:
		.byte 3, IM
		.word nt_asm_rti
		.word xt_asm_rts, z_asm_rts
		.byte "rts"

nt_asm_sbc:
		.byte 3, IM
		.word nt_asm_rts
		.word xt_asm_sbc, z_asm_sbc
		.byte "sbc"

nt_asm_sbc_h:
		.byte 5, IM
		.word nt_asm_sbc
		.word xt_asm_sbc_h, z_asm_sbc_h
		.byte "sbc.#"

nt_asm_sbc_x:
		.byte 5, IM
		.word nt_asm_sbc_h
		.word xt_asm_sbc_x, z_asm_sbc_x
		.byte "sbc.x"

nt_asm_sbc_y:
		.byte 5, IM
		.word nt_asm_sbc_x
		.word xt_asm_sbc_y, z_asm_sbc_y
		.byte "sbc.y"

nt_asm_sbc_z:
		.byte 5, IM
		.word nt_asm_sbc_y
		.word xt_asm_sbc_z, z_asm_sbc_z
		.byte "sbc.z"

nt_asm_sbc_zi:
		.byte 6, IM
		.word nt_asm_sbc_z
		.word xt_asm_sbc_zi, z_asm_sbc_zi
		.byte "sbc.zi"

nt_asm_sbc_ziy:
		.byte 7, IM
		.word nt_asm_sbc_zi
		.word xt_asm_sbc_ziy, z_asm_sbc_ziy
		.byte "sbc.ziy"

nt_asm_sbc_zx:
		.byte 6, IM
		.word nt_asm_sbc_ziy
		.word xt_asm_sbc_zx, z_asm_sbc_zx
		.byte "sbc.zx"

nt_asm_sbc_zxi:
		.byte 7, IM
		.word nt_asm_sbc_zx
		.word xt_asm_sbc_zxi, z_asm_sbc_zxi
		.byte "sbc.zxi"

nt_asm_sec:
		.byte 3, IM
		.word nt_asm_sbc_zxi
		.word xt_asm_sec, z_asm_sec
		.byte "sec"

nt_asm_sed:
		.byte 3, IM
		.word nt_asm_sec
		.word xt_asm_sed, z_asm_sed
		.byte "sed"

nt_asm_sei:
		.byte 3, IM
		.word nt_asm_sed
		.word xt_asm_sei, z_asm_sei
		.byte "sei"

nt_asm_sta:
		.byte 3, IM
		.word nt_asm_sei
		.word xt_asm_sta, z_asm_sta
		.byte "sta"

nt_asm_sta_x:
		.byte 5, IM
		.word nt_asm_sta
		.word xt_asm_sta_x, z_asm_sta_x
		.byte "sta.x"

nt_asm_sta_y:
		.byte 5, IM
		.word nt_asm_sta_x
		.word xt_asm_sta_y, z_asm_sta_y
		.byte "sta.y"

nt_asm_sta_z:
		.byte 5, IM
		.word nt_asm_sta_y
		.word xt_asm_sta_z, z_asm_sta_z
		.byte "sta.z"

nt_asm_sta_zi:
		.byte 6, IM
		.word nt_asm_sta_z
		.word xt_asm_sta_zi, z_asm_sta_zi
		.byte "sta.zi"

nt_asm_sta_ziy:
		.byte 7, IM
		.word nt_asm_sta_zi
		.word xt_asm_sta_ziy, z_asm_sta_ziy
		.byte "sta.ziy"

nt_asm_sta_zx:
		.byte 6, IM
		.word nt_asm_sta_ziy
		.word xt_asm_sta_zx, z_asm_sta_zx
		.byte "sta.zx"

nt_asm_sta_zxi:
		.byte 7, IM
		.word nt_asm_sta_zx
		.word xt_asm_sta_zxi, z_asm_sta_zxi
		.byte "sta.zxi"

nt_asm_stx:
		.byte 3, IM
		.word nt_asm_sta_zxi
		.word xt_asm_stx, z_asm_stx
		.byte "stx"

nt_asm_stx_z:
		.byte 5, IM
		.word nt_asm_stx
		.word xt_asm_stx_z, z_asm_stx_z
		.byte "stx.z"

nt_asm_stx_zy:
		.byte 6, IM
		.word nt_asm_stx_z
		.word xt_asm_stx_zy, z_asm_stx_zy
		.byte "stx.zy"

nt_asm_sty:
		.byte 3, IM
		.word nt_asm_stx_zy
		.word xt_asm_sty, z_asm_sty
		.byte "sty"

nt_asm_sty_z:
		.byte 5, IM
		.word nt_asm_sty
		.word xt_asm_sty_z, z_asm_sty_z
		.byte "sty.z"

nt_asm_sty_zx:
		.byte 6, IM
		.word nt_asm_sty_z
		.word xt_asm_sty_zx, z_asm_sty_zx
		.byte "sty.zx"

nt_asm_stz:
		.byte 3, IM
		.word nt_asm_sty_zx
		.word xt_asm_stz, z_asm_stz
		.byte "stz"

nt_asm_stz_x:
		.byte 5, IM
		.word nt_asm_stz
		.word xt_asm_stz_x, z_asm_stz_x
		.byte "stz.x"

nt_asm_stz_z:
		.byte 5, IM
		.word nt_asm_stz_x
		.word xt_asm_stz_z, z_asm_stz_z
		.byte "stz.z"

nt_asm_stz_zx:
		.byte 6, IM
		.word nt_asm_stz_z
		.word xt_asm_stz_zx, z_asm_stz_zx
		.byte "stz.zx"

nt_asm_tax:
		.byte 3, IM
		.word nt_asm_stz_zx
		.word xt_asm_tax, z_asm_tax
		.byte "tax"

nt_asm_tay:
		.byte 3, IM
		.word nt_asm_tax
		.word xt_asm_tay, z_asm_tay
		.byte "tay"

nt_asm_trb:
		.byte 3, IM
		.word nt_asm_tay
		.word xt_asm_trb, z_asm_trb
		.byte "trb"

nt_asm_trb_z:
		.byte 5, IM
		.word nt_asm_trb
		.word xt_asm_trb_z, z_asm_trb_z
		.byte "trb.z"

nt_asm_tsb:
		.byte 3, IM
		.word nt_asm_trb_z
		.word xt_asm_tsb, z_asm_tsb
		.byte "tsb"

nt_asm_tsb_z:
		.byte 5, IM
		.word nt_asm_tsb
		.word xt_asm_tsb_z, z_asm_tsb_z
		.byte "tsb.z"

nt_asm_tsx:
		.byte 3, IM
		.word nt_asm_tsb_z
		.word xt_asm_tsx, z_asm_tsx
		.byte "tsx"

nt_asm_txa:
		.byte 3, IM
		.word nt_asm_tsx
		.word xt_asm_txa, z_asm_txa
		.byte "txa"

nt_asm_txs:
		.byte 3, IM
		.word nt_asm_txa
		.word xt_asm_txs, z_asm_txs
		.byte "txs"

nt_asm_tya:
		.byte 3, IM
		.word nt_asm_txs
		.word xt_asm_tya, z_asm_tya
		.byte "tya"
