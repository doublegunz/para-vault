## 1. Before You Begin

You have now seen two tree-based ensembles, the random forest and gradient boosting. This lesson introduces a model that works on a completely different principle: the support vector machine, or SVM. Instead of asking yes-or-no questions like a tree, an SVM draws the widest possible boundary between the classes and classifies new points based on which side they fall.

SVMs were one of the most popular models before deep learning rose, and they are still excellent for many problems, especially with clean, scaled data and a moderate number of samples. In this lesson you will train one, see firsthand why SVMs absolutely require feature scaling, and explore how kernels let an SVM draw curved boundaries instead of just straight lines.

### What You'll Build

An SVM pipeline for the Titanic data, a side-by-side demonstration that scaling is not optional for SVMs, and experiments comparing different kernels and the regularization setting `C`.

### What You'll Learn

- ✅ How an SVM separates classes with a maximum-margin boundary
- ✅ Why SVMs need feature scaling to work at all
- ✅ How to build an `SVC` in a pipeline
- ✅ What kernels are and how they enable curved boundaries
- ✅ How the `C` parameter controls regularization
- ✅ When an SVM is a good choice

### What You'll Need

- The pipeline and scaling skills from earlier lessons
- A Colab notebook with scikit-learn and seaborn
- The Titanic dataset (built into seaborn)

---

## 2. How a Support Vector Machine Works

Imagine plotting two classes of points and trying to draw a line that separates them. Usually many lines would work. An SVM picks the one with the largest margin: the line that sits as far as possible from the nearest points of both classes. Those nearest points, the ones that define the boundary, are called the support vectors, which is where the model gets its name.

Why the widest margin? A boundary with lots of breathing room on both sides is more likely to generalize to new data than one that squeaks right past the training points. This focus on the margin makes SVMs powerful and resistant to overfitting on the right problems.

Two ideas make SVMs flexible:

- **The kernel** lets an SVM draw curved boundaries, not just straight lines, by implicitly mapping the data into a higher-dimensional space. The popular `rbf` kernel can wrap around complex shapes.
- **The C parameter** controls how much the SVM tolerates misclassified training points. A small `C` allows more mistakes for a wider, smoother margin (more regularization); a large `C` insists on classifying training points correctly, risking overfitting.

One crucial requirement follows from how SVMs measure distance to the margin: the features must be scaled, or large-valued features dominate. Let us see that dramatically.

---

## 3. Why SVMs Need Scaling

This is the most important practical fact about SVMs. Because an SVM measures distances, a feature on a large scale (like `fare`, which runs into the hundreds) overwhelms a small one (like `pclass`). Without scaling, the model is effectively blind to most features.

### Step 1: Build two pipelines, scaled and unscaled

```python
import pandas as pd
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.svm import SVC
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

scaled_pre = ColumnTransformer([
    ("num", Pipeline([("imp", SimpleImputer(strategy="median")), ("sc", StandardScaler())]), numeric),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
])
unscaled_pre = ColumnTransformer([
    ("num", SimpleImputer(strategy="median"), numeric),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
])
```

The only difference between the two preprocessors is the `StandardScaler` in the numeric branch of `scaled_pre`. Everything else is identical, so any difference in results comes purely from scaling.

### Step 2: Compare the results

```python
svm_scaled = Pipeline([("pre", scaled_pre), ("clf", SVC(random_state=42))]).fit(X_train, y_train)
svm_unscaled = Pipeline([("pre", unscaled_pre), ("clf", SVC(random_state=42))]).fit(X_train, y_train)

print("SVM with scaling:", round(accuracy_score(y_test, svm_scaled.predict(X_test)), 4))
print("SVM without scaling:", round(accuracy_score(y_test, svm_unscaled.predict(X_test)), 4))
```

Output:

```
SVM with scaling: 0.8156
SVM without scaling: 0.6201
```

