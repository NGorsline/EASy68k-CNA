*-----------------------------------------------------------
* Title      : NOPs
* Written by : Clayton Snyder, Audrey Chae (Toucans)
* Date       : 5/19/2018
* Description: Testing file for 68k disassembler
*-----------------------------------------------------------
    ORG    $0300
START:                  ; first instruction of program
    JSR HAI
HAI
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    RTS
    NOP
    NOP
    JSR HAI
    RTS
    NOP
    NOP
    NOP
    
    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
