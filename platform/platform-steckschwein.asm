; from the steckos jumptable
.alias krn_chrout $FFB3
.alias krn_getkey $FFB0
.alias krn_uart_tx  $FFDD
.alias krn_uart_rx  $FFE0


; steckOS uses the prg format used on the C64 with the first
; two bytes containing the load address
.word $8000
.org $8000
kernel_init:
        ; """Initialize the hardware.
        ; There is really not a lot to do as we use the steckOS kernel which already has done
        ; all the dirty work for us.
        ; We put this right before including the "real" taliforth as kernel_init is not called
        ; through any vector. Also, we save a few bytes as we need no jmp to kernel_init and no jmp to forth
        ; """
.scope
                ; We've successfully set everything up, so print the kernel
                ; string
                ldx #0
*               lda s_kernel_id,x
                beq _done
                jsr kernel_putc
                inx
                bra -
_done:
                ;jmp forth
.scend

; I/O facilities are handled in the separate kernel files because of their
; hardware dependencies. See docs/memorymap.txt for a discussion of Tali's
; memory layout.


; MEMORY MAP OF RAM

; Drawing is not only very ugly, but also not to scale. See the manual for
; details on the memory map. Note that some of the values are hard-coded in
; the testing routines, especially the size of the input history buffer, the
; offset for PAD, and the total RAM size. If these are changed, the tests will
; have to be changed as well


;    $0000  +-------------------+  ram_start, zpage, user0
;           |  User varliables  |
;           +-------------------+
;           |                   |
;           |                   |
;           +~~~~~~~~~~~~~~~~~~~+  <-- dsp
;           |                   |
;           |  ^  Data Stack    |
;           |  |                |
;    $0078  +-------------------+  dsp0, stack
;           |                   |
;           |   (Reserved for   |
;           |      kernel)      |
;           |                   |
;    $0100  +-------------------+
;           |                   |
;           |  ^  Return Stack  |  <-- rsp
;           |  |                |
;    $0200  +-------------------+  io area
;           |                   |
;    $0290  +-------------------+  rsp0, buffer, buffer0
;           |  |                |
;           |  v  Input Buffer  |
;           |                   |
;    $0300  +-------------------+  cp0
;           |  |                |
;           |  v  Dictionary    |
;           |       (RAM)       |
;           |                   |
;   (...)   ~~~~~~~~~~~~~~~~~~~~~  <-- cp
;           |                   |
;           |                   |
;           |                   |
;           |                   |
;           |                   |
;           |                   |
;    $7C00  +-------------------+  hist_buff, cp_end
;           |   Input History   |
;           |    for ACCEPT     |
;           |  8x128B buffers   |
;    $7fff  +-------------------+  ram_end


; HARD PHYSICAL ADDRESSES

; Some of these are somewhat silly for the 65c02, where for example
; the location of the Zero Page is fixed by hardware. However, we keep
; these for easier comparisons with Liara Forth's structure and to
; help people new to these things.

.alias ram_start $0000          ; start of installed 32 KiB of RAM
.alias ram_end   $8000-1        ; end of installed RAM
.alias zpage     ram_start      ; begin of Zero Page ($0000-$00ff)
.alias zpage_end $7F            ; end of Zero Page used ($0000-$007f)	
.alias stack0    $0100          ; begin of Return Stack ($0100-$01ff)
.alias hist_buff ram_end-$03ff  ; begin of history buffers


; SOFT PHYSICAL ADDRESSES

; Tali currently doesn't have separate user variables for multitasking. To
; prepare for this, though, we've already named the location of the user
; variables user0.

.alias user0     zpage          ; user and system variables
.alias rsp0      $ff            ; initial Return Stack Pointer (65c02 stack)
.alias bsize     $ff            ; size of input/output buffers
.alias buffer0   stack0+$190    ; input buffer ($0290-$02ff)
                                ; we need to skip $0200-$027f and then some
                                ; because IO area and other stuff
.alias cp0       buffer0+bsize  ; Dictionary starts after last buffer
.alias cp_end    hist_buff      ; Last RAM byte available for code
.alias padoffset $ff            ; offset from CP to PAD (holds number strings)


.require "../taliforth.asm" ; zero page variables, definitions

; =====================================================================
; FINALLY

; Of the 32 KiB we use, 24 KiB are reserved for Tali (from $8000 to $DFFF)
; and the last eight (from $E000 to $FFFF) are used by steckOS kernel

; Default kernel file for Tali Forth 2
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014
; This version: 18. Feb 2018
;
; This section attempts to isolate the hardware-dependent parts of Tali
; Forth 2 to make it easier for people to port it to their own machines.
; Ideally, you shouldn't have to touch any other files. There are three
; routines and one string that must be present for Tali to run:
;
;       kernel_init - Initialize the low-level hardware
;       kernel_getc - Get single character in A from the keyboard (blocks)
;       kernel_putc - Prints the character in A to the screen
;       s_kernel_id - The zero-terminated string printed at boot
;
; This default version Tali ships with is written for the py65mon machine
; monitor (see docs/MANUAL.md for details).

; The main file of Tali got us to $e000. However, py65mon by default puts
; the basic I/O routines at the beginning of $f000. We don't want to change
; that because it would make using it out of the box harder, so we just
; advance past the virtual hardware addresses.
;.advance $f010
platform_bye:
        jmp $e800



kernel_getc:
        ; """Get a single character from the keyboard.
        ; krn_getkey does not block and uses the carry flag to signal
        ; if there was a byte. We need a small wrapper routine.
        ; """
.scope
*       jsr krn_getkey
        bcc -
        rts
.scend

; we need no wrapper routine but alias krn_chrout as kernel_putc as they are compatible
.alias kernel_putc krn_chrout


; Leave the following string as the last entry in the kernel routine so it
; is easier to see where the kernel ends in hex dumps. This string is
; displayed after a successful boot
s_kernel_id:
        .byte "Tali Forth 2 default kernel for steckOS (19. Oct 2018)", AscLF, 0


; Add the interrupt vectors

; END
