// this MUST be run on PRU1
// output pins should be set to mode 0x05 (in proper Command Register location in CortexA8)
// input pins should be set to mode 0x36 (input enabled, pullup enabled, mode 6)


.origin 0
.entrypoint _main

#include "PRU_SPI.hp"

#define DEBUG

// entry point, sets up the PRU memory and begins polling for SPI transactions
_main:
    // set memory start into MEM_START register
    LDI		MEM_START, PRU1_MEMSTART
    // set all cs pins high
    LDI		CS_PINS, 0xFF
//    LDI		ITER, 0
//CSInit:
//    QBEQ	endCSInit, ITER, 7
//    SET		CS_PINS, ITER
//    ADD		ITER, ITER, 1
//    JMP		CSInit
//endCSInit:
    LDI		r20, 0
    SET		r20.t28
ledWait:
    QBEQ	endLEDWait, r20, 0
    SUB		r20, r20, 1
    JMP		ledWait
endLEDWait:
    CLR		CS_PINS, 1

#ifdef DEBUG

    LDI		r21, 0		// count transactions

_loadBogusData:
    LDI		TRANS_BUF_START.b0, 0x21	// read command
    LDI		TRANS_BUF_START.b1, 0x02	// I2C clock
    LDI		TRANS_BUF_START.b2, 0x44	// junk
    LDI		TRANS_BUF_START.b3, 0x00	// space
    LDI		TRANS_TOTAL, 4			// 4 bytes
    LDI		SPEED_MHZ, 1			// 1MHz
    LDI		r1.b0, 2			// MODE_2
    SET		r1.t31				// set ready bit
    LDI		r3, 0
    NOT		r3, r3
    XOUT	SCRATCH_1, r1, 12		// move r1, r2 to scratch pad

_resetCP2120:
    // reset CP2120 by setting RESET low for at least 15us
    CLR		CS_PINS, 7
    SET		CS_PINS, 1		//LED on
    LDI		ITER, 5000		// 25us
holdReset:
    QBEQ	endReset, ITER, 0
    SUB		ITER, ITER, 1
    JMP		holdReset
endReset:
    SET		CS_PINS, 7
    CLR		CS_PINS, 1		// LED off

#endif



// if ready bit is one, there is a transaction waiting
// this also indicates to the other core that a transaction
// is in progress, preventing the register from being overwritten
poll:
    XIN		SCRATCH_1, r1, 4
    QBBC	poll, READY_BIT


////////////////////////////////////////////////////////////
// _spi_setup:
// gets the information from the other PRU core and loads
// it into this PRU's registers and memory to prepare for
// the spi transaction, then selects the correct transaction
// function based on the mode.
////////////////////////////////////////////////////////////
_spi_setup:
    // get information from info register and store locally
    XIN		SCRATCH_1, r1, 4
    // R1 now contains the SPI transfer information
    MOV		MODE_REG, r1.b0		// move the value of mode and deviceID into the mode register
    LSR		ID_REG, MODE_REG, 2	// put the device id into its own byte
    AND		MODE_REG, MODE_REG, 0b11	// clear the upper 6 bits of the mode byte 
    XIN		SCRATCH_1, TRANS_BUF_START, TRANS_MAX    // load scratch pad data into PRU registers
    SBBO	TRANS_BUF_START, MEM_START, 0, TRANS_MAX   // then store it into PRU memory
    QBEQ	no_speed, SPEED_MHZ, 0	// prevent accidental infinite loop if speed is set to zero
    LDI		TEMP_BYTE, PRU_CLOCK_MHZ	
    LDI		ITER, 0			// count subtractions
div_by_sub:
    QBGE	cycles, TEMP_BYTE, 0
    SUB		TEMP_BYTE, TEMP_BYTE, SPEED_MHZ
    ADD		ITER, ITER, 1
    JMP		div_by_sub
cycles:
    MOV		CYCLES_TO_WAIT, ITER		// we have determined how many PRU cycles per clock cycle
    SUB		CYCLES_TO_WAIT, CYCLES_TO_WAIT, 40	// subtract built-in wait
    LSR		CYCLES_TO_WAIT, CYCLES_TO_WAIT, 1	// div by 2
    QBEQ	_mode0, MODE_REG, 0
    QBEQ	_mode1, MODE_REG, 1
    QBEQ	_mode2, MODE_REG, 2
    QBEQ	_mode3, MODE_REG, 3
no_speed:
end_transaction:
    LBBO	TRANS_BUF_START, MEM_START, 0, TRANS_MAX
    XOUT	SCRATCH_1, TRANS_BUF_START, TRANS_MAX
    LDI		r1, 0			// clear setup register
    XOUT	SCRATCH_1, r1, 4	// write setup register
    ADD		r21, r21, 1
    LDI		r20, 0
    NOT		r20, r20
    SBBO	r20, MEM_START, 64, 4
    JMP		poll			// wait for a new transaction

