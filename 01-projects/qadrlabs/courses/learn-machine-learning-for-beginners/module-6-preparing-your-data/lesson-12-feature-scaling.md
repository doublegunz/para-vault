## 1. Before You Begin

In Lesson 11 you made messy data clean and numeric. There is one more preparation step that can dramatically change a model's results: feature scaling. When your features live on very different scales, where one column ranges into the thousands and another from 0 to 1, some models are quietly dominated by the large-numbered column and perform badly. Scaling fixes this.

In this lesson you will see the problem with your own eyes: the same model scoring far worse on unscaled data than on scaled data. Then you will learn the two standard scaling techniques and, just as importantly, which models actually need them. This completes your data-preparation toolkit ahead of the capstone.

### What You'll Build

A notebook that loads the penguins dataset, whose body measurements have wildly different ranges, shows a k-nearest neighbors classifier struggling on the raw data, then applies standardization and normalization to fix it, with the accuracy jumping as a result.

### What You'll Learn

- ✅ Why feature scale affects some models
- ✅ How to standardize features with `StandardScaler`
- ✅ How to normalize features with `MinMaxScaler`
- ✅ Why you fit the scaler on training data only
- ✅ Which models need scaling and which do not
- ✅ How scaling can improve both accuracy and training stability

### What You'll Need

- The data-prep skills from Lesson 11
- The KNN model from Lesson 8
- A Colab notebook with scikit-learn and seaborn

---

## 2. Why Scale Features?

Many models judge examples by distance or by weighted sums, and both are sensitive to the size of the numbers. Imagine a dataset with `age` (roughly 0 to 100) and `income` (roughly 0 to 100000). To a model that measures distance between examples, a 10000 difference in income swamps any difference in age, so age is effectively ignored, not because it is unimportant but because its numbers are small.

Scaling puts every feature on a comparable range so each one gets a fair say. The two standard methods are:

- **Standardization** rescales each feature to have a mean of 0 and a standard deviation of 1. This is the most common choice.
- **Normalization** rescales each feature to a fixed range, usually 0 to 1.

Not every model needs scaling, which you will sort out later in the lesson. First, let us watch the problem happen on real data.

---

## 3. See the Problem

The penguins dataset describes three penguin species (Adelie, Chinstrap, and Gentoo) with four body measurements. Those measurements are on very different scales, which makes it perfect for exposing the scaling problem.

### Step 1: Look at the feature ranges

```python
import seaborn as sns

penguins = sns.load_dataset("penguins").dropna()
X = penguins[["bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g"]]
y = penguins["species"]

X.describe().loc[["min", "max"]].round(2)
```

Output:

```
     bill_length_mm  bill_depth_mm  flipper_length_mm  body_mass_g
min            32.1           13.1              172.0       2700.0
max            59.6           21.5              231.0       6300.0
```

The dataset has a few rows with missing values, so `.dropna()` removes them with the skill you learned in Lesson 11, leaving 333 penguins. Now look at the gap in the ranges. `body_mass_g` runs from 2700 to 6300 grams, while `bill_depth_mm` runs from about 13 to 22 millimeters. To a distance-based model, `body_mass_g` will completely dominate simply because its numbers are hundreds of times larger, even though the bill measurements may matter just as much.

### Step 2: Train KNN on the raw data

```python
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)

knn = KNeighborsClassifier(n_neighbors=5).fit(X_train, y_train)
print("KNN without scaling:", round(accuracy_score(y_test, knn.predict(X_test)), 4))
```

Output:

```
KNN without scaling: 0.78
```

A test accuracy of 0.78 is mediocre. KNN classifies by finding the nearest neighbors, and because `body_mass_g` dominates the distance, the model is essentially comparing penguins on weight alone. That is a problem, because Adelie and Chinstrap penguins weigh about the same and only differ in their bill measurements, which the raw distances barely register. Let us fix it with scaling.

---

## 4. Standardization with StandardScaler

Standardization is the default scaling method. It transforms each feature so its values have a mean of 0 and a standard deviation of 1, putting all features on the same footing.

### Step 1: Fit on training data, transform both sets

```python
from sklearn.preprocessing import StandardScaler

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)
```

