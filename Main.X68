*--------------------------------------------------------------------------
* Title      : Disassembler (Some Assembly Required)
* Written by : Cody Stuck, ___, Natallia Ustsiamchuk
* Date       :
*
* Description: This code contains a method for you to use
* with your Disassembler project IO, and a short demo of
* how to call this method in the body of the "START" code.
*
* Hints and Tips:
*   -Follow the code commenting convention here for file & method headers
*   -Don't rename this file name (Main.X68)
*   -Don't r g the start address ($1000)
*   -Don't rename or edit the IO method I've provided you with here
*   -Don't rename the config.cfg file or change the file format:
*    <Long_StartAddress>\CR\LF
*    <Long_En ress>\CR\LF<EOF>
*---------------------------------------------------------------------------
    ORG    $1000    *Don't change this; see hints and tips above
*---------------------------------------------------------------------------
START:

    ***********************************************************
    * Code demo for printing strings to console & file is here
    * Pay close attention to:
    *   (1) the detailed comments,
    *   (2) how to build a (Callee-Saved) method
    *   (3) how to call that method using JSR (return with RTS)
    ***********************************************************
    *LEA MSG1, A1        ; buffer of chars to write
    *JSR TrapTask13

    *LEA MSG2, A1        ; buffer of chars to write
    *JSR TrapTask13
    
    *LEA ascii_val, A1
    *JSR AsciiToHex     ;  example of how to convert ascii to hex
    
    **************************************************
    *Your disassembler code goes here
    **************************************************


    MOVE.B #%00111001, D7
    JSR rotateModeReg

    MOVEA #opcodebuff, A6
    MOVE.L #$1234ABCD, (A6)
    MOVEA #printbuff,A5
    JSR decodeEA
    MOVE.B #0,(A5)
    MOVEA #printbuff,A1
    JSR TrapTask13

    *LEA testOPCODE,A6
    *MOVEA #printbuff,A5
    *JSR identifyOPCODE
    *MOVE.B #0,(A5)
    *MOVEA #printbuff,A1
    *JSR TrapTask13

    *LEA testOPCODE,A6
    *MOVEA #printbuff,A5
    *JSR identifyOPCODE
    *MOVE.B #0,(A5)
    *MOVEA #printbuff,A1
    *JSR TrapTask13

    ;Open config.cfg (trap subtasks 50-59) (this is an IO responsibility if 3 team members)
    ;load start and end address as longs
    
    *IO
    LEA         inputFile,A1        *Load the file
    MOVE        #51,D0              *Open the file
    TRAP        #15
     
    LEA         good_buffer,A1      *Precondition for trap 53
    MOVE.L      #startaddr,D2       *number of bytes to read   
    MOVE.L      #53,D0              *Reading a file 
    TRAP        #15
    JSR         AsciiToHex          *Convern to hex
    MOVE.L      D0,D2               *starting address hex value is moved to be stored longterm in D2
    
    MOVEA.L     #0,A1               *Clear registry
    
    *how to read second line in the file ???
    MOVE.L      #startaddr,D2       *number of bytes to read   
    MOVE.L      #53,D0              *Reading a file 
    TRAP        #15


    *JSR         AsciiToHex          *Convern to hex
    *MOVE.L      D0,D3              *ending address hex value is moved to be stored longterm in D3
    
    

    ;loop from start to end, printing out the instruction or DATA if not recognized
    ;   use my method below (printStringToFileAndConsole) to print out the individual instruction (or DATA)


*still working on this 
IO_INVALID: 
        *Display DATA YYYY
    LEA         DATA_OUT,A1 


    SIMHALT

*********************************************************************************
* Method Name: yourDisassemblerFirstMethodHere
* Description: call this method from your code above; see the examples above on
*   how to call methods and use them profusely as you build your final project
*
* Preconditions:  TBA
* Postconditions: TBA
*********************************************************************************
method1:
        NOP
        RTS

*********************************************************************************
********************************* I/O Section ***********************************
*********************************************************************************

*Code goes here


*********************************************************************************
******************************* OP Code Section *********************************
*********************************************************************************


*********************************************************************************
* Method Name: identifyOPCODE
* Description:    Attempts to decode an opcode by first examining the first nibble,
*                 then branching off to identify opcode
*
* Preconditions:  A6 should contain the pointer to the opcode.
*                 A5 Should contain the pointer to the next space in good buffer.
*                 D6 should contain the good/bad flag.
*
* Postconditions: A5 will contain the pointer to the next space in the good buffer
*                 D6 will contain the good/bad flag
*                 D7 will contain mode and register bits
*
* MODIFIES:       D3
*********************************************************************************
identifyOPCODE:

*****IDENTIFY FIRST NIBBLE*****
		MOVE.W (A6),D3 *move opcode to D3

        CMP.W RTS,D3 *check if the OP is rts
        BEQ dRTS

		CMP.W RESET,D3 *check if the OP is RESET
		BEQ dRESET

        CMP.W NOP,D3 *check if the OP is NOP
        BEQ dNOP

        AND.W isolateNibbleMask,D3 *isolate nibble by clearing the rest of the bits

        * check the first nibble and jump to the proper jumptable for that prefix
        CMP.W chk0000,D3 *0000
        BEQ ident0000
        CMP.W chk0100,D3 *0100
        BEQ ident0100
        CMP.W chk0101,D3 *0101
        BEQ ident0101
        CMP.W chk0110,D3 *0110
        BEQ ident0110
        CMP.W chk1000,D3 *1000
        BEQ ident1000
        CMP.W chk1001,D3 *1001
        BEQ ident1001
        CMP.W chk1011,D3 *1011
        BEQ ident1011
        CMP.W chk1100,D3 *1100
        BEQ ident1100
        CMP.W chk1101,D3 *1101
        BEQ ident1101
        CMP.W chk0001,D3 *MOVE_A.B
        BEQ identMOVE_A
        CMP.W chk0011,D3 *MOVE_A.W
        BEQ identMOVE_A
        CMP.W chk0010,D3 *MOVE_A.L
        BEQ identMOVE_A
        CMP.W chk1110,D3 *SHIFT/ROTATE OP
        BEQ identREGMEM
        JMP ddata         *data


*****IDENTIFY OPCODE FROM NIBBLE*****

ident0000 * is this ORI/CMPI/BCLR
		MOVE.W (A6),D3 *move the full opcode back into D3

		* ORI?
		AND.W ORIISO,D3 *clear irrelevant bits
		CMP.W #ORICHK,D3 *compare to identity
		BEQ dORI *match?
		MOVE (A6),D3 *move the full opcode back into D3

		* CMPI?
		AND.W CMPIISO,D3 *clear irrelevant bits
		CMP.W CMPICHK,D3 *compare to identity
		BEQ dCMPI *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* BCLR?
		AND.W BCLRISO,D3 *clear irrelevant bits
		CMP.W BCLRCHK,D3 *compare to identity
		BEQ dBCLR *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		JMP ddata *could not identify

ident0100 * is this NEG/RTS/JSR/MOVEM/LEA
		MOVE.W (A6),D3 *move the full opcode back into D3

		*RTS has already been checked

		* NEG?
		AND.W NEGISO,D3 *clear irrelevant bits
		CMP.W NEGCHK,D3 *compare to identity
		BEQ dNEG *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* JSR?
		AND.W JSRISO,D3 *clear irrelevant bits
		CMP.W JSRCHK,D3 *compare to identity
		BEQ dJSR *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* MOVEM?
		AND.W MOVEMISO,D3 *clear irrelevant bits
		CMP.W MOVEMCHK,D3 *compare to identity
		BEQ dMOVEM *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* LEA?
		AND.W LEAISO,D3 *clear irrelevant bits
		CMP.W LEACHK,D3 *compare to identity
		BEQ dLEA *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		JMP ddata *could not identify

