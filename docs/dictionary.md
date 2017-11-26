# Dictionary Structure for Tali Forth 2 for the 65c02
Scot W. Stevenson <scot.stevenson@gmail.com>
First version: 19. Jan 2014
This version: 13. September 2017

THIS DOCUMENT IS BEING COMPLETELY REWRITTEN AND CURRENTLY INCOMPLETE


## Overview

Tali Forth follows the traditional model of a Forth dictionary - a linked list
of words terminated with a zero pointer - with two twists:

1. Headers and code are separate to enable various tricks in the code
2. Multiple lists instead of one list for speed 


## Header and code

Each word has a "name token" (nt, ``nt_word`` in the code) that points to the
first byte of the header, and an "execution token" (xt, ``xt_word``) that points
to the start of the code. There is a third pointer that references the byte
_after_ the end of the code (``z_word``) to enable native compilation of the
word if allowed.

Note that in constrast to most Forths, the length of the word is not contained
in the Dictionary at all. This is because we use multiple lists depending on the
word lenght.

## Linked Lists

http://forum.6502.org/viewtopic.php?f=9&t=4903



(WHAT FOLLOWS IS THE ORIGINAL TEST FROM TALI 1. PLEASE IGNORE)



Each header consists of one byte for the length of the word's string, a status
byte (see below), a link to the next word in the Dictionary (``0000`` marks its
end), the pointer to the beginning of the code (``xt_word``), the pointer to the
end of the code (``z_word``), and then the word's name string in plain ASCII,
without any terminating space or zero.

The Dictionary consists of hard-coded routines in assembly and Forth-coded words
that are generated when the system starts up (or after the COLD word). The first
hard-coded word is always DROP, the last one always BYE (use WORDS to get a
complete list and WORDS&SIZES for a list with the size of the code). Any word
that appears before DROP was automatically generated at boot from the Forth cod>

(During development, a large number of words were first included as high-level
Forth code or simple series of subroutine jumps, and then later optimized in
native code. The aim was to get the system up and running first.)




This document describes the structure of the Tali Forth dictionary entries. The
design stresses simple design and execution speed at the cost of size. 

The entries are linked through pointers to their first bytes (l_xxxx), which are
also the Execution Tokens (xt). This contains a hard-coded Branch Always (BRA)
instruction to the beginning of the Data Field (a_xxxx). This is followed by the
Length Byte, which contains the length of the word's name string (up to 31
chars, coded in 5 bits), and flags:

        IM - Precedence Bit, set if word is immediate
        NC - Native Compile Bit, set if word is to be compiled as native code
        CO - Compile Only Bit, so compile words are not interpreted 

The following two bytes are the link to the next dictionary entry (l_yyyy). A
zero in both bytes marks the end of the list. 

z_xxxx points to the end of the Code Field and is included to allow the
compiling of native code. The byte it points to is not encoded (usually the RTS
instruction). Note that it might make more sense to code this as an offset, not
a pointer, which would save one byte per word and would make looping easier.
This might be changed in the future. 

The Name Fields starts at an offset of seven bytes from the head of the entry.
Names are 7-bit uppercase ASCII. This field can be 31 bytes long. 

The Data Field starts after the Name Field, the first byte is referenced by the
BRA jump at the beginning of the entry. For normal entries, the code starts
here, whereas special types such as variables contain a subroutine jump to the
specialized code. 

                        7 6 5 4 3 2 1 0  bit 
                       +---------------+
      (xt) l_xxxx -->  |   BRA ($80)   |  +0 offset from xt (dictionary head)
                       +-            --+
           a_xxxx <--  |               |  +1 
                       +-+-+-+---------+
                       |I|N|C| Length  |  +2 
                       +-+-+-+---------+
                       |               |  +3 
                       +-    Link     -+ 
           l_yyyy <--  |               |  +4 
                       +---------------+
                       |               |  +5 
                       +-  Code End   -+ 
           z_xxxx <--  |               |  +6 
                       +---------------+
                       |               |  +7 
                       +-             -+
                       |     Name      |
                       +-             -+
                       |           ... |
                       +---------------+
           a_xxxx -->  |               | 
                       +-             -+ 
                       |     Data      |
                       +-             -+
           z_xxxx -->  |           ... |
                       +---------------+

Starting each entry with BRA wastes two bytes and up to four cycles per access.
However, it simplifies the structure: The word can be executed by jumping to the
link itself; the link is at the beginning of the entry, so all other entries can
be easily reached by offsets; we know exactly where all fields are (for
instance, the name field always starts seven bytes down). 
