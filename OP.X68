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
    BEQ     DO_NOP       * This will take it on back to the I/O module
    
    * is it RTS?
    CMP.W   #CODE_RTS,D5
    BEQ     DO_RTS       * This will take it on back to the I/O module
    
    
    ** Not NOP or RTS, check bit-by-bit to narrow down
    
    BTST.L  #15,D5       * Test the most significant bit of the command
    BEQ     OXXX_BRA     * Branch to opcodes starting with zero     
    * BRA     IXXX_BRA     * Branch to opcodes starting with a one  ******** COME BAK
   
    BRA     DO_NOP
    RTS * Return to I/O module (temporary; will go to EA module eventually)
    
    
;; ~~~~~~~~BRANCHES FOR NARROWING OPCODE SELECTION~~~~~~~~
OXXX_BRA
    BTST.L  #14,D5      * Test the second bit 
    BEQ     OOXX_BRA    * Branch to opcodes starting with 00
    * BRA     OIXX_BRA    * Branch to opcodes starting with 01   *** COME BAK

OOXX_BRA
    BTST.L  #13,D5      * Test the second bit 
    BEQ     OOOX_BRA    * Branch to opcodes starting with 000
    * BRA     OIIX_BRA    * Branch to opcodes starting with 011   *** COME BAK
    
OOOX_BRA
    BTST.L  #12,D5      * Test the second bit 
    BEQ     OOOO_BRA    * Decision for SUBI or ADDI
    * BRA     OIII_BRA    * Branch to opcodes starting with 01   *** COME BAK

OOOO_BRA                * tests for ADDI or SUBI
*COME BAKKKKKKKPLZ

OIXX_BRA
    BTST.L  #13,D5
    BEQ     OIOX_BRA    * CLR, JSR, MOVEM, LEA, ADDQ, SUBQ
    
OIOX_BRA
    BTST.L  #12,D5
    BEQ     OIOO_BRA    * CLR, JSR, MOVEM, LEA
    
OIOO_BRA
    ** Test for JSR
    MOVE.W  #JSR_MASK,D2 * Load mask temporarily into register for ANDing
    AND.W   D5,D2        * AND with the current opcode data
    CMP.W   #$0E80,D2    * Result of mask should be 0E80 if code is JSR
    BEQ     DO_JSR       * 
    *WHAT ELSE CAN THIS BE? TBD 
    
;; Typical structure for these chunks:
* 

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
S_NOP   DC.B    'NOP',0
S_RTS   DC.B    'RTS',0
S_MOVE  DC.B    'MOVE',0
S_JSR   DC.B    'JSR',0

*** Mask constants 
JSR_MASK    EQU     %0000111010000000
;; ~*~*~*~*~*~*~*~END OPCODE MODULE~*~*~*~*~*~*~*~


*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
