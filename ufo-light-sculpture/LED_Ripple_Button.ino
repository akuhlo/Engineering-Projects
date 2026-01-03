// LED Ripple with Button
// Button connected to pin 8
// LEDs connected to pins 7, 6, 5, 4, 3, 2

const int buttonPin = 8;
const int ledPins[] = {7, 6, 5, 4, 3, 2};
const int numLEDs = 6;

void setup() {
  // Set button pin as input with internal pull-up resistor
  pinMode(buttonPin, INPUT_PULLUP);

  // Set LED pins as outputs
  for (int i = 0; i < numLEDs; i++) {
    pinMode(ledPins[i], OUTPUT);
    digitalWrite(ledPins[i], LOW);  // Ensure LEDs start OFF
  }
}

void loop() {
  // Button is ACTIVE LOW because of INPUT_PULLUP
  if (digitalRead(buttonPin) == LOW) {  
    // Turn LEDs on one by one
    for (int i = 0; i < numLEDs; i++) {
      digitalWrite(ledPins[i], HIGH);
      delay(100);
    }

    // Turn LEDs off one by one
    for (int i = 0; i < numLEDs; i++) {
      digitalWrite(ledPins[i], LOW);
      delay(100);
    }
  } else {
    // Ensure all LEDs are OFF when button is not pressed
    for (int i = 0; i < numLEDs; i++) {
      digitalWrite(ledPins[i], LOW);
    }
  }
}
