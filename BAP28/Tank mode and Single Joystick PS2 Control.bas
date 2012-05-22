;************************************************
;*** Basic Atom with SSC-32 and PS2 DualShock ***
;******** or MadCatz wireless controller ********
;* H2 program #4 : Tank move + 1 joystick move  *
;***** H2 legs low, middle and high control *****
;******* Sharp GP2D12 IR Sensor Support *********
;********** Bot Board Buzzer support ************
;************************************************
;** Programmer: Laurent Gay, lynxrios@yahoo.fr **
;************************************************
;
; H2 Control Mode 1 :
; Control the right legs with the right joystick (SSC-32 XR command)
; Control the left legs with the left joystick (SSC-32 XL command)
; the global speed is mixed (SSC-32 XS command)
;
; Push the R3 button (Right joystick push button) to swap between control mode
;
; H2 Control Mode 2 :
; Control All legs with the right joystick (SSC-32 XR-XL command mixed)
; the global speed is mixed too (SSC-32 XS command)
;
; Right and Left buttons adjust the speed limit (Mode 1 & 2)
;
; Control The H2 legs 'high' position with the R1/R2buttons
; Control The H2 legs 'low' position with the L1/L2 buttons (H2 body height)
; Control The H2 legs 'low' position with the Up/Down buttons (H2 body height, 10 times faster than L2/R2)
;	and push High position to max (when Up button pressed) if needed
; change the legs trajectories Triangle button -> triangle, Circle button -> triangle like,
;	Cross button -> Square like, Square button -> square
;
; Auto avoid obstacles with the Sharp GP2D12 IR Sensor (lock forward) with sound and pad vibration proportional!
; Disable/enable the sensor with the Start button
;
; you may have to push the Analog Button on a MadCatz Wireless controller (if in sleep mode)
;
;************************************************
;
;
;--------------------------------------------------------------------
;-------------Constants
;PS2 Controller / BotBoard I
DAT con P4
CMD con P5
SEL con P6
CLK con P7
SSC32 con p15
;PS2 Controller / BotBoard II
;DAT con P12
;CMD con P13
;SEL con P14
;CLK con P15
;SSC32 con p8

DeadZone con 28	; must be >= 28
PadMode con $79 ; Dualshock2 mode, use $73 with a Dualshock1

;Sharp GP2D12 IR sensor
GP2D12_Threshold con 250
GP2D12_SoundThreshold con 112 
 
;H2
H2_RH con 2000 	;assume LH = (3000 - H2_RH) = 1000 !
H2_RM con 1333	;assume LM = (3000 - H2_RM) = 1667 !
H2_RL con 1000	;assume LL = (3000 - H2_RL) = 2000 !
					
;--------------------------------------------------------------------				
;-------------Variables
index var Byte
DualShock var Byte(7)
LastButton var Byte(2)
XR var SWord
XL var SWord
MoveModeH2 var Bit		;1 = One Joystick, 0 = Tank
GP2D12Enable var Bit
LockForward var Bit
LargeMotor var Byte
Speed var Byte
MaxSpeed var Byte
MiddleMode var Nib		;0 = triangle, 1 = nearly triangle, 2 = nearly square, 3 = square
H2_High var Word
H2_Middle var Word
H2_Low var word
GP2D12 var Word

XCoord var Sbyte
YCoord var Sbyte
ZCoord var Sbyte
WCoord var Sbyte

;--------------------------------------------------------------------	
;***************
;*** Program ***
;***************

;-------------Init
;DualShock
pause 500

clear
high CLK

again
	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$1\8,$43\8,$0\8,$1\8,$0\8] ;CONFIG_MODE_ENTER
	high SEL
	pause 1
	
	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$01\8,$44\8,$00\8,$01\8,$03\8,$00\8,$00\8,$00\8,$00\8] ;SET_MODE_AND_LOCK
	high SEL
	pause 100
	
	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$01\8,$4F\8,$00\8,$FF\8,$FF\8,$03\8,$00\8,$00\8,$00\8] ;SET_DS2_NATIVE_MODE
	high SEL
	pause 1
	
	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$01\8,$4D\8,$00\8,$00\8,$01\8,$FF\8,$FF\8,$FF\8,$FF\8] ;VIBRATION_ENABLE
	high SEL
	pause 1
	
	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$01\8,$43\8,$00\8,$00\8,$5A\8,$5A\8,$5A\8,$5A\8,$5A\8] ;CONFIG_MODE_EXIT_DS2_NATIVE
	high SEL
	pause 1
	
	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$01\8,$43\8,$00\8,$00\8,$00\8,$00\8,$00\8,$00\8,$00\8] ;CONFIG_MODE_EXIT
	high SEL
	pause 1

	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$1\8]
	shiftin DAT,CLK,FASTLSBPOST,[DualShock(0)\8]
	high SEL
	pause 1
	
	;serout S_OUT,i57600,["PadMode : ", HEX2 DualShock(0), 13]
	Sound 9,[100\4435]
	if DualShock(0) <> PadMode then again
	
