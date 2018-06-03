*------------------------------------------------------------------------------|
* Title      : EA Module                                                       |
* Written by : Clayton Snyder, Audrey Chae, Nicholas Gorsline (Team Toucans)   |
* Created    : 5/20/2018                                                       |
* Description: One half of disassembly logic for a Motorola 68k disassembler.  |
*              Provides subroutines for decoding and writing effective         |
*              modes which can be used by the OP module after the op-code is   |
*              written.                                                        |
*------------------------------------------------------------------------------|

;; ~*~*~*~*~*~*~*~BEGIN EA MODULE~*~*~*~*~*~*~*~

*** A4 -> Location in memory to write to
*** D0 -> Holds mode #
*** D6 -> Holds register #
*** D7 -> Size code given by OP module ($00 -> byte, $01 -> word, $0A -> long)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Invalid op-code ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BAD_DATA
    MOVE.B  #'$',(A4)+
    MOVE.B  #04,D3      * init counter for convert loop
BD_WC_LOOP
    ROL.W   #04,D5      * rotate MSHB to LSBH to mask and convert
    MOVE.B  D5,D2       * copy freshly rotated data into D2 for masking
    ANDI.B  #%00001111,D2   * mask just the last hex bit into D2
    CMPI.B  #$0A,D2     * check if should convert to ASCII digit or letter
    BLT     BD_WDIG_CONVERT * skip past 
    ADDI.B  #$37,D2     * add $37 to get an ASCII letter
    BRA     BD_WCOND_CHECK  * skip digit conversion
BD_WDIG_CONVERT
    ADDI.B  #$30,D2     * add $30 to get an ASCII digit
BD_WCOND_CHECK
    MOVE.B  D2,(A4)+    * write the converted ASCII byte
    SUBI.B  #01,D3      * decrement the counter
    CMP.B   #00,D3      * check if counter has gone to zero
    BGT     BD_WC_LOOP     * if not, keep looping
    RTS 
    



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MOVE and MOVEA parsing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVE_EA
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
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MOVEQ parsing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOVEQ_EA
    *** DECODE SOURCE EA
    * Source of MOVEQ is always one byte of immediate data. This has to be 
    * manually coded because the data is in the opcode, not in memory.
    MOVE.B  #'#',(A4)+          * Write $ to the buffer to indicate imm data
    MOVE.B  #'$',(A4)+          * Write $ to the buffer to indicate hex data
    MOVE.B  D5,D6               * Copy D5 to D6 to mask the data out
    ROR.B   #04,D6              * Rotate so MSB hexa bit is 4 LSB
    AND.B   #%00001111,D6       * Mask the last four bits
    CMP.B   #$A,D6              * Check value for correct ASCII conversion
    BLT     NO_EXTRA            * Don't add extra 7 if it's a digit
    ADDI.B  #$07,D6             * Add extra 7 if it's a character
