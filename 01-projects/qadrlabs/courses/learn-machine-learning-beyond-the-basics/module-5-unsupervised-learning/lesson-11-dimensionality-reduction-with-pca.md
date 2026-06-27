## 1. Before You Begin

In Lesson 10 you used K-means to group rows into clusters. This lesson covers the other major unsupervised technique, and it works on columns instead of rows. Principal component analysis, or PCA, takes many features and compresses them into a few new ones while keeping most of the information. It is the standard tool for reducing dimensionality.

Why would you want fewer features? Datasets with many columns are hard to visualize (you cannot plot 13 dimensions), can be slow to train on, and may contain redundant features that overlap. PCA tackles all three: it lets you plot high-dimensional data in 2D, it can speed up models, and it removes redundancy by combining correlated features. In this lesson you will apply PCA to the 13-feature wine dataset, see how much information each component keeps, and use it inside a pipeline.

### What You'll Build

A PCA analysis of the wine dataset that compresses 13 features into 2 for visualization, measures how much variance each component captures, finds how many components are needed to keep 95 percent of the information, and plugs PCA into a model pipeline.

### What You'll Learn

- ✅ What dimensionality reduction is and why it helps
- ✅ How PCA combines features into principal components
- ✅ How to read the explained variance ratio
- ✅ How to choose the number of components to keep
- ✅ How to use PCA for 2D visualization
- ✅ How to put PCA into a pipeline before a model

### What You'll Need

- The scaling skills from the beginner course
- The pipeline skills from Lesson 1
- A Colab notebook with scikit-learn

---

## 2. What Is Dimensionality Reduction?

Each feature in your data is a dimension. With 13 features, your data lives in 13-dimensional space, which you cannot picture and which can make models slower and noisier. Dimensionality reduction creates a smaller set of new features that still captures most of the structure in the original ones.

PCA does this by finding the directions in which the data varies the most. These directions are called principal components. The first component is the single direction that captures the most variation in the data; the second captures the most of what is left, at a right angle to the first; and so on. Each component is a combination of the original features. By keeping just the first few components, you keep most of the information in far fewer dimensions.

Two important points before we start. First, like other distance-based methods, PCA needs scaled features, or the largest-valued feature dominates the components. Second, PCA is unsupervised: it looks only at the features, never at any target.

---

## 3. Apply PCA to Compress Features

Let us reduce the wine dataset's 13 features down to 2, the simplest case, which also lets us visualize the data.

### Step 1: Load and scale

```python
from sklearn.datasets import load_wine
from sklearn.preprocessing import StandardScaler

wine = load_wine(as_frame=True)
X = wine.data
y = wine.target          # used only for coloring the plot later
print("original shape:", X.shape)

X_scaled = StandardScaler().fit_transform(X)
```

Output:

```
original shape: (178, 13)
```

The wine data has 178 rows and 13 features. We scale them, because PCA is sensitive to feature scale. The target `y` is kept aside only to color a plot later; PCA itself never uses it.

### Step 2: Reduce to two components

```python
from sklearn.decomposition import PCA

pca = PCA(n_components=2)
X_pca = pca.fit_transform(X_scaled)
print("reduced shape:", X_pca.shape)
print("explained variance ratio:", pca.explained_variance_ratio_.round(4))
print("total explained:", round(pca.explained_variance_ratio_.sum(), 4))
```

Output:

```
reduced shape: (178, 2)
explained variance ratio: [0.362  0.1921]
total explained: 0.5541
```

`PCA(n_components=2)` keeps the top 2 components, and `fit_transform` turns the 13 features into 2. The `explained_variance_ratio_` tells you the fraction of the data's total variance each component captures: the first holds 36.2 percent and the second 19.2 percent, for a combined 55.4 percent. So two numbers retain over half the information that was spread across 13 features. That is the power of PCA, though the amount you keep depends on how many components you take.

---

## 4. Choosing How Many Components to Keep

