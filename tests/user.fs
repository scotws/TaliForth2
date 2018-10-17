\ ------------------------------------------------------------------------

\ FILE        : user.fs
\ DESCRIPTION : This file is for users to add their own tests to the
\ test suite.  To add a test, the syntax is:
\ T{ data_for_word word_to_test -> expected_results }T
\ eg.
\ T{ 5 dup -> 5 5 }T
\ If the test passes, Tali will simply report "ok".  If the test does
\ not pass, an error message will be printed.  Results are logged in
\ the file results.txt and users can run just this set of tests using
\ the command:
\ ./talitest.py -t user
