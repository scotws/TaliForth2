# Coding Cheat Sheet for Tali Forth 2
Scot W. Stevenson <scot.stevenson@gmail.com>
First version: 28. Nov 2017
This version: 28. Nov 2017

While coding a Forth, there are certain assembler fragments that get repeated
over and over again. These could be included as macros, but that can make the
code harder to read for somebody only familiar with basic assembly.

Some of these fragments could be written in other variants, such as the "Push
value" version, which could increment the DSP twice before storing a value. We
try to keep these in the same sequence (a "dialect" or "code mannerism" if you
will) so we have the option of adding code analysis tools later.

But first:

### The stack drawing is your friend
```
               +--------------+
               |          ... |
               +-            -+
               |              |   ...
               +-  (empty)   -+
               |              |  FE,X
               +-            -+
         ...   |              |  FF,X
               +==============+
        $0076  |           LSB|  00,X   <-- DSP (X Register)
               +-    TOS     -+
        $0077  |           MSB|  01,X
               +==============+
        $0078  |  (garbage)   |  02,X   <-- DSP0
               +--------------+
        $0079  |              |  03,X
               + (floodplain) +
        $007A  |              |  04,X
               +--------------+

```
It should probably go on your wall or something.

### Drop TOS
```
                inx
                inx
```

### PUSH a value to the Data Stack

Remember the Data Stack Pointer (DSP, the X register of the 65c02)
points to the LSB of the TOS value.
```
                dex
                dex
                lda $<LSB>      ; or pla, jsr kernel_getc, etc.
                sta $00,x
                lda $<LSB>      ; or pla, jsr kernel_getc, etc.
                sta $01,x
```

### POP a value off the Data Stack
```
                lda $00,x
                sta $<LSB>      ; or pha, jsr kernel_putc, etc
                lda $01,x
                sta $<MSB>      ; or pha, jsr kernel_putc, etc
                inx
                inx
```

## Vim abbreviations

One option for these is to add abbreviations to your favorite editor, which
should of course be vim, because vim is cool. There are examples for
that further down. They all assume that auto-indent is on and we are
two tabs in with the code, and use `#` at the end of the abbreviation
to keep them separate from the normal words. My `~/.vimrc` file contains
the following lines for work on `.asm` files:

```
ab drop# inx<tab><tab>; drop<cr>inx<cr><left>
ab push# dex<tab><tab>; push<cr>dex<cr>lda $<LSB><cr>sta $00,x<cr>lda $<MSB><cr>sta $01,x<cr><up><up><up><up><end>
ab pop# lda $00,x<tab><tab>; pop<cr>sta $<LSB><cr>lda $01,x<cr>sta $<MSB><cr>inx<cr>inx<cr><up><up><up><up><up><end>
```
