## 1. Before You Begin

You have trained regression and classification models and glanced at their scores. Now you will learn to measure them properly. This matters more than it sounds, because the wrong metric can make a useless model look great. The classic trap: a model that predicts "no disease" for everyone can be 95 percent accurate while catching zero actual patients.

In this lesson you will learn the standard metrics for both kinds of model, what each one really measures, and, most importantly, when to trust which. By the end you will be able to look at a model and say not just "is it good" but "is it good for this problem".

### What You'll Build

A notebook that computes the three core regression metrics (MAE, RMSE, R2) on the housing model, then the core classification metrics (accuracy, precision, recall, f1, and the confusion matrix) on a deliberately imbalanced example that exposes why accuracy alone can lie.

### What You'll Learn

- ✅ The three main regression metrics and what each tells you
- ✅ Why accuracy can be dangerously misleading
- ✅ How to read a confusion matrix in terms of errors
- ✅ What precision and recall measure, and the trade-off between them
- ✅ How the f1-score balances precision and recall
- ✅ How to choose the right metric for a problem

### What You'll Need

- Models from Modules 3 and 4 (you will rebuild a quick one here)
- A Colab notebook with scikit-learn and NumPy
- The confusion matrix idea introduced in Lesson 7

---

## 2. Why Metrics Matter

A metric is how you turn "the model did okay" into a number you can compare and improve. But every metric measures one specific thing, and optimizing the wrong one leads you astray. Choosing the metric is a decision about what kind of mistake you care about most.

Two principles guide everything in this lesson:

- **Match the metric to the task.** Regression and classification need completely different metrics. You never use R2 on a classifier or accuracy on a regressor.
- **Match the metric to the cost of mistakes.** Missing a cancer diagnosis and flagging a healthy patient are both errors, but they are not equally bad. The metric you optimize should reflect which error hurts more.

With those in mind, let us look at regression metrics first, then the richer world of classification metrics.

---

## 3. Evaluating Regression Models

Regression predicts numbers, so its metrics measure how far the predictions are from the true values. Let us rebuild the housing model and compute all three.

### Step 1: Train a model to evaluate

```python
from sklearn.datasets import fetch_california_housing
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression

df = fetch_california_housing(as_frame=True).frame
X = df.drop(columns="MedHouseVal")
y = df["MedHouseVal"]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)
model = LinearRegression().fit(X_train, y_train)
predictions = model.predict(X_test)
```

This is the same eight-feature housing model from Lesson 6. Now we will measure its predictions three ways.

### Step 2: Mean Absolute Error (MAE)

```python
from sklearn.metrics import mean_absolute_error

print("MAE:", round(mean_absolute_error(y_test, predictions), 4))
```

Output:

```
MAE: 0.5332
```

MAE is the average size of the errors, ignoring whether they are over or under. Because the target is in hundreds of thousands of dollars, an MAE of 0.5332 means the model is off by about 53,000 dollars on average. MAE is the most intuitive metric: it is in the same units as what you predict, and every error counts equally.

### Step 3: Root Mean Squared Error (RMSE)

```python
from sklearn.metrics import root_mean_squared_error

print("RMSE:", round(root_mean_squared_error(y_test, predictions), 4))
```

Output:

```
RMSE: 0.7456
```

RMSE also measures average error in the same units, but it squares each error before averaging, which punishes large mistakes much more than small ones. Notice RMSE (0.7456) is bigger than MAE (0.5332); that gap is a sign that a few predictions are badly off. Use RMSE when big errors are especially costly and you want them to dominate the score.

### Step 4: R squared (R2)

```python
from sklearn.metrics import r2_score

print("R2:", round(r2_score(y_test, predictions), 4))
```

Output:

```
R2: 0.5758
```

R2 answers a different question: what fraction of the variation in the target does the model explain? It ranges up to 1.0, where 1.0 is perfect and 0 means the model is no better than always guessing the average. An R2 of 0.58 means the model explains 58 percent of the variation. Unlike MAE and RMSE, R2 has no units, which makes it good for comparing across different problems but less intuitive on its own. Use all three together: MAE and RMSE for the real-world error size, R2 for the proportion explained.

---

## 4. Evaluating Classification Models

Classification metrics are richer because there are different kinds of mistakes. To see why a single number is not enough, we will use a deliberately imbalanced example: a rare disease that only 5 out of 100 people have.

### Step 1: See how accuracy can lie

