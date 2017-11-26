# Manual for Tali Forth 2 for the 65c02 
First version: FEHLT
This version: 26. Nov 2017
Scot W. Stevenson <scot.stevenson@gmail.com> 

(THIS TEXT IS UNDER DEVELOPMENT AND MERELY A COLLECTION OF NOTES)

## Overview


## Installation


### Running the provided binary

Tali comes with an assembled version that should run out of the box with the
[py65mon](https://github.com/mnaberez/py65) simulator, a Python program. In this
version, Tali is compiled to 32k and starts at $8000. 

To install py65mon with Linux, use `sudo pip install -U py65`

(If you don't have PIP installed, you will have to add it first with
```
sudo apt-get install python-pip
```
There is a setup.py script as part of the package, too.) To start the emulator,
run:
```
py65mon --mpu 65C02 -r ophis.bin
```

## Assembly

Tali Forth was written with vim and the [Ophis 2.1
cross-assembler](http://michaelcmartin.github.io/Ophis/). Ophis uses a slightly
different format than other assemblers, but is in Python and therefore will run
on almost any operating system. To install Ophis on Windows, use the link
provided above. For Linux:

```
git clone https://github.com/michaelcmartin/Ophis
cd src
sudo python setup.py install
```

Switch to the folder where the Tali code lives, and assemble with

```
ophis --65c02 taliforth.asm
```

Development was performed with [py65mon](https://github.com/mnaberez/py65) which
is also in Python. To install on Linux:

```
sudo pip install -U py65
```

(If you don't have PIP installed, you will have to add it first with something like

```
sudo apt-get install python-pip
```

There is a setup.py script as part of the package, too.) To start the emulator, run:

```
py65mon --mpu 65C02 -r ophis.bin
```


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

There is no automatic or formal test suite available at this time. The file
docs/testwords.md includes a list of words that will help with some general
cases.


## For Developers 

Any feedback and comments is welcome. Feel free to adapt Tali Forth to your own
system - this is why the source code is perversely overcommented. 


### General notes

- The X register should not be changed without saving its pointer status

- The Y register is free to be changed by subroutines. This means it should not
  be expected to survive subroutines unchanged.


### Coding style

Until I get around to writing a tool for Ophis assembler code that formats the
source file the way gofmt does for Go (golang), I work with the following rules:

- Actual opcodes are indented by *two tabs*

- Tabs are *eight characters long* and converted to spaces

- Function-like routines are followed by a one-tab indented "function doc" based
  on the Python 3 model: Three quotation marks at the start, three at the end it
  its own line, unless it is a one-liner. This should make it easier to
  automatically extract the docs for them at some point.

- The native words have a special commentary format that allows the automatic
generation of word list by a tool in the tools folder, see there for details.

- Assembler mnenomics are lower case. I get enough uppercase insanity writing
  German, thank you very much.

- Hex numbers are also lower case, such as `$fffe`


## Frequently and Infrequently Asked Questions

### Why "Tali" Forth?

I like the name, and we're probably not going to have anymore kids I can give it
to.

(If it sounds vaguely familiar, you're probably thinking of Tali'Zorah vas
Normandy, a character in the "Mass Effect" universe created by EA / BioWare.
This software has absolutely nothing to do with either the game or the companies
and neither do I, expect that I've played the games and enjoyed them, though I
do have some issues with _Andromeda_. Like what happened to the quarian ark?)


### Then who is "Liara"?

Liara Forth is a STC Forth for the big sibling of the 6502, the 65816. Tali 1
came first, then I wrote Liara with that knowledge and learned even more, and
now Tali 2 is such much better for the experience.

