# Dictionary Structure for Tali Forth 2 for the 65c02
Scot W. Stevenson <scot.stevenson@gmail.com>
First version: 19. Jan 2014
This version: 04. Feb 2018


## Overview

Tali Forth 2 follows the traditional model of a Forth dictionary - a linked list
of words terminated with a zero pointer. The headers and code are kept separate
to allow various tricks in the code.


## Elements of the Header

Each header is at least eight bytes long.

              8 bit     8 bit
               LSB       MSB
 nt_word ->  +--------+--------+
          +0 | Length | Status |
             +--------+--------+
          +2 | Next Header     | nt_next_word
             +-----------------+
          +4 | Start of Code   | xt_word 
             +-----------------+
          +6 | End of Code     | z_word
             +--------+--------+
          +8 | Name   |        |
             +--------+--------+
             |        |        |
             +--------+--------+
             |        |  ...   |
          +n +--------+--------+


Each word has a *name token* (nt, ``nt_word`` in the code) that points to the
first byte of the header. This is the length of the word's name string, which is
limited to 255 characters. 

The second byte in the header (index 1) is the *status byte*. It is created by
the flags defined in the file ``definitions.asm``: 

        CO - Compile Only
        IM - Immediate Word
        NN - Never Native Compile 
        AN - Always Native Compile (may not be called by JSR)

Note there are currently four bits unused. The status byte is followed by the
*pointer to the next header* in the linked list, which makes it the named token of
the next word. A ``0000`` in this position signales the end of the linked list,
which by convention is the word ``bye``. 

This is followed by the current word's *execution token* (xt, ``xt_word``) that
points to the start of the actual code. Some words that have the same
functionality point to the same code block. The *end of the code* is referenced
through the next pointer (``z_word``) to enable native compilation of the word
if allowed. 

The *name string* starts at the eighth byte. The string is _not_
zero-terminated. By default, the strings of Tali Forth 2 are lower case, but
case is respected for words the user defines, so ``quarian`` is a different
words than ``QUARIAN``. 


## Structure of the Header List 

Tali Forth 2 distinguishes between three different list sources: The *native
words* that are hard-coded in the file ``native_words.asm``, the *forth words*
which are defined as high-level words and then generated at run-time when Tali
Forth starts up, and *user words* in the file ``user_words.asm`` which is empty
when Tali Forth ships. 

Tali has an unusually high number of native words in an attempt to make the
Forth as fast as possible on the 65c02. The first word in the list - the one
that is checked first - is always ``drop``, the last one - the one checked for
last - is always ``bye``. The words which are (or are assumed to be) used more
than others come first. Since humans are slow, words that are used more
interactively like ``words`` come later. 

The list of Forth words ends with the intro string. This functions as a
primitive form of a self-test: If you see the string and only the string, the
compilation of the Forth words worked.
