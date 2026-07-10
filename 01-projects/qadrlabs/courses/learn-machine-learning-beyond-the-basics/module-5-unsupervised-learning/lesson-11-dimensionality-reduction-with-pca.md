## 1. Before You Begin

In Lesson 10 you used K-means to group rows into clusters. This lesson covers the other major unsupervised technique, and it works on columns instead of rows. Principal component analysis, or PCA, takes many features and compresses them into a few new ones while keeping most of the information. It is the standard tool for reducing dimensionality.

Why would you want fewer features? Datasets with many columns are hard to visualize (you cannot plot 30 dimensions), can be slow to train on, and may contain redundant features that overlap. PCA tackles all three: it lets you plot high-dimensional data in 2D, it can speed up models, and it removes redundancy by combining correlated features. In this lesson you will apply PCA to the 30-feature breast cancer dataset, see how much information each component keeps, and use it inside a pipeline.

### What You'll Build

A PCA analysis of the breast cancer dataset that compresses 30 features into 2 for visualization, measures how much variance each component captures, finds how many components are needed to keep 95 percent of the information, and plugs PCA into a model pipeline.

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

Each feature in your data is a dimension. With 30 features, your data lives in 30-dimensional space, which you cannot picture and which can make models slower and noisier. Dimensionality reduction creates a smaller set of new features that still captures most of the structure in the original ones.

PCA does this by finding the directions in which the data varies the most. These directions are called principal components. The first component is the single direction that captures the most variation in the data; the second captures the most of what is left, at a right angle to the first; and so on. Each component is a combination of the original features. By keeping just the first few components, you keep most of the information in far fewer dimensions.

Two important points before we start. First, like other distance-based methods, PCA needs scaled features, or the largest-valued feature dominates the components. Second, PCA is unsupervised: it looks only at the features, never at any target.

---

## 3. Apply PCA to Compress Features

Let us reduce the breast cancer dataset's 30 features down to 2, the simplest case, which also lets us visualize the data. You met this dataset in the beginner course: 569 tumor samples, each described by 30 measurements of cell size and shape, labeled malignant or benign.

### Step 1: Load and scale

```python
from sklearn.datasets import load_breast_cancer
from sklearn.preprocessing import StandardScaler

cancer = load_breast_cancer(as_frame=True)
X = cancer.data
y = cancer.target        # used only for coloring the plot later
print("original shape:", X.shape)

X_scaled = StandardScaler().fit_transform(X)
```

Output:

```
original shape: (569, 30)
```

The breast cancer data has 569 rows and 30 features. We scale them, because PCA is sensitive to feature scale. The target `y` (0 for malignant, 1 for benign) is kept aside only to color a plot later; PCA itself never uses it.

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
reduced shape: (569, 2)
explained variance ratio: [0.4427 0.1897]
total explained: 0.6324
```

`PCA(n_components=2)` keeps the top 2 components, and `fit_transform` turns the 30 features into 2. The `explained_variance_ratio_` tells you the fraction of the data's total variance each component captures: the first holds 44.3 percent and the second 19.0 percent, for a combined 63.2 percent. So two numbers retain nearly two-thirds of the information that was spread across 30 features. That is the power of PCA, though the amount you keep depends on how many components you take.

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
cumulative explained variance: [0.4427 0.6324 0.7264 0.7924 0.8473 0.8876 0.9101 0.926  0.9399 0.9516
 0.9614 0.9701 0.9781 0.9834 0.9865 0.9892 0.9911 0.9929 0.9945 0.9956
 0.9966 0.9975 0.9983 0.9989 0.9994 0.9997 0.9999 1.     1.     1.    ]
components needed for 95%: 10
```

Calling `PCA()` with no argument keeps all components, and `np.cumsum` adds up their variance ratios so you can see the running total. Reading the list: 2 components give 63 percent, 5 give 85 percent, and just 10 of the 30 reach 95 percent. `np.argmax(cumulative >= 0.95) + 1` finds that automatically. The breast cancer features are highly redundant, since many of them describe related aspects of cell size and shape, so PCA compresses them aggressively: a third of the components carries 95 percent of the information. That is exactly the situation where PCA shines.

---

## 5. Visualize High-Dimensional Data in 2D

One of PCA's most practical uses is plotting data you otherwise could not see. With the 2-component projection, you can draw all 30 dimensions on a flat chart.

