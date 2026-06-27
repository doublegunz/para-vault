## 1. Before You Begin

So far you predicted numbers: house prices and tip amounts. That is regression. In this lesson you switch to the other big family of supervised learning: classification, where you predict a category instead of a number. Is this email spam or not? Which species is this flower? These are classification problems.

The wonderful news is that the workflow does not change. You still build `X` and `y`, split, `fit`, and `predict`. What changes is the model you choose and how you measure success. You will use logistic regression, the classic starting point for classification, on the famous Iris flower dataset.

### What You'll Build

A notebook that trains a logistic regression classifier to identify the species of an iris flower from four measurements, evaluates it with accuracy and a confusion matrix, and predicts the species of a new flower along with how confident the model is.

### What You'll Learn

- ✅ The difference between classification and regression
- ✅ How logistic regression predicts categories
- ✅ How to train a classifier with the same `fit` and `predict` workflow
- ✅ How to measure a classifier with accuracy and a confusion matrix
- ✅ How to read a classification report (precision, recall, f1)
- ✅ How to get prediction probabilities with `predict_proba`

### What You'll Need

- The workflow from Module 3 (`X`/`y`, split, `fit`, `predict`)
- A Colab notebook with scikit-learn and pandas
- No new installations, since Iris ships with scikit-learn

---

## 2. Classification vs Regression

Both classification and regression are supervised learning, so they share the same workflow, but they answer different kinds of questions. Knowing which one you face tells you which models and metrics to use.

- **Regression** predicts a number on a continuous scale: a price, a temperature, a tip. The answer can be any value in a range.
- **Classification** predicts a category from a fixed set: spam or not spam, one of three flower species, pass or fail. The answer is a label from a known list.

A quick test: if it makes sense to ask "how much" or "how many", it is regression. If it makes sense to ask "which one" or "is it this or that", it is classification. When there are exactly two categories it is called binary classification; with three or more it is multiclass classification. Iris has three species, so this lesson is multiclass.

Despite the name, **logistic regression is a classification model**, not a regression one. The name is historical. It works by estimating the probability that an example belongs to each class and then picking the most likely one.

---

## 3. Meet the Iris Dataset

Iris is the "hello world" of classification: small, clean, and famous. Each row is a flower with four measurements, and the goal is to predict its species.

```python
from sklearn.datasets import load_iris

iris = load_iris(as_frame=True)
df = iris.frame

print(df.shape)
print(iris.target_names)
df.head()
```

Output:

```
(150, 5)
['setosa' 'versicolor' 'virginica']
```

`load_iris(as_frame=True)` loads the dataset, `iris.frame` is the full DataFrame, and `iris.target_names` lists the three species. There are 150 flowers and 5 columns: four measurement features (sepal length, sepal width, petal length, petal width) and a `target` column holding the species as a number, where 0 is setosa, 1 is versicolor, and 2 is virginica.

Check that the classes are balanced:

```python
df["target"].value_counts().sort_index()
```

Output:

```
target
0    50
1    50
2    50
Name: count, dtype: int64
```

There are exactly 50 flowers of each species. A balanced dataset like this makes accuracy a trustworthy metric, which is not always the case, as you will see in the next course.

---

## 4. Prepare the Data

Apply the familiar workflow. The features are the four measurements, and the target is the species.

### Step 1: Build X and y

```python
X = iris.data
y = iris.target

print("X shape:", X.shape)
print("y shape:", y.shape)
```

Output:

```
X shape: (150, 4)
y shape: (150,)
```

`iris.data` is a DataFrame of the four measurement columns, and `iris.target` is the species label for each flower. This is the same `X` (features) and `y` (target) split you have used all along.

### Step 2: Split into train and test

```python
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
print("train:", X_train.shape, "test:", X_test.shape)
```

Output:

```
train: (120, 4) test: (30, 4)
```

This is `train_test_split` with one new argument: `stratify=y`. For classification, `stratify=y` makes the split keep the same proportion of each class in both the train and test sets. Without it, you might by chance get too few of one species in the test set. For classification, stratifying is a good habit.

---

## 5. Train the Logistic Regression Classifier

