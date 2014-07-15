/********************
 *    Guitar Tuner
 *
 *    Cody Geary
 *    15 July 2014
 *
 *   -Displays red and blue waves that align when you play the right note
 *   -Shows a small FFT spectrum plot, peaks are each 4% away from the target note
 *   -The circle plot shrinks down to a point when the target note is hit
 *
 *********************/
 
import ddf.minim.*;  //import audio input library
import ddf.minim.analysis.*;  //import the FFT filter library
Minim minim; AudioInput in; FFT fftLin;

int scale_select = 0;  //initialize the octave selector

//  FULL CHROMATIC SCALE
float[][] Scales = {
{12,55,58.27,61.74,65.41,69.3,73.42,77.78,82.41,87.31,92.5,98,103.83},
{12,110,116.54,123.47,130.81,138.59,146.83,155.56,164.81,174.61,185,196,207.65},
{12,220,233.08,246.94,261.63,277.18,293.66,311.13,329.63,349.23,369.99,392,415.3},
{12,440,466.16,493.88,523.25,554.37,587.33,622.25,659.26,698.46,739.99,783.99,830.61},
{12,880,932.33,987.77,1046.5,1108.73,1174.66,1244.51,1318.51,1396.91,1479.98,1567.98,1661.22},
{12,1760,1864.66,1975.53,2093,2217.46,2349.32,2489.02,2637.02,2793.83,2959.96,3135.96,3322.44}};
   
String[][] Names = {
{"1","A1","A#1/Bb1","B1","C2","C#2/Db2","D2","D#2/Eb2","E2","F2","F#2/Gb2","G2","G#2/Ab2"},
{"2","A2","A#2/Bb2","B2","C3","C#3/Db3","D3","D#3/Eb3","E3","F3","F#3/Gb3","G3","G#3/Ab3"},
{"3","A3","A#3/Bb3","B3","C4","C#4/Db4","D4","D#4/Eb4","E4","F4","F#4/Gb4","G4","G#4/Ab4"},
{"4","A4","A#4/Bb4","B4","C5","C#5/Db5","D5","D#5/Eb5","E5","F5","F#5/Gb5","G5","G#5/Ab5"},
{"5","A5","A#5/Bb5","B5","C6","C#6/Db6","D6","D#6/Eb6","E6","F6","F#6/Gb6","G6","G#6/Ab6"},
{"6","A6","A#6/Bb6","B6","C7","C#7/Db7","D7","D#7/Eb7","E7","F7","F#7/Gb7","G7","G#7/Ab7"}};

int num_scales=6;  //total number of octaves or scales in the array, this time 6

float Buffer[] = new float [18192];   //buffer size set very large to prevent overflow... (not graceful, I know)
float AvgBuffer[] = new float[18192];
float freqmax = 0; int [] freqhit = {0,0}; float freqpeak=0; //variables for choosing the note

boolean mute=true;  //toggles if we mute the display, ie when it's just background noise.

void setup()
{
  size(1000, 400, P2D);
  minim = new Minim(this);  
  in = minim.getLineIn(Minim.MONO, 8192, 44100);   //the buffer size (4096) must be a power of 2 for the FFT to work. The sample rate is 44100 as default.
  frameRate(44100/8192*10);
    
}

