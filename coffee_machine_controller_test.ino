#include <Wire.h>
#include <Adafruit_MCP23X08.h>
#include <Adafruit_BME280.h>
#include <Adafruit_AD569x.h>
#include <MCP342x.h>

// Whether we're building for ESP32 or not
#undef ESP32

// Pin    Arduino pin     ESP32 GPIO     Function
// ---    -----------     ----------     --------
// D0      0              44             -
// D1      1              43             -
// D2      2               5             I/O interrupt
// D3      3               6             Accessory 2
// D4      4               7             Accessory 1
// D5      5               8             Water pump control
// D6      6               9             Fill valve control
// D7      7              10             Water valve control
// D8      8              17             Steam boiler control
// D9      9              18             Coffee boiler control
// D10    10              21             SPI_CS
// D11    11              38             SPI_MOSI
// D12    12              47             SPI_MISO
// D13    13              48             SPI_SCLK
// LED_R  14              46             -
// LED_G  15               0             -
// LED_B  16              45             -
// A0     17               1             -
// A1     18               2             Pressurestat
// A2     19               3             Boiler level sensor
// A3     20               4             Tank level sensor
// A4     21              11             I2C_SDA
// A5     22              12             I2C_SCL
// A6     23              13             -
// A7     24              14             Gear pump tachometer


#ifdef ESP32 // We are using GPIO numbering

#define IO_INTERRUPT            5
#define WATER_PUMP              8
#define ACCESSORY_1             7
#define ACCESSORY_2             6
#define WATER_VALVE             10
#define FILL_VALVE              9
#define STEAM_BOILER            17
#define COFFEE_BOILER           18

#define LED_R                   46
#define LED_G                   0
#define LED_B                   45

#define PRESSURESTAT            2
#define BOILER_AUTOFILL_PROBE   3
#define RESERVOIR_LEVEL_PROBE   4
#define TACHOMETER              14

#else // Arduino IoT 33

#define IO_INTERRUPT            2
#define WATER_PUMP              5
#define ACCESSORY_1             4
#define ACCESSORY_2             3
#define WATER_VALVE             7
#define FILL_VALVE              6
#define STEAM_BOILER            8
#define COFFEE_BOILER           9

#define PRESSURESTAT            A1
#define BOILER_AUTOFILL_PROBE   A2
#define RESERVOIR_LEVEL_PROBE   A3
#define TACHOMETER              A7

#endif // ESP32 or IoT 33

// These are the port numbers for the I/O expander
#define TANK_LED                0
#define ALARM_LED               1
#define BREW_BUTTON             2
#define BREW_LIGHTS             3
#define STATUS_LED              4
#define IO_1                    5
#define IO_2                    6
// GP7 not used

// These are the channel numbers for the ADC
#define DIAL_POTENTIOMETER      1
// Channel 2 is shorted to ground
#define PRESSURE_SENSOR         3
#define THERMISTOR              4

Adafruit_MCP23X08 mcp;
Adafruit_BME280 bme;
Adafruit_AD569x ad5693; // 12-bit DAC
MCP342x adc = MCP342x(0x68); // MCP3424 address is 0x6e

int i;
int timeout = 1000000; // 1 second timeout

float boiler_probe;
float reservoir_probe;
int pressurestat;
float potentiometer;
float pressure;
float thermistor;
float bme_temperature;
float bme_pressure;
float bme_humidity;

int DAC_value = 0;
bool button_flag = false;

#ifdef ESP32

void IRAM_ATTR isr() {
  button_flag = true;
}

const uint8_t HSVlights[61] = 
{0, 4, 8, 13, 17, 21, 25, 30, 34, 38, 42, 47, 51, 55, 59, 64, 68, 72, 76,
81, 85, 89, 93, 98, 102, 106, 110, 115, 119, 123, 127, 132, 136, 140, 144,
149, 153, 157, 161, 166, 170, 174, 178, 183, 187, 191, 195, 200, 204, 208,
212, 217, 221, 225, 229, 234, 238, 242, 246, 251, 255};

// the real HSV rainbow
void trueHSV(int angle)
{
  byte red, green, blue;

  if (angle<60) {red = 255; green = HSVlights[angle]; blue = 0;} else
  if (angle<120) {red = HSVlights[120-angle]; green = 255; blue = 0;} else 
  if (angle<180) {red = 0, green = 255; blue = HSVlights[angle-120];} else 
  if (angle<240) {red = 0, green = HSVlights[240-angle]; blue = 255;} else 
  if (angle<300) {red = HSVlights[angle-240], green = 0; blue = 255;} else 
                 {red = 255, green = 0; blue = HSVlights[360-angle];} 

  analogWrite(LED_R, red);
  analogWrite(LED_G, green);
  analogWrite(LED_B, blue);
}

#else

void isr() {
    button_flag = true;
}

void trueHSV(int angle) {
  return;
}

#endif // RGB LED only exists on the ESP32, interrupts are different

