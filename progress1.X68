*********************************************************************************
* Method Name: identifyOPCODE
* Description:    attempts to decode an opcode by first examining the first nibble, then branching off to identify opcode
*
* Preconditions:  A6 should contain the location of the opcode word
* Postconditions: TBD
*********************************************************************************
identifyOPCODE:
		MOVE.W (A6),D3 *move opcode to D3
		
        CMP.W RTS,D3 *check if the OP is rts
        BEQ dRTS
        
        AND.W isolateNibbleMask,D3 *isolate nibble by clearing the rest of the bits
        
        * check the first nibble and jump to the proper jumptable for that prefix
        CMP.W chk0000,D3
        BEQ ident0000
        CMP.W chk0100,D3
        BEQ ident0100
        CMP.W chk0101,D3
        BEQ ident0101
        CMP.W chk0110,D3
        BEQ ident0110
        CMP.W chk1000,D3
        BEQ ident1000
        CMP.W chk1001,D3
        BEQ ident1001
        CMP.W chk1011,D3
        BEQ ident1011
        CMP.W chk1100,D3
        BEQ ident1100
        CMP.W chk1101,D3
        BEQ ident1101

*TODO add case for MOVEA/MOVE        
                
ident0000
		* is this ORI/CMPI/BCLR
		
		JMP data

ident0100
		* is this NEG/RTS/JRS/MOVEM/LEA
		
		JMP data

ident0101
		* is this SUBQ
		
		JMP data

ident0110
		* is this BRA
		
		JMP data

ident1000
		* is this DIVS/OR
		
		JMP data

ident1001
		* is this SUB
		
		JMP data

ident1011
		* is this EOR/CMP
		
		JMP data

ident1100
		* is this MULS
		
		JMP data

ident1101
		* is this ADD/ADDA
		
		JMP data

dRTS
		*this is RTS
		
		JMP endIdent		
dORI
		*this is ORI
		
		JMP endIdent
dCMPI
		*this is CMPI
		
		JMP endIdent		
dBCLR
		*this is BCLR
		
		JMP endIdent
dNEG
		*this is NEG
		
		JMP endIdent
dJRS
		*this is JRS
		
		JMP endIdent		
dMOVEM
		*this is MOVEM
		
		JMP endIdent
dLEA
		*this is LEA
		
		JMP endIdent		
dSUBQ
		*this is SUBQ
		
		JMP endIdent
dBRA
		*this is BRA
		
		JMP endIdent
dDIVS
		*this is DIVS
		
		JMP endIdent
dOR
		*this is OR
		
		JMP endIdent
dSUB
		*this is SUB
		
		JMP endIdent
dEOR
		*this is EOR
		
		JMP endIdent
dCMP
		*this is CMP
		
		JMP endIdent
dMULS
		*this is MULS
		
		JMP endIdent
dADD
		*this is ADD
		
		JMP endIdent
dADDA
		*this is ADDA
		
		JMP endIdent		
		
data 
		*print DATA
		
		JMP endIdent

endIdent        
        RTS

RTS					DC.W %0100111001110101
JSRMASK				DC.W %0100111010000000

chk0000				DC.W %0000000000000000
chk0100				DC.W %0100000000000000
chk0101				DC.W %0101000000000000
chk0110				DC.W %0110000000000000
chk1000				DC.W %1000000000000000
chk1001				DC.W %1001000000000000
chk1011				DC.W %1011000000000000
chk1100				DC.W %1100000000000000
chk1101				DC.W %1101000000000000



testOPCODE			DC.W %0101111110010101

isolateNibbleMask   DC.W %1111000000000000

TESTSTARTADDRESS	EQU $00004000
TESTENDADDRESS		EQU	$00005000
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
