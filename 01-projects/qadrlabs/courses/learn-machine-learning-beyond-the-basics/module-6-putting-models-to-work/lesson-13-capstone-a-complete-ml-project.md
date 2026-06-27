## 1. Before You Begin

This is the capstone of the course, where every skill you have built comes together into one professional workflow. In the beginner course you built a Titanic predictor by hand: cleaning, encoding, and scaling step by step. Now you will rebuild it the way a practitioner actually works, using a leak-proof pipeline, engineered features, cross-validated model selection, automated hyperparameter tuning, thorough evaluation, and a saved final model ready for deployment.

Think of this lesson as a template you can reuse for any tabular machine learning project. The dataset changes, but these phases stay the same. Work through it carefully, because assembling the whole workflow yourself is what turns a collection of techniques into real competence.

### What You'll Build

A complete, tuned Titanic survival predictor built entirely with pipelines: feature engineering, model comparison by cross-validation, hyperparameter tuning with grid search, full evaluation with accuracy and AUC, predictions on new passengers, and the final model saved to a file.

### What You'll Learn

- ✅ How to run a professional end-to-end ML project
- ✅ How to combine feature engineering with a pipeline
- ✅ How to select a model with cross-validation
- ✅ How to tune the chosen model with `GridSearchCV`
- ✅ How to evaluate thoroughly with accuracy, AUC, and a report
- ✅ How to predict on new data and save the final model

### What You'll Need

- Every skill from Modules 1 through 6
- A Colab notebook with scikit-learn, seaborn, and joblib
- The Titanic dataset (built into seaborn)

---

## 2. The Plan

Before writing code, here is the workflow you will follow. This is the same sequence for almost any supervised tabular problem, and having it in mind keeps a project organized.

1. **Load and engineer features.** Bring in the raw data and create informative new features.
2. **Build a pipeline.** Bundle preprocessing so everything is leak-free and reproducible.
3. **Compare models with cross-validation.** Try several models and pick the most promising one fairly.
4. **Tune the chosen model.** Search hyperparameters with cross-validation to get the best version.
5. **Evaluate on the test set.** Use accuracy, AUC, a confusion matrix, and a classification report, on data the model has never seen.
6. **Predict and save.** Use the model on new passengers and save it to a file for later.

Each phase uses a tool from earlier in the course. Let us execute them in order.

---

## 3. Load and Engineer Features

Start with the raw data and add the features that proved useful in Lesson 2.

### Step 1: Load the data and split

```python
import pandas as pd
import seaborn as sns
from sklearn.model_selection import train_test_split

titanic = sns.load_dataset("titanic")
df = titanic[["survived", "pclass", "sex", "age", "sibsp", "parch", "fare", "embarked"]].copy()

X = df.drop(columns="survived")
y = df["survived"]
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
```

We keep the raw columns and split immediately, holding out 20 percent as a final test set we will not touch until the very end. Stratifying preserves the survival ratio.

### Step 2: Engineer features

```python
def add_features(data):
    data = data.copy()
    data["family_size"] = data["sibsp"] + data["parch"] + 1
    data["is_alone"] = (data["family_size"] == 1).astype(int)
    data["fare_per_person"] = data["fare"] / data["family_size"]
    data["age_group"] = pd.cut(
        data["age"], bins=[0, 12, 18, 40, 60, 120],
        labels=["child", "teen", "adult", "middle", "senior"],
    )
    return data

X_train = add_features(X_train)
X_test = add_features(X_test)
```

This is the feature function from Lesson 2: `family_size`, `is_alone`, `fare_per_person`, and binned `age_group`. We apply it to the training and test sets separately. These features are row-wise, so computing them after the split is safe.

---

## 4. Build the Pipeline

Next, a preprocessor that handles the numeric and categorical columns, including the new features. We will reuse it for every model.

