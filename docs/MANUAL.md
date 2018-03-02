# Manual for Tali Forth 2 for the 65c02  
This version: 27. Feb 2018  
Scot W. Stevenson <scot.stevenson@gmail.com> 

### Underflow stripping

Checking for underflow helps during the design and debug phases of writing Forth
code, but once it ready to ship, those nine bytes per check hurt, as we see in
the case above. To allow those checks to be stripped, we can set the system
variable `uf-strip` to TRUE. 

( Check code )
( UF flag in header ) 

### Other special cases

( R> and >R are a problem )
( Stack manipulation is stripped first, then underflow checking)

