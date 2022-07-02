; ---------------------------------- NOTE : -------------------------------------;
 
;		R0 	= Used in Delay Subroutine
;		R1	= Un-Used 
;		R2	= Un-Used
;		R3	= Stores 1st operand
;		R4	= Monitors * (Operator) increment value
;		R5	= Stores 2nd operand
;		R6	= Monitors which operand is taken as input
;		R7	= Used to store keys in ScanKeypad	

; -------------------------------------------------------------------------------;

			Org 0000H
			
E			Equ		P1.2		; pin P1.2 is assigned for Enable		
RS 			Equ  	P1.3		; pin P1.3 is assigned for Register select
N1 			Equ		30H 		; Stores 1st digit of 1st operand
N2			Equ		32H			; Stores 2nd digit of 1st operand
N3			Equ		34H			; Stores 1st digit of 2nd operand
N4			Equ		36H			; Stores 2nd digit of 2nd operand
N5			Equ		40H			; Stores result after calculation 
N6			Equ		42H			; Stores quotient of result 
N7			Equ		44H			; Stores remainder of result			

; ---------------------------------- Main -------------------------------------;
Main:		
			Clr RS		   		; RS=0 -> Instruction register (I/R) is selected. 
			
			Call MemInit		; Calls the memory initialisation subroutine and clears all the garbage value
			
;-------------------------- Instructions Code ---------------------------------;

			Call FuncSet		; Function set (selecting the 4-bit mode ; for interfacing lcd in 4 bit mode)
	
			Call DispControl	; Turns display and cusor on/off 
			
			Call EntryMode		; Entry mode set - shift cursor to the right
			
;----------------------------- Scan for the keys -------------------------------;	
	
Next:		Call ScanKeyPad		; Calls the scan keypad subroutine
			SetB RS				; RS=1 -> Data register is selected. 
				
			Clr A
			Mov A,R7			
			Call SendChar		; Display the key that is pressed.
			
			Call Operand 		; Stores the 1st and 2nd operand in R3 & R5 .
						
EndHere:	Jmp Next
;------------------------------ End Of Main ---------------------------------;

;--------------- Memory initialisation and clears garbage value ---------------;
MemInit : 	Clr A
			Mov N1,A
			Mov N2,A
			Mov N3,A
			Mov N4,A
			Mov N5,A
			Mov N6,A
			Mov N7,A
			Mov R0,A
			Mov R1,A
			Mov R2,A
			Mov R3,A
			Mov R4,A
			Mov R5,A
			Mov R6,A
			Mov R7,A
			
			Ret
;------------------- Storing operand 1 & 2 into R3 & R5 ----------------------;		

						; Multiplying 10s place with 10 and adding with one's place
						; then storing 1st & 2nd operand into R3 and R5
						
Operand :	Mov B,#0AH			; Storing 10 into register B
			Mov A,N1			; Moving 1st digit of 1st operand into acc
			Mul AB				; Multiplying 1st digit with 10
			Add A,N2			; Adding acc with 2nd digit of operand 1
			Mov R3,A			; R3 stores 1st operand 
			
			Mov B,#0AH
			Mov A,N3
			Mul AB
			Add A,N4
			Mov R5,A			; R5 stores the 2nd operand
			
			Ret

;------------------------------ Code for LCD --------------------------------;

FuncSet:					; Function set (for interfacing lcd in 4 bit mode)
							; P1.4 - P 1.7 controls  both DB0-DB3 and DB4-DB7
			Clr  P1.7		
			Clr  P1.6		
			SetB P1.5		 
			Clr  P1.4		; (DB4)DL = 0 -> puts LCD module into 4-bit mode. 
	
			Call Pulse		; negative edge on E, the module reads the data lines DB7 - DB4
			
			Call Delay		; wait for BF (busy flag) to clear

			Call Pulse		; negative edge on E
							
			SetB P1.7		; P1.7=1 (N=1) -> turns on 2 lines of display
			Clr  P1.6		; P1.6=0 (F=0) -> font set to 5 x 8 dots
			Clr  P1.5
			Clr  P1.4
			
			Call Pulse
			
			Call Delay
			Ret
;------------------------------- Display on/off control -----------------------;

DispControl:				; The display and cursor is turned on
			Clr P1.7		;
			Clr P1.6		;
			Clr P1.5		;
			Clr P1.4		; High nibble set 

			Call Pulse
							; lower nibble set
			SetB P1.7		;
			SetB P1.6		; Sets entire display ON
			SetB P1.5		; Cursor ON
			SetB P1.4		; Cursor blinking ON
			Call Pulse

			Call Delay		; wait for BF to clear	
			Ret