```python
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, OneHotEncoder

numeric = ["age", "fare", "sibsp", "parch", "pclass", "family_size", "fare_per_person", "is_alone"]
categorical = ["sex", "embarked", "age_group"]

def make_preprocessor(scale):
    num_steps = [("imp", SimpleImputer(strategy="median"))]
    if scale:
        num_steps.append(("sc", StandardScaler()))
    return ColumnTransformer([
        ("num", Pipeline(num_steps), numeric),
        ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
    ])
```

The `make_preprocessor` helper takes a `scale` flag, because distance-based and linear models need scaling while tree-based ones do not. It always imputes and one-hot encodes; it adds a `StandardScaler` only when asked. This keeps every model on a fair, leak-free footing.

---

## 5. Compare Models with Cross-Validation

Now try several models and compare them by cross-validated accuracy, the trustworthy way from Lesson 6. This decides which model to invest tuning effort in.

```python
from sklearn.model_selection import cross_val_score
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier

candidates = {
    "LogReg": (make_preprocessor(True), LogisticRegression(max_iter=1000)),
    "RandomForest": (make_preprocessor(False), RandomForestClassifier(n_estimators=200, random_state=42)),
    "GradientBoosting": (make_preprocessor(False), GradientBoostingClassifier(random_state=42)),
}

for name, (pre, estimator) in candidates.items():
    pipe = Pipeline([("pre", pre), ("clf", estimator)])
    scores = cross_val_score(pipe, X_train, y_train, cv=5, scoring="accuracy")
    print(f"{name}: {round(scores.mean(), 4)} +/- {round(scores.std(), 4)}")
```

Output:

```
LogReg: 0.7894 +/- 0.0291
RandomForest: 0.7965 +/- 0.0389
GradientBoosting: 0.8175 +/- 0.0357
```

Each model gets the right preprocessor (logistic regression scaled, the tree ensembles not) and is cross-validated on the training data only. Gradient boosting leads at 0.8175, so it is our choice to tune. Notice we made this decision with cross-validation, never touching the test set.

---

## 6. Tune the Best Model

With gradient boosting chosen, search for its best hyperparameters using `GridSearchCV` from Lesson 7.

```python
from sklearn.model_selection import GridSearchCV

gb_pipe = Pipeline([("pre", make_preprocessor(False)), ("clf", GradientBoostingClassifier(random_state=42))])
param_grid = {
    "clf__n_estimators": [100, 200],
    "clf__learning_rate": [0.05, 0.1],
    "clf__max_depth": [2, 3],
}
grid = GridSearchCV(gb_pipe, param_grid, cv=5, scoring="accuracy", n_jobs=-1)
grid.fit(X_train, y_train)

print("best params:", grid.best_params_)
print("best cv score:", round(grid.best_score_, 4))
```

Output:

```
best params: {'clf__learning_rate': 0.1, 'clf__max_depth': 3, 'clf__n_estimators': 200}
best cv score: 0.826
```

The grid searches 8 combinations, each cross-validated. The best combination lifts the cross-validated accuracy to 0.826, a touch above the default gradient boosting. `GridSearchCV` automatically refit this best model on all the training data, so `grid.best_estimator_` is ready to use.

---

## 7. Evaluate on the Test Set

Now, and only now, bring out the held-out test set for a final, honest evaluation using the metrics from Lessons 8 and 9.

### Step 1: Accuracy and AUC

```python
from sklearn.metrics import accuracy_score, roc_auc_score

best_model = grid.best_estimator_
predictions = best_model.predict(X_test)
probabilities = best_model.predict_proba(X_test)[:, 1]

print("test accuracy:", round(accuracy_score(y_test, predictions), 4))
print("test AUC:", round(roc_auc_score(y_test, probabilities), 4))
```

Output:

```
test accuracy: 0.7989
test AUC: 0.8144
```

On data the model has never seen, it scores 0.7989 accuracy and 0.8144 AUC. These are realistic numbers for this dataset and consistent with the cross-validated estimate, which is exactly what you want: no nasty surprise between cross-validation and the test set.

