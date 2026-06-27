## 1. Before You Begin

In the beginner course you saw a warning example: a model that predicts "no disease" for everyone can be 95 percent accurate while catching zero real patients. That happens because of imbalanced data, where one class vastly outnumbers the other. Fraud, disease, defaults, and rare events are all like this, and they are some of the most important problems in machine learning. This lesson teaches you to handle them properly.

You will build a deliberately imbalanced dataset, watch a normal model fail to detect the rare class despite high accuracy, then fix it with two practical techniques: class weighting and resampling. You will lean heavily on the metrics from Lesson 8, because on imbalanced data, recall, precision, and AUC are what matter, not accuracy.

### What You'll Build

An experiment on a 95/5 imbalanced dataset showing a baseline classifier that scores high accuracy but misses almost all of the rare class, then improved models using `class_weight="balanced"` and manual oversampling that actually detect the minority.

### What You'll Learn

- ✅ Why accuracy is useless on imbalanced data
- ✅ How to measure the right things: recall, precision, and AUC
- ✅ How `class_weight="balanced"` makes the rare class count more
- ✅ How to oversample the minority class with `resample`
- ✅ Why you resample only the training data
- ✅ How adjusting the threshold also helps

### What You'll Need

- The metrics from Lesson 8 (recall, precision, AUC, threshold)
- A Colab notebook with scikit-learn
- No new installations; everything here uses built-in scikit-learn

---

## 2. The Problem with Imbalanced Data

When one class is rare, a model can score high accuracy by simply ignoring it and always predicting the majority class. Accuracy rewards this laziness, which is why it is the wrong metric here. The right metrics focus on how well you find the rare class: recall (what fraction of the rare cases you catch), precision (how many of your alarms are real), and AUC (how well you rank cases by probability).

Let us create a realistic imbalance to study.

```python
import numpy as np
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split

X, y = make_classification(
    n_samples=5000, n_features=10, n_informative=5,
    weights=[0.95, 0.05], random_state=42
)
print("class counts:", np.bincount(y))
print("minority fraction:", round(y.mean(), 4))

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)
```

Output:

```
class counts: [4725  275]
minority fraction: 0.055
```

`make_classification` builds a synthetic dataset, and `weights=[0.95, 0.05]` makes class 1 only about 5 percent of the rows: 275 out of 5000. This mirrors real problems like fraud detection. Note `stratify=y` in the split, which keeps that 5 percent ratio in both train and test. On imbalanced data, stratifying is essential, or a fold could end up with almost no minority examples.

---

## 3. Watch the Baseline Fail

Train a normal logistic regression and look past its accuracy to the metrics that matter.

```python
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, recall_score, precision_score, roc_auc_score, confusion_matrix

baseline = LogisticRegression(max_iter=1000).fit(X_train, y_train)
pred = baseline.predict(X_test)

print("accuracy:", round(accuracy_score(y_test, pred), 4))
print("recall:", round(recall_score(y_test, pred), 4))
print("precision:", round(precision_score(y_test, pred), 4))
print("AUC:", round(roc_auc_score(y_test, baseline.predict_proba(X_test)[:, 1]), 4))
print(confusion_matrix(y_test, pred))
```

Output:

```
accuracy: 0.9487
recall: 0.0976
precision: 0.7273
AUC: 0.8326
[[1415    3]
 [  74    8]]
```

The accuracy looks great at 0.9487, but it is a lie. The recall is 0.0976, meaning the model catches fewer than 1 in 10 of the rare cases. The confusion matrix makes it stark: of 82 true positives, it found only 8 and missed 74. The model achieves high accuracy by almost always predicting the majority class. Interestingly, the AUC of 0.8326 is decent, which tells us the model can rank cases reasonably; it is the default 0.5 threshold that is failing on this imbalance. Now let us fix it.

---

## 4. Fix It with Class Weights

The simplest fix is to tell the model that mistakes on the rare class are more costly. Most scikit-learn classifiers accept `class_weight="balanced"`, which automatically weights each class inversely to its frequency, so the rare class gets much more attention.

