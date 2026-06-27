## 1. Before You Begin

So far, every model you have built lived only for the life of your notebook. Close Colab, and your trained model is gone, ready to be retrained from scratch next time. That is fine for learning, but useless for real applications. A model is valuable because you train it once and then use it many times, often in a different program, a web app, or weeks later. To do that, you need to save it to a file and load it back.

In this lesson you will save a fully trained pipeline, preprocessing and model together, to a single file with `joblib`, then load it back and make predictions, confirming it behaves exactly as before. This is the bridge between a model in a notebook and a model that does real work.

### What You'll Build

A trained Titanic pipeline saved to a file with `joblib`, then loaded back in a fresh step and used to predict on raw new passengers, with a check that the loaded model's predictions are identical to the original. You will also see how model size varies and how to compress it.

### What You'll Learn

- ✅ Why and when to save a trained model
- ✅ How to save a whole pipeline with `joblib.dump`
- ✅ How to load it back with `joblib.load`
- ✅ Why saving the entire pipeline matters
- ✅ How to compress large models
- ✅ Important cautions about versions and security

### What You'll Need

- A trained pipeline (you will build one here)
- A Colab notebook with scikit-learn and `joblib`
- The Titanic dataset (built into seaborn)

---

## 2. Why Save a Model?

Training can be slow and depends on having your training data and code on hand. Once a model is trained, you usually want to reuse it without redoing any of that. Saving the model, a process called serialization or persistence, writes the trained object to a file so you can load it anytime.

Saving a model lets you:

- **Train once, predict forever.** Skip retraining every time you need a prediction.
- **Deploy the model.** Load it inside a web API, a scheduled job, or another program that has never seen your training code.
- **Share and reproduce.** Hand the file to a colleague who can use the exact model you trained.

The crucial idea for this course: you save the whole pipeline, not just the final estimator. Because your pipeline includes imputation, scaling, and encoding, saving it means all of that preprocessing travels with the model. When you load it later, you can feed it raw data and it will clean and predict in one step, with no need to reimplement any preprocessing.

---

## 3. Save a Trained Pipeline

First build and train a pipeline as usual, then write it to a file.

### Step 1: Train the pipeline

```python
import pandas as pd
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score

titanic = sns.load_dataset("titanic")
df = titanic[["survived", "pclass", "sex", "age", "sibsp", "parch", "fare", "embarked"]].copy()
X = df.drop(columns="survived")
y = df["survived"]
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

numeric = ["age", "fare", "sibsp", "parch", "pclass"]
categorical = ["sex", "embarked"]
preprocessor = ColumnTransformer([
    ("num", Pipeline([("imp", SimpleImputer(strategy="median")), ("sc", StandardScaler())]), numeric),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
])

clf = Pipeline([("pre", preprocessor), ("clf", LogisticRegression(max_iter=1000))])
clf.fit(X_train, y_train)
print("trained accuracy:", round(accuracy_score(y_test, clf.predict(X_test)), 4))
```

Output:

```
trained accuracy: 0.8045
```

This is the familiar Titanic pipeline, trained and scoring 0.8045. The `clf` object now holds the fitted preprocessing and the fitted model. That whole object is what we will save.

### Step 2: Save it with joblib

```python
import joblib

joblib.dump(clf, "titanic_model.joblib")
```

`joblib.dump` writes the entire pipeline to a file named `titanic_model.joblib`. `joblib` is scikit-learn's recommended tool for this, because it stores the large NumPy arrays inside models efficiently. The file now contains everything: the imputers, the scaler, the encoder, and the trained logistic regression. In Colab the file lands in your session storage; to keep it, you would download it or save it to Google Drive.

---

## 4. Load and Use the Model

Now imagine a fresh program, days later, that has the file but not the training code. You load the model and use it immediately.

### Step 1: Load the model

```python
loaded_model = joblib.load("titanic_model.joblib")
print("loaded accuracy:", round(accuracy_score(y_test, loaded_model.predict(X_test)), 4))
```

Output:

```
loaded accuracy: 0.8045
```

`joblib.load` reconstructs the full pipeline from the file. Its accuracy is 0.8045, identical to before saving, because it is literally the same trained object restored from disk. No retraining happened.

### Step 2: Predict on raw new data

```python
new_passenger = pd.DataFrame([{
    "pclass": 3, "sex": "male", "age": 25, "sibsp": 0,
    "parch": 0, "fare": 7.25, "embarked": "S"
}])
print("prediction:", loaded_model.predict(new_passenger))
print("probabilities:", loaded_model.predict_proba(new_passenger).round(3))
```

Output:

```
prediction: [0]
probabilities: [[0.9 0.1]]
```

This is the payoff. The loaded model takes a raw passenger, with text values and no manual preprocessing, and predicts directly, because the saved pipeline carries its own imputation, scaling, and encoding. A web app could do exactly this: load the file once at startup, then call `predict` on incoming requests.

### Step 3: Confirm the predictions match

```python
import numpy as np

print("predictions identical:", np.array_equal(clf.predict(X_test), loaded_model.predict(X_test)))
```

Output:

```
predictions identical: True
```

`np.array_equal` confirms the original and loaded models produce exactly the same predictions on the test set. Saving and loading is lossless: you get back precisely the model you trained.

---

## 5. Compression, Versions, and Security

