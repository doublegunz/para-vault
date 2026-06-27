## 1. Before You Begin

This is the moment everything has been building toward. You have learned to explore data, clean it, encode it, scale it, train models, and evaluate them. Now you put all of it together into one complete project: predicting which passengers survived the Titanic disaster, starting from raw, messy data and ending with a working model that makes predictions about new people.

Unlike earlier lessons that each focused on one skill, this capstone is the whole workflow end to end. Treat it as a template. Every real machine learning project you do later will follow these same phases, in this same order. Work through it slowly, and by the end you will have built a real classifier from scratch.

### What You'll Build

A complete survival predictor. You will load the raw Titanic data, explore who survived, clean the missing values, encode the text columns, scale the features, train and compare three models, evaluate the best one properly, and use it to predict the survival of new passengers you describe.

### What You'll Learn

- ✅ How to run a full machine learning project from raw data to predictions
- ✅ How to combine cleaning, encoding, and scaling in the right order
- ✅ How to train and compare several models on one problem
- ✅ How to evaluate a classifier with accuracy, a confusion matrix, and a report
- ✅ How to use a finished model to predict new examples
- ✅ A reusable template for your own future projects

### What You'll Need

- Everything from Modules 1 through 6
- A Colab notebook with pandas, seaborn, and scikit-learn
- The Titanic dataset from Lesson 11

---

## 2. Load and Explore the Data

Every project starts by loading the data and getting to know it. Exploration tells you what you are working with and hints at which features will matter.

### Step 1: Load and select features

```python
import pandas as pd
import seaborn as sns

titanic = sns.load_dataset("titanic")
df = titanic[["survived", "pclass", "sex", "age", "sibsp", "parch", "fare", "embarked"]].copy()
print(df.shape)
df.head()
```

Output:

```
(891, 8)
```

We load the full dataset and keep eight columns: the target `survived`, plus `pclass` (ticket class), `sex`, `age`, `sibsp` (siblings/spouses aboard), `parch` (parents/children aboard), `fare`, and `embarked` (port). The `.copy()` keeps `df` independent of the original.

### Step 2: Check the survival rate

```python
print("survival rate:", round(df["survived"].mean(), 4))
```

Output:

```
survival rate: 0.3838
```

Because `survived` is 0 or 1, its mean is the fraction who survived: about 38 percent. This is your baseline. A model must beat the naive strategy of always guessing "died", which would be right 62 percent of the time.

### Step 3: Explore who survived

```python
print(titanic.groupby("sex")["survived"].mean().round(4))
print(titanic.groupby("pclass")["survived"].mean().round(4))
```

Output:

```
sex
female    0.7420
male      0.1889
Name: survived, dtype: float64
pclass
1    0.6296
2    0.4728
3    0.2424
Name: survived, dtype: float64
```

`groupby` splits the data by a column and computes the survival rate within each group. The story is stark: 74 percent of women survived versus only 19 percent of men, and first-class passengers survived far more often than third-class. The "women and children first" policy and class privilege are both visible in the numbers. This tells us `sex` and `pclass` will be powerful features.

---

## 3. Clean the Data

Models cannot handle missing values, so you find and fill them before anything else.

### Step 1: Find the missing values

```python
df.isnull().sum()
```

Output:

```
survived      0
pclass        0
sex           0
age         177
sibsp         0
parch         0
fare          0
embarked      2
dtype: int64
```

As you saw in Lesson 11, `age` is missing for 177 passengers and `embarked` for 2. The rest are complete.

### Step 2: Fill the gaps

```python
df["age"] = df["age"].fillna(df["age"].median())
df["embarked"] = df["embarked"].fillna(df["embarked"].mode()[0])

df.isnull().sum().sum()
```

Output:

```
0
```

We fill `age` with its median (a robust choice for a skewed numeric column) and `embarked` with its mode (the most common port, for a category). Chaining `.sum().sum()` adds up all the missing counts into a single number, and 0 confirms the data is now complete.

---

## 4. Encode the Categories

Two columns, `sex` and `embarked`, are still text. You convert them to numbers using the techniques from Lesson 11.

```python
df["sex"] = df["sex"].map({"male": 0, "female": 1})

df = pd.get_dummies(df, columns=["embarked"], drop_first=True)
bool_cols = df.select_dtypes("bool").columns
df[bool_cols] = df[bool_cols].astype(int)

print(df.columns.tolist())
```

Output:

```
['survived', 'pclass', 'sex', 'age', 'sibsp', 'parch', 'fare', 'embarked_Q', 'embarked_S']
```

`sex` has two values, so a simple map to 0 and 1 works. `embarked` has three unordered values, so one-hot encoding with `drop_first=True` turns it into `embarked_Q` and `embarked_S` (the dropped `embarked_C` is implied when both are 0). The data is now fully numeric and ready to split.

---

## 5. Split and Scale

