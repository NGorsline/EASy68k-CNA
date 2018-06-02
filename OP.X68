*------------------------------------------------------------------------------|
* Title      : Opcode module                                                   |
* Written by : Audrey Chae, Clayton Snyder, Nicholas Gorsline (Team Toucans)   |
* Creted     : 5/16/2018                                                       |
* Description: One half of disassembly logic for a Motorola 68k disassembler.  |
*              Reads the word at address A6 and identifies the opcode. Writes  |
*              a string representing the opcode to the memory pointed to by A4 |
*              then calls the appropriate subroutine from the EA module to     |
*              the effective addressing modes for the op-code.                 |
*------------------------------------------------------------------------------|

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
    
* ----------------------BEGINNING OF LEFT BRANCH OF OPCODE SELECTIONS -----------------
OXXX_BRA
    BTST.L  #14,D5              * Test the second bit 
    BEQ     OOXX_BRA            * Branch to opcodes starting with 00
    BRA     OIXX_BRA            * Branch to opcodes starting with 01   *** COME BAK

OOXX_BRA
    BTST.L  #13 ,D5              * Test the third bit 
    BEQ     OOOX_BRA            * Branch to opcodes starting with 000
    BRA     OOIX_BRA            * Might be MOVE, MOVEA
    BRA     PRINT_INVALID_MSG
OIXX_BRA
    BTST.L  #13,D5
    BEQ     OIOX_BRA            * CLR, JSR, MOVEM, LEA, ADDQ, SUBQ
    BRA     OIIX_BRA            * BCC, OR MOVEQ
    BRA     PRINT_INVALID_MSG
OOOX_BRA
    BTST.L  #12,D5              * Test the fourth bit 
    BEQ     OOOO_BRA            * Decision for SUBI or ADDI
    BRA     OOOI_BRA            * MOVE and MOVEA (B)
    BRA     PRINT_INVALID_MSG
OOIX_BRA
    BTST.L  #12,D5              * Test the fourth bit 
    BEQ     OOIO_BRA            * MOVE or MOVEA need to be handled here (W)
    BRA     OOII_BRA            * MOVE or MOVEA need to be handled here (L)
    BRA     PRINT_INVALID_MSG
OOOO_BRA                        * tests for ADDI or SUBI
    MOVE.W  #ADDSUBI_MASK,D2   * Load mask for ADDI temporarily into register for AND operation
    AND.W   D5,D2               * AND with current opcode data and store into D2
    CMP.W   #$0600,D2           * Result of mask should be 0060 if the code is ADDi
    BEQ     DO_ADDI     
    CMP.W   #$0400,D2           * SUBI and ADDI  have the same bitmask.
    BEQ     DO_SUBI
    BRA     PRINT_INVALID_MSG
OOOI_BRA                        * MOVE and MOVEA need to be handled here (B)
    MOVE.W  #MOVE_MASK,D2
    AND.W   D5,D2
    CMP.W   #$1000,D2           * is it a byte?
    BEQ     DO_MOVE_B  

    BRA     PRINT_INVALID_MSG   *neither MoveA or Move? BADDDD
OOIO_BRA                        * MOVE and MOVEA need to be handled here (W)
    MOVE.W  #MOVEA_MASK,D2
    AND.W   D5,D2
    CMP.W   #$2040,D2           * is it a moveA long?
    BEQ     DO_MOVEA_L          

    MOVE.W  #MOVE_MASK,D2
    AND.W   D5,D2
    CMP.W   #$2000,D2           * is it a long word?
    BEQ     DO_MOVE_L           

    BRA     PRINT_INVALID_MSG
OOII_BRA                        * MOVE and MOVEA need to be handled here (L)
    MOVE.W  #MOVEA_MASK,D2
    AND.W   D5,D2
    CMP.W   #$3040,D2           * is it a moveA word?
    BEQ     DO_MOVEA_W          

    MOVE.W  #MOVE_MASK,D2
    AND.W   D5,D2
    CMP.W   #$3000,D2           * is it a move word?
    BEQ     DO_MOVE_W           

    BRA     PRINT_INVALID_MSG
OIOX_BRA
    BTST.L  #12,D5
    BEQ     OIOO_BRA    * CLR, JSR, MOVEM, LEA   
    BRA     OIOI_BRA     * ADDQ
