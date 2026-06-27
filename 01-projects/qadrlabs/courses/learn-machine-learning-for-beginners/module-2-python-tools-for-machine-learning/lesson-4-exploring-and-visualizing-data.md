## 1. Before You Begin

In Lesson 3 you learned to load and manipulate data with pandas. Now you will learn to understand it. Before training any model, experienced practitioners always explore their data first: they look at its shape, summarize each column, and plot it to find patterns and problems. This step is called Exploratory Data Analysis, or EDA, and skipping it is one of the biggest beginner mistakes.

In this lesson you will explore a real dataset using pandas for summaries and two plotting libraries, matplotlib and seaborn, for visuals. You will see how a few plots can reveal relationships and surprises that raw numbers hide. Good exploration is what lets you choose the right features and the right model later.

### What You'll Build

A notebook that loads the seaborn `tips` dataset (restaurant bills and tips), inspects it with pandas summaries, then visualizes it with histograms, box plots, scatter plots, count plots, and a correlation heatmap. By the end you will be able to size up any new dataset quickly.

### What You'll Learn

- ✅ Why exploratory data analysis comes before modeling
- ✅ How to inspect a dataset with `head`, `info`, and `describe`
- ✅ How to summarize categories with `value_counts`
- ✅ How to plot distributions with histograms and box plots
- ✅ How to plot relationships with scatter plots and count plots
- ✅ How to read correlations and a correlation heatmap

### What You'll Need

- The pandas skills from Lesson 3
- A Colab notebook with `pandas`, `matplotlib`, and `seaborn` imported
- No new installations, since seaborn ships with sample datasets

---

## 2. Why Explore Data First?

It is tempting to jump straight to training a model, but that almost always backfires. Exploratory data analysis is how you build an understanding of your data so your modeling decisions are informed rather than blind.

Exploring first answers questions that shape everything you do next:

- **How big is the data, and what are the columns?** This tells you what you can predict and what you have to work with.
- **What types are the columns?** Numbers and categories are handled differently by models.
- **Are there missing or strange values?** These break models if you ignore them.
- **Which features relate to the thing you want to predict?** Strong relationships are gold for a model.

A famous reminder of why visuals matter is Anscombe's quartet: four datasets with nearly identical averages and correlations that look completely different when plotted. Summary numbers alone can deceive you, so you look at both numbers and pictures. Let us put this into practice on a real dataset.

---

## 3. Load and Inspect the Dataset

We will use the `tips` dataset that comes with seaborn. It records restaurant bills, tips, and details about each table, which makes it perfect for exploring relationships.

### Step 1: Load the dataset

In a new cell, import the libraries and load the data:

```python
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

tips = sns.load_dataset("tips")
tips.head()
```

`sns.load_dataset("tips")` downloads a small built-in dataset and returns it as a pandas DataFrame. `tips.head()` shows the first five rows, which in a Colab notebook renders as a formatted table:

```
   total_bill   tip     sex smoker  day    time  size
0       16.99  1.01  Female     No  Sun  Dinner     2
1       10.34  1.66    Male     No  Sun  Dinner     3
2       21.01  3.50    Male     No  Sun  Dinner     3
3       23.68  3.31    Male     No  Sun  Dinner     2
4       24.59  3.61  Female     No  Sun  Dinner     4
```

Each row is one table at a restaurant. `total_bill` and `tip` are amounts in dollars, `size` is the number of people, and `sex`, `smoker`, `day`, and `time` are categories.

### Step 2: Check the size

```python
print(tips.shape)
```

Output:

```
(244, 7)
```

There are 244 rows (tables) and 7 columns. Always check this first, so you know the scale of what you are working with.

### Step 3: Inspect column types and missing values

```python
tips.info()
```

Output:

```
<class 'pandas.DataFrame'>
RangeIndex: 244 entries, 0 to 243
Data columns (total 7 columns):
 #   Column      Non-Null Count  Dtype   
---  ------      --------------  -----   
 0   total_bill  244 non-null    float64 
 1   tip         244 non-null    float64 
 2   sex         244 non-null    category
 3   smoker      244 non-null    category
 4   day         244 non-null    category
 5   time        244 non-null    category
 6   size        244 non-null    int64   
dtypes: category(4), float64(2), int64(1)
memory usage: 7.4 KB
```

`info()` is one of the most useful commands in pandas. The `Non-Null Count` column shows 244 for every column, which means there are no missing values here. The `Dtype` column tells you the type: `float64` for decimals, `int64` for whole numbers, and `category` for the text categories. Knowing types matters because numbers and categories are plotted and modeled differently.

