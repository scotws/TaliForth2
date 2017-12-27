; Default kernel file for Tali Forth 2 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014
; This version: 27. Dec 2017
;
; This section attempts to isolate the hardware-dependent parts of Tali Forth
; to make it easier for people to port it to their own machines. Ideally, you
; shouldn't have to touch the other files. There are three routines and one 
; string that must be present for Tali to run:
;
;       kernel_init - Initialize the low-level hardware
;       kernel_getc - Gets a single character in A from the keyboard
;       kernel_putc - Prints the character in A to the screen
;       s_kernel_id - The zero-terminated string printed at boot
;
; This default version Tali ships with is written for the py65mon machine 
; monitor (see docs/MANUAL.md for details). 

; The main file of Tali got us to $e000. However, py65mon by default puts
; the basic I/O routines at the beginning of $f000. We don't want to change
; that because it would make using it out of the box harder, so we just 
; advance past the virtual hardware addresses.
.advance $f006

; All vectors currently end up in the same place - we restart the system
; hard. If you want to use them on actual hardware, you'll have to redirect
; them all.
v_nmi:
v_reset:
v_irq:
kernel_init:
        ; """Initialize the hardware. This is called with a JMP and not
        ; a JSR because we don't have anything set up for that yet. With
        ; py65mon, of course, this is really easy. -- At the end, we JMP
        ; back to the label forth to start the Forth system.
        ; """
                
        ; We've successfully set everything up, so print the kernel
        ; string

.scope
                ldx #00
*               lda s_kernel_id,x
                beq _done
                jsr kernel_putc
                inx
                bra -
_done:
                jmp forth
.scend

kernel_getc:
.scope
        ; """Get a single character from the keyboard. By default, py65mon
        ; is set to $f004, which we just keep. Note that py65mon's getc routine
        ; is non-blocking, so it will return '00' even if no key has been
        ; pressed. We turn this into a blocking version by waiting for a
        ; non-zero character.
        ; """
_loop:
                lda $f004
                beq _loop
                rts
.scend
 
kernel_putc:
        ; """Print a single character to the console. By default, py65mon
        ; is set to $f001, which we just keep.
        ; """
                sta $f001
                rts
        
        
; Leave the following string as the last entry in the kernel routine so it
; is easier to see where the kernel ends in hex dumps. This string is
; displayed after a successful boot

s_kernel_id: .byte "Tali default kernel for py65mon (27. Dec 2017)", AscLF, 0

; --------------------------------------------------------------------- 
; INTERRUPT VECTORS

.advance $fffa

.word v_nmi
.word v_reset
.word v_irq

; END