OIIX_BRA
    *check for MOVEQ and BCC here, which is 0110 always. there is no 0111
    BTST.L  #12,D5
    BEQ     DO_BCC_CASE            * BCC happens here, have to narrow it down to which one!
    BRA     DO_MOVEQ   
OIOO_BRA
    ** Test for JSR
    MOVE.W  #JSR_MASK,D2 * Load mask temporarily into register for ANDing
    AND.W   D5,D2        * AND with the current opcode data
    CMP.W   #$0E80,D2    * Result of mask should be 0E80 if code is JSR
    BEQ     DO_JSR       *

    MOVE.W  #LEA_MASK,D2
    AND     D5,D2
    CMP.W   #$01C0,D2              *EQUAL TO LEA?
    BEQ     DO_LEA

    MOVE.W  #CLR_MASK,D2
    AND.W   D5,D2
    CMP.W   #$0200,D2              * IS IT CLR.B?
    BEQ     DO_CLR_B
    CMP.W   #$0240,D2              * IS IT CLR.W?
    BEQ     DO_CLR_W
    CMP.W   #$0280,D2              * IS IT CLR.L?
    BEQ     DO_CLR_L

    MOVE.W  #MOVEM_MASK,D2
    AND.W   D5,D2
    CMP.W   #$0880,D2               * Is it MOVEM.W?
    BEQ     DO_MOVEM_W

    CMP.W   #$08C0,D2               * Is it MOVEM.L?
    BEQ     DO_MOVEM_L

    BRA     PRINT_OIOO_ERROR       * if not RTS, not JSR, CLR, or LEA, then its invalid. 
OIOI_BRA
    MOVE.W  #ADDQ_MASK,D2
    AND.W   D5,D2
    CMP.W   #$0000,D2               * IS IT ADDQ.B?
    BEQ     DO_ADDQ_B

    CMP.W   #$0040,D2               * IS IT ADDQ.W?
    BEQ     DO_ADDQ_W

    CMP.W   #$0080,D2               * IS IT ADDQ.L?
    BEQ     DO_ADDQ_L

    BRA     PRINT_INVALID_MSG
*------------------------------- END OF LEFT TREE ----------------------------------------
***************************************************************************************
* ----------------------BEGINNING OF RIGHT BRANCH OF OPCODE SELECTIONS -------------------
IXXX_BRA 
    BTST.L  #14,D5              * Test the second bit 
    BEQ     IOXX_BRA            * Branch to opcodes starting with 10
    BRA     IIXX_BRA            * Branch to opcodes starting with 11
IOXX_BRA
    BTST.L  #13,D5              * Test the third bit 
    BEQ     IOOX_BRA            * Might be SUB or DIVU
    BRA     IOIX_BRA            * Might be CMP
    BRA     PRINT_INVALID_MSG
IIXX_BRA
    BTST.L  #13,D5              * Test the third bit 
    BEQ     IIOX_BRA            * might be ADD, ADDA, MULS, MULU, AND
    BRA     IIIX_BRA            
    BRA     PRINT_INVALID_MSG 
IOOX_BRA
    BTST.L  #12,D5              * Test the fourth bit 
    BEQ     IOOO_BRA            * Might be DIVU, OR 
    BRA     IOOI_BRA            * DO SUB!
    BRA     PRINT_INVALID_MSG
IOIX_BRA
    BTST.L  #12,D5              * Test the fourth bit 
    BNE     IOII_BRA            * check if it's CMP
    BRA     PRINT_INVALID_MSG   * reached the end, there is no IOIO module
IIOX_BRA
    BTST.L  #12,D5              * Test the fourth bit 
    BEQ     IIOO_BRA            * might be AND, MULU, MULS,
    BRA     IIOI_BRA            * might be ADD, ADDA, 
    BRA     PRINT_INVALID_MSG 
IIIX_BRA
    BTST.L  #12,D5              * Test the fourth bit   
    BEQ     IIIO_BRA            * might be LSR, LSL, ASR, ASL, ROL, ROR
    BRA     PRINT_INVALID_MSG   * there exists no IIII module 
