*-----------------------------------------------------------
* Title      :  Disassembler I/O 
* Written by :  Audrey Chae, Nicholas Gorsline, Clayton Snyder (Team Toucans)
* Date       :  5/1/18
* Description:  I/O module for the 68k disassembler project. Handles prompting
*               user for input, getting input, converting input from ASCII to
*               raw hex, and serves as the control for program flow.
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here

    ; A4 will point at where we write disassembled code (use to write ASCII)
    MOVEA.L #DISM_CODE,A4
    
    ; Print the input prompt message and get input as a string from user
    LEA     ADDR_PRMPT_STRT,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.B  #2,D0           * get starting address from the user as a string
    TRAP    #15         
    
    ; Check if D1 is valid size, minimum 4 (user entered at least 4 hexa bits)
    CMP     #4,D1           * minimum of a word for the address
    BLT     ERROR_INV_INP   * branch to print the invalid input error msg
    JSR     CONVERSION_LOOP * convert the starting address from ASCII to hex

    ; Starting address has been converted; store it in A6 and get end address
    MOVEA.L D2,A6           * A6 acts as iterator while disassembling
    CLR.L   D2              * prepare D2 to hold converted end address
    CLR.L   D4              * clear D4 to start the counter at 0 again
    LEA     ADDR_PRMPT_END,A1
    MOVE.B  #14,D0          * prompt user to enter end address
    TRAP    #15
    
    MOVE.B  #2,D0           * get end address from user as a string
    TRAP    #15
    
    ; Check if D1 is valid size, minimum 4 (user entered at least 4 hexa bits)
    CMP     #4,D1           * minimum of a word for the address
    BLT     ERROR_INV_INP   * branch to print the invalid input error msg
    JSR     CONVERSION_LOOP * convert the ending address
    
    ; Ending address has been converted; store it in A5
    MOVEA.L D2,A5           * compare A6 to A5 to know when to stop
    CMPA.L  A5,A6           * check beginning address >= end address
    BGE     ERROR_END_LTE_BEG
    BRA     MAIN_LOOP       * if all error checks pass, start main loop
    




;; ~~~~~~~~BEGINNING OF CONVERSION SUBROUTINE~~~~~~~~
CONVERSION_LOOP       
    MOVE.B  (A1)+,D3        * Store the next byte to convert in D3

CHECK_NUM_MIN     ;; Checks if number is >= 30 (0) in ASCII
    CMP     #ASC_NUM_MIN,D3 * Range of ASCII numbers: [2F,3A] then subtract 30
    BGE     CHECK_NUM_MAX   * check if it's in range for x > 2F
    BRA     ERROR_INV_INP   * First condition not met, go to bad input error 
    
CHECK_NUM_MAX     ;; Checks if number is <= 39 (9) in ASCII
    CMP     #ASC_NUM_MAX,D3
    BLE     ASC_TO_NUM      * If condition for the range was met, do the math
    JMP     CHECK_CHAR_MIN  * Second condition not met, check if a character
    
CHECK_CHAR_MIN    ;; Checks if number is >= 41 (A) in ASCII
    CMP     #ASC_CHAR_MIN,D3
    BGE     CHECK_CHAR_MAX  
    BRA     ERROR_INV_INP   * First condition not met, go to bad input error
    
CHECK_CHAR_MAX    ;; Checks if number is <= 46 (F) in ASCII
    CMP     #ASC_CHAR_MAX,D3
    BLE     ASC_TO_CHAR     * Condition was met for A-F
    BRA     ERROR_INV_INP   * Greater than 46 = out of 16-bit system
    
ASC_TO_NUM        ;; Converts a string digit into a hex value
    SUBI.B  #$30,D3
    JMP     SHIFTS          * After routine is finished, complete shifts/adds
    
ASC_TO_CHAR       ;; Converts a string character into a hex value
    SUBI.B  #$37,D3    
    JMP     SHIFTS
    
SHIFTS            ;; Shifts D2 left to make room for converted hexabit
    LSL.L   #4,D2           * shift hexabit left to make room
    ADD.B   D3,D2           * Add modified value from D3 into D2.
    
    ADD.B   #1,D4           * Increment counter by 1
    CMP     D4,D1           * Check if end of input reached (D4 = counter)
    BNE     CONVERSION_LOOP * Continue back to the loop if D4 != D1  
    RTS
;; ~~~~~~~~END OF CONVERSION SUBROUTINE~~~~~~~~




;; ~~~~~~~~ERROR MESSAGES~~~~~~~~
ERROR_INV_INP ;; Prints the INVALID_INPUT error message to the console
    LEA     INVALID_INPUT,A1
    MOVE.B  #13,D0
    TRAP    #15
    BRA     END_NOW
    