Creating and training a classifier uses the exact same two lines as regression. Only the model class is different.

```python
from sklearn.linear_model import LogisticRegression

model = LogisticRegression(max_iter=200)
model.fit(X_train, y_train)
```

`LogisticRegression(max_iter=200)` creates the classifier. The `max_iter=200` raises the number of training iterations from the default so the model has enough steps to settle on a good answer; without it you may see a warning that it did not finish converging. `model.fit(X_train, y_train)` trains it. Under the hood, the model learns how the four measurements separate the three species, but the code you write is identical to the regression workflow.

---

## 6. Evaluate the Classifier

Classification is not measured with R2. The most basic metric is accuracy: the fraction of test flowers the model labeled correctly.

### Step 1: Measure accuracy

```python
from sklearn.metrics import accuracy_score

predictions = model.predict(X_test)
print("accuracy:", round(accuracy_score(y_test, predictions), 4))
```

Output:

```
accuracy: 0.9667
```

`model.predict(X_test)` returns a predicted species for each test flower, and `accuracy_score` compares those predictions to the true species. An accuracy of 0.9667 means the model got about 97 percent of the 30 test flowers right, which is 29 out of 30.

### Step 2: Read the confusion matrix

Accuracy is one number, but a confusion matrix shows exactly where the mistakes happened:

```python
from sklearn.metrics import confusion_matrix

print(confusion_matrix(y_test, predictions))
```

Output:

```
[[10  0  0]
 [ 0  9  1]
 [ 0  0 10]]
```

Each row is the true species and each column is the predicted species, in order setosa, versicolor, virginica. The diagonal counts correct predictions: 10 setosa, 9 versicolor, and 10 virginica classified correctly. The single off-diagonal `1` in the middle row means one versicolor flower was mistakenly predicted as virginica. A confusion matrix tells you not just how many errors there were, but which classes the model confuses.

### Step 3: Read the classification report

For a richer view, the classification report breaks the score down per class:

```python
from sklearn.metrics import classification_report

print(classification_report(y_test, predictions, target_names=iris.target_names))
```

Output:

```
              precision    recall  f1-score   support

      setosa       1.00      1.00      1.00        10
  versicolor       1.00      0.90      0.95        10
   virginica       0.91      1.00      0.95        10

    accuracy                           0.97        30
   macro avg       0.97      0.97      0.97        30
weighted avg       0.97      0.97      0.97        30
```

This report gives three metrics per class. Precision asks "of the flowers predicted as this species, how many were right". Recall asks "of the flowers that truly are this species, how many did we catch". The f1-score blends the two. The `support` is how many test flowers belong to each class. Setosa is perfectly classified, while versicolor and virginica each have one small error, which matches the confusion matrix. You will study these metrics in depth in Lesson 9; for now, notice how much more they tell you than a single accuracy number.

---

## 7. Predict a New Flower

The reward for training a classifier is labeling new examples. Describe a new flower and ask the model what it is.

### Step 1: Predict the species

```python
import pandas as pd

new_flower = pd.DataFrame([{
    "sepal length (cm)": 5.1, "sepal width (cm)": 3.5,
    "petal length (cm)": 1.4, "petal width (cm)": 0.2
}])

predicted_class = model.predict(new_flower)
print("predicted class:", predicted_class)
print("predicted name:", iris.target_names[predicted_class[0]])
```

Output:

```
predicted class: [0]
predicted name: setosa
```

You build a one-row DataFrame with the four measurement columns, then `predict` returns the class number `0`, and indexing `iris.target_names` with it turns `0` into the readable label `setosa`. Converting the number back to a name is what makes the prediction useful to a human.

### Step 2: See the prediction probabilities

Classifiers can also tell you how confident they are:

```python
print("probabilities:", model.predict_proba(new_flower).round(3))
```

Output:

```
probabilities: [[0.978 0.022 0.   ]]
```

`predict_proba` returns the probability the flower belongs to each class, in order setosa, versicolor, virginica. Here the model is 97.8 percent sure it is setosa and assigns almost nothing to the others, so it is very confident. `predict` simply picks the class with the highest probability. Knowing the confidence, not just the label, is valuable when a wrong answer is costly.