IOOO_BRA                        * Logic for OR, DIVU 
    MOVE.W  #DIVU_MASK,D2
    AND.W   D5,D2
    CMP.W   #$00C0,D2           * DIVU can only be 011 in positions 8-6
    BEQ     DO_DIVU_W
    *if not DIVU, try to check if it's any form of OR
    
    CMP.W   #$0000,D2           * Is it a byte operation for <ea> V Dn --> Dn?
    BEQ     DO_OR_B
    CMP.W   #$0100,D2           * Is it a byte operation for Dn V <ea> --> <ea>
    BEQ     DO_OR_B
    CMP.W   #$0040,D2           * Is it a word operation for <ea> V Dn --> Dn?
    BEQ     DO_OR_W
    CMP.W   #$0140,D2           * Is it a word operation for Dn V <ea> --> <ea>
    BEQ     DO_OR_W
    CMP.W   #$0080,D2           * Is it a long word operation for <ea> V Dn --> Dn?
    BEQ     DO_OR_L
    CMP.W   #$0180,D2           * Is it a long word operation for Dn V <ea> --> <ea>
    BEQ     DO_OR_L

    BRA     PRINT_INVALID_MSG   * none of these apply, then invalid op code 

IOOI_BRA                        * Logic for SUB
    MOVE.W   #SUB_MASK,D2
    AND.W    D5,D2
    CMP.W    #$0000,D2          * is it SUB.B for Dn-<ea> --> Dn? 
    BEQ      DO_SUB_B
    CMP.W    #$0100,D2          * is it SUB.B for <ea> - Dn --> <ea> ? 
    BEQ      DO_SUB_B

    CMP.W   #$0040,D2           * is it SUB.W Dn-<ea> --> Dn? 
    BEQ      DO_SUB_W
    CMP.W   #$0140,D2           * is it SUB.W for <ea> - Dn --> <ea> ? 
    BEQ      DO_SUB_W

    CMP.W   #$0080,D2           * is it SUB.L Dn-<ea> --> Dn? 
    BEQ      DO_SUB_L
    CMP.W   #$0180,D2           * is it SUB.L for <ea> - Dn --> <ea> ? 
    BEQ      DO_SUB_L

    BRA     PRINT_INVALID_MSG   * none of these apply, then invalid op code 

IOII_BRA                        * Logic for CMP
    MOVE.W  #CMP_MASK,D2        * Temporarily load mask into D2
    AND.W   D5,D2
    CMP.W   #$B000,D2           * Check if it's CMP.B
    BEQ     DO_CMP_B           

    CMP.W   D5,D2
    CMP.W   #$B040,D2           * Check if it's CMP.W
    BEQ     DO_CMP_W

    CMP.W   D5,D2
    CMP.W   #$B080,D2           * Check if it's CMP.L
    BEQ     DO_CMP_L

    BRA     PRINT_INVALID_MSG   * No other opcodes for IOII 

IIOO_BRA                        * Logic for AND,MULS, MULU
    MOVE.W  #AND_MM_MASK,D2
    AND.W   D5,D2
    CMP.W   #$01C0,D2           * Is it MULS.W?
    BEQ     DO_MULS_W

    CMP.W   #$00C0,D2          * Is it MULU.W?
    BEQ     DO_MULU_W

    CMP.W   #$0000,D2           * Is it AND.B for <ea> ^ Dn --> Dn?
    BEQ     DO_AND_B
    CMP.W   #$0100,D2           * Is it AND.B for Dn ^ <ea> --> <ea>?
    BEQ     DO_AND_B

    CMP.W   #$0040,D2           * Is it AND.W for <ea> ^ Dn --> Dn?
    BEQ     DO_AND_W
    CMP.W   #$0140,D2           * Is it AND.W for Dn ^ <ea> --> <ea>?
    BEQ     DO_AND_W

    CMP.W   #$0080,D2           * Is it AND.L for <ea> ^ Dn --> Dn?
    BEQ     DO_AND_L
    CMP.W   #$0180,D2           * Is it AND.L for Dn ^ <ea> --> <ea>?
    BEQ     DO_AND_L
    BRA     PRINT_INVALID_MSG   * No other opcodes for IOII 
