*-----------------------------------------------------------
* Title      : EA Module
* Written by : Toucans (Audrey Chae, Nick Gorsline, Clayton Snyder)
* Date       : 5/20/2018
* Description: EA Module of the 68k disassembler
*-----------------------------------------------------------


;;;;;;;;;;; HEY HELLO HEY -----> WRITE A NULL TERM AT END OF DECODING A CMD!!! <------

;; ~*~*~*~*~*~*~*~BEGIN EA MODULE~*~*~*~*~*~*~*~

*** A3 -> Null-terminated string to write (load before calling)
*** A4 -> Location in memory to write to

*** D0 -> Holds mode # (used by WRITE)
*** D6 -> Holds register # (used by WRITE)


; EA parsing for MOVE and MOVEA
MOVE_EA

;; *~*~*~*~*~*~*~ pSeUdOcOdE ~*~*~*~*~*~*~* ;;
    * 1.) Mask 3 LSB into D6 (reg #)
    * 2.) ROR 3 bits
    * 3.) Mask 3 LSB into D0 (mode #)
    * 4.) Call mode-specific buffer writer (DO_MODE -> write_mode_x)
;; NOTES: there will be one mode-specific buffer writer for each mode.
;; The routine will write mode-specific strings to the buffer in addition to
;; the register number (converted to ASCII). Use A3 and A4 to do this.
    * 5.) Write a comma
    * 6.) ROR 3 bits
    * 7.) Mask 3 LSB into D0 (mode #)
    * 8.) ROR 3 bits
    * 9.) Mask 3 LSB into D6 (reg #)
    * 10.) Call mode-specific buffer writer
    * 11.) Return to I/O module
    

    *** DECODE SOURCE EA
    MOVE.L  D5,D6               * D6 will be masked to hold only 3 LSB (reg #)
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds source register #
    ROR.W   #3,D5               * rotate by 3 bits. mode should now be 3 LSB
    MOVE.L  D5,D0               * D0 will hold the mode
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds source mode code
    MOVEM   D5,-(SP)            * Save the contents of D5 so DO_MODE can use it
    JSR     DO_MODE             * Get source mode decoded and written to buffer
    MOVEM   (SP)+,D5            * Restore the value of D5
    
    ** CURRENT BUFFER STATE: MOVE.x         Xn
    
    MOVE.B  #',',(A4)+          * Write the comma between EA modes
    
    *** DECODE DESTINATION EA
    ROR.W   #3,D5               * dest mode is now 3 LSB of D5
    MOVE.L  D5,D0               * Copy new rotated word into D0 for masking
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds dest mode code
    ROR.W   #3,D5               * source register is now 3 LSB of D5
    MOVE.L  D5,D6               * Copy new rotated word into D6 for masking
    AND.W   #THREE_LSB_MASK,D6  * mask source register into D6
    JSR     DO_MODE             * Get dest mode decoded and written to buffer
    
    ** FINAL BUFFER STATE: MOVE.x         Xn,Xn
    
    RTS
    
LSD_EA
    *** First, is source value in Dn or immediate value? Check bit 8
    ROL.W   #07,D5              * Rotate so bits 11-9 are 3 LSB
    MOVE.L  D5,D6               * Move rotated word into D6 for masking
    ANDI.W  #THREE_LSB_MASK,D6  * D6 holds either register or imm data
    ROR.W   #07,D5              * Undo the previous rotation
    
    BTST.L  #05,D5              * Test bit 5 to detect size in Dn or immediate
    BNE     LSD_PREP_MODE       * If 1, prep for call to DO_MODE
    
    *** If i/r (bit 5) = 0, bits 11-9 represent immediate data. Can't use the
    *** IMM_DATA subroutine here because logic is unique.
    
    MOVE.B  #'#',(A4)+          * Write # to the buffer for imm. data
    CMP.B   #00,D6              * 000 = 8 for this opcode...
    BGT     GT_ZERO
    ADDI.B  #08,D6              * ...so add 8 before moving on if it's 0.

GT_ZERO
    ADDI.B  #$30,D6             * Convert to ASCII (can't be >8, so no letters)
    MOVE.B  #'0',(A4)+          * Write 0 preceding the ASCII digit
    MOVE.B  D6,(A4)+            * Write the ASCII byte
    BRA     LSD_DEST            * Skip past LST_PREP_MODE to write the dest
    
LSD_PREP_MODE
    *** Here, we prepare registers for a call to DO_MODE to write source EA
    MOVE.B  #00,D0              * Set D0 to hold Dn Direct mode (000)
    MOVEM   D5,-(SP)
    JSR     DO_MODE
    MOVEM   (SP)+,D5
    
LSD_DEST
    MOVE.B  #',',(A4)+          * Write a comma between EA modes
    MOVE.L  D5,D6               * Copy D5 into D6
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds dest register number
    MOVE.B  #00,D0              * Destination mode is always Dn Direct (000)
    JSR     DO_MODE
    RTS
    
    
ADDQ_EA
    *** SOURCE decoding
    MOVE.W  D5,D6               * Copy the instruction into D6
    ROL.W   #07,D6              * Rotate so that the data (1-8) is 3 LSB
    AND.W   #THREE_LSB_MASK,D6  * Mask the 3 LSB; this is the immediate data
    
    MOVE.B  #'#',(A4)+          * Write # to the buffer for imm. data
    CMP.B   #00,D6              * 000 = 8 for this opcode...
    BGT     ADDQ_GT_ZERO
    ADDI.B  #08,D6              * ...so add 8 before moving on if it's 0.
    
ADDQ_GT_ZERO
    ADDI.B  #$30,D6             * Convert to ASCII (can't be >8, so no letters)
    MOVE.B  #'0',(A4)+          * Write 0 preceding the ASCII digit
    MOVE.B  D6,(A4)+            * Write the ASCII byte
    
    MOVE.B  #',',(A4)+          * Write a comma
    
    ** CURRENT BUFFER STATE: ADDQ   
    
    *** DESTINATION decoding
    MOVE.L  D5,D6               * Copy D5 into D6 for register masking
    AND.W   #THREE_LSB_MASK,D6  * Mask regsiter into D6
    ROR.W   #03,D5              * Rotate so mode is in 3 LSB
    MOVE.L  D5,D0               * Copy D5 into D0 for mode masking
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds mode code
    JSR     DO_MODE
    RTS
    
    
    
ADDA_LEA_EA
    *** DECODE SOURCE EA
    MOVE.L  D5,D6               * D6 will be masked to hold only 3 LSB (reg #)
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds source register #
    ROR.W   #3,D5               * rotate by 3 bits. mode should now be 3 LSB
    MOVE.L  D5,D0               * D0 will hold the mode
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds source mode code
    MOVEM   D5,-(SP)            * Save the contents of D5 so DO_MODE can use it
    JSR     DO_MODE             * Get source mode decoded and written to buffer
    MOVEM   (SP)+,D5            * Restore the value of D5
    
    ** CURRENT BUFFER STATE: ADDA.x     Xn
    
    MOVE.B  #',',(A4)+          * Write a comma between modes
    
    *** DECODE DEST EA (always AR direct)
    MOVE.B  #01,D0              * Set D0 to represent AR direct
    ROR.W   #06,D5              * Rotate six bits right so reg is 3 LSB
    MOVE.W  D5,D6               * Copy D5 to D6
    AND.W   #THREE_LSB_MASK,D6  * Mask the reg into D6
    JSR     DO_MODE
    RTS

    
ADDI_SUBI_EA
    *** Source EA will always be immediate data. Save D5 and let SR do the work
    MOVEM   D5,-(SP)
    JSR     IMM_DATA
    MOVEM   (SP)+,D5
    
    ** CURRENT BUFFER STATE: ADDI.x     #$DATA
    
    MOVE.B  #',',(A4)+
    
    *** DECODE DESTINATION
    MOVE.L  D5,D6               * Move the current word into D6 for masking
    AND.W   #THREE_LSB_MASK,D6  * Mask the 3 LSB to get the register
    ROR.W   #03,D5              * Rotate three bits right so mode is 3 LSB
    MOVE.L  D5,D0               * Place rotated word in D6 for masking
    AND.W   #THREE_LSB_MASK,D0  * Mask to get the mode into D0
    JSR     DO_MODE
    
    RTS
    
    
; Checks bit 8 to see if bits 11-6 are source or destination for ADD and SUB
ADD_SUB_EA
    BTST.L  #08,D5
    BEQ     DR_ARITH_EA         * if bit 8 is clear, DR_ARITH_EA logic works
    
    *** If bit 8 is set, we need to handle bits 11-6 as the source
    ROR.W   #05,D5              * Shift 5 then 4 bits (can't shift >8 in one)
    ROR.W   #04,D5              * Bits 11-9 are now bits 2-0
    MOVE.W  D5,D6               * Move rotated instruction word into D6 to mask
    AND.W   #THREE_LSB_MASK,D6  * Mask source register # into D6
    MOVE.B  #00,D0              * Data register direct mode (000) into D0
    ROL.W   #05,D5              * Rotate D5 word back to original state
    ROL.W   #04,D5
    MOVEM   D5,-(SP)            * Save D5 so DO_MODE can use it
    JSR     DO_MODE
    MOVEM   (SP)+,D5            * Restore the value of D5
    
    ** CURRENT BUFFER STATE: OPER.x     Dn
    
    MOVE.B  #',',(A4)+          * Write comma between EA modes
    
    *** NOW DECODE BITS 5-0 AS DESTINATION
    MOVE.L  D5,D6               * D6 will be masked to hold only 3 LSB (reg #)
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds the source register number (Xn)
    ROR.W   #03,D5              * Rotate by 3 bits. Mode should now be 3 LSB
    MOVE.L  D5,D0               * D0 will hold the mode
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds source mode code
    JSR     DO_MODE             * Get source mode decoded and written to buffer
    
    RTS
    
    
    
    
    
    
; EA parsing for ADD, SUB, MULS, MULU, and DIVU
DR_ARITH_EA
    * First half of logic is similar to MOVE_EA
    
    *** DECODE SOURCE EA
    MOVE.L  D5,D6               * D6 will be masked to hold only 3 LSB (reg #)
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds the source register number (Xn)
    ROR.W   #03,D5              * Rotate by 3 bits. Mode should now be 3 LSB
    MOVE.L  D5,D0               * D0 will hold the mode
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds source mode code
    MOVEM   D5,-(SP)            * Save the contents of D5 so DO_MODE can use it
    JSR     DO_MODE             * Get source mode decoded and written to buffer
    MOVEM   (SP)+,D5            * Restore the value of D5
    
    ** CURRENT BUFFER STATE: OPER.x     Xn
    
    MOVE.B  #',',(A4)+          * Write the comma between EA modes
    
    *** DECODE DESTINATION EA
    ROR.W   #06,D5              * Don't need bits 8-6, so move past them
    MOVE.W  D5,D6               * Put newly rotated word into D6 for masking
    AND.W   #THREE_LSB_MASK,D6  * Bits 11-9 hold the destination register (Dn)
    MOVE.B  #00,D0              * The mode here will always be DR Direct (000)
    JSR     DO_MODE             * Get dest mode decoded and written to buffer
    
    ** FINAL BUFFER STATE:  OPER.x      Xn,Dn
    
    RTS
    
    
    
    
; Finds mode stored in D6 and branches to appropriate SR to write to the buffer
DO_MODE
    CMP.B   #00,D0      ** Mode 0 - Data Register Direct
    BEQ     DR_DIRECT
    
    CMP.B   #01,D0      ** Mode 1 - Address Register Direct
    BEQ     AR_DIRECT   
    
    CMP.B   #02,D0      ** Mode 2 - Address Register Indirect
    BEQ     AR_INDIRECT
    
    CMP.B   #03,D0      ** Mode 3 - Address Register Indirect w/ Post-increment
    BEQ     AR_POSTINC
    
    CMP.B   #04,D0      ** Mode 4 - Address Register Indirect w/ Pre-decrement
    BEQ     AR_PREDEC
    
    ** HERE: check for non-required EA modes (101, 110, 111 w/ 010 in Xn, 111 w/ 011 in Xn)
    ** if found, branch to "unsupported EA mode" branch
    
    * assume mode is 111, check Xn for immediate data
    CMP.B   #04,D6
    BEQ     IMM_DATA
    
    * if not, it's absolute address: check size register for size key to branch
    *CMP.B   #10,D7
    *BEQ     ABSOLUTE
    
    * here, must be absolute word. check if word or long-word addressing range
    
    BRA     ABSOLUTE
    
    RTS


DR_DIRECT   *** Mode 0
    MOVE.B  #'D',(A4)+  * Write D to the buffer
    ADDI.B  #$30,D6     * Add $30 to the register number to convert to ASCII
    MOVE.B  D6,(A4)+    * Write the ASCII-converted number to the buffer
    RTS

AR_DIRECT   *** Mode 1
    MOVE.B  #'A',(A4)+  * Write A to the buffer
    ADDI.B  #$30,D6     * Add $30 to the register number to convert to ASCII
    MOVE.B  D6,(A4)+    * Write the ASCII-converted number to the buffer
    RTS
    

AR_INDIRECT *** Mode 2
    MOVE.B  #'(',(A4)+  * Write ( to the buffer
    MOVE.B  #'A',(A4)+  * Write A to the buffer
    ADDI.B  #$30,D6     * Add $30 to the register number to convert to ASCII
    MOVE.B  D6,(A4)+    * Write the ASCII-converted number to the buffer
    MOVE.B  #')',(A4)+  * Write ) to the buffer
    RTS

AR_POSTINC  *** Mode 3
    MOVE.B  #'(',(A4)+  * Write ( to the buffer
    MOVE.B  #'A',(A4)+  * Write A to the buffer
    ADDI.B  #$30,D6     * Add $30 to the register number to convert to ASCII
    MOVE.B  D6,(A4)+    * Write the ASCII-converted number to the buffer
    MOVE.B  #')',(A4)+  * Write ) to the buffer
    MOVE.B  #'+',(A4)+  * Write + to the buffer
    RTS
    
AR_PREDEC   *** Mode 4
    MOVE.B  #'-',(A4)+
    MOVE.B  #'(',(A4)+  * Write ( to the buffer
    MOVE.B  #'A',(A4)+  * Write A to the buffer
    ADDI.B  #$30,D6     * Add $30 to the register number to convert to ASCII
    MOVE.B  D6,(A4)+    * Write the ASCII-converted number to the buffer
    MOVE.B  #')',(A4)+  * Write ) to the buffer
    RTS

IMM_DATA
    MOVE.B  #'#',(A4)+
    MOVE.B  #'$',(A4)+
    JSR     GW_HARD_DATA
    RTS

ABSOLUTE
    MOVE.B  #'$',(A4)+
    * Test for (xxx).W [000 in register field] or (xxx).L [001]
    CMP.B   #00,D6
    BEQ     WORD
    BRA     LONG

    
    
    
    
GW_HARD_DATA
    * Branch based on D7 size code(#0 = byte, #1 = word, #10 = long, decimal)
    CMPI.B  #00,D7
    BEQ     BYTE
    CMPI.B  #01,D7
    BEQ     WORD
    CMPI.B  #10,D7
    BEQ     LONG
    
BYTE
    MOVE.W  (A6)+,D5
    MOVE.B  #02,D3      * init counter for convert loop
    ROL.W   #08,D5      * rotate MSHB to LSHB (twice, for writing only byte)
BC_LOOP
    ROL.W   #04,D5      * rotate MSHB to LSBH to mask and convert
    MOVE.B  D5,D2       * copy freshly rotated data into D2 for masking
    ANDI.B  #%00001111,D2   * mask just the last hex bit into D2
    CMPI.B  #$0A,D2     * check if should convert to ASCII digit or letter
    BLT     BDIG_CONVERT * skip past 
    ADDI.B  #$37,D2     * add $37 to get an ASCII letter
    BRA     BCOND_CHECK  * skip digit conversion
BDIG_CONVERT
    ADDI.B  #$30,D2     * add $30 to get an ASCII digit
BCOND_CHECK
    MOVE.B  D2,(A4)+    * write the converted ASCII byte
    SUBI.B  #01,D3      * decrement the counter
    CMP.B   #00,D3      * check if counter has gone to zero
    BGT     BC_LOOP     * if not, keep looping
    RTS


WORD
    MOVE.W  (A6)+,D5
    MOVE.B  #04,D3       * init counter for convert loop
WC_LOOP
    ROL.W   #04,D5      * rotate MSHB to LSBH to mask and convert
    MOVE.B  D5,D2       * copy freshly rotated data into D2 for masking
    ANDI.B  #%00001111,D2   * mask just the last hex bit into D2
    CMPI.B  #$0A,D2     * check if should convert to ASCII digit or letter
    BLT     WDIG_CONVERT * skip past 
    ADDI.B  #$37,D2     * add $37 to get an ASCII letter
    BRA     WCOND_CHECK  * skip digit conversion
WDIG_CONVERT
    ADDI.B  #$30,D2     * add $30 to get an ASCII digit
WCOND_CHECK
    MOVE.B  D2,(A4)+    * write the converted ASCII byte
    SUBI.B  #01,D3      * decrement the counter
    CMP.B   #00,D3      * check if counter has gone to zero
    BGT     WC_LOOP     * if not, keep looping
    RTS    


LONG
    MOVE.L  (A6)+,D5
    MOVE.B  #08,D3       * init counter for convert loop
LC_LOOP
    ROL.L   #04,D5      * rotate MSHB to LSBH to mask and convert
    MOVE.B  D5,D2       * copy freshly rotated data into D2 for masking
    ANDI.B  #%00001111,D2   * mask just the last hex bit into D2
    CMPI.B  #$0A,D2     * check if should convert to ASCII digit or letter
    BLT     LDIG_CONVERT * skip past 
    ADDI.B  #$37,D2     * add $37 to get an ASCII letter
    BRA     LCOND_CHECK  * skip digit conversion
LDIG_CONVERT
    ADDI.B  #$30,D2     * add $30 to get an ASCII digit
LCOND_CHECK
    MOVE.B  D2,(A4)+    * write the converted ASCII byte
    SUBI.B  #01,D3      * decrement the counter
    CMP.B   #00,D3      * check if counter has gone to zero
    BGT     LC_LOOP     * if not, keep looping
    RTS


*** MASKS
THREE_LSB_MASK  EQU     %0000000000000111

;; ~*~*~*~*~*~*~*~END EA MODULE~*~*~*~*~*~*~*~
*??

    END    START        ; last line of source










*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