### Step 2: Confusion matrix and report

```python
from sklearn.metrics import confusion_matrix, classification_report

print(confusion_matrix(y_test, predictions))
print(classification_report(y_test, predictions, target_names=["died", "survived"]))
```

Output:

```
[[97 13]
 [23 46]]
              precision    recall  f1-score   support

        died       0.81      0.88      0.84       110
    survived       0.78      0.67      0.72        69

    accuracy                           0.80       179
   macro avg       0.79      0.77      0.78       179
weighted avg       0.80      0.80      0.80       179
```

The confusion matrix and report give the full picture. The model is better at identifying who died (recall 0.88) than who survived (recall 0.67), missing 23 of the 69 survivors. For a richer model on the same small dataset, this is solid, and the report tells you precisely where the errors fall, which is what you would dig into if you wanted to improve further.

---

## 8. Predict and Save the Final Model

The model is validated. Use it on new passengers, then save it for deployment.

### Step 1: Predict new passengers

```python
def predict_passenger(raw):
    passenger = add_features(pd.DataFrame([raw]))
    label = best_model.predict(passenger)[0]
    proba = best_model.predict_proba(passenger)[0].round(3)
    outcome = "survived" if label == 1 else "died"
    return outcome, proba

print(predict_passenger({"pclass": 3, "sex": "male", "age": 25, "sibsp": 0, "parch": 0, "fare": 7.25, "embarked": "S"}))
print(predict_passenger({"pclass": 1, "sex": "female", "age": 30, "sibsp": 0, "parch": 0, "fare": 100.0, "embarked": "C"}))
```

Output:

```
('died', array([0.961, 0.039]))
('survived', array([0.013, 0.987]))
```

The helper runs a raw passenger through `add_features`, then the pipeline does the rest. The third-class man is predicted to die with 96 percent confidence, and the first-class woman to survive with 99 percent confidence (the probability array is ordered died, survived). These match the strong survival patterns in the data, a reassuring final sanity check.

### Step 2: Save the model

```python
import joblib

joblib.dump(best_model, "titanic_final.joblib")

loaded = joblib.load("titanic_final.joblib")
print("loaded test accuracy:", round(accuracy_score(y_test, loaded.predict(X_test)), 4))
```

Output:

```
loaded test accuracy: 0.7989
```

`joblib.dump` saves the entire tuned pipeline, preprocessing and all, and loading it back reproduces the exact 0.7989 accuracy. This file is your deliverable: a complete, deployable model. Remember to also note your library versions and to only load model files you trust, as covered in Lesson 12.

---

## 9. Fix the Errors in Your Code

These mistakes break the end-to-end workflow.

**Mistake 1: Touching the test set before the final evaluation.**

```python
# Wrong: tuning or comparing models using the test set leaks it
grid.fit(X_test, y_test)
```

```python
# Correct: select and tune with cross-validation on training data, test once at the end
grid.fit(X_train, y_train)
best_model.predict(X_test)   # only here, at the very end
```

The test set is sacred. Use cross-validation for every decision, and evaluate on the test set exactly once.

**Mistake 2: Forgetting to engineer features on new data before predicting.**

```python
# Wrong: the pipeline expects the engineered columns, but raw input lacks them
best_model.predict(pd.DataFrame([raw_passenger]))
```

```python
# Correct: apply the same add_features step to new data first
best_model.predict(add_features(pd.DataFrame([raw_passenger])))
```

Whatever feature engineering you did for training must also be applied to new data. (For full robustness you could even wrap `add_features` into the pipeline with a `FunctionTransformer`, so it travels with the model.)

**Mistake 3: Comparing models with mismatched preprocessing.**

```python
# Wrong: scaling one model and not another, by accident, makes the comparison unfair
log_reg = Pipeline([("pre", make_preprocessor(False)), ("clf", LogisticRegression())])  # logreg without scaling
```

