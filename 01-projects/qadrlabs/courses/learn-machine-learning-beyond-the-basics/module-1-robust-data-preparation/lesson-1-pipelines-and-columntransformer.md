## 1. Before You Begin

Welcome to the next stage of your machine learning journey. In the beginner course you cleaned data step by step: you imputed missing values, encoded categories, and scaled features, each in its own line of code, applied by hand to the training set and then again to the test set. It worked, but it was fragile. It is easy to forget a step, apply something to the wrong set, or accidentally let test data influence your training. That last mistake, called data leakage, quietly inflates your scores and ruins models in production.

In this lesson you learn the professional way to handle preprocessing: scikit-learn pipelines. A pipeline bundles every preprocessing step and the model into a single object that you `fit` and `predict` like any other model. Combined with `ColumnTransformer`, which applies different steps to different columns, you get clean, reproducible, leak-free preprocessing in a few lines.

### What You'll Build

A complete pipeline for the Titanic dataset that takes raw data, missing values and text columns included, and handles everything internally: median imputation and scaling for numeric columns, most-frequent imputation and one-hot encoding for categorical columns, then a logistic regression classifier. You will train it, score it, and predict survival for brand new raw passengers with no manual preprocessing.

### What You'll Learn

- ✅ What data leakage is and why pipelines prevent it
- ✅ How to build a `Pipeline` that chains preprocessing and a model
- ✅ How to use `ColumnTransformer` to treat numeric and categorical columns differently
- ✅ How `SimpleImputer` and `OneHotEncoder` fit into a pipeline
- ✅ How to predict on raw, unprocessed new data
- ✅ Why pipelines make cross-validation safe

### What You'll Need

- The data-prep skills from the beginner course (imputation, encoding, scaling)
- A Colab notebook with scikit-learn and seaborn
- The Titanic dataset (built into seaborn)

---

## 2. The Problem Pipelines Solve

In the beginner course, you scaled the test set using values learned from the training set, and you were careful to call `fit` only on training data. That care is exactly what pipelines automate. The danger they remove is data leakage: when information from the test set sneaks into the training process and makes your model look better than it really is.

Leakage creeps in through small mistakes:

- Computing an imputation median or a scaler's mean over the whole dataset before splitting, so the training step has secretly seen the test rows.
- Forgetting to apply a transformation to new data before predicting.
- Tuning a model with cross-validation while preprocessing the data only once outside the folds, so each fold's validation data leaks into preprocessing.

A pipeline fixes all of these by treating preprocessing as part of the model. When you call `fit`, every step learns from the training data only. When you call `predict`, the same fitted steps are applied automatically. You can no longer forget a step or apply it to the wrong data, because there is only one object to call.

---

## 3. Build a Pipeline for One Column Type

Let us start simple to see the mechanics, then scale up. A `Pipeline` is just a list of named steps, where every step except the last is a transformer and the last is usually a model.

### Step 1: Load the raw data

```python
import pandas as pd
import seaborn as sns

titanic = sns.load_dataset("titanic")
df = titanic[["survived", "pclass", "sex", "age", "sibsp", "parch", "fare", "embarked"]].copy()
print(df.isnull().sum().to_string())
```

Output:

```
survived      0
pclass        0
sex           0
age         177
sibsp         0
parch         0
fare          0
embarked      2
```

We deliberately keep the raw data with all its problems: `age` has 177 missing values, `embarked` has 2, and `sex` and `embarked` are text. The whole point is to let the pipeline handle this mess for us, instead of cleaning it by hand first.

### Step 2: Split before anything else

```python
from sklearn.model_selection import train_test_split

X = df.drop(columns="survived")
y = df["survived"]
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
```

You split first, before any preprocessing, so the test set stays completely untouched. The pipeline will learn all its imputation and scaling values from `X_train` only, which is what prevents leakage.

---

## 4. Handle Different Columns with ColumnTransformer

Numeric and categorical columns need different treatment. Numeric columns want median imputation and scaling; categorical columns want most-frequent imputation and one-hot encoding. `ColumnTransformer` lets you apply each recipe to the right columns in one object.

### Step 1: Define which columns get which treatment

```python
numeric_features = ["age", "fare", "sibsp", "parch", "pclass"]
categorical_features = ["sex", "embarked"]
```

You list the columns by type. The numeric features will be imputed and scaled; the categorical features will be imputed and encoded. Listing them explicitly keeps the intent clear.

### Step 2: Build a small pipeline for each type

