## 1. Before You Begin

In Lesson 3 you built a random forest, an ensemble that grows many trees independently and averages their votes. Gradient boosting is also an ensemble of trees, but it works in a fundamentally different way, and that difference often makes it one of the most accurate models you can use on tabular data. It is the engine behind many winning solutions on data science competitions.

Where a random forest builds its trees in parallel and lets them vote, gradient boosting builds trees one at a time in sequence, and each new tree focuses on fixing the mistakes the previous trees made. In this lesson you will train a gradient boosting model, see how its two key settings (learning rate and number of trees) interact, and meet the faster modern version, `HistGradientBoostingClassifier`.

### What You'll Build

A gradient boosting pipeline for the Titanic data, compared against your random forest, plus experiments showing how the learning rate and the number of trees affect performance, and a look at the faster histogram-based booster.

### What You'll Learn

- ✅ How gradient boosting differs from a random forest
- ✅ How sequential trees correct each other's errors
- ✅ How to build a `GradientBoostingClassifier` in a pipeline
- ✅ How the learning rate and number of trees trade off
- ✅ How to use the faster `HistGradientBoostingClassifier`
- ✅ When to prefer boosting over a random forest

### What You'll Need

- The random forest from Lesson 3
- The pipeline skills from Lesson 1
- A Colab notebook with scikit-learn and seaborn

---

## 2. How Gradient Boosting Differs from a Random Forest

Both models are ensembles of decision trees, but the way they build and combine those trees is opposite, and understanding the contrast is the key to this lesson.

- **Random forest (bagging).** Builds many deep trees independently, each on a random sample of the data, then averages their votes. The trees do not talk to each other. This reduces variance.
- **Gradient boosting.** Builds many shallow trees in sequence. Each new tree is trained to correct the errors (the residuals) left by the trees before it. The trees are deeply connected. This reduces bias.

A useful analogy: a random forest is a committee where everyone votes at once and you take the average. Gradient boosting is a relay of students, where each student studies the mistakes the previous one made and tries to fix them. Because each tree builds on the last, boosting can reach very high accuracy, but it is also more sensitive to its settings and can overfit if pushed too hard. That sensitivity is why the learning rate matters so much.

---

## 3. Build a Gradient Boosting Model

Gradient boosting is tree-based, so like the random forest it needs no scaling. The pipeline structure is identical; only the classifier changes.

### Step 1: Set up and train

```python
import pandas as pd
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder
from sklearn.ensemble import GradientBoostingClassifier
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
preprocessor = ColumnTransformer([
    ("num", SimpleImputer(strategy="median"), numeric),
    ("cat", Pipeline([
        ("imp", SimpleImputer(strategy="most_frequent")),
        ("oh", OneHotEncoder(handle_unknown="ignore")),
    ]), categorical),
])

gb = Pipeline([("pre", preprocessor), ("clf", GradientBoostingClassifier(random_state=42))])
gb.fit(X_train, y_train)
print("gradient boosting test accuracy:", round(accuracy_score(y_test, gb.predict(X_test)), 4))
```

Output:

```
gradient boosting test accuracy: 0.7989
```

`GradientBoostingClassifier(random_state=42)` uses sensible defaults: 100 trees and a learning rate of 0.1. The pipeline is exactly the tree-based one from Lesson 3 with the classifier swapped. On this single test split it scores 0.7989.

### Step 2: Compare with cross-validation

A single split is noisy, so check the cross-validated score for a fairer read:

```python
from sklearn.model_selection import cross_val_score

print("gb cv mean:", round(cross_val_score(gb, X_train, y_train, cv=5).mean(), 4))
```

Output:

```
gb cv mean: 0.8175
```

Across 5 folds, gradient boosting averages 0.8175, noticeably higher than its single-split number and competitive with the best models you have tried on this data. This is a reminder to always judge with cross-validation, not one split, which you will study fully in Lesson 6.

---

## 4. The Learning Rate and Number of Trees

Gradient boosting's two most important settings work together. The `learning_rate` controls how much each new tree corrects the previous errors, and `n_estimators` sets how many trees there are. They trade off against each other.

