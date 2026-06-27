## 1. Before You Begin

Every model so far has been supervised: you had a target column, and the model learned to predict it. This lesson opens a new door. In unsupervised learning there is no target. You give the algorithm only the features and ask it to find structure on its own. The most common unsupervised task is clustering, grouping similar examples together, and the most popular clustering algorithm is K-means.

Clustering answers questions like "what natural groups exist in my customers?" or "do these data points fall into distinct types?" without anyone labeling the answer first. In this lesson you will run K-means on the Iris measurements while ignoring the species labels, learn how to choose the number of clusters with the elbow method and the silhouette score, and see how well the discovered groups match reality.

### What You'll Build

A K-means clustering analysis of the Iris flowers using only their measurements. You will form clusters, use the elbow method and silhouette score to decide how many clusters to use, and compare the discovered clusters against the true species to see what the algorithm found.

### What You'll Learn

- ✅ What unsupervised learning and clustering are
- ✅ How K-means groups data into clusters
- ✅ Why clustering needs scaled features
- ✅ How to choose the number of clusters with the elbow method
- ✅ How to evaluate clusters with the silhouette score
- ✅ How to assign new points to clusters

### What You'll Need

- The scaling skills from the beginner course
- A Colab notebook with scikit-learn
- The Iris dataset (built into scikit-learn)

---

## 2. What Is Unsupervised Learning?

Supervised learning needs labeled examples: emails marked spam or not, passengers marked survived or not. But often you have data with no labels at all, and you want to discover patterns in it. That is unsupervised learning. There is no "right answer" to predict; the goal is to find structure.

Clustering is the most common unsupervised task. It partitions your data into groups (clusters) so that points in the same cluster are similar and points in different clusters are different. Real uses include segmenting customers by behavior, grouping documents by topic, and spotting distinct types of sensor readings.

K-means is the go-to clustering algorithm. You tell it how many clusters you want, called k, and it works in a simple loop: it places k cluster centers, assigns each point to its nearest center, moves each center to the average of its assigned points, and repeats until the centers stop moving. Because it measures distance to centers, K-means, like KNN and SVM, needs scaled features so no single feature dominates.

---

## 3. Run K-Means

Let us cluster the Iris flowers using only their four measurements. We will deliberately ignore the species labels, since clustering does not use them.

### Step 1: Load and scale the features

```python
from sklearn.datasets import load_iris
from sklearn.preprocessing import StandardScaler

iris = load_iris(as_frame=True)
X = iris.data           # only the measurements, no labels
y_true = iris.target    # kept aside only to check results later

scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)
```

We load the four measurement features into `X` and keep the true species in `y_true` only so we can check our clusters at the end; the algorithm never sees them. `StandardScaler` puts every feature on the same scale, which is essential because K-means measures distances.

### Step 2: Fit K-means and get clusters

```python
import numpy as np
from sklearn.cluster import KMeans

kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
labels = kmeans.fit_predict(X_scaled)

print("cluster sizes:", np.bincount(labels))
print("inertia:", round(kmeans.inertia_, 2))
```

Output:

```
cluster sizes: [53 50 47]
inertia: 139.82
```

`KMeans(n_clusters=3)` asks for 3 clusters. `n_init=10` runs the algorithm 10 times from different random starts and keeps the best, which avoids a poor result from an unlucky start, and `random_state=42` makes it reproducible. `fit_predict` returns a cluster label (0, 1, or 2) for each flower. The three clusters have 53, 50, and 47 members, nicely balanced. `inertia_` is the total squared distance from points to their cluster centers; lower means tighter clusters. But how do we know 3 was the right number? We did not, really, so let us find out.

---

## 4. Choosing k with the Elbow Method

In real clustering you do not know how many groups exist. The elbow method helps you guess. You run K-means for a range of k values and plot the inertia. As k rises, inertia always falls (more clusters fit tighter), but at some point the improvement slows sharply, forming an "elbow". That bend suggests a good k.

