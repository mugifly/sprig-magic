/**
  Aircon class
  @author Masanori Ohgita
**/
#include <Arduino.h>

class AirCon {
  public:
    // Constructor
    AirCon(bool power_turn_on) {
      // Set the environment
      temperature_min = 18;
      temperature_max = 30;
      power_bright_sensor_threshold = 100; // 0 - 1000
      pin_power_bright_sensor = 0; // Analog
      pin_temperature_sensor = 2; // Analog
      pin_solenoid_power = 4;
      pin_solenoid_temp_up = 5;
      pin_solenoid_temp_down = 6;
      solenoid_delay_msec = 300; // 0.3 sec
      // Set the temperature
      if (power_turn_on) {
        temperature_init();
      } else {
        set_temperature = -1;
      }
    }

    // Get whether is running the aircon
    bool getIsRunning() {
      if (getPowerBrightSensor() < power_bright_sensor_threshold) {
        return false; // Power is off
      }
      return true; // Power is on
    }

    // Get a value of bright sensor for power status
    int getPowerBrightSensor() {
      return analogRead(pin_power_bright_sensor);
    }
    
    // Get the latest real-temperature
    float getRealTemperature() {
      int ad = analogRead(pin_temperature_sensor);
      // Convert the AD value to mV value
      float mv = ((long)ad * 5000) / 1024;
      // Subtract the offset of voltage
      float temperature = (mv - 500) / 10;
      
      return temperature;
    }
    
    // Get the latest set-temperature
    int getLatestSetTemperature() {
      return set_temperature;
    }
    
    // Turn on / off the power
    void turnPower(bool power) {
      if (power && !getIsRunning())
        // Turn on
        pushBtnPower();
      else if (!power && getIsRunning())
        // Turn off
        pushBtnPower();
    }

    // Set the temperature
    void setTemperature(int target_temp) {
      if (!getIsRunning())
        return;
      if (getLatestSetTemperature() == -1)
        temperature_init();

      if (target_temp < set_temperature) {
        // Down the temperature
        while (target_temp < set_temperature) {
          pushBtnTempDown();
          set_temperature--;
        }
      } else {
        // Up the temperature
        while (set_temperature < target_temp) {
          pushBtnTempUp();
          set_temperature++;
        }
      }
    }

  protected:
    int solenoid_delay_msec;
    int temperature_min;
    int temperature_max;
    int power_bright_sensor_threshold;
    int pin_power_bright_sensor;
    int pin_temperature_sensor;
    int pin_solenoid_power;
    int pin_solenoid_temp_up;
    int pin_solenoid_temp_down;
    int set_temperature;

    // Initialize
    void temperature_init() {
      // Initialize the temperature to minimum temperature.
      for (int i = 0; i < temperature_max - temperature_min; i++) {
        pushBtnTempDown();
      }
      set_temperature = temperature_min;
    }

    // Push the power button
    void pushBtnPower() {
      digitalWrite(pin_solenoid_power, HIGH);
      delay(solenoid_delay_msec);
      digitalWrite(pin_solenoid_power, LOW);
      delay(solenoid_delay_msec);
    }

    // Push the temperature up button
    void pushBtnTempUp() {
      digitalWrite(pin_solenoid_temp_up, HIGH);
      delay(solenoid_delay_msec);
      digitalWrite(pin_solenoid_temp_up, LOW);
      delay(solenoid_delay_msec);
    }

    // Push the temperature down button
    void pushBtnTempDown() {
      digitalWrite(pin_solenoid_temp_down, HIGH);
      delay(solenoid_delay_msec);
      digitalWrite(pin_solenoid_temp_down, LOW);
      delay(solenoid_delay_msec);
    }
};

