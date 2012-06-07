unsigned long time;
int dist = 175; //the value at which to activate the ir sensors

short ir_Sense_Flag = 0;
short Cruise_Flag = 0;
short ir_Move_Command = 0;
short Cruise_Move_Command = 0;
short Legs_Move_Command  = 0;

unsigned long Stuck_Timer = 0;

void setup()
{
  Serial.begin(115200);
  delay(1000);
  Serial.println("LH1000 LM1333 LL2000 RH2000 RM1667 RL1000 VS3000");
  Serial.println("LF1700 LR1300 RF1300 RR1700 HT750");
}

void Walk(int xl=100, int xr=100, int xs=200)  //Function to make the robot walk
{
  Serial.print("XL");
  Serial.print(xl);
  Serial.print(" XR");
  Serial.print(xr);
  Serial.print(" XS");
  Serial.println(xs);
}

void ir_Sense(int x = 0)    //React to objects in the way of the robot
{
  if(analogRead(0) < dist && analogRead(1) < dist)
  {
    ir_Sense_Flag = 0;
    return;
  }
  else if(analogRead(0) > dist)
  {
    if(millis() - Stuck_Timer < 1000)  // Check if Oscillation is occuring
    {  
      ir_Sense_Flag = 1;
      ir_Move_Command = 3;
    }
    else
    {
      ir_Sense_Flag = 1;
      ir_Move_Command = 2;
    }
  }
  else
  {
    if(millis() - Stuck_Timer < 1000)
    {  
      ir_Sense_Flag = 1;
      ir_Move_Command = 2;
    }
    else
    {
      ir_Sense_Flag = 1;
      ir_Move_Command = 3;
    }
  }    
}
    
void Cruise()  //Make the Robot walk forward
{
  Cruise_Flag = 1;
  Cruise_Move_Command = 1;
}

void Legs_Move(short x)
{
  if(x == 0)
    Walk(0, 0);      //Stop
  else if(x == 1)
  {
    Walk(100, 100);  //Forward
    delay(50);
  }
  else if(x == 2)
  {
    Walk(-100, 100); //Right
    delay(4000);
    Stuck_Timer = millis();  //set the timer to prevent oscillation between left and right
  }
  else if(x == 3)
  {
    Walk(100, -100); //Left
    delay(4000);
    Stuck_Timer = millis();  //set the timer to prevent oscillation between left and right
  }
}


void Arbitrate()  //Check for conflicts between processes and choose the corrent behavior
{
  if(Cruise_Flag)
    Legs_Move_Command = Cruise_Move_Command;
  if(ir_Sense_Flag)
    Legs_Move_Command = ir_Move_Command;
  Legs_Move(Legs_Move_Command);
    
}

void loop()
{
  ir_Sense();
  Cruise();
  Arbitrate();
  delay(100);
}

