## 1. Before You Begin

In Lesson 1 you built a clean pipeline that preprocesses raw data without leakage. That pipeline takes your existing columns as they are. This lesson is about creating better columns. Feature engineering is the craft of building new, more informative features from the data you already have, and it is often the single highest-leverage thing you can do in a machine learning project. A well-chosen feature can help a model more than switching to a fancier algorithm.

You will engineer several features for the Titanic data, check whether they actually capture useful patterns, then fold them into the pipeline from Lesson 1 and measure their effect. Along the way you will learn an honest truth that many tutorials skip: not every engineered feature helps, so you always validate.

### What You'll Build

A feature engineering function that adds family size, an "is alone" flag, fare per person, and age groups to the Titanic data. You will confirm these features track survival, plug them into your pipeline, and compare the model with and without them.

### What You'll Learn

- ✅ What feature engineering is and why it matters so much
- ✅ How to create features by combining and transforming existing columns
- ✅ How to bin a continuous feature into meaningful groups
- ✅ How to check whether a new feature relates to the target
- ✅ How to fold engineered features into a pipeline
- ✅ Why you must validate features instead of assuming they help

### What You'll Need

- The pipeline skills from Lesson 1
- A Colab notebook with scikit-learn and seaborn
- The Titanic dataset (built into seaborn)

---

## 2. What Is Feature Engineering?

Models can only learn from the features you give them. If an important pattern is hidden across several columns, a model may struggle to find it on its own. Feature engineering makes those patterns explicit by creating columns that express them directly.

Good engineered features usually come from one of a few moves:

- **Combining columns.** On the Titanic, `sibsp` (siblings and spouses) and `parch` (parents and children) are separate. Adding them gives `family_size`, a single number that may matter more than either alone.
- **Creating flags.** A yes/no feature like "is this passenger traveling alone" can capture a sharp distinction the raw numbers blur.
- **Transforming a column.** Dividing `fare` by family size gives `fare_per_person`, which may reflect wealth better than the raw group fare.
- **Binning.** Turning a continuous `age` into groups like child, teen, and adult can expose non-linear effects, since survival did not rise smoothly with age.

Domain knowledge guides all of this. Knowing that "women and children first" shaped survival tells you that age groups and family structure are worth encoding. Let us build these features.

---

## 3. Engineer New Features

We will write one function that takes the data and returns it with new columns added. Keeping feature creation in a function makes it easy to apply consistently to training and test data.

### Step 1: Combine columns into family size

```python
import pandas as pd
import seaborn as sns

titanic = sns.load_dataset("titanic")
df = titanic[["survived", "pclass", "sex", "age", "sibsp", "parch", "fare", "embarked"]].copy()

def add_features(data):
    data = data.copy()
    data["family_size"] = data["sibsp"] + data["parch"] + 1
    return data
```

`family_size` adds siblings/spouses, parents/children, and 1 for the passenger themselves. We work on a copy so the original is never mutated, which matters when you apply this inside a pipeline later. A single `family_size` is often more predictive than its two parts because survival depended on the size of the group, not its exact composition.

### Step 2: Create an "is alone" flag

```python
def add_features(data):
    data = data.copy()
    data["family_size"] = data["sibsp"] + data["parch"] + 1
    data["is_alone"] = (data["family_size"] == 1).astype(int)
    return data
```

`is_alone` is 1 when the passenger has no family aboard and 0 otherwise. `(data["family_size"] == 1)` produces True/False, and `.astype(int)` turns that into 1/0. A simple binary flag like this can capture a strong effect that the raw count dilutes.

### Step 3: Transform fare into fare per person

```python
    data["fare_per_person"] = data["fare"] / data["family_size"]
```

A family of four sharing one 100 dollar ticket is not as wealthy as one person paying 100 dollars. Dividing the group `fare` by `family_size` gives a per-person figure that may reflect a passenger's status more faithfully than the raw fare.

### Step 4: Bin age into groups

```python
    data["age_group"] = pd.cut(
        data["age"],
        bins=[0, 12, 18, 40, 60, 120],
        labels=["child", "teen", "adult", "middle", "senior"],
    )
    return data
```

`pd.cut` slices the continuous `age` into labeled ranges: 0 to 12 is child, 12 to 18 is teen, and so on. Binning lets the model treat children as a distinct group rather than assuming survival changes by a fixed amount per year of age. Now apply the full function and look at the result:

```python
df = add_features(df)
df[["sibsp", "parch", "family_size", "is_alone", "fare", "fare_per_person", "age", "age_group"]].head()
```

Output:

```
   sibsp  parch  family_size  is_alone     fare  fare_per_person   age age_group
0      1      0            2         0   7.2500            3.625  22.0     adult
1      1      0            2         0  71.2833           35.642  38.0     adult
2      0      0            1         1   7.9250            7.925  26.0     adult
3      1      0            2         0  53.1000           26.550  35.0     adult
4      0      0            1         1   8.0500            8.050  35.0     adult
```

Each new column expresses something the raw data only implied. Passenger 0 has a family of 2, is not alone, and paid about 3.63 per person.

---

## 4. Check If the Features Make Sense

Before trusting a feature, confirm it actually relates to the target. A feature that shows no pattern with survival is unlikely to help, and checking takes one line.

```python
print(df.groupby("is_alone")["survived"].mean().round(4))
```

Output:

```
is_alone
0    0.5056
1    0.3035
Name: survived, dtype: float64
```

`groupby` shows the survival rate for each value of `is_alone`. Passengers with family aboard survived about 51 percent of the time, while those traveling alone survived only about 30 percent. That is a clear, sizable gap, which is a good sign the feature carries signal. Always sanity-check engineered features this way; if the survival rate is identical across groups, the feature probably will not help.

---

## 5. Fold the Features into the Pipeline and Compare

Now plug the engineered features into the Lesson 1 pipeline and measure their effect against a baseline that uses only the original columns. This is the honest test of whether your work paid off.

### Step 1: Set up both feature sets

```python
from sklearn.model_selection import train_test_split

raw = titanic[["survived", "pclass", "sex", "age", "sibsp", "parch", "fare", "embarked"]].copy()
X = raw.drop(columns="survived")
y = raw["survived"]
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

X_train_eng = add_features(X_train)
X_test_eng = add_features(X_test)
```

