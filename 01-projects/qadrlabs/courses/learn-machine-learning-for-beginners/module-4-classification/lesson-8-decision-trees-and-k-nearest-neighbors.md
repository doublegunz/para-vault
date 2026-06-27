## 1. Before You Begin

In Lesson 7 you classified iris flowers with logistic regression. It works well, but it is only one way to think about classification. In this lesson you meet two more classifiers that reason completely differently, and you compare all three on the same data. Seeing different models solve the same problem is how you start to build intuition for which one to reach for.

Decision trees learn a flowchart of yes-or-no questions. K-nearest neighbors classifies a new example by looking at the most similar examples it has already seen. Neither uses the math of logistic regression, yet both plug into the exact same `fit` and `predict` workflow. That consistency is the superpower of scikit-learn.

### What You'll Build

A notebook that trains a decision tree and a k-nearest neighbors classifier on the Iris dataset, inspects what the tree learned by printing its rules, tries different settings for k, and compares all three classifiers (logistic regression, tree, and KNN) side by side on the same test set.

### What You'll Learn

- ✅ How a decision tree classifies with yes-or-no questions
- ✅ How to read a tree's rules and feature importances
- ✅ How k-nearest neighbors classifies by similarity
- ✅ How the choice of k changes KNN's behavior
- ✅ How to compare several models fairly on the same split
- ✅ The trade-offs that help you choose a model

### What You'll Need

- The classification workflow from Lesson 7
- A Colab notebook with scikit-learn and pandas
- The Iris dataset (built into scikit-learn)

---

## 2. Two New Ways to Classify

Different models make different assumptions about how to separate classes. Understanding the core idea of each one matters more than the math, because the idea is what tells you when a model fits a problem.

**Decision trees** ask a sequence of yes-or-no questions about the features, like a game of twenty questions. "Is the petal shorter than 2.45 cm? If yes, it is setosa. If no, is the petal width below 1.65 cm?" and so on. Each question splits the data into purer groups until it can confidently assign a class. Trees are easy to interpret because you can read the questions directly.

**K-nearest neighbors (KNN)** does almost no work during training. To classify a new flower, it finds the `k` most similar flowers in the training data (its nearest neighbors) and lets them vote. If 4 of the 5 nearest flowers are versicolor, it predicts versicolor. The idea is that similar inputs tend to have similar labels.

Both are supervised classifiers, so they use the same workflow as logistic regression. Let us train each one and see how it behaves.

---

## 3. Set Up the Data

Start from the same Iris data and the same split, so the comparison between models is fair. Reusing one split means any difference in accuracy comes from the models, not from luck in how the data was divided.

```python
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split

iris = load_iris(as_frame=True)
X = iris.data
y = iris.target

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
print("train:", X_train.shape, "test:", X_test.shape)
```

Output:

```
train: (120, 4) test: (30, 4)
```

This is identical to Lesson 7: the four measurement features in `X`, the species in `y`, and a stratified 80/20 split with `random_state=42`. Keeping the split fixed is what lets you compare models honestly.

---

## 4. Build a Decision Tree

A decision tree is one of the most intuitive models because you can literally read its decisions. Let us train one and look inside.

### Step 1: Create and train the tree

```python
from sklearn.tree import DecisionTreeClassifier

tree = DecisionTreeClassifier(max_depth=3, random_state=42)
tree.fit(X_train, y_train)
```

`DecisionTreeClassifier(max_depth=3, random_state=42)` creates the tree. `max_depth=3` limits it to three layers of questions, which keeps it simple and readable and helps prevent it from memorizing the training data. `random_state=42` makes the result reproducible. Then `fit` builds the tree of questions from the training data.

### Step 2: Measure its accuracy

```python
from sklearn.metrics import accuracy_score

print("tree accuracy:", round(accuracy_score(y_test, tree.predict(X_test)), 4))
```

Output:

```
tree accuracy: 0.9667
```

The tree gets about 97 percent of the test flowers right, matching logistic regression. Different reasoning, similar result on this easy dataset.

### Step 3: See which features mattered

A tree can tell you how important each feature was to its decisions:

```python
import pandas as pd

importances = pd.Series(tree.feature_importances_, index=X.columns).round(3)
print(importances)
```

Output:

```
sepal length (cm)    0.000
sepal width (cm)     0.000
petal length (cm)    0.579
petal width (cm)     0.421
dtype: float64
```

`feature_importances_` scores how much each feature contributed, and the scores sum to 1. The tree relied entirely on the two petal measurements and never used the sepal measurements at all. This confirms the insight from the last lesson: petals separate the species best.

### Step 4: Read the tree's rules

The real charm of a tree is that you can print its actual decision rules:

```python
from sklearn.tree import export_text

print(export_text(tree, feature_names=list(X.columns)))
```

Output:

```
|--- petal length (cm) <= 2.45
|   |--- class: 0
|--- petal length (cm) >  2.45
|   |--- petal width (cm) <= 1.65
|   |   |--- petal length (cm) <= 4.95
|   |   |   |--- class: 1
|   |   |--- petal length (cm) >  4.95
|   |   |   |--- class: 2
|   |--- petal width (cm) >  1.65
|   |   |--- petal length (cm) <= 4.85
|   |   |   |--- class: 2
|   |   |--- petal length (cm) >  4.85
|   |   |   |--- class: 2
```

`export_text` prints the tree as nested rules. Read it top down: if the petal length is at most 2.45 cm, predict class 0 (setosa) right away. Otherwise it asks about petal width, then petal length again, narrowing down to versicolor (class 1) or virginica (class 2). This transparency is why trees are popular when you need to explain a decision to a person.

---

## 5. Build a K-Nearest Neighbors Classifier

KNN takes the opposite approach: it stores the training data and classifies by similarity at prediction time. Let us see it in action and explore the one setting that matters most, the number of neighbors.

### Step 1: Create and train with k = 5

```python
from sklearn.neighbors import KNeighborsClassifier

knn = KNeighborsClassifier(n_neighbors=5)
knn.fit(X_train, y_train)
print("knn accuracy:", round(accuracy_score(y_test, knn.predict(X_test)), 4))
```

Output:

```
knn accuracy: 1.0
```

`KNeighborsClassifier(n_neighbors=5)` sets `k` to 5, meaning each prediction is a vote among the 5 most similar training flowers. With `k=5` it classifies every test flower correctly on this split. Note that `fit` for KNN simply memorizes the training data; the real work happens during `predict`.

### Step 2: Try different values of k

The choice of `k` changes the model. A small `k` is sensitive to individual neighbors, while a larger `k` smooths the decision by polling more of them:

```python
for k in [1, 3, 5, 7, 9]:
    model = KNeighborsClassifier(n_neighbors=k)
    model.fit(X_train, y_train)
    print(f"k={k} accuracy:", round(accuracy_score(y_test, model.predict(X_test)), 4))
```

Output:

```
k=1 accuracy: 0.9667
k=3 accuracy: 1.0
k=5 accuracy: 1.0
k=7 accuracy: 0.9667
k=9 accuracy: 1.0
```

The accuracy wobbles a little as `k` changes. With `k=1` the model trusts only the single closest flower, which can be noisy, while larger values average over more neighbors. There is no universally best `k`; you try several and pick what works, a process you will formalize as hyperparameter tuning in the next course. A common rule of thumb is to use an odd `k` so votes cannot tie.

---

## 6. Compare All Three Models

The fair way to compare models is on the same test set. Since you used one fixed split, you can line up logistic regression, the decision tree, and KNN directly.

```python
from sklearn.linear_model import LogisticRegression

logreg = LogisticRegression(max_iter=200).fit(X_train, y_train)

models = [
    ("LogisticRegression", logreg),
    ("DecisionTree", tree),
    ("KNN(5)", knn),
]

for name, model in models:
    acc = accuracy_score(y_test, model.predict(X_test))
    print(f"{name}: {round(acc, 4)}")
```

Output:

```
LogisticRegression: 0.9667
DecisionTree: 0.9667
KNN(5): 1.0
```

All three are excellent here, with KNN edging ahead on this particular split. Do not read too much into the small difference: Iris is an easy dataset, and a single split is a noisy way to compare. The real lesson is the technique, looping over models and scoring them the same way, which you will use on harder problems where the gaps between models are large and meaningful.

---

## 7. How to Choose a Model

Since all three did well, how do you choose in practice? Each model has strengths and weaknesses that go beyond a single accuracy number, and being aware of them guides your choice.

- **Logistic regression** is fast, gives probabilities, and its coefficients are interpretable, but it assumes the classes can be separated in a fairly straight-line way.
- **Decision trees** are very easy to explain and handle non-linear patterns, but a single deep tree can overfit by memorizing the training data. Limiting `max_depth` helps.
- **KNN** is simple and makes no assumptions about the shape of the data, but it slows down as the dataset grows (it compares against every training point) and it is sensitive to feature scales, which you will fix with scaling in Lesson 12.

In real projects you rarely guess. You try several models, evaluate them properly (with the cross-validation you will learn later), and pick the one that performs best and fits your needs for speed and interpretability. For now, the habit to build is this: never assume one model is best, compare them.

---

## 8. Fix the Errors in Your Code

These mistakes are common when juggling several models.

**Mistake 1: Comparing models on different splits.**