ident0101 * is this SUBQ
		MOVE.W (A6),D3 *move the full opcode back into D3

		* SUBQ?
		AND.W SUBQISO,D3 *clear irrelevant bits
		CMP.W SUBQCHK,D3 *compare to identity
		BEQ dSUBQ *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		JMP ddata *could not identify

ident0110 * is this BRA/BCS/BGE/BLT/BVC
		MOVE.W (A6),D3 *move the full opcode back into D3

		* BRA?
		AND.W BCCISO,D3 *clear irrelevant bits
		CMP.W BRACHK,D3 *compare to identity
		BEQ dBRA *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* BCS?
		AND.W BCCISO,D3 *clear irrelevant bits
		CMP.W BCSCHK,D3 *compare to identity
		BEQ dBCS *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* BGE?
		AND.W BCCISO,D3 *clear irrelevant bits
		CMP.W BGECHK,D3 *compare to identity
		BEQ dBGE *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* BLT?
		AND.W BCCISO,D3 *clear irrelevant bits
		CMP.W BLTCHK,D3 *compare to identity
		BEQ dBLT *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* BVC?
		AND.W BCCISO,D3 *clear irrelevant bits
		CMP.W BVCCHK,D3 *compare to identity
		BEQ dBVC *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		JMP ddata *could not identify

ident1000 * is this DIVS/OR
		MOVE.W (A6),D3 *move the full opcode back into D3

        * DIVS?
		AND.W DIVSISO,D3 *clear irrelevant bits
		CMP.W DIVSCHK,D3 *compare to identity
		BEQ dDIVS *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* assume OR
		JMP dOR

		JMP ddata *could not identify

ident1001 * is this SUB
		MOVE.W (A6),D3 *move the full opcode back into D3

		* assume SUB
		JMP dSUB

		JMP ddata *could not identify

ident1011 * is this EOR/CMP
		MOVE.W (A6),D3 *move the full opcode back into D3

		* EOR?
		AND.W EORISO,D3 *clear irrelevant bits
		CMP.W EORCHK,D3 *compare to identity
		BEQ dEOR *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* assume CMP
		JMP dCMP

		JMP ddata

ident1100 * is this MULS
		MOVE.W (A6),D3 *move the full opcode back into D3

		* MULS?
		AND.W MULSISO,D3 *clear irrelevant bits
		CMP.W MULSCHK,D3 *compare to identity
		BEQ dMULS *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		JMP ddata *could not identify

ident1101 * is this ADD/ADDA
		MOVE.W (A6),D3 *move the full opcode back into D3

		AND.W ADDAISO,D3 *clear irrelevant bits
		CMP.W ADDACHK,D3 *compare to identity
		BEQ dADDA *match?
		MOVE.W (A6),D3 *move the full opcode back into D3

		* assume ADD
		JMP dADD

		JMP ddata

identMOVE_A *is this MOVE/MOVEA
		MOVE.W (A6),D3

		* MOVEA?
		AND.W MOVEAISO,D3 *clear irrelevant bits
		CMP.W MOVEACHK,D3 *compare to identity
		BEQ dMOVEA

		* ASSUME MOVE
		JMP dMOVE

identREGMEM *is this a register or memory shift/rotate
		MOVE.W (A6),D3

		* mem?
		AND.W SHIFTROTMEMCHK,D3 *clear irrelevant bits
		CMP.W SHIFTROTMEMCHK,D3 *compare to identity
		BEQ identSHIFTROTMEM

		* ASSUME REG
		JMP identSHIFTROTREG

identSHIFTROTMEM
		MOVE.W (A6),D3

		*ASD?
		AND.W MEMSHIFTORROTISO,D3
		CMP.W MEMASDCHK,D3
		BEQ dMEM_ASD

		*LSD?
		AND.W MEMSHIFTORROTISO,D3
		CMP.W MEMLSDCHK,D3
		BEQ dMEM_LSD

		*ROD?
		AND.W MEMSHIFTORROTISO,D3
		CMP.W MEMRODCHK,D3
		BEQ dMEM_ROD

		JMP ddata

identSHIFTROTREG
		MOVE.W (A6),D3

		*ASD?
		AND.W REGSHIFTORROTISO,D3
		CMP.W REGASDCHK,D3
		BEQ dREG_ASD

		*LSD?
		AND.W REGSHIFTORROTISO,D3
		CMP.W REGLSDCHK,D3
		BEQ dREG_LSD

		*ROD?
		AND.W REGSHIFTORROTISO,D3
		CMP.W REGRODCHK,D3
		BEQ dREG_ROD

		JMP ddata

*****OPCODE IDENTIFIED*****

* EA notes:
*       Functions to call:
*
*       For instructions with:  xxx <immediate>, Xn
*           JSR IncreaseOpPtr
*           JSR setSrcModeReg
*           JSR printImdData
*           JSR printComma
*           JSR decodeEA
*
*       For instructions with:  xxx An, Xn
*           JSR IncreaseOpPtr
*           JSR setSrcModeReg
*           JSR printAn
*           JSR printComma
*           JSR decodeEA
*
*       For instructions with:  xxx Dn, Xn
*           JSR IncreaseOpPtr
*           JSR setSrcModeReg
*           JSR printDn
*           JSR printComma
*           JSR decodeEA
*
*       For instructions with:  xxx An, Xn
*           JSR IncreaseOpPtr
*           JSR setSrcModeReg
*           JSR printAn
*           JSR printComma
*           JSR decodeEA
*
*       For instructions with:  xxx Xn, Xn (Only MoveM)
*           JSR IncreaseOpPtr
*           JSR setSrcModeReg
*           JSR rotateModeReg
*           JSR decodeEA
*           JSR printComma
*           JSR decodeEA

dMEM_ASD *this is mem ASD

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'A',(A5)+
		MOVE.B #'S',(A5)+

		JSR identDIRECTION

		JMP endIdent

dMEM_LSD *this is mem LSD

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'L',(A5)+
		MOVE.B #'S',(A5)+

		JSR identDIRECTION

		JMP endIdent

dMEM_ROD *this is mem ROD

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'R',(A5)+
		MOVE.B #'O',(A5)+

		JSR identDIRECTION

		JMP endIdent

dREG_ASD *this is reg ASD

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'A',(A5)+
		MOVE.B #'S',(A5)+

		JSR identDIRECTION
		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dREG_LSD *this is reg LSD

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'L',(A5)+
		MOVE.B #'S',(A5)+

		JSR identDIRECTION
		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dREG_ROD *this is reg ROD

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'R',(A5)+
		MOVE.B #'O',(A5)+

		JSR identDIRECTION
		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dMOVEA *this is MOVEA

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'M',(A5)+
		MOVE.B #'O',(A5)+
		MOVE.B #'V',(A5)+
		MOVE.B #'E',(A5)+
		MOVE.B #'A',(A5)+

		JMP identifyMOVE_ASIZE

		JMP endIdent

dMOVE *this is MOVE

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'M',(A5)+
		MOVE.B #'O',(A5)+
		MOVE.B #'V',(A5)+
		MOVE.B #'E',(A5)+

		JMP identifyMOVE_ASIZE

		JMP endIdent

