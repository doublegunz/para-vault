## 1. Before You Begin

You can now measure models accurately. In this lesson you use that skill to diagnose the single most important problem in machine learning: the gap between how a model does on data it has seen and data it has not. A model that aces the training data but fails on new data has overfit, and spotting that is what separates a model that works in the real world from one that only looks good in a notebook.

You will see overfitting and underfitting happen in front of you by training the same model at different complexities and comparing its training score to its test score. This comparison is your main diagnostic tool, and the discipline of always holding out a test set is what makes it possible.

### What You'll Build

A notebook that trains decision trees of increasing depth on a real medical dataset, printing both the training accuracy and the test accuracy for each. You will watch underfitting turn into a good fit and then into overfitting, and learn to read the warning signs.

### What You'll Learn

- ✅ What overfitting and underfitting mean
- ✅ How to detect them by comparing training and test scores
- ✅ How model complexity drives the trade-off
- ✅ The bias-variance trade-off in plain language
- ✅ Practical ways to fight overfitting
- ✅ Why a held-out test set is non-negotiable

### What You'll Need

- The evaluation metrics from Lesson 9
- The decision tree and KNN models from Lesson 8
- A Colab notebook with scikit-learn

---

## 2. Overfitting and Underfitting

Every model sits somewhere on a scale from too simple to too complex, and both ends fail in their own way. Understanding the two failure modes tells you how to fix a model that is not working.

**Underfitting** is when a model is too simple to capture the real pattern. It does poorly on both the training data and the test data, because it never learned enough. Imagine drawing a straight line through data that clearly curves: it misses the shape everywhere.

**Overfitting** is when a model is too complex and memorizes the training data, including its random noise, instead of learning the general pattern. It does great on training data but poorly on new data. Imagine a student who memorizes the exact answers to last year's exam but cannot answer a slightly reworded question.

The goal is the sweet spot in between: a model complex enough to capture the real pattern but not so complex that it memorizes noise. The way you locate that spot is by comparing two numbers, the training score and the test score, which you will do next.

---

## 3. Spotting It with Train vs Test Scores

The clearest signal of overfitting is a large gap between training accuracy and test accuracy. Let us make that gap appear by growing a decision tree deeper and deeper.

### Step 1: Load a richer dataset

```python
from sklearn.datasets import load_breast_cancer

data = load_breast_cancer(as_frame=True)
X, y = data.data, data.target
print("shape:", X.shape)
print(y.value_counts())
```

Output:

```
shape: (569, 30)
target
1    357
0    212
Name: count, dtype: int64
```

We switch from Iris to the breast cancer dataset because it has 569 patients and 30 features, enough complexity for overfitting to show up clearly. The target is whether a tumor is benign (1) or malignant (0). Iris was too easy to overfit.

### Step 2: Split the data

```python
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)
```

A stratified 70/30 split, as usual. The training set is what the model learns from, and the test set is the unseen data you use to detect overfitting.

### Step 3: Compare train and test scores across depths

Now train trees of increasing `max_depth` and print both scores for each:

```python
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score

print(f"{'depth':>6} {'train':>8} {'test':>8}")
for depth in [1, 2, 3, 5, 10, None]:
    model = DecisionTreeClassifier(max_depth=depth, random_state=42)
    model.fit(X_train, y_train)
    train_acc = accuracy_score(y_train, model.predict(X_train))
    test_acc = accuracy_score(y_test, model.predict(X_test))
    print(f"{str(depth):>6} {train_acc:>8.4f} {test_acc:>8.4f}")
```

Output:

```
 depth    train     test
     1   0.9271   0.9123
     2   0.9648   0.9181
     3   0.9799   0.9240
     5   0.9950   0.9298
    10   1.0000   0.9181
  None   1.0000   0.9181
```

The loop trains a tree at each depth and records how it scores on the training set and the test set. `max_depth=None` means no limit, so the tree grows until it perfectly separates the training data. The f-string formatting just lines the numbers up into a neat table. Now read what this table is telling you.

---

## 4. Reading the Results

This little table contains the whole story of model complexity. Walk through it from top to bottom.

At **depth 1**, both scores are modest (0.93 train, 0.91 test) and close together. The tree is too simple, asking only one question, so it slightly underfits: it has not squeezed all the signal out of the data.

From **depth 2 to depth 5**, both scores rise and the test score peaks at 0.9298. This is the sweet spot. The tree is now complex enough to capture the real pattern, and the gap between train and test stays small.

At **depth 10 and beyond**, the training score hits a perfect 1.0000 while the test score drops back to 0.9181. This is overfitting in action: the tree has memorized the training patients, noise and all, so it is flawless on them but worse on new patients. The growing gap between a perfect training score and a falling test score is the textbook signature of overfitting.

The practical takeaway: you would choose a tree of around depth 5 here, not the deepest one. The deepest tree looks perfect on training data, which is exactly why you must never judge a model on the data it learned from.

---

## 5. The Bias-Variance Trade-off

The pattern you just saw has a name: the bias-variance trade-off. It is the theory behind why both too-simple and too-complex models fail, and it is worth understanding in plain language.

- **Bias** is error from wrong assumptions, from a model too simple to fit the pattern. High bias causes underfitting. The depth-1 tree had high bias.
- **Variance** is error from being too sensitive to the specific training data, from a model so flexible it fits the noise. High variance causes overfitting. The unlimited-depth tree had high variance.

These two pull in opposite directions. Making a model more complex lowers bias but raises variance; making it simpler does the reverse. There is no way to drive both to zero, so the art is balancing them to minimize total error on new data. Every knob you tune, tree depth, the `k` in KNN, the number of features, is really you moving along this bias-variance scale. Keeping the picture in mind turns model tuning from guesswork into a deliberate search for that balance.

---

