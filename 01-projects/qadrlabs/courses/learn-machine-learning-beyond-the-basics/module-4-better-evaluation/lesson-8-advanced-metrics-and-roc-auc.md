## 1. Before You Begin

In the beginner course you measured classifiers with accuracy, precision, recall, and the confusion matrix. Those are essential, but they all describe a model at one fixed decision point: the default rule that says "if the predicted probability is at least 0.5, call it positive". This lesson goes deeper. You will see that a classifier actually outputs probabilities, that you can move the 0.5 threshold to trade precision for recall, and that ROC curves and the AUC score summarize a model's quality across all possible thresholds at once.

This richer view matters in the real world. A fraud detector and a spam filter both need different thresholds depending on which mistake is costlier, and AUC lets you compare models without committing to any single threshold. By the end you will evaluate classifiers like a professional.

### What You'll Build

An analysis of a logistic regression classifier on the Titanic data that examines its predicted probabilities, shows how moving the decision threshold shifts precision and recall, and computes the ROC curve and AUC score to judge the model across all thresholds.

### What You'll Learn

- ✅ How classifiers produce probabilities, not just labels
- ✅ How the decision threshold controls the precision-recall trade-off
- ✅ How to move the threshold to favor recall or precision
- ✅ What an ROC curve shows
- ✅ What the AUC score measures and why it is threshold-independent
- ✅ How to compare models with AUC

### What You'll Need

- Precision and recall from the beginner course
- The pipeline skills from Lesson 1
- A Colab notebook with scikit-learn and seaborn

---

## 2. Classifiers Output Probabilities

When you call `predict`, a classifier gives you a label like 0 or 1. But under the hood it first computes a probability, then applies a threshold of 0.5 to decide the label. Looking at the raw probabilities, with `predict_proba`, unlocks everything in this lesson.

```python
import pandas as pd
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.linear_model import LogisticRegression

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
    ("num", Pipeline([("imp", SimpleImputer(strategy="median")), ("sc", StandardScaler())]), numeric),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
])

clf = Pipeline([("pre", preprocessor), ("clf", LogisticRegression(max_iter=1000))])
clf.fit(X_train, y_train)

proba = clf.predict_proba(X_test)[:, 1]
print("first 5 survival probabilities:", proba[:5].round(3))
```

Output:

```
first 5 survival probabilities: [0.068 0.048 0.155 0.036 0.672]
```

`predict_proba(X_test)` returns two columns, the probability of class 0 and class 1. We take `[:, 1]`, the probability of survival. The first four passengers are very unlikely to survive (around 0.04 to 0.16), while the fifth is more likely (0.672). The default `predict` would label anyone at or above 0.5 as a survivor. But that 0.5 cutoff is a choice, and you can change it.

---

## 3. Moving the Decision Threshold

The threshold is the dial that trades precision against recall. Lowering it labels more people positive (catching more true positives but also more false alarms), while raising it does the opposite. Let us watch this directly.

### Step 1: The default threshold of 0.5

```python
from sklearn.metrics import precision_score, recall_score, confusion_matrix

pred_default = (proba >= 0.5).astype(int)
print("precision:", round(precision_score(y_test, pred_default), 4))
print("recall:", round(recall_score(y_test, pred_default), 4))
print(confusion_matrix(y_test, pred_default))
```

Output:

```
precision: 0.7931
recall: 0.6667
[[98 12]
 [23 46]]
```

At the standard 0.5 cutoff, precision is 0.7931 and recall is 0.6667. The model catches two thirds of the actual survivors. `(proba >= 0.5).astype(int)` reproduces exactly what `predict` does. Now change the dial.

### Step 2: Lower the threshold to favor recall

```python
pred_low = (proba >= 0.3).astype(int)
print("precision:", round(precision_score(y_test, pred_low), 4))
print("recall:", round(recall_score(y_test, pred_low), 4))
```

Output:

```
precision: 0.6548
recall: 0.7971
```

Dropping the threshold to 0.3 means you call someone a survivor on weaker evidence. Recall jumps to 0.7971 (you catch about 80 percent of survivors) but precision falls to 0.6548 (more of your positive calls are wrong). You would lower the threshold when missing a positive is costly, like screening for a disease.

