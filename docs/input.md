# Input design for Tali Forth 2
Scot W. Stevenson <scot.stevenson@gmail.com>
First version: 27. Dez 2016 (Liara Forth)
This version: 24. Nov 2017

Tali Forth 2 follows the ANSI input model with REFILL instead of older forms. 

There are up to four possible input sources in Forth (C&D p. 155):

1. The keyboard ("user input device")

2. A character string in memory

3. A block file

4. A text file

To check which one is being used, we first call BLK, which gives us the number
of a mass storage block being used, or 0 for the "user input device" (keyboard).
In the second case, we use SOURCE-ID to find out where input is coming from: 0
for the keyboard, -1 (0ffff) for a string in memory, and a number n for a
file-id.

Since Tali currently doesn't support blocks, we can skip the BLK instruction and
go right to SOURCE-ID. 


## Starting up

The intial commands after reboot flow into each other: ``` COLD -> ABORT -> QUIT
``` This is the same as with pre-ANSI Forths. However, QUIT now calls REFILL to
get the input. REFILL does different things based on which of the four input
sources (see above) is active: 

1. **Keyboard entry.** This is the default. Get line of input via ACCEPT and
   return a TRUE flag even if the input string was empty.

2. **EVALUTE string.** Return a FALSE flag.

3. **Input from a buffer.** Not implemented at this time.

4. **Input from a file.** Not implemented at this time.


## The Command Line Interface

Tali Forth accepts input lines of up to 256 characters. It remembers one
previous input that can be accessed with CONTROL-p. 

The address of the current input buffer is stored in `cib` and is either 
`ibuffer1` or `ibuffer2`, each of which is 256 bytes long. The length of the
current buffer is stored in `ciblen` - this is the address that >IN returns. 

When a new line is entered, the address in `cib` is swapped, and the contents of
`ciblen` are moved to `piblen` (for "previous input buffer"). `ciblen` is set to
zero. 

When the previous entry is requested, the address in `cib` is swapped back, and 
`ciblen` and `piblen` are swapped as well.

SOURCE by default returns `cib` and `ciblen` as the address and length of the
input buffer. 

(http://forth.sourceforge.net/standard/dpans/a0006.htm)
(http://forth.sourceforge.net/standard/dpans/dpansa6.htm#A.6.1.2216)

At some point, this system might be expanded to a real history list.


### SAVE-INPUT and RESTORE-INPUT

(see http://forth.sourceforge.net/standard/dpans/dpansa6.htm#A.6.2.2182)



### EVALUATE

(Automatically calls SAVE-INPUT and RESTORE-INPUT)
(http://forth.sourceforge.net/standard/dpans/a0006.htm)


### STATE 

(http://forth.sourceforge.net/standard/dpans/dpans6.htm#6.1.2250)

## Literature

[C&D] Conklin, Edward K.; Rather, Elizabeth D. *Forth Programmers Handbook,*
3.rd edition

