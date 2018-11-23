\ ------------------------------------------------------------------------
testing editor words: ed

\ TODO Rewrite compare strings once s\" is online (check for linefeed character)

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

\ === END OF ED TESTS ===

\ Free memory used for these tests
ed-tests
