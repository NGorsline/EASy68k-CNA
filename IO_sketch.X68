*------------------------------------------------------------------------------|
* Title      :  I/O Module                                                     |
* Written by :  Nicholas Gorsline, Audrey Chae, Clayton Snyder (Team Toucans)  |
* Created    :  5/1/18                                                         |
* Description:  I/O module for the 68k disassembler project. Handles prompting |
*               user for input, getting input, converting input from ASCII to  |
*               raw hex, and serves as the control for program flow.           |
*------------------------------------------------------------------------------|
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    ; A4 will point at where we write disassembled code (use to write ASCII)
    MOVEA.L #DISM_CODE,A4
    ; Jump to logo print
    JSR     PRINT_TOUCAN 
    
GET_INPUT
    JSR     CLEAR_D4D3D2D1
    ; Print the input prompt message and get input as a string from user
    LEA     PROMPT_1,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     PROMPT_2,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     PROMPT_3,A1
    MOVE.B  #13,D0
    TRAP    #15
    
    LEA     ADDR_PRMPT_STRT,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVEA.L  #TEMP_INPUT,A1
    MOVE.B  #2,D0           * get starting address from the user as a string
    TRAP    #15         
    
    ; Check if D1 is valid size, minimum 4 (user entered at least 4 hexa bits)
    CMP     #4,D1           * minimum of a word for the address
    BLT     ERROR_INV_INP   * branch to print the invalid input error msg
    CMP     #6,D1
    BGT     ERROR_INV_INP
    JSR     CONVERSION_LOOP * convert the starting address from ASCII to hex
    
    ; Check if the starting address is out of bounds
    CMP.L   #START_OF_MEM,D2
    BLT     ERROR_OUTSIDE_MEM
    
    ; Check if the starting address is even or odd
    BTST.L  #00,D2
    BNE     ERROR_ODD_START_ADDR
    
    ; Starting address has been converted; store it in A6 and get end address
    MOVEA.L D2,A6           * A6 acts as iterator while disassembling
    CLR.L   D2              * prepare D2 to hold converted end address
    CLR.L   D4              * clear D4 to start the counter at 0 again
    LEA     ADDR_PRMPT_END,A1
    MOVE.B  #14,D0          * prompt user to enter end address
    TRAP    #15
    
    MOVEA.L  #TEMP_INPUT,A1
    MOVE.B  #2,D0           * get end address from user as a string
    TRAP    #15
    
    ; Check if D1 is valid size, minimum 4 (user entered at least 4 hexa bits)
    CMP     #4,D1           * minimum of a word for the address
    BLT     ERROR_INV_INP   * branch to print the invalid input error msg
    CMP     #8,D1
    BGT     ERROR_INV_INP
    JSR     CONVERSION_LOOP * convert the ending address
    
    ; Check to see if end address is inside allotted space
    CMP.L   #END_OF_MEM,D2
    BGT     ERROR_OUTSIDE_MEM
    
    ; Ending address has been converted; store it in A5
    MOVEA.L D2,A5           * compare A6 to A5 to know when to stop
    CMPA.L  A5,A6           * check beginning address >= end address
    BGE     ERROR_END_LTE_BEG
    JSR     INIT_LN
    BRA     MAIN_LOOP       * if all error checks pass, start main loop
    

;; ~~~~~~~~INITIALIZE LINE COUNTER~~~~~~~~
INIT_LN
    MOVE.B  #19,LINE_COUNTER
    RTS
;; ~~~~~~~~END OF INITIALIZE LINE COUNTER~~~~~~~~


;; ~~~~~~~~CLEAR D4 D3 D2 D1 REGISTERS~~~~~~~~
CLEAR_D4D3D2D1
    CLR     D4
    CLR     D3
    CLR     D2
    CLR     D1
    RTS
;; ~~~~~~~~END OF CLEAR D4 D3 D2 D1 REGISTERS~~~~~~~~


;; ~~~~~~~~PRINT TEAM LOGO~~~~~~~~
PRINT_TOUCAN
    LEA     TC00,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC01,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC02,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC03,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC04,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC05,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC06,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC07,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC08,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC09,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC10,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC11,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC12,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC13,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC15,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC16,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     TC17,A1
    MOVE.B  #13,D0
    TRAP    #15
    LEA     NEW_LINE,A1
    MOVE.B  #14,D0
    TRAP    #15
    
    RTS

PRINT_GOODBYE_MSG
    LEA     DONE_MSG,A1
    MOVE.B  #13,D0
    TRAP    #15   
    RTS
    
;; ~~~~~~~~END OF PRINT TEAM LOGO~~~~~~~~


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
    BRA     GET_INPUT
    
ERROR_END_LTE_BEG ;; Prints END_LTE_BEG (end <= beginning) error to console.
    LEA     END_LTE_BEG,A1
    MOVE.B  #13,D0
    TRAP    #15
    BRA     GET_INPUT
    
ERROR_OUTSIDE_MEM
    LEA     OUTSIDE_MEM,A1
    MOVE.B  #13,D0
    TRAP    #15
    BRA     GET_INPUT
    