MoveModeH2 = 0		;1 = One Joystick, 0 = Tank
GP2D12Enable = 1
LockForward = 0
LargeMotor = 0
MiddleMode = 1
MaxSpeed = 100

LastButton(0) = 255
LastButton(1) = 255

;SSC-32 -> H2 engine
pause 500
gosub H2Init

;--------------------------------------------------------------------
;-------------Main loop
main
;DS2
	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$1\8,$42\8]
	for index = 0 to 2
		shiftin DAT,CLK,FASTLSBPOST,[DualShock(index)\8]
	next
	high SEL
	pause 1
	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$1\8,$42\8,$0\8,$0\8,LargeMotor\8]
	for index = 3 to 6
		shiftin DAT,CLK,FASTLSBPOST,[DualShock(index)\8]
	next
	high SEL
	pause 1
	
	XCoord = DualShock(5) - 128
	if XCoord > DeadZone then
		XCoord = XCoord - DeadZone
	elseif XCoord < -DeadZone
		XCoord = XCoord + DeadZone
	else
		XCoord = 0 
	endif
	
	YCoord = DualShock(6) - 128
	if YCoord > DeadZone then
		YCoord = YCoord - DeadZone
	elseif YCoord < -DeadZone
		YCoord = YCoord + DeadZone
	else
		YCoord = 0 
	endif
	
	ZCoord = DualShock(3) - 128
	if ZCoord > DeadZone then
		ZCoord = ZCoord - DeadZone
	elseif ZCoord < -DeadZone
		ZCoord = ZCoord + DeadZone
	else
		ZCoord = 0 
	endif
	
	WCoord = DualShock(4) - 128
	if WCoord > DeadZone then
		WCoord = WCoord - DeadZone
	elseif WCoord < -DeadZone
		WCoord = WCoord + DeadZone
	else
		WCoord = 0 
	endif

;H2		
	if (DualShock(2).bit4 = 0) and LastButton(1).bit4 then	;Triangle Button test
		MiddleMode = 4
	elseif (DualShock(2).bit5 = 0) and LastButton(1).bit5	;Circle Button test
		MiddleMode = 5
	elseif (DualShock(2).bit6 = 0) and LastButton(1).bit6	;Cross Button test
		MiddleMode = 6
	elseif (DualShock(2).bit7 = 0) and LastButton(1).bit7	;Square Button test
		MiddleMode = 7
	else
		goto NoSound1
	endif
	Sound 9,[100\1318]	
NoSound1
	if (DualShock(2).bit2 = 0) and (H2_Low >= (H2_RL + 20)) then 	;L1 Button test
		H2_Low = H2_Low - 20
		MiddleMode = MiddleMode | 8
	elseif (DualShock(2).bit0 = 0) and (H2_Low <= (H2_High - 20))  	;L2 Button test
		H2_Low = H2_Low + 20
		MiddleMode = MiddleMode | 8
	else
		goto NoSound2
	endif
	Sound 9,[30\((H2_RH - H2_Low) / 2 + 100)]	
NoSound2
	if DualShock(1).bit4 = 0 then 	;Up Button test
		H2_Low = H2_Low - 200
		if H2_Low < H2_RL then
			H2_Low = H2_RL
			goto NoSound3
		endif
		MiddleMode = MiddleMode | 8
	elseif DualShock(1).bit6 = 0	;Down Button test
		H2_Low = H2_Low + 200
		if H2_Low > H2_RH then
			H2_Low = H2_RH
			goto NoSound3
		endif
		H2_High = H2_High + 200
		if H2_High > H2_RH then
			H2_High = H2_RH
		endif
		MiddleMode = MiddleMode | 8
	else
		goto NoSound3
	endif
	Sound 9,[50\((H2_RH - H2_Low) / 2 + 100)]	
NoSound3
	if (DualShock(2).bit1 = 0) and (H2_High >= (H2_Low + 20)) then	;R2 Button test
		H2_High = H2_High - 20
		MiddleMode = MiddleMode | 8
	elseif (DualShock(2).bit3 = 0) and (H2_High <= (H2_RH - 20))  	;R1 Button test
		H2_High = H2_High + 20
		MiddleMode = MiddleMode | 8
	else
		goto NoSound4
	endif
	Sound 9,[30\((H2_High - H2_RL) / 2 + 100)]	