### Step 3: Raise the threshold to favor precision

```python
pred_high = (proba >= 0.7).astype(int)
print("precision:", round(precision_score(y_test, pred_high), 4))
print("recall:", round(recall_score(y_test, pred_high), 4))
```

Output:

```
precision: 0.8974
recall: 0.5072
```

Raising the threshold to 0.7 demands strong evidence before calling someone a survivor. Now precision climbs to 0.8974 (your positive calls are usually right) but recall drops to 0.5072 (you miss about half the survivors). You would raise the threshold when a false positive is costly, like an automated spam filter. The threshold is a business decision, not a fixed law.

---

## 4. The ROC Curve

Rather than checking thresholds one at a time, the ROC curve plots a model's behavior across all of them at once. It charts the true positive rate (recall) against the false positive rate as the threshold sweeps from high to low.

```python
from sklearn.metrics import roc_curve

fpr, tpr, thresholds = roc_curve(y_test, proba)
print("number of thresholds evaluated:", len(thresholds))
```

Output:

```
number of thresholds evaluated: 61
```

`roc_curve` returns the false positive rate (`fpr`), the true positive rate (`tpr`), and the `thresholds` it used, here 61 of them. To visualize it:

```python
import matplotlib.pyplot as plt

plt.plot(fpr, tpr, label="ROC curve")
plt.plot([0, 1], [0, 1], "--", label="random guess")
plt.xlabel("False Positive Rate")
plt.ylabel("True Positive Rate")
plt.legend()
plt.show()
```

The plot shows a curve bowing toward the top-left corner. Each point on it corresponds to one threshold: the top-right is a very low threshold (catch everyone, many false alarms), the bottom-left is a very high threshold (catch almost no one, few false alarms). The dashed diagonal is what random guessing would look like. The further the curve bows above that diagonal toward the top-left, the better the model is at separating the classes across all thresholds.

---

## 5. The AUC Score

The ROC curve is a picture; AUC turns it into a single number. AUC stands for Area Under the (ROC) Curve, and it ranges from 0.5 (random guessing) to 1.0 (perfect separation).

```python
from sklearn.metrics import roc_auc_score

print("AUC:", round(roc_auc_score(y_test, proba), 4))
```

Output:

```
AUC: 0.8437
```

An AUC of 0.8437 has a concrete meaning: if you pick one random survivor and one random non-survivor, there is about an 84 percent chance the model assigns the survivor a higher probability. The key advantage of AUC is that it is threshold-independent. It judges how well the model ranks examples by probability, regardless of where you set the cutoff. That makes it ideal for comparing models, especially on imbalanced data where accuracy is misleading. A rough reading guide: 0.5 is useless, 0.7 to 0.8 is acceptable, 0.8 to 0.9 is good, and above 0.9 is excellent.

---

## 6. When to Use Which Metric

You now have a toolbox of classification metrics. Choosing the right one comes down to what you care about for the specific problem.

- **Accuracy:** fine when classes are balanced and every error costs the same. Misleading when classes are imbalanced.
- **Precision and recall:** use when one type of error matters more. Favor recall to avoid missing positives, precision to avoid false alarms.
- **F1-score:** a single balance of precision and recall, handy when you have no strong preference.
- **AUC:** the best single number for comparing models, because it captures ranking quality across all thresholds and is robust to class imbalance.
- **The threshold:** tune it separately, after choosing a model, to hit the precision-recall balance your application needs.

A common workflow is to compare models by AUC (or cross-validated AUC), pick the best one, then choose its operating threshold based on the real-world cost of false positives versus false negatives. Metric choice is part of the modeling decision, not an afterthought.

---

## 7. Fix the Errors in Your Code

These mistakes are common with probability-based metrics.

**Mistake 1: Passing predicted labels to roc_auc_score instead of probabilities.**

```python
# Wrong: AUC needs probabilities (or scores), not hard 0/1 labels
roc_auc_score(y_test, clf.predict(X_test))
```

