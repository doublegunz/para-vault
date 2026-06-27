## 1. Before You Begin

You can now load, manipulate, and explore data. That was the groundwork. In this lesson you finally train a machine learning model, and more importantly, you learn the workflow that every supervised model follows. Once you understand this workflow, learning a new algorithm becomes easy, because scikit-learn uses the exact same steps for all of them.

The pattern is short: separate your features from the target, split the data into a training set and a test set, train the model on the training set with `fit`, and make predictions with `predict`. You will use this same rhythm in every remaining lesson, so it is worth doing slowly and carefully here.

### What You'll Build

A notebook that takes the `tips` dataset, predicts the tip amount from the bill and party size, and walks through the complete workflow: building the feature matrix and target, splitting into train and test sets, training a model, predicting on unseen data, and taking a first look at how good those predictions are.

### What You'll Learn

- ✅ The difference between features (X) and the target (y)
- ✅ Why you split data into training and test sets
- ✅ How to use `train_test_split`
- ✅ The universal `fit` then `predict` pattern in scikit-learn
- ✅ How to make predictions on brand new data
- ✅ A first glimpse of measuring model quality

### What You'll Need

- The pandas and seaborn skills from Module 2
- A Colab notebook with scikit-learn available (it already is in Colab)
- The workflow overview from Lesson 1 fresh in your mind

---

## 2. The Supervised Learning Workflow

Every supervised learning project, whether it predicts prices or classifies emails, follows the same five steps. Keeping this map in mind stops machine learning from feeling like a pile of disconnected tricks.

1. **Features and target.** Split your table into the inputs the model learns from (the features, called `X`) and the answer you want to predict (the target, called `y`).
2. **Train and test split.** Hold back part of the data as a test set the model never sees during training, so you can check whether it really learned.
3. **Choose a model.** Pick an algorithm. In scikit-learn, every model is a class you create, like `LinearRegression()`.
4. **Train with fit.** Call `model.fit(X_train, y_train)` to let the model learn the patterns.
5. **Predict and evaluate.** Call `model.predict(X_test)` to get predictions on unseen data, then compare them to the real answers.

The beautiful part is that scikit-learn is consistent: `fit` then `predict` works the same way for linear regression, decision trees, and dozens of other models. Learn it once, use it everywhere. Let us walk through each step with real code.

---

## 3. Separate Features from the Target

The first step is deciding what you are predicting and what you will predict it from. By strong convention, the features are stored in a variable named `X` (capital) and the target in a variable named `y` (lowercase).

### Step 1: Load the data

```python
import seaborn as sns
import pandas as pd

tips = sns.load_dataset("tips")
tips.head()
```

We reuse the `tips` dataset you explored in Lesson 4. Our goal: predict the `tip` amount from how big the bill was and how many people were at the table.

### Step 2: Build X and y

```python
X = tips[["total_bill", "size"]]
y = tips["tip"]

print("X shape:", X.shape)
print("y shape:", y.shape)
```

Output:

```
X shape: (244, 2)
y shape: (244,)
```

`X = tips[["total_bill", "size"]]` selects the two feature columns, using double brackets so `X` stays a DataFrame (a table). `y = tips["tip"]` selects the single target column as a Series. The shapes confirm it: `X` has 244 rows and 2 columns, while `y` has 244 values and no second number because it is one column. The rule to remember is that `X` is two dimensional (a table of features) and `y` is one dimensional (the answers).

---

## 4. Split into Training and Test Sets

Here is the single most important idea in this lesson. If you train and test a model on the same data, you cannot trust the result, because the model may have simply memorized the answers. To measure real learning, you hold back data the model never sees during training.

### Step 1: Split the data

scikit-learn gives you a function that does this correctly, including shuffling the rows first:

```python
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

print("train:", X_train.shape, "test:", X_test.shape)
```

Output:

```
train: (195, 2) test: (49, 2)
```

`train_test_split` returns four pieces in this order: training features, test features, training target, test target. `test_size=0.2` means 20 percent of the rows go to the test set (49 rows) and 80 percent stay for training (195 rows). `random_state=42` fixes the random shuffling so you get the same split every time you run it, which makes your results reproducible. The exact number 42 is not special; any fixed number works.

### Step 2: Understand why this matters

Think of the test set as a final exam. The model studies from the training set, then you grade it on the test set, questions it has never seen. If it does well on the test set, it has learned a general pattern. If it does well on training but poorly on the test set, it merely memorized, a problem called overfitting that you will study in Lesson 10. Splitting your data is not optional; it is how you keep yourself honest.

---

## 5. Train a Model with fit

With the data split, you create a model and train it. Training means showing the model the training features and their correct answers so it can learn the relationship.

### Step 1: Create the model

```python
from sklearn.linear_model import LinearRegression

model = LinearRegression()
```

`LinearRegression()` creates an untrained model. At this point it knows nothing; it is an empty learner waiting for data. We are using linear regression here purely to demonstrate the workflow, and you will study it properly in the next lesson.

### Step 2: Train it with fit

```python
model.fit(X_train, y_train)
```

`model.fit(X_train, y_train)` is where learning happens. You pass the training features and the matching training answers, and the model adjusts itself to capture the pattern connecting them. Notice you only ever fit on the training data, never the test data. After this single line, the model is trained and ready to make predictions.

---

## 6. Make Predictions with predict

A trained model earns its keep by predicting answers for data it has not seen. That is what the test set is for, and it is also how you would use the model in the real world.

