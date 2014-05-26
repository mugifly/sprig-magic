/**
  Remote Aircon
  @author Masanori Ohgita
**/

#include <SoftwareSerial.h>
#include <String.h>
#include "aircon.h"

static int PIN_SOLENOID_POWER = 4;
static int PIN_SOLENOID_TEMP_UP = 5;
static int PIN_SOLENOID_TEMP_DOWN = 6;
static int PIN_BT_RX = 8;
static int PIN_BT_TX = 7;

AirCon airCon(false);
SoftwareSerial btSerial(PIN_BT_RX, PIN_BT_TX);

struct {
  boolean isCmdDefined;
  String cmd;
  String value;
} cmdBuffer;

void setup() {
  // Set the pin-mode
  pinMode(PIN_SOLENOID_POWER, OUTPUT);
  pinMode(PIN_SOLENOID_TEMP_UP, OUTPUT);
  pinMode(PIN_SOLENOID_TEMP_DOWN, OUTPUT);
  // Initialize the command buffer
  cmdBuffer.isCmdDefined = false;
  cmdBuffer.cmd = "";
  cmdBuffer.value = "";
  // Initialize serial communication
  Serial.begin(9600);
  btSerial.begin(9600);
}

void loop() {
  char c = '\n';
  if (btSerial.available()) {
    c = btSerial.read();
    //Serial.write( c );
  } else if (Serial.available()) {
    c = Serial.read();
    btSerial.write(c);
  }

  if (c == '=') { // Separater of an command and a value
    Serial.println("Command is finalized: " + cmdBuffer.cmd);
    cmdBuffer.isCmdDefined = true; //Marked as command finalized.
  } else if (c == ';') { // End-mark of the command and value
    if (cmdBuffer.cmd != "") { // Parse the command and value
      Serial.println("Command and value is received:  " + cmdBuffer.cmd);

      if (cmdBuffer.cmd == "set_power") {
        // Turn on / off the power
        if (cmdBuffer.value == "true") {
          Serial.println("Set power turn on");
          airCon.turnPower(true);
        } else {
          Serial.println("Set power turn off");
          airCon.turnPower(false);
        }
      } else if (cmdBuffer.cmd == "get_power") {
        Serial.println("log=power_brightness_sensor_value_" + String(airCon.getPowerBrightSensor()) + ";");
        // Get the power
        if (airCon.getIsRunning()) {
          Serial.println("power=true;");
          btSerial.println("power=true;");
        } else {
          Serial.println("power=false;");
          btSerial.println("power=false;");
        }
      } else if (cmdBuffer.cmd == "get_power_sensor_val") {
        // Get a value of the power brightness sensor
        int v = airCon.getPowerBrightSensor();
        Serial.println("get_power_sensor_val=" + String(v) + ";");
        btSerial.println("get_power_sensor_val=" + String(v) + ";");
      } else if (cmdBuffer.cmd == "set_temp") {
        // Set the temperature
        Serial.println("Set the temperature to " + cmdBuffer.value);
        int set_temperature = atoi(cmdBuffer.value.c_str());
        airCon.setTemperature(set_temperature);
      } else if (cmdBuffer.cmd == "get_settemp") {
        // Get the set-temperature (Callback with BT serial)
        int temp = airCon.getLatestSetTemperature();
        Serial.println("get_settemp - settemp=" + String(temp));
        btSerial.println("settemp=" + String(temp) + ";");
      } else if (cmdBuffer.cmd == "get_realtemp") {
        // Get the real temperature (Callback with BT serial)
        float temp = airCon.getRealTemperature();
        Serial.println("realtemp=" + String(temp) + ";");
        btSerial.println("realtemp=" + String(temp) + ";");
      } else {
        // Unknown command
        Serial.println("Unknown command - " + cmdBuffer.cmd + "=" + cmdBuffer.value);
      }

    }
    cmdBuffer.isCmdDefined = false;
    cmdBuffer.cmd = "";
    cmdBuffer.value = "";
  } else if (c != '\r' && c != '\n') {
    Serial.println(c);
    if (cmdBuffer.cmd != "" && cmdBuffer.isCmdDefined) {
      // Append to the value buffer of the command
      cmdBuffer.value += c;
    } else {
      // Append to the command buffer of the command
      cmdBuffer.cmd += c;
    }
  }
}
