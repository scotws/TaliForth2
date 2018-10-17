\ ------------------------------------------------------------------------
testing long strings
decimal

marker long_string_tests

\ We keep this separate for now because it takes a long, long time -- don't be
\ suprised if the delay (-d) for talitest.py has to be set to 0.04 secs.  Once
\ the interface to py65 has been cleaned up, this might be intergrated again.
\ These are Tali-specific tests, the ANSI test suite has nothing like this.

\ Test strings longer than 255 chars (important for 8-bit systems)
\ 516 character string
: s14 s" test                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                " ;
T{ s14 swap drop -> 516 }T
T{ s14 -trailing -> s14 drop 4 }T

: s15 ." abcdefghijklmnopqrstuvwxyz1abcdefghijklmnopqrstuvwxyz2abcdefghijklmnopqrstuvwxyz3abcdefghijklmnopqrstuvwxyz4abcdefghijklmnopqrstuvwxyz5abcdefghijklmnopqrstuvwxyz6abcdefghijklmnopqrstuvwxyz7abcdefghijklmnopqrstuvwxyz8abcdefghijklmnopqrstuvwxyz9abcdefghijklmnopqrstuvwxyz10abcdefghijklmnopqrstuvwxyz11abcdefghijklmnopqrstuvwxyz12abcdefghijklmnopqrstuvwxyz13abcdefghijklmnopqrstuvwxyz14abcdefghijklmnopqrstuvwxyz15abcdefghijklmnopqrstuvwxyz16abcdefghijklmnopqrstuvwxyz17abcdefghijklmnopqrstuvwxyz18abcdefghijklmnopqrstuvwxyz19abcdefghijklmnopqrstuvwxyz20" ;
\ This should output the alphabet 20 times.
T{ s15 -> }T

\ Free memory used for these tests
long_string_tests
