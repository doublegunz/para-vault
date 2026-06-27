## 1. Before You Begin

In the beginner course you met the decision tree, a model that asks a series of yes-or-no questions. A single tree is easy to understand but has a weakness: it can be unstable and overfit, memorizing quirks of the training data. In this lesson you learn a model that fixes that weakness by combining many trees, the random forest. It is one of the most reliable, widely used models in all of classical machine learning.

The idea behind a random forest is an ensemble: instead of trusting one model, you train many slightly different trees and let them vote. The errors of individual trees tend to cancel out, leaving a prediction that is more accurate and more stable than any single tree. Best of all, it drops straight into the pipeline you already know.

### What You'll Build

A random forest pipeline for the Titanic data that outperforms a single decision tree, plus an exploration of how the number of trees affects accuracy and a ranking of which features the forest relied on most.

### What You'll Learn

- ✅ What an ensemble is and how bagging works
- ✅ How a random forest combines many trees by voting
- ✅ How to build a `RandomForestClassifier` in a pipeline
- ✅ Why more trees usually help, up to a point
- ✅ How to read a forest's feature importances
- ✅ The strengths and limits of random forests

### What You'll Need

- The pipeline skills from Lesson 1
- The decision tree from the beginner course
- A Colab notebook with scikit-learn and seaborn

---

## 2. What Is a Random Forest?

A random forest is an ensemble of decision trees. An ensemble combines many models so that their collective decision beats any individual one, the same reason a crowd's average guess often beats a single expert. The technique a random forest uses is called bagging, short for bootstrap aggregating, and it has two sources of randomness.

- **Random rows (bootstrap).** Each tree is trained on a random sample of the training rows, drawn with replacement, so every tree sees a slightly different dataset.
- **Random features.** At each split, a tree may only choose from a random subset of the features, which stops every tree from looking the same.

Because of this double randomness, the trees make different mistakes. When you average their votes (for classification, a majority vote), the random errors cancel out while the real signal reinforces. The result is a model with much lower variance than a single tree: it overfits far less and generalizes better. You give up some of the easy interpretability of one tree, but you gain accuracy and stability.

---

## 3. Build a Random Forest

A random forest uses the same pipeline structure you already know. One nice property: because it is tree-based, it does not need feature scaling, so the preprocessing is even simpler.

### Step 1: Set up the pipeline

```python
import pandas as pd
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder

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
```

This is the Lesson 1 preprocessor with one change: there is no `StandardScaler` in the numeric branch, because trees split on thresholds and do not care about feature scale. The numeric columns just need imputation; the categorical ones still need imputation and one-hot encoding.

### Step 2: Train the forest and compare to a single tree

```python
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

tree = Pipeline([("pre", preprocessor), ("clf", DecisionTreeClassifier(max_depth=4, random_state=42))])
tree.fit(X_train, y_train)
print("single tree:", round(accuracy_score(y_test, tree.predict(X_test)), 4))

forest = Pipeline([("pre", preprocessor), ("clf", RandomForestClassifier(n_estimators=200, random_state=42))])
forest.fit(X_train, y_train)
print("random forest:", round(accuracy_score(y_test, forest.predict(X_test)), 4))
```

Output:

```
single tree: 0.7877
random forest: 0.8212
```

The only change between the two pipelines is the classifier. `RandomForestClassifier(n_estimators=200)` builds 200 trees and averages their votes. On this test split it scores 0.8212 versus the single tree's 0.7877, a clear improvement from the ensemble effect. `random_state=42` keeps the randomness reproducible.

---

## 4. Why More Trees Help

The `n_estimators` argument sets how many trees the forest grows. More trees mean more votes to average, which generally improves and stabilizes the prediction up to a point of diminishing returns.

```python
for n in [1, 10, 50, 200]:
    model = Pipeline([("pre", preprocessor), ("clf", RandomForestClassifier(n_estimators=n, random_state=42))])
    model.fit(X_train, y_train)
    print(f"n_estimators={n}: {round(accuracy_score(y_test, model.predict(X_test)), 4)}")
```

Output:

```
n_estimators=1: 0.7151
n_estimators=10: 0.8101
n_estimators=50: 0.8045
n_estimators=200: 0.8212
```

With a single tree (`n_estimators=1`), the forest is just one bootstrapped tree and scores a weak 0.7151. Jumping to 10 trees lifts it sharply, and by 200 it settles around 0.82. The accuracy does not climb forever; after enough trees the votes stabilize and adding more mostly costs computation. A common practice is to use a few hundred trees, which is plenty for most problems.

---

## 5. Feature Importances

Like a single tree, a random forest can tell you how much each feature contributed to its decisions, averaged across all the trees. This is one of the most useful things a forest gives you for free.

```python
forest.fit(X_train, y_train)
feature_names = forest.named_steps["pre"].get_feature_names_out()
importances = pd.Series(
    forest.named_steps["clf"].feature_importances_, index=feature_names
).sort_values(ascending=False)
print(importances.round(4))
```

Output:

```
num__fare          0.2617
num__age           0.2428
cat__sex_male      0.1563
cat__sex_female    0.1366
num__pclass        0.0834
num__sibsp         0.0468
num__parch         0.0369
cat__embarked_S    0.0172
cat__embarked_C    0.0115
cat__embarked_Q    0.0068
dtype: float64
```

`feature_importances_` scores each feature by how much it reduced impurity across the forest, and the scores sum to 1. Here `fare` and `age` are the top numeric drivers, with `sex` close behind once you add its two one-hot columns together. Importances are great for understanding your model and for deciding which features to keep, though remember they reflect this dataset and model, not universal truth.

---

## 6. Strengths and Limits of Random Forests