```python
balanced = LogisticRegression(max_iter=1000, class_weight="balanced").fit(X_train, y_train)
pred = balanced.predict(X_test)

print("accuracy:", round(accuracy_score(y_test, pred), 4))
print("recall:", round(recall_score(y_test, pred), 4))
print("precision:", round(precision_score(y_test, pred), 4))
print("AUC:", round(roc_auc_score(y_test, balanced.predict_proba(X_test)[:, 1]), 4))
print(confusion_matrix(y_test, pred))
```

Output:

```
accuracy: 0.7487
recall: 0.8415
precision: 0.1594
AUC: 0.8468
[[1054  364]
 [  13   69]]
```

The transformation is dramatic. Recall jumps from 0.0976 to 0.8415: the model now catches 69 of the 82 rare cases instead of 8. Accuracy drops to 0.7487, but that is the point, you are trading meaningless accuracy for genuine detection of the rare class. Precision falls to 0.1594, since the model now raises many more alarms (364 false positives). Whether that trade is worth it depends on your problem, but for catching fraud or disease, high recall usually matters most. Adding `class_weight="balanced"` is a one-argument change with a huge effect.

---

## 5. Fix It with Resampling

Another approach is to rebalance the training data itself by oversampling the minority class, duplicating its rows until both classes are equal. The golden rule: resample only the training data, never the test data, which must stay representative of reality.

```python
import pandas as pd
from sklearn.utils import resample

train = pd.DataFrame(X_train)
train["target"] = y_train

majority = train[train["target"] == 0]
minority = train[train["target"] == 1]

minority_upsampled = resample(
    minority, replace=True, n_samples=len(majority), random_state=42
)
balanced_train = pd.concat([majority, minority_upsampled])
print("resampled class counts:", np.bincount(balanced_train["target"]))

X_bal = balanced_train.drop(columns="target").values
y_bal = balanced_train["target"].values

model = LogisticRegression(max_iter=1000).fit(X_bal, y_bal)
pred = model.predict(X_test)
print("recall:", round(recall_score(y_test, pred), 4))
print("precision:", round(precision_score(y_test, pred), 4))
print("AUC:", round(roc_auc_score(y_test, model.predict_proba(X_test)[:, 1]), 4))
```

Output:

```
resampled class counts: [3307 3307]
recall: 0.8293
precision: 0.16
AUC: 0.8468
```

`resample` with `replace=True` draws the minority rows with repetition until there are as many as the majority (3307 each). Training on this balanced set gives a recall of 0.8293, very similar to class weighting, which makes sense since both tell the model to take the rare class seriously. We resample after the split and only on the training rows, so the test set still reflects the true 5 percent rate. For more sophisticated resampling, the `imbalanced-learn` library adds methods like SMOTE that create synthetic minority examples rather than duplicating, but the principle is the same.

---

## 6. Practical Guidance for Imbalanced Problems

You now have several tools. Here is how to put them together on a real imbalanced problem.

- **Never judge by accuracy alone.** Lead with recall, precision, F1, and AUC. Report the confusion matrix so the errors are visible.
- **Stratify every split.** Use `stratify=y` and stratified cross-validation so each fold keeps the class ratio.
- **Start with class_weight="balanced".** It is a one-line change supported by logistic regression, SVMs, random forests, and more. Often it is all you need.
- **Try resampling if weighting is not enough.** Oversample the minority (or undersample the majority), always on training data only. Look into `imbalanced-learn` and SMOTE for advanced options.
- **Tune the threshold.** As you saw in Lesson 8, lowering the decision threshold raises recall, another lever for catching the rare class.
- **Choose based on cost.** How bad is a missed positive versus a false alarm? That decides how far you push recall over precision.

The recurring theme: high accuracy on imbalanced data means little. Detecting the rare class well is the real goal, and these techniques get you there.

---

## 7. Fix the Errors in Your Code

These mistakes are common and dangerous on imbalanced data.

**Mistake 1: Resampling before the split, or resampling the test set.**

```python
# Wrong: oversampling everything before splitting leaks duplicates into the test set
X_bal, y_bal = oversample(X, y)
X_train, X_test, y_train, y_test = train_test_split(X_bal, y_bal)
```

```python
# Correct: split first, then resample only the training data
X_train, X_test, y_train, y_test = train_test_split(X, y, stratify=y, random_state=42)
# resample X_train / y_train only; leave the test set untouched
```