This is the critical pattern. `scaler.fit_transform(X_train)` learns the mean and standard deviation from the training data and scales it in one step. `scaler.transform(X_test)` then applies those same training values to the test data. You never call `fit` on the test set, because the test set must stay unseen; learning scaling values from it would leak information. Learn from train, apply to both.

### Step 2: Verify the result

```python
import pandas as pd

scaled_df = pd.DataFrame(X_train_scaled, columns=X.columns)
print("body_mass_g mean:", round(scaled_df["body_mass_g"].mean(), 4))
print("body_mass_g std:", round(scaled_df["body_mass_g"].std(), 4))
```

Output:

```
body_mass_g mean: -0.0
body_mass_g std: 1.0022
```

After standardization, `body_mass_g` has a mean of essentially 0 and a standard deviation of about 1, instead of ranging into the thousands. Every other feature is rescaled the same way, so now they are all comparable. The tiny deviations from exactly 0 and 1 are just floating-point and sampling details.

### Step 3: Train KNN on the scaled data

```python
knn_scaled = KNeighborsClassifier(n_neighbors=5).fit(X_train_scaled, y_train)
print("KNN with scaling:", round(accuracy_score(y_test, knn_scaled.predict(X_test_scaled)), 4))
```

Output:

```
KNN with scaling: 1.0
```

The accuracy jumps from 0.78 to a perfect 1.0 with no change to the model, only to the data's scale. This is the whole point: with every feature contributing fairly, the bill measurements can finally separate Adelie from Chinstrap, and the three species become fully distinguishable. For distance-based models, scaling is not optional.

---

## 5. Normalization with MinMaxScaler

Normalization is the other common method. Instead of mean 0 and standard deviation 1, it squeezes each feature into a fixed range, by default 0 to 1.

```python
from sklearn.preprocessing import MinMaxScaler

minmax = MinMaxScaler()
X_train_mm = minmax.fit_transform(X_train)
X_test_mm = minmax.transform(X_test)

mm_df = pd.DataFrame(X_train_mm, columns=X.columns)
print("body_mass_g min:", round(mm_df["body_mass_g"].min(), 4))
print("body_mass_g max:", round(mm_df["body_mass_g"].max(), 4))

knn_mm = KNeighborsClassifier(n_neighbors=5).fit(X_train_mm, y_train)
print("KNN with MinMax:", round(accuracy_score(y_test, knn_mm.predict(X_test_mm)), 4))
```

Output:

```
body_mass_g min: 0.0
body_mass_g max: 1.0
KNN with MinMax: 1.0
```

`MinMaxScaler` follows the exact same fit-on-train, transform-both pattern. After it, `body_mass_g` runs from 0 to 1, and KNN again scores a perfect 1.0, matching standardization. So which do you pick? Standardization is the safer default and handles outliers better, while normalization is handy when you specifically need values bounded between 0 and 1. In practice, standardization is the more common choice.

---

## 6. Which Models Need Scaling

Scaling helps some models a lot and does nothing for others. Knowing the difference saves you from unnecessary work and from skipping it when it matters.

- **Need scaling:** distance-based and weight-based models. KNN, support vector machines, and any model using gradient descent (including logistic regression and neural networks) all benefit, often a lot. These models compare features by distance or by weighted sums, so scale matters directly.
- **Do not need scaling:** tree-based models. Decision trees, random forests, and gradient boosting split on one feature at a time using thresholds, so the scale of a feature does not change which splits are chosen. Scaling them is harmless but pointless.

A practical bonus: scaling often helps gradient-based models like logistic regression train faster and more reliably, sometimes turning a "failed to converge" warning into a clean fit. When in doubt, scaling rarely hurts, so standardizing by default is a reasonable habit, especially while you are learning which models are sensitive.

---

## 7. Fix the Errors in Your Code

These mistakes either leak data or scale the wrong things.

**Mistake 1: Fitting the scaler on the whole dataset before splitting.**

```python
# Wrong: the scaler sees test data, leaking information into training
scaler.fit(X)               # uses all rows, including the test set
X_scaled = scaler.transform(X)
X_train, X_test = train_test_split(X_scaled, ...)
```

```python
# Correct: split first, then fit the scaler on the training set only
X_train, X_test, y_train, y_test = train_test_split(X, y, ...)
scaler.fit(X_train)
X_train_scaled = scaler.transform(X_train)
X_test_scaled = scaler.transform(X_test)
```

