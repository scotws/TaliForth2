# Platform-specific definitions for Tali Forth 2
First version: 17. Oct 2018
This version: 17. Oct 2018

This folder contains platform-specific information for systems that run Tali
Forth 2. The default value for testing with the py65 emulator is
`platform-py65mon.asm`. Others are included to make life easier for individual
developers and as examples for people who want to port Tali to their own
hardware. 

To submit your configuration file, pick a name with the form `platform-*.asm`
that is not taken yet and initiate a pull request with it. A few comment lines
at the beginning with some background information would be nice. You'll probably
want to include your own boot string (see the bottom of the file) because that's
pretty cool.

Submitting your code implies that you are okay with other people using or
adapting it for their own systems. If your routines contain code for control of
your supervillain hide-out, the Evil League of Evil suggests you keep it off of
GitHub. 

Note that this is being provided as a service only. As always, we take no
resposibility for anything, and you'll have to keep an eye on the code
yourself.
