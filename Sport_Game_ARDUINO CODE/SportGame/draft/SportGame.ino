/*
  Button

  Turns on and off a light emitting diode(LED) connected to digital pin 13,
  when pressing a pushbutton attached to pin 2.

  The circuit:
  - LED attached from pin 13 to ground through 220 ohm resistor
  - pushbutton attached to pin 2 from +5V
  - 10K resistor attached to pin 2 from ground

  - Note: on most Arduinos there is already an LED on the board
    attached to pin 13.

  created 2005
  by DojoDave <http://www.0j0.org>
  modified 30 Aug 2011
  by Tom Igoe

  This example code is in the public domain.

  https://www.arduino.cc/en/Tutorial/BuiltInExamples/Button
*/

// constants won't change. They're used here to set pin numbers:
const int buttonPin = 5;  // the number of the pushbutton pin
const int ledPin = 33;    // the number of the LED pin

// variables will change:
int buttonState = 1;  // variable for reading the pushbutton status
int light = 1;
void setup() {
  // initialize the LED pin as an output:
  Serial.begin(9600);
  pinMode(ledPin, OUTPUT);
  // initialize the pushbutton pin as an input:
  pinMode(buttonPin, INPUT);
  digitalWrite(ledPin, HIGH);
}


void loop() {
  buttonState = digitalRead(buttonPin);
  Serial.println(buttonState);

  if(buttonState == LOW && light == 1){
    digitalWrite(ledPin, LOW);
    delay(500);
    light = 0;
  }
  
  buttonState = digitalRead(buttonPin);

  if(buttonState == LOW && light == 0){
    digitalWrite(ledPin, HIGH);
    delay(500);
    light = 1;
  }

}
/*
  // read the state of the pushbutton value:
  // check if the pushbutton is pressed. If it is, the buttonState is HIGH:
  while (buttonState == LOW) {
    Serial.println("test1");
    Serial.println(buttonState);
    // turn LED off:
    digitalWrite(ledPin, LOW);
    buttonState = digitalRead(buttonPin);
  }
   while (buttonState == HIGH) {
    Serial.println("test2");
    Serial.println(buttonState);
    // turn LED on:
    digitalWrite(ledPin, HIGH);
    buttonState = digitalRead(buttonPin);

  }
}*/
