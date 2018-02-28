# Raw Forth flies for Tali Forth 2 for the 65c02  
Scot W. Stevenson <scot.stevenson@gmail.com>   
First version: 27. Feb 2018
This version: 27. Feb 2018 

## What's all this then?

Tali Forth 2 uses a bunch of high-level Forth words that are compiled at
run-time, some defined by the system, some addition defined by the user. To
making using them easier, we create the original Forth files with `.fs` suffix
in this directory, and then use the `forth_to_dotbyte.py` tool in this directory
to convert them to Ophis `.byte " ... "` instructions. These are placed as
`.asm` files of the same name in the parent (main) folder. 

> Ophis actually has a directive, `.incbin`, to include files as binary.
> However, we need to strip comments and whitespace to make the ASCII file as
> compact as possible.