IIOI_BRA                        * Logic for ADDA, ADD, 
    MOVE.W  #ADD_MASK,D2
    AND.W   D5,D2
    CMP.W   #$00C0,D2           * first check if it's ADDA.W
    BEQ     DO_ADDA_W

    CMP.W   #$01C0,D2           * first check if it's ADDA.L
    BEQ     DO_ADDA_L
    * Not ADDA? check for all cases of ADD
    CMP.W   #$0000,D2           * Is it ADD.B for <ea> + Dn --> Dn ?
    BEQ     DO_ADD_B
    CMP.W   #$0100,D2           * Is it ADD.B for Dn + <ea> --> <ea> ? 
    BEQ     DO_ADD_B

    CMP.W   #$0040,D2           * Is it ADD.W for <ea> + Dn --> Dn ?
    BEQ     DO_ADD_W
    CMP.W   #$0140,D2           * Is it ADD.W for Dn + <ea> --> <ea> ? 
    BEQ     DO_ADD_W

    CMP.W   #$0080,D2           * Is it ADD.L for <ea> + Dn --> Dn ?
    BEQ     DO_ADD_L
    CMP.W   #$0180,D2           * Is it ADD.L for Dn + <ea> --> <ea> ? 
    BEQ     DO_ADD_L

    BRA     PRINT_INVALID_MSG   * none of these apply, then invalid op code 
IIIO_BRA                        * Logic for LSd, RSd, ROd,ASd
    MOVE.W  #R_MODE_MASK,D2     * Initial rotation to differentiate between LSd, ROd, and ASd
    AND.W   D5,D2
    CMP.W   #$0008,D2           * Is it LSd? (M = 01)
    BEQ     DO_LSd

    CMP.W   #$0018,D2           * Is it ROd? (M = 11)
    BEQ     DO_ROd

    CMP.W   #$0000,D2           * Is it ASd? (M = 00)
    BEQ     DO_ASd

    BRA     PRINT_INVALID_MSG   * none of these apply, then invalid op code 
*------------------------------- END OF LEFT TREE ----------------------------------------
***************************************************************************************
*-------------------------------- SUB-ROUTINE SECTION ------------------------------------
DO_LSd
    MOVE.W  #ROTATION_MASK,D2   * Now need to find size and direction
    AND.W   D5,D2
    *-- Starting left checks --*
    CMP.W   #$0100,D2           * LSL.B 
    BEQ     DO_LSL_B

    CMP.W   #$0140,D2           * LSL.W 
    BEQ     DO_LSL_W

    CMP.W   #$0180,D2           * LSL.L
    BEQ     DO_LSL_L

    *-- Starting right checks --*
    CMP.W   #$0000,D2           * LSR.B 
    BEQ     DO_LSR_B

    CMP.W   #$0040,D2           * LSR.W 
    BEQ     DO_LSR_W

    CMP.W   #$0080,D2           * LSR.L
    BEQ     DO_LSR_L

    BRA     PRINT_INVALID_MSG   * none of these apply, then invalid op code 
DO_ROd
    MOVE.W  #ROTATION_MASK,D2   * Now need to find size and direction
    AND.W   D5,D2
    *-- Starting left checks --*
    CMP.W   #$0100,D2           * ROL.B 
    BEQ     DO_ROL_B

    CMP.W   #$0140,D2           * ROL.W 
    BEQ     DO_ROL_W

    CMP.W   #$0180,D2           * ROL.L
    BEQ     DO_ROL_L

    *-- Starting right checks --*
    CMP.W   #$0000,D2           * ROR.B 
    BEQ     DO_ROR_B

    CMP.W   #$0040,D2           * ROR.W 
    BEQ     DO_ROR_W

    CMP.W   #$0080,D2           * ROR.L
    BEQ     DO_ROR_L

    BRA     PRINT_INVALID_MSG   * none of these apply, then invalid op code 
DO_ASd
    MOVE.W  #ROTATION_MASK,D2   * Now need to find size and direction
    AND.W   D5,D2
    *-- Starting left checks --*
    CMP.W   #$0100,D2           * ASL.B 
    BEQ     DO_ASL_B

    CMP.W   #$0140,D2           * ASL.W 
    BEQ     DO_ASL_W

    CMP.W   #$0180,D2           * ASL.L
    BEQ     DO_ASL_L

    *-- Starting right checks --*
    CMP.W   #$0000,D2           * ASR.B 
    BEQ     DO_ASR_B

    CMP.W   #$0040,D2           * ASR.W 
    BEQ     DO_ASR_W

    CMP.W   #$0080,D2           * ASR.L
    BEQ     DO_ASR_L

    BRA     PRINT_INVALID_MSG   * none of these apply, then invalid op code 