```python
# Correct: pass the probability of the positive class
roc_auc_score(y_test, clf.predict_proba(X_test)[:, 1])
```

AUC measures how well the model ranks examples by probability. Feeding it hard labels throws away that ranking and gives a misleading number.

**Mistake 2: Taking the wrong probability column.**

```python
# Wrong: column 0 is the probability of the negative class
proba = clf.predict_proba(X_test)[:, 0]
```

```python
# Correct: column 1 is the probability of the positive class (survived)
proba = clf.predict_proba(X_test)[:, 1]
```

`predict_proba` returns one column per class. For binary problems you almost always want column 1, the positive class.

**Mistake 3: Treating accuracy as the only metric on imbalanced data.**

```python
# Risky: high accuracy can hide poor detection of the rare class
accuracy_score(y_test, clf.predict(X_test))
```

```python
# Better: also report AUC, precision, and recall
roc_auc_score(y_test, clf.predict_proba(X_test)[:, 1])
```

When one class is rare, accuracy can look great while the model misses most positives. AUC, precision, and recall reveal what accuracy hides, which is the subject of the next lesson.

---

## 8. Exercises

**Exercise 1:** Train a random forest pipeline and compute its AUC on the test set. How does it compare to the logistic regression AUC of 0.8437?

**Exercise 2:** Using the logistic regression probabilities, apply a threshold of 0.4 and print the resulting precision and recall. How do they sit between the 0.3 and 0.5 results from the lesson?

**Exercise 3:** Compare the AUC of logistic regression against a gradient boosting model on the test set. Which ranks survivors better here?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score

rf_pre = ColumnTransformer([
    ("num", SimpleImputer(strategy="median"), numeric),
    ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
])
rf = Pipeline([("pre", rf_pre), ("clf", RandomForestClassifier(n_estimators=200, random_state=42))])
rf.fit(X_train, y_train)
print("RF AUC:", round(roc_auc_score(y_test, rf.predict_proba(X_test)[:, 1]), 4))
```

Output:

```
RF AUC: 0.8315
```

The random forest's AUC of 0.8315 is slightly below logistic regression's 0.8437 on this split, meaning logistic regression ranks survivors marginally better here. Note trees do not need scaling, so this pipeline drops the scaler.

**Solution for Exercise 2:**

```python
pred = (proba >= 0.4).astype(int)
print("precision:", round(precision_score(y_test, pred), 4))
print("recall:", round(recall_score(y_test, pred), 4))
```

Output:

```
precision: 0.7297
recall: 0.7826
```

A threshold of 0.4 sits neatly between the lesson's 0.3 and 0.5 results: recall (0.7826) is higher than at 0.5 but lower than at 0.3, while precision (0.7297) moves the opposite way. This confirms the smooth trade-off, you can dial in any balance you need.

**Solution for Exercise 3:**

```python
from sklearn.ensemble import GradientBoostingClassifier

gb = Pipeline([("pre", rf_pre), ("clf", GradientBoostingClassifier(random_state=42))])
gb.fit(X_train, y_train)

print("logreg AUC:", round(roc_auc_score(y_test, clf.predict_proba(X_test)[:, 1]), 4))
print("gb AUC:", round(roc_auc_score(y_test, gb.predict_proba(X_test)[:, 1]), 4))
```

Output:

```
logreg AUC: 0.8437
gb AUC: 0.8181
```

On this test split, logistic regression (0.8437) actually ranks survivors better than gradient boosting (0.8181) by AUC. As always, a single split is noisy, so you would confirm with cross-validated AUC before declaring a winner, but it is a useful reminder that the simplest model is sometimes the best ranker.

---

## Next Up - Lesson 9

You now evaluate classifiers across all thresholds, not just one. You can read predicted probabilities, move the decision threshold to trade precision for recall, and use ROC curves and the AUC score to judge and compare models independently of any single cutoff. This is the complete picture of classifier performance.

In Lesson 9, you will tackle a problem where these skills become essential: imbalanced data, where one class vastly outnumbers the other. You will see why accuracy fails completely there and learn techniques like class weighting and resampling to build models that actually detect the rare class.
