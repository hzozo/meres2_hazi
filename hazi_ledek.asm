;*************************************************************** 
;* Feladat: 
;* Rövid leírás:
; 
;* Szerzõk: 
;* Mérõcsoport: <merocsoport jele>
;
;***************************************************************
;* "AVR ExperimentBoard" port assignment information:
;***************************************************************
;*
;* LED0(P):PortC.0          LED4(P):PortC.4
;* LED1(P):PortC.1          LED5(P):PortC.5
;* LED2(S):PortC.2          LED6(S):PortC.6
;* LED3(Z):PortC.3          LED7(Z):PortC.7        INT:PortE.4
;*
;* SW0:PortG.0     SW1:PortG.1     SW2:PortG.4     SW3:PortG.3
;* 
;* BT0:PortE.5     BT1:PortE.6     BT2:PortE.7     BT3:PortB.7
;*
;***************************************************************
;*
;* AIN:PortF.0     NTK:PortF.1    OPTO:PortF.2     POT:PortF.3
;*
;***************************************************************
;*
;* LCD1(VSS) = GND         LCD9(DB2): -
;* LCD2(VDD) = VCC         LCD10(DB3): -
;* LCD3(VO ) = GND         LCD11(DB4): PortA.4
;* LCD4(RS ) = PortA.0     LCD12(DB5): PortA.5
;* LCD5(R/W) = GND         LCD13(DB6): PortA.6
;* LCD6(E  ) = PortA.1     LCD14(DB7): PortA.7
;* LCD7(DB0) = -           LCD15(BLA): VCC
;* LCD8(DB1) = -           LCD16(BLK): PortB.5 (1=Backlight ON)
;*
;***************************************************************

.include "m128def.inc" ; Definition file for ATmega128 
;* Program Constants 
.equ tized =1080 ; Generic Constant Structure example

;* Program Variables Definitions 
.def temp =r16 ; Temporary Register example 
.def szamlalo = r17
.def switch = r18
.def led = r19
.def uzem = r20

;*************************************************************** 
;* Reset & Interrupt Vectors  
.cseg 
.org $0000 ; Define start of Code segment 
	jmp RESET ; Reset Handler, jmp is 2 word instruction 
	jmp DUMMY_IT	; Ext. INT0 Handler
	jmp DUMMY_IT	; Ext. INT1 Handler
	jmp DUMMY_IT	; Ext. INT2 Handler
	jmp DUMMY_IT	; Ext. INT3 Handler
	jmp DUMMY_IT	; Ext. INT4 Handler (INT gomb)
	jmp DUMMY_IT	; Ext. INT5 Handler
	jmp DUMMY_IT	; Ext. INT6 Handler
	jmp DUMMY_IT	; Ext. INT7 Handler
	jmp DUMMY_IT	; Timer2 Compare Match Handler 
	jmp DUMMY_IT	; Timer2 Overflow Handler 
	jmp DUMMY_IT	; Timer1 Capture Event Handler 
	jmp T1CM_IT		; Timer1 Compare Match A Handler 
	jmp DUMMY_IT	; Timer1 Compare Match B Handler 
	jmp DUMMY_IT	; Timer1 Overflow Handler 
	jmp DUMMY_IT	; Timer0 Compare Match Handler 
	jmp DUMMY_IT	; Timer0 Overflow Handler 
	jmp DUMMY_IT	; SPI Transfer Complete Handler 
	jmp DUMMY_IT	; USART0 RX Complete Handler 
	jmp DUMMY_IT	; USART0 Data Register Empty Hanlder 
	jmp DUMMY_IT	; USART0 TX Complete Handler 
	jmp DUMMY_IT	; ADC Conversion Complete Handler 
	jmp DUMMY_IT	; EEPROM Ready Hanlder 
	jmp DUMMY_IT	; Analog Comparator Handler 
	jmp DUMMY_IT	; Timer1 Compare Match C Handler 
	jmp DUMMY_IT	; Timer3 Capture Event Handler 
	jmp DUMMY_IT	; Timer3 Compare Match A Handler 
	jmp DUMMY_IT	; Timer3 Compare Match B Handler 
	jmp DUMMY_IT	; Timer3 Compare Match C Handler 
	jmp DUMMY_IT	; Timer3 Overflow Handler 
	jmp DUMMY_IT	; USART1 RX Complete Handler 
	jmp DUMMY_IT	; USART1 Data Register Empty Hanlder 
	jmp DUMMY_IT	; USART1 TX Complete Handler 
	jmp DUMMY_IT	; Two-wire Serial Interface Handler 
	jmp DUMMY_IT	; Store Program Memory Ready Handler 