DO_NOP
    LEA     S_NOP,A3    * Load the NOP string into A3 for WRITE subroutine
    JSR     WRITE       * Jump to WRITE subroutine
    *** No EA call for NOP
    RTS                 * Return to I/O module 
DO_MOVE_B
    LEA     S_MOVE_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA
    JSR     WRITE
    JSR     MOVE_EA
    RTS
DO_MOVE_W
    LEA     S_MOVE_W,A3   
    MOVE.B  #01,D7          * passing size code WORD to EA    
    JSR     WRITE
    JSR     MOVE_EA
    RTS
DO_MOVE_L
    LEA     S_MOVE_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA    
    JSR     WRITE
    JSR     MOVE_EA
    RTS
DO_MOVEA_W
    LEA     S_MOVEA_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     MOVE_EA
    RTS
DO_MOVEA_L
    LEA     S_MOVEA_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     MOVE_EA
    RTS
DO_MOVEQ
    LEA     S_MOVEQ,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     MOVEQ_EA
    RTS
DO_BCC_CASE
    MOVE.W  #Bcc_MASK,D2
    AND     D5,D2
    CMP.W   #$0E00,D2                * Is it BGT?
    BEQ     DO_BGT_SIZE
    
    CMP.W   #$0F00,D2                * Is it BLE?
    BEQ     DO_BLE_SIZE

    CMP.W   #$0400,D2                * Is it BCC?
    BEQ     DO_BCC_SIZE

    BRA     PRINT_INVALID_MSG        * none of these options? not required or invalid
DO_MOVEM_W
    LEA     S_MOVEM_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    RTS
DO_MOVEM_L
    LEA     S_MOVEM_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    RTS
DO_ADD_B
    LEA     S_ADD_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_ADD_W
    LEA     S_ADD_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_ADD_L
    LEA     S_ADD_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_ADDA_W
    LEA     S_ADDA_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     ADDA_LEA_EA
    RTS
DO_ADDA_L
    LEA     S_ADDA_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADDA_LEA_EA
    RTS
DO_ADDI
    MOVE.W  #ADDSUBI_S_MASK,D2
    AND.W   D5,D2
    CMP.W   #$0000,D2       *is it ADDI.B?
    BEQ     DO_ADDI_B

    CMP.W   #$0040,D2       *is it ADDI.W?
    BEQ     DO_ADDI_W

    CMP.W   #$0080,D2       *is it ADDI.L?
    BEQ     DO_ADDI_L

    BRA     PRINT_INVALID_MSG
DO_ADDI_B
    LEA     S_ADDI_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA
    JSR     WRITE
    JSR     ADDI_SUBI_EA
    RTS
DO_ADDI_W
    LEA     S_ADDI_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     ADDI_SUBI_EA
    RTS
DO_ADDI_L
    LEA     S_ADDI_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADDI_SUBI_EA
    RTS
DO_ADDQ_B
    LEA     S_ADDQ_B,A3
     MOVE.B  #00,D7          * passing size code BYTE to EA
    JSR     WRITE
    JSR     ADDQ_EA
    RTS
DO_ADDQ_W
    LEA     S_ADDQ_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     ADDQ_EA
    RTS
DO_ADDQ_L
    LEA     S_ADDQ_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADDQ_EA
    RTS
DO_SUB_B
    LEA     S_SUB_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_SUB_W
    LEA     S_SUB_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_SUB_L
    LEA     S_SUB_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_SUBI
    MOVE.W  #ADDSUBI_S_MASK,D2
    AND.W   D5,D2
    CMP.W   #$0000,D2       *is it SUBI.B?
    BEQ     DO_SUBI_B

    CMP.W   #$0040,D2       *is it SUBI.W?
    BEQ     DO_SUBI_W

    CMP.W   #$0080,D2       *is it SUBI.L?
    BEQ     DO_SUBI_L

    BRA     PRINT_INVALID_MSG
DO_SUBI_B
    LEA     S_SUBI_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    JSR     ADDI_SUBI_EA
    RTS
