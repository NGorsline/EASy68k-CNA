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
    
    * is it NOP?
    CMP.W   #CODE_NOP,D5
    BEQ     DO_NOP       * This will take it on back to the I/O module
    
    * is it RTS?
    CMP.W   #CODE_RTS,D5
    BEQ     DO_RTS       * This will take it on back to the I/O module
    
    RTS * Return to I/O module (temporary; will go to EA module eventually)
    
    
;; ~~~~~~~~CHUNKS FOR WRITING DECODED OPS TO MEMORY~~~~~~~~

;; Typical structure for these chunks:
* 

DO_NOP
    LEA     S_NOP,A3    * Load the NOP string into A3 for WRITE subroutine
    JSR     WRITE       * Jump to WRITE subroutine
    RTS                 * Return to I/O module 
    

DO_RTS
    LEA     S_RTS,A3    * Load the RTS string into A3 for WRITE subroutine
    JSR     WRITE       * Jump to WRITE subroutine
    RTS                 * Return to the I/O module
   
*** A3 -> String to write (load before calling)
*** A1 -> Location in memory to write to 
WRITE   * Writes string pointed to by A3 to memory pointed to by A1
    MOVE.B  (A3)+,(A1)+     * Write one byte and increment
    CMP.B   #0,(A3)         * Are we at the null terminator?
    BNE     WRITE           * If not, keep going
    RTS                     * Executes once null terminator was reached
    
;; ~~~~~~~~STRING CONSTANTS~~~~~~~~

*** ML constants for op-codes without EA modes (NOP, RTS)
CODE_NOP    EQU     $4E71
CODE_RTS    EQU     $4E75

*** Strings for opcodes (write these to memory)
S_NOP   DC.B    'NOP',0
S_RTS   DC.B    'RTS',0


;; ~*~*~*~*~*~*~*~END OPCODE MODULE~*~*~*~*~*~*~*~
*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