;----------------------------- Entry mode set (4-bit mode) ----------------------;
							; Set to increment the DDRAM address by one and cursor shifted to the right;	
EntryMode:	Clr P1.7		; 
			Clr P1.6		; 
			Clr P1.5		; 
			Clr P1.4		; high nibble set 

			Call Pulse
							; lower nibble set
			Clr  P1.7		; P1.7 = '0'
			SetB P1.6		; P1.6 = '1'
			SetB P1.5		; P1.5 = '1' ; I/D=1 -> Increment ; I/D=0 -> Decrement
			Clr  P1.4		; P1.4 = '0'
 
			Call Pulse

			Call Delay		; wait for BF to clear
			Ret
;------------------------------------- SendChar ----------------------------------;	

								; Display the key that is pressed.
SendChar:	Mov C, ACC.7		; |	high nibble set
			Mov P1.7, C			; |
			Mov C, ACC.6		; |
			Mov P1.6, C			; |
			Mov C, ACC.5		; |
			Mov P1.5, C			; |
			Mov C, ACC.4		; |
			Mov P1.4, C			; | 
			
			Call Pulse

			Mov C, ACC.3		; |	low nibble set
			Mov P1.7, C			; |
			Mov C, ACC.2		; |
			Mov P1.6, C			; |
			Mov C, ACC.1		; |
			Mov P1.5, C			; |
			Mov C, ACC.0		; |
			Mov P1.4, C			; | 

			Call Pulse

			Call Delay			; wait for BF to clear
			
			Ret
;------------------------------------ Pulse subroutine --------------------------------------;
Pulse:		SetB E		; P1.2 is connected to 'E' pin of LCD module*
			Clr  E		; i.e. The LCD module will read the data lines (DB7-DB4)
			Ret			; on the falling edge of the signal
;------------------------------------- Delay Subroutine ------------------------------------;
Delay:		Mov R0,#01DH
			Djnz R0, $
			Ret	
;------------------------------- Scan Row ---------------------------------------;
ScanKeyPad:	;Scan Row3
			CLR P0.3			;Clear Row3
			CALL IDCode0		;Call scan column subroutine
			SetB P0.3			;Set Row 3
			JB F0,Done  		;If F0 is set, end scan 
						
			;Scan Row2
			CLR P0.2			;Clear Row2
			CALL IDCode1		;Call scan column subroutine
			SetB P0.2			;Set Row 2
			JB F0,Done		 	;If F0 is set, end scan 						

			;Scan Row1
			CLR P0.1			;Clear Row1
			CALL IDCode2		;Call scan column subroutine
			SetB P0.1			;Set Row 1
			JB F0,Done			;If F0 is set, end scan

			;Scan Row0			
			CLR P0.0			;Clear Row0
			CALL IDCode3		;Call scan column subroutine
			SetB P0.0			;Set Row 0
			JB F0,Done			;If F0 is set, end scan 
														
			JMP ScanKeyPad		;Go back to scan Row3
							
Done:		Clr F0		        ;Clear F0 flag before exit
			Ret
			
;---------------------------- Scan column subroutine ----------------------------;

IDCode0:	JNB P0.4, KeyCode03				;If Col0 Row3 is cleared - key found
			JNB P0.5, KeyCode13				;If Col1 Row3 is cleared - key found
			JNB P0.6, KeyCode23				;If Col2 Row3 is cleared - key found
			RET					

KeyCode03:	SETB F0							;Key found - set F0
			Mov R7,#'3'						;Code for '3'
											
					; Checks the value of R6, and according to that it jumps to required subroutine
											
			cjne R6,#00H, next1			; If R6 is 0, execute the next command, otherwise jump to next1 
			Mov N1,#03H					; stores this digit as digit 1 of operand 1 in N1 memory location
			inc R6
			ret		
		      
next1: 		cjne R6,#01H, next2			; If R6 is 1, execute the next command, otherwise jump to next2 
			Mov N2,#03H					; stores this digit as digit 2 of operand 1 in N2 memory location
			inc R6
			ret							
		
next2: 		cjne R6,#02H, next3			; If R6 is 2, execute the next command, otherwise jump to next3
            Mov N3,#03H					; stores this digit as digit 1 of operand 2 in N3 memory location	
			inc R6
			ret				
		
