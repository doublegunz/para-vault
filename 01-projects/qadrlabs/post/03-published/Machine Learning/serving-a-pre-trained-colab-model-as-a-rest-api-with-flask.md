---
title: "Serving a Pre-Trained Colab Model as a REST API with Flask"
slug: "serving-a-pre-trained-colab-model-as-a-rest-api-with-flask"
category: "Machine Learning"
date: "2026-04-27"
status: "published"
---

You have successfully trained a machine learning model, but it is currently isolated inside a Jupyter Notebook or a local script. A predictive model provides no real business value if web applications, mobile apps, or other services cannot access its predictions. Rewriting the model logic in another language is impractical and error-prone. The standard approach is to wrap the trained model in a lightweight web server. This tutorial will show you how to use Flask to build a REST API that loads your saved model and serves predictions via JSON.

This article is Part 2 of our machine learning series. If you have not built the model yet, please complete [Building a Simple Machine Learning Model with Scikit-Learn in Google Colab](https://qadrlabs.com/post/building-a-simple-machine-learning-model-with-scikit-learn-in-google-colab) first.

## Overview {#overview}

This tutorial transitions your project from data science to software engineering. You will take the serialized model file from the previous tutorial and embed it into a Python web application.

### What You'll Build
- A Python virtual environment configured for web development.
- A Flask web application that loads a pre-trained scikit-learn model.
- A POST endpoint (`/predict`) that accepts student data in JSON format and returns a pass or fail prediction.

### What You'll Learn
- How to initialize a Flask application.
- How to safely load a serialized machine learning model into memory when the server starts.
- How to parse incoming JSON requests and convert them into pandas DataFrames.
- How to format model predictions into clean JSON responses.

### What You'll Need
- Python 3.9 or newer installed on your machine.
- Familiarity with basic terminal commands.
- The `model.pkl` file generated in the previous tutorial.

![model from previous tutorial](https://cdn.jsdelivr.net/gh/gungunpriatna/tes-repositori@master/machine-learning/machine-learning-goolge-colab/01-model-from-previous-tutorial.webp)

![download model](https://github.com/gungunpriatna/tes-repositori/blob/master/machine-learning/machine-learning-goolge-colab/02-download-model.webp)

## Step 1: Set Up the Flask Environment {#step-1-setup-flask}

A dedicated virtual environment keeps your project dependencies isolated from the rest of your system. This ensures that the specific versions of Flask and scikit-learn you use here will not conflict with other projects.

Open your terminal and run the following commands to create a new project directory, initialize the environment, and install the required packages.

```bash
mkdir flask-ml-api
cd flask-ml-api
python3 -m venv venv
source venv/bin/activate
pip install Flask pandas scikit-learn joblib
```

Make sure you copy the `model.pkl` file you downloaded in the previous tutorial into this `flask-ml-api` directory.



## Step 2: Build the API Application {#step-2-build-api}

Now you will write the actual web server code. Flask is a micro-framework that makes it incredibly simple to define web routes and handle HTTP requests.

Create a new file named `app.py` in your `flask-ml-api` directory and write the following code.

```python
from flask import Flask, request, jsonify
import joblib
import pandas as pd

# Initialize the Flask application
app = Flask(__name__)

# Load the trained model globally when the application starts.
# We do this outside the route function so the model is only loaded once,
# which saves memory and makes incoming requests process much faster.
model = joblib.load('model.pkl')

# Define a route that listens for POST requests at the /predict URL
@app.route('/predict', methods=['POST'])
def predict():
    # Check if the request contains JSON data
    if not request.is_json:
        return jsonify({'error': 'Request must be JSON'}), 400
        
    data = request.get_json()
    
    # Validate that all required features are present in the JSON payload
    required_keys = ['study_hours', 'attendance_pct', 'avg_score']
    for key in required_keys:
        if key not in data:
            return jsonify({'error': f'Missing required key: {key}'}), 400

    try:
        # Wrap the incoming dictionary in a list to create a single-row DataFrame.
        # This matches the format the scikit-learn model expects.
        input_df = pd.DataFrame([data])
        
        # Make the prediction
        prediction = model.predict(input_df)[0]
        probabilities = model.predict_proba(input_df)[0]
        
        # Format the prediction outcome
        label = "Pass" if prediction == 1 else "Fail"
        confidence = float(max(probabilities))
        
        # Return the result as a JSON response
        return jsonify({
            'prediction': label,
            'confidence': confidence,
            'input': data
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Run the development server on port 5000
    app.run(host='0.0.0.0', port=5000, debug=True)
```

Save the file. Your application is now ready to handle incoming prediction requests.

## Step 3: Try It Out {#step-3-try-it-out}

It is time to test your API. You will start the server in one terminal window and send data to it from another.

In your current terminal, run the Flask application.

```bash
python app.py
```

You should see an output similar to this.

```text
 * Serving Flask app 'app'
 * Debug mode: on
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on [http://127.0.0.1:5000](http://127.0.0.1:5000)
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 123-456-789
```

Leave that terminal running. Open a new terminal window, and use `curl` to send a POST request with a strong student profile.

```bash
curl -X POST http://127.0.0.1:5000/predict \
     -H "Content-Type: application/json" \
     -d '{"study_hours": 7.5, "attendance_pct": 85.0, "avg_score": 78.0}'
```

The API will respond with the prediction.

```json
{
  "confidence": 0.765432109,
  "input": {
    "attendance_pct": 85.0,
    "avg_score": 78.0,
    "study_hours": 7.5
  },
  "prediction": "Pass"
}
```

Now test what happens with a failing student profile. Run this command.

```bash
curl -X POST http://127.0.0.1:5000/predict \
     -H "Content-Type: application/json" \
     -d '{"study_hours": 2.0, "attendance_pct": 45.0, "avg_score": 35.0}'
```

The result will accurately reflect the failing data.

```json
{
  "confidence": 0.993456789,
  "input": {
    "attendance_pct": 45.0,
    "avg_score": 35.0,
    "study_hours": 2.0
  },
  "prediction": "Fail"
}
```

You can stop the Flask server in your first terminal by pressing `Ctrl + C`.

## Understanding Model API Integration {#understanding-model-api-integration}

When wrapping a machine learning model in a web framework, there are a few structural decisions that impact performance and reliability.

The most critical detail in `app.py` is loading the model outside of the `predict()` route. Machine learning models can be massive files. If you place `joblib.load()` inside the route function, the server will read the file from the disk into memory every single time a user makes a request. This will cause severe latency and eventually crash the server under high traffic. Loading it globally ensures it happens only once during startup.

Data validation is another vital component. The model was trained on a DataFrame with specific column names. If a user sends a JSON payload missing one of those keys, pandas will create a DataFrame with missing columns, and scikit-learn will throw a fatal error. The explicit dictionary key checks in the route prevent bad data from ever reaching the model.

Finally, notice the casting of the probability score using `float()`. NumPy arrays produce specific data types like `numpy.float64` that Python's standard `json` library does not know how to serialize. Converting it to a standard Python float ensures the `jsonify` function can safely build the response.

## Conclusion {#conclusion}

You have successfully bridged the gap between a standalone machine learning model and a web service. Here are the most important takeaways from building this API.

- **Model isolation.** Flask provides a clean boundary between data science and software engineering, allowing other applications to use the model without knowing Python.
- **Global loading.** Loading the model into memory once when the server starts saves resources and drastically reduces response times.
- **Data formatting.** Wrapping the incoming JSON payload into a pandas DataFrame ensures scikit-learn receives the exact data structure it expects.
- **JSON communication.** Standardizing inputs and outputs as JSON makes your model completely framework agnostic and accessible to any client.