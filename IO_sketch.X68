*-----------------------------------------------------------
* Title      :  Disassembler I/O 
* Written by :  touCANs
* Date       :  5/1/18 - 
* Description:  I/O functionality for the disassembler 
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    LEA     buffer,A1       * Load buffers affective address into A1
    MOVE.B  #2,D0           * takes in value as a string 
    TRAP    #15         
    
*** Need to first check if D1 is a valid size of minimum 4 
    CMP     #4,D1       
    BLT     ERROR_1         * invalid start address  
*    ADDI.B  #1,D4           * offset our counter to start at 1
 
READING_LOOP       
    MOVE.B  (A1)+,D3        * store the next thingy B
*** Need to check for proper hex conversion 
RANGE_1
    CMP     #$2F,D3         * Range of numbers: (2F >= 3A) then subtract 30    
    BGT     SEC_COND        * check if it's in range for x > 2F
    BRA     ERROR_1         * First condition not met, go to bad input error     
SEC_COND                    * Second condition for Range_1 checking
    CMP     #$3A,D3
    BLT     MATH_DIGITS     * If condition for the range was met, do the math
    JMP     RANGE_2         * Second condition was not met, jump to second check 
RANGE_2
    CMP     #$41,D3
    BGE     SEC_COND_2  
    BRA     ERROR_1         * First condition not met, D3 < 41 = symbols. Go to bad input error
SEC_COND_2
    CMP     #$46,D3
    BLE     MATH_HEX        * Condition was met for A-F     
    BRA     ERROR_1         * Greater than 46 = out of 16-bit system
MATH_DIGITS                 * Convert a string digit into a hex value
    SUBI.B  #$30,D3
    JMP     SHIFTS          * After this routine is finished, complete shifts/adds
MATH_HEX                    * Convert a string character into a hex value
    SUBI.B  #$37,D3    
    JMP     SHIFTS          * Convert a string character into a hex value
SHIFTS                      * Instructions for shifting data into correct register
    LSL.L   #4,D2           * Initial value in D2 shifted hexabit over to the left to make room   
    ADD.B   D3,D2           * Add modified value from D3 into D2.
    
    ADD.B   #1,D4           * Increment counter by 1 
    CMP     D4,D1           * Check if we have already reached the end of the input. D4 = counter
    BNE     READING_LOOP    * Continue back to the loop if D4 != D1  
   
    BRA     END_NOW         * Temporary way of preventing Error_1 from being executed every time
ERROR_1                     * invalid start address   
    LEA     INVALID_INPUT,A1
    MOVE.B  #13,D0
    TRAP    #15

    SIMHALT             ; halt simulator

* Put variables and constants here

INVALID_INPUT DC.B  'Invalid input! Out of Range',0
buffer  DC.L    1
END_NOW
    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