////////////////////////////////////////////////////////////
// _byteTransition:
// store the full RX_BYTE into the current byte in memory,
// then move to and load the next byte in memory,
// resetting the iterator to 7 (to handle MSB)
////////////////////////////////////////////////////////////
_byteTransition:
    // store the current received byte
    SBBO	RX_BYTE, MEM_START, TRANS_COUNTER, 1
    // move to next byte
    ADD		TRANS_COUNTER, TRANS_COUNTER, 1		// move to next byte
    LBBO	TX_BYTE, MEM_START, TRANS_COUNTER, 1  // load next byte	
    LDI		BIT_ITER, 7	// BIT_ITER = 7
    JMP		RET_ADDR	// return


////////////////////////////////////////////////////////////
// _waitLong:
// occurs after all the operations in a normal clock cycle
// 	when a byteTransition is not occurring.
// this wait adds an additional 9 PRU cycles to the
// 	short wait
////////////////////////////////////////////////////////////
_waitLong:  // assume we have started with 8 cycles used
    NOOP				//1
    LDI		ITER, 2			//2
waitLongLoop:
    QBEQ	_waitShort, ITER, 0	//3,6,9
    SUB		ITER, ITER, 1		//4,7
    JMP		waitLongLoop		//5,8
    // add 9 cycles -> 17 cycles
_waitShort:
    LDI		ITER, 0				//18
    // if clock MHz >= 10, just return
    QBLE 	waitShortReturn, SPEED_MHZ, 10		//if 10 <= SPEED_MHZ, return
waitShortLoop:
    QBGE 	waitShortReturn, CYCLES_TO_WAIT, ITER
    ADD		ITER, ITER, 3
    JMP waitShortLoop
    // cycles to wait is cpu_cycles_per_clock - 8
waitShortReturn:
    JMP		RET_ADDR			//20

////////////////////////////////////////////////////////////
// _mode0:
// the logic to handle Mode 0 SPI devices
////////////////////////////////////////////////////////////
_mode0:


////////////////////////////////////////////////////////////
// _mode1:
// the logic to handle Mode 1 SPI devices
//////////////////////////////////////////////////////////// 
_mode1:


////////////////////////////////////////////////////////////
// _mode2:
// the logic to handle Mode 2 SPI devices
////////////////////////////////////////////////////////////
_mode2:
    SET		CLOCK_PIN	// clock starts high
    LDI		BIT_ITER, 7
    LDI		RX_BYTE, 0		// clear the rx buffer byte
    LDI		TRANS_COUNTER, 0
    // load first byte from memory
    LBBO	TX_BYTE, MEM_START, TRANS_COUNTER, 1
    CLR		CS_PINS, ID_REG	// set CS to low (pin will be shifted by the value in ID_REG)

    // while transaction countdown is not zero
mode2Loop:
    QBEQ 	_mode2End, TRANS_COUNTER, TRANS_TOTAL				
//----------------------------------------------------------CLOCK HIGH----SHIFT EDGE-
    SET 	CLOCK_PIN    // set clock high							1
    LSR 	TEMP_BYTE, TX_BYTE, BIT_ITER	// LSR TEMP_BYTE, current_reg, BIT_ITER		2
    QBBS 	mode2If1, TEMP_BYTE.t0	        // if not TEMP_BYTE.t0				3
    CLR 	MOSI_PIN							//		4		
    JMP 	mode2EndIf1							//		5
mode2If1:
    SET 	MOSI_PIN        // else set MOSI_PIN						4
	/// MOSI SHOULD NOW BE VALID
    NOOP									//		5
mode2EndIf1:
    NOOP									//		6
    NOOP									//		7
    NOOP									//		8
    JAL 	RET_ADDR, _waitLong    // WAIT					//		9
//----------------------------------------------------------CLOCK LOW----SAMPLE EDGE-
    CLR		CLOCK_PIN        // set clock low						1
    LSL 	RX_BYTE, RX_BYTE, 1					//			2
    QBBC 	mode2EndIf2, MISO_PIN	 // check input						3
    SET 	RX_BYTE.t0						//			4
mode2EndIf2:
    QBLT	mode2SameByte, BIT_ITER, 0				//			5
    JAL		RET_ADDR, _byteTransition
    JAL		RET_ADDR, _waitShort
    JMP 	mode2Loop
mode2SameByte:        // else
    SUB		BIT_ITER, BIT_ITER, 1					//			6
    JAL		RET_ADDR, _waitLong					//			7
    JMP 	mode2Loop						// 			8
		// the check at the beginning of mode2Loop counts as				9
_mode2End:
    SET		CLOCK_PIN
    // give sufficient time before CS up
    LDI		ITER, 0
waitToRelease:
    QBEQ	mode2Release, ITER, 10
    ADD		ITER, ITER, 2
    NOOP
    JMP		waitToRelease
mode2Release:
    SET		CS_PINS, ID_REG
    JMP		end_transaction


////////////////////////////////////////////////////////////
// _mode3:
// the logic to handle Mode 3 SPI devices
////////////////////////////////////////////////////////////
_mode3:


// end the PRU's operation.
_done:
    // Send notification to Host for program completion
//#ifdef AM33XX
//    MOV       r31.b0, PRU1_ARM_INTERRUPT+16
//#else
//    MOV       r31.b0, #PRU1_ARM_INTERRUPT
//#endif

    HALT
