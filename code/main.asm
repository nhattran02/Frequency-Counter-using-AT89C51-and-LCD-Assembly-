;---------------------------------------------------------------------------------------------------#!
;---------------------------------{{Tran Minh Nhat}}--------------------------------------------#!
;-----------------------{{Project: Digital Frequency Meter}}------------------------------------#!
;---------------------------{{System: 8051 microcontroller}}----------------------------------------#!
;------------------------------{{Released at: 9/6/2022}}-------------------------------------------#!
;---------------------------------------------------------------------------------------------------#!
;khai bao ket noi phan cung;
            EN         BIT   P2.7        ;#!chan P2.7 la EN cua LCD
            RS         BIT   P2.5        ;#!chan P2.5 la RS cua LCD
            LCD        EQU   P1          ;#!khai bao port du lieu LCD
            F          EQU   30H         ;#!khai bao bien tan so F
            T_ON_1     EQU   31H         ;#!chua du lieu thoi gian muc cao 
            T_ON_2     EQU   32H
            T_ON_3     EQU   33H
            R8_        EQU   50H         ;#!thanh ghi tao them cho phep tinh
            R9_        EQU   51H         ;#!thanh ghi tao them cho phep tinh
            R10_       EQU   52H         ;#!thanh ghi tao them cho phep tinh
            COUNT      EQU   53H         ;#!bien dem de tinh tan so
;---------------------------------------------------------------------------------------------------#!
;-------------------------------------------------------------#!
;			~ CHUONG TRINH MAIN  ~
;-------------------------------------------------------------#!
;1.Su dung ngat ngoai 0 de dem tan so va ngat timer 1 mode 1 (16bit) de tinh time_on,
;
;2.Bo dem se reset sau moi 1 giay dung timer 0, mode 1, timer 16 bit 
;
;3.Hien thi thong bao len man hinh LCD
;
;------------------------------------------------------------#!
            ORG   0000H                   
            AJMP MAIN 
            ORG   0003H                   ;#!vector ngat ngoai 0
            AJMP  EX0_ISR
            ORG   001BH                   ;#!vector ngat timer 1
            AJMP  ET1_ISR 
            
            ORG   0030H 
MAIN:       ACALL LCD_INIT                ;#!khoi tao man hinh LCD 
AGAIN:      ACALL CALCULATE_HZ            ;#!tinh tan so
            ACALL HEXtoBCD                ;#!chuyen doi so hex sang BCD de hien thi
            ACALL LCD_DISPLAY             ;#!hien thi tan so ra man hinh LCD
            ;
            ACALL CALCULATE_DUTY_CYCLE    ;#!tinh chu ki nhiem vu duty cycle
            ACALL HEX32TOBCD              ;#!chuyen doi so hex 32 bit sang BCD hien thi
            ACALL LCD_DISPLAY_DUTY_CYCLE  ;#!hien thi duty cycle ra man hinh LCD
            AJMP  AGAIN                   ;#!lap vong tro lai
;---------------------------------------
EX0_ISR:
            INC   COUNT
            RETI 
ET1_ISR:
            INC   T_ON_3
            RETI

;-------------------------------------------------------------#!
;			~ chuong trinh con LCD_INIT ~
;-------------------------------------------------------------#!
		;khoi tao LCD 16x2 
		;gui cac ma code LCD de khoi tao 38H,0CH,01H,06H,8BH
		;dung phuong phap tra bang 
;-------------------------------------------------------------#!
LCD_INIT:
            MOV   DPTR, #CODE_INIT              ;#!dat dia chi tra bang
LOOP1:      CLR   A                             ;#!xoa co ACC cho lenh tiep theo
            MOVC  A, @A+DPTR                    ;#!tra bang 
            ACALL LCD_CMD                       ;#!goi chuong trinh con ghi lenh ra LCD
            INC   DPTR                          ;#!tang gia tri DPTR  <DPTR = DPTR + 1>
            JNZ   LOOP1                         ;#!nhay vong lai neu ACC khac 0

            
            RET 
	     										;#!return if zero to MAIN routine
;-------------------------------------------------------------------#!
;			~ chuong trinh con CALCULATE_HZ ~
;-------------------------------------------------------------------#!
		;tinh so chu ki trong 1 giay
		;
		;dung timer 0 delay 1 giay
		;cho timer0 chay 16 vong voi gia tri 62500
		; 16 x 62500 = 1 000 000 uSec = 1 Sec
		;
		;dem so chu ki dung bien COUNT
