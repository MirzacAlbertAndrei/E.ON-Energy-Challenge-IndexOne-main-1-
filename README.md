# Smart Gas Meter

An end-to-end IoT and computer vision prototype that adds remote monitoring and analytics to a conventional gas meter.

The system uses an ESP32-CAM to capture the meter display, sends the image to a Python backend, extracts the reading with a two-stage YOLO pipeline, stores measurements, analyzes consumption patterns, and exposes the data to a Flutter application.

## Features

- Automatic meter image capture with ESP32-CAM
- Configurable capture interval using an external RTC
- Two-stage YOLO computer vision pipeline
  - detects and crops the meter index area
  - detects and orders individual digits
- FastAPI backend for image ingestion and data access
- SQLite persistence through SQLAlchemy
- Consumption anomaly detection using recent historical readings
- Next-consumption prediction with linear regression
- Flutter mobile dashboard and reading history
- Backend-controlled request interval for the ESP32 device

## System Architecture

```text
ESP32-CAM
   |
   | JPEG image
   v
FastAPI Backend
   |
   +--> YOLO meter-region detection
   |        |
   |        v
   |    YOLO digit detection
   |
   +--> SQLite / SQLAlchemy
   |
   +--> Anomaly detection
   |
   +--> Consumption prediction
   |
   v
Flutter Mobile App
```

## Tech Stack

**Embedded / IoT**
- ESP32-CAM
- Arduino / C++
- Wi-Fi and HTTP
- PCF8563 RTC

**Backend**
- Python
- FastAPI
- SQLAlchemy
- SQLite
- Uvicorn

**Computer Vision & Analytics**
- YOLO / Ultralytics
- OpenCV
- NumPy
- scikit-learn

**Mobile**
- Flutter
- Dart
- Provider
- fl_chart

## How the Meter Reading Works

The computer vision pipeline uses two detection stages:

1. A YOLO model identifies the meter index region in the captured image.
2. The detected region is cropped and enlarged.
3. A second YOLO model detects the individual digits.
4. Overlapping detections are filtered and the remaining digits are ordered from left to right.
5. The final reading is stored by the backend and made available to the mobile app.

## Analytics

The backend derives consumption from consecutive meter readings.

For anomaly detection, recent consumption values from a 14-day window are used to calculate a statistical threshold based on the historical mean and standard deviation.

A linear regression model is also used to estimate the next consumption value from previous consumption samples.

## Repository Structure

```text
E.ON-Energy-Challenge-IndexOne-main/
├── ESP32_CAM/
│   ├── ESP32_CAM.ino
│   └── secrets.h.example
└── E.ON/
    ├── App/                    # FastAPI backend and analytics
    ├── ReadingBackend/         # Earlier backend prototype
    ├── smart_gas_meter_app/    # Flutter application
    ├── best.pt                 # Meter-region YOLO model
    └── yolo_digits.pt          # Digit-detection YOLO model
```
