*-----------------------------------------------------------
* Title      : Opcode module
* Written by : Clayton Snyder of Toucans
* Date       : Created 5/16/2018
* Description: One half of disassembly logic for a Motorola 68k disassembler.
*              Reads the word at address A6 and identifies the opcode. Writes
*              a string representing the opcode to the memory pointed to by A1
*              then calls the EA decoding module. 
*-----------------------------------------------------------

;; ~*~*~*~*~*~*~*~BEGIN OPCODE MODULE~*~*~*~*~*~*~*~

OP_DECODE
    MOVE.W  (A6)+,D5     * Load the next opcode to decode into D5, incrementing
    * NOTE: A6 now points at either the next opcode or imm. data for EA part
    
    * is it NOP?
    CMP.W   #CODE_NOP,D5
    BEQ     DO_NOP      * After execution of this branch, will return to I/O
    
    * is it RTS?
    CMP.W   #CODE_RTS,D5
    BEQ     DO_RTS      * After execution of this branch, will return to I/O
    
    ** Not NOP or RTS, check bit-by-bit to narrow down
    
    BTST.L  #15,D5       * Test the most significant bit of the command
    BEQ     OXXX_BRA     * Branch to opcodes starting with zero     
    BRA     IXXX_BRA     * Branch to opcodes starting with a one  ******** COME BAK
   
    BRA     DO_NOP
    RTS * Return to I/O module (temporary; will go to EA module eventually)
    
* ----------------------BEGIN NARROWING THE LEFT BRANCH OF THE OPCODE SELECTIONS ----------
OXXX_BRA
    BTST.L  #14,D5      * Test the second bit 
    BEQ     OOXX_BRA    * Branch to opcodes starting with 00
    BRA     OIXX_BRA    * Branch to opcodes starting with 01   *** COME BAK

OOXX_BRA
    BTST.L  #13,D5          * Test the second bit 
    BEQ     OOOX_BRA        * Branch to opcodes starting with 000
    BRA     OOIX_BRA        * Might be MOVE, MOVEA
    BRA     PRINT_INVALID_MSG
OIXX_BRA
    BTST.L  #13,D5
    BEQ     OIOX_BRA    * CLR, JSR, MOVEM, LEA, ADDQ, SUBQ
    BRA     OIIX_BRA    * BCC, OR MOVEQ
OOOX_BRA
    BTST.L  #12,D5              * Test the second bit 
    BEQ     OOOO_BRA            * Decision for SUBI or ADDI
    BRA     PRINT_COME_BACK_MSG * might be MOVE, MOVEA, 
OOIX_BRA
    * BTST.L  #12,D5              * Test the second bit 
    * BEQ     OOOO_BRA            * Decision for MOVE OR MOVEA
    BRA     PRINT_COME_BACK_MSG * might be MOVE, MOVEA, 
OOOO_BRA                        * tests for ADDI or SUBI
    MOVE.W  #ADDSUBI_MASK,D2   * Load mask for ADDI temporarily into register for AND operation
    AND.W   D5,D2               * AND with current opcode data and store into D2
    CMP.W   #$0600,D2           * Result of mask should be 0060 if the code is ADDi
    BEQ     DO_ADDI     
    CMP.W   #$0400,D2           * SUBI and ADDI  have the same bitmask.
    BEQ     DO_SUBI
    BRA     PRINT_INVALID_MSG
OIOX_BRA
    BTST.L  #12,D5
    BEQ     OIOO_BRA    * CLR, JSR, MOVEM, LEA   
    BRA     DO_ADDQ    * ADDQ 
OIIX_BRA
    *check for MOVEQ and BCC here, which is 0110 always. there is no 0111
    BTST.L  #12,D5
    BEQ     OIIO_BRA            * BCC and MOVEQ happens here
    BRA     PRINT_INVALID_MSG   * There is no 0111
OIOO_BRA
    ** Test for JSR
    MOVE.W  #JSR_MASK,D2 * Load mask temporarily into register for ANDing
    AND.W   D5,D2        * AND with the current opcode data
    CMP.W   #$0E80,D2    * Result of mask should be 0E80 if code is JSR
    BEQ     DO_JSR       *

    MOVE.W  #CLR_MASK,D2
    AND.W   D5,D2
    CMP.W   #$0200,D2              * IS IT CLR?
    BEQ     DO_CLR

    MOVE.W  #LEA_MASK,D2
    AND     D5,D2
    CMP.W   #$01C0,D2              *EQUAL TO LEA?
    BEQ.W   DO_LEA
    BRA     PRINT_OIOO_ERROR       * if not RTS, not JSR, CLR, or LEA, then its invalid. 

OIIO_BRA
    BRA     PRINT_COME_BACK_MSG   * Need halp 

*------------------------------- END OF LEFT TREE - STARTING RIGHT TREE ----------------
IXXX_BRA
    BRA     PRINT_COME_BACK_MSG   * temporary until further development of right branch 