next3: 		cjne R6,#03H, $				; If R6 is 3, execute the next command, otherwise do nothing	
			Mov N4,#03H					; stores this digit as digit 2 of operand 2 in N4 memory location
			
			RET				

KeyCode13:	SETB F0						; Key found - set F0 flag
			Mov R7,#'2'					; Code for '2'
			
			cjne R6,#00H, next4
			Mov N1,#02H	
			inc R6
			ret	
		
next4:		cjne R6,#01H, next5
            Mov N2,#02H	
			inc R6
			ret	
		
next5: 		cjne R6,#02H, next6
			Mov N3,#02H	
			inc R6
			ret	
		
next6:		cjne R6,#03H, $
			Mov N4,#02H
			
			RET				

KeyCode23:	SETB F0							;Key found - set F0
			Mov R7,#'1'						;Code for '1'
			
			cjne R6,#00H, next7
			Mov N1,#01H	
			inc R6
			ret	
		
next7: 		cjne R6,#01H, next8
			Mov N2,#01H
			inc R6
			ret		
		
next8: 		cjne R6,#02H, next9
            Mov N3,#01H
			inc R6
			ret		
		
next9:		cjne R6,#03H, $
			Mov N4,#01H
			
			RET				

IDCode1:	JNB P0.4, KeyCode02				;If Col0 Row2 is cleared - key found
			JNB P0.5, KeyCode12				;If Col1 Row2 is cleared - key found
			JNB P0.6, KeyCode22				;If Col2 Row2 is cleared - key found
			RET					

KeyCode02:	SETB F0							;Key found - set F0
			Mov R7,#'6'						;Code for '6'
			
			cjne R6,#00H, next10
			Mov N1,#06H
			inc R6
			
			ret			
		
next10: 	cjne R6,#01H, next11
			Mov N2,#06H
			inc R6
			ret		
		
next11: 	cjne R6,#02H, next12
			Mov N3,#06H
			inc R6
			ret		
		
next12:		cjne R6,#03H, $
			Mov N4,#06H

			Ret			

KeyCode12:	SETB F0							;Key found - set F0
			Mov R7,#'5'						;Code for '5'
			
			cjne R6,#00H, next13
			Mov N1,#05H	
			inc R6
			ret	
		
next13: 	cjne R6,#01H, next14
			Mov N2,#05H	
			inc R6
			ret	
		
next14: 	cjne R6,#02H, next15
            Mov N3,#05H	
			inc R6
			ret	
		
next15:		cjne R6,#03H, $
			Mov N4,#05H			
			RET				

KeyCode22:	SETB F0							;Key found - set F0
			Mov R7,#'4'						;Code for '4'
			
			cjne R6,#00H, next16
			Mov N1,#04H
			inc R6
			ret		
		
next16: 	cjne R6,#01H, next17
			Mov N2,#04H
			inc R6
			ret		
		
next17: 	cjne R6,#02H, next18
			Mov N3,#04H
			inc R6
			ret		
		
next18:		cjne R6,#03H, $
			Mov N4,#04H
			
			RET				

IDCode2:	JNB P0.4, KeyCode01				;If Col0 Row1 is cleared - key found
			JNB P0.5, KeyCode11				;If Col1 Row1 is cleared - key found
			JNB P0.6, KeyCode21				;If Col2 Row1 is cleared - key found
			RET					

KeyCode01:	SETB F0							;Key found - set F0
			Mov R7,#'9'						;Code for '9'
			
			cjne R6,#00H, next19
			Mov N1,#09H
			inc R6
			ret		
		
next19: 	cjne R6,#01H, next20
			Mov N2,#09H	
			inc R6
			ret	
		
next20: 	cjne R6,#02H, next21
			Mov N3,#09H
			inc R6
			ret		
		
next21:		cjne R6,#03H, $
			Mov N4,#09H
			
			RET				

KeyCode11:	SETB F0							;Key found - set F0
			Mov R7,#'8'						;Code for '8'
			
			cjne R6,#00H, next22
			Mov N1,#08H
			inc R6
			ret		
		
next22: 	cjne R6,#01H, next23
			Mov N2,#08H
			inc R6
			ret		
		
next23: 	cjne R6,#02H, next24
			Mov N3,#08H
			inc R6
			ret		
		
next24:		cjne R6,#03H, $
			Mov N4,#08H
			
			RET				

KeyCode21:	SETB F0							;Key found - set F0
			Mov R7,#'7'						;Code for '7'
			
			cjne R6,#00H, next25
			Mov N1,#07H	
			inc R6
			ret	
		
