#!/usr/bin/env python3
# Convert SAN data file to assembler routines and headers
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 13. Dec 2018
# This version: 13. Dec 2018
"""Convert SAN data to assembler routines and headers

Assumes the file "opcodes65c02.txt" in the current directory with three
values in a tuple: Opcode in hex, SAN mnemonic as a string, and length
of instruction in bytes (1 to 3). It is used to generate entries for
three parts of Tali: The assembler routines in assembler.asm, the
header routines in header.asm, and the test routines in tests/asm.fs.

This is a one-shot program and is not maintained. Use at your own risk.
"""

SOURCE = 'opcodes65c02.txt'

TEMPLATE_ASSEMBLER = 'xt_asm_{0}:\n'\
        '        jsr asm_common\n'\
        '        .byte ${1}, {2}\n'\
        'z_asm_{0}:\n'


TEMPLATE_HEADER = 'nt_{0}:\n'\
        '        .byte {1}, IM\n'\
        '        .word 0000, xt_{2}, z_{3}\n'\
        '        .byte "{4}"\n'


def main():
    """Main function"""

    with open(SOURCE) as opcode_list:

        for line in opcode_list:
            ws = line.split()

            if ws[1] == 'UNUSED':
                continue 

            print(ws[0], ":", ws[1], ws[2])


if __name__ == '__main__':
    main()