```python
for k in range(1, 7):
    model = KMeans(n_clusters=k, random_state=42, n_init=10).fit(X_scaled)
    print(f"k={k}: inertia={round(model.inertia_, 2)}")
```

Output:

```
k=1: inertia=600.0
k=2: inertia=222.36
k=3: inertia=139.82
k=4: inertia=114.09
k=5: inertia=90.93
k=6: inertia=81.54
```

Read the drops between consecutive values. Going from 1 to 2 clusters slashes inertia from 600 to 222, and 2 to 3 drops it to 140, both big improvements. After that, 3 to 4 only gains a little (140 to 114), and further increases barely help. The "elbow" is around k=3, where adding more clusters stops paying off. Plotting `inertia` against `k` would show this bend visually, but the numbers already make it clear.

---

## 5. Evaluating Clusters with the Silhouette Score

The elbow method is a judgment call. The silhouette score gives a more objective measure. It ranges from -1 to 1 and captures how well each point fits its own cluster versus the nearest other cluster. Higher is better: points are tight within their cluster and far from others.

```python
from sklearn.metrics import silhouette_score

for k in range(2, 7):
    labels = KMeans(n_clusters=k, random_state=42, n_init=10).fit_predict(X_scaled)
    print(f"k={k}: silhouette={round(silhouette_score(X_scaled, labels), 4)}")
```

Output:

```
k=2: silhouette=0.5818
k=3: silhouette=0.4599
k=4: silhouette=0.3869
k=5: silhouette=0.3459
k=6: silhouette=0.3171
```

Interestingly, the silhouette score is highest at k=2 (0.5818), not k=3. This is an honest and instructive disagreement. Two of the three iris species (versicolor and virginica) overlap heavily, so from a pure distance standpoint they look like one cluster, and two well-separated clusters score best. The elbow hinted at 3, the silhouette prefers 2, and we happen to know there are really 3 species. This is the reality of unsupervised learning: there is often no single correct k. You combine the elbow method, the silhouette score, and domain knowledge to make a sensible choice.

---

## 6. How Good Are the Clusters Really?

Because Iris actually has known species, we can peek at how well the k=3 clusters matched them, something you usually cannot do in real unsupervised problems. This is purely a sanity check, not part of the clustering itself.

```python
import pandas as pd

labels = KMeans(n_clusters=3, random_state=42, n_init=10).fit_predict(X_scaled)
print(pd.crosstab(labels, y_true))
```

Output:

```
target   0   1   2
row_0             
0        0  39  14
1       50   0   0
2        0  11  36
```

Each row is a discovered cluster and each column is a true species. Cluster 1 captured all 50 of species 0 (setosa) perfectly, with no contamination, because setosa is clearly separate from the others. Clusters 0 and 2 split species 1 and 2 (versicolor and virginica) imperfectly, mixing them a little, exactly the overlap the silhouette score detected. So K-means, using no labels at all, rediscovered most of the real structure: one species cleanly and the other two approximately. That is a strong result for an algorithm that never saw the answers.

---

## 7. Fix the Errors in Your Code

These mistakes are common with clustering.

**Mistake 1: Clustering without scaling.**

```python
# Wrong: unscaled features let large-valued columns dominate the distances
labels = KMeans(n_clusters=3, n_init=10).fit_predict(X)
```

```python
# Correct: scale first, since K-means is distance-based
X_scaled = StandardScaler().fit_transform(X)
labels = KMeans(n_clusters=3, n_init=10, random_state=42).fit_predict(X_scaled)
```

Like KNN and SVM, K-means measures distance, so unscaled features distort the clusters. Always scale first.

**Mistake 2: Judging cluster count by inertia alone, expecting a "best" value.**

```python
# Misleading: inertia always decreases with more clusters, so lowest is not best
best_k = min(range(1, 10), key=lambda k: KMeans(k, n_init=10).fit(X_scaled).inertia_)
```

```python
# Better: look for the elbow and check the silhouette score
# combine both with domain knowledge to choose k
```

Inertia keeps falling as k grows, reaching 0 when every point is its own cluster. Use the elbow bend and the silhouette score, not the minimum inertia.