Random forests are a strong default, but knowing their trade-offs helps you choose wisely rather than reaching for them reflexively.

Strengths:

- **Accurate and robust.** They usually beat a single tree and resist overfitting thanks to averaging.
- **Low maintenance.** They need no scaling, handle mixed feature types well, and work decently with little tuning.
- **Informative.** Feature importances come built in.

Limits:

- **Less interpretable.** You cannot read 200 trees the way you can read one. You lose the simple flowchart explanation.
- **Slower and larger.** Training and storing hundreds of trees costs more time and memory than one model.
- **Not always the winner.** On small, simple datasets a well-tuned single tree or a linear model can match or beat a forest. On the Titanic data, for instance, a shallow tree cross-validates about as well as the default forest, so always validate rather than assuming the fancier model wins.

The practical takeaway: reach for a random forest as a strong, reliable baseline, but still compare it against simpler models with proper validation. Power is not the same as the best fit for every problem.

---

## 7. Fix the Errors in Your Code

These mistakes are common when using random forests.

**Mistake 1: Adding a scaler that the forest does not need (and thinking it is required).**

```python
# Unnecessary: scaling does nothing for tree-based models
("num", Pipeline([("imp", SimpleImputer(strategy="median")), ("sc", StandardScaler())]), numeric)
```

```python
# Simpler: trees split on thresholds, so imputation alone is enough
("num", SimpleImputer(strategy="median"), numeric)
```

Scaling a forest is harmless but pointless. Leaving it out keeps the pipeline simpler and faster. (Distance-based and linear models still need it, as you learned in the beginner course.)

**Mistake 2: Reading importances without combining the pipeline.**

```python
# Wrong: feature_importances_ has no column names on its own
forest.named_steps["clf"].feature_importances_   # just an array of numbers
```

```python
# Correct: pair them with the transformed feature names from the preprocessor
names = forest.named_steps["pre"].get_feature_names_out()
pd.Series(forest.named_steps["clf"].feature_importances_, index=names).sort_values(ascending=False)
```

The raw importances are an unlabeled array. Pair them with `get_feature_names_out()` so you know which feature each number belongs to.

**Mistake 3: Forgetting random_state and being confused by changing results.**

```python
# Risky: results shift slightly every run because of the built-in randomness
RandomForestClassifier(n_estimators=200)
```

```python
# Better: fix random_state for reproducible results
RandomForestClassifier(n_estimators=200, random_state=42)
```

A forest is random by design. Setting `random_state` makes your accuracy and importances reproducible, which is essential when comparing models.

---

## 8. Exercises

**Exercise 1:** Build a random forest pipeline with `n_estimators=50` and `max_depth=5` on the Titanic data. Print its test accuracy.

**Exercise 2:** Using your model from Exercise 1, print the top 3 feature importances. Which feature dominates when the trees are shallower?

**Exercise 3:** Compare the 5-fold cross-validated accuracy of a single `DecisionTreeClassifier(max_depth=4)` against a `RandomForestClassifier(n_estimators=200)` on the training data. Are you surprised by the result?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

rf = Pipeline([
    ("pre", preprocessor),
    ("clf", RandomForestClassifier(n_estimators=50, max_depth=5, random_state=42)),
])
rf.fit(X_train, y_train)
print("test accuracy:", round(accuracy_score(y_test, rf.predict(X_test)), 4))
```

Output:

```
test accuracy: 0.8045
```

Limiting each tree to `max_depth=5` constrains the forest, giving 0.8045 on this split. Shallower trees are simpler and can generalize well, though here the default unlimited-depth forest from the lesson did a touch better.

**Solution for Exercise 2:**

```python
names = rf.named_steps["pre"].get_feature_names_out()
importances = pd.Series(
    rf.named_steps["clf"].feature_importances_, index=names
).sort_values(ascending=False)
print(importances.head(3).round(4))
```

Output:

```
cat__sex_male      0.3099
cat__sex_female    0.2094
num__fare          0.1531
dtype: float64
```

When the trees are shallow (`max_depth=5`), they have fewer splits to spend, so they focus on the single most powerful signal: `sex`. Its two columns dominate, with `fare` a distant third. Compare this to the deep forest in the lesson, where `fare` and `age` ranked highest, and you see that importances depend on the model's settings.

**Solution for Exercise 3:**

```python
from sklearn.model_selection import cross_val_score
from sklearn.tree import DecisionTreeClassifier

tree = Pipeline([("pre", preprocessor), ("clf", DecisionTreeClassifier(max_depth=4, random_state=42))])
forest = Pipeline([("pre", preprocessor), ("clf", RandomForestClassifier(n_estimators=200, random_state=42))])

print("tree cv:", round(cross_val_score(tree, X_train, y_train, cv=5).mean(), 4))
print("forest cv:", round(cross_val_score(forest, X_train, y_train, cv=5).mean(), 4))
```

Output:

```
tree cv: 0.8175
forest cv: 0.7937
```

Surprise: the shallow single tree actually cross-validates slightly higher (0.8175) than the default random forest (0.7937) on this data. The Titanic dataset is small and its signal is dominated by a few features, so a constrained tree is hard to beat. This is the honest reality the lesson warned about: a more powerful model is not guaranteed to win, which is exactly why you validate instead of assume.

---

## Next Up - Lesson 4

You now have the random forest in your toolkit: an ensemble of trees that vote together for accuracy and stability, with feature importances built in. You also saw, honestly, that it does not always beat a simpler model, so you keep validating.

In Lesson 4, you meet another powerful ensemble that often tops leaderboards: gradient boosting. Where a random forest builds many trees independently and averages them, gradient boosting builds trees in sequence, each one correcting the mistakes of the last. You will see how it differs and when to prefer it.