### Step 1: Vary the learning rate

```python
for lr in [0.01, 0.1, 0.5, 1.0]:
    model = Pipeline([("pre", preprocessor), ("clf", GradientBoostingClassifier(learning_rate=lr, random_state=42))])
    model.fit(X_train, y_train)
    print(f"learning_rate={lr}: {round(accuracy_score(y_test, model.predict(X_test)), 4)}")
```

Output:

```
learning_rate=0.01: 0.7933
learning_rate=0.1: 0.7989
learning_rate=0.5: 0.8045
learning_rate=1.0: 0.8212
```

A small learning rate means each tree makes a tiny correction, so the model learns slowly and cautiously. A large rate lets each tree make bold corrections. The catch is that a high learning rate with many trees can overfit, while a low rate needs more trees to reach full strength. The standard advice is to use a smallish learning rate (like 0.05 or 0.1) together with enough trees, then validate. Do not read too much into the single-split numbers here; the real tuning happens with cross-validation in Lesson 7.

### Step 2: Vary the number of trees

```python
for n in [10, 50, 100, 300]:
    model = Pipeline([("pre", preprocessor), ("clf", GradientBoostingClassifier(n_estimators=n, random_state=42))])
    model.fit(X_train, y_train)
    print(f"n_estimators={n}: {round(accuracy_score(y_test, model.predict(X_test)), 4)}")
```

Output:

```
n_estimators=10: 0.7989
n_estimators=50: 0.8101
n_estimators=100: 0.7989
n_estimators=300: 0.8156
```

Unlike a random forest, where more trees almost always helps or plateaus harmlessly, boosting with too many trees can eventually start overfitting, because each tree keeps chasing the training errors. The number of trees and the learning rate must be tuned together: lower the learning rate and you usually want more trees, raise it and you want fewer. Lesson 7 will show you how to search for the best combination automatically.

---

## 5. The Faster Modern Booster

scikit-learn includes a newer, much faster gradient boosting implementation called `HistGradientBoostingClassifier`. It buckets feature values into histograms to train far quicker on larger datasets, and it even handles missing values on its own.

```python
from sklearn.ensemble import HistGradientBoostingClassifier

hgb = Pipeline([("pre", preprocessor), ("clf", HistGradientBoostingClassifier(random_state=42))])
hgb.fit(X_train, y_train)
print("HistGradientBoosting test accuracy:", round(accuracy_score(y_test, hgb.predict(X_test)), 4))
```

Output:

```
HistGradientBoosting test accuracy: 0.8268
```

`HistGradientBoostingClassifier` is a drop-in alternative that scores 0.8268 here, the best of the boosters on this split, while training faster. For anything beyond small datasets, it is usually the gradient boosting class to reach for. If you later explore libraries like XGBoost or LightGBM, you will find they use the same histogram idea and the same boosting principle you learned here.

---

## 6. When to Prefer Boosting over a Random Forest

Both are excellent tree ensembles, so how do you choose? A few guidelines help, though the honest answer is always to validate both on your data.

- **Boosting often reaches higher accuracy** on structured, tabular data, which is why it dominates competitions. If squeezing out the last bit of accuracy matters, try it.
- **Random forests are more forgiving.** They work well with little tuning and are harder to overfit, making them a great first baseline.
- **Boosting needs more careful tuning.** The learning rate, number of trees, and tree depth interact, so boosting rewards (and demands) the hyperparameter tuning you will learn in Lesson 7.
- **Both are tree-based,** so neither needs scaling and both give feature importances.

On the small Titanic dataset the boosters and the simpler models all land in a similar range, which once again shows that more sophistication does not guarantee a better score on every problem. Use boosting when you have enough data and the accuracy gain justifies the extra tuning effort.

---

## 7. Fix the Errors in Your Code

These mistakes are common when moving to gradient boosting.

**Mistake 1: Cranking the learning rate and tree count both very high.**

```python
# Risky: a high learning rate with many trees overfits aggressively
GradientBoostingClassifier(learning_rate=1.0, n_estimators=1000)
```

