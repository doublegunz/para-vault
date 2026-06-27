## 1. Before You Begin

In the last few lessons you set values like `n_estimators=200`, `max_depth=4`, `C=0.5`, and `learning_rate=0.1` by hand, trying a few options and eyeballing the results. That works for exploration, but it is slow and easy to get wrong. In this lesson you automate it. You will let scikit-learn search through many combinations of these settings for you and report the best one, each combination scored with the cross-validation you learned in Lesson 6.

These settings are called hyperparameters, and finding good values is called hyperparameter tuning. The two main tools are `GridSearchCV`, which tries every combination you list, and `RandomizedSearchCV`, which samples a fixed number of random combinations. Both fit cleanly around your pipeline.

### What You'll Build

A `GridSearchCV` that tunes a random forest pipeline on the Titanic data, reporting the best hyperparameters and cross-validated score, then a `RandomizedSearchCV` that searches a larger space more efficiently. You will compare the tuned models against the defaults.

### What You'll Learn

- ✅ The difference between parameters and hyperparameters
- ✅ How to tune a pipeline with `GridSearchCV`
- ✅ How the `step__parameter` naming addresses pipeline steps
- ✅ How to read `best_params_`, `best_score_`, and predict with the best model
- ✅ How `RandomizedSearchCV` searches large spaces efficiently
- ✅ When to choose grid search versus randomized search

### What You'll Need

- Cross-validation from Lesson 6
- The pipeline and models from earlier lessons
- A Colab notebook with scikit-learn and seaborn

---

## 2. What Are Hyperparameters?

It helps to separate two kinds of values a model has. Parameters are what the model learns from data during `fit`, like the coefficients of a logistic regression or the split points of a tree. You never set those by hand. Hyperparameters are the settings you choose before training that control how the model learns, like the number of trees, the maximum depth, or the SVM's `C`.

There is no formula for the best hyperparameters; they depend on the data. So you search. The honest, leak-free way to compare candidate settings is to score each one with cross-validation and pick the combination with the best average score. Doing this by hand is tedious and error-prone, which is exactly what `GridSearchCV` and `RandomizedSearchCV` automate: they loop over candidate settings, cross-validate each, and hand you the winner.

One important discipline: you tune using cross-validation on the training data, and you keep the test set untouched for one final, honest evaluation at the end. Tuning against the test set would leak it.

---

## 3. Grid Search with GridSearchCV

Grid search tries every combination of the hyperparameter values you list. You give it a dictionary of options, and it cross-validates each combination.

### Step 1: Build the pipeline and the parameter grid

```python
import pandas as pd
import seaborn as sns
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder
from sklearn.ensemble import RandomForestClassifier

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
    ("num", SimpleImputer(strategy="median"), numeric),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
])

pipe = Pipeline([("pre", preprocessor), ("clf", RandomForestClassifier(random_state=42))])

param_grid = {
    "clf__n_estimators": [100, 200],
    "clf__max_depth": [4, 6, 8, None],
    "clf__min_samples_leaf": [1, 2, 4],
}
```

The key detail is the naming in `param_grid`. To address a hyperparameter inside a pipeline, you write `stepname__parameter`, with a double underscore. Here `clf` is the name of the classifier step, so `clf__n_estimators` means "the `n_estimators` of the classifier". This grid has 2 times 4 times 3, which is 24 combinations.

### Step 2: Run the search

```python
grid = GridSearchCV(pipe, param_grid, cv=5, scoring="accuracy", n_jobs=-1)
grid.fit(X_train, y_train)
```

`GridSearchCV` wraps your pipeline and the grid. With `cv=5` it cross-validates each of the 24 combinations 5 times (120 fits in total), `scoring="accuracy"` is the metric to optimize, and `n_jobs=-1` uses all your processor cores to run faster. Calling `fit` runs the entire search and, at the end, refits the best combination on all of the training data automatically.

### Step 3: Read the results and test

```python
from sklearn.metrics import accuracy_score

print("best params:", grid.best_params_)
print("best cv score:", round(grid.best_score_, 4))
print("test accuracy:", round(accuracy_score(y_test, grid.predict(X_test)), 4))
```

Output:

```
best params: {'clf__max_depth': None, 'clf__min_samples_leaf': 2, 'clf__n_estimators': 100}
best cv score: 0.8231
test accuracy: 0.8156
```

