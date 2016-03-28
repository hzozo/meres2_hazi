;*************************************************************** 
;* Feladat: 
;* R�vid le�r�s:
; 
;* Szerz�k: 
;* M�r�csoport: <merocsoport jele>
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
.def szamlalo = r17 ;a futofeny sebessegehez
.def switch = r18
.def led = r19 ;ledek
.def uzem = r20 ;ejszaka, nappal
.def gomb = r21 ;btn0
.def state = r22 ;kikapcsolva, futofeny, minden vilagit

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
	jmp T0CM_IT		; Timer0 Compare Match Handler 
	jmp T0IF_IT		; Timer0 Overflow Handler 
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

;< t�bbi IT kezel� a f�jl v�g�re! >

DUMMY_IT:	
	ldi r16,   0xFF ; LED pattern:  *-
	out DDRC,  r16  ;               -*
	ldi r16,   0xA5	;               *-
	out PORTC, r16  ;               -*
DUMMY_LOOP:
	rjmp DUMMY_LOOP ; endless loop

;< t�bbi IT kezel� a f�jl v�g�re! >

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
;< ki- �s bemenetek inicializ�l�sa stb > 
	;10HZ
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

	;FAST PWM

	ldi temp, 123	;a pdf szerint kb. fel fenyero
	out OCR0, temp
	ldi temp, 0b01001111 ;FAST PWM
	out TCCR0, temp
	ldi temp, 0b00010011
	out TIMSK, temp

	ldi temp, 0
	sts DDRG, temp
	;a ledek inicializalasa
	ldi temp, 0xFF
	out DDRC, temp
	ldi led, 0b00010001
	ldi state, 0
	ldi temp, 0b11011111
	out DDRE, temp
	ldi gomb, 0
	


;*************************************************************** 
;* MAIN program, Endless loop part
 
M_LOOP: 

;< f�ciklus >
	call KAPCSOLO ;ki, be, fullf�ny
	call UZEMSZAK
  FOLYTATAS:
	lds switch, PING
	andi switch, 0b00011011
	mov temp, switch
	andi temp, 0b00010000
	lsr temp
	lsr temp
	andi switch, 0b00001011
	or switch, temp
	jmp M_LOOP ; Endless Loop  


;*************************************************************** 
;* Subroutines, Interrupt routines

EJSZAKA:
	ldi temp, 0b00010011
	out TIMSK, temp
	jmp FOLYTATAS

UZEMSZAK:
	in temp, ADCH
	sbrc temp, 7 ;51%-os valasztovonal
	ldi uzem, 0 ;ejszaka bet�ltese
	sbrs temp, 7 
	ldi uzem, 1	;nappal bet�ltese
	sbrc uzem, 0
	jmp EJSZAKA
	ldi temp, 0b00010000
	out TIMSK, temp
	ret

KAPCSOLO: ;perg�smentes�t�s
	lsl gomb
	in temp, PINE
	bst temp, 5
	bld gomb, 0
	andi gomb, 0b00000011
	cpi gomb, 0b00000010
	breq STATE_ALLITAS ;ha meg lett nyomva
	call CHECK_STATE
	ret

CHECK_STATE: ;a STATE-nek megfeleloen be�ll�tjuk
	cpi state, 0
	breq KIKAPCSOLVA
	cpi state, 1
	breq FUTOFENYBEN
	cpi state, 2
	breq MINDEN
  KIKAPCSOLVA:
  	ldi temp, 0
	out DDRC, temp
  	jmp M_LOOP
  FUTOFENYBEN:
  	sei ;itt bekapcsoljuk, eddig nem kellett
  	ret
  MINDEN:
	cli ;letiltjuk az it-ket
  	ldi temp, 0xFF
	out DDRC, temp
	out PORTC, temp
	jmp M_LOOP ;mert a tobbi funkcio ilyenkor felesleges

STATE_ALLITAS: ;allitjuk a STATE-ET
	cpi state, 0 ;ki van kapcsolva
	breq KIKAPCSOLT
	cpi state, 1 ;futofenyben volt
	breq FUTOFENY
	cpi state, 2
	breq ALL
  KIKAPCSOLT:
    inc state
	jmp M_LOOP
  FUTOFENY:
  	inc state
	jmp M_LOOP
  ALL: ;minden led vilagit
	ldi state, 0
	jmp M_LOOP
	

T1CM_IT:
	push temp
	in temp,SREG
	push temp

	;t�rzs
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
	inc led; inkerement�lom, hiszen ak�rhol is �llt, az p�ros volt, �s �gy a 0-ba fog bej�nni az 1-es
	jmp VISSZA

T0CM_IT:  ; a pdf alapjan
	push temp
	in	 temp,SREG
	push temp

	ldi temp, 0 ;kapcsolja ki
	jmp END_IT

T0IF_IT: ;kapcsolja be
	push temp
	in	temp,SREG
	push temp

	mov temp, led
	andi temp, 0b11110000 ;ejszaka csak a bal oldali vilagit
END_IT:
	out DDRC, temp
	pop temp
	out SREG, temp
	pop temp
	reti
