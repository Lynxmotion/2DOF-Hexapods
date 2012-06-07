;************************************************
;*** Basic Atom Pro, SSC-32 and PS2 DualShock ***
;***** H2 program #6EXP3 : 1 joystick move  *****
;***** H2 legs low, middle and high control *****
;******* Sharp GP2D12 IR Sensor Support *********
;********** Bot Board Buzzer support ************
;************ Pan and tilt control **************
;************************************************
;** Programmer: Laurent Gay, lynxrios@yahoo.fr **
;** Modified by: Jim Frye ***********************
;************************************************
;
; Pan & Tilt :
; Control a Pan & Tilt assembly with the left joystick
; Push the L3 button to swap between P&T control mode
; Mode 1 (default): Jog
; Mode 2 : P&T positions are linked to Joystick position 
;
; H2 Control :
; Control All legs with the right joystick (SSC-32 XR-XL command mixed)
; the global speed is mixed too (SSC-32 XS command)
;
; Right and Left buttons adjust the speed limit (Mode 1 & 2)
;
; Set trajectory, speed, lift with:
; Triangle button -> triangle, fast, min lift 
; Circle button -> triangle like, medium, med lift
; Cross button -> Square like, medium slow, med lift
; Square button -> square, slow, max lift
;
; Auto avoid obstacles with the Sharp GP2D12 IR Sensor (lock forward) with sound and pad vibration proportional!
; Disable/enable the sensor with the Start button
;
;************************************************
;
;
;--------------------------------------------------------------------
;-------------Constants
;PS2 Controller / BotBoard II
DAT con P12
CMD con P13
SEL con P14
CLK con P15
SSC32 con p8

DeadZone con 28	; must be >= 28
PadMode con $79 ; Dualshock2 mode, use $73 with a Dualshock1

;Sharp GP2D12 IR sensor
GP2D12_Threshold con 250
GP2D12_SoundThreshold con 112 

;Pan & Tilt
PanPin con 28
PanNeutral con 1500
PanRange con 500	;Right and Left Range: min = PanNeutral - PanRange, max = PanNeutral + PanRange
TiltPin con 29
TiltNeutral con 1500
TiltRange con 500	;Right and Left Range: min = PanNeutral - TiltRange, max = PanNeutral + TiltRange
 
;--------------------------------------------------------------------				
;-------------Variables
index var Byte
DualShock var Byte(7)
LastButton var Byte(2)
XR var SWord
XL var SWord
GP2D12Enable var Bit
LockForward var Bit
MoveModePanAndTilt var bit 	;0 = Jog, 1 = linked to Joystick position
LargeMotor var Byte
Speed var Byte
MaxSpeed var Byte
H2_RH var word
H2_RM var word
H2_RL var word
H2_High var Word
H2_Middle var Word
H2_Low var word
GP2D12 var Word
PanPos var Sword
TiltPos var Sword

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
pause 2500

clear
high CLK

gosub Ps2Init
	
GP2D12Enable = 0	;0 = off, 1 = on
LockForward = 0
LargeMotor = 0
MoveModePanAndTilt = 0	;0 = Jog, 1 = linked to Joystick position
MaxSpeed = 80

LastButton(0) = 255
LastButton(1) = 255

;SSC-32 -> H2 engine
pause 500

;H2 Default
H2_RH = 2000 	;assume LH = (3000 - H2_RH) = 1000 !
H2_RM = 1333	;assume LM = (3000 - H2_RM) = 1667 !
H2_RL = 1000	;assume LL = (3000 - H2_RL) = 2000 !
H2_High = H2_RH
H2_Middle = H2_RM
H2_Low = H2_RL

gosub H2Init

;--------------------------------------------------------------------
;-------------Main loop
main
;DS2
	;Get the buttons
	low SEL
	shiftout CMD,CLK,FASTLSBPRE,[$1\8,$42\8]
	shiftin DAT,CLK,FASTLSBPOST,[DualShock(0)\8, DualShock(1)\8, DualShock(2)\8]
	high SEL
	pause 1
	;Get the joysticks
	low SEL 
	shiftout CMD,CLK,FASTLSBPRE,[$1\8,$42\8,$0\8,$0\8,LargeMotor\8]
	shiftin DAT,CLK,FASTLSBPOST,[DualShock(3)\8, DualShock(4)\8,DualShock(5)\8, DualShock(6)\8]
	high SEL
	pause 1
	;Deadband routine
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

;H2 Default
;H2_High = 2000 	;assume LH = (3000 - H2_RH) = 1000 !
;H2_Middle = 1333	;assume LM = (3000 - H2_RM) = 1667 !
;H2_Low = 1000	;assume LL = (3000 - H2_RL) = 2000 !