;---------------------------------------------------------------------#!

CALCULATE_HZ: 
            MOV   TMOD, #00010001B        ;#!timer 1 & 0 mode 1 (16bit)
            SETB  EA                      ;#!cho phep ngat toan cuc
            SETB  IT0                     ;#!bat canh xuong cua /INT0
            ;
            MOV   TL1, #00H               ;#!khoi tao cac gia tri bien tinh
            MOV   TH1, #00H 
            MOV   T_ON_1, #00H
            MOV   T_ON_2, #00H
            MOV   T_ON_3, #00H
            MOV   COUNT, #00H

            ;#!tinh thoi gian muc 1 (5V)

            JB    P3.2, $
            JNB   P3.2, $                 ;#!cho canh len
            SETB  TR1                     ;#!cho timer1 chay de do thoi gian time_on
            SETB  ET1                     ;#!cho phep ngat timer1
            JB    P3.2, $                 ;#!doi muc 1
            CLR   TR1                     ;#!sau khi muc 1 ketthuc thi dung timer1
            MOV   T_ON_1, TL1             ;#!tra ve gia tri dem duoc vao T_ON_1 va T_ON_2
            MOV   T_ON_2, TH1 
            CLR   ET1                     ;#!cam ngat timer1

            ;#!do tan so

            SETB  EX0                     ;#!cho phep ngat ngoai 0     
            MOV   R7, #14                 ;#!delay 1 Sec
BACK:       MOV   TL0, #LOW(-62500)
            MOV   TH0, #HIGH(-62500)
            SETB  TR0         
            JNB	TF0, $      
            CLR	TR0                     ;#!dung timer
	     CLR	TF0                     ;#!xoa co bao tran TF0
	     DJNZ  R7, BACK    
            MOV   F, COUNT                ;#!tra gia tri tan so ve F
            CLR   EX0                     ;#!cam ngat ngoai 0
            RET                           


;-------------------------------------------------------------------#!
;			~ chuong trinh con CALCULATE_DUTY_CYCLE ~
;-------------------------------------------------------------------#!
		;tinh chu ki nhiem vu
		;do thoi gian time_on trong mot chu ki
		;DC = time_on x tanso
;---------------------------------------------------------------------#!
CALCULATE_DUTY_CYCLE:
            ;#! thuc hien phep nhan time_on voi tanso

            MOV R0, #40H            ;#!dia chi dau luu ket qua
            MOV R1, T_ON_1          ;#!gan 
            MOV R2, T_ON_2
            MOV R3, T_ON_3
            MOV R4, F 
            MOV A, R4   
            MOV B, A 
            MOV A, R1 
            MUL AB      
            MOV @R0, A 
            INC R0 
            MOV A, B 
            MOV R5, A 
            MOV A, F  
            MOV B, A 
            MOV A, R2 
            MUL AB 
            ADD A, R5 
            MOV @R0, A 
            INC R0 
            MOV A, B 
            MOV R5, A 
            MOV A, F 
            MOV B, A 
            MOV A, R3 
            MUL AB 
            ADD A, R5 
            MOV @R0, A 
            MOV A, B 
            ADDC A, #00H 
            INC R0 
            MOV @R0, A 
            RET 
;-------------------------------------------------------------#!
;			~ chuong trinh con HEXtoBCD ~
;-------------------------------------------------------------#!
       ;chuyen so HEX 8 bit sang ASCII 7 digits
       ;ngo vao data byte = F 
       ;ngo ra hang tram = R3
       ;ngo ra hang chuc = R2
       ;ngo ra hang don vi = R1
;--------------------------------------------------------------#!

HEXtoBCD:
            MOV 	R1,#00H                 ;#!don vi
            MOV 	R2,#00H                 ;#!chuc
            MOV 	R3,#00H                 ;#!tram 
            ;	
            MOV   B, #10 
            MOV   A, F
            DIV   AB 
            MOV   R1, B 
            ;
            MOV   B, #10 
            DIV   AB 
            MOV   R2, B
            MOV   R3, A 
            RET 
