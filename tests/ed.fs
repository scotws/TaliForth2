\ ------------------------------------------------------------------------
testing editor words: ed

decimal
marker ed-tests 

\ Use 10000 (decimal) as write area. This may have to be changed if tests crash
\ to a higher value. Currently, we are already using 7000 (check with HERE).
\ Note ed tests will usually return with ( 0 0 ) on the stack because of the 
\ target address

\ === SIMPLE TESTS ===

\ --- a command ---

\ Simple adding of text; want aaaa bbbb
ed
a
aaaa
bbbb
.
10000w
q

T{ 10000 10  s\" aaaa\nbbbb\n" compare -> 10000 10 0 }T

\ Add text to end of existing text; want aaaa bbbb cccc
ed
a
aaaa
bbbb
.
a
cccc
.
10000w
q
T{ 10000 15  s\" aaaa\nbbbb\ncccc\n" compare -> 10000 15 0 }T


\ Add a line between two lines of existing text
\ Want aaaa cccc bbbb
ed
a
aaaa
bbbb
.
1a
cccc
.
10000w
q
T{ 10000 15  s\" aaaa\ncccc\nbbbb\n" compare -> 10000 15 0 }T

\ Add two lines between two existing lines of existing text
\ Want: aaaa cccc dddd bbbb
ed
a
aaaa
bbbb
.
1a
cccc
dddd
.
10000w
q
T{ 10000 20  s\" aaaa\ncccc\ndddd\nbbbb\n" compare -> 10000 20 0 }T

\ Add a line above existing text; want bbbb aaaa 
ed
a
aaaa
.
0a
bbbb
.
10000w
q
T{ 10000 10  s\" bbbb\naaaa\n" compare -> 10000 10 0 }T


\ --- d command ---

\ Delete first of two lines; want bbbb
ed
a
aaaa
bbbb
.
1d
10000w
q
T{ 10000 5  s\" bbbb\n" compare -> 10000 5 0 }T

\ Delete second of two lines; want aaaa
ed
a
aaaa
bbbb
.
2d
10000w
q
T{ 10000 5  s\" aaaa\n" compare -> 10000 5 0 }T

\ --- i command ---

\ Simple adding of text; want qqqq rrrr
ed
i
qqqq
rrrr
.
10000w
q
T{ 10000 10  s\" qqqq\nrrrr\n" compare -> 10000 10 0 }T

\ Add text to start of existing text; want tttt dddd aaaa
ed
a
dddd
aaaa
.
1i
tttt
.
10000w
q
T{ 10000 15  s\" tttt\ndddd\naaaa\n" compare -> 10000 15 0 }T


\ Add a line between two lines of existing text
\ Want mmmm oooo gggg
ed
a
mmmm
gggg
.
2i
oooo
.
10000w
q
T{ 10000 15  s\" mmmm\noooo\ngggg\n" compare -> 10000 15 0 }T

\ Add two lines between two existing lines of existing text
\ Want: tttt cccc dddd ssss
ed
a
tttt
ssss
.
2i
cccc
dddd
.
10000w
q
T{ 10000 20  s\" tttt\ncccc\ndddd\nssss\n" compare -> 10000 20 0 }T

\ Add a line above existing text; want uuuu zzzz 
ed
a
zzzz
.
0i
uuuu
.
10000w
q
T{ 10000 10  s\" uuuu\nzzzz\n" compare -> 10000 10 0 }T


\ === OUTPUT TESTS ===

\ These involve redirecting output and have the potential to crash the system.
\ They also assume that the assembler is working as well as the wordlist
\ functions. Note that the tests have to be defined as part of a word to work
\ correctly. Based on code by Sam Colwell, see
\ https://github.com/scotws/TaliForth2/issues/159 for a discussion of how this
\ works

assembler-wordlist >order
assembler-wordlist set-current

variable 'old-output
variable #saved-output
create 'saved-output  1000 allot

\ Retrieves the output string we saved after redirection
: saved-string ( -- addr u )  'saved-output #saved-output @ ;

\ We write our own output routine to replace the built-in one. Uses the
\ assembler macro push-a
: save-output ( c -- ) 
   [ push-a ]  \ "dex dex  sta 0,x  stz 1,x" - push A to TOS
   [ phy 36 lda.z pha 37 lda.z pha ] \ Save y and tmp1.
   saved-string + c!  \ Save the character.
   1 #saved-output +! \ Increment the string length.
   [ pla 37 sta.z pla 36 sta.z ply ] \ Restore y and tmp1.
;

: redirect-output ( -- )
   output @  'old-output !     \ save the original vector
   ['] save-output  output !   \ replace vector with our routine
   0 #saved-output ! ;         \ empty the string to start

: restore-output ( -- )  'old-output @  output ! ; 

\ ---- Internal test for output redirection (tests within tests!) ----

: internal-output-test  ( -- )
   redirect-output ." Redirection works, let's do this! " restore-output ; 

internal-output-test
cr .( >>>> )  saved-string type  .( <<<< ) cr


\ ---- Finally the actual redirection tests ----

( TODO ADD TESTS)

\ ---- Cleanup from redirection tests ----
previous
forth-wordlist set-current


\ === END OF ED TESTS ===

\ Free memory used for these tests
ed-tests
