## 1. Before You Begin

Every dataset so far has been clean and ready to model. Real data is not like that. It has gaps where values are missing and text categories that models cannot read. Before any algorithm can learn from real data, you have to clean and convert it, and that work is the focus of this module.

In this lesson you meet the Titanic dataset, the data you will use for your capstone project, and you fix its two most common problems: missing values and categorical (text) features. These are skills you will use in literally every real project, because clean data is a precondition for every model you have learned.

### What You'll Build

A notebook that loads the Titanic passenger data, finds where values are missing, fills those gaps sensibly, and converts text columns like sex and port of embarkation into numbers that scikit-learn models can use. By the end you will have a fully numeric, gap-free table ready for modeling.

### What You'll Learn

- ✅ Why models need numeric data with no missing values
- ✅ How to detect missing values with `isnull().sum()`
- ✅ How to fill missing values by imputation (median and mode)
- ✅ How to encode a binary category by mapping
- ✅ How to one-hot encode a multi-category column with `get_dummies`
- ✅ When to use which encoding

### What You'll Need

- The pandas skills from Module 2
- A Colab notebook with pandas and seaborn
- The Titanic dataset (built into seaborn)

---

## 2. Why Real Data Needs Cleaning

scikit-learn models have two firm requirements: every value must be a number, and there can be no missing values. Real datasets routinely violate both. A survey has blank answers, a sensor drops readings, and columns like "city" or "gender" hold text. If you feed such data straight into a model, it errors out.

So the job before modeling is to make the data satisfy those two rules:

- **No missing values.** You either fill the gaps (imputation) or drop the affected rows or columns.
- **All numeric.** You convert every text category into numbers through encoding.

Doing this thoughtfully matters, because careless cleaning can distort the data and mislead the model. Let us work through it on a real, messy dataset.

---

## 3. Meet the Titanic Dataset

The Titanic dataset records passengers on the famous voyage, including whether each one survived. It is the classic first classification project because it is small, relatable, and genuinely messy. You will build a survival predictor from it in the capstone.

```python
import pandas as pd
import seaborn as sns

titanic = sns.load_dataset("titanic")
print(titanic.shape)

df = titanic[["survived", "pclass", "sex", "age", "fare", "embarked"]].copy()
df.head()
```

Output:

```
(891, 15)
```

`sns.load_dataset("titanic")` loads 891 passengers with 15 columns. To keep this lesson focused, we select a useful subset into `df`: `survived` (the target, 1 if they survived), `pclass` (ticket class 1 to 3), `sex`, `age`, `fare` (ticket price), and `embarked` (port of boarding). The `.copy()` makes `df` an independent table so our changes do not touch the original. The `sex` and `embarked` columns are text, and some values are missing, which is exactly what we will fix.

---

## 4. Detecting Missing Values

You cannot fix gaps you have not found, so the first step is always to count missing values per column.

```python
df.isnull().sum()
```

Output:

```
survived      0
pclass        0
sex           0
age         177
fare          0
embarked      2
dtype: int64
```

`df.isnull()` produces a table of True/False marking each missing cell, and chaining `.sum()` counts the Trues per column. The result is clear: `age` is missing for 177 passengers and `embarked` for 2, while the other columns are complete. This single line is the first thing you run on any new dataset, because it tells you exactly what needs fixing and how big the problem is.

---

## 5. Filling Missing Values

With two columns to fix, you choose a strategy for each. The common approach, called imputation, fills each gap with a sensible substitute drawn from the column itself.

### Step 1: Impute a numeric column with the median

For `age`, a number, the median (middle value) is a robust choice because it is not thrown off by a few very old or very young passengers:

```python
median_age = df["age"].median()
print("median age:", median_age)

df["age"] = df["age"].fillna(median_age)
```

Output:

```
median age: 28.0
```

`df["age"].median()` computes the middle age, 28.0, and `fillna(median_age)` replaces every missing age with it. We use the median rather than the mean because the median is less sensitive to extreme values, which makes it a safer default for skewed data like ages or prices.

### Step 2: Impute a categorical column with the mode

For `embarked`, a category, you cannot take a median. Instead you fill with the mode, the most frequent value:

```python
most_common_port = df["embarked"].mode()[0]
print("most common port:", most_common_port)

df["embarked"] = df["embarked"].fillna(most_common_port)
```

Output:

```
most common port: S
```

`df["embarked"].mode()` returns the most common categories and `[0]` takes the first, here `S` (Southampton). Filling the 2 missing ports with the most common one is reasonable when so few are missing. Now confirm the data is complete:

```python
df.isnull().sum()
```

Output:

```
survived    0
pclass      0
sex         0
age         0
fare        0
embarked    0
dtype: int64
```

Every column now reads 0 missing. The first requirement, no missing values, is satisfied. Next is the second requirement: all numeric.

---

## 6. Encoding Categorical Features

Two columns are still text: `sex` and `embarked`. Models cannot read text, so you encode them into numbers. The right encoding depends on how many categories there are and whether they have an order.

### Step 1: Encode a binary category by mapping

`sex` has just two values, so you can map them directly to 0 and 1:

```python
print("sex values:", df["sex"].unique().tolist())

df["sex"] = df["sex"].map({"male": 0, "female": 1})
df["sex"].head()
```

Output:

```
sex values: ['male', 'female']
0    0
1    1
2    1
3    1
4    0
Name: sex, dtype: int64
```

`df["sex"].unique()` confirms there are only two categories. `map({"male": 0, "female": 1})` replaces each text value with its number. Mapping is the simplest encoding and is perfect for a column with exactly two categories.