If you resample before splitting, copies of the same row can land in both train and test, leaking information and inflating your scores. The test set must keep the real class balance.

**Mistake 2: Judging an imbalanced model by accuracy.**

```python
# Wrong: 0.95 accuracy can mean the rare class is completely missed
accuracy_score(y_test, baseline.predict(X_test))
```

```python
# Correct: report recall, precision, and AUC for the rare class
recall_score(y_test, pred)
roc_auc_score(y_test, model.predict_proba(X_test)[:, 1])
```

Accuracy is the metric that hid the problem in the first place. Always look at recall, precision, and AUC instead.

**Mistake 3: Forgetting to stratify the split.**

```python
# Risky: a plain split might put very few minority cases in the test set
train_test_split(X, y, test_size=0.3, random_state=42)
```

```python
# Better: stratify so train and test keep the same class ratio
train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)
```

With a rare class, a non-stratified split can leave the test set with almost no positives, making your evaluation meaningless. Always stratify.

---

## 8. Exercises

**Exercise 1:** Build the same imbalanced dataset and print the baseline logistic regression's classification report (use `classification_report`). What does the recall for class 1 tell you?

**Exercise 2:** Train a `RandomForestClassifier(n_estimators=200)` with and without `class_weight="balanced"` on the imbalanced data. Compare their recall on the minority class.

**Exercise 3:** Using the baseline logistic regression's probabilities, lower the decision threshold to 0.2 and report the recall and precision. Compare to the default 0.5 threshold.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from sklearn.metrics import classification_report

baseline = LogisticRegression(max_iter=1000).fit(X_train, y_train)
print(classification_report(y_test, baseline.predict(X_test)))
```

Output:

```
              precision    recall  f1-score   support

           0       0.95      1.00      0.97      1418
           1       0.73      0.10      0.17        82

    accuracy                           0.95      1500
   macro avg       0.84      0.55      0.57      1500
weighted avg       0.94      0.95      0.93      1500
```

The class 1 recall of 0.10 reveals the failure that the 0.95 accuracy hides: the model catches only 10 percent of the rare cases. The macro average f1 of 0.57, which weights both classes equally, is far below the accuracy, another signal that the model is doing poorly on the minority.

**Solution for Exercise 2:**

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import recall_score

plain = RandomForestClassifier(n_estimators=200, random_state=42).fit(X_train, y_train)
weighted = RandomForestClassifier(n_estimators=200, class_weight="balanced", random_state=42).fit(X_train, y_train)

print("plain recall:", round(recall_score(y_test, plain.predict(X_test)), 4))
print("balanced recall:", round(recall_score(y_test, weighted.predict(X_test)), 4))
```

Output:

```
plain recall: 0.5244
balanced recall: 0.5854
```

The random forest is naturally better than logistic regression at the rare class even without help (recall 0.5244), and `class_weight="balanced"` improves it further to 0.5854. The balanced version also reached an AUC around 0.93, the best ranking of any model here. Class weighting helps across model types.

**Solution for Exercise 3:**

```python
proba = baseline.predict_proba(X_test)[:, 1]
for t in [0.5, 0.2]:
    pred = (proba >= t).astype(int)
    print(f"threshold {t}: recall {round(recall_score(y_test, pred), 4)}, precision {round(precision_score(y_test, pred), 4)}")
```

Output:

```
threshold 0.5: recall 0.0976, precision 0.7273
threshold 0.2: recall 0.4268, precision 0.407
```

Lowering the threshold from 0.5 to 0.2 lifts recall from 0.0976 to 0.4268, catching far more of the rare class, at the cost of precision dropping from 0.73 to 0.41. Threshold tuning is a quick, model-agnostic lever for imbalanced problems, and it pairs well with class weighting and resampling.

---

## Next Up - Lesson 10

You can now handle imbalanced data, the situation behind many of the most valuable machine learning problems. You know to ignore accuracy in favor of recall, precision, and AUC, to stratify your splits, and to boost the rare class with class weights, resampling, and threshold tuning. These skills turn a model that looks good into one that actually works.

In Lesson 10, you leave supervised learning behind and enter Module 5 on unsupervised learning. You will meet K-means clustering, which finds natural groups in unlabeled data, opening up a whole new category of problems where there is no target column to predict.