`best_params_` is the winning combination, `best_score_` is its cross-validated accuracy (0.8231), and because `GridSearchCV` refit the best model, `grid.predict` uses it directly to score 0.8156 on the held-out test set. You optimized on cross-validation and confirmed once on the test set, exactly the right discipline.

---

## 4. Randomized Search with RandomizedSearchCV

Grid search becomes expensive fast: adding more values or more hyperparameters multiplies the number of combinations. `RandomizedSearchCV` instead samples a fixed number of random combinations from ranges you specify, which often finds an excellent setting in a fraction of the time.

```python
from sklearn.model_selection import RandomizedSearchCV
from scipy.stats import randint

param_dist = {
    "clf__n_estimators": randint(100, 400),
    "clf__max_depth": [4, 6, 8, 10, None],
    "clf__min_samples_leaf": randint(1, 6),
}

search = RandomizedSearchCV(
    pipe, param_dist, n_iter=15, cv=5, scoring="accuracy", random_state=42, n_jobs=-1
)
search.fit(X_train, y_train)

print("best params:", search.best_params_)
print("best cv score:", round(search.best_score_, 4))
print("test accuracy:", round(accuracy_score(y_test, search.predict(X_test)), 4))
```

Output:

```
best params: {'clf__max_depth': 10, 'clf__min_samples_leaf': 2, 'clf__n_estimators': 291}
best cv score: 0.8231
test accuracy: 0.8101
```

Instead of fixed lists, you can pass distributions. `randint(100, 400)` lets `n_estimators` be any integer in that range, and `randint(1, 6)` does the same for `min_samples_leaf`. `n_iter=15` means it tries 15 random combinations rather than every possibility. It reached the same best cross-validated score of 0.8231 as the exhaustive grid, but explored a wider range of values with far fewer fits. `random_state` makes the random sampling reproducible.

---

## 5. Grid Search vs Randomized Search

Both find good hyperparameters, so which should you use? It comes down to the size of your search space and your time budget.

- **Use grid search when the space is small.** If you have only a few hyperparameters with a few values each, trying every combination is thorough and guarantees you check them all.
- **Use randomized search when the space is large.** With many hyperparameters or wide ranges, the number of combinations explodes, and randomized search finds a strong setting much faster by sampling. Research shows random sampling is surprisingly effective because only a few hyperparameters usually matter.
- **A common workflow:** start with a randomized search over a wide range to find a promising region, then run a small grid search to fine-tune around it.

One honest note: the best cross-validated combination does not always win on a single test split. Here the tuned model scored 0.8156 on the test set while the default random forest happened to score 0.8268 on that same split. That is split noise, not a failure of tuning. Trust the cross-validated `best_score_` for your decision, and treat the single test number as one final sanity check, not the deciding vote.

---

## 6. Fix the Errors in Your Code

These mistakes are common when tuning.

**Mistake 1: Wrong parameter name for a pipeline.**

```python
# Wrong: GridSearchCV cannot find a bare parameter name inside a pipeline
param_grid = {"n_estimators": [100, 200]}
```

```python
# Correct: prefix with the step name and a double underscore
param_grid = {"clf__n_estimators": [100, 200]}
```

Inside a pipeline, every hyperparameter must be addressed as `stepname__parameter`. The double underscore is required.

**Mistake 2: Tuning against the test set.**

```python
# Wrong: searching while looking at the test set leaks it into tuning
grid.fit(X_test, y_test)
```

```python
# Correct: tune on training data with cross-validation, test once at the end
grid.fit(X_train, y_train)
grid.predict(X_test)   # single final evaluation
```

The search already cross-validates internally on the training data. The test set is only for the final check, never for tuning.

**Mistake 3: Letting a grid explode in size.**

```python
# Risky: this grid has 5 * 5 * 5 * 4 = 500 combinations, times cv = very slow
param_grid = {
    "clf__n_estimators": [50, 100, 200, 400, 800],
    "clf__max_depth": [2, 4, 6, 8, 10],
    "clf__min_samples_leaf": [1, 2, 4, 8, 16],
    "clf__max_features": ["sqrt", "log2", 0.5, 1.0],
}
```

```python
# Better: use RandomizedSearchCV with n_iter to cap the work
RandomizedSearchCV(pipe, param_dist, n_iter=30, cv=5, random_state=42, n_jobs=-1)
```

