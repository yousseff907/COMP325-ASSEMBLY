#INCLUDE "p16f877a.inc"
	__CONFIG _CP_OFF & _WDT_OFF & _PWRTE_OFF & _BODEN_OFF & _LVP_OFF & _HS_OSC

	ORG 0X00

KEY_ROW	EQU	0x20
KEY_COL	EQU	0x21
KEY_VAL	EQU	0x22
TEMP	EQU	0x23
DEB_REG	EQU	0x24
REG1    EQU     0x25
REG2    EQU     0x26
REG3    EQU     0x27
TEMP_C	EQU	0x29
TENS	EQU	0x2A
ONES	EQU	0x2B

;COUNTING LOGIC
PASSENGERS	EQU	0x28
STATION_A_P	EQU	0x2C
STATION_B_P	EQU	0x2D
STATION_C_P	EQU	0x2E
CURR_STATION	EQU	0x2F
REG4		EQU	0x30


CONFI
	BSF	STATUS,RP0		; Bank 1

	MOVLW   B'11101100'		; A0=Buzzer OUT, A1=Motor OUT, rest inputs
	MOVWF   TRISA

	MOVLW   B'00001111'		; B7-B4 outputs (keypad rows), B3-B0 inputs (keypad cols)
	MOVWF   TRISB

	MOVLW   B'10111111'		; C7=RX input, C6=TX output, rest inputs
	MOVWF   TRISC

	CLRF	TRISD			; PORTD all output (LCD data)

	CLRF	TRISE			; PORTE all output (LCD control: RS, RW, EN)

	BCF	OPTION_REG,7		; enable PORTB internal pull-ups

	MOVLW   B'00000100'		; A2 analog, rest digital
	MOVWF   ADCON1

	BCF	STATUS,RP0		; Back to Bank 0
	MOVLW   B'10010001'
	MOVWF   ADCON0

INIT
	CLRF	PORTA			; Buzzer OFF, Motor OFF
	CLRF	PORTB			; Keypad row outputs LOW
	BSF	PORTC,6			; TX idle state HIGH
	CLRF	PORTD			; LCD data cleared
	CLRF	PORTE			; LCD control cleared
	CALL	CONFILCD

MAIN
	CALL	REFRESH_LCD
	CALL	CHECK_TEMP
	CALL	DELAY2S
	GOTO	MAIN





REFRESH_LCD
	MOVLW	H'01'
	CALL	COMMAND
	CALL	DELAY3MS
	CALL	INIT_LCD
	RETURN

INIT_LCD
	MOVLW   'C'
	CALL	CHAR
	MOVLW   'U'
	CALL	CHAR
	MOVLW	'R'
	CALL	CHAR
	MOVLW	'R'
	CALL	CHAR
	MOVLW   ':'
	CALL	CHAR
	CALL	GET_CURR_STATION
	CALL	CHAR
	MOVLW	' '
	CALL	CHAR
	MOVLW	' '
	CALL	CHAR
	MOVLW	' '
	CALL	CHAR
	MOVLW	' '
	CALL	CHAR
	MOVLW   'N'
	CALL	CHAR
	MOVLW   'E'
	CALL	CHAR
	MOVLW   'X'
	CALL	CHAR
	MOVLW   'T'
	CALL	CHAR
	MOVLW   ':'
	CALL	CHAR
	MOVLW   '-'
	CALL	CHAR

	MOVLW	0xC0
	CALL	COMMAND
	MOVLW	'T'
	CALL	CHAR
	MOVLW	'E'
	CALL	CHAR
	MOVLW	'M'
	CALL	CHAR
	MOVLW	'P'
	CALL	CHAR
	MOVLW	':'
	CALL	CHAR
	CALL	READ_LM35DZ
	MOVF	TENS,W
	ADDLW	'0'
	CALL	CHAR
	MOVF	ONES,W
	ADDLW	'0'
	CALL	CHAR
	MOVLW	0xDF	; ° symbol
	CALL	CHAR
	MOVLW	'C'
	CALL	CHAR
	MOVLW	' '
	CALL	CHAR
	MOVLW	'P'
	CALL	CHAR
	MOVLW	'A'
	CALL	CHAR
	MOVLW	'X'
	CALL	CHAR
	MOVLW	':'
	CALL	CHAR
	MOVLW	'-'
	CALL	CHAR
	MOVLW	'-'
	CALL	CHAR

	RETURN

