#!/usr/bin/env python3
# Convert SAN data file to assembler routines and headers
# Scot W. Stevenson <scot.stevenson@gmail.com>
# First version: 13. Dec 2018
# This version: 15. Dec 2018
"""Convert SAN data to assembler routines and headers

Assumes the file "opcodes65c02.txt" in the current directory with three
values in a tuple: Opcode in hex, SAN mnemonic as a string, and length
of instruction in bytes (1 to 3). It is used to generate entries for
three parts of Tali: The assembler routines in assembler.asm, the
header routines in header.asm, and the test routines in tests/asm.fs.

This is a one-shot program and is not maintained. Use at your own risk.
"""

SOURCE = 'opcodes65c02.txt'

TEMPLATE_ASSEMBLER = 'xt_asm_{4}:\t\t; {0} \ {3}\n'\
        '\t\tlda #${1}\n'\
        '\t\tldy #{2}\n'\
        '\t\tjmp asm_common\n'\
        'z_asm_{4}:\n'

TEMPLATE_HEADER = 'nt_asm_{2}:\n'\
        '\t\t.byte {1}, IM\n'\
        '\t\t.word {3}\n'\
        '\t\t.word xt_asm_{2}, z_asm_{2}\n'\
        '\t\t.byte "{0}"\n'

TEMPLATE_OPC = 'T{{ {0} {1} s" {3}{2}" opcode-test -> -1 -1 }}T'


def cleanup_opcode(ocs):
    """Given an opcode hex value in the form of a string such as '0xea',
    remove the '0x' prefix and return the actual two digits as uppercase
    string.
    """
    return ocs[2:].upper()


def labelize_mnemonic(mne):
    """Given a SAN mnemonic in the form of a string such as 'and.z', convert
    any dot to an underscore for use in the labels. Also convert any '#' into
    an 'h' so 'lda.#' becomes 'lda_h'.
    """
    s1 = mne.replace('.', '_')
    s2 = s1.replace ('#', 'h')
    return s2


def main():
    """Main function"""

    assembler_list = []
    header_list = []
    test_opc_list = []
    test_opr_list = []

    # Fake operands for testing: 1 byte, 2 byte, 3 byte instructions
    # First entry is dummy value. Note spaces.
    fake_opr = ['UNUSED', '', '12 ', '1122 ']

    with open(SOURCE) as opcode_list:

        previous_header = '0000'

        for line in opcode_list:
            ws = line.split()

            lm = labelize_mnemonic(ws[0])
            co = cleanup_opcode(ws[1])
            lgth = int(ws[2])

            assembler_list.append(TEMPLATE_ASSEMBLER.format(ws[0],\
                    co, lgth, ws[0].upper(), lm))

            header_list.append(TEMPLATE_HEADER.format(ws[0], len(ws[0]), lm,\
                    previous_header))

            previous_header = 'nt_asm_{0}'.format(lm)

            test_opc_list.append(TEMPLATE_OPC.format('0'+co, lgth,\
                ws[0], fake_opr[lgth]))

    # Print out everyting to standard output. The user can redirect this to
    # a file and edit the rest by hand
    for l in assembler_list:
        print(l)

    print('-'*80)

    for l in header_list:
        print(l)

    print('-'*80)

    for l in test_opc_list:
        print(l)



if __name__ == '__main__':
    main()