### Step 4: Summarize the numbers

```python
tips.describe()
```

Output:

```
       total_bill         tip        size
count  244.000000  244.000000  244.000000
mean    19.785943    2.998279    2.569672
std      8.902412    1.383638    0.951100
min      3.070000    1.000000    1.000000
25%     13.347500    2.000000    2.000000
50%     17.795000    2.900000    2.000000
75%     24.127500    3.562500    3.000000
max     50.810000   10.000000    6.000000
```

`describe()` summarizes the numeric columns. You can already read a story here: the average bill is about 19.79 dollars, the average tip about 3.00 dollars, and the median table size is 2 people. The biggest bill was 50.81 dollars and the biggest tip 10 dollars. These numbers give you a baseline before you plot anything.

---

## 4. Summarize Categorical Columns

`describe()` skips category columns, so to summarize them you count how often each value appears with `value_counts()`.

### Step 1: Count categories

```python
tips["day"].value_counts()
```

Output:

```
day
Sat     87
Sun     76
Thur    62
Fri     19
Name: count, dtype: int64
```

`value_counts()` tallies how many rows fall into each category, sorted from most to least common. Here you see most tables were on Saturday and Sunday, and Friday was the quietest day. This is the go-to tool for understanding any category column, and it instantly flags rare categories you might need to handle carefully later.

---

## 5. Visualize Distributions

Numbers summarize, but plots reveal shape. A distribution plot shows how the values of a single column are spread out, which tells you about typical values, outliers, and skew.

### Step 1: Plot a histogram

A histogram groups values into bins and shows how many fall in each bin:

```python
sns.histplot(data=tips, x="total_bill", bins=20)
plt.title("Distribution of Total Bill")
plt.show()
```

`sns.histplot()` draws the histogram, `data=tips` is the DataFrame, `x="total_bill"` is the column to plot, and `bins=20` splits the range into 20 bars. `plt.title()` adds a title and `plt.show()` displays the figure.

You will see a chart where the bars rise quickly and then trail off to the right. Most bills cluster between roughly 10 and 20 dollars, with a long tail of fewer, larger bills up to about 50. This shape, common in money data, is called right-skewed: a bunch of small values and a few large ones pulling the tail out.

### Step 2: Plot a box plot

A box plot summarizes a distribution and is great for comparing groups:

```python
sns.boxplot(data=tips, x="day", y="total_bill")
plt.title("Total Bill by Day")
plt.show()
```

Here `x="day"` puts a separate box for each day and `y="total_bill"` is the value being summarized. Each box spans the middle 50 percent of bills for that day, the line inside the box is the median, and the dots beyond the whiskers are outliers (unusually large bills). Reading it, weekend days show slightly higher and more spread-out bills, and you can spot a few large outlier bills. Box plots make group comparisons fast.

---

## 6. Visualize Relationships

The most valuable plots show how two columns relate, because relationships are exactly what a model learns. 

### Step 1: Plot a scatter plot

A scatter plot puts one numeric column on each axis and draws a dot for every row:

```python
sns.scatterplot(data=tips, x="total_bill", y="tip")
plt.title("Tip vs Total Bill")
plt.show()
```

`x="total_bill"` and `y="tip"` map the two numeric columns to the axes. Each dot is one table. The chart shows a clear upward trend: as the total bill grows, the tip tends to grow too. That makes intuitive sense and signals that `total_bill` would be a useful feature for predicting `tip`. Spotting trends like this is the whole point of a scatter plot.

### Step 2: Plot a count plot

For a category column, a count plot is the visual version of `value_counts()`:

```python
sns.countplot(data=tips, x="day")
plt.title("Number of Tables by Day")
plt.show()
```

`sns.countplot()` draws one bar per category, with the bar height equal to the number of rows. You will see four bars, with Saturday tallest, then Sunday, Thursday, and a short Friday bar. It is the same information as `value_counts()`, but a picture makes the imbalance between days obvious at a glance.

---

## 7. Correlations Between Numeric Features

A correlation measures how strongly two numeric columns move together, on a scale from -1 to 1. A value near 1 means they rise together, near -1 means one rises as the other falls, and near 0 means little linear relationship. This is a fast way to find which features relate to your target.

### Step 1: Compute the correlation table

```python
tips[["total_bill", "tip", "size"]].corr()
```

Output:

```
            total_bill       tip      size
total_bill    1.000000  0.675734  0.598315
tip           0.675734  1.000000  0.489299
size          0.598315  0.489299  1.000000
```