The difference is enormous: 0.8156 with scaling versus 0.6201 without. The unscaled model is barely better than guessing the majority class, because `fare` dwarfs every other feature and the SVM cannot see them. For an SVM, scaling is not a nice-to-have; it is mandatory. The pipeline makes this easy by scaling correctly inside cross-validation and on new data.

---

## 4. Build and Cross-Validate the SVM

Now that scaling is in place, treat the SVM like any other model in the pipeline.

```python
from sklearn.model_selection import cross_val_score

svm = Pipeline([("pre", scaled_pre), ("clf", SVC(random_state=42))])
svm.fit(X_train, y_train)
print("svm cv mean:", round(cross_val_score(svm, X_train, y_train, cv=5).mean(), 4))
```

Output:

```
svm cv mean: 0.8147
```

`SVC(random_state=42)` uses the default `rbf` kernel and `C=1`. Across 5 folds it averages 0.8147, right in line with the other strong models you have tried on this data. Because the scaler lives in the pipeline, each cross-validation fold scales using only its own training portion, so there is no leakage.

---

## 5. Kernels and the C Parameter

An SVM's behavior is shaped mainly by its kernel and its `C` value. Exploring them builds intuition for how the model fits.

### Step 1: Compare kernels

```python
for kernel in ["linear", "poly", "rbf"]:
    model = Pipeline([("pre", scaled_pre), ("clf", SVC(kernel=kernel, random_state=42))])
    model.fit(X_train, y_train)
    print(f"{kernel}: {round(accuracy_score(y_test, model.predict(X_test)), 4)}")
```

Output:

```
linear: 0.7765
poly: 0.8212
rbf: 0.8156
```

The `linear` kernel draws a straight boundary, which is fastest and works when classes are roughly linearly separable. The `poly` (polynomial) and `rbf` (radial basis function) kernels draw curved boundaries that can capture more complex patterns. Here the curved kernels edge out the linear one. The `rbf` kernel is the usual default and a strong all-rounder.

### Step 2: Vary the C parameter

```python
for C in [0.1, 1, 10, 100]:
    model = Pipeline([("pre", scaled_pre), ("clf", SVC(C=C, random_state=42))])
    model.fit(X_train, y_train)
    print(f"C={C}: {round(accuracy_score(y_test, model.predict(X_test)), 4)}")
```

Output:

```
C=0.1: 0.8101
C=1: 0.8156
C=10: 0.7989
C=100: 0.7821
```

`C` controls the trade-off between a wide, smooth margin and fitting the training data exactly. A small `C` (like 0.1) regularizes more, allowing some training errors for a simpler boundary, while a large `C` (like 100) tries to classify every training point correctly and tends to overfit. On this data the accuracy actually drops as `C` grows, a sign that the simpler, more regularized boundary generalizes better. The best `C` and kernel are things you tune systematically, which is the subject of Lesson 7.

---

## 6. When to Use an SVM

SVMs are powerful but not always the right tool. Knowing their sweet spot helps you decide when to reach for one.

SVMs tend to shine when:

- The data is **clean and well scaled**, with a clear margin between classes.
- You have a **small to medium number of samples**. SVMs can be slow to train on very large datasets because their cost grows quickly with the number of rows.
- The number of **features is high relative to samples**, a setting where SVMs are traditionally strong (for example, text classification).

SVMs are less ideal when:

- You have a **very large dataset**, where tree ensembles or linear models scale better.
- You need **probability estimates or interpretability**, which SVMs provide less naturally than logistic regression or trees.

On the Titanic data the SVM performs comparably to the tree ensembles, landing around 0.81 in cross-validation. As always, the practical move is to include an SVM among the models you compare, scale your features, and let proper validation decide.

---

## 7. Fix the Errors in Your Code

These mistakes are especially common with SVMs.

**Mistake 1: Forgetting to scale.**

```python
# Wrong: an SVM without scaling is dominated by large-valued features
Pipeline([("pre", unscaled_pre), ("clf", SVC())])
```

```python
# Correct: always scale numeric features for an SVM
Pipeline([("pre", scaled_pre), ("clf", SVC())])
```

