---
title: "Serving a Machine Learning Model with Flask: Building a JSON API"
slug: "serving-a-machine-learning-model-with-flask-building-a-json-api"
category: "Machine Learning"
date: "2026-04-27"
status: "published"
---

In [Part 1 of this series](https://qadrlabs.com/post/building-a-simple-machine-learning-model-with-scikit-learn), you built a Logistic Regression classifier that predicts whether a student passes or fails, evaluated its performance, and saved the trained model to `model.pkl` using `joblib`. The model works correctly. But right now, the only way to use it is to open a terminal, activate a virtual environment, and run a Python script. That is fine for development, but it is a dead end for everything else.

If a teammate wants to use your model, they need to set up the same Python environment. If a mobile app wants to show predictions, it needs direct access to your machine. If another service in your system wants a prediction, it has to speak Python. A Flask JSON API solves all of this at once. By wrapping your model in a web server with a single endpoint, you give anything that can make an HTTP request, which is virtually every programming language and platform in existence, the ability to get a prediction in milliseconds without knowing anything about scikit-learn, joblib, or pandas.

This article walks you through building that API. By the end, you will have a running Flask server with a health check route and a `/predict` endpoint that accepts student data as JSON and returns a prediction alongside a confidence score.

## Overview {#overview}

This is Part 2 of a two-part series on building and deploying a machine learning model with Python and Flask. Part 1 covered creating the dataset, training the model, and saving it to disk. This article picks up from that saved `model.pkl` file and builds the serving layer around it. If you have not read Part 1, the prerequisites section below describes exactly what you need to have in place before continuing.

### What You'll Build

- A Flask application with two routes: a health check at `GET /` and a prediction endpoint at `POST /predict`.
- Structured JSON responses that include the prediction label, confidence score, and the input values that produced the result.
- An input validation layer that returns descriptive error messages when required fields are missing or have an incorrect type.

### What You'll Learn

- How to load a `joblib` model at application startup rather than per request, and why that distinction matters for performance.
- How to receive and parse a JSON request body in Flask using `request.get_json()`.
- How to write a validation layer that catches problems before they reach the model.
- How to structure a Flask project inside an existing Python project using a subfolder, and what the production-grade alternative looks like.

### What You'll Need

- Completion of Part 1 of this series (specifically, a `model.pkl` file and the `student-pass-predictor/` project folder).
- Python 3.10 or higher with `pip`.
- `curl` installed in your terminal. It is available by default on macOS, Linux, and modern Windows (10 version 1803 and later).
- A basic understanding of HTTP methods (GET vs POST) and status codes (200 for success, 400 for a bad request).

## Step 1: Prepare the Project Structure {#step-1-prepare-project-structure}

Because the Flask application is a separate concern from training and evaluation scripts, it deserves its own subfolder. This keeps the API code isolated from the training pipeline, which makes it easier to reason about each part independently.

Navigate to the root of the project you built in Part 1, then create the subfolder and its files:

```bash
cd student-pass-predictor
mkdir flask-app
cd flask-app
touch app.py requirements.txt
```

Next, copy `model.pkl` from the project root into `flask-app/`. The Flask application needs a local copy of the model file so it can operate as a self-contained unit.

```bash
cp ../model.pkl model.pkl
```

> **Two paths forward:** If you completed Part 1, `model.pkl` already exists in the project root and the command above will work immediately. If you are starting fresh from this article, go to the project root and run `python train.py` first to generate the file.

Your project folder should now look like this:

```
student-pass-predictor/
├── venv/
├── generate_data.py
├── train.py
├── predict.py
├── student_data.csv
├── model.pkl
└── flask-app/
    ├── app.py
    ├── model.pkl
    └── requirements.txt
```

Open `flask-app/requirements.txt` and list the dependencies the application needs:

```
flask
scikit-learn
pandas
joblib
```

Now install Flask into the shared virtual environment. Go back to the project root, activate the venv, and run `pip install`:

```bash
cd ..
source venv/bin/activate   # on Windows: venv\Scripts\activate
pip install flask
```

> **A note on project structure and best practices.** In this tutorial, the Flask application lives in a subfolder and shares a virtual environment with the training scripts. This arrangement keeps the setup simple and all the context in one place, which is exactly what you want when learning. In a production setting, the approach is different in three important ways. First, the model training code and the serving API would live in separate repositories, each with its own deployment pipeline, so a change to the training logic does not risk breaking the live API. Second, each service would have its own virtual environment or Docker container with only the packages it actually needs. Third, the `model.pkl` file would not be copied manually; instead, it would be stored in a model registry or artifact store, and the Flask application would download it at startup using a file path or URL from an environment variable. For this tutorial, the subfolder approach gives you all the concepts without the operational overhead.

## Step 2: Build the Flask Application {#step-2-build-flask-app}

With the structure in place, you can now write the application. The design is intentionally minimal: two routes, one for health checking and one for predictions, with input validation before any data reaches the model.

Open `flask-app/app.py` and write the following:

```python
# app.py

import joblib
import pandas as pd
from flask import Flask, request, jsonify

# Load the model into memory once, at application startup.
# This is a deliberate performance decision: joblib.load() reads and deserializes
# the .pkl file from disk. If this call were placed inside the /predict route,
# Flask would repeat that expensive work on every incoming request. By loading
# here at module level, the model object lives in memory for the entire lifetime
# of the server process and is immediately available to every request.
model = joblib.load('model.pkl')

app = Flask(__name__)

# A constant listing the field names the model expects.
# Keeping this at module level means you only need to update it in one place
# if the model's features ever change in a future version.
REQUIRED_FIELDS = ['study_hours', 'attendance_pct', 'avg_score']


@app.route('/')
def health_check():
    # A lightweight endpoint that confirms the server is running and the model
    # loaded successfully. Monitoring tools and load balancers ping endpoints like
    # this to verify the service is alive before routing traffic to it.
    return jsonify({
        'status': 'ok',
        'model': 'student-pass-predictor',
        'version': '1.0.0'
    })


@app.route('/predict', methods=['POST'])
def predict():
    # request.get_json() parses the incoming request body as a JSON object and
    # returns a Python dictionary. It returns None if the body is empty or if
    # the request's Content-Type header is not 'application/json'.
    data = request.get_json()

    if not data:
        return jsonify({'error': 'Request body must be valid JSON'}), 400

    # Check that all required fields are present.
    # The list comprehension collects every field name that is absent from the
    # request body. If any are missing, we return 400 with the exact list of
    # missing fields so the caller knows precisely what to fix.
    missing = [field for field in REQUIRED_FIELDS if field not in data]
    if missing:
        return jsonify({
            'error': 'Missing required fields',
            'missing_fields': missing
        }), 400

    # Convert each value to float. This handles two common scenarios: a caller
    # who sends proper numbers (7.5) and a caller who accidentally sends them as
    # strings ("7.5"). If a value cannot be converted at all (e.g., "abc"),
    # we return a 400 error with a clear message.
    try:
        study_hours    = float(data['study_hours'])
        attendance_pct = float(data['attendance_pct'])
        avg_score      = float(data['avg_score'])
    except (ValueError, TypeError):
        return jsonify({'error': 'All fields must be numeric values'}), 400

    # Build the input as a DataFrame with named columns.
    # The column names here must match exactly what the model saw during training.
    # Passing a plain numpy array would cause scikit-learn to raise a UserWarning
    # because it cannot verify that the features are in the correct order.
    # Using a named DataFrame makes the intent explicit and eliminates the warning.
    input_df = pd.DataFrame([{
        'study_hours':    study_hours,
        'attendance_pct': attendance_pct,
        'avg_score':      avg_score,
    }])

    prediction  = model.predict(input_df)[0]
    probability = model.predict_proba(input_df)[0]

    # prediction is a numpy integer (0 or 1). We convert it to a readable label.
    # probability is a two-element array: [prob_of_fail, prob_of_pass].
    # max() selects the probability of whichever class was predicted.
    # float() converts the numpy float to a native Python float so jsonify can
    # serialize it. round() keeps the output to four decimal places.
    label      = 'pass' if prediction == 1 else 'fail'
    confidence = round(float(max(probability)), 4)

    return jsonify({
        'prediction': label,
        'confidence': confidence,
        'input': {
            'study_hours':    study_hours,
            'attendance_pct': attendance_pct,
            'avg_score':      avg_score,
        }
    })


if __name__ == '__main__':
    # debug=True enables the interactive reloader and browser-based debugger.
    # The reloader restarts the server automatically whenever you save a change
    # to app.py, which is helpful during development. The browser debugger lets
    # you inspect variables when an unhandled exception occurs.
    # Never use debug=True in production: it exposes an interactive Python shell
    # to anyone who can trigger an error in the running server.
    app.run(debug=True)
```

Save the file. The application is complete. Notice the deliberate ordering: the model loads at the very top, the Flask instance comes next, and then the routes. If `joblib.load()` fails because `model.pkl` is not in the right location, the error will surface immediately when you start the server rather than the first time a request comes in. Failing loudly at startup is far easier to diagnose than failing silently mid-request.

## Step 3: Try It Out {#step-3-try-it-out}

Make sure you are inside the `flask-app/` directory with the virtual environment still active, then start the server:

```bash
cd flask-app
python app.py
```

You should see Flask's development server start up and confirm the application is running:

```
 * Serving Flask app 'app'
 * Debug mode: on
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:5000
Press CTRL+C to quit
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 123-456-789
```

Keep this terminal open. Open a second terminal window for the following scenarios.

### Scenario A: Health Check

Start with the health check to confirm the server is up and the model loaded without errors:

```bash
curl http://127.0.0.1:5000/
```

Expected response:

```json
{
  "model": "student-pass-predictor",
  "status": "ok",
  "version": "1.0.0"
}
```

### Scenario B: Predict a Passing Student

Use the same input values from `predict.py` in Part 1 so you can verify the API returns an identical result:

```bash
curl -X POST http://127.0.0.1:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"study_hours": 7.5, "attendance_pct": 85.0, "avg_score": 78.0}'
```

Expected response:

```json
{
  "confidence": 0.765,
  "input": {
    "attendance_pct": 85.0,
    "avg_score": 78.0,
    "study_hours": 7.5
  },
  "prediction": "pass"
}
```

The confidence value of 0.765 matches the 76.5% you saw in Part 1. Because the same model file is loaded with the same input, the prediction is fully deterministic.

### Scenario C: Predict a Failing Student

```bash
curl -X POST http://127.0.0.1:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"study_hours": 2.0, "attendance_pct": 45.0, "avg_score": 35.0}'
```

Expected response:

```json
{
  "confidence": 0.993,
  "input": {
    "attendance_pct": 45.0,
    "avg_score": 35.0,
    "study_hours": 2.0
  },
  "prediction": "fail"
}
```

### Scenario D: Missing a Required Field

Send a request with `avg_score` omitted to test the validation layer:

```bash
curl -X POST http://127.0.0.1:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"study_hours": 7.5, "attendance_pct": 85.0}'
```

Expected response (HTTP 400):

```json
{
  "error": "Missing required fields",
  "missing_fields": [
    "avg_score"
  ]
}
```

The server returns HTTP 400 and names the exact field that is missing. Without this validation layer, the incomplete dictionary would reach `pd.DataFrame([...])`, build a DataFrame missing one column, and cause the model to raise an unhandled exception that Flask would convert into a generic HTTP 500 error. Catching the problem early and returning a 400 with a useful message is far better for whoever is calling your API.

## Understanding the Prediction Flow {#understanding-prediction-flow}

Now that the API is working, it is worth tracing exactly what happens between a request arriving and a response leaving, because understanding this sequence will help you extend and debug the application confidently.

When you run `python app.py`, Python executes the module from top to bottom before Flask starts listening for requests. It hits `joblib.load('model.pkl')` at the very top and deserializes the `LogisticRegression` object into a variable called `model`. This object, with all its trained weights, now lives in memory. Nothing in the routes will touch the file system again.

When a POST request arrives at `/predict`, Flask matches the URL and HTTP method to the `predict()` function and calls it. The first thing `predict()` does is call `request.get_json()`, which reads and parses the request body. The model is not involved at this point. The next two blocks are pure validation: a presence check and a type check. Only after both pass does the function construct `input_df` and call `model.predict()`.

`model.predict()` takes the DataFrame, applies the learned weights to each feature column, passes the weighted sum through the sigmoid function, and compares the result to a 0.5 threshold. If the output is above 0.5, the prediction is 1 (Pass); otherwise it is 0 (Fail). `model.predict_proba()` does the same calculation but returns the raw probabilities before the threshold step, giving you a two-element array where the values always sum to 1.0. Taking `max()` of that array gives you the probability of whichever class was predicted, which you then format as the confidence score.

The critical habit to take from this flow is that validation always comes before the model. A scikit-learn model does not validate its own input. If you pass it a DataFrame where `avg_score` is `None`, it will either raise a cryptic internal error or, in some cases, silently produce a prediction based on a numerical representation of `None`. Either outcome is bad. The validation layer you wrote is the only thing standing between a malformed request and a misleading or broken response.

## Conclusion {#conclusion}

You have taken a saved machine learning model and turned it into an HTTP API that any client can call. Here are the key takeaways from this article.

- **Load the model once, at startup.** Deserializing a model file on every request adds unnecessary disk I/O and latency. Loading at module level means the object stays in memory for the lifetime of the process.
- **Validate before you predict.** A scikit-learn model has no awareness of bad or incomplete input. A missing field or a non-numeric value should be caught and rejected with a 400 response, not allowed to reach the model.
- **Use a DataFrame with named columns for inference.** Passing a plain numpy array to a model trained on a named DataFrame triggers a scikit-learn warning and risks passing features in the wrong order if the column sequence ever changes. Explicit column names eliminate both problems.
- **Return the input alongside the prediction.** Including the values you received in the response makes it straightforward to verify that the caller sent what they intended, which is especially useful when debugging unexpected predictions.
- **HTTP 400 is more useful than HTTP 500.** A 400 response with a clear message tells the caller exactly what went wrong. A 500 response tells them something broke internally without giving them anything actionable to fix.
- **`debug=True` is for development only.** It exposes an interactive Python shell if an unhandled error occurs. Disable it before deploying anywhere beyond your local machine.
- **The subfolder structure works for learning; separate repositories are better for production.** Collocating the training code and the API in one project simplifies the tutorial workflow. In production, these concerns belong in separate codebases with independent deployment pipelines and their own dependency management.