### Step 2: One-hot encode a multi-category column

`embarked` has three values (S, C, Q). You should not map them to 0, 1, 2, because that would falsely tell the model the ports have an order and that Q is somehow three times S. Instead you one-hot encode: create a separate 0/1 column for each category.

```python
df = pd.get_dummies(df, columns=["embarked"], drop_first=True)

bool_cols = df.select_dtypes("bool").columns
df[bool_cols] = df[bool_cols].astype(int)

df.head()
```

Output:

```
   survived  pclass  sex   age     fare  embarked_Q  embarked_S
0         0       3    0  22.0   7.2500           0           1
1         1       1    1  38.0  71.2833           0           0
2         1       3    1  26.0   7.9250           0           1
3         1       1    1  35.0  53.1000           0           1
4         0       3    0  35.0   8.0500           0           1
```

`pd.get_dummies(df, columns=["embarked"])` replaces the single `embarked` column with one column per category. `drop_first=True` drops one of them (here `embarked_C`) because it is redundant: if both `embarked_Q` and `embarked_S` are 0, the passenger must have boarded at C. The two lines after convert the new True/False columns to clean 0 and 1 integers (newer pandas creates them as booleans; both work for models, but 0/1 is tidier). Reading row 0: `embarked_S` is 1, so that passenger boarded at Southampton.

A quick guide to choosing an encoding:

- **Two categories:** map them to 0 and 1.
- **Several unordered categories** (like ports or cities): one-hot encode with `get_dummies`.
- **Ordered categories** (like small, medium, large): map them to ordered numbers, since the order is meaningful.

Your table is now fully numeric with no missing values, which means it is ready to feed into any model from this course.

---

## 7. Fix the Errors in Your Code

These mistakes are common when cleaning data.

**Mistake 1: One-hot encoding values that are really ordered.**

```python
# Wrong: pclass 1, 2, 3 has a real order, so one-hot throws away that information
df = pd.get_dummies(df, columns=["pclass"])
```

```python
# Correct: leave ordered numeric categories as numbers
# pclass is already 1, 2, 3, which correctly encodes first, second, third class
```

When a category has a meaningful order, keep it as ordered numbers. One-hot encoding discards the order.

**Mistake 2: Mapping a multi-category column to 0, 1, 2.**

```python
# Wrong: this invents a false order and false distances between ports
df["embarked"] = df["embarked"].map({"S": 0, "C": 1, "Q": 2})
```

```python
# Correct: one-hot encode unordered categories
df = pd.get_dummies(df, columns=["embarked"], drop_first=True)
```

Unordered categories must not be numbered, because the model would read fake relationships like "Q is greater than S". Use one-hot encoding instead.

**Mistake 3: Imputing using the whole dataset before splitting.**

```python
# Risky: computing the median over all data lets test information leak into training
df["age"] = df["age"].fillna(df["age"].median())   # median includes test rows
```

```python
# Better in a real pipeline: compute the fill value from the training set only,
# then apply it to both train and test (you will automate this with Pipelines
# in the next course)
```

Strictly, you should learn fill values from the training data only, so the test set stays truly unseen. For this single-table lesson the simple version is fine, but keep the principle in mind.

---

## 8. Exercises

**Exercise 1:** Load the full Titanic dataset and print the missing-value count for every column. Which column has so many missing values that you might drop it entirely?

**Exercise 2:** From the full Titanic data, one-hot encode the `who` column (which has values man, woman, child) with `drop_first=True`, convert the result to 0/1 integers, and print the first few rows.

**Exercise 3:** The `alive` column holds the text "yes" and "no". Map it to 1 and 0 and print the first five values.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
import seaborn as sns

titanic = sns.load_dataset("titanic")
print(titanic.isnull().sum())
```

Output:

```
survived         0
pclass           0
sex              0
age            177
sibsp            0
parch            0
fare             0
embarked         2
class            0
who              0
adult_male       0
deck           688
embark_town      2
alive            0
alone            0
dtype: int64
```

The `deck` column is missing for 688 of 891 passengers, over three quarters of the data. With that little information, imputing it would be mostly guessing, so dropping the column entirely is the sensible choice.

**Solution for Exercise 2:**

```python
import pandas as pd

who_encoded = pd.get_dummies(titanic[["who"]], columns=["who"], drop_first=True)
bool_cols = who_encoded.select_dtypes("bool").columns
who_encoded[bool_cols] = who_encoded[bool_cols].astype(int)
who_encoded.head()
```

Output:

```
   who_man  who_woman
0        1          0
1        0          1
2        0          1
3        0          1
4        1          0
```

The `who` column had three categories, so one-hot encoding with `drop_first=True` produces two columns. A row where both are 0 represents the dropped category, child. Row 0 is a man, row 1 is a woman.

**Solution for Exercise 3:**

```python
mapped = titanic["alive"].map({"no": 0, "yes": 1})
print(mapped.head())
```

Output:

```
0    0
1    1
2    1
3    1
4    0
Name: alive, dtype: int64
```

Because `alive` has exactly two values, a simple map to 0 and 1 is the right encoding. Note that `alive` is really just a text version of the `survived` target, so you would not use both as features in a real model.

---

## Next Up - Lesson 12

You can now take a messy, real dataset and make it model-ready: detect missing values, fill them by imputation, and encode text categories with mapping or one-hot encoding. These cleaning skills apply to every dataset you will ever model.

In Lesson 12, you finish data preparation with feature scaling. Some models care a lot about the scale of your features, where a column ranging into the thousands can drown out one ranging from 0 to 1. You will learn standardization and normalization, and exactly which models need them, completing your toolkit for the capstone.