We split first, then apply `add_features` to each part separately. The engineered features here are row-wise (each row's new value depends only on that row), so this is safe, but applying after the split keeps the discipline you learned in Lesson 1.

### Step 2: Build and score both pipelines

```python
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score

def make_pipeline(numeric, categorical):
    pre = ColumnTransformer([
        ("num", Pipeline([("imp", SimpleImputer(strategy="median")), ("sc", StandardScaler())]), numeric),
        ("cat", Pipeline([("imp", SimpleImputer(strategy="most_frequent")), ("oh", OneHotEncoder(handle_unknown="ignore"))]), categorical),
    ])
    return Pipeline([("pre", pre), ("clf", LogisticRegression(max_iter=1000))])

# Baseline: original columns only
base_clf = make_pipeline(["age", "fare", "sibsp", "parch", "pclass"], ["sex", "embarked"])
base_clf.fit(X_train, y_train)
print("baseline test accuracy:", round(accuracy_score(y_test, base_clf.predict(X_test)), 4))

# Engineered: original plus new features
eng_clf = make_pipeline(
    ["age", "fare", "sibsp", "parch", "pclass", "family_size", "fare_per_person", "is_alone"],
    ["sex", "embarked", "age_group"],
)
eng_clf.fit(X_train_eng, y_train)
print("engineered test accuracy:", round(accuracy_score(y_test, eng_clf.predict(X_test_eng)), 4))
```

Output:

```
baseline test accuracy: 0.8045
engineered test accuracy: 0.8324
```

Adding the engineered features raised test accuracy from 0.8045 to 0.8324, a real improvement from the same model and the same data, just expressed better. The `make_pipeline` helper keeps the two setups identical except for the feature lists, so the comparison is fair.

---

## 6. The Honest Truth About Feature Engineering

That test improvement is encouraging, but feature engineering is not magic, and you should hold a healthy skepticism. If you also cross-validate these two setups, the engineered version comes out roughly equal to the baseline (both around 0.79), even though it won on this particular test split. That gap between a single test split and cross-validation is exactly why you never trust one number.

A few principles to carry forward:

- **Always validate.** A feature that seems clever can do nothing, or even hurt. Measure with cross-validation, which you will formalize in Lesson 6, rather than a single split.
- **Lean on domain knowledge.** The best features come from understanding the problem, like knowing that family structure and age shaped Titanic survival.
- **Prefer simple, interpretable features.** `family_size` and `is_alone` are easy to explain and debug. Resist adding dozens of obscure features that you cannot reason about.
- **More features is not always better.** Irrelevant features add noise and can encourage overfitting. Keep the ones that earn their place.

Feature engineering is experimental by nature. You hypothesize, you build, you validate, and you keep only what genuinely helps.

---

## 7. Fix the Errors in Your Code

These mistakes are common when engineering features.

**Mistake 1: Mutating the original DataFrame by accident.**

```python
# Wrong: without copy(), this changes the caller's DataFrame as a side effect
def add_features(data):
    data["family_size"] = data["sibsp"] + data["parch"] + 1
    return data
```

```python
# Correct: copy first so the original is untouched
def add_features(data):
    data = data.copy()
    data["family_size"] = data["sibsp"] + data["parch"] + 1
    return data
```

Modifying the input in place leads to confusing bugs where data changes unexpectedly. Always work on a copy inside a feature function.

**Mistake 2: Creating features from the whole dataset before splitting, using global statistics.**

```python
# Risky: filling a new feature with a median computed over all rows leaks test info
df["fare_per_person"] = df["fare"] / df["family_size"]
df["fare_per_person"] = df["fare_per_person"].fillna(df["fare_per_person"].median())  # median over all data
```

```python
# Better: row-wise features are fine before splitting, but any fill value should be
# learned on training data only (let the pipeline's imputer handle it after the split)
df["fare_per_person"] = df["fare"] / df["family_size"]   # row-wise, safe
# leave imputation to the SimpleImputer inside the pipeline
```

Row-wise features (each row independent) are safe to compute anytime. But any statistic across rows, like a median used to fill gaps, must come from training data only. Let the pipeline's imputer do it.

**Mistake 3: Forgetting to add the new categorical feature to the categorical list.**

```python
# Wrong: age_group is text, but it was left in the numeric list
numeric = ["age", "fare", "family_size", "age_group"]
```

```python
# Correct: route age_group to the categorical transformer
numeric = ["age", "fare", "family_size", "fare_per_person", "is_alone"]
categorical = ["sex", "embarked", "age_group"]
```

A binned feature like `age_group` holds labels, so it belongs with the categorical columns that get one-hot encoded, not with the numeric ones.

---

## 8. Exercises

**Exercise 1:** Create the `family_size` feature on the Titanic data and print the survival rate for each family size. Which family sizes survived best?

**Exercise 2:** Create a `small_family` feature that is 1 when `family_size` is between 2 and 4 (inclusive) and 0 otherwise. Print the survival rate for each value. Does belonging to a small family help?

**Exercise 3:** Create the `age_group` feature with `pd.cut` and print the survival rate for each age group. Which group survived most?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
import seaborn as sns

titanic = sns.load_dataset("titanic")
df = titanic[["survived", "sibsp", "parch"]].copy()
df["family_size"] = df["sibsp"] + df["parch"] + 1
print(df.groupby("family_size")["survived"].mean().round(4))
```

Output:

```
family_size
1     0.3035
2     0.5528
3     0.5784
4     0.7241
5     0.2000
6     0.1364
7     0.3333
8     0.0000
11    0.0000
Name: survived, dtype: float64
```

Survival rises for small families and peaks at size 4 (about 72 percent), then collapses for large families of 5 or more. The relationship is not linear, which is exactly why `family_size` (and groupings of it) can help a model more than the raw `sibsp` and `parch` counts.

**Solution for Exercise 2:**

```python
df["small_family"] = df["family_size"].between(2, 4).astype(int)
print(df.groupby("small_family")["survived"].mean().round(4))
```

Output:

```
small_family
0    0.2888
1    0.5788
Name: survived, dtype: float64
```

Passengers in a small family of 2 to 4 survived about 58 percent of the time, nearly double the 29 percent for everyone else (alone or in a large family). This single binary feature captures the peak you saw in Exercise 1, and its strong gap suggests it is a useful feature.

**Solution for Exercise 3:**

```python
import pandas as pd

df = titanic[["survived", "age"]].copy()
df["age_group"] = pd.cut(
    df["age"], bins=[0, 12, 18, 40, 60, 120],
    labels=["child", "teen", "adult", "middle", "senior"],
)
print(df.groupby("age_group", observed=True)["survived"].mean().round(4))
```

Output:

```
age_group
child     0.5797
teen      0.4286
adult     0.3882
middle    0.3906
senior    0.2273
Name: survived, dtype: float64
```

Children survived most (about 58 percent) and seniors least (about 23 percent), with the rate generally falling as age rises. The `observed=True` argument tells pandas to skip empty category combinations. This clear ordering confirms `age_group` captures the "children first" effect.

---

## Next Up - Lesson 3

You can now engineer features that make hidden patterns explicit, check that they relate to the target, and fold them into a pipeline, while keeping the honest habit of validating whether they actually help. Feature engineering plus clean pipelines is a powerful combination.

In Lesson 3, you move from preparing data to using more powerful models. You will meet the random forest, an ensemble of many decision trees that vote together. It usually outperforms a single tree, resists overfitting better, and tells you which features matter most, all while fitting neatly into the pipeline you already know.
