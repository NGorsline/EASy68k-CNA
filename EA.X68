*-----------------------------------------------------------
* Title      : EA Module
* Written by : Toucans (Audrey Chae, Nick Gorsline, Clayton Snyder)
* Date       : 5/20/2018
* Description: EA Module of the 68k disassembler
*-----------------------------------------------------------

;; ~*~*~*~*~*~*~*~BEGIN EA MODULE~*~*~*~*~*~*~*~

*** A3 -> Null-terminated string to write (load before calling)
*** A4 -> Location in memory to write to
*** Call this function to print the string loaded in A3 to the running
*** human-readable line. Note that this subroutine will not write a null
*** terminator; one must be written at the very end of decoding a full command.
WRITE   * Writes tring pointed to by A3 to memory pointed to by A4
    MOVE.B  (A3)+,(A4)+     * Write one byte and increment
    CMP.B   #0,(A3)         * Check if the null terminator has been reached
    BNE     WRITE           * If not, keep writing!
    RTS

MOVE_EA
    MOVE.L  D5,D6               * D6 will be masked to hold only 3 LSB (register #)
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds register #
    ROR.L   #3,D5               * rotate by 3 bits. mode should now be 3 LSB
    MOVE.L  D5,D2               * D2 will hold the mode
    AND.W   #THREE_LSB_MASK,D2  * D2 now holds mode code

    ** Check D2 (mode) against all possible modes for this op-code pattern
    CMP.W   #0,D2       * Mode: Data register direct
    BEQ     DATA_REG_DIR
    CMP.W   #0,D2       * Check again to branch after subroutine returns
    BEQ     MODE_2

    CMP.W   #2,D2       * Mode: Address register indirect
    BEQ     ADDR_REG_INDIR
    CMP.W   #2,D2       * Check again to branch after subroutine returns
    BEQ     MODE_2

    CMP.W   #3,D2       * Mode: Address register indirect post increment
    BEQ     ADDR_REG_INCR
    CMP.W   #3,D2       * Check again to branch after subroutine returns
    BEQ     MODE_2

    CMP.W   #4,D2       * Mode: Address register indirect pre increment
    BEQ     ADDR_REG_DEC
    CMP.W   #4,D2       * Check again to branch after subroutine returns
    BEQ     MODE_2

    CMP.W   #7,D2       * Mode: Absolute addressing (word or longword)
    BEQ     GET_ABS_LENGTH

    BRA     INVALID_EA

GET_ABS_LENGTH
    CMP.W   #00,D6      * Word absolute address (get the word from memory)
    BEQ     ABS_WORD
    CMP.W   #7,D2
    BEQ     MODE_2      * Skip past BRA INVALID_EA after subroutine returns

    CMP.W   #01,D6      * Longword absolute address (get the long from memory)
    BEQ     ABS_LONG
    CMP.W   #7,D2
    BEQ     MODE_2      * Skip past BRA INVALID_EA after subroutine returns

    BRA     INVALID_EA

MODE_2
    

*** D6 -> Register number to right (i.e., 0-7)
DATA_REG_DIR
    LEA     OPEN_PAREN_D,A3
    JSR     WRITE
    * Get the register number from D6, adding $30 to convert to ASCII
    ADDI.B  #$30,D6
    MOVE.B  D6,(A4)+    * Move the ASCII byte into memory after the opening (
    LEA     CLOSE_PAREN,A3
    JSR     WRITE
    RTS
    
    

ADDR_REG_DIR
    LEA     OPEN_PAREN_A,A3
    JSR     WRITE
    * Get the register number from D6, adding $30 to convert to ASCII
    ADDI.B  #$30,D6
    

ADDR_REG_INDIR
    * WRITE (A
    * WRITE NUMBER IN D6
    * WRITE )

IMM_DATA
    * HOW TO DO THIS?

ADDR_REG_INCR
    * WRITE (A
    * WRITE NUMBER IN D6
    * WRITE )+

ADDR_REG_DECR
    * WRITE -(A
    * WRITE NUMBER IN D6
    * WRITE )

ABS_LONG
    * GET LONG FROM (A6)+
    * WRITE $
    * WRITE DATA GOT FROM A6

ABS_WORD
    * GET WORD FROM (A6)+
    * WRITE $
    * WRITE DATA GOT FROM A6
    
OPEN_PAREN_A    DC.B    '(A',0
OPEN_PAREN_D    DC.B    '(D',0
DECR_OPEN_PAREN DC.B    '-(',0
CLOSE_PAREN     DC.B    ')',0
INC_CLOSE_PAREN DC.B    ')+',0

*** MASKS
THREE_LSB_MASK  EQU     %0000000000000111

;; ~*~*~*~*~*~*~*~END EA MODULE~*~*~*~*~*~*~*~


*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