CHECK_STATION_A_BTN
	BTFSC	PORTC,1
	RETURN
TEST_CLICK_A
	BTFSS	PORTC,1
	GOTO	TEST_CLICK_A
TEST_RELEASE_A
	BTFSC	PORTC,1
	GOTO	TEST_RELEASE_A
	INCF	STATION_A_P,F
	RETURN

CHECK_STATION_B_BTN
	BTFSC	PORTC,3
	RETURN
TEST_CLICK_B
	BTFSS	PORTC,3
	GOTO	TEST_CLICK_B
TEST_RELEASE_B
	BTFSC	PORTC,3
	GOTO	TEST_RELEASE_B
	INCF	STATION_B_P
	RETURN

CHECK_STATION_C_BTN
	BTFSC	PORTC,5
	RETURN
TEST_CLICK_C
	BTFSS	PORTC,5
	GOTO	TEST_CLICK_C
TEST_RELEASE_C
	BTFSC	PORTC,5
	GOTO	TEST_RELEASE_C
	INCF	STATION_C_P
	RETURN

GET_SET_CURR_STATION
	CALL GET_CURR_STATION
	MOVWF CURR_STATION
	RETURN
GET_CURR_STATION
	BTFSS	PORTC,0
	RETLW	'A'
	BTFSS	PORTC,2
	RETLW	'B'
	BTFSS	PORTC,4
	RETLW	'C'
	GOTO	GET_CURR_STATION

; GET_NEXT_STATION
; 	CALL	GET_CURR_STATION
; 	MOVWF	TEMP
; 	XORLW	'A'
; 	BTFSC	STATUS,Z
; 	GOTO	STATION_A
; 	MOVF	TEMP,W
; 	XORLW	'B'
; 	BTFSC	STATUS,Z
; 	GOTO	STATION_B
; 	MOVF	TEMP,W
; 	XORLW	'C'
; 	BTFSC	STATUS,Z
; 	GOTO	STATION_C
; 	RETLW	'-'

; need to implement STATION_X logic and count passengers on each station and rethink lcd logic

STATION_A

	;returns next station


CHECK_TEMP	; TO CALL AFTER READING SENSOR
	MOVLW	D'30'
	SUBWF	TEMP_C,W
	BTFSC	STATUS,C
	RETURN
	CALL	BUZZER_FIRE_ALARM
	RETURN
BUZZER_FIRE_ALARM
	MOVLW D'5'
	MOVWF REG4
	CALL FIRING
	DECFSZ REG4,F
	GOTO $-2
	RETURN

FIRING
	BSF	PORTA,4
	BSF	PORTA,1
	CALL	DELAY500MS
	BCF	PORTA,0
	BCF	PORTA,1
	RETURN

READ_LM35DZ
	BSF	ADCON0,2
WAIT_ADC
	BTFSC	ADCON0,2
	GOTO	WAIT_ADC
	MOVF	ADRESH,W
	MOVWF	TEMP_C
	BCF	STATUS,C
	RLF	TEMP_C,F	;multiplied by 2
SPLIT_DIGITS
	MOVF	TEMP_C,W
	MOVWF	ONES
	CLRF	TENS
DIV_LOOP
	MOVLW	D'10'
	SUBWF	ONES,W
	BTFSS	STATUS,C
	RETURN
	MOVWF	ONES
	INCF	TENS,F
	GOTO	DIV_LOOP



CONFILCD
	CALL DELAY20MS
	MOVLW H'3C'	;Function set(bits, lines, and font)
	CALL COMMAND
	MOVLW H'0C'	;display control
	CALL COMMAND
	MOVLW H'06'	;cursor moves right
	CALL COMMAND
	MOVLW H'01'	;clearing lcd
	CALL COMMAND
	RETURN