Now you separate features from the target, hold out a test set, and scale the features. Order matters: you split first, then fit the scaler on the training data only.

### Step 1: Build X and y, then split

```python
from sklearn.model_selection import train_test_split

X = df.drop(columns="survived")
y = df["survived"]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
print("train:", X_train.shape, "test:", X_test.shape)
```

Output:

```
train: (712, 8) test: (179, 8)
```

`X` is the eight features, `y` is survival. A stratified 80/20 split keeps the same survival proportion in both sets, giving 712 training and 179 test passengers.

### Step 2: Scale the features

```python
from sklearn.preprocessing import StandardScaler

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)
```

We `fit_transform` on training data and `transform` on test data, exactly as in Lesson 12. Scaling matters here because `fare` ranges into the hundreds while the others are small, and the distance-based KNN model would otherwise be dominated by fare.

---

## 6. Train and Compare Models

Rather than betting on one model, you train three and compare them on the same test set, the disciplined approach from Lesson 8.

```python
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score

models = {
    "LogisticRegression": LogisticRegression(max_iter=1000),
    "DecisionTree": DecisionTreeClassifier(max_depth=4, random_state=42),
    "KNN": KNeighborsClassifier(n_neighbors=5),
}

for name, model in models.items():
    model.fit(X_train_scaled, y_train)
    acc = accuracy_score(y_test, model.predict(X_test_scaled))
    print(f"{name}: {round(acc, 4)}")
```

Output:

```
LogisticRegression: 0.8045
DecisionTree: 0.7877
KNN: 0.8156
```

The loop trains each model on the scaled training data and scores it on the test set. All three comfortably beat the 62 percent baseline, with KNN edging ahead at 0.8156. We will take KNN as our chosen model and evaluate it more closely. The differences are small, so on a real project you would confirm this with cross-validation, but KNN is the best on this split.

---

## 7. Evaluate the Best Model

Accuracy is one number. To understand the model's strengths and weaknesses, you look at the confusion matrix and the classification report from Lesson 9.

### Step 1: The confusion matrix

```python
best_model = KNeighborsClassifier(n_neighbors=5).fit(X_train_scaled, y_train)
predictions = best_model.predict(X_test_scaled)

from sklearn.metrics import confusion_matrix
print(confusion_matrix(y_test, predictions))
```

Output:

```
[[98 12]
 [21 48]]
```

Rows are the truth (died, then survived) and columns are the prediction. The model correctly identified 98 who died and 48 who survived. It made 12 false positives (predicted survived but died) and 21 false negatives (predicted died but survived). It is a bit more likely to miss a survivor than to wrongly predict one.

### Step 2: The classification report

```python
from sklearn.metrics import classification_report
print(classification_report(y_test, predictions, target_names=["died", "survived"]))
```

Output:

```
              precision    recall  f1-score   support

        died       0.82      0.89      0.86       110
    survived       0.80      0.70      0.74        69

    accuracy                           0.82       179
   macro avg       0.81      0.79      0.80       179
weighted avg       0.81      0.82      0.81       179
```

The report breaks performance down per class. The model is better at identifying who died (recall 0.89) than who survived (recall 0.70), meaning it misses some survivors. Precision is balanced around 0.80 to 0.82 for both classes. For a first model on real data with only a handful of features, an overall accuracy of 0.82 is a solid result.

---

## 8. Predict New Passengers

The payoff: use the finished model to predict survival for people you invent. Remember to run any new passenger through the same scaler before predicting.

```python
# A 25-year-old man, 3rd class, traveling alone, cheap ticket, boarded at Southampton
passenger_1 = pd.DataFrame([{
    "pclass": 3, "sex": 0, "age": 25, "sibsp": 0, "parch": 0,
    "fare": 7.25, "embarked_Q": 0, "embarked_S": 1
}])

# A 30-year-old woman, 1st class, expensive ticket, boarded at Cherbourg
passenger_2 = pd.DataFrame([{
    "pclass": 1, "sex": 1, "age": 30, "sibsp": 0, "parch": 0,
    "fare": 100.0, "embarked_Q": 0, "embarked_S": 0
}])

for name, p in [("3rd class man", passenger_1), ("1st class woman", passenger_2)]:
    p_scaled = scaler.transform(p)
    pred = best_model.predict(p_scaled)[0]
    proba = best_model.predict_proba(p_scaled)[0].round(3)
    outcome = "survived" if pred == 1 else "died"
    print(f"{name}: {outcome} (probabilities died/survived: {proba})")
```

Output:

```
3rd class man: died (probabilities died/survived: [0.8 0.2])
1st class woman: survived (probabilities died/survived: [1. 0.])
```

Each new passenger is built with the same feature columns, scaled with the training scaler, then predicted. The model says the third-class man likely died (80 percent) and the first-class woman almost certainly survived (100 percent of her 5 nearest neighbors survived). These predictions line up perfectly with the survival patterns you found during exploration, which is a reassuring sign your model learned something real.

