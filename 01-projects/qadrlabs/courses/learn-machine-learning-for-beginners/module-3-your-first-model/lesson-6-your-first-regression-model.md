## 1. Before You Begin

In Lesson 5 you learned the workflow that every supervised model follows. Now you will apply it with intent to build your first real regression model: one that predicts California house prices. Regression means predicting a number on a continuous scale, and house price is the classic example.

This time you will not just train and predict. You will interpret the model, looking at what it actually learned about how each feature pushes the price up or down. Understanding a model, not just running it, is the skill that turns you from someone who copies code into someone who does machine learning.

### What You'll Build

A notebook that loads the California Housing dataset, trains a linear regression model to predict the median house value of a district from features like median income and house age, evaluates it, inspects its learned coefficients, and predicts the value of a new district you describe.

### What You'll Learn

- ✅ What the California Housing dataset contains and what you are predicting
- ✅ How to build a regression model with all features at once
- ✅ How to evaluate a regression model with R2 and MAE
- ✅ How to read a model's coefficients to understand what it learned
- ✅ How to predict the price of a brand new example
- ✅ Why feature scales make raw coefficients tricky to compare

### What You'll Need

- The workflow from Lesson 5 (`X`/`y`, split, `fit`, `predict`)
- A Colab notebook with scikit-learn and pandas
- Curiosity about why a model predicts what it does

---

## 2. Meet the California Housing Dataset

Before modeling, you always get to know your data. The California Housing dataset is built into scikit-learn, so there is nothing to download. Each row describes a district (a block group) in California, not a single house.

```python
import pandas as pd
from sklearn.datasets import fetch_california_housing

housing = fetch_california_housing(as_frame=True)
df = housing.frame

print(df.shape)
print(df.columns.tolist())
```

Output:

```
(20640, 9)
['MedInc', 'HouseAge', 'AveRooms', 'AveBedrms', 'Population', 'AveOccup', 'Latitude', 'Longitude', 'MedHouseVal']
```

`fetch_california_housing(as_frame=True)` returns the data, and `housing.frame` gives the full DataFrame. There are 20,640 districts and 9 columns. Eight are features and one, `MedHouseVal`, is the target you will predict.

A quick look at a few columns and the target:

```python
df[["MedInc", "HouseAge", "AveRooms", "MedHouseVal"]].head()
```

Output:

```
   MedInc  HouseAge  AveRooms  MedHouseVal
0  8.3252      41.0  6.984127        4.526
1  8.3014      21.0  6.238137        3.585
2  7.2574      52.0  8.288136        3.521
3  5.6431      52.0  5.817352        3.413
4  3.8462      52.0  6.281853        3.422
```

The important detail is units. `MedInc` is median income in tens of thousands of dollars, so 8.3252 means about 83,252 dollars. The target `MedHouseVal` is the median house value in hundreds of thousands of dollars, so 4.526 means about 452,600 dollars. Knowing the units lets you sanity check every prediction later.

---

## 3. Prepare Features and Target

With the data understood, apply the workflow. The target is `MedHouseVal`, and the features are every other column.

### Step 1: Build X and y

```python
X = df.drop(columns=["MedHouseVal"])
y = df["MedHouseVal"]

print("X shape:", X.shape)
print("y shape:", y.shape)
```

Output:

```
X shape: (20640, 8)
y shape: (20640,)
```

`df.drop(columns=["MedHouseVal"])` returns the DataFrame without the target column, giving you all 8 features in `X`. `y` is the single target column. Using `drop` is a clean way to say "everything except the target" without listing all eight feature names by hand.

### Step 2: Split into train and test

```python
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)
print("train:", X_train.shape, "test:", X_test.shape)
```

Output:

```
train: (16512, 8) test: (4128, 8)
```

The same `train_test_split` from Lesson 5: 80 percent of the 20,640 districts go to training (16,512) and 20 percent to the test set (4,128). The `random_state=42` keeps the split reproducible.

---

## 4. Train the Linear Regression Model

Linear regression finds the straight-line relationship that best predicts the target from the features. In plain terms, it learns a weight for each feature and adds them up.

### Step 1: Create and train the model

```python
from sklearn.linear_model import LinearRegression

model = LinearRegression()
model.fit(X_train, y_train)
```

