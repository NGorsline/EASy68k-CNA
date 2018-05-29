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
    
    
    
    
    
    MOVE.B  D2,D4
    SUBI.B  #$11,D5
    CMP.B   #$11,D0
    CLR     D5
    RTS
    LEA	$DC00FF00,A2
    MOVEQ   #$FF,D7
   
    CMP.W     D1,D2
    BGT     HAI
    CMP.L     D1,D2
    BLE     HAI
    CMP.B     D1,D2
    BCC     HAI  
    MOVE.B  D2,D3
    MOVE.L  D3,D4
    MOVE.W  D4,D5
    DIVU.W  D3,D5
    MOVEA.W (A2),A3
    MOVEA.L (A2),A5
    OR.B    D1,D2
    OR.W    D2,D3
    OR.L    D3,D1
    ADD.B   D2,D3
    ADD.W   D3,D1
    ADD.L   D3,D2
    ADDA.W  A2,A4
    ADDA.L  A4,A3

    SUB.B   D2,D3
    SUB.W   D3,D1
    SUB.L   D3,D2

    AND.B   D2,D1
    AND.W   D1,D3
    AND.L   D1,D2

    MULS.W  D2,D4
    MULU.W  D1,D3

    LSL.B   D1,D2
    LSL.W   D2,D3
    LSL.L   D3,D4

    LSR.B   D1,D2
    LSR.W   D2,D3
    LSR.L   D3,D4

    ASL.B   D1,D2
    ASL.W   D2,D3
    ASL.L   D3,D4

    ASR.B   D1,D2
    ASR.W   D2,D3
    ASR.L   D3,D4

    ROL.B   D1,D2
    ROL.W   D2,D3
    ROL.L   D3,D4

    ROR.B   D1,D2
    ROR.W   D2,D3
    ROR.L   D3,D4
    * SUBI.B  #$11,D5         *this should give an invalid address error after SUBI.B until EA is fixed 
    * SUBI.W  #$1111,D5
    * SUBI.L  #$11111111,D5
    * ADDI.B  #$11,D5
    * ADDI.W  #$1111,D5
    * ADDI.L  #$11111111,D5


    NOP
    NOP
    NOP
    
    END    START        ; last line of source








*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
