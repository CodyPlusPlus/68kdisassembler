*--------------------------------------------------------------------------
* Title      : Disassembler Skeleton
* Written by : Cody Stuck
* Date       :
*
* Description: This code contains a method for you to use
* with your Disassembler project IO, and a short demo of
* how to call this method in the body of the "START" code.
*
* Hints and Tips:
*   -Follow the code commenting convention here for file & method headers
*   -Don't rename this file name (Main.X68)
*   -Don't reorg the start address ($1000)
*   -Don't rename or edit the IO method I've provided you with here
*   -Don't rename the config.cfg file or change the file format:
*    <Long_StartAddress>\CR\LF
*    <Long_EndAddress>\CR\LF<EOF>
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
    LEA MSG1, A1        ; buffer of chars to write
    JSR TrapTask13

    LEA MSG2, A1        ; buffer of chars to write
    JSR TrapTask13

    **************************************************
    *Your disassembler code goes here
    **************************************************

    LEA testOPCODE,A6
    JSR identifyOPCODE

    ;Open config.cfg (trap subtasks 50-59) (this is an IO responsibility if 3 team members)
    ;load start and end address as longs

    ;loop from start to end, printing out the instruction or DATA if not recognized
    ;   use my method below (printStringToFileAndConsole) to print out the individual instruction (or DATA)

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
* Method Name: yourDisassemblerSecondMethodHere
* Description:    TBA
*
* Preconditions:  TBA
* Postconditions: TBA
*********************************************************************************
method2:
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
* Description:    attempts to decode an opcode by first examining the first nibble,
*                 then branching off to identify opcode
*
* Preconditions:  A6 should contain the location of the opcode word
* Postconditions: TBD
*********************************************************************************
identifyOPCODE:
		MOVE.W (A6),D3 *move opcode to D3

        CMP.W RTS,D3 *check if the OP is rts
        BEQ dRTS

        CMP.W NOP,D3 *check if the OP is NOP
        BEQ dNOP

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
        JMP data

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
dNOP
		*this is NOP

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

*********************************************************************************
********************************* EA Section ************************************
*********************************************************************************


*********************************************************************************
* Method Name:    decodeEA
* Description:    * Decodes the 6 bits of the EA field of the instruction. After
*                   Finding and adding the proper text to the buffer, it sets the
*                   Good/bad flag and goes back to the calling function.
*
* Preconditions:  * D6 Should contain the 6 bits from EA field of opcode, within
*                   The first byte.
*                 * A6 should contain the pointer to the next word after opcode.
*                 * A7 Should contain the pointer to the next space in good buffer.
*                 * D7 should contain the good/bad flag.
*
* Postconditions: * Sets the memory pointer to the next word after EA at A6.
*                 * Sets the pointer to next available space in good buffer at A7.
*                 * Sets the good/bad flag at D6.
*********************************************************************************
decodeEA:
        MOVE.B D6,D5                           *Bit mask the 3 bits in the middle
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
        *TODO: Write proper data to buffer, and set flag.
        JMP endEaDecode

* For decoding Dn
decodeDn
        *TODO: Write proper data to buffer, and set flag.
        JMP endEaDecode

* For decoding (Ad)
decodeAd
        *TODO: Write proper data to buffer, and set flag.
        JMP endEaDecode

* For decoding (Ad)+
decodeAd_Increment
        *TODO: Write proper data to buffer, and set flag.
        JMP endEaDecode

*For decoding -(Ad)
decodeAd_Decrement
        *TODO: Write proper data to buffer, and set flag.
        JMP endEaDecode

*For finding out which of the ((xxx).w and (xxx).l and immediate.) were referenced.
decode111
        MOVE.B D6,D5                          *Bitmask to select the last 6 bits.
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
        *TODO: Write proper data to buffer, and set flag.
        JMP endEaDecode

*For decoding (xxx).L
decodeAbs_Long
        *TODO: Write proper data to buffer, and set flag.
        JMP endEaDecode

*For decoding immediate.
decodeImmediate
        *TODO: Write proper data to buffer, and set flag.
        JMP endEaDecode

*If none of the valid modes were detetected, it comes here.
invalidEA
        *TODO: Set the invalid flag.
        JMP endEaDecode

*All the sections come here after the execution of their codes.
endEaDecode
        RTS

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

RTS					DC.W %0100111001110101
JSRMASK				DC.W %0100111010000000
NOP					DC.W %0100111001110001

* I/O Variables.
*Variables go here.

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


testOPCODE			DC.W %0101111110010101

isolateNibbleMask   DC.W %1111000000000000

TESTSTARTADDRESS	EQU $00004000
TESTENDADDRESS		EQU	$00005000

   END    START        ; last line of source





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