`LinearRegression()` creates the untrained model and `model.fit(X_train, y_train)` trains it on the training data. Behind that one line, the model searches for the set of weights that makes its predictions as close as possible to the real prices in the training set. After `fit`, the model is ready.

The idea under the hood is simple: the model computes a prediction as `intercept + w1 * MedInc + w2 * HouseAge + ...`, where each `w` is a weight (called a coefficient) it learned. You will inspect those weights shortly.

---

## 5. Evaluate the Predictions

A trained model is only useful if it predicts well on data it has not seen. You measure that on the test set with two common regression metrics.

### Step 1: Check R2 with score

```python
print("R2 on test:", round(model.score(X_test, y_test), 4))
```

Output:

```
R2 on test: 0.5758
```

For regression, `score` returns R2, which ranges up to 1.0. A 0.58 means the model explains about 58 percent of the variation in house values across districts. That is decent for such a simple model on real-world data, and it leaves clear room to improve with better models later.

### Step 2: Check the average error with MAE

R2 is a relative score. To know the error in real dollars, use Mean Absolute Error:

```python
from sklearn.metrics import mean_absolute_error

predictions = model.predict(X_test)
print("MAE:", round(mean_absolute_error(y_test, predictions), 4))
```

Output:

```
MAE: 0.5332
```

`mean_absolute_error` computes the average size of the prediction errors, ignoring their direction. Because the target is in hundreds of thousands of dollars, an MAE of 0.5332 means the model is off by about 53,000 dollars on average. That concrete number is often more meaningful to people than R2.

### Step 3: Compare a few predictions

```python
print("first 5 pred:", predictions[:5].round(3))
print("first 5 true:", y_test[:5].values.round(3))
```

Output:

```
first 5 pred: [0.719 1.764 2.71  2.839 2.605]
first 5 true: [0.477 0.458 5.    2.186 2.78 ]
```

Some predictions land close, like 2.605 versus 2.78, and some miss badly, like 2.71 versus 5.0. Seeing individual errors reminds you that an average metric hides a range of good and bad predictions, which is exactly why you will study evaluation more carefully in Lesson 9.

---

## 6. Understand What the Model Learned

This is what sets a thoughtful practitioner apart. A linear model is interpretable: each feature has a coefficient telling you how it affects the prediction. Inspecting them turns the model from a black box into an explanation.

```python
coefficients = pd.Series(model.coef_, index=X.columns).round(4)
print(coefficients)
print("intercept:", round(model.intercept_, 4))
```

Output:

```
MedInc        0.4487
HouseAge      0.0097
AveRooms     -0.1233
AveBedrms     0.7831
Population   -0.0000
AveOccup     -0.0035
Latitude     -0.4198
Longitude    -0.4337
intercept: -37.0233
```

`model.coef_` is the list of learned weights, one per feature, and pairing it with `X.columns` in a Series labels each one. A positive coefficient pushes the predicted value up as that feature grows; a negative one pushes it down. Reading the biggest effects: `MedInc` has a strong positive coefficient, so richer districts predict higher house values, which matches intuition. `Latitude` and `Longitude` are negative, capturing that location (moving north and east, away from the expensive coast) lowers predicted value.

One important caution: these coefficients are not directly comparable because the features are on different scales. `MedInc` ranges into the tens while `Population` ranges into the thousands, so a small coefficient on `Population` can still represent a real effect. This is exactly why scaling features matters, a technique you will learn in Lesson 12. For now, the takeaway is that you can open up a linear model and read what it learned.

---

## 7. Predict the Value of a New District

The point of a model is to use it. Let us describe a brand new district and ask the model for its predicted median house value.

### Step 1: Build a new example

```python
new_district = pd.DataFrame([{
    "MedInc": 8.0, "HouseAge": 20, "AveRooms": 6.0, "AveBedrms": 1.0,
    "Population": 1000, "AveOccup": 3.0, "Latitude": 34.0, "Longitude": -118.0
}])
```

You build a one-row DataFrame that includes every feature the model was trained on, with realistic values. This describes a fairly well-off district (median income around 80,000 dollars) near Los Angeles.

### Step 2: Predict

```python
prediction = model.predict(new_district)
print("predicted MedHouseVal:", prediction.round(3))
```

Output:

```
predicted MedHouseVal: [3.696]
```

