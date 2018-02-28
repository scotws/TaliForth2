# Test Routine for forth_to_ophisbin.py 
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 28. Feb 2018
# This version: 28. Feb 2018

import forth_to_ophisbin
from unittest import TestCase, main


class HelperTestCase(TestCase):
    """Tests functions that support"""

    def test_has_bracket_comment(self):
        """Test routine to detect inline comments"""

        table = (('no comment', False),
                 ('a ( comment ) here', True),
                 ('( beginning ) comment', True),
                 ('( broken comment', False),
                 ('.( print command)', False),
                 ('a final ( comment)', True),
                 ('a ( comment ) with .( print )', True))

        for entry in table:

            given = entry[0]
            expected = entry[1]

            self.assertEqual(forth_to_ophisbin.has_bracket_comment(given), expected)


    def test_remove_bracket_comment(self):
        """Test routine to remove inline comments"""

        table = ((' no comment', ' no comment'),
                 (' a ( comment ) here', ' a here'),
                 (' ( beginning ) comment', ' comment'),
                 (' .( print command)', ' .( print command)'),
                 (' a final ( comment)', ' a final'),
                 (' a ( comment ) with .( print )', ' a with .( print )'))

        for entry in table:

            given = entry[0]
            expected = entry[1]

            self.assertEqual(forth_to_ophisbin.remove_bracket_comment(given), expected)


if __name__ == '__main__':
    main()