void draw()
{
  smooth();
  background(10,10,10);
  stroke(255);
 
  for (int i=0; i< in.bufferSize()-20; i++) {  //produce a moving average of the data and a copy, and store in the buffer
    AvgBuffer[i] = (in.mix.get(i)+in.mix.get(i+2)+in.mix.get(i+4)+in.mix.get(i+6)+in.mix.get(i+8)+in.mix.get(i+10)+in.mix.get(i+12)+in.mix.get(i+14)+in.mix.get(i+16)+in.mix.get(i+18))/10;
    Buffer[i] = in.mix.get(i); }
   
  int peakmax=0;  float peakvalue=0;  //vars for keeping track of the maximum input level    
  for(int i = 0; i < in.bufferSize()-20; i++) { //Scan through the averaged input buffer and find the biggest peak
    if ( AvgBuffer[i] > (peakvalue) ) {
      peakvalue=in.mix.get(i);
      if ( abs(AvgBuffer[i])<.005 ) {   //if the largest peak is less than a threshhold, then mute the plot so it looks less noisy
        peakvalue=AvgBuffer[i]*.01/abs(AvgBuffer[i])*4;
        mute=true;
        freqpeak=0; freqmax=0;  //reset the FFT max counter
      } else {mute=false;}
      if ( i<in.bufferSize()/3 ) {  // only choose max-peak positions in the first 1/3 of the buffer, since we will plot multiple wavelenths
        peakmax=i;
      }
    }
  }
    
  float freq = 0; int delay=0;   float decay = 1.02; int space = -(height/16); int interval; float viewscale; float wide=4*width/5;
  float point1; float point2; float point3; float point4;
  float wavesize=height/8;  float num_strings = Scales[scale_select][0];
  fill(255,255,255);

  for (int j=0; j<num_scales; j++) {                                //<-Loop through the Scales
     scale_select=j;

     for (int n=0; n<num_strings; n++) {                   //<-this loop cycles through each string
          freq = Scales[scale_select][n+1];                //<-pick the frequency of the string from the scale array
          
          if (freq>106){ fftLin = new FFT( 8192, 22050 ); }  //for higher frequencies use the high frequency spectrum
          else         { fftLin = new FFT( 8192, 22050 ); }  //for frequencies 200Hz or lower use the low frequency spectrum, but now set to be both the same though   
          fftLin.forward(in.mix);     

      //find the strongest FFT signal in the current buffer
       float newfreqmax = 0; int [] newfreqhit = {0,0}; float newfreqpeak=0;  //variables for choosing the note
       if ( ( fftLin.getFreq(freq) > freqmax) && (freq>50) && (freq<1662) ) { 
       newfreqmax = fftLin.getFreq(freq);
       newfreqhit [0]= scale_select;
       newfreqhit [1]= n+1;
       newfreqpeak = fftLin.getFreq(freq);
       }
       
       if (newfreqpeak > freqpeak) {  //only replace the frequency when we get a new top hit, so avoid switching when it decays
          freqmax = newfreqmax;
          freqhit [0]= newfreqhit [0];  
          freqhit [1]= newfreqhit [1]; 
          freqpeak = newfreqpeak;      
       }
  }
  }

  space=250; //how far from the top to draw the graph
     freq = Scales[freqhit[0]][freqhit[1]];                  //<-pick the frequency of the string from the scale array

     textSize(60);
     if (!mute) {text(Names[freqhit[0]][freqhit[1]], 80, 80);}         //<-pick the name of the string to display on the screen
     
     delay = round(44100/freq);   interval = delay*(2);   viewscale = (wide)/interval; 
     
     for (int i = 0; i < interval; i++) {     //WAVEFORM Draw
       point1 = Buffer[i+peakmax]/peakvalue; point2 = Buffer[i+peakmax+1]/peakvalue;
       point3 = Buffer[i+peakmax+delay]/peakvalue; point4 = Buffer[i+peakmax+delay+1]/peakvalue;  
       stroke(255,0,0);
       line( i*(viewscale)+30, space + point1*wavesize, (i+1)*(viewscale)+30, space + point2*wavesize );
       stroke(100,100,255);
       line( i*(viewscale)+30, space + point3*wavesize*decay, (i+1)*(viewscale)+30, space + point4*wavesize*decay );
     }
         
     
     if (freq>106){ fftLin = new FFT( 8192, 22050 ); }  //for higher frequencies use the high frequency spectrum
     else         { fftLin = new FFT( 8192, 22050 ); }  //for frequencies 200Hz or lower use the low frequency spectrum, but here set to be the same always   
     fftLin.forward(in.mix);      //draw the FFT spectrum analysis with bars every 2%
     strokeWeight(4); stroke(150,150,150);
     int startfreq = 4*width/5 + width/10; float eqscale=0.25;
     line(startfreq,    space, startfreq,    space-fftLin.getFreq(freq*.76)*eqscale);
     line(startfreq+5,  space, startfreq+5,  space-fftLin.getFreq(freq*.79)*eqscale);
     line(startfreq+10, space, startfreq+10, space-fftLin.getFreq(freq*.82)*eqscale);
     line(startfreq+15, space, startfreq+15, space-fftLin.getFreq(freq*.85)*eqscale); 
     line(startfreq+20, space, startfreq+20, space-fftLin.getFreq(freq*.88)*eqscale);
     line(startfreq+25, space, startfreq+25, space-fftLin.getFreq(freq*.91)*eqscale);
     line(startfreq+30, space, startfreq+30, space-fftLin.getFreq(freq*.94)*eqscale);
     line(startfreq+35, space, startfreq+35, space-fftLin.getFreq(freq*.97)*eqscale);   
  
     stroke(255,255,255);   //make the center frequency bright white
     line(startfreq+40, space, startfreq+40, space-fftLin.getFreq(freq)*eqscale); 
     stroke(150,150,150);
     
     line(startfreq+45, space, startfreq+45, space-fftLin.getFreq(freq*1.03)*eqscale);
     line(startfreq+50, space, startfreq+50, space-fftLin.getFreq(freq*1.06)*eqscale);  
     line(startfreq+55, space, startfreq+55, space-fftLin.getFreq(freq*1.09)*eqscale); 
     line(startfreq+60, space, startfreq+60, space-fftLin.getFreq(freq*1.12)*eqscale);
     line(startfreq+65, space, startfreq+65, space-fftLin.getFreq(freq*1.15)*eqscale);
     line(startfreq+70, space, startfreq+70, space-fftLin.getFreq(freq*1.18)*eqscale);  
     line(startfreq+75, space, startfreq+75, space-fftLin.getFreq(freq*1.21)*eqscale); 
     line(startfreq+80, space, startfreq+80, space-fftLin.getFreq(freq*1.25)*eqscale);

     strokeWeight(1);  
     
     float outoftune=( (fftLin.getFreq(freq*1.03)+fftLin.getFreq(freq*1.06) )-(fftLin.getFreq(freq*.97)+fftLin.getFreq(freq*.94)) );
     textSize(20);
     if (!mute) {
      float threshold=5;  //set the sensitivity of the green dot and red arrows 
      fill(255,100,100);
      if (outoftune>threshold) {triangle(395, 80, 365, 55, 395, 30);}
      if (outoftune<-threshold) {triangle(400, 80, 430, 55, 400, 30);}
      ellipseMode(CENTER);
      if (abs(outoftune)<threshold) {
      fill(0,200,0);
      ellipse(397.5,55,30,30);}
     }
     
     
}

void stop()
{
  // close Minim audio classes when you are done with them
  in.close();
  minim.stop();  
  super.stop();
}
