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
    ADDI.B  #$AB,D5
    NOP
    NOP
    RTS
    NOP
    NOP
    JSR HAI
    SUBI.B  #$11,D5
    CLR     D5
    RTS
    LEA	$DC00FF00,A2
    MOVEQ #$FF,D7
    
    CMP.W   #$1111,D2
    BGT     HAI
    CMP.W   #$1111,D2
    BLE     HAI
    CMP.W   #$1111,D2
    BCC     HAI  
    MOVE.B  #$11,D3
    MOVE.L  #$1234FFFF,D4
    MOVE.W  #$1234,D5
    MOVEA.W (A2),A3
    MOVEA.L (A2),A5
    NOP
    NOP
    NOP
    
    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