dRTS *this is RTS

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'R',(A5)+
		MOVE.B #'T',(A5)+
		MOVE.B #'S',(A5)+

		JMP endIdent

dNOP *this is NOP

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'N',(A5)+
		MOVE.B #'O',(A5)+
		MOVE.B #'P',(A5)+

		JMP endIdent

dORI *this is ORI

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'O',(A5)+
		MOVE.B #'R',(A5)+
		MOVE.B #'I',(A5)+

		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dCMPI *this is CMPI

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'C',(A5)+
		MOVE.B #'M',(A5)+
		MOVE.B #'P',(A5)+
		MOVE.B #'I',(A5)+

		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dBCLR *this is BCLR

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'B',(A5)+
		MOVE.B #'C',(A5)+
		MOVE.B #'L',(A5)+
		MOVE.B #'R',(A5)+

		JMP endIdent

dNEG *this is NEG

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'N',(A5)+
		MOVE.B #'E',(A5)+
		MOVE.B #'G',(A5)+

		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dJSR *this is JSR

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'J',(A5)+
		MOVE.B #'S',(A5)+
		MOVE.B #'R',(A5)+

		JMP endIdent

dMOVEM *this is MOVEM

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'M',(A5)+
		MOVE.B #'O',(A5)+
		MOVE.B #'V',(A5)+
		MOVE.B #'E',(A5)+
        MOVE.B #'M',(A5)+

        *find and append size
        JSR identMOVEMSIZE

		JMP endIdent

dLEA *this is LEA

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'L',(A5)+
		MOVE.B #'E',(A5)+
		MOVE.B #'A',(A5)+

		JMP endIdent

dSUBQ *this is SUBQ

        *add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'S',(A5)+
		MOVE.B #'U',(A5)+
		MOVE.B #'B',(A5)+
		MOVE.B #'Q',(A5)+

		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dBRA *this is BRA

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'B',(A5)+
		MOVE.B #'R',(A5)+
		MOVE.B #'A',(A5)+

		JMP endIdent

dBCS *this is BCS

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'B',(A5)+
		MOVE.B #'C',(A5)+
		MOVE.B #'S',(A5)+

		JMP endIdent

dBGE *this is BGE

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'B',(A5)+
		MOVE.B #'G',(A5)+
		MOVE.B #'E',(A5)+

		JMP endIdent

dBLT *this is BTL

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'B',(A5)+
		MOVE.B #'T',(A5)+
		MOVE.B #'L',(A5)+

		JMP endIdent

dBVC *this is BVC

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'B',(A5)+
		MOVE.B #'V',(A5)+
		MOVE.B #'C',(A5)+

		JMP endIdent

dDIVS *this is DIVS

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'D',(A5)+
		MOVE.B #'I',(A5)+
		MOVE.B #'V',(A5)+
		MOVE.B #'S',(A5)+

		JMP endIdent

dOR *this is OR

        *add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'O',(A5)+
		MOVE.B #'R',(A5)+

		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dSUB *this is SUB

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'S',(A5)+
		MOVE.B #'U',(A5)+
		MOVE.B #'B',(A5)+

		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dEOR *this is EOR

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'E',(A5)+
		MOVE.B #'O',(A5)+
		MOVE.B #'R',(A5)+

		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dCMP *this is CMP

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'C',(A5)+
		MOVE.B #'M',(A5)+
		MOVE.B #'P',(A5)+

		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dMULS *this is MULS

        *add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'M',(A5)+
		MOVE.B #'U',(A5)+
		MOVE.B #'L',(A5)+
		MOVE.B #'S',(A5)+

		JMP endIdent

dADD *this is ADD

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'A',(A5)+
		MOVE.B #'D',(A5)+
		MOVE.B #'D',(A5)+

		JSR identifyOPSIZE *identify size of operation and add to buffer

		JMP endIdent

dADDA *this is ADDA

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'A',(A5)+
		MOVE.B #'D',(A5)+
		MOVE.B #'D',(A5)+
		MOVE.B #'A',(A5)+

		JSR identADDAsize

		JMP endIdent

ddata *this must be data

		*print DATA here maybe?
		MOVE.B #1,D6 *set bad flag

		JMP endIdent

dRESET *this is RESET

		*add to buffer
		MOVE.B #' ',(A5)+
		MOVE.B #'R',(A5)+
		MOVE.B #'E',(A5)+
		MOVE.B #'S',(A5)+
		MOVE.B #'E',(A5)+
		MOVE.B #'T',(A5)+

		JMP endIdent

endIdent
        RTS
*********************************************************************************
* Method Name: identMOVEMSIZE
* Description:    adds the size of the MOVEM operation to the buffer
*
* Preconditions:  A5 Should contain the pointer to the next space in good buffer.
*			      A6 should contain the pointer to the opcode
*
* Postconditions: A5 will contain the pointer to the next space in the good buffer
*				  the size of the operation will be appended to the buffer
*
* MODIFIES:       D3
*********************************************************************************
identMOVEMSIZE:
		MOVE (A6),D3 *move the full opcode back into D3
		AND.W MOVEMSIZECHK,D3
		CMP.W MOVEMSIZECHK,D3
		BEQ dMOVEML
		JMP dMOVEMW

dMOVEMW
		*add to buffer
		MOVE.B #'.',(A5)+
		MOVE.B #'W',(A5)+

		JMP endidentMOVEMSIZE

dMOVEML
		*add to buffer
		MOVE.B #'.',(A5)+
		MOVE.B #'L',(A5)+

		JMP endidentMOVEMSIZE

endidentMOVEMSIZE

		RTS
*********************************************************************************
* Method Name: identDIRECTION
* Description:    adds the direction of the shift/rotation to the buffer
*
* Preconditions:  A5 Should contain the pointer to the next space in good buffer.
*			      A6 should contain the pointer to the opcode
*
* Postconditions: A5 will contain the pointer to the next space in the good buffer
*				  the size of the operation will be appended to the buffer
*
* MODIFIES:       D3
*********************************************************************************
identDIRECTION:
		MOVE (A6),D3 *move the full opcode back into D3
		AND.W DIRECTIONCHK,D3
		CMP.W DIRECTIONCHK,D3
		BEQ dirLEFT
		JMP dirRIGHT

dirRIGHT
		*add to buffer
		MOVE.B #'R',(A5)+

		JMP endidentDIRECTION

dirLEFT
		*add to buffer
		MOVE.B #'L',(A5)+

		JMP endidentDIRECTION

endidentDIRECTION

		RTS
*********************************************************************************
* Method Name: identADDAsize
* Description:    adds the size of the ADDA op to the buffer
*
* Preconditions:  A5 Should contain the pointer to the next space in good buffer.
*			      A6 should contain the pointer to the opcode
*
* Postconditions: A5 will contain the pointer to the next space in the good buffer
*				  the size of the operation will be appended to the buffer
*
* MODIFIES:       D3
*				  D5
************************************************,*********************************
identADDAsize:
		MOVE (A6),D3 *move the full opcode back into D3
		AND.W ADDASIZECHK,D3
		CMP.W ADDASIZECHK,D3
		BEQ ADDAL
		JMP ADDAW
ADDAW
		JSR addWbuff
		JMP endidentADDAsize

ADDAL
		JSR addLbuff
		JMP endidentADDAsize

endidentADDAsize

		RTS

