*-----------------------------------------------------------
* Title      :  Disassembler I/O 
* Written by :  touCANs
* Date       :  5/1/18 - 
* Description:  I/O functionality for the disassembler 
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    MOVEA.L #DISM_CODE,A4
    
    LEA     ADDR_PRMPT_STRT,A1
    MOVE.B  #14,D0
    TRAP    #15

    LEA     buffer,A1       * Load buffer's effective address into A1
    MOVE.B  #2,D0           * get the starting address from the user as a string
    
    TRAP    #15         
    
*** Need to first check if D1 is a valid size of minimum 4 (user entered at least 4 hexa bits)
    CMP     #4,D1           * minimum of a word for the address
    BLT     ERROR_INV_INP   * invalid start address  
    
    JSR     CONVERSION_LOOP * convert the starting address
    
*** FULL STARTING ADDRESS HAS BEEN CONVERTED, STORE IN A6 AND GET ENDING ADDRESSS
    MOVEA.L D2,A6           * move converted addr to A6 (A6 acts as iterator while disassembling)
    CLR.L   D2              * clear register D2 in preparation to hold the converted end address
    CLR.L   D4              * clear register D4 to start the counter at 0 again
    
    LEA     ADDR_PRMPT_END,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  #2,D0           * get the ending address from the user as a string
    TRAP    #15
    
*** Need to first check if D1 is a valid size of minimum 4 (user entered at least 4 hexa bits)
    CMP     #4,D1           * minimum of a word for the address
    BLT     ERROR_INV_INP   * invalid end address
    
    JSR     CONVERSION_LOOP * convert the ending address
    MOVEA.L D2,A5           * move converted addr to A5 (compare A6 to A5 to know when to stop)
    CMPA.L  A5,A6           * check if beginning address is >= end address. If so, display error
    BGE     ERROR_END_LTE_BEG
    BRA     MAIN_LOOP       * skip past the CONVERSION_LOOP subroutine to continue with the program
    


*    ADDI.B  #1,D4           * offset our counter to start at 1


;; ~~~~~~~~BEGINNING OF CONVERSION SUBROUTINE~~~~~~~~
CONVERSION_LOOP       
    MOVE.B  (A1)+,D3        * store the next thingy B
*** Need to check for proper hex conversion 

CHECK_NUM_MIN     ;; Checks if number is >= 30 (0) in ASCII
    CMP     #ASC_NUM_MIN,D3 * Range of ASCII numbers: (2F >= 3A)[2F,3A] then subtract 30    
    BGE     CHECK_NUM_MAX   * check if it's in range for x > 2F
    BRA     ERROR_INV_INP   * First condition not met, go to bad input error 
    
CHECK_NUM_MAX     ;; Checks if number is <= 39 (9) in ASCII
    CMP     #ASC_NUM_MAX,D3
    BLE     ASC_TO_NUM      * If condition for the range was met, do the math
    JMP     CHECK_CHAR_MIN  * Second condition was not met, check if a character
    
CHECK_CHAR_MIN    ;; Checks if number is >= 41 (A) in ASCII
    CMP     #ASC_CHAR_MIN,D3
    BGE     CHECK_CHAR_MAX  
    BRA     ERROR_INV_INP   * First condition not met, D3 < 41 = symbols. Go to bad input error
    
CHECK_CHAR_MAX    ;; Checks if number is <= 46 (F) in ASCII
    CMP     #ASC_CHAR_MAX,D3
    BLE     ASC_TO_CHAR     * Condition was met for A-F     
    BRA     ERROR_INV_INP   * Greater than 46 = out of 16-bit system
    
ASC_TO_NUM        ;; Converts a string digit into a hex value
    SUBI.B  #$30,D3
    JMP     SHIFTS          * After this routine is finished, complete shifts/adds
    
ASC_TO_CHAR       ;; Converts a string character into a hex value
    SUBI.B  #$37,D3    
    JMP     SHIFTS          * Convert a string character into a hex value
    
SHIFTS            ;; Shifts D2 left by four bits to make room for the newly converted hexabit
    LSL.L   #4,D2           * Initial value in D2 shifted hexabit over to the left to make room   
    ADD.B   D3,D2           * Add modified value from D3 into D2.
    
    ADD.B   #1,D4           * Increment counter by 1 
    CMP     D4,D1           * Check if we have already reached the end of the input. D4 = counter
    BNE     CONVERSION_LOOP * Continue back to the loop if D4 != D1  
    RTS
;; ~~~~~~~~END OF CONVERSION SUBROUTINE~~~~~~~~
    
    
    
