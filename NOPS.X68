*-----------------------------------------------------------
* Title      : NOPs
* Written by : Clayton Snyder, Audrey Chae (Toucans)
* Date       : 5/19/2018
* Description: Testing file for 68k disassembler
*-----------------------------------------------------------
    ORG    $0300
START:                  ; first instruction of program
    *JSR HAI
HAI
    NOP
    MOVE.B  D2,D4
    MOVE.L  D0,D5
    MOVE.W  D3,D7
    NOP
    NOP
    NOP
    NOP
    NOP
    MOVE.B  D1,D1
    MOVE.B  D5,D4
    MOVE.B  D7,D2
    
    
    
    
    
    *MOVE.B  D2,D4
*    SUBI.B  #$11,D5
*    CLR     D5
*    RTS
*    LEA	$DC00FF00,A2
*    MOVEQ   #$FF,D7
*    
*    CMP.W   #$1111,D2
*    BGT     HAI
*    CMP.W   #$1111,D2
*    BLE     HAI
*    CMP.W   #$1111,D2
*    BCC     HAI  
*    MOVE.B  D2,D3
*    MOVE.L  D3,D4
*    MOVE.W  D4,D5
*    *MOVEA.W (A2),A3
*    *MOVEA.L (A2),A5
*    NOP
*    NOP
*    NOP
    
    END    START        ; last line of source





*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