```python
import matplotlib.pyplot as plt

plt.scatter(X_pca[:, 0], X_pca[:, 1], c=y, cmap="viridis")
plt.xlabel("Principal Component 1")
plt.ylabel("Principal Component 2")
plt.title("Breast Cancer Data in 2D (PCA)")
plt.colorbar(label="diagnosis (0 = malignant, 1 = benign)")
plt.show()
```

`X_pca[:, 0]` and `X_pca[:, 1]` are the two new components, plotted on the axes. We color each point by its true diagnosis with `c=y` only to see whether the structure makes sense. The plot shows two fairly distinct groups of points, malignant on one side and benign on the other, even though PCA never saw the labels. This is a great sanity check: if the classes separate well in 2D, your features carry strong signal. Visualizing data this way often reveals clusters, outliers, and patterns that are invisible in a table.

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
full-feature cv: 0.9799
2-component cv: 0.9523
```

The PCA pipeline scales, then reduces to 2 components, then classifies, all leak-free inside cross-validation. Using all 30 features scores 0.9799, while just 2 components scores 0.9523. You lost only about 2.8 points of accuracy while throwing away 28 of 30 features. On this small, clean dataset the full model wins slightly, but on large datasets with many redundant features, PCA can speed up training dramatically with little or no accuracy loss, and sometimes it even helps by removing noise.

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
# "PC1" is a blend of all 30 original columns, not "mean radius" or "fare"
```

```python
# Keep in mind: PCA trades interpretability for compactness
# use original features when you need to explain the model
```

Principal components are combinations of all the original features, so they do not have simple meanings. If interpretability matters, weigh that against the compression PCA gives you.

---

## 8. Exercises

**Exercise 1:** Apply PCA with 3 components to the scaled breast cancer data and print the explained variance ratio and the total variance retained.

**Exercise 2:** Using the full PCA fit, find how many components are needed to retain at least 90 percent of the variance.

**Exercise 3:** Compare the test accuracy of a full-feature logistic regression pipeline against a 2-component PCA pipeline on the breast cancer data. How much accuracy is lost?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from sklearn.datasets import load_breast_cancer
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

X = load_breast_cancer(as_frame=True).data
X_scaled = StandardScaler().fit_transform(X)

pca3 = PCA(n_components=3).fit(X_scaled)
print("explained variance ratio:", pca3.explained_variance_ratio_.round(4))
print("total:", round(pca3.explained_variance_ratio_.sum(), 4))
```

Output:

```
explained variance ratio: [0.4427 0.1897 0.0939]
total: 0.7264
```

Adding a third component captures another 9.4 percent of the variance, bringing the total to 72.6 percent. Each successive component explains less than the one before, which is always true of PCA: the components are ordered from most to least informative.

**Solution for Exercise 2:**

```python
import numpy as np

cumulative = np.cumsum(PCA().fit(X_scaled).explained_variance_ratio_)
print("components for 90%:", np.argmax(cumulative >= 0.90) + 1)
```

Output:

```
components for 90%: 7
```

You need only 7 of the 30 components to retain 90 percent of the variance (compared to 10 for 95 percent). The breast cancer features are highly correlated, so the data compresses far more aggressively than a dataset with mostly independent columns would.

**Solution for Exercise 3:**

```python
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score

y = load_breast_cancer(as_frame=True).target
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42, stratify=y)

full = Pipeline([("sc", StandardScaler()), ("clf", LogisticRegression(max_iter=5000))]).fit(X_train, y_train)
pca2 = Pipeline([("sc", StandardScaler()), ("pca", PCA(n_components=2)), ("clf", LogisticRegression(max_iter=5000))]).fit(X_train, y_train)

print("full test:", round(accuracy_score(y_test, full.predict(X_test)), 4))
print("pca2 test:", round(accuracy_score(y_test, pca2.predict(X_test)), 4))
```

Output:

```
full test: 0.9883
pca2 test: 0.9474
```

Compressing to 2 components costs about 4.1 points of test accuracy (0.9883 to 0.9474) while using only 2 of 30 features. Whether that trade is worth it depends on your goal: for a quick visualization or a much faster model on huge data, it is often well worth it; when you need every last point of accuracy on small data, keep more components.

---

## Next Up - Lesson 12

You can now reduce dimensionality with PCA: compressing many features into a few principal components, reading the explained variance to choose how many to keep, visualizing high-dimensional data in 2D, and folding PCA into a pipeline. Together with K-means, you now have the core unsupervised toolkit.

In Lesson 12, you move into Module 6 and learn to make your models usable beyond the notebook. You will save a fully trained pipeline to disk and load it back, so a model you trained once can make predictions later or in another program, the first step toward putting machine learning into real use.
