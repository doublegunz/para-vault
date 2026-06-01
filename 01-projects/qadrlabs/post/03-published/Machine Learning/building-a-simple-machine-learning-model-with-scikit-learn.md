---
title: "Building a Simple Machine Learning Model with Scikit-Learn"
slug: "building-a-simple-machine-learning-model-with-scikit-learn"
category: "Machine Learning"
date: "2026-04-27"
status: "published"
---

You have been reading about machine learning for a while. You understand the concepts, you know Python, and you have seen plenty of code snippets online. But when the time actually comes to sit down and build something from scratch, the question hits: where do I even start? Most tutorials assume you already have a perfectly formatted dataset sitting on your disk, and many of them skip explaining why each step exists. If that gap between theory and a first working model feels frustrating, you are in the right place.

This article takes a direct, practical approach. You will create a synthetic dataset from scratch, train a Logistic Regression classifier that predicts whether a student passes or fails, evaluate its performance properly, and save the trained model to a file so it can be reused. In Part 2 of this series, you will load that saved model inside a Flask application and expose it as a JSON API.

## Overview {#overview}

This article is the first part of a two-part series on building and deploying machine learning models with Flask. Before you can serve a model, you need a model worth serving. That is exactly what this article covers: building, evaluating, and persisting a trained scikit-learn model in a clean, reusable way.

### What You'll Build

- A Python script that generates a synthetic student dataset and saves it as a CSV file.
- A trained Logistic Regression classifier that predicts whether a student passes based on their study hours, attendance percentage, and average exam score.
- A saved model file (`model.pkl`) that can be loaded and reused by any Python application, including the Flask API you will build in Part 2.

### What You'll Learn

- How to create a realistic synthetic dataset using NumPy and Pandas.
- How to split data into training and testing sets using scikit-learn.
- How to train a Logistic Regression classifier.
- How to evaluate a model using accuracy score and a full classification report.
- How to save and reload a trained model with `joblib`.

### What You'll Need

- Python 3.10 or higher
- Basic familiarity with Python functions and data structures
- `pip` installed and working in your terminal
- No prior machine learning experience is required; core concepts will be explained as you go

## Step 1: Set Up the Project {#step-1-set-up-project}

A clean project structure is one of those small habits that pays off later. When you add a Flask application on top of this model in Part 2, you will be glad the files are already organized in a predictable layout.

Start by creating a new directory and setting up a virtual environment:

```bash
mkdir student-pass-predictor
cd student-pass-predictor
python -m venv venv
```

Activate the virtual environment. On macOS and Linux:

```bash
source venv/bin/activate
```

On Windows:

```bash
venv\Scripts\activate
```

Now install the libraries you will need throughout this tutorial:

```bash
pip install scikit-learn pandas numpy joblib
```

Here is what each library does in this project. **scikit-learn** is the machine learning library you will use to train and evaluate the model. **pandas** lets you create and manipulate the dataset as a structured DataFrame. **numpy** handles numerical operations, especially generating random data. **joblib** serializes the trained model to disk and deserializes it back, which is the mechanism that lets Part 2 load your model without retraining it.

Once the installation finishes, create the three Python scripts you will work on:

```bash
touch generate_data.py train.py predict.py
```

Your project folder should now look like this:

```
student-pass-predictor/
├── venv/
├── generate_data.py
├── train.py
└── predict.py
```

## Step 2: Create the Dataset {#step-2-create-dataset}

Real-world datasets often come with missing values, inconsistent column names, and surprises you did not plan for. For a first project, that complexity is a distraction from learning the ML workflow itself. Using a synthetic dataset lets you focus entirely on the machine learning steps without spending hours on data cleaning.

The scenario is straightforward: you have a group of 300 students, and for each student you know three things: how many hours per day they study, what percentage of classes they attended, and what their average exam score is. The goal is to predict whether each student passes or fails.

Open `generate_data.py` and write the following:

```python
# generate_data.py

import numpy as np
import pandas as pd

# Fix the random seed so this script produces the same dataset every time it runs.
# Reproducibility is important: two people running this script should get
# the exact same CSV file and, eventually, the same trained model.
np.random.seed(42)

N = 300  # total number of student records to generate

# Generate three input features for each student.
# np.random.uniform(low, high, size) draws N samples from a uniform distribution
# between the given bounds, meaning every value in that range is equally likely.
study_hours    = np.random.uniform(1, 10, N).round(1)   # hours studied per day
attendance_pct = np.random.uniform(40, 100, N).round(1) # class attendance percentage
avg_score      = np.random.uniform(30, 100, N).round(1) # average exam score

# Define the pass rule: a student passes if their average score is at least 60
# AND their attendance is at least 60 percent.
# The result is a boolean array; .astype(int) converts True to 1 and False to 0.
pass_label = ((avg_score >= 60) & (attendance_pct >= 60)).astype(int)

# Add a small amount of noise to make the dataset more realistic.
# We randomly flip 10 percent of the labels. This simulates real-world edge cases:
# a student who barely passed despite poor attendance, or failed despite good numbers.
# Without noise, the model would learn a nearly perfect rule and be overconfident.
rng = np.random.default_rng(42)
noise_indices = rng.choice(N, size=int(0.1 * N), replace=False)
pass_label[noise_indices] = 1 - pass_label[noise_indices]

# Assemble all columns into a DataFrame and save it to a CSV file.
df = pd.DataFrame({
    'study_hours':    study_hours,
    'attendance_pct': attendance_pct,
    'avg_score':      avg_score,
    'pass':           pass_label
})

df.to_csv('student_data.csv', index=False)

print(f"Dataset created: {len(df)} records")
print(f"\nClass distribution:")
print(df['pass'].value_counts().to_string())
print(f"\nFirst 5 rows:")
print(df.head().to_string())
```

Save the file and run it:

```bash
python generate_data.py
```

You should see output similar to this:

```
Dataset created: 300 records

Class distribution:
pass
0    193
1    107
Name: count, dtype: int64

First 5 rows:
   study_hours  attendance_pct  avg_score  pass
0          4.4            43.1       41.8     0
1          9.6            71.9       49.5     0
2          7.6            72.4       42.4     0
3          6.4            78.2       36.2     0
4          2.4            83.6       38.4     0
```

The class distribution shows 193 failing students and 107 passing ones. This is a moderately imbalanced dataset: roughly a 64/36 split. It is realistic, since in practice more students tend to fail than pass in a strict grading scenario. This imbalance is also why the classification report later will show different precision and recall values between the two classes; the model has more "Fail" examples to learn from, which affects how it handles the minority "Pass" class. You now have `student_data.csv` in your project folder.

## Step 3: Train the Model {#step-3-train-model}

With the dataset ready, you can write the training script. This is where the machine learning actually happens: loading the data, splitting it into training and testing portions, fitting the model, and measuring how well it performs on data it has never seen before.

Open `train.py` and write the following:

```python
# train.py

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score
import joblib

# --- Load the dataset ---
df = pd.read_csv('student_data.csv')

# Separate features (X) from the label (y).
# X is a DataFrame with the three columns the model will learn from.
# y is a Series containing the value the model is trying to predict (0 or 1).
X = df[['study_hours', 'attendance_pct', 'avg_score']]
y = df['pass']

# --- Split data into training and testing sets ---
# We use 80% of the data for training and hold out 20% for testing.
# The test set simulates "unseen data" so you get an honest performance estimate.
# stratify=y ensures both splits contain the same ratio of passes to fails
# as the full dataset, preventing accidental imbalance in either split.
# random_state=42 makes the split reproducible across runs.
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    stratify=y,
    random_state=42
)

print(f"Training samples : {len(X_train)}")
print(f"Testing samples  : {len(X_test)}")

# --- Train the model ---
# LogisticRegression finds the best set of weights to predict the probability
# that a student passes, given their three feature values.
# max_iter=200 gives the solver enough iterations to converge on those weights.
# random_state=42 keeps results reproducible for solvers that have randomness.
model = LogisticRegression(max_iter=200, random_state=42)
model.fit(X_train, y_train)

print("\nModel training complete.")

# --- Evaluate the model ---
# We predict on X_test (the held-out data the model never saw during training),
# then compare those predictions to the actual labels in y_test.
y_pred = model.predict(X_test)

accuracy = accuracy_score(y_test, y_pred)
print(f"\nAccuracy: {accuracy:.2%}")

print("\nClassification Report:")
print(classification_report(y_test, y_pred, target_names=['Fail', 'Pass']))

# --- Save the trained model to disk ---
# joblib.dump() serializes the model object into a binary file.
# This lets you reload the exact same trained model later without retraining,
# which is essential for Part 2 where Flask needs to load it at startup.
joblib.dump(model, 'model.pkl')
print("Model saved to model.pkl")
```