```python
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, OneHotEncoder

numeric_transformer = Pipeline(steps=[
    ("imputer", SimpleImputer(strategy="median")),
    ("scaler", StandardScaler()),
])

categorical_transformer = Pipeline(steps=[
    ("imputer", SimpleImputer(strategy="most_frequent")),
    ("onehot", OneHotEncoder(handle_unknown="ignore")),
])
```

Each `Pipeline` is a named list of steps. The numeric one first fills missing values with the column median (`SimpleImputer(strategy="median")`), then standardizes with `StandardScaler`. The categorical one fills missing values with the most frequent category, then one-hot encodes. `handle_unknown="ignore"` tells the encoder to safely ignore any category it did not see during training, instead of crashing on new data.

### Step 3: Combine them with ColumnTransformer

```python
from sklearn.compose import ColumnTransformer

preprocessor = ColumnTransformer(transformers=[
    ("num", numeric_transformer, numeric_features),
    ("cat", categorical_transformer, categorical_features),
])
```

`ColumnTransformer` routes each group of columns through its matching transformer. The `num` transformer runs on the numeric features and the `cat` transformer on the categorical ones, then the results are joined back into one feature matrix. This single object now encapsulates all of your preprocessing.

---

## 5. Add the Model and Train the Full Pipeline

The final move is to put the preprocessor and a model into one outer pipeline. Now the entire workflow, cleaning and modeling, is a single object.

### Step 1: Assemble the full pipeline

```python
from sklearn.linear_model import LogisticRegression

clf = Pipeline(steps=[
    ("preprocessor", preprocessor),
    ("classifier", LogisticRegression(max_iter=1000)),
])
```

The outer pipeline has two steps: the `preprocessor` you just built, followed by a `classifier`. When data flows through, it is preprocessed and then handed to logistic regression, all automatically.

### Step 2: Fit and score

```python
from sklearn.metrics import accuracy_score

clf.fit(X_train, y_train)
print("test accuracy:", round(accuracy_score(y_test, clf.predict(X_test)), 4))
```

Output:

```
test accuracy: 0.8045
```

One call to `clf.fit(X_train, y_train)` learns the imputation values, the scaler, the encoder, and the model, all from the training data only. One call to `clf.predict(X_test)` applies the exact same transformations to the test data and predicts. The accuracy of 0.8045 matches what you achieved by hand in the beginner capstone, but now there is zero risk of leakage and far less code to get wrong.

---

## 6. Predict on Raw New Data

This is where pipelines really shine. Because preprocessing lives inside the pipeline, you can predict directly on raw new passengers, with text and everything, and the pipeline cleans them for you.

```python
new_passenger = pd.DataFrame([{
    "pclass": 3, "sex": "male", "age": 25, "sibsp": 0,
    "parch": 0, "fare": 7.25, "embarked": "S"
}])
print("prediction:", clf.predict(new_passenger))
print("probabilities:", clf.predict_proba(new_passenger).round(3))
```

Output:

```
prediction: [0]
probabilities: [[0.9 0.1]]
```

Notice the new passenger uses raw values: `"male"` and `"S"` as text, not numbers. You did no imputation, no encoding, no scaling. The pipeline applied every fitted transformation automatically before predicting that this third-class man likely died, with 90 percent probability. Compare that to the beginner course, where you had to manually encode and scale every new example in exactly the right way. Pipelines remove that whole class of mistakes.

---

## 7. Why This Makes Cross-Validation Safe

You will study cross-validation properly in Lesson 6, but it is worth seeing now why pipelines matter for it. Cross-validation trains and validates a model on several different splits of the data. If you preprocess once, outside the process, every split's validation data leaks into that preprocessing. A pipeline avoids this because it re-fits its preprocessing inside each split.

```python
from sklearn.model_selection import cross_val_score

scores = cross_val_score(clf, X_train, y_train, cv=5, scoring="accuracy")
print("cv scores:", scores.round(4))
print("cv mean:", round(scores.mean(), 4))
```

Output:

```
cv scores: [0.7902 0.7622 0.8028 0.8169 0.8099]
cv mean: 0.7964
```

`cross_val_score` splits the training data into 5 parts, and for each part it re-fits the entire pipeline (preprocessing and all) on the other 4 parts before scoring. Because the pipeline learns its imputation and scaling fresh inside every fold, there is no leakage. The mean of about 0.80 is a more reliable estimate of performance than any single split. Do not worry about the details yet; just note that passing a pipeline (not raw preprocessed data) to cross-validation is what keeps it honest.

---

## 8. Fix the Errors in Your Code

These mistakes either break the pipeline or reintroduce the leakage it was meant to prevent.

**Mistake 1: Preprocessing outside the pipeline, then cross-validating.**

