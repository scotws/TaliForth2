# Tali Forth 2 for the 65c02 
Scot W. Stevenson <scot.stevenson@gmail.com> 
First version: 19. Jan 2014 (original Tali Forth)
This version: 21. Nov 2017

(THIS VERSION OF TALI IS BEING COMPLETELY REWRITTEN, THE CODE CURRENTLY WON'T
EVEN ASSEMBLE. COME BACK LATER!)

## Dude, I am the very model of a Salarian scientist, let me just start!

Run `py65mon --mpu 65C02 -r ophis.bin` from this directory.


## Introduction

Tali Forth is a Subroutine Threaded Code (STC) implementation of ANSI(ish) Forth
for the 65c02 MPU. The aim is to provide a modern Forth that is easy to port to
individial hardware projects, especially Single Board Computers (SBC). It is
released in the public domain with no warranty of any kind -- use at your own
risk (see `COPYING.txt` for details.) Tali Forth is hosted at GitHub, you can
find the most current version at
[https://github.com/scotws/TaliForth](https://github.com/scotws/TaliForth).


## More detail 

Tali Forth aims to be, in rough order of priority: 

- **Simple**. The primary aim is to create a Forth system that can be understood
  byte-by-byte by interested hobbyists, who can use this knowledge to adapt this
  software to their own hardware. This is one of the reasons why the STC design
  was chosen, and why the source code is perversely overcommented. 

- **Specific**. Many Forths available are "general" implementations with a small
  core adapted to the target processor. Tali Forth was written as a "bare metal
  Forth" for the 65c02 8-bit MPU and that MPU only, with its strengths and
  limitations in mind. 

- **Standardized**. Most Forths available for the 6502 are based on ancient,
  outdated templates such as FIG Forth. Learning Forth with them is like trying
  to learn modern English by reading Chaucer. Tali Forth roughly follows the
  ANSI Standard 200x, with various additions. 
  
The functional reference for Tali is GNU Forth (GForth,
[https://www.gnu.org/software/gforth/](https://www.gnu.org/software/gforth/)).
Programs written for Tali should run on Gforth or have a very good reason not
to. Also, may Gforth words were adapted for Tali, especially when they make the
code simpler (see `FIND-NAME` or `BOUNDS`). 
  

## Seriously super lots more detail 

See `docs\MANUAL.md` for the Tali Forth manual, which covers the installation,
setup and internal structure. The central discussion forum is
[http://forum.6502.org/viewtopic.php?f=9&t=2926](http://forum.6502.org/viewtopic.php?f=9&t=2926)
at 6502.org.