ERROR_ODD_START_ADDR
    LEA     ODD_ADDR_BD,A1
    MOVE.B  #13,D0
    TRAP    #15
    BRA     GET_INPUT
    
;; ~~~~~~~~END OF ERROR MESSAGES~~~~~~~~
  
  
  
  
;; ~~~~~~~~PRINT MEMORY ADDRESS~~~~~~~~
PRINT_MEM_ADDRESS

    MOVE.L  A6,D3       * Copy current location into working register
    MOVE.B  #$08,D4     * For looping
    
DEC_ADDR_LOOP
    ROL.L   #4,D3       * Rotate 4 bits to front of register
    MOVE.L  #ADR_PR_MASK,D2
    AND.L   D3,D2
    
    CMP.B   #$0A,D2     * Checking to see if the current hexabit is num or letter
    BGE     IS_A_F     
IS_0_9
    ADDI.B  #$30,D2
    BRA     CONT_CONV
IS_A_F
    ADDI.B  #$37,D2
CONT_CONV               * Continue conversion
    MOVE.B  D2,(A4)+ 
    SUBI.B  #$01,D4     * Subtract one from loop counter
    CMP     #$0,D4      * Check if we are at 0 (MAKE SURE NOT OFF BY ONE ERROR), probably is
    BNE     DEC_ADDR_LOOP
    JSR     ADD_SPACES  * Adding spaces
    RTS                 * Return back to main loop
    
ADD_SPACES
    MOVE.B #11,D4       * Counter for loop, adding 12 spaces
ADD_SP_LOOP             * Adding space loop

    MOVE.B  #$20,(A4)+  * Writing to memory
    SUBI.B  #$1,D4      * Dec loop
    CMP.B   #$0,D4      * Checking to see if finished with loop
    BNE     ADD_SP_LOOP
    RTS                 * Returb back to print mem address
    

;; ~~~~~~~~END OF PRINT MEMORY ADDRESS~~~~~~~~




;; ~~~~~~~~OPCODE PRINTED COUNTER~~~~~~~~
CHECK_LINES_PRINTED
    SUBI.B  #1,LINE_COUNTER
    MOVE.B  LINE_COUNTER,D0
    CMP.B   #00,D0
    BEQ     WFI
    RTS 
    
;; ~~~~~~~~END OF OPCODE PRINTED COUNTER~~~~~~~~

;; ~~~~~~~~WAIT FOR INOUT~~~~~~~~
WFI
    LEA     ENTER_TO_CONT,A1
    MOVE.B  #14,D0
    TRAP    #15             * ask user to hit enter to next page
    LEA     LINE_COUNTER,A1
    MOVE.B  #2,D0
    TRAP    #15

    MOVE.B  #$19,LINE_COUNTER
    RTS
;; ~~~~~~~~END OF WAIT FOR INPUT~~~~~~~~


;; ~~~~~~~~CLEAR REGISTERS~~~~~~~~
CLR_REGISTERS
    CLR.L   D0
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    CLR.L   D4
    CLR.L   D5
    CLR.L   D6
    CLR.L   D7
    MOVEA.L #$00,A0
    MOVEA.L #$00,A1
    MOVEA.L #$00,A2
    MOVEA.L #$00,A3
    MOVEA.L #$00,A4
    MOVEA.L #$00,A5
    MOVEA.L #$00,A6
    
    BRA     START
    
;; ~~~~~~~~END OF CLEAR REGISTERS~~~~~~~~


;; ~~~~~~~~RUN AGAIN~~~~~~~~
RUN_PROGRAM_AGAIN

    LEA     NEW_LINE,A1     * New line for clarity
    MOVE.B  #13,D0
    TRAP    #15
    
    ; Print the message asking if user want to run again
    LEA     RUN_AGAIN_STR,A1
    MOVE.B  #14,D0
    TRAP    #15
    MOVEA.L  #TEMP_INPUT,A1
    MOVE.B  #2,D0           * get response from user as a string
    TRAP    #15
    
    CMP.B   #$59,(A1)       * Check if 'Y'
    BEQ     CLR_REGISTERS
    CMP.B   #$79,(A1)       * Check if 'y'
    BEQ     CLR_REGISTERS
    CMP.B   #$4E,(A1)       * CHeck if 'N'
    BEQ     END_NOW
    CMP.B   #$6E,(A1)       * Check if 'n'
    BEQ     END_NOW
    
    LEA     INV_CONT_MSG,A1 * Invalid input, print message then loop again
    MOVE.B  #13,D0
    TRAP    #15
    
    BRA     RUN_PROGRAM_AGAIN

    
    