This is the number one SVM mistake. Without scaling, performance collapses, as you saw (0.62 versus 0.82). Always include a scaler.

**Mistake 2: Cranking C very high to "fit better".**

```python
# Risky: a huge C forces the SVM to fit training points exactly, overfitting
SVC(C=1000)
```

```python
# Better: start near C=1 and tune, watching validation scores
SVC(C=1, random_state=42)
```

A large `C` reduces regularization and overfits. Treat `C` as a value to tune, not to maximize.

**Mistake 3: Expecting probabilities by default.**

```python
# Wrong: predict_proba raises an error unless probability estimates are enabled
SVC().fit(X_train, y_train).predict_proba(X_test)
```

```python
# Correct: enable probability=True if you need predict_proba (it is slower)
SVC(probability=True, random_state=42).fit(X_train, y_train).predict_proba(X_test)
```

An `SVC` does not produce probabilities unless you set `probability=True`, which adds extra computation. If you only need the predicted class, `predict` works without it.

---

## 8. Exercises

**Exercise 1:** Build an SVM pipeline with a `linear` kernel (scaled features) and print its test accuracy. How does it compare to the default `rbf` kernel?

**Exercise 2:** Build an SVM pipeline with the `rbf` kernel and `C=0.5`. Print its test accuracy.

**Exercise 3:** Compare the 5-fold cross-validated accuracy of a default SVM with scaling against the same SVM without scaling. How big is the gap?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from sklearn.svm import SVC
from sklearn.metrics import accuracy_score

linear_svm = Pipeline([("pre", scaled_pre), ("clf", SVC(kernel="linear", random_state=42))])
linear_svm.fit(X_train, y_train)
print("test accuracy:", round(accuracy_score(y_test, linear_svm.predict(X_test)), 4))
```

Output:

```
test accuracy: 0.7765
```

The linear kernel scores 0.7765, below the default `rbf` kernel's 0.8156 on this split. The curved `rbf` boundary captures patterns a straight line cannot, which is why `rbf` is the common default.

**Solution for Exercise 2:**

```python
rbf_svm = Pipeline([("pre", scaled_pre), ("clf", SVC(kernel="rbf", C=0.5, random_state=42))])
rbf_svm.fit(X_train, y_train)
print("test accuracy:", round(accuracy_score(y_test, rbf_svm.predict(X_test)), 4))
```

Output:

```
test accuracy: 0.8268
```

Lowering `C` to 0.5 (more regularization) gives 0.8268 here, the best SVM result so far on this split. A smoother, more forgiving boundary generalized better, matching the trend you saw when varying `C` in the lesson.

**Solution for Exercise 3:**

```python
from sklearn.model_selection import cross_val_score

scaled = Pipeline([("pre", scaled_pre), ("clf", SVC(random_state=42))])
unscaled = Pipeline([("pre", unscaled_pre), ("clf", SVC(random_state=42))])

print("scaled cv:", round(cross_val_score(scaled, X_train, y_train, cv=5).mean(), 4))
print("unscaled cv:", round(cross_val_score(unscaled, X_train, y_train, cv=5).mean(), 4))
```

Output:

```
scaled cv: 0.8147
unscaled cv: 0.6939
```

Scaling lifts the cross-validated accuracy from 0.6939 to 0.8147, a gap of more than 12 percentage points. This confirms across multiple folds, not just one split, that scaling is essential for an SVM.

---

## Next Up - Lesson 6

You now have a third family of models alongside the tree ensembles: the support vector machine, which finds a maximum-margin boundary, uses kernels to bend that boundary, and depends completely on scaled features. With logistic regression, trees, forests, boosting, and SVMs, your model toolkit is well stocked.

In Lesson 6, you move into Module 3 and turn to a question that has come up in every lesson: how do you evaluate and compare these models reliably? You will learn cross-validation properly, understanding why a single train/test split can mislead you and how averaging over multiple folds gives a far more trustworthy estimate of performance.