### Step 1: Predict on the test set

```python
predictions = model.predict(X_test)
print("first 5 predictions:", predictions[:5].round(2))
print("first 5 actual:     ", y_test[:5].values)
```

Output:

```
first 5 predictions: [2.9  1.9  3.86 3.98 2.28]
first 5 actual:      [3.18 2.   2.   5.16 2.  ]
```

`model.predict(X_test)` returns a predicted tip for each row in the test set. We print the first five predictions next to the first five real tips so you can compare. Some predictions are close, like 1.9 versus 2.0, and some are off, like 3.98 versus 5.16. No model is perfect, and seeing the gap between prediction and reality is the start of evaluating quality.

### Step 2: Predict on a brand new example

The real power is predicting for data that is not in your dataset at all. Say a new table has a 25 dollar bill and a party of 3:

```python
new = pd.DataFrame({"total_bill": [25.0], "size": [3]})
print("predicted tip:", model.predict(new).round(2))
```

Output:

```
predicted tip: [3.64]
```

You build a one-row DataFrame with the same feature columns the model was trained on, then call `predict`. The model estimates a tip of about 3.64 dollars. This is machine learning doing its job: turning patterns learned from past data into a prediction about a new situation.

---

## 7. A First Look at Model Quality

You compared a few predictions by eye, but you need a single number to judge a model fairly. Every scikit-learn model has a `score` method for a quick check.

```python
print("R2 on test:", round(model.score(X_test, y_test), 4))
```

Output:

```
R2 on test: 0.4811
```

For regression models, `score` returns a value called R squared (R2). It ranges up to 1.0, where 1.0 is a perfect fit and 0 means the model is no better than always guessing the average. Our 0.48 means the bill and party size explain a fair chunk of the variation in tips, but far from all of it, which is realistic since tipping also depends on service, mood, and habit. Do not worry about the details yet; Lesson 9 is devoted to evaluation metrics. The key point now is that `score` gives you one honest number, measured on the test set, to compare models.

---

## 8. Fix the Errors in Your Code

These three mistakes trip up nearly everyone learning the workflow. Spotting them quickly will save you hours.

**Mistake 1: Making the features one dimensional.**

```python
# Wrong: single brackets give a 1D Series, but models expect a 2D X
X = tips["total_bill"]
```

```python
# Correct: double brackets keep X as a 2D DataFrame
X = tips[["total_bill"]]
```

scikit-learn requires the features `X` to be two dimensional, even when there is only one feature. Use double brackets so `X` stays a table.

**Mistake 2: Unpacking train_test_split in the wrong order.**

```python
# Wrong: this order mislabels the pieces
X_train, y_train, X_test, y_test = train_test_split(X, y)
```

```python
# Correct: the order is X_train, X_test, y_train, y_test
X_train, X_test, y_train, y_test = train_test_split(X, y)
```

The function returns the two feature sets first, then the two target sets. Getting the order wrong silently mixes up your data and ruins your results.

**Mistake 3: Calling predict before fit.**

```python
# Wrong: the model has not learned anything yet
model = LinearRegression()
model.predict(X_test)
# NotFittedError
```

```python
# Correct: always fit before you predict
model = LinearRegression()
model.fit(X_train, y_train)
model.predict(X_test)
```

A model must be trained before it can predict. Always call `fit` first, and only ever fit on the training data.

---

## 9. Exercises

**Exercise 1:** Using the `tips` dataset, build `X` from just the `total_bill` column (remember double brackets) and `y` from `tip`. Print the shapes of `X` and `y`.

**Exercise 2:** Split that data with a 30 percent test set and `random_state=0`, then print the number of rows in the training and test sets.

**Exercise 3:** Train a `LinearRegression` model on the training set, predict on the test set, and print the model's `score` on the test set.

---

## 10. Solutions

**Solution for Exercise 1:**

```python
import seaborn as sns
tips = sns.load_dataset("tips")

X = tips[["total_bill"]]
y = tips["tip"]
print("X shape:", X.shape)
print("y shape:", y.shape)
```

Output:

```
X shape: (244, 1)
y shape: (244,)
```

`X` is now a table with 244 rows and 1 column, while `y` is a 1D Series of 244 values. The double brackets are what keep `X` two dimensional.

**Solution for Exercise 2:**

```python
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=0
)
print("train rows:", len(X_train))
print("test rows:", len(X_test))
```

Output:

```
train rows: 170
test rows: 74
```

A 30 percent test size puts 74 of the 244 rows in the test set and leaves 170 for training. `random_state=0` makes this split reproducible.

**Solution for Exercise 3:**

```python
from sklearn.linear_model import LinearRegression

model = LinearRegression()
model.fit(X_train, y_train)
print("R2 on test:", round(model.score(X_test, y_test), 4))
```

Output:

```
R2 on test: 0.4952
```

With just `total_bill` as the feature and this particular split, the model explains about 0.50 of the variation in tips. The exact value depends on the split, which is why fixing `random_state` matters for getting repeatable numbers.

---

## Next Up - Lesson 6

You now know the workflow that powers all of supervised machine learning: build `X` and `y`, split into train and test, `fit` the model, `predict` on unseen data, and `score` the result. This single pattern carries you through every model in the course.

In Lesson 6, you will build your first real model with intent: a linear regression that predicts California house prices. You will go deeper into what the model actually learned by inspecting its coefficients, and you will start interpreting its predictions in the language of the problem.
