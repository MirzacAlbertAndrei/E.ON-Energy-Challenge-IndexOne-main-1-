from sklearn.linear_model import LinearRegression
import numpy as np

def predict_next_consumption(readings):
    if len(readings) < 4:
        return None

    sorted_readings = sorted(readings, key=lambda x: x.recorded_at)

    consumptions = []
    for i in range(1, len(sorted_readings)):
        prev = float(sorted_readings[i - 1].reading_value)
        curr = float(sorted_readings[i].reading_value)
        diff = curr - prev

        if 0 <= diff < 1000:
            consumptions.append(diff)

    if len(consumptions) < 3:
        return None

    X = np.array(range(len(consumptions))).reshape(-1, 1)
    y = np.array(consumptions)

    model = LinearRegression()
    model.fit(X, y)

    next_index = np.array([[len(consumptions)]])
    prediction = model.predict(next_index)[0]

    if prediction < 0:
        prediction = 0

    return round(float(prediction), 3)