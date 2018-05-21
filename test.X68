*****************************
*
*
* Created 2/18/2016
*
* Test program
*
*****************************

start		EQU	$0300	* ORG and END address

* ORG the program so that it straddles the address boundary $00007FFF to $00008000

		ORG	start

* NOP and similar instructions. Should clearly differentiate NOP and RTS from others.

		NOP			*Required
		RTS			*Required
		STOP	#$2000  	* Not required instruction

* This is a group of ADD instructions

add_start	ADDI.W	#$4000,D0	
		
* This is a group of SUB instructions
subtracts	SUBA.W	(A4),A6

* Group is random data

data1		DC.B		$FF,$AA,$45,$0A

* Move instructions

moves		MOVE.B	D0,D1

data5		DC.B	'Here is some interspersed data'
		
* Divide and multiple optional instructions
	
ands		AND.B	#$01,$4568

shifts		ASL.B	D0,D0

rolls		ROL.L	D2,D3

clear		CLR	D4

load_addr	LEA	$DC00FF00,A2

* random data	
		DC.W	2949,0411,2848,7869

compares	CMP.B	(A3),D5

* Branches	
		

* Jump and branch instructions

jmplabel	BCC	compares		
		BGT	compares		
		BLE	compares	
		
*These are not required instructions
multiply	MULS	D0,D3
		DIVU	(A3),D5	*Optional instruction

		END	start









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~8~
