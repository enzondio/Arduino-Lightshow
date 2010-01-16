#include "Tlc5940.h"

// Data smoothing
#define filterSamples   50              // filterSamples should  be an odd number, no smaller than 3
int sensSmoothArray [filterSamples];   // array for holding raw sensor values for sensor1 
int rawData, smoothData;  // variables for sensor1 data
int pingPin = 7;

// Color business.
float red_offset = 0;
float blue_offset = 0;
float green_offset = 0;
float base_freq = 1.5;
float red_freq = 0.2;
float blue_freq = 0.4;
float green_freq = 0.6;
float red_mag = 1024;
float blue_mag = 2048;
float green_mag = 2048;
float step_size = 200;

// TLC
int num_of_leds = 12;

void setup()
{
  Tlc.init();
  Serial.begin(9600);
}

void loop()
{
 float duration = get_ping_duration();
 float m = millis();
 
 // Use the duration to calculate our base frequency.  Smoothing the data will avoid
 // rough transitions and bounciness.
 base_freq =(1.5/duration)*10000;
 base_freq = base_freq*base_freq;
 base_freq =  digitalSmooth(base_freq, sensSmoothArray);  // every sensor you use with digitalSmooth needs its own array
 
 Tlc.clear();

 for (int i = 0; i < num_of_leds; i++) {
   // Use the base frequency plus each color frequency and offset to set each LED
   red(i, sin(((base_freq+ red_freq)*(m + i*step_size) + red_offset)/1000.0));
   blue(i, sin(((base_freq+ blue_freq)*(m + i*step_size) + blue_offset)/1000.0));
   green(i, sin(((base_freq+ green_freq)*(m + i*step_size) + green_offset)/1000.0));
 }
    
 Tlc.update();
 delay(30);
}

float get_ping_duration() {
  // The PING))) is triggered by a HIGH pulse of 2 or more microseconds.
  // We give a short LOW pulse beforehand to ensure a clean HIGH pulse.
  pinMode(pingPin, OUTPUT);
  digitalWrite(pingPin, LOW);
  delayMicroseconds(2);
  digitalWrite(pingPin, HIGH);
  delayMicroseconds(5);
  digitalWrite(pingPin, LOW);

  // The same pin is used to read the signal from the PING))): a HIGH
  // pulse whose duration is the time (in microseconds) from the sending
  // of the ping to the reception of its echo off of an object.
  pinMode(pingPin, INPUT);
  return pulseIn(pingPin, HIGH); 
 
}

void red(int index, float val) {
  Tlc.set(index*3, val*red_mag + red_mag);
}
void blue(int index, float val) {
  Tlc.set(index*3 + 1, val*blue_mag + blue_mag);
}
void green(int index, float val) {
  Tlc.set(index*3 + 2, val*green_mag + green_mag);
}

int digitalSmooth(int rawIn, int *sensSmoothArray){     // "int *sensSmoothArray" passes an array to the function - the asterisk indicates the array name is a pointer
  int j, k, temp, top, bottom;
  long total;
  static int i;
 // static int raw[filterSamples];
  static int sorted[filterSamples];
  boolean done;

  i = (i + 1) % filterSamples;    // increment counter and roll over if necc. -  % (modulo operator) rolls over variable
  sensSmoothArray[i] = rawIn;                 // input new data into the oldest slot

  // Serial.print("raw = ");

  for (j=0; j<filterSamples; j++){     // transfer data array into anther array for sorting and averaging
    sorted[j] = sensSmoothArray[j];
  }

  done = 0;                // flag to know when we're done sorting              
  while(done != 1){        // simple swap sort, sorts numbers from lowest to highest
    done = 1;
    for (j = 0; j < (filterSamples - 1); j++){
      if (sorted[j] > sorted[j + 1]){     // numbers are out of order - swap
        temp = sorted[j + 1];
        sorted [j+1] =  sorted[j] ;
        sorted [j] = temp;
        done = 0;
      }
    }
  }

  // throw out top and bottom 15% of samples - limit to throw out at least one from top and bottom
  bottom = max(((filterSamples * 15)  / 100), 1); 
  top = min((((filterSamples * 85) / 100) + 1  ), (filterSamples - 1));   // the + 1 is to make up for asymmetry caused by integer rounding
  k = 0;
  total = 0;
  for ( j = bottom; j< top; j++){
    total += sorted[j];  // total remaining indices
    k++; 
  }

  return total / k;    // divide by number of samples
}

