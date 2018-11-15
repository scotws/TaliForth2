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

\ Simple adding of text
ed
a
abcdefgh
ijklmnop
.
10000w
q

T{ 10000 c@ -> 0 0 char a }T
T{ 10000 8  s" abcdefgh" compare -> 0 }T
T{ 10008 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 10009 8  s" ijklmnop" compare -> 0 }T

\ Add text to end of existing text
ed
a
abcdefgh
ijklmnop
.
a
qrstuvwx
.
10000w
q
T{ 10000 8  s" abcdefgh" compare -> 0 0 0 }T
T{ 10008 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 10009 8  s" ijklmnop" compare -> 0 }T
T{ 10017 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 10018 8  s" qrstuvwx" compare -> 0 }T


\ Add a line between two lines of existing text
ed
a
abcdefgh
ijklmnop
.
1a
qrstuvwx
.
10000w
q
T{ 10000 8  s" abcdefgh" compare -> 0 0 0 }T
T{ 10008 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 10009 8  s" qrstuvwx" compare -> 0 }T
T{ 10017 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 10018 8  s" ijklmnop" compare -> 0 }T

\ Add two lines between two existing lines of existing text
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
T{ 10000 4  s" aaaa" compare -> 0 0 0 }T
T{ 10004 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 10005 4  s" cccc" compare -> 0 }T
T{ 10009 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 10010 4  s" dddd" compare -> 0 }T
T{ 10014 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 10015 4  s" bbbb" compare -> 0 }T


\ Add a line above existing text
ed
a
abcdefgh
.
0a
ijklmnop
.
10000w
q
T{ 10000 8  s" ijklmnop" compare -> 0 0 0 }T
T{ 10008 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 10009 8  s" abcdefgh" compare -> 0 }T


\ --- d command ---

\ Delete first of two lines
ed
a
aaaa
bbbb
.
1d
10000w
q
T{ 10000 4  s" bbbb" compare -> 0 0 0 }T

\ Delete second of two lines
ed
a
aaaa
bbbb
.
2d
10000w
q
T{ 10000 4  s" aaaa" compare -> 0 0 0 }T

\ === END OF ED TESTS ===

\ Free memory used for these tests
ed-tests