The test set must stay unseen. Fitting the scaler on it leaks test information into training and inflates your scores.

**Mistake 2: Calling fit_transform on the test set.**

```python
# Wrong: this re-learns scaling from the test data
X_test_scaled = scaler.fit_transform(X_test)
```

```python
# Correct: only transform the test set with the scaler fitted on training data
X_test_scaled = scaler.transform(X_test)
```

Use `fit_transform` on training data and `transform` (no fit) on test data, so both are scaled by the same training-derived values.

**Mistake 3: Scaling the target variable.**

```python
# Wrong: you almost never scale y for standard regression or classification
y_scaled = scaler.fit_transform(y)
```

```python
# Correct: scale only the features X, leave the target y alone
X_train_scaled = scaler.fit_transform(X_train)
# y_train stays as it is
```

Scaling applies to the input features. The target stays in its original units so your predictions and metrics remain interpretable.

---

## 8. Exercises

**Exercise 1:** Load the penguins dataset and print the standard deviation of every feature (use `X.std()`). Which feature has the largest spread, and why would that hurt a distance-based model?

**Exercise 2:** Section 6 claims tree-based models do not need scaling. Prove it: train a `DecisionTreeClassifier(max_depth=2, random_state=42)` on the penguin features without scaling and then with `StandardScaler` (use a stratified 30 percent test split, `random_state=42`). Compare the two test accuracies.

**Exercise 3:** Apply `StandardScaler` to the penguin training features and confirm that the `flipper_length_mm` feature now has a mean of about 0 and a standard deviation of about 1.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
import seaborn as sns

penguins = sns.load_dataset("penguins").dropna()
X = penguins[["bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g"]]
print(X.std().round(2).sort_values(ascending=False))
```

Output:

```
body_mass_g          805.22
flipper_length_mm     14.02
bill_length_mm         5.47
bill_depth_mm          1.97
dtype: float64
```

`body_mass_g` has by far the largest spread, hundreds of times bigger than `bill_depth_mm`. In a distance-based model, that single high-spread feature would dominate every distance calculation, drowning out the others until you scale them onto a common range.

**Solution for Exercise 2:**

```python
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score

y = penguins["species"]
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)

# Without scaling
tree = DecisionTreeClassifier(max_depth=2, random_state=42).fit(X_train, y_train)
print("no scaling:", round(accuracy_score(y_test, tree.predict(X_test)), 4))

# With scaling
scaler = StandardScaler()
X_train_s = scaler.fit_transform(X_train)
X_test_s = scaler.transform(X_test)
tree2 = DecisionTreeClassifier(max_depth=2, random_state=42).fit(X_train_s, y_train)
print("with scaling:", round(accuracy_score(y_test, tree2.predict(X_test_s)), 4))
```

Output:

```
no scaling: 0.93
with scaling: 0.93
```

The accuracy is identical either way. A decision tree splits on one feature at a time using thresholds ("is `body_mass_g` above 4500?"), and rescaling a feature just rescales the threshold without changing which rows go left or right. Compare that with KNN, which jumped from 0.78 to 1.0: scaling is essential for distance-based models and pointless for trees.

**Solution for Exercise 3:**

```python
import pandas as pd

scaler = StandardScaler()
X_train_s = scaler.fit_transform(X_train)
scaled_df = pd.DataFrame(X_train_s, columns=X.columns)

print("flipper_length_mm mean:", round(scaled_df["flipper_length_mm"].mean(), 4))
print("flipper_length_mm std:", round(scaled_df["flipper_length_mm"].std(), 4))
```

Output:

```
flipper_length_mm mean: -0.0
flipper_length_mm std: 1.0022
```

After standardization the `flipper_length_mm` feature is centered at 0 with a standard deviation of about 1, exactly like every other feature. That shared scale is what lets each feature contribute fairly to the model.

---

## Next Up - Lesson 13

You now have the complete data-preparation toolkit: handling missing values, encoding categories, and scaling features, plus the judgment to know when each is needed. Combined with everything from earlier modules, you have all the pieces of a real machine learning project.

In Lesson 13, you bring it all together in the capstone. You will take the raw, messy Titanic dataset and carry it through the entire workflow, exploring, cleaning, encoding, splitting, training, and evaluating, to build a model that predicts which passengers survived. It is the moment where every skill in this course comes together into one complete project.