## 6. How to Fight Overfitting

Once you have spotted overfitting, you have several practical tools to reduce it. These are the moves you reach for whenever the test score lags far behind the training score.

- **Simplify the model.** Reduce complexity, for example by lowering `max_depth` on a tree or raising `k` in KNN. A simpler model has less room to memorize noise.
- **Get more training data.** More examples make it harder to memorize and easier to learn the real pattern. This is often the most effective fix when it is possible.
- **Use fewer or better features.** Dropping irrelevant features and engineering meaningful ones gives the model less noise to latch onto.
- **Use cross-validation.** Instead of trusting a single train and test split, cross-validation averages performance over several splits for a more reliable estimate, which you will learn in the next course.

Underfitting is the opposite problem, and the fixes are mirror images: make the model more complex, add more informative features, or train longer. The diagnosis always comes from the same place, comparing training and test scores, and the table you built is the tool that makes that diagnosis visible.

---

## 7. Fix the Errors in Your Code

These mistakes hide overfitting or make it worse.

**Mistake 1: Reporting only the training score.**

```python
# Wrong: training accuracy alone cannot reveal overfitting
model.fit(X_train, y_train)
print(model.score(X_train, y_train))   # 1.0 looks perfect, but means nothing alone
```

```python
# Correct: always compare training and test scores
print("train:", model.score(X_train, y_train))
print("test:", model.score(X_test, y_test))
```

A perfect training score is meaningless on its own. Only the comparison to the test score tells you whether the model generalizes.

**Mistake 2: Tuning settings while peeking at the test set repeatedly.**

```python
# Risky: trying dozens of options and picking the best test score leaks the test set
# (the test set slowly becomes part of your tuning, inflating your confidence)
```

```python
# Better: use cross-validation on the training data to choose settings,
# and keep the test set for one final, honest check at the very end
```

If you tune endlessly against the test set, you start overfitting to it too. Reserve the test set for a final evaluation and use cross-validation for tuning.

**Mistake 3: Concluding a model is good from one lucky split.**

```python
# Risky: a single split can be unusually easy or hard
X_train, X_test, y_train, y_test = train_test_split(X, y)  # no random_state, varies each run
```

```python
# Better: fix the split for reproducibility, and prefer cross-validation for a stable estimate
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)
```

One split is noisy. Fix it for reproducibility now, and lean on cross-validation later for a trustworthy estimate.

---

## 8. Exercises

**Exercise 1:** Using the breast cancer dataset and the same split, build the train-versus-test table for decision trees of depth 1, 3, 5, and 8. Which depth gives the best test accuracy?

**Exercise 2:** Build a similar train-versus-test table for KNN with `k` of 1, 5, 15, and 50. What does `k=1` do to the training accuracy, and why?

**Exercise 3:** A model scores 0.99 on training data and 0.72 on test data. In a comment, state whether it is overfitting or underfitting and name two things you would try to fix it.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score

X, y = load_breast_cancer(return_X_y=True, as_frame=True)
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)

print(f"{'depth':>6} {'train':>8} {'test':>8}")
for depth in [1, 3, 5, 8]:
    model = DecisionTreeClassifier(max_depth=depth, random_state=42).fit(X_train, y_train)
    tr = accuracy_score(y_train, model.predict(X_train))
    te = accuracy_score(y_test, model.predict(X_test))
    print(f"{depth:>6} {tr:>8.4f} {te:>8.4f}")
```

Output:

```
 depth    train     test
     1   0.9271   0.9123
     3   0.9799   0.9240
     5   0.9950   0.9298
     8   1.0000   0.9181
```

Depth 5 gives the best test accuracy at 0.9298. By depth 8 the training accuracy is already a perfect 1.0000 while the test accuracy has fallen back to 0.9181, the clear sign of overfitting.

**Solution for Exercise 2:**

```python
from sklearn.neighbors import KNeighborsClassifier

print(f"{'k':>4} {'train':>8} {'test':>8}")
for k in [1, 5, 15, 50]:
    model = KNeighborsClassifier(n_neighbors=k).fit(X_train, y_train)
    tr = accuracy_score(y_train, model.predict(X_train))
    te = accuracy_score(y_test, model.predict(X_test))
    print(f"{k:>4} {tr:>8.4f} {te:>8.4f}")
```

Output:

```
   k    train     test
   1   1.0000   0.9240
   5   0.9497   0.9240
  15   0.9422   0.9240
  50   0.9221   0.9181
```

With `k=1` the training accuracy is a perfect 1.0000, because each training point's single nearest neighbor is itself, so it always votes correctly. That perfect training score with a lower test score is overfitting: `k=1` is the most complex, most noise-sensitive version of KNN. Larger `k` smooths the model, lowering training accuracy while keeping test accuracy stable.

**Solution for Exercise 3:**

```python
# The model is OVERFITTING: it scores far higher on training (0.99)
# than on test (0.72), so it memorized the training data instead of
# learning a general pattern.
#
# Two fixes to try:
# 1. Simplify the model (for example, reduce tree depth or raise k).
# 2. Get more training data, or reduce/clean the features.
```

A 27-point gap between training and test scores is a textbook overfitting signal. The fixes all aim to reduce complexity or give the model more to learn from, so it captures the real pattern rather than the noise.

---

## Next Up - Lesson 11

You can now diagnose the health of any model by comparing its training and test scores, you understand the bias-variance trade-off that explains why both too-simple and too-complex models fail, and you know the practical moves to fight overfitting and underfitting. This diagnostic skill underpins every modeling decision you will make.

In Lesson 11, you move into Module 6 and start preparing real, messy data. Up to now your datasets were clean and ready, but real data has missing values and text categories that models cannot handle directly. You will learn to fill missing values and encode categories so that any dataset becomes model-ready.