*********************************************************************************
* Method Name: addBbuff
* Description:    adds B to buff
*
* Preconditions:  A5 Should contain the pointer to the next space in good buffer.
*
* Postconditions: A5 will contain the pointer to the next space in the good buffer
*				  .B will be added to the buffer
*                 D5 will contain the number of bytes that were last identified.
*
* MODIFIES:       A5
*                 D5
*********************************************************************************
addBbuff:
	    *add to buffer
		MOVE.B #'.',(A5)+
		MOVE.B #'B',(A5)+

        *Set the D5 to the number of bytes.
        MOVE.B #1, D5

		RTS

*********************************************************************************
* Method Name: addWbuff
* Description:    adds W to buff
*
* Preconditions:  A5 Should contain the pointer to the next space in good buffer.
*
* Postconditions: A5 will contain the pointer to the next space in the good buffer
*				  .B will be added to the buffer
*                 D5 will contain the number of bytes that were last identified.
*
* MODIFIES:       A5
*                 D5
*********************************************************************************
addWbuff:
	    *add to buffer
		MOVE.B #'.',(A5)+
		MOVE.B #'W',(A5)+

        *Set the D5 to the number of bytes.
        MOVE.B #2, D5

		RTS

*********************************************************************************
* Method Name: addLbuff
* Description:    adds L to buff
*
* Preconditions:  A5 Should contain the pointer to the next space in good buffer.
*
* Postconditions: A5 will contain the pointer to the next space in the good buffer
*				  .L will be added to the buffer
*                 D5 will contain the number of bytes that were last identified.
*
* MODIFIES:       A5
*                 D5
*********************************************************************************
addLbuff:
	    *add to buffer
		MOVE.B #'.',(A5)+
		MOVE.B #'L',(A5)+

        *Set the D5 to the number of bytes.
        MOVE.B #4, D5

		RTS
*********************************************************************************
* Method Name: identifyOPSIZE
* Description:    Determines the size of the operation decoded and appends it to the printstream
*
* Preconditions:  A5 Should contain the pointer to the next space in good buffer.
*                 A6 should contain the pointer to the opcode
*
* Postconditions: A5 will contain the pointer to the next space in the good buffer
*                 The size of the operation will be appended to the printbuffer ('.B','.W','L')
*                 D6 bad flag will be set if size cannot be determined
*
* MODIFIES:       D3
*********************************************************************************

*****IDENTIFY SIZE*****
identifyOPSIZE:

decodesize

        * byte?
        MOVE.W (A6),D3 *move opcode into D3
        AND.W SIZEISO, D3 *isolate size bits
        CMP.W BSIZECHECK,D3 *is this byte?
        BEQ dBYTE

        * word?
        MOVE.W (A6),D3 *move opcode into D3
        AND.W SIZEISO, D3 *isolate size bits
        CMP.W WSIZECHECK,D3 *is this word?
        BEQ dWORD

        * long?
        MOVE.W (A6),D3 *move opcode into D3
        AND.W SIZEISO, D3 *isolate size bits
        CMP.W LSIZECHECK,D3 *is this long?
        BEQ dLONG

        * size could not be determined
        JMP sizeidenterror

*****SIZE IDENTIFIED*****

dBYTE *this is byte

        *add to buffer
		JSR addBbuff

        JMP endidentsize

dWORD *this is word

        *add to buffer
		JSR addWbuff

        JMP endidentsize

dLONG *this is looong

        *add to buffer
		JSR addLbuff

        JMP endidentsize

sizeidenterror

        MOVE.B #1,D6

endidentsize

        RTS

*********************************************************************************
* Method Name: identifyMOVE_ASIZE
* Description:    Determines the size of the MOVE_A operation and appends it to the printstream
*
* Preconditions:  A5 Should contain the pointer to the next space in good buffer.
*                 A6 should contain the pointer to the opcode
*
* Postconditions: A5 will contain the pointer to the next space in the good buffer
*                 The size of the operation will be appended to the printbuffer ('.B','.W','L')
*                 D6 bad flag will be set if size cannot be determined
*
* MODIFIES:       D3
*********************************************************************************

*****IDENTIFY SIZE*****
identifyMOVE_ASIZE:

        * byte?
        MOVE.W (A6),D3 *move opcode into D3
        AND.W MOVE_A_SIZEISO, D3 *isolate size bits
        CMP.W MOVE_A_BSIZECHECK,D3 *is this byte?
        BEQ dMOVE_ABYTE

        * word?
        MOVE.W (A6),D3 *move opcode into D3
        AND.W MOVE_A_SIZEISO, D3 *isolate size bits
        CMP.W MOVE_A_WSIZECHECK,D3 *is this word?
        BEQ dMOVE_AWORD

        * long?
        MOVE.W (A6),D3 *move opcode into D3
        AND.W MOVE_A_SIZEISO, D3 *isolate size bits
        CMP.W MOVE_A_LSIZECHECK,D3 *is this long?
        BEQ dMOVE_ALONG

        * size could not be determined (this should not happen.)
        JMP MOVE_Asizeidenterror

*****SIZE IDENTIFIED*****

dMOVE_ABYTE * this is BYTE

        *add to buffer
		JSR addBbuff

        JMP endMOVE_Aidentsize

dMOVE_AWORD * this is WORD

        *add to buffer
		JSR addWbuff

        JMP endMOVE_Aidentsize

dMOVE_ALONG * this is LONG

        *add to buffer
		JMP addLbuff

        JMP endMOVE_Aidentsize

MOVE_Asizeidenterror

		MOVE.B #1,D6

endMOVE_Aidentsize

		RTS

*********************************************************************************
******************************* Pre-EA Section **********************************
*********************************************************************************

*********************************************************************************
* Method Name:    setDestModeReg (For Destination)
* Description:    * Extracts the 6 bits needed from the OpCode and puts it in D7
*                   It is used to put the bits needed in D7 to run the EA decoding.
*
* Preconditions:  * A6 should contain the pointer to the next word after opcode.
*
* Postconditions: * Sets the first byte of D7 to the bits (9-16) of the opcode.
*
* Modifies:       * D7
*********************************************************************************
setDestModeReg:
        MOVE.W -(A6), D7
        JSR IncreaseOpPtr
        RTS

*********************************************************************************
* Method Name:    setSrcModeReg (For Source)
* Description:    * Extracts the 6 bits needed from the OpCode and puts it in D7
*                   It is used to put the bits needed in D7 to run the EA decoding.
*
* Preconditions:  * A6 should contain the pointer to the next word after opcode.
*
* Postconditions: * Sets the first byte of D7 to the bits (3-10) of the opcode.
*
* Modifies:       * D7
*********************************************************************************
setSrcModeReg:
        MOVE.W -(A6), D7
        ROR.W #6, D7
        JSR IncreaseOpPtr
        RTS

*********************************************************************************
* Method Name:    IncreaseOpPtr
* Description:    * Increases the opcode pointer by 1 word. (Makes it point
*                   either to the next opcode or the immediate data).
*
* Preconditions:  * A6 should contain the pointer to the opcode.
*
* Postconditions: * A6 will get increased by 2 bytes.
*
* Modifies:       * A6
*********************************************************************************
IncreaseOpPtr:
        ADD.W #2, A6
        RTS

*********************************************************************************
* Method Name:    printComma
* Description:    * Prints a comma into the output buffer.
*
* Preconditions:  * A5 should contain a pointer to the good buffer.
*
* Postconditions: * A5 will contain a byte which is the ASCII value of a comma.
*
* Modifies:       * A5
*********************************************************************************
printComma:
        MOVE.B #',', (A5)+
        RTS