```python
# Wrong: scaling the whole training set once, then cross-validating, leaks across folds
X_scaled = StandardScaler().fit_transform(X_train)
cross_val_score(LogisticRegression(), X_scaled, y_train, cv=5)
```

```python
# Correct: put preprocessing in the pipeline and pass the pipeline to cross_val_score
clf = Pipeline([("preprocessor", preprocessor), ("classifier", LogisticRegression(max_iter=1000))])
cross_val_score(clf, X_train, y_train, cv=5)
```

If preprocessing happens once outside cross-validation, each fold's validation data has already influenced it. Keep preprocessing in the pipeline so it re-fits per fold.

**Mistake 2: Listing a column in the wrong transformer.**

```python
# Wrong: putting a text column in the numeric list makes the scaler fail
numeric_features = ["age", "fare", "sex"]   # sex is text
```

```python
# Correct: numeric transformers get numeric columns, categorical get text columns
numeric_features = ["age", "fare", "sibsp", "parch", "pclass"]
categorical_features = ["sex", "embarked"]
```

`StandardScaler` cannot scale text. Route each column to the transformer that matches its type.

**Mistake 3: Forgetting handle_unknown on the encoder.**

```python
# Risky: a category not seen in training will crash prediction
OneHotEncoder()
```

```python
# Safer: ignore unseen categories at prediction time
OneHotEncoder(handle_unknown="ignore")
```

Real new data sometimes contains categories your training data did not. `handle_unknown="ignore"` lets the pipeline handle them gracefully instead of raising an error.

---

## 9. Exercises

**Exercise 1:** Rebuild the full pipeline but swap the logistic regression for a `DecisionTreeClassifier(max_depth=4, random_state=42)`. Train it and print the test accuracy. (Note: trees do not need scaling, but leaving the scaler in does no harm.)

**Exercise 2:** Using your decision tree pipeline, predict the survival of a raw passenger: a 2nd class female, age 8, with 1 sibling and 2 parents aboard, fare 30, embarked at Southampton. Print the prediction and probabilities.

**Exercise 3:** After fitting the original logistic regression pipeline, print the names of the features produced by the preprocessor using `clf.named_steps["preprocessor"].get_feature_names_out()`. How many features did one-hot encoding create?

---

## 10. Solutions

**Solution for Exercise 1:**

```python
from sklearn.tree import DecisionTreeClassifier

tree_clf = Pipeline(steps=[
    ("preprocessor", preprocessor),
    ("classifier", DecisionTreeClassifier(max_depth=4, random_state=42)),
])
tree_clf.fit(X_train, y_train)
print("test accuracy:", round(accuracy_score(y_test, tree_clf.predict(X_test)), 4))
```

Output:

```
test accuracy: 0.7877
```

Swapping the model is a one-line change because the preprocessing is reusable. The tree scores 0.7877 here, slightly below logistic regression on this split. The pipeline structure stays identical no matter which model you drop in.

**Solution for Exercise 2:**

```python
new = pd.DataFrame([{
    "pclass": 2, "sex": "female", "age": 8, "sibsp": 1,
    "parch": 2, "fare": 30.0, "embarked": "S"
}])
print("prediction:", tree_clf.predict(new))
print("probabilities:", tree_clf.predict_proba(new).round(3))
```

Output:

```
prediction: [1]
probabilities: [[0.083 0.917]]
```

The pipeline cleans the raw passenger and the tree predicts survival with about 92 percent probability. A young girl in 2nd class fits the strongest survival profile, so the confident prediction makes sense.

**Solution for Exercise 3:**

```python
clf.fit(X_train, y_train)
print(clf.named_steps["preprocessor"].get_feature_names_out())
```

Output:

```
['num__age' 'num__fare' 'num__sibsp' 'num__parch' 'num__pclass'
 'cat__sex_female' 'cat__sex_male' 'cat__embarked_C' 'cat__embarked_Q'
 'cat__embarked_S']
```

The preprocessor turned 7 input columns into 10 features. The 5 numeric columns pass through as themselves (prefixed `num__`), while `sex` became 2 columns and `embarked` became 3 columns (prefixed `cat__`). The prefixes tell you which transformer produced each feature, which is handy when you inspect a model later.

---

## Next Up - Lesson 2

You now build preprocessing the professional way. A pipeline bundles imputation, scaling, encoding, and the model into one leak-proof object that you can fit, predict, and cross-validate, even on raw data. This is the foundation every later lesson in this course builds on.

In Lesson 2, you will focus on feature engineering: creating new, more informative features from the data you already have. A good engineered feature can boost a model more than a fancier algorithm, and you will fold your new features cleanly into the pipeline you just learned to build.
