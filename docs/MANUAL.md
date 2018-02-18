# Manual for Tali Forth 2 for the 65c02  
This version: 18. Feb 2018  
Scot W. Stevenson <scot.stevenson@gmail.com> 

(THIS TEXT IS UNDER DEVELOPMENT. SOME PARTS ARE INCOMPLETE, OTHERS DOWNRIGHT WRONG)

## Overview


## Installation


### Running the provided binary

Tali comes with an assembled version that should run out of the box with the
[py65mon](https://github.com/mnaberez/py65) simulator, a Python program. In this
version, Tali is compiled to 32k and starts at $8000. 

To install py65mon with Linux, use `sudo pip install -U py65`. If you don't 
have PIP installed, you will have to add it first with
```
sudo apt-get install python-pip
```
There is a setup.py script as part of the package, too. To start the emulator,
run:
```
py65mon --mpu 65c02 -r ophis.bin
```

## Assembly

Tali Forth was written with vim (well, obviously) and the [Ophis 2.1
cross-assembler](http://michaelcmartin.github.io/Ophis/). Ophis uses a slightly
different format than other assemblers, but is in Python and therefore will run
on almost any operating system. To install Ophis on Windows, use the link
provided above. For Linux:

```
git clone https://github.com/michaelcmartin/Ophis
cd src
sudo python setup.py install
```

Switch to the folder where the Tali code lives, and assemble with the primitive
shell script provided:

```
./assemble.sh
```

The script also automatically updates the file listings in the `docs` folder.

Note that Ophis will not accept math operation characters (`-*/+`) in label
names because it will try to perform those operations. Because of this, 
we use underscores for label names. This is a major difference to Liara
Forth.


## Gotchas

Tali has a 16-bit cell size (use `1 cells 8 * .` to get the cells size in bits
with any Forth), which can trip up calculations when compared to the _de facto_
standard Gforth with 64 bits. Take this example:
```
( Gforth ) DECIMAL 1000 100 UM* HEX SWAP U. U.  186A0 0  OK
( Tali )   DECIMAL 1000 100 UM* HEX SWAP U. U.  86A0 1  OK
```
Tali has to use the upper cell of a double-celled number to correctly report the
result, while Gforth doesn't. If the conversion from double to single is only
via a DROP instruction, this will produce different results.


## Testing

There is no automatic or formal test suite available at this time, and due to
space considerations, there probably never will be. The file `docs/testwords.md`
includes a collection of words that will help with some general cases.

To experiment with various parameters for native compiling, the Forth word
WORDS&SIZES is included in user_words.txt (but commented out by default). The
Forth is:
```
: words&sizes ( --) 
        latestnt 
        begin 
                dup 
        0<> while
                dup name>string type space
                dup wordsize u. cr      \ calculates and prints size of word
                2 + @
        repeat
        drop ; 
```
Changing the NC-LIMIT should show differences in the Forth words.


## For Developers 

Any feedback and comments is welcome. Feel free to adapt Tali Forth to your own
system - this is why the source code is perversely overcommented. 


### General notes

- The X register should not be changed without saving its pointer status

- The Y register is free to be changed by subroutines. This means it should not
  be expected to survive subroutines unchanged.

- All words should have one point of entry - the `xt_word` link - and one point
  of exit at `z_word`. In may cases, this means a branch to an internal label
  `_done` right before `z_word`.

- Because of the way native compiling works, the usual trick of combining
  JSR/RTS pairs to a single JMP (usually) doesn't work. 


### Coding style

Until I get around to writing a tool for Ophis assembler code that formats the
source file the way gofmt does for Go (golang), I work with the following rules:

- Actual opcodes are indented by **two tabs**

- Tabs are **eight characters long** and converted to spaces

- Function-like routines are followed by a one-tab indented "function doc" based
  on the Python 3 model: Three quotation marks at the start, three at the end it
  its own line, unless it is a one-liner. This should make it easier to
  automatically extract the docs for them at some point.

- The native words have a special commentary format that allows the automatic
  generation of word list by a tool in the tools folder, see there for details.

- Assembler mnenomics are lower case. I get enough uppercase insanity writing
  German, thank you very much.

- Hex numbers are also lower case, such as `$fffe`

- Numbers in mnemonics are a stripped-down as possible to reduce visual clutter:
  `lda 0,x` instead of `lda $00,x`. 

- Comments are included like popcorn to help readers who are new both to Forth
  and 6502 assembler.


## Frequently (and Infrequently) Asked Questions

### Why does Tali Forth 2 take so long to start up?

After the default kernel string is printed, you'll notice a short pause that
didn't occur with Tali Forth 1. This is because Tali Forth 2 has more words
defined in high-level Forth (see `forth-words.asm`) than Tali did. The pause
happens because they are being compiled on the fly.


### Why "Tali" Forth?

I like the name, and we're probably not going to have anymore kids I can give it
to.

(If it sounds vaguely familiar, you're probably thinking of Tali'Zorah vas
Normandy, a character in the "Mass Effect" universe created by EA / BioWare.
This software has absolutely nothing to do with either the game or the companies
and neither do I, expect that I've played the games and enjoyed them, though I
do have some issues with _Andromeda_. Like what happened to the quarian ark?)


### Then who was "Liara"?

Liara Forth is a STC Forth for the big sibling of the 6502, the 65816. Tali 1
came first, then I wrote Liara with that knowledge and learned even more, and
now Tali 2 is such much better for the experience. Oh, and it's another "Mass
Effect" character.