.org $0046

;****************************************************************
;* DUMMY_IT interrupt handler -- CPU hangup with LED pattern
;* (This way unhandled interrupts will be noticed)

;< többi IT kezelõ a fájl végére! >

DUMMY_IT:	
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< többi IT kezelõ a fájl végére! >

;*************************************************************** 
;* MAIN program, Initialisation part
.org $004B;
RESET: 
;* Stack Pointer init, 
;  Set stack pointer to top of RAM 
	ldi temp, LOW(RAMEND) ; RAMEND = "max address in RAM"
	out SPL, temp 	      ; RAMEND value in "m128def.inc" 
	ldi temp, HIGH(RAMEND) 
	out SPH, temp 

M_INIT:
;< ki- és bemenetek inicializálása stb > 
	ldi temp, 0x00
	out TCCR1A, temp
	ldi temp, 0b00001101
	out TCCR1B, temp
	ldi temp, HIGH(tized)
	out OCR1AH, temp
	ldi temp, LOW(tized)
	out OCR1AL, temp
	ldi temp, 0
	out TCNT1H, temp
	out TCNT1L, temp

	ldi temp, 0b00010000
	out TIMSK, temp

	ldi temp, 0
	sts DDRG, temp
	;a ledek inicializalasa
	ldi temp, 0xFF
	out DDRC, temp
	ldi led, 0b00010001
	out PORTC, led
	sei
	


;*************************************************************** 
;* MAIN program, Endless loop part
 
M_LOOP: 

;< fõciklus >
	lds switch, PING
	andi switch, 0b00011011
	mov temp, switch
	andi temp, 0b00010000
	lsr temp
	lsr temp
	andi switch, 0b00001011
	or switch, temp
	in temp, ADCH
	sbrc temp, 7 ;51%-os valasztovonal
	ldi uzem, 0
	sbrs temp, 7
	ldi uzem, 1

	jmp M_LOOP ; Endless Loop  


;*************************************************************** 
;* Subroutines, Interrupt routines

T1CM_IT:
	push temp
	in temp,SREG
	push temp

	;törzs
	inc szamlalo
	call COMPARE

	pop temp
	out SREG, temp
	pop temp
	reti

COMPARE:
	ori switch, 0b11110000
	com switch
	cpi switch, 0 ;ha a switch 0 (tehat 100msec)
	breq FENYSOR ;akkor mehet a leptetes
	cpse switch, szamlalo ;egyebkent ellenoriz
	ret	;es ha nem egyezik meg a 2, akkor visszater
FENYSOR:	;ha megegyezik, akkor leptet
	ROL led;		megy balra a led reg-ben az 1-es
	brcs UGRAS;	ujra leptetjuk ha a carry be van utve es a branch mar nem fog latszodni mert a ROL kiuti a carryt
VISSZA:
	out PORTC, led
	ldi szamlalo, 0	;lenullazzuk, hogy a szamlalas mukodjon
	ret

UGRAS:
	clc
	inc led
	ldi szamlalo, 0
	jmp VISSZA

T0CM_IT: 
	push temp
	in temp,SREG
	push temp

	

	pop temp
	out SREG, temp
	pop temp
	reti

T0IF_IT:
	push temp
	in temp,SREG
	push temp

	ldi temp, 0x01	

	pop temp
	out SREG, temp
	pop temp
	reti