```python
# Correct: give each model the preprocessing it needs, deliberately
log_reg = Pipeline([("pre", make_preprocessor(True)), ("clf", LogisticRegression(max_iter=1000))])
forest = Pipeline([("pre", make_preprocessor(False)), ("clf", RandomForestClassifier(random_state=42))])
```

Be deliberate about which models get scaling. An accidental mismatch can make a good model look bad or vice versa.

---

## 10. Exercises

**Exercise 1:** Run the model comparison step yourself and confirm which model has the highest cross-validated accuracy. Print all three results.

**Exercise 2:** Instead of gradient boosting, tune a `RandomForestClassifier` with `GridSearchCV` over `clf__n_estimators` of [100, 200] and `clf__max_depth` of [4, 6, None]. Print the best params and cross-validated score.

**Exercise 3:** Use the final saved model to predict the survival of a 2nd class girl, age 8, with 1 sibling and 2 parents aboard, fare 30, embarked at Southampton. Remember to engineer features first.

---

## 11. Solutions

**Solution for Exercise 1:**

```python
from sklearn.model_selection import cross_val_score

for name, (pre, estimator) in candidates.items():
    pipe = Pipeline([("pre", pre), ("clf", estimator)])
    scores = cross_val_score(pipe, X_train, y_train, cv=5, scoring="accuracy")
    print(f"{name}: {round(scores.mean(), 4)} +/- {round(scores.std(), 4)}")
```

Output:

```
LogReg: 0.7894 +/- 0.0291
RandomForest: 0.7965 +/- 0.0389
GradientBoosting: 0.8175 +/- 0.0357
```

Gradient boosting wins with the highest mean (0.8175) and a competitive spread, which is why it was chosen for tuning. Cross-validation makes this comparison trustworthy rather than a guess based on one split.

**Solution for Exercise 2:**

```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GridSearchCV

rf_pipe = Pipeline([("pre", make_preprocessor(False)), ("clf", RandomForestClassifier(random_state=42))])
rf_grid = GridSearchCV(
    rf_pipe,
    {"clf__n_estimators": [100, 200], "clf__max_depth": [4, 6, None]},
    cv=5, scoring="accuracy", n_jobs=-1,
)
rf_grid.fit(X_train, y_train)
print("best params:", rf_grid.best_params_)
print("best cv score:", round(rf_grid.best_score_, 4))
```

Output:

```
best params: {'clf__max_depth': 4, 'clf__n_estimators': 100}
best cv score: 0.8245
```

The tuned random forest reaches 0.8245 in cross-validation, just below the tuned gradient boosting's 0.826. It prefers a shallow `max_depth` of 4, consistent with what you saw earlier: on this small dataset, constraining the trees helps.

**Solution for Exercise 3:**

```python
girl = add_features(pd.DataFrame([{
    "pclass": 2, "sex": "female", "age": 8, "sibsp": 1,
    "parch": 2, "fare": 30.0, "embarked": "S"
}]))
print("prediction:", best_model.predict(girl))
print("probabilities:", best_model.predict_proba(girl).round(3))
```

Output:

```
prediction: [1]
probabilities: [[0.024 0.976]]
```

The model predicts this 2nd class girl survived, with about 98 percent confidence. A young female passenger in a higher class fits the strongest survival profile in the data, and engineering her features first (family size, age group, and so on) ensures the pipeline receives exactly what it expects.

---

## Next Up - Lesson 14

You built a complete, professional machine learning project from start to finish: engineered features, a leak-proof pipeline, cross-validated model selection, automated tuning, thorough evaluation, predictions on new data, and a saved final model. This workflow is the blueprint for real projects, and you now own it.

In Lesson 14, the final lesson, you will step back to review everything this course covered, see how the intermediate toolkit fits together, and get a clear roadmap for where to go next, from deep learning to deploying models in production.