```python
# Better: a modest learning rate with a sensible number of trees, then tune
GradientBoostingClassifier(learning_rate=0.1, n_estimators=200, random_state=42)
```

Boosting keeps correcting training errors, so an aggressive setup memorizes noise. Use a moderate learning rate and validate before pushing the tree count up.

**Mistake 2: Expecting more trees to always help, as in a random forest.**

```python
# Wrong assumption: "more trees is always safer" (true for forests, not boosting)
GradientBoostingClassifier(n_estimators=5000)
```

```python
# Better: tune n_estimators with the learning rate, watching validation scores
GradientBoostingClassifier(n_estimators=300, learning_rate=0.05, random_state=42)
```

In a forest, extra trees plateau harmlessly. In boosting, too many trees can overfit, so the count is something to tune, not maximize.

**Mistake 3: Reaching for plain GradientBoosting on a large dataset.**

```python
# Slow: the classic implementation is fine for small data but crawls on large data
GradientBoostingClassifier()
```

```python
# Faster: the histogram-based version scales much better and handles NaNs
HistGradientBoostingClassifier()
```

For larger datasets, prefer `HistGradientBoostingClassifier`. It trains far faster and is the modern default.

---

## 8. Exercises

**Exercise 1:** Build a `GradientBoostingClassifier` pipeline with `n_estimators=200` and `learning_rate=0.05`. Print its test accuracy.

**Exercise 2:** Build a `HistGradientBoostingClassifier` pipeline and print its 5-fold cross-validated accuracy on the training data.

**Exercise 3:** Compare the 5-fold cross-validated accuracy of `GradientBoostingClassifier` against a `RandomForestClassifier(n_estimators=200)` on the training data. Which wins here?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import accuracy_score

gb = Pipeline([
    ("pre", preprocessor),
    ("clf", GradientBoostingClassifier(n_estimators=200, learning_rate=0.05, random_state=42)),
])
gb.fit(X_train, y_train)
print("test accuracy:", round(accuracy_score(y_test, gb.predict(X_test)), 4))
```

Output:

```
test accuracy: 0.8045
```

Pairing 200 trees with a gentle learning rate of 0.05 gives 0.8045 on this split. The lower learning rate is balanced by the larger number of trees, which is the typical way to configure a booster.

**Solution for Exercise 2:**

```python
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.model_selection import cross_val_score

hgb = Pipeline([("pre", preprocessor), ("clf", HistGradientBoostingClassifier(random_state=42))])
print("cv mean:", round(cross_val_score(hgb, X_train, y_train, cv=5).mean(), 4))
```

Output:

```
cv mean: 0.8091
```

The histogram booster cross-validates at about 0.8091 here. Its real advantage shows on larger datasets, where it trains dramatically faster than the classic implementation while staying just as accurate.

**Solution for Exercise 3:**

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import cross_val_score

gb = Pipeline([("pre", preprocessor), ("clf", GradientBoostingClassifier(random_state=42))])
rf = Pipeline([("pre", preprocessor), ("clf", RandomForestClassifier(n_estimators=200, random_state=42))])

print("gb cv:", round(cross_val_score(gb, X_train, y_train, cv=5).mean(), 4))
print("rf cv:", round(cross_val_score(rf, X_train, y_train, cv=5).mean(), 4))
```

Output:

```
gb cv: 0.8175
rf cv: 0.7937
```

Here gradient boosting (0.8175) edges out the random forest (0.7937) in cross-validation. Boosting's sequential error-correction pays off even on this small dataset, though the margin is modest and could shift with tuning. As always, validate on your own data rather than assuming one ensemble is universally better.

---

## Next Up - Lesson 5

You now understand both major tree ensembles: random forests that average independent trees, and gradient boosting that builds trees in sequence to correct each other. You also met the fast `HistGradientBoostingClassifier` and saw how the learning rate and tree count must be balanced.

In Lesson 5, you meet a very different kind of model: the support vector machine. Instead of trees, an SVM finds the widest possible boundary between classes, and with kernels it can carve out curved boundaries too. You will see how it works, why it needs feature scaling, and where it shines.