*********************************************************************************
********************************* EA Section ************************************
*********************************************************************************
dataRegsToSave REG D0-D5

*********************************************************************************
* Method Name:    printAn (For Src)
* Description:    * Prints the value defined in 6th, 5th, and 4th bits of the
*                   byte defined in D7 (Only prints after Ax without checking mode).
*
* Preconditions:  * D7 Should contain 6 bits right before the EA mode/reg bits.
*                 * A6 should contain the pointer to the next word after opcode.
*                 * A5 Should contain the pointer to the next space in good buffer.
*                 * D6 should contain the good/bad flag.
*
* Postconditions: * Sets the pointer to next available space in good buffer at A5.
*                 * Sets the good/bad flag at D6.
*
* Modifies:       * D6
*                 * A5
*                 * A6
*********************************************************************************
printAn:
        MOVEM.L dataRegsToSave, -(SP)         *Save the status of the registers.
        JSR rotateModeReg                     *Get the D7 ready for decoding (rotate)
        JSR decodeAn                          *Decode, print and come back here.
        RTS

*********************************************************************************
* Method Name:    printDn (For Src)
* Description:    * Prints the value defined in 6th, 5th, and 4th bits of the
*                   byte defined in D7 (Only prints after Dx without checking mode).
*
* Preconditions:  * D7 Should contain 6 bits right before the EA mode/reg bits.
*                 * A6 should contain the pointer to the next word after opcode.
*                 * A5 Should contain the pointer to the next space in good buffer.
*                 * D6 should contain the good/bad flag.
*
* Postconditions: * Sets the memory pointer to the next word after Immediate at A6.
*                 * Sets the pointer to next available space in good buffer at A5.
*                 * Sets the good/bad flag at D6.
*
* Modifies:       * D6
*                 * A5
*                 * A6
*********************************************************************************
printDn:
        MOVEM.L dataRegsToSave, -(SP)         *Save the status of the registers.
        JSR rotateModeReg                     *Get the D7 ready for decoding (rotate)
        JSR decodeDn                          *Decode, print and come back here.
        RTS

*********************************************************************************
* Method Name:    printImdData (For Src)
* Description:    * Checks the register D5 to see what was the last set size value
*                   (D5 = 1 means a byte, D5 = 2 means a word, D5 = 4 means a long)
*                   Then it calls the appropriate printImdData subroutine.
*
* Preconditions:  * A6 should contain the pointer to the next word after opcode.
*                 * A5 Should contain the pointer to the next space in good buffer.
*                 * D5 should contain the number of bytes which should be read
*                   In the immmediate data.
*
* Postconditions: * Sets the memory pointer to the next word after Immediate at A6.
*                 * Sets the pointer to next available space in good buffer at A5.
*
* Modifies:       * A5
*                 * A6
*********************************************************************************
printImdData:
        CMP.B #1, D5                        *Branch if flag is a byte.
        BEQ printImdData_b

        CMP.B #2, D5                        *Branch if flag is two bytes (Word).
        BEQ printImdData_w

        CMP.B #4, D5                        *Branch if flag is fours bytes (Long).
        BEQ printImdData_l

        RTS

*********************************************************************************
* Method Name:    printImdData_b (For Src)
* Description:    * Reads and Prints the immediate byte data pointed to by the A6
*                   It also increases the pointer to the next field.
*
* Preconditions:  * A6 should contain the pointer to the next word after opcode.
*                 * A5 Should contain the pointer to the next space in good buffer.
*
* Postconditions: * Sets the memory pointer to the next word after Immediate at A6.
*                 * Sets the pointer to next available space in good buffer at A5.
*
* Modifies:       * A5
*                 * A6
*********************************************************************************
printImdData_b:
        MOVEM.L dataRegsToSave, -(SP)         *Save the status of the registers.
        MOVE.B #' ', (A5)+                    *Add data to print buffer.
        MOVE.B #'#', (A5)+
        MOVE.B #'$', (A5)+

        MOVE.B (A6)+, D4                      *Set temp word in d4.
        MOVE.B #0, D3                         *Setup a counter for loop.

loop_decodeImd_b
        CMP.B #2, D3                          *Check if we've read 2 nibbles.
        BEQ loop_decodeImd_b_done
        ROL.W #4, D4                          *Rotate, get the first nibble and store in D4.
        MOVE.B D4, D5
        AND.B firstNibble, D5
        JSR hexToAscii                        *Get the ASCII value.
        MOVE.B D5, (A5)+                      *Add the new ASCII byte to the output.
        ADD.B #1, D3                          *Increase the counter.
        JMP loop_decodeImd_b

loop_decodeImd_b_done
        MOVE.B #' ', (A5)+
        MOVEM.L (SP)+, dataRegsToSave         *Restore the registers.
        RTS

*********************************************************************************
* Method Name:    printImdData_w (For Src)
* Description:    * Reads and Prints the immediate word data pointed to by the A6
*                   It also increases the pointer to the next field.
*
* Preconditions:  * A6 should contain the pointer to the next word after opcode.
*                 * A5 Should contain the pointer to the next space in good buffer.
*
* Postconditions: * Sets the memory pointer to the next word after Immediate at A6.
*                 * Sets the pointer to next available space in good buffer at A5.
*
* Modifies:       * A5
*                 * A6
*********************************************************************************
printImdData_w:
        MOVEM.L dataRegsToSave, -(SP)         *Save the status of the registers.
        MOVE.B #' ', (A5)+                    *Add data to print buffer.
        MOVE.B #'#', (A5)+
        MOVE.B #'$', (A5)+

        MOVE.W (A6)+, D4                      *Set temp word in d4.
        MOVE.B #0, D3                         *Setup a counter for loop.

loop_decodeImd_w
        CMP.B #4, D3                          *Check if we've read 4 nibbles.
        BEQ loop_decodeImd_w_done
        ROL.W #4, D4                          *Rotate, get the first nibble and store in D4.
        MOVE.B D4, D5
        AND.B firstNibble, D5
        JSR hexToAscii                        *Get the ASCII value.
        MOVE.B D5, (A5)+                      *Add the new ASCII byte to the output.
        ADD.B #1, D3                          *Increase the counter.
        JMP loop_decodeImd_w

loop_decodeImd_w_done
        MOVE.B #' ', (A5)+
        MOVEM.L (SP)+, dataRegsToSave         *Restore the registers.
        RTS

*********************************************************************************
* Method Name:    printImdData_w (For Src)
* Description:    * Reads and Prints the immediate long data pointed to by the A6
*                   It also increases the pointer to the next field.
*
* Preconditions:  * A6 should contain the pointer to the next word after opcode.
*                 * A5 Should contain the pointer to the next space in good buffer.
*
* Postconditions: * Sets the memory pointer to the next word after Immediate at A6.
*                 * Sets the pointer to next available space in good buffer at A5.
*
* Modifies:       * A5
*                 * A6
*********************************************************************************
printImdData_l:
        MOVEM.L dataRegsToSave, -(SP)         *Save the status of the registers.
        MOVE.B #' ', (A5)+                    *Add data to print buffer.
        MOVE.B #'#', (A5)+
        MOVE.B #'$', (A5)+

        MOVE.L (A6)+, D4                      *Set temp word in d4.
        MOVE.B #0, D3                         *Setup a counter for loop.