NO_EXTRA
    ADDI.B  #$30,D6             * Convert to ASCII
    MOVE.B  D6,(A4)+            * Write the conveted ASCII character

    MOVE.B  D5,D6               * Restore D6 (won't be rotated this time)
    AND.B   #%00001111,D6       * Mask the last four bits
    CMP.B   #$A,D6              * Check value for correct ASCII conversion
    BLT     NO_EXTRA_2          * Don't add extra 7 if it's a digit
    ADDI.B  #$07,D6             * Add extra 7 if it's a character
NO_EXTRA_2
    ADDI.B  #$30,D6
    MOVE.B  D6,(A4)+

    *** CURRENT BUFFER STATE: MOVEQ     #<data>
    
    MOVE.B  #',',(A4)+

    *** DECODE DESTINATION EA
    ROL.W   #07,D5              * Rotate so that destination register is 3 LSB
    MOVE.W  D5,D6               * Copy D5 to D6 for masking
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds destination register number
    MOVE.B  #00,D0              * DR Direct (000) for the mode
    JSR     DO_MODE
    RTS
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MOVEM parsing ;;;;;;;;;;;;;;;;;;NOT WORKING: WILL SPECIFY IN DOCUMENTATION;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
* MOVEM_EA
*     * First obtain the MODE
*     MOVE.W  #MOVEM_MODE_MASK,D0 * Store the mask in D0 to find the Mode
*     AND.W   D5,D0               * Find out what the mode digits are
*     ROR.W   #03,D0              * Rotate the last three 0's out to make mode LSB

*     * Obtain the REGISTER
*     MOVE.W  #THREE_LSB_MASK,D6  * Need to clear the bit at position 3 for register bits
*     AND.W  D5,D6               * last 3 bits of D5 are already the register bits;
    
*     * Then Parse first word in D5 to find the dr
*     BTST.L  #10,D5              * Bit position 10 contains the dr field         
*     BEQ     MOVEM_REG_MEM       * Branch to the Register --> memory MOVEM logic
*     BRA     MOVEM_MEM_REG       * Branch to the memory --> register MOVEM logic
*     RTS                         * Not sure if this is the correct move
* MOVEM_REG_MEM   * When dr = 0, code structure: MOVEM <list>, <ea> 
*     MOVE.W  (A6)+,D5    * Load data
*     * First, write Register List
*     CMP.B   #04,D0  * Predecrement case has different register list mask order       
*     BEQ     FIND_LIST_PREDECREMENT  * Finds the Register List in D0-D7/A0-A7 format
*     BRA     FIND_LIST               * Finds the Register List in A7-A0/D7-D0 format 
*     JSR     DO_MODE                 * Then write the <ea> portion
*     RTS
* MOVEM_MEM_REG   * When dr = 1, code structure: MOVEM <ea>,<list>
*     MOVE.W  (A6)+,D5    * Load data

*     * First, write the <ea> portion
*     JSR     DO_MODE
*                                     * Then, write Register List
*     CMP.B   #04,D0                  * Predecrement case has different register list mask order       
*     BEQ     FIND_LIST_PREDECREMENT  * Finds the Register List in D0-D7/A0-A7 format
*     BRA     FIND_LIST               * Finds the Register List in A7-A0/D7-D0 format 
*     RTS
* * ------ Routine for finding PREDECREMENT Register list 
* APPEND_A_REGS
*     MOVE.B  #'(',(A4)+  * Write ( to the buffer
*     MOVE.B  #'A',(A4)+  * Write A to the buffer
*     SUBI.B  #07,D4      * WRITE bitPos-7
*     MOVE.B  D4,(A4)+    * Write the ASCII-converted number to the buffer
*     MOVE.B  #')',(A4)+  * Write ) to the buffer
*     ADDI.B  #07,D4      * restore 
*     RTS
* APPEND_D_REGS
*     MOVE.B  #'D',(A4)+      * write bitPos -15
*     SUBI.B  #15,D4      
*     MOVE.B  D4,(A4)+        * Write the ASCII-converted number to the buffer
*     ADDI.B  #15,D4
*     RTS
* MAKE_LIST
*     CMP.B   #08,D4          * If bit position >= 8, data register
*     BGE     APPEND_D_REGS   * write data registers
*     BRA     APPEND_A_REGS   * bit position < 8, address registers
*     SUBI.B  #01,D4          * After it all, decrement bit position
*     ADDI.B  #01,D3          *Increment sequence counter   
* INNER_LOOP
*     BTST.L  D4,D5           *check if bit at the bit position counter is 0
*     BNE     CHECK_LIST      * = 1; A register of that number exists 
* COMMA_LOOP                  * should make sure that there's no comma at the end 
*     CMP.B   #00,D3          * If there hasn't been a sequence, skip over.
*     BNE     PRINT_COMMA     * Previous sequence existed and is ending
*     * No sequence existed, just skip over
*     SUBI.B  #01,D4          * Moving on, looking at next 
*     BRA     OUTER_COND      * Continue on with the loop   
* PRINT_COMMA 
*     MOVE.B  #',',(A4)+      * Write the comma in between separated registers
*     CLR.L   D3              * clear the sequence counter
*     SUBI.B  #01,D4          * decrement the bit position
* OUTER_COND
*     CMP.B   #08,D4          * check that the bit position hasn't reached 8 while (bitPos != limit)
*     BGE     INNER_LOOP      * process for finding the data register list
*     * Check if there was nothing done here before
*     MOVE.B  #'/',(A4)+      * write the / for differentiating address and data registers
*     BRA     INNER_LOOP      * process for finding address register
* CHECK_LIST
*     CMP.B   #00,D3          * check if sequence counter = 0
*     BEQ     MAKE_LIST
*     RTS
* FIND_LIST_PREDECREMENT      * Finds and writes Register List in D0-D7/A0-A7
*     MOVE.B  #15,D4          * bit position; starting from MSB -- > bit #15
*     CLR.L   D3          * sequence counter; need to clear later
*     BRA     OUTER_COND
*     RTS
* *------ End Predecrement Register List routine
* *-----------------------------------------------------
* *------ Routine for finding Register List 
* APPEND_A_REGS_2
*     MOVE.B  #'(',(A4)+  * Write ( to the buffer
*     MOVE.B  #'A',(A4)+  * Write A to the buffer
*     SUBI.B  #08,D4      * WRITE bitPos-8
*     MOVE.B  D4,(A4)+    * Write the ASCII-converted number to the buffer
*     MOVE.B  #')',(A4)+  * Write ) to the buffer
*     ADDI.B  #08,D4      * Restore value 
*     RTS
* APPEND_D_REGS_2
*     MOVE.B  #'D',(A4)+          * write bitPos -7
*     SUBI.B  #07,D4      
*     MOVE.B  D4,(A4)+            * Write the ASCII-converted number to the buffer
*     ADDI.B  #07,D4              * Restore value 
*     RTS
* MAKE_LIST_2
*     CMP.B   #08,D4              * If bit position >= 8, data register
*     BGE     APPEND_D_REGS_2     * write data registers
*     BRA     APPEND_A_REGS_2     * bit position < 8, address registers
*     ADDI.B  #01,D4              * After it all, increment bit position
*     ADDI.B  #01,D3              *Increment sequence counter   
* INNER_LOOP_2
*     BTST.L  D4,D5           *check if bit at the bit position counter is 0
*     BNE     CHECK_LIST_2
* COMMA_LOOP_2                  * should make sure that there's no comma at the end 
*     MOVE.B  #',',(A4)+      * Write the comma in between separated registers 
*     CLR.L   D3              * clear the sequence counter
*     ADDI.B  #01,D4          * increment the bit position
* OUTER_COND_2
*     CMP.B   #08,D4          * check that the bit position hasn't reached 8 while (bitPos != limit)
*     BGE     INNER_LOOP_2    * process for finding the data register list
*     MOVE.B  #'/',(A4)+      * write the / for differentiating address and data registers
*     BRA     INNER_LOOP_2    * process for finding address register
* CHECK_LIST_2
*     CMP.B   #00,D3          * check if sequence counter = 0
*     BEQ     MAKE_LIST_2
*     RTS
* FIND_LIST               * Finds and writes Register List in A7-A0/D7-D0 format
*     MOVE.B  #15,D4          * BIT POSITION; starting from MSB -- > bit #15
*     CLR.L   D3          * sequence counter; need to clear later
*     BRA     OUTER_COND_2
*     RTS    

 *------ End Register List routine
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~   

*------ SECOND IDEA FOR MOVEM ---- *
* DID NOT FINISH, WILL EXPLAIN IN DOCUMENTATION
* MOVEM_EA
* * First obtain the MODE
*     MOVE.W  #MOVEM_MODE_MASK,D0 * Store the mask in D0 to find the Mode
*     AND.W   D5,D0               * Find out what the mode digits are
*     ROR.W   #03,D0              * Rotate the last three 0's out to make mode LSB

*     * Obtain the REGISTER
*     MOVE.W  #THREE_LSB_MASK,D6  * Need to clear the bit at position 3 for register bits
*     AND.W  D5,D6                * last 3 bits of D5 are already the register bits;
    
*     * Then Parse first word in D5 to find the dr
*     BTST.L  #10,D5              * Bit position 10 contains the dr field         
*     BEQ     MOVEM_REG_MEM       * Branch to the Register --> memory MOVEM logic
*     BRA     MOVEM_MEM_REG       * Branch to the memory --> register MOVEM logic
*     RTS                         * Not sure if this is the correct move
* MOVEM_REG_MEM   * dr = 0 = MOVEM <List> , <EA>
*     JSR     LIST_FINDER
*     * Need to pull another word before calling EA
*     MOVE.W  (A6)+,D5
*     JSR     DO_MODE
* MOVEM_MEM_REG   * dr = 1 = MOVEM <EA> , <List> 
*     JSR     DO_MODE
*     JSR     LIST_FINDER
* LIST_FINDER
*     MOVE.W  (A6)+,D5    * Load data to be viewed
*     CMP.B   #04,D0
*     BEQ     D0_D7_A0_A7
*     BRA     A7_A0_D7_D0
*     RTS
* PRINT_COMMA 
*     MOVE.B  #',',(A4)+      * Write the comma in between separated registers
*     CLR.L   D3              * clear the sequence counter
*     SUBI.B  #01,D4          * decrement the bit position
*     BRA     OUTER_LOOP  
* DATA_WRITE
*     MOVE.B  #'D',(A4)+      * write bitPos -15
*     SUBI.B  #15,D4          * need this switches   
*     MOVE.B  D4,(A4)+        * Write the ASCII-converted number to the buffer
*     ADDI.B  #15,D4

*     SUBI.B  #01,D4          * move right
*     BRA     OUTER_LOOP      * continue to return 
* WRITE_SLASH
*     MOVE.B  #'/',(A4)+      * write the / for differentiating address and data registers
*     BRA     ADDRESS_CONT    * return back to write the addressings 
* ADDRESS_WRITE
*     CMP.B   #07,D4          * did we just freshly enter into addresses?
*     BEQ     WRITE_SLASH
* ADDRESS_CONT
*     MOVE.B  #'(',(A4)+  * Write ( to the buffer
*     MOVE.B  #'A',(A4)+  * Write A to the buffer
*     SUBI.B  #07,D4      * WRITE bitPos-7 * need this switched 
*     MOVE.B  D4,(A4)+    * Write the ASCII-converted number to the buffer
*     MOVE.B  #')',(A4)+  * Write ) to the buffer
*     ADDI.B  #07,D4      * restore 

*     SUBI.B  #01,D4          * move right
*     BRA     OUTER_LOOP      * continue to return
* CHECK_LIST  * position at byte position was 1 at this point
*     CMP.B   #08,D4
*     BGE     DATA_WRITE
*     BRA     ADDRESS_WRITE
* CHECK_SQN 
*     CMP.B   #00,D3      * no previous sequence?
*     BNE     PRINT_COMMA
*     SUBI.B  #01,D4      * if == 0 ,do nothing
*     BRA     OUTER_LOOP
* INNER_LOOP
*     BTST.L  D4,D5       * check the position of the loaded in word
*     BNE     CHECK_LIST  * if =1, that position has a register
*     * BRA     CHECK_SQN   * if = 0, check the sequence for commas   
* OUTER_LOOP
*     CMP.B   #00,D4      * while it's still searching
*     BGE     INNER_LOOP  * check for required registers 
*     RTS                 * leave if finished 
* D0_D7_A0_A7     * Formats in D0-D7/A0-A7 style for indirect, post-decrement 
*     * first check to see if any register portion is 0
*     MOVE.B  #15,D4  * bit position
*     CLR.L   D3      * sequence counter
*     BRA     OUTER_LOOP
* A7_A0_D7_D0     * Formats in A7-A0/D7-D0 style for others


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LSd and ROd (register) parsing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ROT_EA
    *** First thing to do is check if register or memory rotate
    CMP.B   #11,D7              * Size code 11 means it's memory rotate
    BNE     ROT_NOT_MEM         * Skip past memory rotation logic if not
JSR_EA                          * JSR can use this logic directly
    MOVE.W  D5,D6               * Move D5 into D6 for masking
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds register number
    MOVE.W  D5,D0               * Copy D5 to D0 for masking
    ROR.W   #03,D0              * Rotate so mode code is 3 LSB
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds mode code
    JSR     DO_MODE
    RTS

ROT_NOT_MEM
    *** Is source value in Dn or immediate value? Check bit 8
    ROL.W   #07,D5              * Rotate so bits 11-9 are 3 LSB
    MOVE.L  D5,D6               * Move rotated word into D6 for masking
    ANDI.W  #THREE_LSB_MASK,D6  * D6 holds either register or imm data
    ROR.W   #07,D5              * Undo the previous rotation
    
    BTST.L  #05,D5              * Test bit 5 to detect size in Dn or immediate
    BNE     ROT_PREP_MODE       * If 1, prep for call to DO_MODE
    
    *** If i/r (bit 5) = 0, bits 11-9 represent immediate data. Can't use the
    *** IMM_DATA subroutine here because logic is unique.
    
    MOVE.B  #'#',(A4)+          * Write # to the buffer for imm. data
    CMP.B   #00,D6              * 000 = 8 for this opcode...
    BGT     ROT_GT_ZERO
    ADDI.B  #08,D6              * ...so add 8 before moving on if it's 0.

ROT_GT_ZERO
    ADDI.B  #$30,D6             * Convert to ASCII (can't be >8, so no letters)
    MOVE.B  #'0',(A4)+          * Write 0 preceding the ASCII digit
    MOVE.B  D6,(A4)+            * Write the ASCII byte
    BRA     ROT_DEST            * Skip past LST_PREP_MODE to write the dest
    
ROT_PREP_MODE
    *** Here, we prepare registers for a call to DO_MODE to write source EA
    MOVE.B  #00,D0              * Set D0 to hold Dn Direct mode (000)
    MOVEM   D5,-(SP)
    JSR     DO_MODE
    MOVEM   (SP)+,D5
    
ROT_DEST
    MOVE.B  #',',(A4)+          * Write a comma between EA modes
    MOVE.L  D5,D6               * Copy D5 into D6
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds dest register number
    MOVE.B  #00,D0              * Destination mode is always Dn Direct (000)
    JSR     DO_MODE
    RTS
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CLR parsing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CLR_EA
    MOVE.L  D5,D6               * Copy D5 into D6 for register masking
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds register number
    ROR.W   #03,D5              * Rotate so mode is 3 LSB
    MOVE.L  D5,D0               * Copy D5 into D0 for mode masking
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds mode code
    JSR     DO_MODE
    RTS
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ADDQ parsing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ADDA and LEA parsing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ADDI and SUBI parsing ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ADD and SUB parsing when source is Dn (otherwise use DR_ARITH_EA) ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Checks bit 8 to see if bits 11-6 are source or destination for ADD and SUB
ADD_SUB_AND_OR_CMP_EA
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
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MULS, MULU, DIV, and certain cases for SUB and ADD parsing ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Bcc parsing ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BCC_EA
    MOVE.B  #'$',(A4)+           * Write hex indicator to buffer

    * First, identify the type of displacement
    CMP.B   #01,D7              * Word size
    BEQ     BCC_WORD_EA
    
    ** Byte displacement here
    CLR.L   D6
    MOVE.B  D5,D6
    MOVE.W  A6,D0               * Move address of Bcc command into D0 to add
    ADD.L   D0,D6               * Add displacement to 
    
BCC_WORD_EA
    MOVE.W  A6,D0               * Address A6 used to calculate address of label
    CLR.L   D6
    MOVE.W  (A6)+,D6            * Get the displacement word of the Bcc command
    ADD.L   D0,D6               * Add displacement to Bcc addr (get label addr)
    
    ** Convert the new calculated displacement to ASCII and write
    MOVE.B  #08,D3       * init counter for convert loop
BCC_LC_LOOP
    ROL.L   #04,D6      * rotate MSHB to LSBH to mask and convert
    MOVE.B  D6,D2       * copy freshly rotated data into D2 for masking
    ANDI.B  #%00001111,D2   * mask just the last hex bit into D2
    CMPI.B  #$0A,D2     * check if should convert to ASCII digit or letter
    BLT     BCC_LDIG_CONVERT * skip past 
    ADDI.B  #$37,D2     * add $37 to get an ASCII letter
    BRA     BCC_LCOND_CHECK  * skip digit conversion
BCC_LDIG_CONVERT
    ADDI.B  #$30,D2     * add $30 to get an ASCII digit
BCC_LCOND_CHECK
    MOVE.B  D2,(A4)+    * write the converted ASCII byte
    SUBI.B  #01,D3      * decrement the counter
    CMP.B   #00,D3      * check if counter has gone to zero
    BGT     BCC_LC_LOOP * if not, keep looping
    
    
    RTS
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DO_MODE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Branch to appropriate writing subroutine based on the mode in D0 ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DR_DIRECT AR_DIRECT AR_INDIRECT AR_POSTINC AR_PREDEC IMM_DATA ABSOLUTE ;;;;;;
; Branch to appropriate writing subroutine based on the mode in D0 ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~


    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GET/WRITE HARD DATA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
; Gets, converts, and writes hard data EA modes (absolute and immediate) ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
    MOVE.B  #04,D3          * init counter for convert loop
WC_LOOP
    ROL.W   #04,D5          * rotate MSHB to LSBH to mask and convert
    MOVE.B  D5,D2           * copy freshly rotated data into D2 for masking
    ANDI.B  #%00001111,D2   * mask just the last hex bit into D2
    CMPI.B  #$0A,D2         * check if should convert to ASCII digit or letter
    BLT     WDIG_CONVERT    * skip past 
    ADDI.B  #$37,D2         * add $37 to get an ASCII letter
    BRA     WCOND_CHECK     * skip digit conversion
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
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~
; ~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~




THREE_LSB_MASK  EQU     %0000000000000111
MOVEM_MODE_MASK EQU     %0000000000111000
;; ~*~*~*~*~*~*~*~END EA MODULE~*~*~*~*~*~*~*~













*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
