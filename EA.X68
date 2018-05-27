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



;; PROBABLY REMOVE THIS WRITE SR
*** Call this function to print the string loaded in A3 to the running
*** human-readable line. Note that this subroutine will not write a null
*** terminator; one must be written at the very end of decoding a full command.
*WRITE   * Writes tring pointed to by A3 to memory pointed to by A4
*    MOVE.B  (A3)+,(A4)+     * Write one byte and increment
*    CMP.B   #0,(A3)         * Check if the null terminator has been reached
*    BNE     WRITE           * If not, keep writing!
*    RTS

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
    

    MOVE.L  D5,D6               * D6 will be masked to hold only 3 LSB (reg #)
    AND.W   #THREE_LSB_MASK,D6  * D6 now holds source register #
    ROR.W   #3,D5               * rotate by 3 bits. mode should now be 3 LSB
    MOVE.L  D5,D0               * D0 will hold the mode
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds source mode code
    JSR     DO_MODE             * Get source mode decoded and written to buffer
    
    ** CURRENT BUFFER STATE: MOVE.x         Xn
    
    MOVE.B  #',',(A4)+           * Write the comma between EA modes
    ROR.W   #3,D5               * dest mode is now 3 LSB of D5
    MOVE.L  D5,D0               * Copy new rotated word into D0 for masking
    AND.W   #THREE_LSB_MASK,D0  * D0 now holds dest mode code
    ROR.W   #3,D5               * source register is now 3 LSB of D5
    MOVE.L  D5,D6               * Copy new rotated word into D6 for masking
    AND.W   #THREE_LSB_MASK,D6  * mask source register into D6
    JSR     DO_MODE             * Get dest mode decoded and written to buffer
    
    ** FINAL BUFFER STATE: MOVE.x         Xn,Xn
    
    RTS
    
    
    
;; Finds the mode stored in D6 and branches to appropriate SR to write to the buffer
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
    
    RTS


DR_DIRECT   *** Mode 0
    MOVE.B  #'D',(A4)+   * Write D to the buffer
    ADDI.B  #$30,D6     * Add $30 to the register number to convert to ASCII
    MOVE.B  D6,(A4)+    * Write the ASCII-converted number to the buffer
    RTS

AR_DIRECT   *** Mode 1
*    LEA     OPEN_PAREN_A,A3
*    JSR     WRITE
*    * Get the register number from D6, adding $30 to convert to ASCII
*    ADDI.B  #$30,D6
    

AR_INDIRECT *** Mode 2
    * WRITE (A
    * WRITE NUMBER IN D6
    * WRITE )

AR_POSTINC  *** Mode 3
    * WRITE (A
    * WRITE NUMBER IN D6
    * WRITE )+
    
AR_PREDEC   *** Mode 4
    * WRITE -(A
    * WRITE NUMBER IN D6
    * WRITE )

IMM_DATA
    * HOW TO DO THIS?

ABS_LONG
    * GET LONG FROM (A6)+
    * WRITE $
    * WRITE DATA GOT FROM A6

ABS_WORD
    * GET WORD FROM (A6)+
    * WRITE $
    * WRITE DATA GOT FROM A6
    
*OPEN_PAREN_A    DC.B    '(A',0
*OPEN_PAREN_D    DC.B    '(D',0
*DECR_OPEN_PAREN DC.B    '-(',0
*CLOSE_PAREN     DC.B    ')',0
*INC_CLOSE_PAREN DC.B    ')+',0

*** MASKS
THREE_LSB_MASK  EQU     %0000000000000111

;; ~*~*~*~*~*~*~*~END EA MODULE~*~*~*~*~*~*~*~
*??

    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