DO_SUBI_W
    LEA     S_SUBI_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     ADDI_SUBI_EA
    RTS
DO_SUBI_L
    LEA     S_SUBI_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADDI_SUBI_EA
    RTS
DO_MULS_W
    LEA     S_MULS_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     DR_ARITH_EA
    RTS   
DO_MULU_W
    LEA     S_MULU_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     DR_ARITH_EA
    RTS   
DO_DIVU_W
    LEA     S_DIVU,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     DR_ARITH_EA
    RTS
DO_LEA
    LEA     S_LEA,A3    * Load the NOP string into A3 for WRITE subroutine
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADDA_LEA_EA
    RTS
DO_CLR_B
    LEA     S_CLR_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    JSR     CLR_EA
    RTS
DO_CLR_W
    LEA     S_CLR_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     CLR_EA
    RTS
DO_CLR_L
    LEA     S_CLR_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     CLR_EA
    RTS
DO_AND_B
    LEA     S_AND_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_AND_W
    LEA     S_AND_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_AND_L
    LEA     S_AND_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_OR_B
    LEA     S_OR_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_OR_W
    LEA     S_OR_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA      
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_OR_L
    LEA     S_OR_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS

DO_LSL_B
    LEA     S_LSL_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_LSL_W
    LEA     S_LSL_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_LSL_L
    LEA     S_LSL_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_LSR_B
    LEA     S_LSR_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_LSR_W
    LEA     S_LSR_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_LSR_L
    LEA     S_LSR_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_ASR_B
    LEA     S_ASR_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    RTS
DO_ASR_W
    LEA     S_ASR_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA
    JSR     WRITE
    RTS
DO_ASR_L
    LEA     S_ASR_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    RTS
DO_ASL_B
    LEA     S_ASL_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    RTS
DO_ASL_W
    LEA     S_ASL_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA
    JSR     WRITE
    RTS
DO_ASL_L
    LEA     S_ASL_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    RTS
DO_ROL_B
    LEA     S_ROL_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_ROL_W
    LEA     S_ROL_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_ROL_L
    LEA     S_ROL_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_ROR_B
    LEA     S_ROR_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA    
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_ROR_W
    LEA     S_ROR_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_ROR_L
    LEA     S_ROR_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     LSD_EA
    RTS
DO_CMP_B
    LEA     S_CMP_B,A3
    MOVE.B  #00,D7          * passing size code BYTE to EA
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_CMP_W
    LEA     S_CMP_W,A3
    MOVE.B  #01,D7          * passing size code WORD to EA
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_CMP_L
    LEA     S_CMP_L,A3
    MOVE.B  #10,D7          * passing size code LONG to EA 
    JSR     WRITE
    JSR     ADD_SUB_AND_OR_CMP_EA
    RTS
DO_BGT_SIZE
    TST.B   D5              * test a byte from D5, the displacement bits of the Branch
    BEQ.S   DO_BGT_W        * if the displacement byte = 0, then it's a word
    LEA     S_BGT_B,A3      * if not a word, it's a byte size
    MOVE.B  #00,D7
    JSR     WRITE
    ** EA Module will be called now
    RTS
DO_BGT_W
    LEA     S_BGT_W,A3
    MOVE.B  #01,D7
    JSR     WRITE
    ** EA Module will be called now
    RTS
DO_BLE_SIZE
    TST.B   D5              * test a byte from D5, the displacement bits of the Branch
    BEQ.S   DO_BLE_W        * if the displacement byte = 0, then it's a word
    LEA     S_BLE_B,A3      * if not a word, it's a byte size
    MOVE.B  #00,D7
    JSR     WRITE
    ** EA Module will be called now
    RTS
DO_BLE_W
    LEA     S_BLE_W,A3
    MOVE.B  #01,D7
    JSR     WRITE
    ** EA Module will be called now
    RTS
DO_BCC_SIZE
    TST.B   D5              * test a byte from D5, the displacement bits of the Branch
    BEQ.S   DO_BCC_W        * if the displacement byte = 0, then it's a word
    LEA     S_BCC_B,A3      * if not a word, it's a byte size
    MOVE.B  #00,D7
    JSR     WRITE
    ** EA Module will be called now
    RTS