**Mistake 3: Forgetting n_init and getting unstable results.**

```python
# Risky: a single random start can land in a poor clustering
KMeans(n_clusters=3)
```

```python
# Better: run several initializations and fix the seed
KMeans(n_clusters=3, n_init=10, random_state=42)
```

K-means depends on its random starting centers. `n_init=10` tries several and keeps the best, and `random_state` makes the result reproducible.

---

## 8. Exercises

**Exercise 1:** Cluster the scaled Iris data with k=2 and print the cluster sizes and silhouette score. Does the score match the lesson's k=2 value?

**Exercise 2:** Fit a 3-cluster K-means on the scaled Iris data, then use `predict` to assign a new flower with small petals (sepal length 5.0, sepal width 3.4, petal length 1.5, petal width 0.2) to a cluster.

**Exercise 3:** Load the wine dataset, scale it, and print the inertia for k from 1 to 5, plus the silhouette score at k=3. Where is the elbow?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
import numpy as np
from sklearn.datasets import load_iris
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

X = load_iris(as_frame=True).data
X_scaled = StandardScaler().fit_transform(X)

km2 = KMeans(n_clusters=2, random_state=42, n_init=10).fit(X_scaled)
print("sizes:", np.bincount(km2.labels_))
print("silhouette:", round(silhouette_score(X_scaled, km2.labels_), 4))
```

Output:

```
sizes: [100  50]
silhouette: 0.5818
```

With k=2, K-means cleanly splits the 50 setosa flowers into one cluster and lumps the overlapping versicolor and virginica (100 flowers) into the other. The silhouette of 0.5818 matches the lesson exactly and is the highest of any k, confirming that two clusters are the most distinct grouping by pure distance.

**Solution for Exercise 2:**

```python
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans

iris = load_iris(as_frame=True)
scaler = StandardScaler().fit(iris.data)
km3 = KMeans(n_clusters=3, random_state=42, n_init=10).fit(scaler.transform(iris.data))

new = pd.DataFrame([{
    "sepal length (cm)": 5.0, "sepal width (cm)": 3.4,
    "petal length (cm)": 1.5, "petal width (cm)": 0.2
}])
print("assigned cluster:", km3.predict(scaler.transform(new)))
```

Output:

```
assigned cluster: [1]
```

The new flower has the tiny petals typical of setosa, and K-means assigns it to cluster 1, the pure setosa cluster from the lesson. Note we scale the new point with the same fitted scaler before predicting, exactly as you would with a supervised model.

**Solution for Exercise 3:**

```python
from sklearn.datasets import load_wine
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

X_wine = StandardScaler().fit_transform(load_wine().data)
for k in range(1, 6):
    print(f"k={k}: inertia={round(KMeans(n_clusters=k, random_state=42, n_init=10).fit(X_wine).inertia_, 2)}")
labels = KMeans(n_clusters=3, random_state=42, n_init=10).fit_predict(X_wine)
print("silhouette k=3:", round(silhouette_score(X_wine, labels), 4))
```

Output:

```
k=1: inertia=2314.0
k=2: inertia=1658.76
k=3: inertia=1277.93
k=4: inertia=1175.43
k=5: inertia=1109.51
silhouette k=3: 0.2849
```

The inertia drops steeply from k=1 to k=3, then the gains shrink, putting the elbow around k=3, which happens to match the three wine cultivars in the data. The silhouette of 0.2849 is modest, reflecting that the wine clusters are less cleanly separated than Iris, a realistic outcome for messier data.

---

## Next Up - Lesson 11

You can now find structure in unlabeled data. K-means groups similar points into clusters, and you choose the number of clusters with the elbow method and the silhouette score, tempered by domain knowledge. Clustering opens up a whole class of problems where there is no target to predict.

In Lesson 11, you will meet another unsupervised technique: principal component analysis, or PCA. Instead of grouping rows, PCA compresses columns, reducing many features into a few while keeping most of the information. It is invaluable for visualizing high-dimensional data and speeding up models.
