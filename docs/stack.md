# Stack Structure of Tali Forth 2 for the 65c02
Scot W. Stevenson <scot.stevenson@gmail.com> 
First version: 19. Jan 2014 
This version:  27. Feb 2017 

Tali Forth uses the lowest part of Zero Page for the Data Stack (DS) and the X
register as the Data Stack Pointer (DSP). This points to the current top element
of the stack ("Top of the Stack", TOS). 

> In the first versions of Tali, the DSP pointed to the next free element of the
> stack. The new system makes detecting underflow easier and parallels the
> structure of Liara Forth. 

Initially, the DSP points to $F8, not $FF as might be expected. This provides a
few bytes as a "floodplain" in case of underflow. The initial value of the DSP
is `dsp0` in the code. 

**Single cell values:** Since the cell size is 16 bits, each stack entry
consists of two bytes. They are stored little endian (least significant byte
first). Therefore, the DSP points to the LSB of the current TOS (try reading
that last sentence to a friend who isn't into computers. Aren't abbreviations 
fun?)

Because the DSP points to the current top of the stack, the byte it points to
after boot - `DSP0` - will never be accessed: The DSP is decremented first with
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
        $01F6  |           LSB|  00,X   <-- DSP (X Register)
               +-    TOS     -+ 
        $01F7  |           MSB|  01,X
               +==============+ 
        $01F8  |  (garbage)   |  02,X   <-- DSP0 
               +--------------+           
        $01F9  |              |  03,X
               + (floodplain) + 
        $01FA  |              |  04,X
               +--------------+           
```
_Snapshot of the Data Stack with one entry as Top of the Stack (TOS). The DSP
has been increased by one and the value written._

Note that the 65c02 system stack - used as the Return Stack (RS) by Tali -
pushes the MSB on first and then the LSB (preserving little endian), so the
basic structure is the same for both stacks. 

Because of this stack design, the second entry ("next on stack", NOS) starts at
`02,X` and the third entry ("third on stack", 3OS) at `04,X`. 

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
the execution of a word as part of the QUIT loop. There is no checking for
overflow. 

