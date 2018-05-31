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
      MOVEA.W A1,A2
      MOVEA.L (A3)+,A4
      MOVEA.L -(A5),A6
      NOP
      MOVE.B  D1,D1
      MOVE.B  D5,D4
      MOVE.B  D7,D2
    

      SUBI.B  #$11,D5
      CMP.B   #$11,D0
      CLR.B   D5
      CLR.W   D2
      CLR.L   D3
      
          * ADD
      ADD.B       D3,-(A4)
      ADD.B       -(A4),D3
      ADD.W       D2,D1
      ADD.L       A2,D3
      ADD.B       $ABCD,D1
      ADD.W       $EFAB,D2
      ADD.L       D3,$CD00
    
    * SUB
      SUB.B       D4,-(A5)
      SUB.W       D6,D7
      SUB.L       (A5)+,D6
      SUB.W       $ABCD,D6
      SUB.B       $ABCD,D1
      SUB.W       $EFAB,D2
      SUB.L       $CDEF,D3
      SUB.W       D1,$FC00
    
      * MULS, MULU, DIVU
      MULU.W      -(A2),D3
      MULU.W      (A4)+,D5
      DIVU.W      $0300,D5
      DIVU.W      $8010,D5
      DIVU.W      (A6)+,D7
      DIVU.W      -(A6),D5
      DIVU.W      (A4),D3
      DIVU.W      $1234,D2
      MULS.W      (A2),D1
      MULS.W      -(A2),D3
      MULS.W      (A4)+,D5
      MULS.W      $5678,D5

      MOVEM.W D1,$0000
      MOVEM.L D2,$0001
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
      
      AND.B   D2,D1
      AND.W   D1,D3
      AND.L   D1,D2

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



    NOP
    NOP
    NOP
    
    END    START        ; last line of source









*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
