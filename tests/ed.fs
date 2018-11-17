\ ------------------------------------------------------------------------
testing editor words: ed

\ TODO Rewrite compare strings once s\" is online (check for linefeed character)

decimal
marker ed-tests 

\ Use 8000 (decimal) as write area. This may have to be changed if tests crash
\ to a higher value. Currently, we are already using 7000 (check with HERE)

\ --- a command ---
\ Simple adding of text
ed
a
abcdefgh
ijklmnop
.
8000w
q

T{ 8000 c@ -> char a }T
T{ 8000 8  s" abcdefgh" compare -> 0 }T
T{ 8008 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 8009 8  s" ijklmnop" compare -> 0 }T

\ Add text to end of existing text
ed
a
abcdefgh
ijklmnop
.
a
qrstuvwx
.
8000w
q
T{ 8000 8  s" abcdefgh" compare -> 0 }T
T{ 8008 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 8009 8  s" ijklmnop" compare -> 0 }T
T{ 8017 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 8018 8  s" qrstuvwx" compare -> 0 }T


\ Add a line between two lines of existing text
ed
a
abcdefgh
ijklmnop
.
1a
qrstuvwx
.
8000w
q
T{ 8000 8  s" abcdefgh" compare -> 0 }T
T{ 8008 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 8009 8  s" qrstuvwx" compare -> 0 }T
T{ 8017 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 8018 8  s" ijklmnop" compare -> 0 }T

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
8000w
q
T{ 8000 4  s" aaaa" compare -> 0 }T
T{ 8004 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 8005 4  s" cccc" compare -> 0 }T
T{ 8009 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 8010 4  s" dddd" compare -> 0 }T
T{ 8014 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 8015 4  s" bbbb" compare -> 0 }T


\ Add a line above existing text
ed
a
abcdefgh
.
0a
ijklmnop
.
8000w
q
T{ 8000 8  s" ijklmnop" compare -> 0 }T
T{ 8008 1  s" 10" here hexstore  here swap  compare -> 0 }T  \ Linefeed character
T{ 8009 8  s" abcdefgh" compare -> 0 }T



\ Free memory used for these tests
ed-tests