```python
import numpy as np
from sklearn.metrics import accuracy_score, recall_score, precision_score

# 95 healthy people (0) and 5 sick people (1)
y_true = np.array([0] * 95 + [1] * 5)

# A lazy model that predicts "healthy" for everyone
y_pred_lazy = np.array([0] * 100)

print("accuracy:", round(accuracy_score(y_true, y_pred_lazy), 4))
print("recall:", round(recall_score(y_true, y_pred_lazy, zero_division=0), 4))
print("precision:", round(precision_score(y_true, y_pred_lazy, zero_division=0), 4))
```

Output:

```
accuracy: 0.95
recall: 0.0
precision: 0.0
```

This is the trap. A model that always says "healthy" is 95 percent accurate, because 95 percent of people really are healthy. But it catches zero of the 5 sick patients, so its recall is 0. The high accuracy is worthless here. Whenever your classes are imbalanced, accuracy alone is dangerously misleading, and you need precision and recall.

### Step 2: Read the confusion matrix

Let us look at a real model that catches 4 of the 5 sick patients but raises 3 false alarms:

```python
from sklearn.metrics import confusion_matrix

# 92 correct healthy, 3 false alarms, 4 sick caught, 1 sick missed
y_pred = np.array([0] * 92 + [1] * 3 + [1] * 4 + [0] * 1)

print(confusion_matrix(y_true, y_pred))
```

Output:

```
[[92  3]
 [ 1  4]]
```

The confusion matrix lays out every outcome. Rows are the truth (healthy, then sick) and columns are the prediction. Reading it: 92 healthy people correctly cleared (true negatives), 3 healthy people wrongly flagged (false positives), 1 sick person missed (false negative), and 4 sick people correctly caught (true positives). Every classification metric is computed from these four numbers.

### Step 3: Precision and recall

```python
print("precision:", round(precision_score(y_true, y_pred), 4))
print("recall:", round(recall_score(y_true, y_pred), 4))
```

Output:

```
precision: 0.5714
recall: 0.8
```

These two answer different questions. Recall asks: of the people who are truly sick, how many did we catch? Here 4 of 5, so 0.8. Precision asks: of the people we flagged as sick, how many really were? Here 4 of 7, so 0.5714. A test can be high in one and low in the other, which is why you almost always report both.

### Step 4: The f1-score

```python
from sklearn.metrics import f1_score

print("f1:", round(f1_score(y_true, y_pred), 4))
```

Output:

```
f1: 0.6667
```

The f1-score combines precision and recall into one number using their harmonic mean, which stays low unless both are reasonably high. It is the go-to single metric for imbalanced classification, because unlike accuracy it cannot be fooled by ignoring the rare class. Our f1 of 0.67 reflects decent recall held back by modest precision.

---

## 5. Precision vs Recall: Which to Optimize

Precision and recall pull against each other. If you flag more people as sick, you catch more real cases (higher recall) but also raise more false alarms (lower precision), and vice versa. Which one you favor depends entirely on the cost of each mistake.

Think about the two failure modes:

- **Favor recall when missing a positive is dangerous.** For a cancer screening or fraud detection, missing a real case is far worse than a false alarm. You accept more false positives to catch as many true cases as possible.
- **Favor precision when a false alarm is costly.** For a spam filter, wrongly sending an important email to the spam folder is worse than letting one spam through. You want to be sure before you flag something.

There is no universal answer; the right balance is a business and ethical decision, not a math one. The f1-score is a sensible default when you have no strong preference. The key skill is to ask, before you even train a model, which error you care about most, and then choose your metric to match. In the next course you will even learn to adjust the decision threshold to dial precision and recall up or down.

---

## 6. Fix the Errors in Your Code

These mistakes lead to misleading evaluations.

**Mistake 1: Trusting accuracy on imbalanced data.**

```python
# Wrong: accuracy looks great but hides total failure on the rare class
accuracy_score(y_true, y_pred_lazy)   # 0.95, yet recall is 0
```

```python
# Correct: report precision, recall, and f1 for imbalanced problems
precision_score(y_true, y_pred)
recall_score(y_true, y_pred)
f1_score(y_true, y_pred)
```

When one class is rare, always look beyond accuracy to precision, recall, and f1.

**Mistake 2: Swapping the argument order in a metric.**

```python
# Wrong: metrics expect (y_true, y_pred); reversing can flip precision and recall
precision_score(y_pred, y_true)
```