DO_BCC_W
    LEA     S_BCC_W,A3
    MOVE.B  #01,D7
    JSR     WRITE
    ** EA Module will be called now
    RTS
DO_JSR 
    LEA     S_JSR,A3
    JSR     WRITE
    ** EA Module will be called now
    RTS
DO_RTS
    LEA     S_RTS,A3    * Load the RTS string into A3 for WRITE subroutine
    JSR     WRITE
    RTS
PRINT_INVALID_MSG
    LEA     INVALID,A3
    MOVE.B  #0,D7
    JSR     WRITE
     ** EA Module will be called now
    RTS
PRINT_OIOO_ERROR
    LEA     BAD_OIOO,A3
    MOVE.B  #0,D7
    JSR     WRITE
    ** EA Module will be called now
    RTS
PRINT_COME_BACK_MSG
    LEA     COMEBK,A3
    MOVE.B  #0,D7
    JSR     WRITE
     ** EA Module will be called now
    RTS
*** A3 -> String to write (load before calling)
*** A4 -> Location in memory to write to 
WRITE   * Writes string pointed to by A3 to memory pointed to by A1
    *MOVEA.L A4,A1     * Save the position of A4 before writing (for I/0)
WRITE_LOOP
    MOVE.B  (A3)+,(A4)+     * Write one byte and increment
    CMP.B   #0,(A3)         * Are we at the null terminator?
    BNE     WRITE_LOOP      * If not, keep going
    *MOVE.B  #$2C,(A4)+     * Write the null terminator before exiting
    RTS                     * Executes once null terminator was reached
    
*------------------------------- END OF SUB-ROUTINE SECTION ----------------------------------------
***************************************************************************************
*-------------------------------- STRING CONSTANTS SECTION ------------------------------------

*** ML constants for op-codes without EA modes (NOP, RTS)
CODE_NOP    EQU     $4E71
CODE_RTS    EQU     $4E75

*** Variable used to store the previous value of A1 before writing
A4_PREV     SET     $2000

