## 1. Before You Begin

Throughout this course you have quietly relied on `cross_val_score`, and several times a single train/test split disagreed with the cross-validated result. This lesson finally explains why. Cross-validation is the technique that turns "my model got 0.83 on one split" into "my model scores 0.79 plus or minus 0.02 on average", a far more trustworthy statement that you can actually base decisions on.

A single split is a roll of the dice. Depending on which rows happen to land in the test set, your accuracy can swing by several percentage points. Cross-validation removes that luck by testing on every part of the data in turn and averaging the results. Once you understand it, you will use it for every model comparison and every tuning decision.

### What You'll Build

Experiments that expose how much a single split varies, then proper k-fold and stratified cross-validation on the Titanic data, ending with a fair comparison of several models using their cross-validated mean and standard deviation.

### What You'll Learn

- ✅ Why a single train/test split can mislead you
- ✅ How k-fold cross-validation works
- ✅ How to use `cross_val_score` and read its mean and spread
- ✅ Why stratified folds matter for classification
- ✅ How to compare models fairly with cross-validation
- ✅ How to control folds with `StratifiedKFold`

### What You'll Need

- The pipeline skills from Lesson 1
- The models from Module 2
- A Colab notebook with scikit-learn and seaborn

---

## 2. Why a Single Split Misleads

A single `train_test_split` puts a random 20 percent of rows into the test set. Change the random seed and you get a different test set, and often a noticeably different score. Let us see how much it swings.

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

numeric = ["age", "fare", "sibsp", "parch", "pclass"]
categorical = ["sex", "embarked"]
preprocessor = ColumnTransformer([
    ("num", Pipeline([("imp", SimpleImputer(strategy="median")), ("sc", StandardScaler())]), numeric),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
])

for rs in [0, 1, 2, 3, 42]:
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=rs, stratify=y)
    model = Pipeline([("pre", preprocessor), ("clf", LogisticRegression(max_iter=1000))])
    model.fit(X_train, y_train)
    print(f"random_state={rs}: {round(accuracy_score(y_test, model.predict(X_test)), 4)}")
```

Output:

```
random_state=0: 0.7821
random_state=1: 0.7877
random_state=2: 0.7877
random_state=3: 0.8268
random_state=42: 0.8045
```

Same model, same data, same code: only the random split changed, yet the accuracy ranges from 0.7821 to 0.8268, almost five percentage points. If you reported just the `random_state=3` run, you would overstate your model. This instability is exactly why you cannot trust a single split, and it is the problem cross-validation solves.

---

## 3. How K-Fold Cross-Validation Works

Cross-validation tests on all of the data by rotating which part is held out. In k-fold cross-validation, you split the data into k equal parts (folds). You then train on k-1 folds and test on the remaining one, repeating k times so every fold serves as the test set exactly once. The k scores are averaged.

With 5-fold cross-validation, for example:

- Fold 1 is the test set; train on folds 2 to 5.
- Fold 2 is the test set; train on folds 1, 3, 4, 5.
- And so on, five times.

The benefit is that every row is used for both training and testing (in different rounds), so no single lucky or unlucky split dominates. You also get a spread of scores, which tells you how stable the model is. A small spread means consistent performance; a large spread means the model is sensitive to the data it sees.

The cost is computation: 5-fold cross-validation trains the model five times. For most problems that is well worth the reliability it buys.

---

## 4. Run Cross-Validation with cross_val_score

`cross_val_score` does the whole k-fold loop for you. Pass it a pipeline, the features, the target, and the number of folds.

```python
from sklearn.model_selection import cross_val_score

clf = Pipeline([("pre", preprocessor), ("clf", LogisticRegression(max_iter=1000))])
scores = cross_val_score(clf, X, y, cv=5)

print("scores:", scores.round(4))
print("mean:", round(scores.mean(), 4))
print("std:", round(scores.std(), 4))
```

Output:

```
scores: [0.7765 0.7865 0.7809 0.7697 0.8258]
mean: 0.7879
std: 0.0198
```

`cv=5` runs 5-fold cross-validation, returning one score per fold. The individual scores range from 0.7697 to 0.8258, which again shows how much a single split could mislead. The mean of 0.7879 is your best single estimate of the model's accuracy, and the standard deviation of 0.0198 tells you the typical swing. Always report both: a model is "0.79 plus or minus 0.02", not just "0.79". Passing the whole pipeline (not pre-scaled data) keeps each fold leak-free, as you learned in Lesson 1.

---

## 5. Stratified Folds for Classification

For classification, the folds should preserve the class balance, so each fold has roughly the same proportion of survivors as the full data. scikit-learn does this automatically for classifiers, but you can control it explicitly with `StratifiedKFold`, which also lets you shuffle the data first.

```python
from sklearn.model_selection import StratifiedKFold

skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
scores = cross_val_score(clf, X, y, cv=skf)

print("stratified scores:", scores.round(4))
print("mean:", round(scores.mean(), 4))
```

Output:

```
stratified scores: [0.7709 0.8034 0.7921 0.7809 0.8202]
mean: 0.7935
```

`StratifiedKFold` keeps each fold's survival rate close to the overall rate, which matters when one class is less common. `shuffle=True` mixes the rows before splitting (useful if the data has any order), and `random_state` makes that reproducible. When you pass an integer like `cv=5` to a classifier, scikit-learn already uses stratified folds under the hood; creating the object yourself just gives you control over shuffling and reproducibility.

---

## 6. Compare Models the Right Way

Cross-validation's biggest payoff is fair model comparison. Run each model through the same cross-validation and compare their mean scores and spreads, rather than trusting one split.

```python
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier

models = {
    "LogReg": LogisticRegression(max_iter=1000),
    "RandomForest": RandomForestClassifier(n_estimators=200, random_state=42),
    "GradientBoosting": GradientBoostingClassifier(random_state=42),
}

for name, estimator in models.items():
    pipe = Pipeline([("pre", preprocessor), ("clf", estimator)])
    scores = cross_val_score(pipe, X, y, cv=5)
    print(f"{name}: {round(scores.mean(), 4)} +/- {round(scores.std(), 4)}")
```

Output:

```
LogReg: 0.7879 +/- 0.0198
RandomForest: 0.807 +/- 0.0257
GradientBoosting: 0.8227 +/- 0.0178
```

Now the comparison is trustworthy. Gradient boosting leads at 0.8227 with the smallest spread (0.0178), making it both the most accurate and the most stable on this data. The random forest is next, and logistic regression last. Crucially, these conclusions hold across all five folds, not just one lucky split, so you can act on them with confidence. When two models are close and their spreads overlap, the difference may not be meaningful, which is another insight a single split could never give you.

---

## 7. Fix the Errors in Your Code

These mistakes undermine cross-validation.

**Mistake 1: Reporting only the mean, hiding the spread.**

```python
# Incomplete: the mean alone hides how stable the model is
print(scores.mean())
```

```python
# Better: report mean and standard deviation together
print(f"{scores.mean():.4f} +/- {scores.std():.4f}")
```

The spread tells you whether a difference between models is real or just noise. Always report it alongside the mean.

**Mistake 2: Cross-validating pre-transformed data instead of a pipeline.**

```python
# Wrong: scaling once outside leaks information across folds
X_scaled = StandardScaler().fit_transform(X[numeric])
cross_val_score(LogisticRegression(), X_scaled, y, cv=5)
```

```python
# Correct: pass the full pipeline so preprocessing re-fits inside each fold
clf = Pipeline([("pre", preprocessor), ("clf", LogisticRegression(max_iter=1000))])
cross_val_score(clf, X, y, cv=5)
```

If you preprocess once before cross-validation, each fold's validation data has leaked into that preprocessing. Always cross-validate the pipeline.

**Mistake 3: Using plain KFold for imbalanced classification.**

```python
# Risky: plain shuffling can leave a fold with too few of the rare class
from sklearn.model_selection import KFold
cross_val_score(clf, X, y, cv=KFold(n_splits=5, shuffle=True))
```

```python
# Better: stratify so every fold preserves the class balance
from sklearn.model_selection import StratifiedKFold
cross_val_score(clf, X, y, cv=StratifiedKFold(n_splits=5, shuffle=True, random_state=42))
```

For classification, stratified folds keep the class proportions stable. (Passing an integer to a classifier already stratifies, but be explicit when you build the splitter yourself.)

---

## 8. Exercises

**Exercise 1:** Run 10-fold cross-validation on the logistic regression pipeline and print the mean and standard deviation. How does using more folds compare to 5-fold?

**Exercise 2:** Use `StratifiedKFold` with 5 splits, shuffling, and `random_state=0` to cross-validate the logistic regression pipeline. Print the per-fold scores and the mean.

**Exercise 3:** Compare the 5-fold cross-validated accuracy of logistic regression against a scaled SVM (`SVC`). Which model is better on this data?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from sklearn.model_selection import cross_val_score

scores = cross_val_score(clf, X, y, cv=10)
print("mean:", round(scores.mean(), 4))
print("std:", round(scores.std(), 4))
```

Output:

```
mean: 0.7901
std: 0.0236
```

With 10 folds the mean (0.7901) is very close to the 5-fold mean (0.7879), as expected, since both estimate the same thing. The standard deviation is a bit larger because each fold's test set is smaller (about 89 rows instead of 178), making individual fold scores noisier. More folds means more training runs and slightly noisier per-fold scores, but a similar overall estimate.

**Solution for Exercise 2:**

```python
from sklearn.model_selection import StratifiedKFold

skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)
scores = cross_val_score(clf, X, y, cv=skf)
print("scores:", scores.round(4))
print("mean:", round(scores.mean(), 4))
```

Output:

```
scores: [0.8101 0.8371 0.7697 0.7584 0.7697]
mean: 0.789
```

A different shuffle (`random_state=0`) produces different folds and a mean of 0.789, close to the lesson's 0.7935 but not identical. The individual folds still vary, which reinforces why you average over folds rather than trusting any one of them.

**Solution for Exercise 3:**

```python
from sklearn.svm import SVC
from sklearn.model_selection import cross_val_score

logreg = Pipeline([("pre", preprocessor), ("clf", LogisticRegression(max_iter=1000))])
svm = Pipeline([("pre", preprocessor), ("clf", SVC(random_state=42))])

print("logreg cv:", round(cross_val_score(logreg, X, y, cv=5).mean(), 4))
print("svm cv:", round(cross_val_score(svm, X, y, cv=5).mean(), 4))
```

Output:

```
logreg cv: 0.7879
svm cv: 0.8283
```

The scaled SVM (0.8283) clearly outperforms logistic regression (0.7879) across the folds. Because this comparison is cross-validated rather than based on a single split, you can trust the conclusion that the SVM is the stronger model here.

---

## Next Up - Lesson 7

You now evaluate models the trustworthy way. Cross-validation rotates the test set across all the data, giving you a mean score and a spread that reveal both how good and how stable a model is, and let you compare models fairly. This is the bedrock of every sound modeling decision.

In Lesson 7, you will use cross-validation to do something powerful: automatically find the best settings for a model. Instead of trying hyperparameters by hand, you will let `GridSearchCV` and `RandomizedSearchCV` search combinations for you, each one evaluated with the cross-validation you just learned.
