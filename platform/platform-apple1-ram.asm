; This is the platform file for 65C02 based Apple 1 machines
; This version has a memory layout for RAM based TaliForth2
; Jump to $2900 from the WOZMON with "2900R" after loading the
; Forth into RAM.
; The original Apple 1 has a 6502, so TaliForth2 will not work
; on an origial Apple 1. But some replica machines (such as the
; Replica 1 from Vince Briel) have a 65C02.
; There is also Apple 1 emulators containing emulation for 65C02
; based Apple 1 machines:
;  * Pom 1 enhanced by Ken Wessen:
;    http://school.anhb.uwa.edu.au/personalpages/kwessen/apple1/krusader.htm
;  * lua_6502, an 65C02 Emulator written in Lua 5.3+
;    https://github.com/JorjBauer/lua-6502

.org $2900

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
;    $0200  +-------------------+  rsp0, buffer, buffer0
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
;    $2500  +-------------------+  hist_buff, cp_end
;           |   Input History   |
;           |    for ACCEPT     |
;           |  8x128B buffers   |
;    $28ff  +-------------------+  ram_end


; HARD PHYSICAL ADDRESSES

; Some of these are somewhat silly for the 65c02, where for example
; the location of the Zero Page is fixed by hardware. However, we keep
; these for easier comparisons with Liara Forth's structure and to
; help people new to these things.

.alias ram_start $0000          ; start of installed 32 KiB of RAM
.alias ram_end   $2900-1        ; end of free RAM
.alias zpage     ram_start      ; begin of Zero Page ($0000-$00ff)
.alias zpage_end $7F            ; end of Zero Page used ($0000-$007f)	
.alias stack0    $0100          ; begin of Return Stack ($0100-$01ff)
.alias hist_buff ram_end-$03ff  ; begin of history buffers


; SOFT PHYSICAL ADDRESSES

; Tali currently doesn't have separate user variables for multitasking. To
; prepare for this, though, we've already named the location of the user
; variables user0. Note cp0 starts one byte further down so that it currently
; has the address $300 and not $2FF. This avoids crossing the page boundry when
; accessing the user table, which would cost an extra cycle.

.alias user0     zpage            ; user and system variables
.alias rsp0      $ff              ; initial Return Stack Pointer (65c02 stack)
.alias bsize     $ff              ; size of input/output buffers
.alias buffer0   stack0+$100      ; input buffer ($0200-$027f)
.alias cp0       buffer0+bsize+1  ; Dictionary starts after last buffer
.alias cp_end    hist_buff        ; Last RAM byte available for code
.alias padoffset $ff              ; offset from CP to PAD (holds number strings)


.require "../taliforth.asm" ; zero page variables, definitions

; =====================================================================
; FINALLY

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

; All vectors currently end up in the same place - we restart the system
; hard. If you want to use them on actual hardware, you'll have to redirect
; them all.

kernel_init:
        ; """Initialize the hardware. This is called with a JMP and not
        ; a JSR because we don't have anything set up for that yet.
        ; In an Apple 1, the machine is already initialized from WOZROM
        ; so we just print the Kernel message and leave.
        ; """
.scope
                sei             ; Disable interrupts

                ; We've successfully set everything up, so print the kernel
                ; string
                ldx #0
*               lda s_kernel_id,x
                beq _done
                jsr kernel_putc
                inx
                bra -
_done:
                jmp forth
.scend

kernel_getc:
        ; """The high bit in the Apple 1 Keyboard Control Register KBDCR
        ; indicates a waiting keypress which will be read from the keyboard
        ; register KBD. Since the Apple 1 only knows upper case characters,
        ; and TaliForth2 needs lower case Forth words, we shift all upper case
        ; ASCII characters between 'A' and 'Z' to lower case 'a' to 'z'.
        ; """
.scope
.alias KBD   $D010		; Apple 1 keyboard register
.alias KBDCR $D011 		; Apple 1 keyboard control register

_loop:
  lda KBDCR 			; key press waiting?
  bpl _loop
  lda KBD			; read key
  and #$7F			; clear bit 7
  cmp #$41                      ; large 'A'
  bcc _exit                     ; below 'A'
  cmp #$5B                      ; large 'Z'+1
  bcs _exit                     ; above 'Z'
  eor #$20                      ; make lower case
_exit:
  rts
.scend

.scope
.alias DSP $D012 		; Display output register

kernel_putc:
                                ; """Print a single character to the console.
                                ; the Apple 1 can only display upper case
	                        ; characters. If the character to be printed
				; is between 'a' and 'z', it will be shifted to
				; upper case.
                                ; """

  bit DSP			; is the Display ready to receive a char?
  bmi kernel_putc		; no, loop
  cmp #$61                      ; little 'a'
  bcc out			; lower than 'a'
  cmp #$7B                      ; little 'z'+1
  bcs out			; higher than 'z'
  and #$DF			; clear bit 6 (make upper case)
out:
  cmp #AscLF			; Line feet?
  bne nolf
  lda #AscCR			; change to carriage return
nolf:
  sta DSP			; write out char
  rts
.scend

; platform dependend "bye" behaviour. for now, brk is retained like in platform-py65mon
platform_bye:
    brk


; Leave the following string as the last entry in the kernel routine so it
; is easier to see where the kernel ends in hex dumps. This string is
; displayed after a successful boot
s_kernel_id:
        .byte AscCR, AscCR, "Tali Forth 2 default kernel for Apple 1 (15.06.2019)", AscCR, 0

_taliend:	NOP
; END