COMMAND
	BCF PORTE,2 ; RS=0
	BCF PORTE,0 ; E= 0
	MOVWF PORTD  ; SENDING THE BYTE TO THE DATA PORT OF LCD
	NOP          ; SHORT DELAY 1 CYCLE
	BSF PORTE,0  ;E= 1
	NOP          ; DELAY OF THE ENABLE PULSE
	BCF PORTE,0  ; E= 0
	CALL DELAY3MS ; TIME OF EXECUTION
	RETURN

CHAR
	BSF PORTE,2    ; RS=1 (this is a character, not command)
	BCF PORTE,0    ; EN=0 (make SURE enable is low to start)
	MOVWF PORTD    ; put the byte on the data bus
	NOP            ; let data settle on PORTD
	BSF PORTE,0    ; EN=1 (raise enable — "I'm presenting data")
	NOP            ; hold high briefly
	BCF PORTE,0    ; EN=0 (drop enable — LCD LATCHES the data HERE)
	CALL DELAY3MS  ; wait for LCD to finish processing
	RETURN



;==========================================================
; SCAN_KEY
; Scans the 4x4 keypad
; PORTB: B7-B4 = rows (outputs), B3-B0 = columns (inputs w/ pull-ups)
; Result: KEY_VAL holds ASCII of key pressed, or 0xFF if none
; Column mapping: B0=col0 (leftmost), B3=col3 (rightmost)
;==========================================================
SCAN_KEY
    MOVLW   0xFF
    MOVWF   KEY_VAL             ; default = no key pressed

    ; ---------- Row 0: drive B4 LOW ----------
    MOVLW   B'01111111'
    MOVWF   PORTB
    CALL    DEBOUNCE
    MOVF    PORTB,W
    ANDLW   B'00001111'         ; isolate column bits
    MOVWF   TEMP                ; save for row handler
    XORLW   B'00001111'         ; all 1s = no key in this row
    BTFSC   STATUS,Z
    GOTO    ROW1_CHECK
    CALL    ROW0_KEY
    MOVWF   KEY_VAL             ; store returned ASCII
    RETURN                      ; first key wins, exit

ROW1_CHECK
    ; ---------- Row 1: drive B5 LOW ----------
    MOVLW   B'10111111'
    MOVWF   PORTB
    CALL    DEBOUNCE
    MOVF    PORTB,W
    ANDLW   B'00001111'
    MOVWF   TEMP
    XORLW   B'00001111'
    BTFSC   STATUS,Z
    GOTO    ROW2_CHECK
    CALL    ROW1_KEY
    MOVWF   KEY_VAL
    RETURN

ROW2_CHECK
    ; ---------- Row 2: drive B6 LOW ----------
    MOVLW   B'11011111'
    MOVWF   PORTB
    CALL    DEBOUNCE
    MOVF    PORTB,W
    ANDLW   B'00001111'
    MOVWF   TEMP
    XORLW   B'00001111'
    BTFSC   STATUS,Z
    GOTO    ROW3_CHECK
    CALL    ROW2_KEY
    MOVWF   KEY_VAL
    RETURN

ROW3_CHECK
    ; ---------- Row 3: drive B7 LOW ----------
    MOVLW   B'11101111'
    MOVWF   PORTB
    CALL    DEBOUNCE
    MOVF    PORTB,W
    ANDLW   B'00001111'
    MOVWF   TEMP
    XORLW   B'00001111'
    BTFSC   STATUS,Z
    RETURN                      ; nothing pressed, KEY_VAL stays 0xFF
    CALL    ROW3_KEY
    MOVWF   KEY_VAL
    RETURN

;==========================================================
; Row handlers
; TEMP holds masked column bits (only B3-B0 valid)
; Returns ASCII of pressed key in W
; Column mapping: B0=col0, B1=col1, B2=col2, B3=col3
;==========================================================
ROW0_KEY                        ; row 0: 1 2 3 A
    BTFSS   TEMP,0
    RETLW   '1'
    BTFSS   TEMP,1
    RETLW   '2'
    BTFSS   TEMP,2
    RETLW   '3'
    BTFSS   TEMP,3
    RETLW   'A'
    RETLW   0xFF                ; safety fallback