void setup() {  
  // Set up Arduino I/O
  pinMode(WATER_PUMP, OUTPUT);
  pinMode(ACCESSORY_1, OUTPUT);
  pinMode(ACCESSORY_2, OUTPUT);
  pinMode(WATER_VALVE, OUTPUT);
  pinMode(FILL_VALVE, OUTPUT);
  pinMode(STEAM_BOILER, OUTPUT);
  pinMode(COFFEE_BOILER, OUTPUT);

  pinMode(IO_INTERRUPT, INPUT_PULLUP);
  pinMode(PRESSURESTAT, INPUT_PULLUP);
  pinMode(BOILER_AUTOFILL_PROBE, INPUT);
  pinMode(RESERVOIR_LEVEL_PROBE, INPUT);
  pinMode(TACHOMETER, INPUT_PULLUP);

#ifdef ESP32
  pinMode(LED_R, OUTPUT);
  pinMode(LED_G, OUTPUT);
  pinMode(LED_B, OUTPUT);
#endif

  // These are all off by default 
  digitalWrite(WATER_PUMP, LOW);
  digitalWrite(ACCESSORY_1, LOW);
  digitalWrite(ACCESSORY_2, LOW);
  digitalWrite(WATER_VALVE, LOW);
  digitalWrite(FILL_VALVE, LOW);
  digitalWrite(STEAM_BOILER, LOW);
  digitalWrite(COFFEE_BOILER, LOW);

#ifdef ESP32
  // Start with RGB all on
  analogWrite(LED_R, 64);
  analogWrite(LED_G, 64);
  analogWrite(LED_B, 64);
#endif

  // Start the serial interface
  Serial.begin(115200);

  // Start up the MCP23008
  mcp.begin_I2C();

  // Set up interrupts
  mcp.setupInterrupts(true, false, LOW);

  // The brew button is the only input
  for(i = 0; i < 8; i++) {
    if(i == BREW_BUTTON) {
      mcp.pinMode(i, INPUT_PULLUP);
      mcp.setupInterruptPin(i, LOW);
    }
    else {
      mcp.pinMode(i, OUTPUT);

      // Turn on the brew lights
      if((i == BREW_LIGHTS) || (i == STATUS_LED) || (i == IO_1))
        mcp.digitalWrite(i, HIGH);
      else
        mcp.digitalWrite(i, LOW);
    }
  }

  // Start up the DAC, set voltage to zero
  ad5693.begin(0x4C, &Wire);
  delay(100);
  ad5693.reset();
  ad5693.setMode(NORMAL_MODE, true, true);
  ad5693.writeUpdateDAC(0);

  // BME280, SDO is wired to ground so I2C address is 0x76
  bme.begin(0x76, &Wire);

  // Initialize ADC
  MCP342x::generalCallReset();

  // Wait for everything to catch up
  delay(1000);

  // Make sure the ADC is really there
  Wire.requestFrom(0x68, (uint8_t)1);
  if(!Wire.available()) {
    delay(1000);
    Serial.println("ADC not found");
    while(1);
  }

	attachInterrupt(IO_INTERRUPT, isr, CHANGE);
}

void read_sequence() {
  long value; // ADC reading
  MCP342x::Config status; // ADC status

  for(int i = 0; i < 11; i++) {
    // Handle interrupt
    if(button_flag == true) {
      button_flag = false;
      if(mcp.digitalRead(BREW_BUTTON) == HIGH)
        mcp.digitalWrite(STATUS_LED, HIGH);
      else
        mcp.digitalWrite(STATUS_LED, LOW);
    }

    switch(i) {
      case 0: // Read boiler probe (output in volts)
        boiler_probe = ((float)analogRead(BOILER_AUTOFILL_PROBE) * 3.3) / 1024.0;
        break;
      case 1: // Read reservoir probe (output in volts)
        reservoir_probe = ((float)analogRead(RESERVOIR_LEVEL_PROBE) * 3.3) / 1024.0;
        break;
      case 2: // Read pressurestat
        pressurestat = digitalRead(PRESSURESTAT);
        break;
      case 3: // Read analog dial
        adc.convertAndRead(MCP342x::channel1, MCP342x::oneShot, MCP342x::resolution16, MCP342x::gain1, timeout, value, status);
        potentiometer = value;
        break;
      case 4: // Read pressure sensor
        adc.convertAndRead(MCP342x::channel3, MCP342x::oneShot, MCP342x::resolution16, MCP342x::gain1, timeout, value, status);
        pressure = value;
        break;
      case 5: // Read brew head thermistor
        adc.convertAndRead(MCP342x::channel4, MCP342x::oneShot, MCP342x::resolution16, MCP342x::gain1, timeout, value, status);
        thermistor = value;
        break;
      case 6: // Read BME280 sensor value
        bme_temperature = bme.readTemperature();
        break;
      case 7: // Read BME280 pressure
        bme_pressure = bme.readPressure() / 100.0F;
        break;
      case 8: // Read BME280 humidity
        bme_humidity = bme.readHumidity();
      case 9: // Update DAC
        ad5693.writeUpdateDAC(DAC_value);
        if(DAC_value > 65400) DAC_value = 0; else DAC_value += 1023;
        break;
      default:
        Serial.print("Boiler level: "); Serial.println(boiler_probe);
        Serial.print("Tank level: "); Serial.println(reservoir_probe);
        Serial.print("Pressurestat: "); Serial.println(pressurestat);
        Serial.print("Dial: "); Serial.println(potentiometer);
        Serial.print("Line pressure: "); Serial.println(pressure);
        Serial.print("Group temp: "); Serial.println(thermistor);
        Serial.print("Case temp: "); Serial.println(bme_temperature);
        Serial.print("Air pressure: "); Serial.println(bme_pressure);
        Serial.print("Humidity: "); Serial.println(bme_humidity);
        Serial.println();
        break;
    }
  }
}

void loop() {
  for(int n = 0; n < 360; n += 2) {
    read_sequence();
    trueHSV(n);
  }
}