NoSound4
	if (DualShock(1).bit2 = 0) and LastButton(0).bit2 then	;R3 Button test
		MoveModeH2 = MoveModeH2 ^ 1
		Sound 9,[100\1318]
	endif
	if (DualShock(1).bit3 = 0) and LastButton(0).bit3 then	;Start Button test
		GP2D12Enable = GP2D12Enable ^ 1
		if GP2D12Enable then
			Sound 9,[100\880,100\1480]
		else
			LockForward = 0
			LargeMotor = 0
			sound 9,[100\1480,100\880]	
		endif
	endif
	if (DualShock(1).bit5 = 0) and (MaxSpeed <= 190) then	;Right Button test
		MaxSpeed = MaxSpeed + 10
	elseif (DualShock(1).bit7 = 0) and (MaxSpeed >= 20)		;Left Button test
		MaxSpeed = MaxSpeed - 10
	else
		goto NoSound5
	endif
	Sound 9,[100\(MaxSpeed * 10 + 100)]
NoSound5	
	if MoveModeH2 then	;One Joystick Mode
		XR = -ZCoord - WCoord
		XL = ZCoord - WCoord
		
		if XR > 100 then
			XR = 100
		elseif XR < -100
			XR = -100
		endif
		
		if XL > 100 then
			XL = 100
		elseif XL < -100
			XL = -100
		endif
		
		if LockForward then
		 	if (XR > 0) then
				XR = 0
			endif
			if (XL > 0) then
				XL = 0
			endif
		endif
		
		if abs(WCoord) > abs(ZCoord) then
			Speed = abs(WCoord) * MaxSpeed / 100
		else
			Speed = abs(ZCoord) * MaxSpeed / 100
		endif
	else				;Tank Mode
		if LockForward then
		 	if (YCoord < 0) then
				YCoord = 0
			endif
			if (WCoord < 0) then
				WCoord = 0
			endif
		endif
		if abs(WCoord) > abs(YCoord) then
			Speed = abs(WCoord) * MaxSpeed / 100
		else
			Speed = abs(YCoord) * MaxSpeed / 100
		endif	
		XR = -WCoord
		XL = -YCoord
	endif
	if MiddleMode > 3 then
		MiddleMode = MiddleMode & 3
		if MiddleMode = 0 then
			H2_Middle = H2_Low
		elseif MiddleMode = 1
			H2_Middle = (H2_High - H2_Low) / 3 + H2_Low
		elseif MiddleMode = 2
			H2_Middle = (H2_High - H2_Low) * 2 / 3 + H2_Low
		else
			H2_Middle = H2_High
		endif
		serout SSC32,i38400,["LH",DEC 3000 - H2_High," LM",DEC 3000 - H2_Middle," LL",DEC 3000 - H2_Low,13]
		serout SSC32,i38400,["RH",DEC H2_High," RM",DEC H2_Middle," RL",DEC H2_Low,13]
		if Speed = 0 then
			Speed = 200 	;Ensure legs updating
		endif
	endif
	serout SSC32,i38400,["XS",DEC Speed," XR",SDEC XR," XL",SDEC XL,13]
	
;Sharp IR Sensor
	if GP2D12Enable then
		;adin AX0,2,AD_RON,GP2D12
		adin 16,GP2D12
		LockForward = 0
		LargeMotor = 0
		if GP2D12 > GP2D12_Threshold then
			LockForward = 1
			LargeMotor = 255
			Sound 9,[20\200]
		elseif GP2D12 > GP2D12_SoundThreshold
			LargeMotor = GP2D12
			Sound 9,[10\(GP2D12 * 10)]
		endif
	endif
	
	pause 50
	
	LastButton(0) = DualShock(1)
	LastButton(1) = DualShock(2)
	
	goto main
	
;-------------Sub H2 Init
H2Init
	serout SSC32,i38400,[13]									;clear the SSC-32 buffers
	;Servo Offset Command
	;Replace the section between the quotes with the values as described in the tutorial.
	;serout SSC32,i38400,["#0PO0 #1PO0 #2PO0 #3PO0 #4PO0 #5PO0 #16PO0 #17PO0 #18PO0 #19PO0 #20PO0 #21PO0",13]
	
	serout SSC32,i38400,["XS0 XSTOP",13]						;Stop the sequencer if running
	serout SSC32,i38400,["LF1700 RF1300 LR1300 RR1700",13] 	;Horizontal
	serout SSC32,i38400,["LH",DEC 3000 - H2_RH," LM",DEC 3000 - H2_RM," LL",DEC 3000 - H2_RL,13] 	;Vertical Left
	serout SSC32,i38400,["RH",DEC H2_RH," RM",DEC H2_RM," RL",DEC H2_RL,13]						;Vertical Right
	serout SSC32,i38400,["VS2500 HT500",13]					;Vertical Speed and Horizontal Time				
	serout SSC32,i38400,["XS0",13]							;Set Global Speed to 0
	H2_High = H2_RH
	H2_Middle = H2_RM
	H2_Low = H2_RL
	MiddleMode = 1
	
	return