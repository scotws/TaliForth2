# Tali Forth 2 for the 65c02  
Scot W. Stevenson <scot.stevenson@gmail.com>   
First version: (Tali Forth 1 ) 19. Jan 2014
This version: (Version 1.0 ) 25. Jan 2020

## Dude, I am the very model of a Salarian scientist, just let me start!

Run `py65mon -m 65c02 -r taliforth-py65mon.bin` from this directory.


## Introduction

Tali Forth 2 is a subroutine threaded code (STC) implementation of an ANS-based
Forth for the 65c02 8-bit MPU. The aim is to provide a modern Forth that is easy
to get started with and can be ported to individial hardware projects,
especially Single Board Computers (SBC), with little effort. It is free --
released in the public domain -- but with absolutely _no warranty_ of any kind.
Use at your own risk! (See `COPYING.txt` for details.) Tali Forth 2 is hosted at
GitHub. You can find the most current version at
[https://github.com/scotws/TaliForth2](https://github.com/scotws/TaliForth2).


## A little more detail please

Tali Forth 2 aims to be, roughly in order of priority: 

- **Easy to try.** Download the source -- or even just the binary
  `taliforth-py65mon.bin` -- and run the emulator with `py65mon -m 65c02 -r
  taliforth-py65mon.bin` to get it running. This lets you experiment with a
  working 8-bit Forth for the 65c02 without any special configuration. This
  includes things like block wordset.

- **Simple**. The simple subroutine-threaded (STC) design and excessively
  commented source code give hobbyists the chance to study a working Forth at
  the lowest level. Separate documentation - including a manual with more than
  100 pages - in the `docs` folder discusses specific topics and offers
  tutorials. The aim is to make it easy to port Tali Forth 2 to various 65c02
  hardware projects. 

- **Specific**. Many Forths available are "general" implementations with a small
  core adapted to the target processor. Tali Forth 2 was written as a "bare
  metal Forth" for the 65c02 8-bit MPU and that MPU only, with its strengths and
  limitations in mind. 

- **Standardized**. Most Forths available for the 65c02 are based on ancient,
  outdated templates such as FIG Forth. Learning Forth with them is like trying
  to learn modern English by reading Chaucer. Tali Forth (mostly) follows the
  current ANS Standard, and ensures this passing an enhanced test suite.
  
The functional reference for Tali is GNU Forth (Gforth,
[https://www.gnu.org/software/gforth/](https://www.gnu.org/software/gforth/)).
Programs written for Tali should run on Gforth or have a very good reason not
to. Also, may Gforth words were adapted for Tali, especially when they make the
code simpler (like `FIND-NAME` or `BOUNDS`). 

The first Tali Forth was my first Forth ever. It is hosted at
[https://github.com/scotws/TaliForth](https://github.com/scotws/TaliForth) and
is superceded by this version. The second version was strongly influence by
what I learned writing Liara Forth for the 65816. Liara and Tali 2 share large
parts of their internal logic. 


## Seriously super lots more detail 

See `docs\manual.html` for the Tali Forth manual, which covers the installation,
setup, tutorials, and internal structure. The central discussion forum is
[http://forum.6502.org/viewtopic.php?f=9&t=2926](http://forum.6502.org/viewtopic.php?f=9&t=2926)
at 6502.org.
