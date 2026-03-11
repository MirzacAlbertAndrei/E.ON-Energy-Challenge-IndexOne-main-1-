import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import cv2
import numpy as np
import os
import json
from datetime import datetime
from . import prediction

from . import models, database, analytics

try:
    from .meter_reader import GasMeterReader
except ImportError:
    from meter_reader import GasMeterReader

app = FastAPI()

print("Initializing AI...")
try:
    ai_reader = GasMeterReader()
    print("AI Loaded.")
except Exception as e:
    ai_reader = None
    print(f"AI Failed to load: {e}")

models.Base.metadata.create_all(bind=database.engine)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")
CONFIG_FILE = os.path.join(BASE_DIR, "request_config.json")

os.makedirs(UPLOAD_DIR, exist_ok=True)

DEFAULT_INTERVAL_SECONDS = 60
MIN_INTERVAL_SECONDS = 10
MAX_INTERVAL_SECONDS = 255


def save_request_interval(seconds: int):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        json.dump({"request_interval_seconds": seconds}, f, indent=2)


def load_request_interval():
    if not os.path.exists(CONFIG_FILE):
        save_request_interval(DEFAULT_INTERVAL_SECONDS)
        return DEFAULT_INTERVAL_SECONDS

    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            value = int(data.get("request_interval_seconds", DEFAULT_INTERVAL_SECONDS))

            if value < MIN_INTERVAL_SECONDS:
                return DEFAULT_INTERVAL_SECONDS
            if value > MAX_INTERVAL_SECONDS:
                return MAX_INTERVAL_SECONDS

            return value
    except Exception:
        return DEFAULT_INTERVAL_SECONDS


@app.get("/request-interval")
async def get_request_interval():
    return {
        "status": "success",
        "request_interval_seconds": load_request_interval()
    }


@app.post("/request-interval")
async def set_request_interval(
    seconds: int = Query(..., ge=MIN_INTERVAL_SECONDS, le=MAX_INTERVAL_SECONDS)
):
    save_request_interval(seconds)
    return {
        "status": "success",
        "message": "Request interval updated successfully.",
        "request_interval_seconds": seconds
    }


@app.post("/receive-image")
async def receive_image_from_esp32(
    file: UploadFile = File(...),
    db: Session = Depends(database.get_db)
):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Connection received...")

    try:
        contents = await file.read()
        nparr = np.frombuffer(contents, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img is None:
            raise HTTPException(status_code=400, detail="Invalid image")

        filename = f"capture_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
        save_path = os.path.join(UPLOAD_DIR, filename)
        cv2.imwrite(save_path, img)

        final_reading = 0.0
        status = "FAILED"

        if ai_reader:
            detected_value_str = ai_reader.process_image(img)

            if detected_value_str:
                try:
                    final_reading = float(detected_value_str)
                    status = "SUCCESS"
                    print(f"AI Detected: {final_reading}")
                except ValueError:
                    status = "INVALID_FORMAT"
            else:
                status = "NO_DIGITS"
                print("AI hasn't found digits.")
        else:
            status = "AI_ERROR"

        new_reading = models.MeterReading(
            reading_value=final_reading,
            meter_id="esp32_cam_01",
            status=status
        )
        db.add(new_reading)
        db.commit()
        db.refresh(new_reading)

        all_readings = db.query(models.MeterReading).all()
        is_anomaly, message = analytics.detect_anomaly(all_readings)

        return {
            "status": "success",
            "value": final_reading,
            "is_anomaly": is_anomaly,
            "alert_message": message,
            "command": "SLEEP_NOW",
            "request_interval_seconds": load_request_interval()
        }

    except Exception as e:
        print(f"Server Error: {e}")
        return {
            "status": "error",
            "detail": str(e),
            "request_interval_seconds": load_request_interval()
        }


@app.get("/readings")
async def get_readings(limit: int = 20, db: Session = Depends(database.get_db)):
    readings = (
        db.query(models.MeterReading)
        .order_by(models.MeterReading.recorded_at.desc())
        .limit(limit)
        .all()
    )

    data = []
    for r in readings:
        data.append({
            "id": r.id,
            "value": float(r.reading_value),
            "date": r.recorded_at.strftime("%Y-%m-%d %H:%M"),
            "status": r.status
        })

    return {
        "status": "success",
        "data": data
    }

@app.get("/analytics")
async def get_analytics(db: Session = Depends(database.get_db)):
    all_readings = db.query(models.MeterReading).all()
    is_anomaly, message = analytics.detect_anomaly(all_readings)

    return {
        "status": "success",
        "data": {
            "is_anomaly": is_anomaly,
            "message": message
        }
    }

@app.get("/prediction")
async def get_prediction(db: Session = Depends(database.get_db)):
    all_readings = db.query(models.MeterReading).all()
    predicted = prediction.predict_next_consumption(all_readings)

    return {
        "status": "success",
        "data": {
            "predicted_next_consumption": predicted
        }
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

    