Save the file and run it:

```bash
python train.py
```

Expected output:

```
Training samples : 240
Testing samples  : 60

Model training complete.

Accuracy: 76.67%

Classification Report:
              precision    recall  f1-score   support

        Fail       0.80      0.85      0.82        39
        Pass       0.68      0.62      0.65        21

    accuracy                           0.77        60
   macro avg       0.74      0.73      0.74        60
weighted avg       0.76      0.77      0.76        60

Model saved to model.pkl
```

Let us read through what these numbers mean. **Accuracy** at 76.67% means the model correctly predicted the outcome for about 3 out of 4 students in the test set. **Precision** for the "Fail" class (0.80) means that when the model predicts a student will fail, it is correct 80% of the time. **Recall** for "Fail" (0.85) means the model catches 85% of all students who actually did fail. Notice that the "Pass" class scores lower on both metrics: precision of 0.68 and recall of 0.62. This is a direct consequence of the class imbalance. Because the model saw nearly twice as many "Fail" examples during training, it learned that boundary more confidently. **F1-score** is the harmonic mean of precision and recall, giving you a single balanced metric per class that is especially useful when classes are not equal in size. For a first model on a small synthetic dataset, these numbers are a realistic and honest starting point.

## Step 4: Save and Verify the Model {#step-4-save-verify-model}

The training script already saved `model.pkl` using `joblib.dump()`. But before handing this file off to a Flask application in Part 2, you should confirm that loading it and making a prediction actually works as expected. Catching a serialization issue here is far easier than debugging it inside a running web server.

Open `predict.py` and write the following:

```python
# predict.py

import joblib
import pandas as pd

# Load the model from disk.
# joblib.load() reverses joblib.dump(): it reads the binary file and reconstructs
# the exact same trained model object in memory, with all its learned weights intact.
model = joblib.load('model.pkl')

print("Model loaded successfully.")
print(f"Model type: {type(model).__name__}")

# Define two sample students to test with.
# Each sample is a dictionary with the exact same column names used during training.
# Using a dictionary (and building a DataFrame from it) is important: the model
# was fitted on a DataFrame with named columns, so passing a plain numpy array
# would trigger a warning about mismatched feature names.
samples = [
    {'study_hours': 7.5, 'attendance_pct': 85.0, 'avg_score': 78.0},  # strong candidate
    {'study_hours': 2.0, 'attendance_pct': 45.0, 'avg_score': 35.0},  # weak candidate
]

print("\n--- Predictions ---")

for i, sample in enumerate(samples):
    # pd.DataFrame([sample]) wraps the dictionary into a single-row DataFrame.
    # The column names automatically match what the model was trained on,
    # which is exactly what scikit-learn expects.
    sample_df = pd.DataFrame([sample])

    prediction  = model.predict(sample_df)[0]
    probability = model.predict_proba(sample_df)[0]

    label      = "Pass" if prediction == 1 else "Fail"
    confidence = max(probability)

    print(f"Student {i + 1}: {list(sample.values())}")
    print(f"  Prediction : {label}")
    print(f"  Confidence : {confidence:.1%}")
    print()
```

Save the file and run it:

```bash
python predict.py
```

Expected output:

```
Model loaded successfully.
Model type: LogisticRegression

--- Predictions ---
Student 1: [7.5, 85.0, 78.0]
  Prediction : Pass
  Confidence : 76.5%

Student 2: [2.0, 45.0, 35.0]
  Prediction : Fail
  Confidence : 99.3%
```