loop_decodeImd_l
        CMP.B #8, D3                          *Check if we've read 8 nibbles.
        BEQ loop_decodeImd_l_done
        ROL.W #4, D4                          *Rotate, get the first nibble and store in D4.
        MOVE.B D4, D5
        AND.B firstNibble, D5
        JSR hexToAscii                        *Get the ASCII value.
        MOVE.B D5, (A5)+                      *Add the new ASCII byte to the output.
        ADD.B #1, D3                          *Increase the counter.
        JMP loop_decodeImd_l

loop_decodeImd_l_done
        MOVE.B #' ', (A5)+
        MOVEM.L (SP)+, dataRegsToSave         *Restore the registers.
        RTS

*********************************************************************************
* Method Name:    rotateModeReg (For Src)
* Description:    * Rotates the mode and register bits. In one byte, it replaces
*                   the first 3 bits with the second 3 bits and vice-versa.
*
* Preconditions:  * First byte of D7 should contain the mode/register bits.
*
* Postconditions: * Overrites D7 with the modified (shifted) value.
*
* Modifies:       * D7
*********************************************************************************
rotateModeReg:
        MOVEM.L dataRegsToSave, -(SP)          *Save the status of the registers.
        MOVE.B D7, D5                          *Save the value of D7 in a temp variable.
        ROL.B #3, D7                           *Rotate one 3 bits to the left, and
        ROR.B #3, D5                           *the other 3 bits to the right.

        AND.B second3Bitmask, D7               *Bitmask to only get the first and second
        AND.B first3Bitmask, D5                *3 bits.

        OR.B D5, D7                            *Or them to get one value.
        MOVEM.L (SP)+, dataRegsToSave          *Restore the registers.
        RTS

*********************************************************************************
* Method Name:    decodeEA (For Dest)
* Description:    * Decodes the 6 bits of the EA field of the instruction. After
*                   Finding and adding the proper text to the buffer, it sets the
*                   Good/bad flag and goes back to the calling function.
*
* Preconditions:  * D7 Should contain the 6 bits from EA field of opcode, within
*                   The first byte.
*                 * A6 should contain the pointer to the next word after opcode.
*                 * A5 Should contain the pointer to the next space in good buffer.
*                 * D6 should contain the good/bad flag.
*
* Postconditions: * Sets the memory pointer to the next word after EA at A6.
*                 * Sets the pointer to next available space in good buffer at A5.
*                 * Sets the good/bad flag at D6.
*
* Modifies:       * D6
*                 * A5
*                 * A6
*********************************************************************************
decodeEA:
        MOVEM.L dataRegsToSave, -(SP)          *Save the status of the registers.
        MOVE.B D7,D5                           *Bit mask the 3 bits in the middle
        AND.B #%00111000, D5

        CMP.B modeAn, D5                       *Check every supported mode based
        BEQ decodeAn                           *on the 3 selected bits.

        CMP.B modeDn, D5
        BEQ decodeDn

        CMP.B  modeAd, D5                      *Branch to proper labels.
        BEQ decodeAd

        CMP.B modeAd_Increment, D5
        BEQ decodeAd_Increment

        CMP.B modeAd_Decrement, D5
        BEQ decodeAd_Decrement

        CMP.B mode111, D5                     *For the last 3 modes more info is needed.
        BEQ decode111                         *so if bits were 111, go to decode111 to decide.

        JMP invalidEA                         *If none of the modes, it would be invalid.

* For decoding An
decodeAn
        MOVE.B D7, D5                         *Bitmask the least significant 3 bits.
        AND.B #%00000111, D5
        JSR hexToAscii                        *Get the ASCII value.

        MOVE.B #' ', (A5)+                    *Add data to print buffer.
		MOVE.B #'A', (A5)+
		MOVE.B D5, (A5)+
        MOVE.B #' ', (A5)+

        JMP endEaDecode

* For decoding Dn
decodeDn
        MOVE.B D7, D5                         *Bitmask the least significant 3 bits.
        AND.B #%00000111, D5
        JSR hexToAscii                        *Get the ASCII value.

        MOVE.B #' ', (A5)+                    *Add data to print buffer.
		MOVE.B #'D', (A5)+
		MOVE.B D5, (A5)+
        MOVE.B #' ', (A5)+

        JMP endEaDecode

* For decoding (Ad)
decodeAd
        MOVE.B D7, D5                         *Bitmask the least significant 3 bits.
        AND.B #%00000111, D5
        JSR hexToAscii                        *Get the ASCII value.

        MOVE.B #' ', (A5)+                    *Add data to print buffer.
        MOVE.B #'(', (A5)+
		MOVE.B #'A', (A5)+
		MOVE.B D5, (A5)+
        MOVE.B #')', (A5)+
        MOVE.B #' ', (A5)+

        JMP endEaDecode

* For decoding (Ad)+
decodeAd_Increment
        MOVE.B D7, D5                         *Bitmask the least significant 3 bits.
        AND.B #%00000111, D5
        JSR hexToAscii                        *Get the ASCII value.

        MOVE.B #' ', (A5)+                    *Add data to print buffer.
        MOVE.B #'(', (A5)+
        MOVE.B #'A', (A5)+
        MOVE.B D5, (A5)+
        MOVE.B #')', (A5)+
        MOVE.B #'+', (A5)+
        MOVE.B #' ', (A5)+
        JMP endEaDecode

*For decoding -(Ad)
decodeAd_Decrement
        MOVE.B D7, D5                         *Bitmask the least significant 3 bits.
        AND.B #%00000111, D5
        JSR hexToAscii                        *Get the ASCII value.

        MOVE.B #' ', (A5)+                    *Add data to print buffer.
        MOVE.B #'-', (A5)+
        MOVE.B #'(', (A5)+
        MOVE.B #'A', (A5)+
        MOVE.B D5, (A5)+
        MOVE.B #')', (A5)+
        MOVE.B #' ', (A5)+
        JMP endEaDecode

*For finding out which of the ((xxx).w and (xxx).l and immediate.) were referenced.
decode111
        MOVE.B D7,D5                          *Bitmask to select the last 6 bits.
        AND.B #%00111111, D5

        CMP.B modeAbs_Word, D5                *Check the remaining modes and
        BEQ decodeAbs_Word                    *Go to their label accordingly.

        CMP.B modeAbs_Long, D5
        BEQ decodeAbs_Long

        CMP.B modeImmediate, D5
        BEQ decodeImmediate

        JMP invalidEA                         *If none of the modes, given mode is invalid.

*For decoding (xxx).W
decodeAbs_Word
        MOVE.B #' ', (A5)+                    *Add data to print buffer.
        MOVE.B #'$', (A5)+

        MOVE.W (A6)+, D4                      *Set temp word in d4.
        MOVE.B #0, D3                         *Setup a counter for loop.

loop_Abs_w
        CMP.B #4, D3                          *Check if we've read 4 nibbles.
        BEQ loop_Abs_w_done
        ROL.W #4, D4                          *Rotate, get the first nibble and store in D4.
        MOVE.B D4, D5
        AND.B firstNibble, D5
        JSR hexToAscii                        *Get the ASCII value.
        MOVE.B D5, (A5)+                      *Add the new ASCII byte to the output.
        ADD.B #1, D3                          *Increase the counter.
        JMP loop_Abs_w

loop_Abs_w_done
        MOVE.B #'.', (A5)+                    *Add the .W at the end.
        MOVE.B #'W', (A5)+
        MOVE.B #' ', (A5)+

        JMP endEaDecode