`corr()` computes the correlation between every pair of numeric columns. The diagonal is always 1 because every column correlates perfectly with itself. The interesting cell is `total_bill` versus `tip` at 0.68, a fairly strong positive correlation that confirms what the scatter plot showed. `size` also correlates with both, which makes sense: bigger groups spend and tip more.

### Step 2: Visualize correlations with a heatmap

A heatmap turns that table into color, which is much easier to scan when you have many columns:

```python
sns.heatmap(tips[["total_bill", "tip", "size"]].corr(), annot=True, cmap="coolwarm")
plt.title("Correlation Heatmap")
plt.show()
```

`sns.heatmap()` colors each cell by its value, `annot=True` writes the number inside each cell, and `cmap="coolwarm"` uses warm colors for high values and cool colors for low ones. You will see a grid where the strong `total_bill` and `tip` relationship stands out as a warmer color. With real datasets that have dozens of columns, a heatmap is the quickest way to spot which features are worth your attention.

---

## 8. Fix the Errors in Your Code

These mistakes are common when you start plotting. Recognizing them saves a lot of confusion.

**Mistake 1: Forgetting to pass the data argument.**

```python
# Wrong: seaborn does not know which DataFrame "total_bill" comes from
sns.histplot(x="total_bill")
```

```python
# Correct: tell seaborn which DataFrame to use
sns.histplot(data=tips, x="total_bill")
```

When you reference a column by name, seaborn needs `data=` to know which DataFrame that name belongs to.

**Mistake 2: Using a numeric plot on a category column (or the reverse).**

```python
# Wrong: a histogram expects a numeric column, not a category like "day"
sns.histplot(data=tips, x="day")
```

```python
# Correct: use a count plot for categories
sns.countplot(data=tips, x="day")
```

Match the plot to the column type: histograms and scatter plots for numbers, count plots and bar plots for categories.

**Mistake 3: Calling corr on the whole DataFrame including text columns.**

```python
# Wrong: older pandas errors when text columns are included
tips.corr()
```

```python
# Correct: select numeric columns first, or pass numeric_only=True
tips[["total_bill", "tip", "size"]].corr()
tips.corr(numeric_only=True)
```

Correlation is only defined for numbers, so select the numeric columns or use `numeric_only=True` to tell pandas to skip the rest.

---

## 9. Exercises

**Exercise 1:** Load the `tips` dataset and make a histogram of the `tip` column with 15 bins. Describe its shape in a comment.

**Exercise 2:** Make a box plot of `total_bill` split by `time` (Lunch vs Dinner). Which time has higher bills?

**Exercise 3:** Make a scatter plot of `size` on the x-axis and `total_bill` on the y-axis, then compute the correlation between `size` and `total_bill`.

---

## 10. Solutions

**Solution for Exercise 1:**

```python
import seaborn as sns
import matplotlib.pyplot as plt

tips = sns.load_dataset("tips")
sns.histplot(data=tips, x="tip", bins=15)
plt.title("Distribution of Tips")
plt.show()
# Shape: right-skewed, most tips between 2 and 4 dollars with a tail toward 10
```

The histogram of `tip` is right-skewed like the bill, with most tips clustered at the lower end and a few large tips stretching the tail to the right.

**Solution for Exercise 2:**

```python
sns.boxplot(data=tips, x="time", y="total_bill")
plt.title("Total Bill by Time")
plt.show()
```

The two boxes let you compare directly. Dinner bills are higher and more spread out than Lunch bills, with the Dinner box sitting above the Lunch box and showing a few large outliers.

**Solution for Exercise 3:**

```python
sns.scatterplot(data=tips, x="size", y="total_bill")
plt.title("Total Bill vs Party Size")
plt.show()

print(tips[["size", "total_bill"]].corr())
```

Output of the correlation:

```
            size  total_bill
size        1.000000    0.598315
total_bill  0.598315    1.000000
```

The scatter plot shows total bill rising with party size, and the correlation of about 0.60 confirms a moderate positive relationship: larger groups tend to run up larger bills.

---

## Next Up - Lesson 5

You can now explore a dataset end to end: check its size and types, summarize numbers and categories, and visualize distributions, relationships, and correlations. This habit of looking before modeling will serve you in every project, and it directly informs which features to feed a model.

In Lesson 5, you take the leap into machine learning itself. You will learn the core workflow that every supervised model follows: separating features from the target, splitting data into training and test sets, and the universal `fit` and `predict` pattern that scikit-learn uses for every model. It is the foundation for the first model you build in Lesson 6.
