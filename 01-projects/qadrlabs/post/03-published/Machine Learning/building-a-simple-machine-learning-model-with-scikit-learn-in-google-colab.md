---
title: "Building a Simple Machine Learning Model with Scikit-Learn in Google Colab"
slug: "building-a-simple-machine-learning-model-with-scikit-learn-in-google-colab"
category: "Machine Learning"
date: "2026-04-27"
status: "published"
---

You have been reading about machine learning for a while. You understand the concepts, you know Python, and you have seen plenty of code snippets online. But when the time actually comes to sit down and build something from scratch, the question hits: where do I even start? Most tutorials assume you already have a perfectly formatted dataset sitting on your disk, and many of them skip explaining why each step exists. If that gap between theory and a first working model feels frustrating, you are in the right place.

This article takes a direct, practical approach using Google Colab. You will write code directly in your browser without worrying about local environment setup. You will create a synthetic dataset from scratch, train a Logistic Regression classifier that predicts whether a student passes or fails, evaluate its performance properly, and save the trained model to a file so it can be reused. In Part 2 of this series, you will download that saved model and load it inside a Flask application to expose it as a JSON API.

## Overview {#overview}

Unlike the [previous tutorial](https://qadrlabs.com/post/building-a-simple-machine-learning-model-with-scikit-learn), this article is the first part of a two-part series on building and deploying machine learning models. Before you can serve a model, you need a model worth serving. That is exactly what this article covers: building, evaluating, and persisting a trained scikit-learn model in a clean, reusable way using a cloud-based notebook environment.

### What You'll Build

- A Google Colab notebook that generates a synthetic student dataset and saves it as a CSV file.
- A trained Logistic Regression classifier that predicts whether a student passes based on their study hours, attendance percentage, and average exam score.
- A saved model file (`model.pkl`) that can be downloaded and reused by any Python application.

### What You'll Learn

- How to use Google Colab for interactive machine learning development.
- How to create a realistic synthetic dataset using NumPy and Pandas.
- How to split data into training and testing sets using scikit-learn.
- How to evaluate a model using accuracy score and a full classification report.
- How to save and reload a trained model with `joblib`.

### What You'll Need

- A Google account to access Google Colab.
- A modern web browser.
- Basic familiarity with Python functions and data structures.
- No prior machine learning experience is required; core concepts will be explained as you go.

## Step 1: Set Up the Google Colab Environment {#step-1-setup-colab}

A clean project environment is essential, but configuring Python and installing libraries locally can sometimes be an obstacle for beginners. Google Colab solves this by providing a free Jupyter notebook environment hosted in the cloud. It comes pre-installed with all the data science libraries you will need for this tutorial.

Start by opening your web browser and navigating to [colab.research.google.com](https://colab.research.google.com/). Sign in with your Google account if you are not already logged in. Click on "New notebook" to create a fresh, empty workspace. 

By default, Colab already has `scikit-learn`, `pandas`, `numpy`, and `joblib` installed and ready to go. You will use **scikit-learn** to train and evaluate the model, **pandas** to create and manipulate the dataset, **numpy** to handle numerical operations and generate random data, and **joblib** to serialize the trained model to disk.

Rename your notebook by clicking on the title `Untitled0.ipynb` at the top left and changing it to `Student_Pass_Predictor.ipynb`.

## Step 2: Create the Dataset {#step-2-create-dataset}

Real-world datasets often come with missing values, inconsistent column names, and surprises you did not plan for. For a first project, that complexity is a distraction from learning the machine learning workflow itself. Using a synthetic dataset lets you focus entirely on the core steps without spending hours on data cleaning.

The scenario is straightforward: you have a group of 300 students. For each student, you know three things: how many hours per day they study, what percentage of classes they attended, and what their average exam score is. The goal is to predict whether each student passes or fails.

In your Colab notebook, click into the first empty code cell and write the following code:

```python
import numpy as np
import pandas as pd

# Fix the random seed so this script produces the same dataset every time it runs.
# Reproducibility is important: two people running this code should get
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

Run the cell by pressing `Shift + Enter` or clicking the "Play" button on the left side of the cell. You should see output similar to this below the cell:

```text
Dataset created: 300 records

Class distribution:
pass
0    193
1    107

First 5 rows:
   study_hours  attendance_pct  avg_score  pass
0          4.4            43.1       41.8     0
1          9.6            71.9       49.5     0
2          7.6            72.4       42.4     0
3          6.4            78.2       36.2     0
4          2.4            83.6       38.4     0
```

The class distribution shows 193 failing students and 107 passing ones. This is a moderately imbalanced dataset with roughly a 64 to 36 split. It is realistic, since in practice more students tend to fail than pass in a strict grading scenario. This imbalance is also why the classification report later will show different precision and recall values between the two classes. The model has more "Fail" examples to learn from, which affects how it handles the minority "Pass" class. You now have `student_data.csv` saved in your Colab session storage.

## Step 3: Train the Model {#step-3-train-model}

With the dataset ready, you can write the training code. This is where the machine learning actually happens: loading the data, splitting it into training and testing portions, fitting the model, and measuring how well it performs on data it has never seen before.

Create a new code cell in your Colab notebook and write the following:

```python
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score
import joblib

# Load the dataset from the CSV file generated in the previous cell
df = pd.read_csv('student_data.csv')

# Separate features (X) from the label (y).
# X is a DataFrame with the three columns the model will learn from.
# y is a Series containing the value the model is trying to predict (0 or 1).
X = df[['study_hours', 'attendance_pct', 'avg_score']]
y = df['pass']

# Split data into training and testing sets
# We use 80 percent of the data for training and hold out 20 percent for testing.
# The test set simulates unseen data so you get an honest performance estimate.
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

# Initialize and train the Logistic Regression model
# LogisticRegression finds the best set of weights to predict the probability
# that a student passes, given their three feature values.
# max_iter=200 gives the solver enough iterations to converge on those weights.
# random_state=42 keeps results reproducible for solvers that have randomness.
model = LogisticRegression(max_iter=200, random_state=42)
model.fit(X_train, y_train)

print("\nModel training complete.")

# Evaluate the model on the testing set
# We predict on X_test (the held-out data the model never saw during training),
# then compare those predictions to the actual labels in y_test.
y_pred = model.predict(X_test)

accuracy = accuracy_score(y_test, y_pred)
print(f"\nAccuracy: {accuracy:.2%}")

print("\nClassification Report:")
print(classification_report(y_test, y_pred, target_names=['Fail', 'Pass']))

# Save the trained model to a file using joblib
# joblib.dump() serializes the model object into a binary file.
# This lets you reload the exact same trained model later without retraining.
joblib.dump(model, 'model.pkl')
print("Model saved to model.pkl")
```

Run the cell. Expected output:

```text
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

The training cell already saved `model.pkl` to your Colab session storage. Before downloading this file to use in a future application, you should confirm that loading it and making a prediction actually works as expected. Catching a serialization issue right away is far easier than debugging it inside a running web server later.

Create a final code cell and write the following:

```python
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

print("\nModel Predictions:")

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

Run the cell. Expected output:

```text
Model loaded successfully.
Model type: LogisticRegression

Model Predictions:
Student 1: [7.5, 85.0, 78.0]
  Prediction : Pass
  Confidence : 76.5%

Student 2: [2.0, 45.0, 35.0]
  Prediction : Fail
  Confidence : 99.3%
```

Both predictions match what you would expect. Student 1 has solid attendance and a good score, so the model predicts Pass. Student 2 has poor attendance and a low score, so the model predicts Fail with very high confidence (99.3%). Notice that Student 1's confidence is lower at 76.5%, which reflects the class imbalance you saw earlier. The model is less certain about "Pass" cases because it has seen fewer examples of them during training. That nuance is actually useful information.

To download the model for future use, click on the **Folder icon** on the left sidebar of Colab to open the file explorer. Locate `model.pkl`, click the three dots next to the file name, and select **Download**. You will need this file when building your Flask application.

## How Logistic Regression Works {#how-logistic-regression-works}

Now that you have seen what the model produces, it is worth understanding what is actually happening inside it. You do not need to memorize the math, but a clear mental model will help you make better decisions in future projects.

### The Core Idea

Despite its name, Logistic Regression is a classification algorithm, not a regression one. The name comes from the mathematical function it uses internally: the logistic function, which is also called the sigmoid. This function takes any real number and squashes it into a value between 0 and 1, making it perfect for representing a probability.

When you call `model.fit(X_train, y_train)`, the algorithm looks at your training data and figures out a set of weights, one for each feature. In your case, that is one weight for `study_hours`, one for `attendance_pct`, and one for `avg_score`, plus a bias term. The algorithm adjusts these weights iteratively until the predicted probabilities are as close as possible to the actual labels.

Once training is done, making a prediction works systematically. The model multiplies each feature value by its corresponding weight, sums everything up, passes the result through the sigmoid function, and produces a number between 0 and 1. If that number is above 0.5, it predicts class 1 (Pass); otherwise it predicts class 0 (Fail).

### Why It Works Well Here

Logistic Regression performs well when the boundary between classes can be described as a straight line, or a flat hyperplane in higher dimensions. In this dataset, the pass and fail rule you defined is essentially linear: students with high scores and high attendance pass. That maps directly onto what Logistic Regression is designed to find.

It also has the advantage of being fast to train, easy to interpret, and naturally produces probabilities through `predict_proba()`. For a student with borderline values, knowing the model is only 61% confident is genuinely useful information, whereas a simpler decision tree would just give you a hard yes or no.

### When to Choose Something Else

Logistic Regression is a good default for binary classification problems with numerical features. If your data has complex non-linear boundaries, such as patterns that look like rings or spirals, or if you have hundreds of interacting features, then algorithms like Random Forest, Gradient Boosting, or neural networks tend to outperform it. For this tutorial, Logistic Regression is exactly the right tool.

## Conclusion {#conclusion}

You have gone from an empty browser window to a trained, saved, and verified machine learning model running in the cloud. Here are the key things to take away from this article.

- **Synthetic datasets are a legitimate learning tool.** Creating data with NumPy lets you control the signal, the noise, and the class distribution, which makes it much easier to understand whether your model is learning correctly.
- **The train and test split is mandatory.** Evaluating a model on the same data it was trained on gives you a falsely optimistic accuracy. Holding out 20 percent of data as a test set gives you an honest estimate of how the model will behave on new input.
- **Stratification matters more than it looks.** If your dataset has more of one class than the other, a random split could accidentally put most of one class in the test set. Using `stratify=y` prevents that by preserving the class ratio in both splits.
- **Joblib is the right way to persist scikit-learn models.** It handles NumPy arrays and internal state more reliably than Python's built-in `pickle` for large numeric objects.
- **Probabilities give you confidence, not just a label.** A hard prediction of Pass or Fail tells you the outcome; the probability tells you how certain the model is. Exposing this data allows you to handle borderline cases intelligently.
- **Logistic Regression is a solid baseline.** It trains quickly, produces interpretable weights, and gives you probability estimates out of the box. Always try the simple model before reaching for more complex ones.