*** Strings for opcodes (write these to memory)
* ----- Strings from LEFT (0) branch --------- *
S_NOP       DC.B    'NOP            ',0
S_RTS       DC.B    'RTS            ',0
S_MOVE      DC.B    'MOVE           ',0
S_JSR       DC.B    'JSR            ',0
S_ADDQ_B    DC.B    'ADDQ.B         ',0
S_ADDQ_W    DC.B    'ADDQ.W         ',0
S_ADDQ_L    DC.B    'ADDQ.L         ',0
S_ADDI_B    DC.B    'ADDI.B         ',0
S_ADDI_W    DC.B    'ADDI.W         ',0
S_ADDI_L    DC.B    'ADDI.L         ',0
S_SUBI_B    DC.B    'SUBI.B         ',0
S_SUBI_W    DC.B    'SUBI.W         ',0
S_SUBI_L    DC.B    'SUBI.L         ',0
S_CLR_B     DC.B    'CLR.B          ',0
S_CLR_W     DC.B    'CLR.W          ',0
S_CLR_L     DC.B    'CLR.L          ',0
S_LEA       DC.B    'LEA            ',0
S_MOVEQ     DC.B    'MOVEQ          ',0
S_BGT_B     DC.B    'BGT.B          ',0
S_BGT_W     DC.B    'BGT.W          ',0
S_BLE_B     DC.B    'BLE.B          ',0
S_BLE_W     DC.B    'BLE.W          ',0
S_BCC_B     DC.B    'BCC.B          ',0
S_BCC_W     DC.B    'BCC.W          ',0
S_MOVE_B    DC.B    'MOVE.B         ',0
S_MOVE_W    DC.B    'MOVE.W         ',0
S_MOVE_L    DC.B    'MOVE.L         ',0
S_MOVEA_W   DC.B    'MOVEA.W        ',0
S_MOVEA_L   DC.B    'MOVEA.L        ',0
S_MOVEM_W   DC.B    'MOVEM.W        ',0
S_MOVEM_L   DC.B    'MOVEM.L        ',0
* ----- Strings from RIGHT (1) branch --------- *
S_DIVU      DC.B    'DIVU.W         ',0
S_OR        DC.B    'OR             ',0
S_SUB       DC.B    'SUB            ',0
S_CMP_B     DC.B    'CMP.B          ',0
S_CMP_W     DC.B    'CMP.W          ',0
S_CMP_L     DC.B    'CMP.L          ',0
S_ADDA      DC.B    'ADDA           ',0
S_LSR       DC.B    'LSR            ',0
S_LSL       DC.B    'LSL            ',0
S_ROR       DC.B    'ROR            ',0
S_ROL       DC.B    'ROL            ',0
S_ASL       DC.B    'ASL            ',0
S_ASR       DC.B    'ASR            ',0
S_OR_B      DC.B    'OR.B           ',0
S_OR_W      DC.B    'OR.W           ',0
S_OR_L      DC.B    'OR.L           ',0
S_ADDA_W    DC.B    'ADDA.W         ',0
S_ADDA_L    DC.B    'ADDA.L         ',0
S_ADD_B     DC.B    'ADD.B          ',0
S_ADD_W     DC.B    'ADD.W          ',0
S_ADD_L     DC.B    'ADD.L          ',0
S_SUB_B     DC.B    'SUB.B          ',0
S_SUB_W     DC.B    'SUB.W          ',0
S_SUB_L     DC.B    'SUB.L          ',0
S_AND_B     DC.B    'AND.B          ',0
S_AND_W     DC.B    'AND.W          ',0
S_AND_L     DC.B    'AND.L          ',0
S_MULS_W    DC.B    'MULS.W         ',0
S_MULU_W    DC.B    'MULU.W         ',0
S_LSL_B     DC.B    'LSL.B          ',0
S_LSL_W     DC.B    'LSL.W          ',0
S_LSL_L     DC.B    'LSL.L          ',0
S_LSR_B     DC.B    'LSR.B          ',0
S_LSR_W     DC.B    'LSR.W          ',0
S_LSR_L     DC.B    'LSR.L          ',0
S_ROL_B     DC.B    'ROL.B          ',0
S_ROL_W     DC.B    'ROL.W          ',0
S_ROL_L     DC.B    'ROL.L          ',0
S_ROR_B     DC.B    'ROR.B          ',0
S_ROR_W     DC.B    'ROR.W          ',0
S_ROR_L     DC.B    'ROR.L          ',0
S_ASL_B     DC.B    'ASL.B          ',0
S_ASL_W     DC.B    'ASL.W          ',0
S_ASL_L     DC.B    'ASL.L          ',0
S_ASR_B     DC.B    'ASR.B          ',0
S_ASR_W     DC.B    'ASR.W          ',0
S_ASR_L     DC.B    'ASR.L          ',0
* ---- Strings for messages ----- 
INVALID     DC.B    'INVALID OPCODE. LETS FIX THIS MESSAGE LATER',0
COMEBK      DC.B    'Come back to me pls dont forget me',0 
BAD_OIOO    DC.B    'Bad OIOO maybe not JSR,RTS,CLR,LEA.. who knows.',0

*------------------------------- END OF STRING CONSTANTS SECTION ------------------------------
***************************************************************************************
*-------------------------------- MASK CONSTANTS SECTION ------------------------------------
JSR_MASK        EQU     %0000111111000000
ADDSUBI_MASK    EQU     %0000111100000000       ** come back and fix this to be the same but diferent comparisons 
ADDSUBI_S_MASK  EQU     %0000000011000000       * To determine the size
CLR_MASK        EQU     %0000111111000000
LEA_MASK        EQU     %0000000111000000
Bcc_MASK        EQU     %0000111100000000
ADDQ_MASK       EQU     %0000000011000000
MOVEA_MASK      EQU     %0011000111000000
MOVE_MASK       EQU     %0011000000000000
MOVEM_MASK      EQU     %0000100011000000
CMP_MASK        EQU     %1111000011000000
DIVU_MASK       EQU     %0000000111000000
ADD_MASK        EQU     %0000000111000000
SUB_MASK        EQU     %0000000111000000
AND_MM_MASK     EQU     %0000000111000000
R_MODE_MASK     EQU     %0000000000011000       * This one is to differentiate between LSd, ASd, and ROd
ROTATION_MASK   EQU     %0000000111000000       * This mask will be used to find direction and size
;; ~*~*~*~*~*~*~*~END OPCODE MODULE~*~*~*~*~*~*~*~







*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
