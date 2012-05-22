;************************************************
;************ Basic Atom with SSC-32 ************
;********** H2 program #7 : autonomous **********
;****** 3 Sharp GP2D12 IR Sensor Support ********
;********** Bot Board Buzzer support ************
;************************************************
;** Programmer: Laurent Gay, lynxrios@yahoo.fr **
;************************************************
;
;
;--------------------------------------------------------------------
;-------------Constants
 
;H2
H2_RH con 2000 	;assume LH = (3000 - H2_RH) = 1000 !
H2_RM con 1100	;assume LM = (3000 - H2_RM) = 1900 !
H2_RL con 1000	;assume LL = (3000 - H2_RL) = 2000 !
					
;--------------------------------------------------------------------				
;-------------Variables
XR var Sword
XL var Sword
XS var Byte

Rear_Detect var Word	;Rear Sensor
Left_Detect var Word	;Right sensor, left facing
Right_Detect var Word	;Left sensor, right facing

BackwardFlag var bit

;--------------------------------------------------------------------	
;***************
;*** Program ***
;***************

pause 500

Sound 9,[100\4435]

clear

serout p15,i38400,[13]									;clear the SSC-32 buffers	



serout p15,i38400,["XS0 XSTOP",13]						;Stop the sequencer if running
serout p15,i38400,["LF1700 RF1300 LR1300 RR1700",13] 	;Horizontal
serout p15,i38400,["LH",DEC 3000 - H2_RH," LM",DEC 3000 - H2_RM," LL",DEC 3000 - H2_RL,13] 	;Vertical Left
serout p15,i38400,["RH",DEC H2_RH," RM",DEC H2_RM," RL",DEC H2_RL,13]						;Vertical Right
serout p15,i38400,["VS2500 HT500",13]					;Vertical Speed and Horizontal Time				
serout p15,i38400,["XS0",13]							;Set Global Speed to 0

;-------------Main loop
main
	adin 16,Right_Detect	;Left sensor, right facing
	adin 17,Left_Detect 	;Right sensor, left facing
	adin 18,Rear_Detect 
	
	XR = XR + 10 - (Right_Detect / 10)
	XL = XL + 10 - (Left_Detect / 10)
	
	if Rear_Detect > 300 then
		XR = XR + (Rear_Detect / 10)
		XL = XL + (Rear_Detect / 10)
	endif
	
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
	
	if abs(XR) > abs(XL) then
		XS = abs(XR) * 2
	else
		XS = abs(XL) * 2
	endif
	
	if (XL < 0) and (XR < 0) then
		BackwardFlag = 1
	elseif (XL > 0) and (XR > 0) and (BackwardFlag)
		XR = 100
		XL = -100
		XS = 200
		
		BackwardFlag = 0	
	endif
	
	serout p15,i38400,["XS",DEC XS," XR",SDEC XR," XL",SDEC XL,13]
	
	nap 1 ;internal sleep mode, approx 19ms
	
	goto main