The model predicts about 3.696, which means roughly 369,600 dollars. Because you know the units, you can judge whether that is reasonable, and for a comfortable district near LA it certainly is. This is the full payoff of the workflow: a model that turns district features into a dollar estimate.

---

## 8. Fix the Errors in Your Code

These mistakes are common when building a regression model. Learn to spot them.

**Mistake 1: Leaving the target inside the features.**

```python
# Wrong: MedHouseVal is still in X, so the model "cheats" by seeing the answer
X = df
y = df["MedHouseVal"]
```

```python
# Correct: drop the target from the features
X = df.drop(columns=["MedHouseVal"])
y = df["MedHouseVal"]
```

If the target is in `X`, the model gets the answer as an input and reports an unrealistically perfect score. Always remove the target from the features.

**Mistake 2: Giving predict a new example with missing or mismatched columns.**

```python
# Wrong: only two features, but the model was trained on eight
new = pd.DataFrame([{"MedInc": 8.0, "HouseAge": 20}])
model.predict(new)
```

```python
# Correct: include every feature the model was trained on
new = pd.DataFrame([{
    "MedInc": 8.0, "HouseAge": 20, "AveRooms": 6.0, "AveBedrms": 1.0,
    "Population": 1000, "AveOccup": 3.0, "Latitude": 34.0, "Longitude": -118.0
}])
model.predict(new)
```

A model expects new data to have exactly the same feature columns it was trained on, in the same meaning. Missing columns cause an error.

**Mistake 3: Judging the model on the training score.**

```python
# Wrong: scoring on training data overstates how good the model is
model.score(X_train, y_train)
```

```python
# Correct: always judge on the held-out test set
model.score(X_test, y_test)
```

The training score reflects data the model already saw. Only the test score tells you how it performs on new data.

---

## 9. Exercises

**Exercise 1:** Load the California Housing dataset and print the correlation between `MedInc` and `MedHouseVal`. Does income relate strongly to house value?

**Exercise 2:** Build a model that uses only `MedInc` as the feature to predict `MedHouseVal`. Use a 20 percent test set with `random_state=42` and print the test R2.

**Exercise 3:** Using your single-feature model from Exercise 2, predict the median house value for a district with `MedInc` of 3.0 and for one with `MedInc` of 9.0. How much does the prediction change?

---

## 10. Solutions

**Solution for Exercise 1:**

```python
import pandas as pd
from sklearn.datasets import fetch_california_housing

df = fetch_california_housing(as_frame=True).frame
print("correlation:", round(df["MedInc"].corr(df["MedHouseVal"]), 4))
```

Output:

```
correlation: 0.6881
```

A correlation of about 0.69 is a fairly strong positive relationship: districts with higher median income tend to have higher house values. That is why `MedInc` ends up being the most influential single feature.

**Solution for Exercise 2:**

```python
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression

X = df[["MedInc"]]
y = df["MedHouseVal"]
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)
model = LinearRegression()
model.fit(X_train, y_train)
print("R2 on test:", round(model.score(X_test, y_test), 4))
```

Output:

```
R2 on test: 0.4589
```

With income as the only feature, the model explains about 46 percent of the variation. That single feature alone gets you most of the way to the 0.58 from the full eight-feature model, which confirms how dominant income is.

**Solution for Exercise 3:**

```python
print("MedInc=3:", model.predict(pd.DataFrame({"MedInc": [3.0]})).round(3))
print("MedInc=9:", model.predict(pd.DataFrame({"MedInc": [9.0]})).round(3))
```

Output:

```
MedInc=3: [1.703]
MedInc=9: [4.219]
```

Tripling the income from 3.0 to 9.0 raises the predicted value from about 1.703 to 4.219, that is from roughly 170,000 to 422,000 dollars. The jump reflects the model's positive income coefficient: more income, higher predicted value.

---

## Next Up - Lesson 7

You built and interpreted your first real regression model. You predicted a continuous number (house value), measured it with R2 and MAE, read the coefficients to understand what the model learned, and used it on a new district. That is a complete regression project end to end.

In Lesson 7, you switch from predicting numbers to predicting categories. You will build a classification model with logistic regression on the Iris dataset, learning how the same `fit` and `predict` workflow applies, and how classification is measured differently from regression.