ERROR_END_LTE_BEG ;; Prints END_LTE_BEG (end <= beginning) error to console.
    LEA     END_LTE_BEG,A1
    MOVE.B  #13,D0
    TRAP    #15
    BRA     END_NOW
;; ~~~~~~~~END OF ERROR MESSAGES~~~~~~~~
  
  
  
; Main loop of the program; Checks if the iterator (A6) is past the ending 
; address (A5). If not, calls the OP module. Once the OP and EA modules have
; finished, they return to this module, which then places a null terminator
; on the buffer. This is necessary because OP and EA modules do not write a 
; null terminator to the buffer, but trap task 13 needs one to know when to
; stop printing. After the line is printed, A4 is copied into A1 to start 
; printing from the next spot in memory where the buffer (A4) writes to.
MAIN_LOOP
    CMPA.L  A5,A6
    BGE     END_NOW     * End program if iterator is at or past A5 (end addr)
    JSR     OP_DECODE   * Call the OP module, which will read next word
    MOVE.B  #$00,(A4)+  * Write null term at end of freshly decoded line
    MOVE.B  #13,D0      * Trap task 13 prints bytes at A1 until a null term
    TRAP    #15
    MOVEA.L A4,A1       * Set A1 to point at beginning of next decoded line
    ;;; NICK -- I think you could put logic for printing 10 at a time here.
    BRA     MAIN_LOOP
    
    * Once the loop exits, print a farewell message to the console.
    LEA     DONE_MSG,A1
    MOVE.B  #13,D0
    TRAP    #15

    SIMHALT             ; halt simulator




;; ~~~~~~~~VARIABLES AND CONSTANTS~~~~~~~~

; ASCII constants used in the conversion loop. Subtract these from an ASCII
; character to get the raw hex value (depending on whether digit or a char).
ASC_NUM_MIN     EQU     $30     * ASCII key for 0
ASC_NUM_MAX     EQU     $39     * ASCII key for 9
ASC_CHAR_MIN    EQU     $41     * ASCII key for A
ASC_CHAR_MAX    EQU     $46     * ASCII key for F

; Message strings
NEW_LINE        DC.B    '',0,CR,LF
DONE_MSG        DC.B    'Done.',0
INVALID_INPUT   DC.B    'Invalid input! Out of Range.',0
END_LTE_BEG     DC.B    'Invalid input! End address is less than or equal to start address.',0  
ADDR_PRMPT_STRT DC.B    'Enter a starting address in hex: $',0
ADDR_PRMPT_END  DC.B    'Enter an ending address in hex: $',0
PRINT_IT_STRING DC.B    'I am a PRINT_IT string. It is printing time!',0
LF              EQU      $0A
CR              EQU      $0D

DISM_CODE     EQU     $8000     * Where to write disassembled code
    
    NOP                         * Ensures included files align on word boundary

END_NOW
    LEA     DONE_MSG,A1
    MOVE.B  #1,D0
    TRAP    #15
   
    
    INCLUDE 'OP.X68'
    
    NOP                         * Ensures included files align on word boundary
    
    INCLUDE 'EA.X68'
    
    END    START        ; last line of source












;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~ deprecated code ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; ~~~ Below here is code that is no longer used, but is being saved in     ~~~
;; ~~~ case we need it later, or in case we want to reference it later.     ~~~
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



;; ~~~~~~~~BEGINNING OF PRINT LOOP~~~~~~~~   
* PRINT_IT          ;; Placeholder for now; just prints all data between start and end
*     LEA     PRINT_IT_STRING,A1
*     MOVE.B  #13,D0
*     TRAP    #15
    
* PRINT_IT_LOOP
*     MOVE.B  #15,D0  * Trap task 15 to print a signed number in the base in D2
*     MOVE.B  #16,D2  * Base 16 for the next two TRAPs
*     * PRINT THE CURRENT ADDRESS
*     MOVE.L  A6,D1
*     TRAP    #15
*     CLR.L   D1          * clear D1 so that it holds just the data on the next print
    
*     LEA     COLON_SPACE,A1
*     MOVE.B  #14,D0
*     TRAP    #15
    
*     MOVE.L  (A6)+,D1    * move the data at the pointer into D1 and increment.
*     MOVE.B  #15,D0      * Trap task 15 to print a signed number in the base in D2
*     TRAP    #15
    
*     * Print a new line
*     LEA     NEW_LINE,A1
*     MOVE.B  #13,D0
*     TRAP    #15
    
*     * Check if end address has been reached
*     CMP.L   A5,A6
*     BLE     PRINT_IT_LOOP
;; ~~~~~~~~END OF PRINT LOOP~~~~~~~~


*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
