import statistics
from datetime import datetime, timedelta

def detect_anomaly(readings: list):
    if len(readings) < 2:
        return False, "Not enough data to calculate consumption."

    sorted_readings = sorted(readings, key=lambda x: x.recorded_at) 
   
    consumptions_with_date = []
    
    for i in range(1, len(sorted_readings)):
        prev = sorted_readings[i-1]
        curr = sorted_readings[i]
        
        try:
            val_prev = float(prev.reading_value)
            val_curr = float(curr.reading_value)
            
            diff = val_curr - val_prev
          
            if diff >= 0 and diff < 1000:
                consumptions_with_date.append({
                    'value': diff,
                    'date': curr.recorded_at
                })
        except:
            continue

    if not consumptions_with_date:
        return False, "Consumption could not be computed (invalid data)."

    current_data = consumptions_with_date[-1]
    current_consumption = current_data['value']
    current_date = current_data['date']
    
    raw_history = consumptions_with_date[:-1]

    cutoff_date = current_date - timedelta(days=14)
    
    window_history = [
        item['value'] 
        for item in raw_history 
        if item['date'] >= cutoff_date
    ]

    if len(window_history) < 3:
         return False, f"Calibrating... (Need more data in the last 14 days. Found: {len(window_history)})"

    try:
        mean = statistics.mean(window_history)          
        stdev = statistics.stdev(window_history) 
    except:
        mean = statistics.mean(window_history)
        stdev = 0.5 

    if stdev == 0:
        stdev = 0.1

    threshold = mean + (3 * stdev)

    if threshold < 1.0: 
        threshold = 1.0

    print(f"[ANALYTICS] Window (14 days): {len(window_history)} samples | Mean: {mean:.2f} | Current: {current_consumption:.2f} | Limit: {threshold:.2f}")

    if current_consumption > threshold:
        return True, f"ALERT! Abnormal consumption: {current_consumption:.2f} m³)"
    
    return False, f"Normal consumption.)"