```python
# Wrong: a fresh random split for each model makes the comparison meaningless
X_train, X_test, y_train, y_test = train_test_split(X, y)  # different every time
```

```python
# Correct: create one split with a fixed random_state and reuse it for all models
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
```

To compare models fairly, they must face the same test data. Fix the split once and reuse it.

**Mistake 2: Letting a decision tree grow without limit, then trusting the training score.**

```python
# Risky: an unlimited tree can memorize the training data
tree = DecisionTreeClassifier()
tree.fit(X_train, y_train)
tree.score(X_train, y_train)   # often a perfect 1.0, but misleading
```

```python
# Better: limit depth and judge on the test set
tree = DecisionTreeClassifier(max_depth=3, random_state=42)
tree.fit(X_train, y_train)
tree.score(X_test, y_test)
```

A full-depth tree can score perfectly on training data while doing worse on new data. Limit `max_depth` and always judge on the test set.

**Mistake 3: Choosing an even k for KNN.**

```python
# Risky: an even k can produce tied votes
knn = KNeighborsClassifier(n_neighbors=4)
```

```python
# Safer: use an odd k so the vote has a clear winner
knn = KNeighborsClassifier(n_neighbors=5)
```

With an even number of neighbors, a vote can tie between classes. An odd `k` avoids that in the common two-class case.

---

## 9. Exercises

**Exercise 1:** Train a decision tree on Iris with `max_depth=2` and `random_state=42` (same stratified split as the lesson). Print its test accuracy and feature importances. How does it compare to the depth-3 tree?

**Exercise 2:** Train a KNN classifier with `k=11` and print its test accuracy. Is more neighbors always better here?

**Exercise 3:** Train a depth-3 tree and a k=5 KNN, then predict the species of a flower with sepal length 5.8, sepal width 2.7, petal length 5.1, and petal width 1.9 with both. Do they agree?

---

## 10. Solutions

**Solution for Exercise 1:**

```python
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score
import pandas as pd

iris = load_iris(as_frame=True)
X, y = iris.data, iris.target
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

tree2 = DecisionTreeClassifier(max_depth=2, random_state=42)
tree2.fit(X_train, y_train)
print("accuracy:", round(accuracy_score(y_test, tree2.predict(X_test)), 4))
print(pd.Series(tree2.feature_importances_, index=X.columns).round(3))
```

Output:

```
accuracy: 0.9333
sepal length (cm)    0.000
sepal width (cm)     0.000
petal length (cm)    0.552
petal width (cm)     0.448
dtype: float64
```

The shallower depth-2 tree scores 0.9333, slightly below the depth-3 tree's 0.9667. With one fewer layer of questions it cannot separate the two harder species as cleanly, but it still relies only on the petal features.

**Solution for Exercise 2:**

```python
from sklearn.neighbors import KNeighborsClassifier

knn11 = KNeighborsClassifier(n_neighbors=11)
knn11.fit(X_train, y_train)
print("accuracy:", round(accuracy_score(y_test, knn11.predict(X_test)), 4))
```

Output:

```
accuracy: 0.9667
```

With `k=11` the accuracy is 0.9667, lower than the perfect score at `k=5`. More neighbors is not always better: too many can blur the boundary between classes by including less similar flowers in the vote. The best `k` is something you search for, not assume.

**Solution for Exercise 3:**

```python
import pandas as pd
from sklearn.tree import DecisionTreeClassifier
from sklearn.neighbors import KNeighborsClassifier

tree3 = DecisionTreeClassifier(max_depth=3, random_state=42).fit(X_train, y_train)
knn5 = KNeighborsClassifier(n_neighbors=5).fit(X_train, y_train)

new = pd.DataFrame([{
    "sepal length (cm)": 5.8, "sepal width (cm)": 2.7,
    "petal length (cm)": 5.1, "petal width (cm)": 1.9
}])
print("tree:", iris.target_names[tree3.predict(new)[0]])
print("knn:", iris.target_names[knn5.predict(new)[0]])
```

Output:

```
tree: virginica
knn: virginica
```

Both models predict virginica for this flower, which has the long, wide petals typical of that species. When different models agree, you can be more confident in the prediction.

---

## Next Up - Lesson 9

You now have three classifiers in your toolkit and a way to compare them. You saw how a decision tree reasons with rules, how KNN reasons by similarity, and how the choice of settings like tree depth and k changes the result. Most importantly, you learned to compare models fairly on the same split.

In Lesson 9, you will go deep on evaluation. Accuracy alone can be misleading, so you will learn the metrics that tell the real story: precision, recall, and f1 for classification, and MAE, RMSE, and R2 for regression. Knowing how to measure a model honestly is what makes all your comparisons trustworthy.
