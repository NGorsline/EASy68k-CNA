# EASy68k-CNA
Dis-ass-embler
Test

# Registers
A1 - "Good buffer"
A3 - Used by WRITE loop to point to/iterate through a string constant to write to memory pointed to by A1
A5 - End address (from user)
A6 - Beginning address/iterator

D1 - Comparators
D5 - Word data @ A6 (to decode)
D7 - Opcode number for EA module (1 - 30, top-to-bottom according to our opcode chart)