---

## 9. Fix the Errors in Your Code

These mistakes break an end-to-end project. They are worth memorizing.

**Mistake 1: Doing things in the wrong order.**

```python
# Wrong: encoding or scaling before handling missing values causes errors
df = pd.get_dummies(df, columns=["embarked"])   # but embarked still has NaNs
```

```python
# Correct: the order is explore, clean, encode, split, scale, then model
df["embarked"] = df["embarked"].fillna(df["embarked"].mode()[0])
df = pd.get_dummies(df, columns=["embarked"], drop_first=True)
```

The workflow has an order for a reason. Clean missing values first, then encode, then split, then scale. Skipping ahead causes errors or subtle bugs.

**Mistake 2: Forgetting to scale a new passenger before predicting.**

```python
# Wrong: the model was trained on scaled data, so raw input gives garbage
best_model.predict(passenger_1)
```

```python
# Correct: apply the same scaler used in training
best_model.predict(scaler.transform(passenger_1))
```

Whatever you did to the training features, you must do to any new data before predicting, using the scaler already fitted on training data.

**Mistake 3: Leaving the target in the features.**

```python
# Wrong: survived is still in X, so the model "cheats"
X = df
y = df["survived"]
```

```python
# Correct: drop the target from the features
X = df.drop(columns="survived")
y = df["survived"]
```

If the answer is among the inputs, the model reports a fake-perfect score and is useless on real data. Always separate the target out.

---

## 10. Exercises

**Exercise 1:** Create a new feature `alone` that is 1 when a passenger has no family aboard (`sibsp + parch == 0`) and 0 otherwise. Print the survival rate for people traveling alone versus with family. Who survived more often?

**Exercise 2:** Train a `DecisionTreeClassifier` with `max_depth=4` on the prepared features and print its feature importances, sorted from highest to lowest. Which feature matters most for predicting survival?

**Exercise 3:** Use the trained KNN model to predict the survival of a 2nd class girl, age 8, with 1 sibling and 2 parents aboard, fare 30, boarded at Southampton. Print the prediction and probabilities.

---

## 11. Solutions

**Solution for Exercise 1:**

```python
import seaborn as sns

titanic = sns.load_dataset("titanic")
df = titanic[["survived", "sibsp", "parch"]].copy()
df["alone"] = ((df["sibsp"] + df["parch"]) == 0).astype(int)
print(df.groupby("alone")["survived"].mean().round(4))
```

Output:

```
alone
0    0.5056
1    0.3035
Name: survived, dtype: float64
```

Passengers with family aboard (`alone` is 0) survived about 51 percent of the time, while those traveling alone survived only about 30 percent. Family connections mattered, which makes `alone` a promising engineered feature. Creating new features like this is the subject of the next course.

**Solution for Exercise 2:**

```python
import pandas as pd
from sklearn.tree import DecisionTreeClassifier

tree = DecisionTreeClassifier(max_depth=4, random_state=42)
tree.fit(X_train, y_train)
importances = pd.Series(tree.feature_importances_, index=X.columns)
print(importances.round(3).sort_values(ascending=False))
```

Output:

```
sex           0.576
pclass        0.196
age           0.107
fare          0.063
embarked_S    0.037
sibsp         0.012
parch         0.008
embarked_Q    0.000
dtype: float64
```

`sex` is by far the most important feature at 0.576, followed by `pclass` and `age`. This confirms what exploration suggested: gender and class were the biggest factors in who survived. Note the tree here is trained on the unscaled features, since trees do not need scaling.

**Solution for Exercise 3:**

```python
import pandas as pd

passenger = pd.DataFrame([{
    "pclass": 2, "sex": 1, "age": 8, "sibsp": 1, "parch": 2,
    "fare": 30.0, "embarked_Q": 0, "embarked_S": 1
}])
passenger_scaled = scaler.transform(passenger)
print("prediction:", best_model.predict(passenger_scaled))
print("probabilities:", best_model.predict_proba(passenger_scaled).round(3))
```

Output:

```
prediction: [1]
probabilities: [[0. 1.]]
```

The model predicts this 2nd class girl survived, with full confidence (all 5 nearest neighbors survived). A young female passenger in a higher class fits the strongest survival profile in the data, so the confident prediction makes sense.

---

## Next Up - Lesson 14

You did it. You built a complete machine learning project from raw, messy data to a working predictor, combining every skill from this course: exploration, cleaning, encoding, scaling, model comparison, evaluation, and prediction. This workflow is the template for every project you will tackle from here on.

In Lesson 14, the final lesson, you will step back and review the whole journey, see where machine learning can take you next, and get a clear roadmap of what to learn after this course, including a preview of the intermediate techniques waiting for you in "Machine Learning: Beyond the Basics".
