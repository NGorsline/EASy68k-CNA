*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    LEA     buffer,A1
    MOVE.B  #2,D0
    TRAP    #15

    MOVE.B  (A1)+,D1
    SUBI.B  #$37,D1
    
    
    LEA     buffer,A1
    MOVE.B  #13,D0
    TRAP    #15


    SIMHALT             ; halt simulator

* Put variables and constants here

message dc.b    'Hello', 0

buffer  dc.b    80
    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
