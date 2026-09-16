from datetime import datetime, timedelta
import sys

from App import database, models


def seed_readings(mode: str):
    db = database.SessionLocal()

    try:
        print("Clearing existing readings...")
        db.query(models.MeterReading).delete()
        db.commit()

        start_time = datetime.now() - timedelta(days=14)

        if mode == "normal":
            values = [
                3335.629,  # start
                3335.681,  # +0.052
                3335.741,  # +0.060
                3335.796,  # +0.055
                3335.864,  # +0.068
                3335.921,  # +0.057
                3335.985,  # +0.064
                3336.041,  # +0.056
                3336.109,  # +0.068
                3336.167,  # +0.058
                3336.229,  # +0.062
                3336.284,  # +0.055
                3336.351,  # +0.067
                3336.409,  # +0.058
                3336.468,  # +0.059
            ]
            print("Seeding NORMAL dataset...")

        elif mode == "alert":
            values = [
                3335.629,  # start
                3335.681,  # +0.052
                3335.741,  # +0.060
                3335.796,  # +0.055
                3335.864,  # +0.068
                3335.921,  # +0.057
                3335.985,  # +0.064
                3336.041,  # +0.056
                3336.109,  # +0.068
                3336.167,  # +0.058
                3336.229,  # +0.062
                3336.284,  # +0.055
                3336.351,  # +0.067
                3336.409,  # +0.058
                3337.789,  # +1.380 anomaly spike
            ]
            print("Seeding ALERT dataset...")

        else:
            print("Usage:")
            print("python seed_demo_data.py normal")
            print("python seed_demo_data.py alert")
            return

        for i, value in enumerate(values):
            reading = models.MeterReading(
                reading_value=value,
                meter_id="demo_meter",
                status="SUCCESS",
                recorded_at=start_time + timedelta(days=i),
            )
            db.add(reading)

        db.commit()
        print(f"Inserted {len(values)} readings successfully.")

    finally:
        db.close()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("python seed_demo_data.py normal")
        print("python seed_demo_data.py alert")
    else:
        seed_readings(sys.argv[1].lower())