;H2	Presets
	if (DualShock(2).bit4 = 0) and LastButton(1).bit4 then	;Triangle Button test
			H2_High = 1900
			H2_Low = 1100
			H2_Middle = H2_Low
			MaxSpeed = 100
	elseif (DualShock(2).bit5 = 0) and LastButton(1).bit5	;Circle Button test
			H2_High = 2000
			H2_Low = 1000
			H2_Middle = (H2_High - H2_Low) / 3 + H2_Low
			MaxSpeed = 80
	elseif (DualShock(2).bit6 = 0) and LastButton(1).bit6	;Cross Button test
			H2_High = 2100
			H2_Low = 900
			H2_Middle = (H2_High - H2_Low) * 2 / 3 + H2_Low
			MaxSpeed = 60
	elseif (DualShock(2).bit7 = 0) and LastButton(1).bit7	;Square Button test
			H2_High = 2300
			H2_Low = 700
			H2_Middle = H2_High
			MaxSpeed = 40
	else
		goto L1L2Test
	endif
;Send data to SSC-32
		serout SSC32,i38400,["LH",DEC 3000 - H2_High," LM",DEC 3000 - H2_Middle," LL",DEC 3000 - H2_Low,13]
		serout SSC32,i38400,["RH",DEC H2_High," RM",DEC H2_Middle," RL",DEC H2_Low,13]
		Sound 9,[100\1318]	

L1L2Test
	if DualShock(2).bit2 = 0 then 	;L1 Button test
		;stuff
	endif
	if DualShock(2).bit0 = 0 then	;L2 Button test
		;stuff
	endif
UpDownTest
	if DualShock(1).bit4 = 0 then 	;Up Button test
		;stuff
	endif
	if DualShock(1).bit6 = 0 then	;Down Button test
		;stuff
	endif
R1R2Test	
	if DualShock(2).bit1 = 0 then	;R2 Button test
		;stuff
	endif
	if DualShock(2).bit3 = 0 then  	;R1 Button test
		;stuff
	endif
R3Test
	if (DualShock(1).bit2 = 0) and LastButton(0).bit2 then	;R3 Button test
		;stuff
	endif
StartTest
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
	XR = -ZCoord - WCoord
	XL = ZCoord - WCoord
;Min and Max lock	
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
;Prevent forward motion if obstical detected	
	if LockForward then
	 	if (XR > 0) then
			XR = 0
		endif
		if (XL > 0) then
			XL = 0
		endif
	endif
;Set speed to largest joystick value	
	if abs(WCoord) > abs(ZCoord) then
		Speed = abs(WCoord) * MaxSpeed / 100
	else
		Speed = abs(ZCoord) * MaxSpeed / 100
	endif
	
SpeedDirection
	serout SSC32,i38400,["XS",DEC Speed," XR",SDEC XR," XL",SDEC XL,13]

;Pan and Tilt
	if (DualShock(1).bit1 = 0) and LastButton(0).bit1 then	;L3 Button test
		MoveModePanAndTilt = MoveModePanAndTilt ^ 1
		Sound 9,[100\1318]
	endif
	if MoveModePanAndTilt then
		PanPos = abs(XCoord) * PanRange / 100	; **** due to bug in Basic ****
		if XCoord < 0 then
			PanPos = -PanPos
		endif
		TiltPos = abs(YCoord) * TiltRange / 100	; **** due to bug in Basic ****
		if YCoord > 0 then
			TiltPos = -TiltPos
		endif
	else
		PanPos = PanPos + (XCoord / 2)
		if PanPos > PanRange then
			PanPos = PanRange
		elseif PanPos < (-PanRange)
			PanPos = -PanRange	
		endif
		
		TiltPos = TiltPos - (YCoord / 2)
		if TiltPos > TiltRange then
			TiltPos = TiltRange
		elseif TiltPos < (-TiltRange)
			TiltPos = -TiltRange	
		endif
		
	endif
	serout SSC32,i38400,["#",DEC PanPin,"P",DEC (PanNeutral + PanPos) |
		," #",DEC TiltPin,"P",DEC (TiltNeutral + TiltPos)," T100",13]	
		
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
	
	LastButton(0) = DualShock(1)
	LastButton(1) = DualShock(2)
	pause 50
	goto main
	
;-------------Sub H2 Init
H2Init
	serout SSC32,i38400,[13]									;clear the SSC-32 buffers
	serout SSC32,i38400,["XS0 XSTOP",13]						;Stop the sequencer if running
	serout SSC32,i38400,["LF1700 RF1300 LR1300 RR1700",13] 	;Horizontal
	serout SSC32,i38400,["LH",DEC 3000 - H2_RH," LM",DEC 3000 - H2_RM," LL",DEC 3000 - H2_RL,13] 	;Vertical Left
	serout SSC32,i38400,["RH",DEC H2_RH," RM",DEC H2_RM," RL",DEC H2_RL,13]						;Vertical Right
	serout SSC32,i38400,["VS2500 HT500",13]					;Vertical Speed and Horizontal Time				
	serout SSC32,i38400,["XS0",13]							;Set Global Speed to 0
return
	
;-------------PS2 Initialization
Ps2Init
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
	if DualShock(0) <> PadMode then Ps2Init
return