ERROR_INV_INP ;; Prints the INVALID_INPUT error message to the console
    LEA     INVALID_INPUT,A1
    MOVE.B  #13,D0
    TRAP    #15
    BRA     END_NOW
    
ERROR_END_LTE_BEG ;; Prints the END_LTE_BEG (end <= to beginning) error message to the console.
    LEA     END_LTE_BEG,A1
    MOVE.B  #13,D0
    TRAP    #15
    BRA     END_NOW
  
  
MAIN_LOOP
    *BRA     END_NOW
    CMPA.L  A5,A6
    BGE     END_NOW * End program
    *MOVE.W  A6,D0   * Copy A6 location to restore after jump to SR
    JSR     OP_DECODE
    
<<<<<<< Updated upstream
PRINT_LOOP ;; Print the most recently decoded line
=======
PRINT_LOOP ;; Print the most recently decoded line    
>>>>>>> Stashed changes
    MOVE.B  #13,D0
    TRAP    #15
    BRA     MAIN_LOOP
    
;; print nops
PRINT_NOPS_TEST
    MOVE.B  #15,D0  * Trap task 15 to print a signed number in the base in D2
    MOVE.B  #16,D2  * Base 16 for the next two TRAPs
    * PRINT THE CURRENT ADDRESS
    MOVE.L  A6,D1
    TRAP    #15
    CLR.L   D1          * clear D1 so that it holds just the data on the next print
    
    LEA     COLON_SPACE,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.B  #1,D0   * Print string, no CRLF
    
    
    
    

;; ~~~~~~~~BEGINNING OF PRINT LOOP~~~~~~~~   
PRINT_IT          ;; Placeholder for now; just prints all data between start and end
    LEA     PRINT_IT_STRING,A1
    MOVE.B  #13,D0
    TRAP    #15
    
PRINT_IT_LOOP
    MOVE.B  #15,D0  * Trap task 15 to print a signed number in the base in D2
    MOVE.B  #16,D2  * Base 16 for the next two TRAPs
    * PRINT THE CURRENT ADDRESS
    MOVE.L  A6,D1
    TRAP    #15
    CLR.L   D1          * clear D1 so that it holds just the data on the next print
    
    LEA     COLON_SPACE,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    MOVE.L  (A6)+,D1    * move the data at the pointer into D1 and increment.
    MOVE.B  #15,D0      * Trap task 15 to print a signed number in the base in D2
    TRAP    #15
    
    * Print a new line
    LEA     NEW_LINE,A1
    MOVE.B  #13,D0
    TRAP    #15
    
    * Check if end address has been reached
    CMP.L   A5,A6
    BLE     PRINT_IT_LOOP
;; ~~~~~~~~END OF PRINT LOOP~~~~~~~~


    
    
    LEA     DONE_MSG,A1
    MOVE.B  #13,D0
    TRAP    #15

    SIMHALT             ; halt simulator

* Put variables and constants here

*** ASCII constants used in the conversion loop. Subtract these from an ASCII character to get its
*** real hex value (depending on whether it's a digit or a character).
ASC_NUM_MIN     EQU     $30     * ASCII key for 0
ASC_NUM_MAX     EQU     $39     * ASCII key for 9
ASC_CHAR_MIN    EQU     $41     * ASCII key for A
ASC_CHAR_MAX    EQU     $46     * ASCII key for F

*** Message strings
    * Temporary; used for debugging and testing
NEW_LINE        DC.B    '',0,CR,LF
    * Temporary; used for debugging and testing
DONE_MSG        DC.B    'Done.',0
    * Temporary; used for debugging and testing
COLON_SPACE     DC.B    ': ',0
INVALID_INPUT   DC.B    'Invalid input! Out of Range.',0
END_LTE_BEG     DC.B    'Invalid input! End address is less than or equal to start address.',0  
ADDR_PRMPT_STRT DC.B    'Enter a starting address in hex: $',0
ADDR_PRMPT_END  DC.B    'Enter an ending address in hex: $',0
PRINT_IT_STRING DC.B    'I am a PRINT_IT string. It is printing time!',0
LF              EQU      $0A
CR              EQU      $0D

buffer  DC.L    1

DISM_CODE     EQU     $8000 * Where to write disassembled code
    
    NOP

END_NOW
    LEA     DONE_MSG,A1
    MOVE.B  #1,D0
    TRAP    #15
    LEA     buffer,A1
    
    INCLUDE 'OP.X68'
    END    START        ; last line of source








<<<<<<< Updated upstream
=======


>>>>>>> Stashed changes
*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