ROW1_KEY                        ; row 1: 4 5 6 B
    BTFSS   TEMP,0
    RETLW   '4'
    BTFSS   TEMP,1
    RETLW   '5'
    BTFSS   TEMP,2
    RETLW   '6'
    BTFSS   TEMP,3
    RETLW   'B'
    RETLW   0xFF

ROW2_KEY                        ; row 2: 7 8 9 C
    BTFSS   TEMP,0
    RETLW   '7'
    BTFSS   TEMP,1
    RETLW   '8'
    BTFSS   TEMP,2
    RETLW   '9'
    BTFSS   TEMP,3
    RETLW   'C'
    RETLW   0xFF

ROW3_KEY                        ; row 3: * 0 # D
    BTFSS   TEMP,0
    RETLW   '*'
    BTFSS   TEMP,1
    RETLW   '0'
    BTFSS   TEMP,2
    RETLW   '#'
    BTFSS   TEMP,3
    RETLW   'D'
    RETLW   0xFF

;==========================================================
; DEBOUNCE - small delay (~few ms) using DEB_REG
; Does NOT touch TEMP (important - TEMP holds column bits)
;==========================================================
DEBOUNCE
    MOVLW   D'250'
    MOVWF   DEB_REG
DEB_LOOP
    NOP
    NOP
    DECFSZ  DEB_REG,F
    GOTO    DEB_LOOP
    RETURN

;==========================================================
; WAIT_RELEASE - call after detecting a key, waits until
; the user lets go before returning. Prevents one press
; from being read multiple times.
;==========================================================
WAIT_RELEASE
    CLRF    PORTB               ; drive ALL rows LOW
    CALL    DEBOUNCE
    MOVF    PORTB,W
    ANDLW   B'00001111'         ; read column bits
    XORLW   B'00001111'         ; all HIGH = no key held
    BTFSS   STATUS,Z
    GOTO    WAIT_RELEASE        ; key still held, wait
    RETURN

GET_KEY
    CALL    SCAN_KEY            ; one scan attempt
    MOVF    KEY_VAL,W
    XORLW   0xFF                ; compare to "no key"
    BTFSC   STATUS,Z
    GOTO    GET_KEY             ; nothing pressed, try again
    CALL    WAIT_RELEASE        ; wait for user to let go
    MOVF    KEY_VAL,W           ; load key into W for return
    RETURN


; DELAYS

DELAY500MS
	MOVLW D'5'
	MOVWF REG3
	MOVLW D'127'
	MOVWF REG2
	MOVLW D'255'
	MOVWF REG1
	DECFSZ REG1,F
	GOTO $-1
	DECFSZ REG2,F
	GOTO $-5
	DECFSZ REG3,F
	GOTO $-9
	RETURN

DELAY20MS
        MOVLW D'1'
        MOVWF REG3
        MOVLW D'25'
        MOVWF REG2
        MOVLW D'255'
	MOVWF REG1
        DECFSZ REG1,F
	GOTO $-1
	DECFSZ REG2,F
	GOTO $-5
	DECFSZ REG3,F
	GOTO $-9
        RETURN

DELAY3MS
        MOVLW D'1'
        MOVWF REG3
        MOVLW D'6'
        MOVWF REG2
        MOVLW D'166'
		MOVWF REG1
        DECFSZ REG1,F
		GOTO $-1
		DECFSZ REG2,F
		GOTO $-5
		DECFSZ REG3,F
		GOTO $-9
        RETURN

DELAY2S  MOVLW D'10'
        MOVWF REG3
        MOVLW D'255'
        MOVWF REG2
        MOVLW D'255'
        MOVWF REG1
        DECFSZ REG1
        GOTO $-1
        DECFSZ REG2
        GOTO $-5
        DECFSZ REG3
        GOTO   $-9
        RETURN

DELAY5S	MOVLW D'26'
	MOVWF REG3
	MOVLW D'255'
	MOVWF REG2
	MOVLW D'255'
	MOVWF REG1
	DECFSZ REG1,F
	GOTO $-1
	DECFSZ REG2,F
	GOTO $-5
	DECFSZ REG3,F
	GOTO $-9
	RETURN

	END