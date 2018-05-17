# EASy68k-CNA
Dis-ass-embler
Test

# Registers
A1 - "Good buffer"

A3 - Used by WRITE loop to point to/iterate through a string constant to write to memory pointed to by A1

A4 - Pointer to write the disassembled code (ASCII)

A5 - End address (from user)

A6 - Beginning address/iterator


D0 - Trap task numbers

D1 - Comparators. D1 is the length of the input given. for example: if user input was 3000, then D1 holds 4

D5 - Word data @ A6 (to decode)

D7 - Opcode number for EA module (1 - 30, top-to-bottom according to our opcode chart)