;-------------------------------------------------------------------------#!
;			~ chuong trinh con HEX32TOBCD ~
;-------------------------------------------------------------#!
       ;chuyen so hex 32 bit sang ASCII 7 digits
       ;input Data byte 3 = (43H)
       ;input Data byte 2 = (42H)
       ;input Data byte 1 = (41H)
	 ;input Data byte 0 = (40H)
      
;------------------------------------------------------------#!
HEX32TOBCD:
            MOV R1, #00H            ;#!khoi tao gia tri ban dau cho cac bien
            MOV R2, #00H 
            MOV R3, #00H 
            MOV R4, #00H 
            MOV R5, #00H 
            MOV R6, #00H 
            MOV R7, #00H 
            MOV R8_, #00H 
            MOV R9_, #00H 
            MOV R10_, #00H
            ;
            MOV B, #10 
            MOV A, 40H 
            DIV AB 
            MOV R1, B 
            ;
            MOV B, #10 
            DIV AB 
            MOV R2, B 
            MOV R3, A 
            ;
            MOV A, 41H 
            CJNE A, #0H, NEXT1_
            MOV A, 42H 
            CJNE A, #0H, NEXT2_
            MOV A, 43H 
            CJNE A, #0H, NEXT3_
            RET 
            ;
NEXT1_:                            ;#!cong 256 tuong ung vao R1, R2, R3
            MOV A, #6
            ADD A, R1 
            MOV B, #10 
            DIV AB 
            MOV R1, B 
            ;
            ADD A, #5
            ADD A, R2 
            MOV B, #10 
            DIV AB 
            MOV R2, B 
            ;
            ADD A, #2 
            ADD A, R3 
            MOV B, #10 
            DIV AB 
            MOV R3, B
            ;
            ADD A, R4 
            MOV R4, A 
            DJNZ 41H, NEXT1_
            MOV B, #10 
            MOV A, R4 
            DIV AB 
            MOV R4, B
            ; 
            MOV R5, A
            MOV A, #42H 
            CJNE A, #0H, NEXT2_
            RET 
            ;
NEXT2_:                             ;#!cong 65536 tuong ung vao R1, R2, R3, R4, R5
            MOV A, #6 
            ADD A, R1 
            MOV B, #10 
            DIV AB 
            MOV R1, B 
            ;
            ADD A, #3
            ADD A, R2 
            MOV B, #10 
            DIV AB 
            MOV R2, B 
            ;
            ADD A, #5 
            ADD A, R3 
            MOV B, #10 
            DIV AB 
            MOV R3, B 
            ;
            ADD A, #5 
            ADD A, R4 
            MOV B, #10
            DIV AB 
            MOV R4, B 
            ;
            ADD A, #6 
            ADD A, R5 
            MOV B, #10 
            DIV AB 
            MOV R5, B 
            ;
            ADD A, R6 
            MOV R6, A 
            DJNZ 42H, NEXT2_
            MOV B, #10 
            MOV A, R6 
            DIV AB 
            MOV R6, B 
            MOV R7, A 
            ;
            MOV A, 43H
            CJNE A, #0H, NEXT3_
            RET 
            ;
NEXT3_:                              ;#!cong 16777216 tuong ung vao R1, R2, R3, R4, R5, R6, R7, R8
            MOV A, #6 
            ADD A, R1 
            MOV B, #10 
            DIV AB 
            MOV R1, B 
            ;
            ADD A, #1 
            ADD A, R2 
            MOV B, #10 
            DIV AB 
            MOV R2, B 
            ;
            ADD A, #2 
            ADD A, R3 
            MOV B, #10 
            DIV AB 
            MOV R3, B 
            ;
            ADD A, #7
            ADD A, R4 
            MOV B, #10 
            DIV AB 
            MOV R4, B 
            ;
            ADD A, #7 
            ADD A, R5 
            MOV B, #10 
            DIV AB 
            MOV R5, B 
            ;
            ADD A, #7 
            ADD A, R6 
            MOV B, #10 
            DIV AB 
            MOV R6, B 
            ;
            ADD A, #6 
            ADD A, R7 
            MOV B, #10 
            DIV AB 
            MOV R7, B 
            ;
            ADD A, #1 
            ADD A, R8_ 
            MOV B, #10 
            DIV AB 
            MOV R8_, B 
            ;
            ADD A, R9_ 
            MOV R9_, A 
            DJNZ 43H, NEXT3_
            MOV B, #10 
            MOV A, R9_
            DIV AB 
            MOV R9_, B 
            MOV R10_, A 
            RET 