next25: 	cjne R6,#01H, next26
			Mov N2,#07H	
			inc R6
			ret	
		
next26: 	cjne R6,#02H, next27
			Mov N3,#07H	
			inc R6
			ret	
		
next27:		cjne R6,#03H, $
			Mov N4,#07H	
			
			RET				

IDCode3:	JNB P0.4, KeyCode00				;If Col0 Row0 is cleared - key found
			JNB P0.5, KeyCode10				;If Col1 Row0 is cleared - key found
			JNB P0.6, KeyCode20				;If Col2 Row0 is cleared - key found
			RET					


KeyCode00:	SETB F0							; Key found - set F0
			Mov R7,#'='						; Code for '#' 
			Clr A
			Mov A,R7
			Call SendChar
			
			; R4 stores the number of times the key '*' is pressed
			
			cjne R4,#01H, OP2				; If R4=1, jump to ADDITION subroutine
			Call ADDITION					
			
OP2:		cjne R4,#02H, OP3				; If R4=2, jump to SUBTRACTION subroutine
			Call SUBTRACTION     			

OP3:		cjne R4,#03H, OP4				; If R4=3, jump to MULTIPLICATION subroutine+
			Call MULTIPLICATION				

OP4:		Call DIVISION					; Jump to DIVISION subroutine
			
			RET				

KeyCode10:	SETB F0							;Key found - set F0
			Mov R7,#'0'						;Code for '0'
			
			cjne R6,#00H, next28
			Mov N1,#00H	
			inc R6
			Ret
		
next28: 	cjne R6,#01H, next29
			Mov N2,#00H	
			inc R6	
			Ret
		
next29: 	cjne R6,#02H, next30
			Mov N3,#00H	
			inc R6	
			Ret
			
next30:		cjne R6,#03H, $
			Mov N4,#00H
			
			RET					

KeyCode20:	SETB F0							;Key found - set F0
			Mov R7,#'*'	   					;Code for '*' 
			
			;cjne R7,#'*'
			inc R4
			
			RET	
					
;-------------------------------- Calculation ---------------------------------;

ADDITION: 			Mov A,R3
					Add A,R5
					Call ResultBits			; Extracting two digits from the final rewsult
					Call Ascii1				; Converts the first HEX digit into ASCII
					Call Ascii2				; Converts the second HEX digit into ASCII
					
					jmp $

SUBTRACTION:		Mov A,R3						;Code for subtraction
					Subb A,R5
					Jc Negative 					;jump if result of calculation is negative
					Call Positive
					
Positive:			Call ResultBits					;printing for positive result
					Call Ascii1
					Call Ascii2
					
					jmp $
					
Negative:			Mov R7,#'-'						;for displaying -ve character
					Clr A
					Mov A,R7
					Call SendChar
					Clr A
					Mov A,R5						;calculating sub result in case of -ve 
					Subb A,R3
					Inc A 
					Call ResultBits					;displaying -ve result
					Call Ascii1
					Call Ascii2
					
					jmp $
			
			
MULTIPLICATION:		Mov A,R3						;code for multiplication
					Mov B,R5
					Mul AB
					Call ResultBits					;displaying results	
					Call Ascii1
					Call Ascii2
					
					jmp $
			
DIVISION:			Mov A,R3						;code for division
					Mov B,R5
					Div AB
					Call ResultBits					;displaying results
					Call Ascii1
					Call Ascii2
					
					jmp $
		
;--------------- Extracting two digits from the calculation result ---------------;		
					
ResultBits:			mov N5,A			;moves result to N5
					mov B,#0AH
					Div AB
					Mov N6,A			;moves quotient of result to N6
					Mov N7,B			;moves remainder of result to N7
					ret
					
;---------------------------- HEX to ASCII Convertion ----------------------------;					
					
Ascii1 :			MOV A, N6 			; Store first digit into A
					CLR C
					SUBB A, #0AH 		; Check if digit is greater than 10
					MOV A, N6
					JC SKIP1
					ADD A, #07H			; Add 07 if >09
					Call SendChar
					
					ret
					
SKIP1:				ADD A, #30H 		; Else add only 30h for 0-9
					Call SendChar
					
Ascii2 :			MOV A, N7 			; Store second digit into A
					CLR C
					SUBB A, #0AH 		; Check if digit is greater than 10
					MOV A, N7
					JC SKIP2
					ADD A, #07H			; Add 07 if number is >09
					Call SendChar
					
					ret
					
SKIP2:				ADD A, #30H 		; Else add only 30h for 0-9
					Call SendChar
					
					
					End