*For decoding (xxx).L
decodeAbs_Long
        MOVE.B #' ', (A5)+                    *Add data to print buffer.
        MOVE.B #'$', (A5)+

        MOVE.L (A6)+, D4                      *Set temp word in d4.
        MOVE.B #0, D3                         *Setup a counter for loop.

loop_Abs_l
        CMP.B #8, D3                          *Check if we've read 8 nibbles.
        BEQ loop_Abs_l_done
        ROL.L #4, D4                          *Rotate, get the first nibble and store in D4.
        MOVE.B D4, D5
        AND.B firstNibble, D5
        JSR hexToAscii                        *Get the ASCII value.
        MOVE.B D5, (A5)+                      *Add the new ASCII byte to the output.
        ADD.B #1, D3                          *Increase the counter.
        JMP loop_Abs_l

loop_Abs_l_done
        MOVE.B #'.', (A5)+                    *Add the .l at the end.
        MOVE.B #'L', (A5)+
        MOVE.B #' ', (A5)+
        JMP endEaDecode

*For decoding immediate.
decodeImmediate
        MOVE.B #' ', (A5)+                    *Add data to print buffer.
        MOVE.B #'$', (A5)+

        MOVE.W (A6)+, D4                      *Set temp word in d4.
        MOVE.B #0, D3                         *Setup a counter for loop.

loop_Imd
        CMP.B #4, D3                          *Check if we've read 4 nibbles.
        BEQ loop_Imd_done
        ROL.W #4, D4                          *Rotate, get the first nibble and store in D4.
        MOVE.B D4, D5
        AND.B firstNibble, D5
        JSR hexToAscii                        *Get the ASCII value.
        MOVE.B D5, (A5)+                      *Add the new ASCII byte to the output.
        ADD.B #1, D3                          *Increase the counter.
        JMP loop_Imd

loop_Imd_done
        MOVE.B #' ', (A5)+
        JMP endEaDecode

*If none of the valid modes were detetected, it comes here.
invalidEA
        MOVE.B #1, D6                       *Set the bad flag.
        MOVEM.L (SP)+, dataRegsToSave       *Restore the registers.
        RTS

*All the sections come here after the execution of their codes.
endEaDecode
        MOVE.B #0, D6                       *Set the good flag.
        MOVEM.L (SP)+, dataRegsToSave       *Restore the registers.
        RTS

*********************************************************************************
* Method Name:    hexToAscii
* Description:    * converts the nibble (hex) stored in the first byte of
*                   D5 to an ASCII value.
*
* Preconditions:  * First byte of D5 should contain a value between 0-F
*
* Postconditions: * Sets the value in D5 to its corresponding ASCII value.
*                 * Will just return if the number is invalid (>F)
*
* Modifies:       * D5
*********************************************************************************
hexToAscii:
    CMP.B #$F, D5                           *Check for invalid values in the register.
    BGT invalid_number

    CMP.B #10, D5                           *Check if its a digit or a number.
    BLT hex_digit                           *Branch accordingly.
    BPL hex_character

hex_digit
    ADD.B #48, D5                           *Add to get digit ascii value.
    RTS

hex_character                               *Add to get character ascii value.
    ADD.B #55, D5
    RTS

invalid_number                              *Just return if its not valid.
    RTS

*----------------------------------------------------------------------------------
* Method Name: AsciiToHex
* Written by : Berger, Modified by Nash
* Date       : 3/1/2019
* Description: Converts chars '0'-'9' and 'a'-'f' to 0-9,a-F
*              Transforms/unpacks 8 chars (8b each) pointed to by A1 into 
*              its (4b each) equivalent hex value 
*  
*  Preconditions & Input
*       A1 (input) points to a memory buffer holding 8 ascii chars (not null-terminated) 
*       This function calls another function (strip_ascii)
*
*  Postconditions & Output
*       D7 (output) holds the converted value 
*       Caller-Saved : D0 is temp, D6 is a loop var
*----------------------------------------------------------------------------------
AsciiToHexRegList REG D0,D6
AsciiToHex     
    MOVEM.L asciiToHexRegList, -(SP)  *save context
    CLR.L D7 * clear our return value
    MOVE.L #8, D6 ; and set up our loop counter

chrLoop
    MOVE.B (A1)+,D0 * Get the first byte
    jsr strip_ascii * Get rid of the ascii code    
    OR.W D0,D7 * Load the bits into D7
    
    subI.B #1,D6  *decrement our loop variable
    BEQ chrDone   *skip shifting if we are done
    
    ASL.L #4,D7 * shift left 4 bits to prepare for next byte
    BRA chrLoop

chrDone
    MOVEM.L (SP)+,asciiToHexRegList 
    RTS


**********************************************************************
* SUBROUTINE: strip_ascii
* remove the ascii code from the digits 0-9,a-f, or A-F
* Input Parameters: <D0> = ascii code
*
* Return parameters: D0.B = number 0...F, returned as 00...0F
* Registers used internally: D0
* Assumptions: D0 contains $30-$39, $41-$46 or $61-66
*
***********************************************************************
strip_ascii
      CMP.B #$39,D0 * Is it in range of 0-9?
      BLE sub30 * Its a number
      CMP.B #$46,D0 * Is is A...F?
      BLE sub37 * Its A...F
      SUB.B #$57,D0 * Its a...f
      BRA ret_sa * Go back
sub37 SUB.B #$37,D0 * Strip 37
      BRA ret_sa * Go back
sub30 SUB.B #$30,D0 * Strip 30
ret_sa RTS * Go back

*********************************************************************************
*********************** Trap 13, Variables, Constants ***************************
*********************************************************************************


*********************************************************************************
* Method Name: TrapTask13
* Description: Creates a file if none exists, and appends bytes to that file
*   while also echoing the written bytes to the screen.  You shouldn't need to
*   change this code.
*
* Calling Convention: Callee-Saved
*
* Preconditions & Method Input:
*   A1 points to the null-terminated buffer to write (newline will be added for you)
*
* Postconditions & Output:
*   ALL files that were previously open will be CLOSED (FileIDs will be invalid)
*   See 'Output.txt' in directory for the results, also piped to the console
*
*
*  A2 holds a pointer to null terminated string to write (input)
*  A3 points to the null-terminated file name
*  D3 holds the number of bytes already in the file to write
*
*  D5 holds number of bytes to write
********************************************************************************
toSave REG D0-D5/A2-A3
TrapTask13:
    *******************************************************************
    * Method initialization, regsiter spilling, parameter saving, etc.
    *******************************************************************
    MOVEM.L toSave, -(SP)   ;  Callee-Saved, so save and restore

    MOVEA.L A1, A2 ; save this buffer to write
    LEA outFilename, A3  ; save this for later, too

    move #50,d0
    trap #15 ; close all files, suggested to begin any IO
    *******************************************************************
    * End Method Init
    *******************************************************************

    ******************************************************************************************
    * Calculate the number of bytes to write by searching for the null in the target buffer A0
    ******************************************************************************************
    CLR.L D5 *D5 is now the number of bytes to write
nullLoop:
    MOVE.B (A1)+, D0
    CMPI.B #0,D0  * compare to null
    BEQ findNullLoopDone
    ADDI.W #1, D5
    BRA nullLoop