;; Typical structure for these chunks:
*
DO_ADDI
    LEA     S_ADDI,A3
    MOVE.B  #8,D7
    ** Eventually, EA Module will be called here
    JSR     WRITE
    RTS
DO_SUBI
    LEA     S_SUBI,A3
    MOVE.B  #11,D7
    ** Eventually, EA Module will be called here
    JSR     WRITE
    RTS
DO_ADDQ
    *Check for full opcode for 11 and onwards. if invalid, print the message
    LEA     S_ADDQ,A3
    MOVE.B  #9,D7
    ** Eventually, EA Module will be called here
    JSR     WRITE
    RTS
DO_CLR
    LEA     S_CLR,A3
    MOVE.B  #16,D7
    ** Eventually, EA Module will be called here
    JSR     WRITE
    RTS
DO_LEA
    LEA     S_LEA,A3    * Load the NOP string into A3 for WRITE subroutine
    MOVE.B  #15,D7       * Store key for op code for EA module
    ** Eventually, EA Module will be called here
    JSR     WRITE       * Jump to WRITE subroutine
    RTS                 * Return to I/O module 
DO_NOP
    LEA     S_NOP,A3    * Load the NOP string into A3 for WRITE subroutine
    MOVE.B  #1,D7       * Store key for op code for EA module
    ** Eventually, EA Module will be called here
    JSR     WRITE       * Jump to WRITE subroutine
    RTS                 * Return to I/O module 
DO_RTS
    LEA     S_RTS,A3    * Load the RTS string into A3 for WRITE subroutine
    MOVE.B  #28,D7      * Store key for op code for EA module
    ** Eventually, EA Module will be called here
    JSR     WRITE       * Jump to WRITE subroutine
    RTS                 * Return to the I/O module bra op_decode  
DO_MOVE
    LEA     S_MOVE,A3
    MOVE.B  #2,D7
    ** Eventually, EA Module will be called here
    JSR     WRITE
    RTS
    
DO_JSR
    LEA     S_JSR,A3
    MOVE.B  #27,D7
    ** Eventually, NOCK will be called here
    JSR     WRITE
    RTS
PRINT_INVALID_MSG
    LEA     INVALID,A3
    MOVE.B  #0,D7
    ** Eventually, NOCK will be called here
    JSR     WRITE
    RTS
PRINT_OIOO_ERROR
    LEA     BAD_OIOO,A3
    MOVE.B  #0,D7
    ** Eventually, NOCK will be called here
    JSR     WRITE
    RTS
PRINT_COME_BACK_MSG
    LEA     COMEBK,A3
    MOVE.B  #0,D7
    ** Eventually, NOCK will be called here
    JSR     WRITE
    RTS
*** A3 -> String to write (load before calling)
*** A4 -> Location in memory to write to 
WRITE   * Writes string pointed to by A3 to memory pointed to by A1
    MOVEA.L A4,A1     * Save the position of A1 before writing (for I/0)
WRITE_LOOP
    MOVE.B  (A3)+,(A4)+     * Write one byte and increment
    CMP.B   #0,(A3)         * Are we at the null terminator?
    BNE     WRITE_LOOP      * If not, keep going
    MOVE.B  (A3)+,(A4)+     * Write the null terminator before exiting
    RTS                     * Executes once null terminator was reached
    
;; ~~~~~~~~STRING CONSTANTS~~~~~~~~

*** ML constants for op-codes without EA modes (NOP, RTS)
CODE_NOP    EQU     $4E71
CODE_RTS    EQU     $4E75

*** Variable used to store the previous value of A1 before writing
A4_PREV     SET     $2000

*** Strings for opcodes (write these to memory)
S_NOP       DC.B    'NOP',0
S_RTS       DC.B    'RTS',0
S_MOVE      DC.B    'MOVE',0
S_JSR       DC.B    'JSR',0
S_ADDQ      DC.B    'ADDQ',0
S_ADDI      DC.B    'ADDI',0
S_SUBI      DC.B    'SUBI',0
S_CLR       DC.B    'CLR',0
S_LEA       DC.B    'LEA',0    
INVALID     DC.B    'INVALID OPCODE. LETS FIX THIS MESSAGE LATER',0
COMEBK      DC.B    'Come back to me pls dont forget me',0 
BAD_OIOO    DC.B    'Bad OIOO maybe not JSR,RTS,CLR,LEA.. who knows.',0

*** Mask constants 
JSR_MASK        EQU     %0000111111000000
ADDSUBI_MASK    EQU     %0000111100000000       ** come back and fix this to be the same but diferent comparisons 
BYTE_MASK       EQU     %0000000000000000
WORD_MASK       EQU     %0000000001000000
LONG_MASK       EQU     %0000000010000000  
CLR_MASK        EQU     %0000111100000000
LEA_MASK        EQU     %0000000111000000
;; ~*~*~*~*~*~*~*~END OPCODE MODULE~*~*~*~*~*~*~*~


*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
