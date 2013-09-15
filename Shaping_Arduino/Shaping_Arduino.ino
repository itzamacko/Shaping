// ---------------------------------------------------------------------------
// Shaping - Arduino v. 1.0
// COPYRIGHT © 2013 Oskar Pineño
// ---------------------------------------------------------------------------
// You are welcome to use this program for teaching and/or research purposes.
// Please do NOT make any copies or distribute this program to other people.
// ---------------------------------------------------------------------------

#include <Servo.h> 

Servo servo;

const int ledPin = 13;
const int servoPin = 12;
const int manualDeliveryPin = 11;

const int servoRest = 10;
const int servoServe = 150;

byte rxByte;

void setup ()
{
  Serial.begin (9600);
  Serial.println("Shaping in progress...");
  
  servo.attach(servoPin);
  pinMode (ledPin, OUTPUT);
  pinMode (manualDeliveryPin, INPUT);
  digitalWrite (manualDeliveryPin, HIGH);
  
  servo.write(servoRest);
  digitalWrite (ledPin, HIGH);
  delay (500);
  digitalWrite (ledPin, LOW);
}

void loop ()
{
  if (Serial.available() > 0)
  {
    rxByte = Serial.read();
    if (rxByte == 1)
        pelletDelivery();
    if (rxByte == 0)
        endOfTraining();
  }
  if (digitalRead(manualDeliveryPin) == LOW)
    pelletDelivery();
  delay (10);
}


void pelletDelivery ()
{
  servo.write(servoServe);
  digitalWrite (ledPin, HIGH);
  delay(500);
  servo.write(servoRest);
  digitalWrite (ledPin, LOW);
}

void endOfTraining ()
{
  servo.write(servoRest);
  for (int i=0; i<10; i++)
  {
    digitalWrite (ledPin, HIGH);
    delay(100);
    digitalWrite (ledPin, LOW);
    delay(100);
  }
}
