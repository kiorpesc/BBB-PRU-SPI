/***********************************
128 by 64 LCD Logic Analyzer 6 channel and 3Mb/s
By Bob Davis
Uses Universal 8bit Graphics Library, http://code.google.com/p/u8glib/
  Copyright (c) 2012, olikraus@gmail.com   All rights reserved.

********************************************/


int Sample[128];
int Input=0;
int OldInput=0;
int xpos=0;
 


void draw(void) {
 
// wait for a trigger of CS going negative
  while ((PINC & 0x01));
// collect the analog data into an array
// No loop is about 50% faster!
    Sample[0]=PINC;
    Sample[1]=PINC;    Sample[2]=PINC;    Sample[3]=PINC;    Sample[4]=PINC;    
    Sample[5]=PINC;    Sample[6]=PINC;    Sample[7]=PINC;    Sample[8]=PINC;
    Sample[9]=PINC;    Sample[10]=PINC;    Sample[11]=PINC;    Sample[12]=PINC;
    Sample[13]=PINC;    Sample[14]=PINC;    Sample[15]=PINC;    Sample[16]=PINC;    
    Sample[17]=PINC;    Sample[18]=PINC;    Sample[19]=PINC;    Sample[20]=PINC;
    Sample[21]=PINC;    Sample[22]=PINC;    Sample[23]=PINC;    Sample[24]=PINC;
    Sample[25]=PINC;    Sample[26]=PINC;    Sample[27]=PINC;    Sample[28]=PINC;
    Sample[29]=PINC;    Sample[30]=PINC;    Sample[31]=PINC;    Sample[32]=PINC;
    Sample[33]=PINC;    Sample[34]=PINC;    Sample[35]=PINC;    Sample[36]=PINC;
    Sample[37]=PINC;    Sample[38]=PINC;    Sample[39]=PINC;    Sample[40]=PINC;
    Sample[41]=PINC;    Sample[42]=PINC;    Sample[43]=PINC;    Sample[44]=PINC;
    Sample[45]=PINC;    Sample[46]=PINC;    Sample[47]=PINC;    Sample[48]=PINC;
    Sample[49]=PINC;    Sample[50]=PINC;    Sample[51]=PINC;    Sample[52]=PINC;
    Sample[53]=PINC;    Sample[54]=PINC;    Sample[55]=PINC;    Sample[56]=PINC;
    Sample[57]=PINC;    Sample[58]=PINC;    Sample[59]=PINC;    Sample[60]=PINC;
    Sample[61]=PINC;    Sample[62]=PINC;    Sample[63]=PINC;    Sample[64]=PINC;
    Sample[65]=PINC;    Sample[66]=PINC;    Sample[67]=PINC;    Sample[68]=PINC;
    Sample[69]=PINC;    Sample[70]=PINC;    Sample[71]=PINC;    Sample[72]=PINC;
    Sample[73]=PINC;    Sample[74]=PINC;    Sample[75]=PINC;    Sample[76]=PINC;
    Sample[77]=PINC;    Sample[78]=PINC;    Sample[79]=PINC;    Sample[80]=PINC;
    Sample[81]=PINC;    Sample[82]=PINC;    Sample[83]=PINC;    Sample[84]=PINC;
    Sample[85]=PINC;    Sample[86]=PINC;    Sample[87]=PINC;    Sample[88]=PINC;
    Sample[89]=PINC;    Sample[90]=PINC;    Sample[91]=PINC;    Sample[92]=PINC;
    Sample[93]=PINC;    Sample[94]=PINC;    Sample[95]=PINC;    Sample[96]=PINC;
    Sample[97]=PINC;    Sample[98]=PINC;    Sample[99]=PINC;    Sample[100]=PINC;
    Sample[101]=PINC;    Sample[102]=PINC;    Sample[103]=PINC;    Sample[104]=PINC;
    Sample[105]=PINC;    Sample[106]=PINC;    Sample[107]=PINC;    Sample[108]=PINC;
    Sample[109]=PINC;    Sample[110]=PINC;    Sample[111]=PINC;    Sample[112]=PINC;
    Sample[113]=PINC;    Sample[114]=PINC;    Sample[115]=PINC;    Sample[116]=PINC;
    Sample[117]=PINC;    Sample[118]=PINC;    Sample[119]=PINC;    Sample[120]=PINC;
    Sample[121]=PINC;    Sample[122]=PINC;    Sample[123]=PINC;    Sample[124]=PINC;
    Sample[125]=PINC;    Sample[126]=PINC;    Sample[127]=PINC;

// display the collected analog data from array
  for(int xpos=0; xpos<128; xpos++) {
    Serial.println(Sample[xpos]);
  }
  Serial.println("-------------------------------------------");
}

void setup(void) {
  pinMode(A0, INPUT);
  pinMode(A1, INPUT);
  pinMode(A2, INPUT);
  pinMode(A3, INPUT);
  pinMode(A4, INPUT);
  pinMode(A5, INPUT);

  Serial.begin(115200);
}

void loop(void) {
  draw(); 
  delay(100);
}
