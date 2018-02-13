# Stack Structure of Tali Forth 2 for the 65c02
Scot W. Stevenson <scot.stevenson@gmail.com> 
First version: 19. Jan 2014 
This version:  12. Feb 2018

Tali Forth 2 uses the lowest part of the top half of Zero Page for the Data
Stack (DS). This leaves the lower half of the Zero Page for any kernel stuff the
user might require. The DS therefore grows towards the initial user variables,
see definitions.asm for details. 

> Because of the danger of underflow, it is recommended that the user kernel's
> variables are keep closer to $0100 than to $007f.

The X register is used as the Data Stack Pointer (DSP). It points to the least
significant byte of the current top element of the stack ("Top of the Stack",
TOS). 

> In the first versions of Tali, the DSP pointed to the next _free_ element of
> the stack. The new system makes detecting underflow easier and parallels the
> structure of Liara Forth. 

Initially, the DSP points to $78, not $7F as might be expected. This provides a
few bytes as a "floodplain" in case of underflow. The initial value of the DSP
is defined `dsp0` in the code in definitions.asm. 

**Single cell values:** Since the cell size is 16 bits, each stack entry
consists of two bytes. They are stored little endian (least significant byte
first). Therefore, the DSP points to the LSB of the current TOS (try reading
that last sentence to a friend who isn't into computers. Aren't abbreviations 
fun?)

Because the DSP points to the current top of the stack, the byte it points to
after boot - `dsp0` - will never be accessed: The DSP is decremented first with
two `dex` instructions, and then the new value is placed on the stack. This
means that the initial byte is garbage and can be considered part of the floodplain. 
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
_Snapshot of the Data Stack with one entry as Top of the Stack (TOS). The DSP
has been increased by one and the value written._

Note that the 65c02 system stack - used as the Return Stack (RS) by Tali -
pushes the MSB on first and then the LSB (preserving little endian), so the
basic structure is the same for both stacks. 

Because of this stack design, the second entry ("next on stack", NOS) starts at
`02,X` and the third entry ("third on stack", 3OS) at `04,X`. 

**Underflow detection** In contrast to Tali Forth 1, this version contains
underflow detection for most words. It does this by comparing the Data Stack
Pointer (X) to values that it must be smaller than (because the stack grows
towards 0000). For instance, to make sure we have one element on the stack, we
write

```
                cpx #dsp0-1
                bmi okay

                lda #11         ; error string for underflow
                jmp error
okay:
                (...)
```
For the most common cases, we have:
```
           1 cell       dsp0-1
           2 cells      dsp0-3
           3 cells      dsp0-5
```
Though underflow detection slows the code down slighly, it adds enormously to
the stability of the program.

**Double cell values:** The double cell is stored on top of the single cell.
Note this places the sign bit at the beginning of the byte below the DSP.
```
               +---------------+
               |               |  
               +===============+  
               |            LSB|  $0,x   <-- DSP (X Register) 
               +-+  Top Cell  -+         
               |S|          MSB|  $1,x
               +-+-------------+ 
               |            LSB|  $2,x
               +- Bottom Cell -+         
               |            MSB|  $3,x   
               +===============+ 
```

**Under- and overflow.** For speed reasons, Tali only checks for underflow after
the execution of a word as part of the `quit` loop. There is no checking for
overflow, which in normal operation is too rare to justify the computing expense. 