```python
# Correct: true labels first, predictions second
precision_score(y_true, y_pred)
```

scikit-learn metrics take the true labels first and the predictions second. Reversing them silently gives wrong numbers.

**Mistake 3: Using a classification metric on a regressor (or the reverse).**

```python
# Wrong: accuracy is meaningless for continuous predictions
accuracy_score(y_test, model.predict(X_test))   # housing prices
```

```python
# Correct: use regression metrics for regression
mean_absolute_error(y_test, model.predict(X_test))
r2_score(y_test, model.predict(X_test))
```

Continuous predictions almost never match a target exactly, so accuracy would be near zero and meaningless. Match the metric family to the task.

---

## 7. Exercises

**Exercise 1:** Train a single-feature regression model on the housing data using only `MedInc` (20 percent test set, `random_state=42`). Print its MAE, RMSE, and R2. How do they compare to the full eight-feature model?

**Exercise 2:** Given the true labels `[1,0,1,1,0,1,0,0,1,1]` and predictions `[1,0,0,1,0,1,1,0,1,0]`, print the confusion matrix and the precision, recall, and f1-score.

**Exercise 3:** For each scenario, decide whether you would prioritize precision or recall, and explain why in a comment: (a) a model that screens for a serious contagious disease, (b) a filter that auto-deletes emails it thinks are spam.

---

## 8. Solutions

**Solution for Exercise 1:**

```python
from sklearn.datasets import fetch_california_housing
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error, root_mean_squared_error, r2_score

df = fetch_california_housing(as_frame=True).frame
X = df[["MedInc"]]
y = df["MedHouseVal"]
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)
model = LinearRegression().fit(X_train, y_train)
pred = model.predict(X_test)

print("MAE:", round(mean_absolute_error(y_test, pred), 4))
print("RMSE:", round(root_mean_squared_error(y_test, pred), 4))
print("R2:", round(r2_score(y_test, pred), 4))
```

Output:

```
MAE: 0.6299
RMSE: 0.8421
R2: 0.4589
```

With only income as a feature, every metric is worse than the full model: MAE rises from 0.53 to 0.63, RMSE from 0.75 to 0.84, and R2 drops from 0.58 to 0.46. Fewer features means less information, and the metrics agree on that.

**Solution for Exercise 2:**

```python
import numpy as np
from sklearn.metrics import confusion_matrix, precision_score, recall_score, f1_score

y_true = np.array([1, 0, 1, 1, 0, 1, 0, 0, 1, 1])
y_pred = np.array([1, 0, 0, 1, 0, 1, 1, 0, 1, 0])

print(confusion_matrix(y_true, y_pred))
print("precision:", round(precision_score(y_true, y_pred), 4))
print("recall:", round(recall_score(y_true, y_pred), 4))
print("f1:", round(f1_score(y_true, y_pred), 4))
```

Output:

```
[[3 1]
 [2 4]]
precision: 0.8
recall: 0.6667
f1: 0.7273
```

The confusion matrix shows 3 true negatives, 1 false positive, 2 false negatives, and 4 true positives. Precision is 4 of 5 flagged (0.8) and recall is 4 of 6 actual positives (0.6667), giving an f1 of 0.7273. Here precision beats recall, meaning the model misses some positives but rarely raises a false alarm.

**Solution for Exercise 3:**

```python
# (a) Serious contagious disease: prioritize RECALL.
#     Missing a sick person (false negative) could spread the disease,
#     which is far worse than a false alarm that leads to a follow-up test.

# (b) Auto-deleting spam filter: prioritize PRECISION.
#     Deleting a real, important email (false positive) is very costly,
#     so be highly confident before flagging something as spam.
```

There is no code output here; the point is the reasoning. Scenario (a) makes false negatives the dangerous error, so you maximize recall. Scenario (b) makes false positives the dangerous error, so you maximize precision. Always start by asking which mistake hurts more.

---

## Next Up - Lesson 10

You can now measure models honestly. For regression you have MAE, RMSE, and R2, and for classification you have the confusion matrix, precision, recall, and f1, plus the judgment to know when accuracy lies and which error to prioritize. Trustworthy metrics are what make every model comparison meaningful.

In Lesson 10, you will tackle the central challenge that metrics help you detect: overfitting and underfitting. You will see how a model can ace the training data yet fail on new data, learn to recognize the warning signs by comparing training and test scores, and understand the bias-variance trade-off at the heart of machine learning.