Saving models is simple, but three practical issues are worth knowing before you rely on it in real projects.

**Model size and compression.** Simple models are tiny, but complex ones can be large. The logistic regression above is only a few kilobytes, while a 200-tree random forest can be several megabytes, since it stores every tree. You can compress the file with `joblib.dump(model, "model.joblib", compress=3)`, trading a little save and load time for a much smaller file.

**Version compatibility.** A saved scikit-learn model is not guaranteed to load correctly in a different scikit-learn version. For anything important, record the library versions you trained with (for example in a `requirements.txt`) so you can recreate the same environment when loading. Loading across very different versions can fail or behave subtly wrong.

**Security.** `joblib` files use Python's pickle format under the hood, which can execute arbitrary code when loaded. Never load a `.joblib` or pickle file from an untrusted source, because a malicious file could run harmful code on your machine. Only load models you or people you trust created.

Keep these in mind and saving models becomes a reliable part of your workflow rather than a source of surprises.

---

## 6. Fix the Errors in Your Code

These mistakes undermine saving and loading.

**Mistake 1: Saving only the model, not the whole pipeline.**

```python
# Wrong: saving just the classifier loses all the preprocessing
joblib.dump(clf.named_steps["clf"], "model.joblib")
```

```python
# Correct: save the entire pipeline so preprocessing travels with it
joblib.dump(clf, "model.joblib")
```

If you save only the final estimator, the loaded model expects already-preprocessed data and cannot handle raw input. Save the full pipeline.

**Mistake 2: Forgetting to fit before saving.**

```python
# Wrong: saving an unfitted pipeline stores a model that knows nothing
clf = Pipeline([...])
joblib.dump(clf, "model.joblib")   # never called fit
```

```python
# Correct: fit first, then save the trained pipeline
clf.fit(X_train, y_train)
joblib.dump(clf, "model.joblib")
```

Saving happens after training. An unfitted pipeline saved to disk is useless because it has not learned anything.

**Mistake 3: Loading a model from an untrusted source.**

```python
# Dangerous: loading an unknown file can execute malicious code
model = joblib.load("downloaded_from_random_site.joblib")
```

```python
# Safe: only load files you or trusted colleagues created
model = joblib.load("my_trained_model.joblib")
```

Because the format can run code on load, treat model files like executables. Only load ones you trust.

---

## 7. Exercises

**Exercise 1:** Train a random forest pipeline (200 trees) on the Titanic data, save it with `joblib`, and print the file size in kilobytes. How does it compare to a logistic regression model?

**Exercise 2:** Load your saved random forest and confirm its test accuracy matches the original before saving.

**Exercise 3:** Save the same random forest again with `compress=3` and print the new file size. How much smaller is it, and does accuracy change after loading the compressed version?

---

## 8. Solutions

**Solution for Exercise 1:**

```python
import os, joblib
from sklearn.ensemble import RandomForestClassifier

rf_pre = ColumnTransformer([
    ("num", SimpleImputer(strategy="median"), numeric),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
])
rf = Pipeline([("pre", rf_pre), ("clf", RandomForestClassifier(n_estimators=200, random_state=42))])
rf.fit(X_train, y_train)

joblib.dump(rf, "rf_model.joblib")
print("file size (KB):", round(os.path.getsize("rf_model.joblib") / 1024, 1))
```

Output:

```
file size (KB): 4546.8
```

The random forest file is about 4547 KB, roughly 4.5 megabytes, because it stores all 200 trees. Compare that to the logistic regression in the lesson, which was only a few kilobytes. Model size grows with model complexity, which matters when you deploy or share models. (Exact sizes can vary slightly by environment.)

**Solution for Exercise 2:**

```python
from sklearn.metrics import accuracy_score

loaded_rf = joblib.load("rf_model.joblib")
print("loaded accuracy:", round(accuracy_score(y_test, loaded_rf.predict(X_test)), 4))
```

Output:

```
loaded accuracy: 0.8212
```

The loaded random forest scores 0.8212, exactly matching the model before saving. Like the logistic regression, persistence is lossless: you recover the identical trained model.

**Solution for Exercise 3:**

```python
joblib.dump(rf, "rf_compressed.joblib", compress=3)
print("compressed size (KB):", round(os.path.getsize("rf_compressed.joblib") / 1024, 1))

loaded_compressed = joblib.load("rf_compressed.joblib")
print("compressed accuracy:", round(accuracy_score(y_test, loaded_compressed.predict(X_test)), 4))
```

Output:

```
compressed size (KB): 785.0
compressed accuracy: 0.8212
```

Compression shrinks the file from about 4547 KB to 785 KB, roughly a sixth of the size, with no change in accuracy (still 0.8212). The trade-off is slightly slower saving and loading, which is usually well worth it for large models you need to store or transfer.

---

## Next Up - Lesson 13

You can now persist your work. With `joblib.dump` and `joblib.load` you save a fully trained pipeline, preprocessing and all, to a file and reload it later to predict on raw data, exactly as if it had never left memory. You also know how to compress large models and the version and security cautions to keep in mind.

In Lesson 13, you bring the entire course together in a capstone project. You will take a dataset from raw form all the way through a tuned, validated pipeline, evaluate it thoroughly, and save the finished model, combining every skill from this course into one complete, professional machine learning workflow.