Two components are great for plotting but may lose too much for modeling. A common rule is to keep enough components to retain a target amount of variance, often 95 percent. The cumulative explained variance tells you how many that takes.

```python
import numpy as np

pca_full = PCA().fit(X_scaled)
cumulative = np.cumsum(pca_full.explained_variance_ratio_)
print("cumulative explained variance:", cumulative.round(4))

n_components_95 = np.argmax(cumulative >= 0.95) + 1
print("components needed for 95%:", n_components_95)
```

Output:

```
cumulative explained variance: [0.362  0.5541 0.6653 0.736  0.8016 0.851  0.8934 0.9202 0.9424 0.9617
 0.9791 0.992  1.    ]
components needed for 95%: 10
```

Calling `PCA()` with no argument keeps all components, and `np.cumsum` adds up their variance ratios so you can see the running total. Reading the list: 2 components give 55 percent, 5 give 80 percent, and you need 10 of the 13 to reach 95 percent. `np.argmax(cumulative >= 0.95) + 1` finds that automatically. For the wine data the features are not very redundant, so heavy compression loses real information. On datasets with more correlated features, PCA often reaches 95 percent with far fewer components.

---

## 5. Visualize High-Dimensional Data in 2D

One of PCA's most practical uses is plotting data you otherwise could not see. With the 2-component projection, you can draw all 13 dimensions on a flat chart.

```python
import matplotlib.pyplot as plt

plt.scatter(X_pca[:, 0], X_pca[:, 1], c=y, cmap="viridis")
plt.xlabel("Principal Component 1")
plt.ylabel("Principal Component 2")
plt.title("Wine Data in 2D (PCA)")
plt.colorbar(label="wine class")
plt.show()
```

`X_pca[:, 0]` and `X_pca[:, 1]` are the two new components, plotted on the axes. We color each point by its true wine class with `c=y` only to see whether the structure makes sense. The plot shows three fairly distinct groups of points, one per wine cultivar, even though PCA never saw the labels. This is a great sanity check: if the classes separate well in 2D, your features carry strong signal. Visualizing data this way often reveals clusters, outliers, and patterns that are invisible in a table.

---

## 6. Use PCA Inside a Pipeline

PCA is a transformer, so it slots into a pipeline right before the model, just like a scaler. This is how you would use it to potentially speed up or denoise a model.

```python
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.3, random_state=42, stratify=y
)

full = Pipeline([("sc", StandardScaler()), ("clf", LogisticRegression(max_iter=5000))])
reduced = Pipeline([("sc", StandardScaler()), ("pca", PCA(n_components=2)), ("clf", LogisticRegression(max_iter=5000))])

print("full-feature cv:", round(cross_val_score(full, X_train, y_train, cv=5).mean(), 4))
print("2-component cv:", round(cross_val_score(reduced, X_train, y_train, cv=5).mean(), 4))
```

Output:

```
full-feature cv: 0.9837
2-component cv: 0.9677
```

The PCA pipeline scales, then reduces to 2 components, then classifies, all leak-free inside cross-validation. Using all 13 features scores 0.9837, while just 2 components scores 0.9677. You lost only about 1.6 points of accuracy while throwing away 11 of 13 features. On this small, clean dataset the full model wins slightly, but on large datasets with many redundant features, PCA can speed up training dramatically with little or no accuracy loss, and sometimes it even helps by removing noise.

---

## 7. Fix the Errors in Your Code

These mistakes are common with PCA.

**Mistake 1: Running PCA without scaling.**

```python
# Wrong: unscaled features let the largest-valued one dominate the components
X_pca = PCA(n_components=2).fit_transform(X)
```

```python
# Correct: scale first, since PCA is variance-based and scale-sensitive
X_scaled = StandardScaler().fit_transform(X)
X_pca = PCA(n_components=2).fit_transform(X_scaled)
```

PCA finds directions of maximum variance, so a feature with a large range would dominate purely because of its units. Always scale first.

**Mistake 2: Fitting PCA on all the data before splitting.**