Both predictions match what you would expect. Student 1 has solid attendance and a good score, so the model predicts Pass. Student 2 has poor attendance and a low score, so the model predicts Fail with very high confidence (99.3%). Notice that Student 1's confidence is lower at 76.5%, which reflects the class imbalance you saw earlier: the model is less certain about "Pass" cases because it has seen fewer examples of them during training. That nuance is actually useful information, and in Part 2 you will include both the prediction label and the confidence value in the JSON response so API callers can handle borderline cases accordingly.

One important detail about the code: the sample is passed as a `pd.DataFrame` with named columns rather than a plain numpy array. The reason is that when you trained the model in `train.py`, the input `X` was a DataFrame with columns named `study_hours`, `attendance_pct`, and `avg_score`. If you pass a numpy array without those names at prediction time, scikit-learn raises a `UserWarning` because it cannot verify that the features are in the correct order. Using a DataFrame with matching column names eliminates that warning and makes the intent of the code explicit.

## How Logistic Regression Works {#how-logistic-regression-works}

Now that you have seen what the model produces, it is worth understanding what is actually happening inside it. You do not need to memorize the math, but a clear mental model will help you make better decisions in future projects.

### The Core Idea

Despite its name, Logistic Regression is a **classification** algorithm, not a regression one. The name comes from the mathematical function it uses internally: the **logistic function** (also called the sigmoid). This function takes any real number and squashes it into a value between 0 and 1, making it perfect for representing a probability.

When you call `model.fit(X_train, y_train)`, the algorithm looks at your training data and figures out a set of **weights**, one for each feature. In your case, that is one weight for `study_hours`, one for `attendance_pct`, and one for `avg_score`, plus a bias term. The algorithm adjusts these weights iteratively until the predicted probabilities are as close as possible to the actual labels.

Once training is done, making a prediction works like this: the model multiplies each feature value by its corresponding weight, sums everything up, passes the result through the sigmoid function, and produces a number between 0 and 1. If that number is above 0.5, it predicts class 1 (Pass); otherwise it predicts class 0 (Fail).

### Why It Works Well Here

Logistic Regression performs well when the boundary between classes can be described as a straight line (or a flat hyperplane in higher dimensions). In this dataset, the pass/fail rule you defined is essentially linear: students with high scores and high attendance pass. That maps directly onto what Logistic Regression is designed to find.

It also has the advantage of being fast to train, easy to interpret, and naturally produces probabilities through `predict_proba()`. For a student with borderline values, knowing the model is only 61% confident is genuinely useful information, whereas a decision tree would just give you a hard yes or no.

### When to Choose Something Else

Logistic Regression is a good default for binary classification problems with numerical features. If your data has complex non-linear boundaries, such as patterns that look like rings or spirals, or if you have hundreds of interacting features, then algorithms like Random Forest, Gradient Boosting, or neural networks tend to outperform it. For this tutorial, Logistic Regression is exactly the right tool.

## Conclusion {#conclusion}

You have gone from an empty folder to a trained, saved, and verified machine learning model. Here are the key things to take away from this article.

- **Synthetic datasets are a legitimate learning tool.** Creating data with NumPy lets you control the signal, the noise, and the class distribution, which makes it much easier to understand whether your model is learning correctly.
- **The train/test split is non-negotiable.** Evaluating a model on the same data it was trained on gives you a falsely optimistic accuracy. Holding out 20% of data as a test set gives you an honest estimate of how the model will behave on new input.
- **`stratify=y` matters more than it looks.** If your dataset has more of one class than the other, a random split could accidentally put most of one class in the test set. Stratification prevents that by preserving the class ratio in both splits.
- **`joblib` is the right way to persist scikit-learn models.** It handles NumPy arrays and internal state more reliably than Python's built-in `pickle` for large numeric objects.
- **`predict_proba()` gives you confidence, not just a label.** A hard prediction of Pass or Fail tells you the outcome; the probability tells you how certain the model is. Always expose this in your API so callers can act on borderline cases accordingly.
- **Logistic Regression is a solid baseline.** It trains quickly, produces interpretable weights, and gives you probability estimates out of the box. Always try the simple model before reaching for more complex ones.

In Part 2, you will take the `model.pkl` file you just created and build a Flask application around it, exposing the prediction logic as a clean JSON API endpoint.