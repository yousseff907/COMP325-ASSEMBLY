#INCLUDE "p16f877a.inc"
	__CONFIG _CP_OFF & _WDT_OFF & _PWRTE_OFF & _BODEN_OFF & _LVP_OFF & _HS_OSC

	ORG 0X00

KEY_ROW	EQU	0x20
KEY_COL	EQU	0x21
KEY_VAL	EQU	0x22
TEMP	EQU	0x23

CONFI
	BSF	STATUS,RP0		; Bank 1

	MOVLW   B'11111100'		; A0=Buzzer OUT, A1=Motor OUT, rest inputs
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

INIT
	CLRF	PORTA			; Buzzer OFF, Motor OFF
	CLRF	PORTB			; Keypad row outputs LOW
	BSF	PORTC,6			; TX idle state HIGH
	CLRF	PORTD			; LCD data cleared
	CLRF	PORTE			; LCD control cleared


;----------------------------------------------------------
; SCAN_KEY
; Returns: KEY_VAL = key pressed (0xFF if nothing)
;----------------------------------------------------------

SCAN_KEY
	MOVLW   0xFF
	MOVWF   KEY_VAL		 ; default = no key

	; --- Row 0: drive B4 LOW ---
	MOVLW   B'11101111'
	MOVWF   PORTB
	CALL	DEBOUNCE
	MOVF	PORTB,W
	ANDLW   B'00001111'	 ; mask, keep only col bits
	XORLW   B'00001111'	 ; if all 1s, no key in this row
	BTFSS   STATUS,Z
	CALL	ROW0_KEY		; something pressed in row 0

	; --- Row 1: drive B5 LOW ---
	MOVLW   B'11011111'
	MOVWF   PORTB
	CALL	DEBOUNCE
	MOVF	PORTB,W
	ANDLW   B'00001111'
	XORLW   B'00001111'
	BTFSS   STATUS,Z
	CALL	ROW1_KEY

	; --- Row 2: drive B6 LOW ---
	MOVLW   B'10111111'
	MOVWF   PORTB
	CALL	DEBOUNCE
	MOVF	PORTB,W
	ANDLW   B'00001111'
	XORLW   B'00001111'
	BTFSS   STATUS,Z
	CALL	ROW2_KEY

	; --- Row 3: drive B7 LOW ---
	MOVLW   B'01111111'
	MOVWF   PORTB
	CALL	DEBOUNCE
	MOVF	PORTB,W
	ANDLW   B'00001111'
	XORLW   B'00001111'
	BTFSS   STATUS,Z
	CALL	ROW3_KEY

	RETURN

;==========================================================
; Row handlers: TEMP holds masked column bits
; Returns ASCII of pressed key in W
; Bit mapping: B0=col0 (leftmost), B3=col3 (rightmost)
;==========================================================
ROW0_KEY	; 1 2 3 A
	BTFSS   TEMP,0
	RETLW   '1'
	BTFSS   TEMP,1
	RETLW   '2'
	BTFSS   TEMP,2
	RETLW   '3'
	BTFSS   TEMP,3
	RETLW   'A'
	RETLW   0xFF

ROW1_KEY	; 4 5 6 B
	BTFSS   TEMP,0
	RETLW   '4'
	BTFSS   TEMP,1
	RETLW   '5'
	BTFSS   TEMP,2
	RETLW   '6'
	BTFSS   TEMP,3
	RETLW   'B'
	RETLW   0xFF

ROW2_KEY	; 7 8 9 C
	BTFSS   TEMP,0
	RETLW   '7'
	BTFSS   TEMP,1
	RETLW   '8'
	BTFSS   TEMP,2
	RETLW   '9'
	BTFSS   TEMP,3
	RETLW   'C'
	RETLW   0xFF

ROW3_KEY	; * 0 # D
	BTFSS   TEMP,0
	RETLW   '*'
	BTFSS   TEMP,1
	RETLW   '0'
	BTFSS   TEMP,2
	RETLW   '#'
	BTFSS   TEMP,3
	RETLW   'D'
	RETLW   0xFF

;----------------------------------------------------------
; Short debounce delay (~5ms)
;----------------------------------------------------------
DEBOUNCE
	MOVLW   D'10'
	MOVWF   TEMP
DEB_LOOP
	NOP
	DECFSZ  TEMP,F
	GOTO	DEB_LOOP
	RETURN