;; ~~~~~~~~END OF RUN AGAIN~~~~~~~~

  
; Main loop of the program; Checks if the iterator (A6) is past the ending 
; address (A5). If not, calls the OP module. Once the OP and EA modules have
; finished, they return to this module, which then places a null terminator
; on the buffer. This is necessary because OP and EA modules do not write a 
; null terminator to the buffer, but trap task 13 needs one to know when to
; stop printing. After the line is printed, A4 is copied into A1 to start 
; printing from the next spot in memory where the buffer (A4) writes to.
MAIN_LOOP
    MOVEA.L A4,A1       * Set A1 to point at beginning of next decoded line    
    JSR     PRINT_MEM_ADDRESS
    JSR     OP_DECODE   * Call the OP module, which will read next word
    MOVE.B  #$00,(A4)+  * Write null term at end of freshly decoded line
    MOVE.B  #13,D0      * Trap task 13 prints bytes at A1 until a null term
    TRAP    #15
    CMPA.L  A5,A6       * Need to check if we're at the end of the program first
    BGE     RUN_PROGRAM_AGAIN     * End program loop if iterator is at or past A5 (end addr)
    JSR     CHECK_LINES_PRINTED
    BRA     MAIN_LOOP
    
    * Once the loop exits, print a complete message to the console.
*    LEA     DONE_MSG,A1
*    MOVE.B  #13,D0
*    TRAP    #15
    
    * Branch to checking if the user want to run the program again
    
    

    SIMHALT             ; halt simulator




;; ~~~~~~~~VARIABLES AND CONSTANTS~~~~~~~~

; ASCII constants used in the conversion loop. Subtract these from an ASCII
; character to get the raw hex value (depending on whether digit or a char).
ASC_NUM_MIN     EQU     $30     * ASCII key for 0
ASC_NUM_MAX     EQU     $39     * ASCII key for 9
ASC_CHAR_MIN    EQU     $41     * ASCII key for A
ASC_CHAR_MAX    EQU     $46     * ASCII key for F

START_OF_MEM    EQU     $007000   * The start of where memory can be loaded in
END_OF_MEM      EQU     $0F0000   * The end of where memory can be loaded in

; Masks
ADR_PR_MASK     EQU     %00000000000000000000000000001111

; Variables
LINE_COUNTER    DS.B    * A place to store the data for counting printed lines
TEMP_INPUT      DS.B    * Reset where A1 is pointing when getting input

; Message strings
NEW_LINE        DC.B    '',0,CR,LF
DONE_MSG        DC.B    'Done.',0
INVALID_INPUT   DC.B    'Invalid input! Out of Range.',0
END_LTE_BEG     DC.B    'Invalid input! End address is less than or equal to start address.',0  
PROMPT_1        DC.B    'Please enter hex values between 4-6 characters',0
PROMPT_2        DC.B    'Use uppercase letters if entering hex',0
PROMPT_3        DC.B    'Load program between 7000 and F0000',0
ADDR_PRMPT_STRT DC.B    'Enter a starting address in hex: $',0
ADDR_PRMPT_END  DC.B    'Enter an ending address in hex : $',0
OUTSIDE_MEM     DC.B    'That memory location is outside of the allotted space.',0
PRINT_IT_STRING DC.B    'I am a PRINT_IT string. It is printing time!',0
RUN_AGAIN_STR   DC.B    'Would you like to disassemble another memory image? (y/n): ',0
ODD_ADDR_BD     DC.B    'Starting address cannot be odd. Please only enter even start',0
INV_CONT_MSG    DC.B    'Please enter (y/n) only...',0
ENTER_TO_CONT   DC.B    'Press Enter to continue...',0

LF              EQU      $0A
CR              EQU      $0D

TC00           DC.B '           _ _.-''''''--._       _____',0
TC01           DC.B '        .` `.  ...------.\   |_   _|__  _   _  ___ __ _ _ __  ___ ',0
TC02           DC.B '       / |O :-`   _,.,---"     | |/ _ \| | | |/ __/ _` | `_ \/ __|',0
TC03           DC.B '      .  \   ;--""             | | (_) | |_| | (_| (_| | | | \__ \',0
TC04           DC.B '      | _." (                  |_|\___/ \__,_|\___\__,_|_| |_|___/' ,0
TC05           DC.B '      ,. _," `-.',0
TC06           DC.B '      : /       ".',0
TC07           DC.B '      \ \         "',0
TC08           DC.B '       `.|         `.             __    ___  _    ',0
TC09           DC.B '         `-._        \           / /_  ( _ )| | __',0
TC10           DC.B '             ".  ,-.  \         | `_ \ / _ \| |/ /',0
TC11           DC.B ' .__          _`.\..`\ \        | (_) | (_) |   < ',0
TC12           DC.B ' ,  ""- . _,-".,-"  ``: \        \___/ \___/|_|\_\',0
TC13           DC.B ' "-...._ (( (("-.._    \ \          disassembler',0
TC14           DC.B '        `--..      `"-. \ \ ',0
TC15           DC.B '             `..     "   \ \',0
TC16           DC.B '                `\ \/     `"',0
TC17           DC.B '                  \ \ ',0

DISM_CODE       EQU     $F0000     * Where to write disassembled code
    
    NOP                         * Ensures included files align on word boundary

END_NOW
    BRA     PRINT_GOODBYE_MSG
    MOVE.B  #09,D0
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
*~Font size~14~
*~Tab type~1~
*~Tab size~4~