```python
# Wrong: fitting PCA on the whole dataset leaks test information
X_pca = PCA(n_components=2).fit_transform(X_scaled)
X_train, X_test = train_test_split(X_pca, ...)
```

```python
# Correct: put PCA in a pipeline so it fits on training folds only
reduced = Pipeline([("sc", StandardScaler()), ("pca", PCA(n_components=2)), ("clf", LogisticRegression(max_iter=5000))])
cross_val_score(reduced, X_train, y_train, cv=5)
```

Like any transformer, PCA must learn its components from training data only. A pipeline guarantees this inside cross-validation.

**Mistake 3: Expecting interpretable features after PCA.**

```python
# Misleading: principal components are not your original features
# "PC1" is a blend of all 13 original columns, not "alcohol" or "fare"
```

```python
# Keep in mind: PCA trades interpretability for compactness
# use original features when you need to explain the model
```

Principal components are combinations of all the original features, so they do not have simple meanings. If interpretability matters, weigh that against the compression PCA gives you.

---

## 8. Exercises

**Exercise 1:** Apply PCA with 3 components to the scaled wine data and print the explained variance ratio and the total variance retained.

**Exercise 2:** Using the full PCA fit, find how many components are needed to retain at least 90 percent of the variance.

**Exercise 3:** Compare the test accuracy of a full-feature logistic regression pipeline against a 2-component PCA pipeline on the wine data. How much accuracy is lost?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from sklearn.datasets import load_wine
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

X = load_wine(as_frame=True).data
X_scaled = StandardScaler().fit_transform(X)

pca3 = PCA(n_components=3).fit(X_scaled)
print("explained variance ratio:", pca3.explained_variance_ratio_.round(4))
print("total:", round(pca3.explained_variance_ratio_.sum(), 4))
```

Output:

```
explained variance ratio: [0.362  0.1921 0.1112]
total: 0.6653
```

Adding a third component captures another 11.1 percent of the variance, bringing the total to 66.5 percent. Each successive component explains less than the one before, which is always true of PCA: the components are ordered from most to least informative.

**Solution for Exercise 2:**

```python
import numpy as np

cumulative = np.cumsum(PCA().fit(X_scaled).explained_variance_ratio_)
print("components for 90%:", np.argmax(cumulative >= 0.90) + 1)
```

Output:

```
components for 90%: 8
```

You need 8 of the 13 components to retain 90 percent of the variance (compared to 10 for 95 percent). The wine features are only mildly redundant, so the data does not compress as aggressively as datasets with many correlated columns would.

**Solution for Exercise 3:**

```python
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score

y = load_wine(as_frame=True).target
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)

full = Pipeline([("sc", StandardScaler()), ("clf", LogisticRegression(max_iter=5000))]).fit(X_train, y_train)
pca2 = Pipeline([("sc", StandardScaler()), ("pca", PCA(n_components=2)), ("clf", LogisticRegression(max_iter=5000))]).fit(X_train, y_train)

print("full test:", round(accuracy_score(y_test, full.predict(X_test)), 4))
print("pca2 test:", round(accuracy_score(y_test, pca2.predict(X_test)), 4))
```

Output:

```
full test: 0.9815
pca2 test: 0.9444
```

Compressing to 2 components costs about 3.7 points of test accuracy (0.9815 to 0.9444) while using only 2 of 13 features. Whether that trade is worth it depends on your goal: for a quick visualization or a much faster model on huge data, it is often well worth it; when you need every last point of accuracy on small data, keep more components.

---

## Next Up - Lesson 12

You can now reduce dimensionality with PCA: compressing many features into a few principal components, reading the explained variance to choose how many to keep, visualizing high-dimensional data in 2D, and folding PCA into a pipeline. Together with K-means, you now have the core unsupervised toolkit.

In Lesson 12, you move into Module 6 and learn to make your models usable beyond the notebook. You will save a fully trained pipeline to disk and load it back, so a model you trained once can make predictions later or in another program, the first step toward putting machine learning into real use.