---

## 8. Fix the Errors in Your Code

These mistakes catch beginners moving from regression to classification.

**Mistake 1: Using a regression metric on a classifier.**

```python
# Wrong: R2 is for regression, not classification
from sklearn.metrics import r2_score
r2_score(y_test, predictions)
```

```python
# Correct: use accuracy (or other classification metrics)
from sklearn.metrics import accuracy_score
accuracy_score(y_test, predictions)
```

Match the metric to the task. Accuracy, precision, recall, and f1 are for classification; R2 and MAE are for regression.

**Mistake 2: Ignoring the convergence warning.**

```python
# Wrong: default iterations may be too few, causing a ConvergenceWarning
model = LogisticRegression()
```

```python
# Correct: give it more iterations so training finishes
model = LogisticRegression(max_iter=200)
```

If you see a warning that the model failed to converge, raising `max_iter` usually fixes it. It means the training needed more steps to settle.

**Mistake 3: Forgetting to convert the predicted number to a label.**

```python
# Confusing: this prints a bare number with no meaning to a reader
print(model.predict(new_flower))   # [0]
```

```python
# Clear: map the number back to its class name
pred = model.predict(new_flower)[0]
print(iris.target_names[pred])     # setosa
```

The model predicts class numbers. Translating them back to names with `target_names` makes the output meaningful.

---

## 9. Exercises

**Exercise 1:** Load the Iris dataset and train a logistic regression model using only the two petal features (`petal length (cm)` and `petal width (cm)`). Use a 20 percent stratified test set with `random_state=42` and print the accuracy.

**Exercise 2:** Print the confusion matrix for your two-feature model from Exercise 1. Did using fewer features change the errors?

**Exercise 3:** Using your two-feature model, predict the species of a flower with petal length 5.0 and petal width 1.8, and print both the predicted name and the probabilities.

---

## 10. Solutions

**Solution for Exercise 1:**

```python
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score

iris = load_iris(as_frame=True)
X = iris.data[["petal length (cm)", "petal width (cm)"]]
y = iris.target

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
model = LogisticRegression(max_iter=200)
model.fit(X_train, y_train)
print("accuracy:", round(accuracy_score(y_test, model.predict(X_test)), 4))
```

Output:

```
accuracy: 0.9667
```

Using only the two petal measurements gives the same 0.9667 accuracy as all four features. The petal measurements carry most of the information needed to tell the species apart, which is a useful real-world insight: more features are not always necessary.

**Solution for Exercise 2:**

```python
from sklearn.metrics import confusion_matrix
print(confusion_matrix(y_test, model.predict(X_test)))
```

Output:

```
[[10  0  0]
 [ 0  9  1]
 [ 0  0 10]]
```

The confusion matrix is identical to the four-feature model: the only error is one versicolor predicted as virginica. The two species that look most alike are the ones the model occasionally confuses, regardless of how many features it uses.

**Solution for Exercise 3:**

```python
import pandas as pd

new_flower = pd.DataFrame([{
    "petal length (cm)": 5.0, "petal width (cm)": 1.8
}])
pred = model.predict(new_flower)[0]
print("predicted name:", iris.target_names[pred])
print("probabilities:", model.predict_proba(new_flower).round(3))
```

Output:

```
predicted name: virginica
probabilities: [[0.001 0.338 0.661]]
```

The model predicts virginica with about 66 percent confidence, giving versicolor a notable 34 percent and setosa essentially zero. A petal that long and wide leans virginica, but because these measurements sit near the versicolor and virginica boundary, the model is only moderately sure rather than confident.

---

## Next Up - Lesson 8

You built your first classifier, measured it with accuracy and a confusion matrix, read a classification report, and predicted a new flower with a confidence score. Classification uses the same workflow as regression but a different model and different metrics.

In Lesson 8, you will meet two more classifiers that think very differently from logistic regression: decision trees, which learn a flowchart of yes-or-no questions, and k-nearest neighbors, which classifies by looking at the most similar examples. You will compare all three side by side and start to develop intuition for choosing a model.