findNullLoopDone:
    MOVEA.L A3, A1 * reset A1 so it points to the file to write to (to open, next)

    ;check if file exists, and open with task 51 if so, otherwise 52
    ;(precondition here is A1 points to the null-terminated filename )
    MOVE.B #51, D0      ;open file (task 51 is existing, 52 is new)
    trap #15

    if.w D0 <NE> #0 then.s         ; if file error (404, not found)
        MOVE.B #52, D0             ; open new file (52 is new)
        trap #15
    endi

    *********************************************************************************************************
    * Seek to END of FILE by counting the number of bytes, closing, reopening, then seeking.
    *    (first, count number of bytes already in the file to obtain seek position)
    *********************************************************************************************************
    Clr.L D3   ;TODO: reg save, D3 is now our count of bytes read
    MOVE.L #1, D2 ; read one byte at a time
    LEA byteRead, A1

countLoop:
    MOVE.B #53, D0 ; try to read one byte (TODO: move out of loop)
    trap #15

    CMPI.W #1,D0  ;1 == EOF
    BEQ countDone
    ADDI #1, D3
    BRA countLoop

countDone:
    * close this file
     move #56,d0
     trap #15

     * reopen the target file
     MOVE.L A3,A1
     MOVE #51, D0
     trap #15

    * seek to right position, then continue with writing
    MOVE.L D3, D2 ; move the number of bytes found in the file to D2
    MOVE #55, D0  ; position file task
    trap #15

    ******************************************************************************
    * Actually write the buffer to the file, after caculating the number of bytes
    *  to write and after seeking to the right location in the file for append
    ******************************************************************************

    MOVE.L D5, D2 ; restore this for the actually writing the buffer
    ; assumes A0 hasnt changed since handed to this method
    MOVEA.L A2, A1 ; load the address of the buffer we want to write to disk
    ; assumes file ID is still stored in D1.L
    MOVE.B #54, D0 ; subtask 54 is write to open file (append, or?), assumes D2 holds # of bytes
    trap #15

    ; add a newline to the file output
    LEA NEWLINE, A1
    MOVE.B #54, D0
    MOVE.B #2,D2  ; kills # of bytes to write from input param
    trap #15

    ; finally, close only this file
    MOVE.B #56, D0 ; close file task
    trap #15

    ; report to screen
    MOVEA.L A2, A1 ; load the address of the buffer we want to write to disk & screen
    MOVE.B #13, D0
    trap #15

    ; restore context
    MOVEM.L (SP)+, toSave

    RTS

* Required variables and constants go here for your Disassembler
CR                  EQU $0D
LF                  EQU $0A
NEWLINE             DC.B CR,LF,0
MSG1                DC.B 'DATA',0
MSG2                DC.B 'NOP',0
outFilename         DC.B 'Output.txt',0
byteRead            DS.B 1
ascii_val           DC.B $31,$41,$30,$30,$31,$41,$30,$30 * Test value $1A001A00

* I/O Variables.
*Variables go here.
printbuff           EQU $4000
opcodebuff          EQU $6000
inputFile           DC.B   'Config.cfg',0
good_buffer         DS.B    100
startaddr           DS.L    64 CR,LF,0
endaddr             DS.L    64 CR,LF,EOD
DATA_OUT            DC.B 'DATA',0      *output message when invalid instruction


* Opcode variables.
chk0000				DC.W %0000000000000000
chk0100				DC.W %0100000000000000
chk0101				DC.W %0101000000000000
chk0110				DC.W %0110000000000000
chk1000				DC.W %1000000000000000
chk1001				DC.W %1001000000000000
chk1011				DC.W %1011000000000000
chk1100				DC.W %1100000000000000
chk1101				DC.W %1101000000000000

chk0001				DC.W %0001000000000000
chk0011				DC.W %0011000000000000
chk0010				DC.W %0010000000000000

chk1110				DC.W %1110000000000000

RTS					DC.W %0100111001110101
JSRMASK				DC.W %0100111010000000
NOP					DC.W %0100111001110001

MOVEAISO			DC.W %0000000111000000
MOVEACHK			DC.W %0000000001000000

ORIISO              DC.W %0000111100000000
ORICHK              DC.W %0000000000000000
CMPIISO             DC.W %0000111100000000
CMPICHK             DC.W %0000110000000000
BCLRISO             DC.W %0000111111000000
BCLRCHK             DC.W %0000100010000000

SUBQISO             DC.W %0000000100000000
SUBQCHK             DC.W %0000000100000000

EORISO           	DC.W %0000000100000000
EORCHK	            DC.W %0000000100000000

BCCISO              DC.W %0000111100000000
BRACHK              DC.W %0000000000000000
BCSCHK				DC.W %0000010100000000
BGECHK				DC.W %0000110000000000
BLTCHK				DC.W %0000110100000000
BVCCHK				DC.W %0000100000000000


MULSISO             DC.W %0000000110000000
MULSCHK             DC.W %0000000111000000

DIVSISO             DC.W %0000000111000000
DIVSCHK             DC.W %0000000111000000

ADDAISO             DC.W %0000000011000000
ADDACHK             DC.W %0000000011000000
ADDASIZECHK			DC.W %0000000100000000

NEGISO              DC.W %0000111100000000
NEGCHK              DC.W %0000010000000000
JSRISO              DC.W %0000111111000000
JSRCHK              DC.W %0000111010000000
MOVEMISO            DC.W %0000101110000000
MOVEMCHK            DC.W %0000100010000000
LEAISO              DC.W %0000000111000000
LEACHK              DC.W %0000000111000000

MOVEMSIZECHK		DC.W %0000000001000000

SIZEISO             DC.W %0000000011000000
BSIZECHECK          DC.W %0000000000000000
WSIZECHECK          DC.W %0000000001000000
LSIZECHECK          DC.W %0000000010000000

MOVE_A_SIZEISO      DC.W %0011000000000000
MOVE_A_BSIZECHECK   DC.W %0001000000000000
MOVE_A_WSIZECHECK   DC.W %0011000000000000
MOVE_A_LSIZECHECK   DC.W %0010000000000000

SHIFTROTMEMCHK		DC.W %0000000011000000

MEMSHIFTORROTISO	DC.W %0000111000000000
REGSHIFTORROTISO	DC.W %0000000000011000

MEMASDCHK			DC.W %0000000000000000
MEMLSDCHK			DC.W %0000001000000000
MEMRODCHK			DC.W %0000011000000000

REGASDCHK			DC.W %0000000000000000
REGLSDCHK			DC.W %0000000000001000
REGRODCHK			DC.W %0000000000011000

DIRECTIONCHK		DC.W %0000000100000000

RESET				DC.W %0100111001110000

testOPCODE          DC.W %0100111001110000


* Ea variables.
modeAn              DC.B %00000000      * An
modeDn              DC.B %00001000      * Dn
modeAd              DC.B %00010000      * (Ad)
modeAd_Increment    DC.B %00011000      * (Ad)+
modeAd_Decrement    DC.B %00100000      * -(Ad)

mode111             DC.B %00111000      * 3 following modes:
modeAbs_Word        DC.B %00111000      * (xxx).W
modeAbs_Long        DC.B %00111001      * (xxx).L
modeImmediate       DC.B %00111100      * Immediate

firstNibble         DC.B %00001111      * For converting from hex.

first3Bitmask       DC.B %00000111      * For mode/reg rotation.
second3Bitmask      DC.B %00111000

* End Ea Variables.
isolateNibbleMask   DC.W %1111000000000000
*TESTSTARTADDRESS	EQU $00004000
*TESTENDADDRESS		EQU	$00005000


   END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~














*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