Every value you add multiplies the total. When a grid grows large, switch to randomized search and cap the number of trials with `n_iter`.

---

## 7. Exercises

**Exercise 1:** Run a `GridSearchCV` on a gradient boosting pipeline, tuning `clf__n_estimators` over [100, 200] and `clf__learning_rate` over [0.01, 0.1]. Print the best params and best cross-validated score.

**Exercise 2:** Compare the test accuracy of a default `RandomForestClassifier` against a tuned one using the best params from the lesson (`max_depth=None`, `min_samples_leaf=2`, `n_estimators=100`). What do you notice?

**Exercise 3:** Run a `GridSearchCV` on a scaled SVM pipeline, tuning `clf__C` over [0.1, 1, 10] and `clf__kernel` over ["linear", "rbf"]. Print the best params, best cross-validated score, and test accuracy.

---

## 8. Solutions

**Solution for Exercise 1:**

```python
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.model_selection import GridSearchCV

gb_pipe = Pipeline([("pre", preprocessor), ("clf", GradientBoostingClassifier(random_state=42))])
gb_grid = GridSearchCV(
    gb_pipe,
    {"clf__n_estimators": [100, 200], "clf__learning_rate": [0.01, 0.1]},
    cv=5, scoring="accuracy", n_jobs=-1,
)
gb_grid.fit(X_train, y_train)
print("best params:", gb_grid.best_params_)
print("best cv score:", round(gb_grid.best_score_, 4))
```

Output:

```
best params: {'clf__learning_rate': 0.1, 'clf__n_estimators': 200}
best cv score: 0.8204
```

The search prefers the higher learning rate (0.1) paired with more trees (200), reaching a cross-validated 0.8204. With only 4 combinations, grid search is a perfect fit for this small space.

**Solution for Exercise 2:**

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

default_rf = Pipeline([("pre", preprocessor), ("clf", RandomForestClassifier(random_state=42))])
default_rf.fit(X_train, y_train)
print("default test:", round(accuracy_score(y_test, default_rf.predict(X_test)), 4))

tuned_rf = Pipeline([("pre", preprocessor), ("clf", RandomForestClassifier(
    max_depth=None, min_samples_leaf=2, n_estimators=100, random_state=42))])
tuned_rf.fit(X_train, y_train)
print("tuned test:", round(accuracy_score(y_test, tuned_rf.predict(X_test)), 4))
```

Output:

```
default test: 0.8268
tuned test: 0.8156
```

Surprisingly, the default scores higher than the tuned model on this particular test split, even though the tuned settings won in cross-validation. This is the split-noise point from the lesson: a single test number can disagree with the more reliable cross-validated result. Trust the cross-validation, not one split.

**Solution for Exercise 3:**

```python
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC

scaled_pre = ColumnTransformer([
    ("num", Pipeline([("imp", SimpleImputer(strategy="median")), ("sc", StandardScaler())]), numeric),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
])
svm_pipe = Pipeline([("pre", scaled_pre), ("clf", SVC(random_state=42))])
svm_grid = GridSearchCV(
    svm_pipe,
    {"clf__C": [0.1, 1, 10], "clf__kernel": ["linear", "rbf"]},
    cv=5, scoring="accuracy", n_jobs=-1,
)
svm_grid.fit(X_train, y_train)
print("best params:", svm_grid.best_params_)
print("best cv score:", round(svm_grid.best_score_, 4))
print("test accuracy:", round(accuracy_score(y_test, svm_grid.predict(X_test)), 4))
```

Output:

```
best params: {'clf__C': 10, 'clf__kernel': 'rbf'}
best cv score: 0.8259
test accuracy: 0.7989
```

The search picks an `rbf` kernel with `C=10`, reaching a cross-validated 0.8259. Note the SVM pipeline keeps its scaler, which `GridSearchCV` correctly re-fits inside every fold, so there is no leakage during the search.

---

## Next Up - Lesson 8

You can now tune models automatically. `GridSearchCV` tries every combination in a small space, `RandomizedSearchCV` samples efficiently from a large one, and both use cross-validation to choose honestly while you save the test set for a final check. Tuning plus cross-validation is the professional workflow for getting the most from a model.

In Lesson 8, you move into Module 4 and deepen your evaluation skills. Accuracy hides important details, so you will learn ROC curves and the AUC score, how to adjust the decision threshold, and how to read the precision-recall trade-off, giving you a much richer picture of classifier performance.
