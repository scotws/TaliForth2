; Default kernel file for Tali Forth 2 
; Scot W. Stevenson <scot.stevenson@gmail.com>
; First version: 19. Jan 2014
; This version: 26. Nov 2017
;
; This section attempts to isolate the hardware-dependent parts of Tali Forth
; to make it easier for people to port it two their own machines. Ideally, you
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


kernel_init:
        ; """Initialize the hardware. This is called with a JMP and not
        ; a JSR because we don't have anything set up for that yet. With
        ; py65mon, of course, this is really easy. -- At the end, we JMP
        ; back to the label forth to start the Forth system.
        ; """
                nop                     ; this is just to make a point
                jmp forth


kernel_getc:
        ; """Get a single character from the keyboard. By default, py65mon
        ; is set to $f004, which we just keep.
        ; """
                lda $f004
                rts
 
kernel_putc:
        ; """Print a single character to the console. By default, py65mon
        ; is set to $f001, which we just keep.
        ; """
                sta $f001
                rts
        
        
; Leave the following string as the last entry in the kernel routine so it
; is easier to see where the kernel ends in hex dumps. This string is
; displayed after a successful boot
s_kernel_id: .byte "Tali default kernel for py65mon (26. Nov 2017)", 0

; END