;-------------------------------------------------------------#!
;			~ chuong trinh con LCD_DISPLAY ~
;-------------------------------------------------------------#!
;		;In du lieu tan so ra man hinh LCD
;-------------------------------------------------------------#!
LCD_DISPLAY:
            MOV A, #82H       
            ACALL LCD_CMD     
            ;
            MOV A, #"F"
            ACALL LCD_DATA 
            ;
            MOV A, #"="
            ACALL LCD_DATA  
            ;
            MOV A, R3 
            ADD A, #30H 
            ACALL LCD_DATA
            ;
            MOV A, R2 
            ADD A, #30H 
            ACALL LCD_DATA
            ;
            MOV A, R1
            ADD A, #30H 
            ACALL LCD_DATA
            ;
            MOV A, #"H"
            ACALL LCD_DATA
            MOV A, #"z"
            ACALL LCD_DATA
            RET 	
;-------------------------------------------------------------#!
;	    ~ chuong trinh con LCD_DISPLAY_DUTY_CYCLE ~
;-------------------------------------------------------------#!
;		    ;In du lieu duty cycle ra man hinh LCD
;-------------------------------------------------------------#!
LCD_DISPLAY_DUTY_CYCLE:
            MOV A, #0C2H
            ACALL LCD_CMD
            ;
            MOV A, #"D"
            ACALL LCD_DATA 
            ;
            MOV A, #"C"
            ACALL LCD_DATA
            ;
            MOV A, #"="
            ACALL LCD_DATA  
            ;
             MOV A, R10_
            ADD A, #30H 
            ACALL LCD_DATA
            ;
             MOV A, R9_
            ADD A, #30H 
            ACALL LCD_DATA
            ;
            MOV A, R8_
            ADD A, #30H 
            ACALL LCD_DATA
            ;
            MOV A, R7
            ADD A, #30H 
            ACALL LCD_DATA
            ;
            MOV A, R6
            ADD A, #30H 
            ACALL LCD_DATA
            ;
            MOV A, R5
            ADD A, #30H 
            ACALL LCD_DATA
            ;
            MOV A, #"."
            ACALL LCD_DATA 
            ;
            MOV A, R4
            ADD A, #30H 
            ACALL LCD_DATA
            ;
            MOV A, R3
            ADD A, #30H 
            ACALL LCD_DATA
            ;
      
            MOV A, #"%"
            ACALL LCD_DATA

            RET 
;-------------------------------------------------------------#!
;			~ chuong trinh con LCD_CMD ~
;-------------------------------------------------------------#!
;		;De gui lenh dieu khien ra cac port LCD
;-------------------------------------------------------------#!
LCD_CMD:
            MOV 	LCD, A 							;#!gui noi dung code sang P1
	     CLR 	RS 								;#!RS=0 vao mode command
	     SETB 	EN 								;#!E=1 tao xung len
	     ACALL DELAY 							;#!delay
	     CLR 	EN 								;#!E=0 de tao canh xuong 
	     RET	

;-------------------------------------------------------------#!
;			~ chuong trinh con LCD_DATA ~
;-------------------------------------------------------------#!
;		;De gui noi dung hien thi ra cac port LCD
;-------------------------------------------------------------#!
LCD_DATA:									
	      MOV 	LCD, A 							;#!gui du lieu sang P1
	      SETB 	RS 								;#!RS=1 vao mode data
	      SETB 	EN								;#!E=1 tao xung len
	      ACALL DELAY 							;#!delay
	      CLR 	EN 								;#!E=0 de tao canh xuong 
	      RET	
;-------------------------------------------------------------#!
;			~ chuong trinh con  DELAY ~
;-------------------------------------------------------------#!
;		
;-------------------------------------------------------------#!
 DELAY:											
	      MOV 	R0,#255							
	      DJNZ 	R0,$							
	      RET
;---------------------------------------------------------------------------------------------------#!
;---------------------------------------------------------------------------------------------------#!
CODE_INIT:   DB    38H,0CH,01H,06H,8BH,0			;#!Look-up table for LCD initialization commands 
	      END	







