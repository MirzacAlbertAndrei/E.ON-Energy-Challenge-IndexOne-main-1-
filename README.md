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

## Repository Structure

```text
Smart-Gas-Meter/
├── backend/              # FastAPI backend, database, analytics and prediction
├── firmware/             # ESP32-CAM firmware and example network configuration
├── mobile/               # Flutter application
├── models/               # YOLO model weights
├── seed_demo_data.py     # Demo data generator for analytics testing
├── .gitignore
└── README.md
```

## How the Meter Reading Works

1. The ESP32-CAM captures the gas meter display.
2. The image is uploaded to the FastAPI backend.
3. A YOLO model locates the meter index region.
4. A second YOLO model detects the individual digits.
5. Overlapping detections are filtered and sorted from left to right.
6. The resulting reading is stored and exposed to the mobile app.

## Analytics

The backend derives consumption from consecutive meter readings.

For anomaly detection, recent consumption values from a 14-day window are used to calculate a threshold based on the historical mean and standard deviation.

A linear regression model is also used to estimate the next consumption value from previous consumption samples.

## API Overview

The FastAPI backend includes endpoints for:

- receiving images from the ESP32-CAM
- retrieving stored meter readings
- reading and updating the capture interval
- anomaly detection
- next-consumption prediction
