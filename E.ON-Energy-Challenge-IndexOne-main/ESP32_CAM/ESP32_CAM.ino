#include "esp_camera.h"
#include <Wire.h>
#include <Rtc_Pcf8563.h>
#include <WiFi.h>
#include <HTTPClient.h>

// -------------------- WIFI / SERVER --------------------
const char* ssid = "DIGI-YyN6";
const char* password = "R7tkT2PCUg";
const char* serverName = "http://192.168.1.141:8000/receive-image";

// -------------------- PINS --------------------
const int PIN_LATCH = 14;
const int I2C_SDA = 2;
const int I2C_SCL = 15;
const int PIN_FLASH = 4;

// -------------------- FLASH --------------------
const int flashFreq = 5000;
const int flashRes = 8;
const int flashBrightness = 85;

// -------------------- CAMERA AI-THINKER --------------------
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// -------------------- GLOBALS --------------------
int nextSleepSeconds = 60;

// -------------------- FUNCTION DECLARATIONS --------------------
int extractIntervalFromResponse(const String& response);
void programRTC(int seconds);

// -------------------- HELPERS --------------------
int extractIntervalFromResponse(const String& response) {
  String key = "\"request_interval_seconds\":";
  int keyPos = response.indexOf(key);

  if (keyPos == -1) {
    return -1;
  }

  int start = keyPos + key.length();

  while (start < response.length() &&
         (response[start] == ' ' || response[start] == '\t')) {
    start++;
  }

  int end = start;
  while (end < response.length() && isDigit(response[end])) {
    end++;
  }

  if (end == start) {
    return -1;
  }

  String valueStr = response.substring(start, end);
  return valueStr.toInt();
}

// -------------------- SETUP --------------------
void setup() {
  pinMode(PIN_LATCH, OUTPUT);
  digitalWrite(PIN_LATCH, HIGH);

  Serial.begin(115200);
  delay(500);
  Serial.println("\n[SYSTEM] >> Start...");

  ledcAttach(PIN_FLASH, flashFreq, flashRes);

  // WIFI
  Serial.print("[WIFI]   >> Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  int wifiAttempts = 0;
  while (WiFi.status() != WL_CONNECTED && wifiAttempts < 20) {
    delay(500);
    Serial.print(".");
    wifiAttempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WIFI]   >> Connected! IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\n[WIFI]   >> Connection failed!");
  }

  // I2C / RTC
  Wire.begin(I2C_SDA, I2C_SCL);

  Wire.beginTransmission(0x51);
  if (Wire.endTransmission() == 0) {
    Serial.println("[RTC]    >> OK.");
  } else {
    Serial.println("[RTC]    >> Not responding.");
  }

  // CAMERA CONFIG
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sscb_sda = SIOD_GPIO_NUM;
  config.pin_sscb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_VGA;
  config.jpeg_quality = 12;
  config.fb_count = 1;

  if (esp_camera_init(&config) == ESP_OK) {
    Serial.println("[CAMERA] >> OK.");

    ledcWrite(PIN_FLASH, flashBrightness);
    delay(500);

    camera_fb_t* fb = esp_camera_fb_get();

    ledcWrite(PIN_FLASH, 0);

    if (fb) {
      Serial.printf("[PHOTO]  >> Capture OK (%zu bytes)\n", fb->len);

      if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        http.begin(serverName);
        http.setTimeout(10000);

        String boundary = "----ESP32Boundary123456";
        String head =
          "--" + boundary + "\r\n"
          "Content-Disposition: form-data; name=\"file\"; filename=\"capture.jpg\"\r\n"
          "Content-Type: image/jpeg\r\n\r\n";
        String tail = "\r\n--" + boundary + "--\r\n";

        size_t totalLen = head.length() + fb->len + tail.length();
        uint8_t* post_data = (uint8_t*) ps_malloc(totalLen);

        if (post_data) {
          memcpy(post_data, head.c_str(), head.length());
          memcpy(post_data + head.length(), fb->buf, fb->len);
          memcpy(post_data + head.length() + fb->len, tail.c_str(), tail.length());

          http.addHeader("Content-Type", "multipart/form-data; boundary=" + boundary);

          Serial.println("[SERVER] >> Sending HTTP request...");
          int httpResponseCode = http.POST(post_data, totalLen);

          if (httpResponseCode > 0) {
            Serial.printf("[SERVER] >> Response code: %d\n", httpResponseCode);

            String response = http.getString();
            Serial.println("[SERVER] >> Body:");
            Serial.println(response);

            int parsedInterval = extractIntervalFromResponse(response);

            if (parsedInterval >= 10 && parsedInterval <= 255) {
              nextSleepSeconds = parsedInterval;
              Serial.printf("[RTC]    >> Interval received from server: %d sec\n", nextSleepSeconds);
            } else {
              Serial.printf("[RTC]    >> Invalid interval in response. Using fallback: %d sec\n", nextSleepSeconds);
            }
          } else {
            Serial.printf("[SERVER] >> HTTP error: %d\n", httpResponseCode);
            Serial.printf("[RTC]    >> Using fallback: %d sec\n", nextSleepSeconds);
          }

          free(post_data);
        } else {
          Serial.println("[SERVER] >> ERROR: Not enough PSRAM for POST data.");
        }

        http.end();
      } else {
        Serial.println("[WIFI]   >> Not connected, skipping upload.");
      }

      esp_camera_fb_return(fb);
    } else {
      Serial.println("[CAMERA] >> Frame buffer capture failed.");
    }
  } else {
    Serial.println("[CAMERA] >> Camera initialization failed.");
  }

  programRTC(nextSleepSeconds);
}

void loop() {
}

void programRTC(int seconds) {
  if (seconds < 1) {
    seconds = 60;
  }

  if (seconds > 255) {
    seconds = 255;
  }

  Wire.beginTransmission(0x51);
  Wire.write(0x01);
  Wire.write(0x00);
  Wire.endTransmission();

  Wire.beginTransmission(0x51);
  Wire.write(0x0E);
  Wire.write(0x82);
  Wire.endTransmission();

  Wire.beginTransmission(0x51);
  Wire.write(0x0F);
  Wire.write(seconds);
  Wire.endTransmission();

  Wire.beginTransmission(0x51);
  Wire.write(0x01);
  Wire.write(0x11);
  Wire.endTransmission();

  Serial.printf("[RTC]    >> Sleep for %d seconds. Bye!\n", seconds);
  delay(200);
  digitalWrite(PIN_LATCH, LOW);
}