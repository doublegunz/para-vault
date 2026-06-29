## 1. Before You Begin

In Lesson 2 you built a tiny network and pushed data through it, but that model never learned anything: its weights were random and its predictions were meaningless. Now you will build a network that actually learns. You will train it on a real dataset, watch its accuracy climb epoch by epoch, and use it to make genuine predictions.

If you took the machine learning courses, you already classified data with logistic regression and decision trees. This lesson solves a classification problem too, but with a neural network. The reward is seeing the full deep learning loop for the first time: compile the model with a loss and an optimizer, call `fit` to train it, then evaluate and predict, all in the familiar Keras style.

### What You'll Build

A notebook that loads a medical dataset of tumor measurements, scales the features, builds a small neural network, trains it to classify each tumor as malignant or benign, evaluates it on held-out data, and predicts on new examples with a confidence score.

### What You'll Learn

- ✅ How to prepare data for a neural network, including why scaling matters
- ✅ How to build a classification network with a sigmoid output
- ✅ What `compile` does, and how to choose a loss, an optimizer, and a metric
- ✅ How to train with `fit` and read the per-epoch training output
- ✅ How to evaluate on a test set and turn predicted probabilities into decisions
- ✅ A first feel for how the network actually learns

### What You'll Need

- The working `dl-setup` environment from Lesson 2 (Keras and TensorFlow ready)
- Comfort with the train/test workflow from the machine learning courses
- A Colab notebook with the GPU enabled

---

## 2. Meet the Dataset

Before modeling, you always get to know your data. You will use the Breast Cancer Wisconsin dataset, which ships with scikit-learn, so there is nothing to download. Each row describes a tumor using 30 numeric measurements, and the goal is to predict whether it is malignant or benign.

```python
import numpy as np
from sklearn.datasets import load_breast_cancer

data = load_breast_cancer()
X, y = data.data, data.target

print("X shape:", X.shape)
print("y shape:", y.shape)
print("classes:", dict(zip(data.target_names, np.bincount(y))))
```

`load_breast_cancer()` returns the dataset, where `data.data` is the feature matrix and `data.target` is the label for each row. The labels are `0` for malignant and `1` for benign. Running it gives:

```
X shape: (569, 30)
y shape: (569,)
classes: {'malignant': 212, 'benign': 357}
```

There are 569 tumors, each described by 30 features such as radius, texture, and smoothness. The target has two classes, 212 malignant and 357 benign, which makes this a binary classification problem. The classes are reasonably balanced, so plain accuracy will be a fair measure here.

---

## 3. Prepare the Data

Neural networks are picky about their input. The same train, test, and scale steps you know from classical machine learning apply here, but scaling is no longer optional: it is essential for a network to train well.

### Step 1: Split into train and test

```python
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
print("train:", X_train.shape, "test:", X_test.shape)
```

Output:

```
train: (455, 30) test: (114, 30)
```

This is the same `train_test_split` you used before. Eighty percent of the tumors go to training and twenty percent are held out for testing. The `stratify=y` argument keeps the same malignant-to-benign ratio in both sets, and `random_state=42` makes the split reproducible.

### Step 2: Scale the features

```python
from sklearn.preprocessing import StandardScaler

scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)

print("train mean ~0:", round(float(X_train.mean()), 6))
print("train std ~1:", round(float(X_train.std()), 6))
```

Output:

```
train mean ~0: -0.0
train std ~1: 1.0
```

`StandardScaler` rescales every feature so it has a mean near 0 and a standard deviation near 1. This matters far more for neural networks than for models like decision trees. A network learns by taking small steps to reduce its error, and when features live on wildly different scales, those steps become unstable and training stalls. Notice that you call `fit_transform` on the training data but only `transform` on the test data. Fitting the scaler on the test set would leak information from data the model is supposed to have never seen, exactly the leakage trap you learned to avoid with pipelines.

---

## 4. Build the Network

Now define the model. This is a small network, but it has everything a real one does: an input, hidden layers that learn features, and an output layer shaped for the task.

### Step 1: Define the layers

```python
from tensorflow import keras
from tensorflow.keras import layers

keras.utils.set_random_seed(42)
model = keras.Sequential([
    layers.Input(shape=(30,)),
    layers.Dense(16, activation="relu"),
    layers.Dense(8, activation="relu"),
    layers.Dense(1, activation="sigmoid")
])
```

`keras.utils.set_random_seed(42)` fixes the random starting weights so your results match this lesson closely. Inside the model, `layers.Input(shape=(30,))` declares that each example has 30 features. The two hidden `Dense` layers with 16 and 8 neurons do the learning, each using the `relu` activation. The final layer is the important one for classification: `layers.Dense(1, activation="sigmoid")` has a single neuron with a `sigmoid` activation, which squeezes its output into a value between 0 and 1. You read that value as the probability that the tumor is benign.

### Step 2: Compile the model

A model in Keras must be compiled before training. Compiling tells it how to measure its error and how to improve.

```python
model.compile(
    optimizer="adam",
    loss="binary_crossentropy",
    metrics=["accuracy"]
)
```

The three arguments are the heart of training:

- `optimizer="adam"` is the algorithm that adjusts the weights to reduce the error. Adam is a reliable default you will use constantly.
- `loss="binary_crossentropy"` is the number the model tries to make small. Binary crossentropy measures how far the predicted probabilities are from the true 0 or 1 labels, which is the right loss for two-class problems.
- `metrics=["accuracy"]` is a human-friendly score reported during training. Unlike the loss, accuracy is not what the model optimizes; it is just there so you can read progress.

You will dig into loss and optimizers in Lesson 4. For now, treat this line as the standard setup for a binary classifier.

### Step 3: Inspect the model

```python
model.summary()
```

Output:

```
Model: "sequential"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┓
┃ Layer (type)                    ┃ Output Shape           ┃       Param # ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━┩
│ dense (Dense)                   │ (None, 16)             │           496 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense_1 (Dense)                 │ (None, 8)              │           136 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense_2 (Dense)                 │ (None, 1)              │             9 │
└─────────────────────────────────┴────────────────────────┴───────────────┘
 Total params: 641 (2.50 KB)
 Trainable params: 641 (2.50 KB)
 Non-trainable params: 0 (0.00 B)
```

The first layer has 496 parameters: 30 inputs times 16 neurons is 480 weights, plus 16 biases. The model has 641 trainable parameters in total, all of which start random and will be tuned during training. That is what the next step does.

---

## 5. Train the Network

Training is a single call to `fit`, but several arguments control how it runs. This is where the random weights turn into a model that classifies tumors.

### Step 1: Call fit

```python
history = model.fit(
    X_train, y_train,
    validation_split=0.2,
    epochs=20,
    batch_size=16,
    verbose=2
)
```

Each argument has a clear job:

- `validation_split=0.2` sets aside the last 20 percent of the training data as a validation set. The model never trains on it, so its score on that slice is an honest check during training.
- `epochs=20` means the model passes over the training data 20 times. Each pass is a chance to improve.
- `batch_size=16` means the weights are updated after every 16 examples rather than after the whole dataset, which makes learning faster and smoother.
- `verbose=2` prints one tidy line per epoch.

Running it produces this, with the timing column varying from run to run:

```
Epoch 1/20
23/23 - 1s - 32ms/step - accuracy: 0.7335 - loss: 0.5788 - val_accuracy: 0.8462 - val_loss: 0.4981
Epoch 2/20
23/23 - 0s - 3ms/step - accuracy: 0.8956 - loss: 0.4188 - val_accuracy: 0.9231 - val_loss: 0.3733
Epoch 3/20
23/23 - 0s - 3ms/step - accuracy: 0.9231 - loss: 0.3149 - val_accuracy: 0.9231 - val_loss: 0.2839
Epoch 4/20
23/23 - 0s - 3ms/step - accuracy: 0.9451 - loss: 0.2446 - val_accuracy: 0.9341 - val_loss: 0.2268
Epoch 5/20
23/23 - 0s - 3ms/step - accuracy: 0.9505 - loss: 0.1977 - val_accuracy: 0.9341 - val_loss: 0.1882
Epoch 6/20
23/23 - 0s - 3ms/step - accuracy: 0.9533 - loss: 0.1653 - val_accuracy: 0.9341 - val_loss: 0.1613
Epoch 7/20
23/23 - 0s - 3ms/step - accuracy: 0.9560 - loss: 0.1426 - val_accuracy: 0.9560 - val_loss: 0.1417
Epoch 8/20
23/23 - 0s - 3ms/step - accuracy: 0.9670 - loss: 0.1257 - val_accuracy: 0.9670 - val_loss: 0.1258
Epoch 9/20
23/23 - 0s - 3ms/step - accuracy: 0.9698 - loss: 0.1128 - val_accuracy: 0.9670 - val_loss: 0.1131
Epoch 10/20
23/23 - 0s - 3ms/step - accuracy: 0.9725 - loss: 0.1032 - val_accuracy: 0.9780 - val_loss: 0.1026
Epoch 11/20
23/23 - 0s - 3ms/step - accuracy: 0.9725 - loss: 0.0954 - val_accuracy: 0.9780 - val_loss: 0.0936
Epoch 12/20
23/23 - 0s - 3ms/step - accuracy: 0.9725 - loss: 0.0888 - val_accuracy: 0.9780 - val_loss: 0.0854
Epoch 13/20
23/23 - 0s - 3ms/step - accuracy: 0.9725 - loss: 0.0829 - val_accuracy: 0.9780 - val_loss: 0.0790
Epoch 14/20
23/23 - 0s - 3ms/step - accuracy: 0.9753 - loss: 0.0781 - val_accuracy: 0.9780 - val_loss: 0.0737
Epoch 15/20
23/23 - 0s - 3ms/step - accuracy: 0.9808 - loss: 0.0735 - val_accuracy: 0.9780 - val_loss: 0.0692
Epoch 16/20
23/23 - 0s - 3ms/step - accuracy: 0.9808 - loss: 0.0694 - val_accuracy: 0.9890 - val_loss: 0.0656
Epoch 17/20
23/23 - 0s - 3ms/step - accuracy: 0.9808 - loss: 0.0658 - val_accuracy: 0.9890 - val_loss: 0.0626
Epoch 18/20
23/23 - 0s - 3ms/step - accuracy: 0.9808 - loss: 0.0628 - val_accuracy: 0.9890 - val_loss: 0.0598
Epoch 19/20
23/23 - 0s - 3ms/step - accuracy: 0.9835 - loss: 0.0602 - val_accuracy: 0.9890 - val_loss: 0.0573
Epoch 20/20
23/23 - 0s - 3ms/step - accuracy: 0.9835 - loss: 0.0576 - val_accuracy: 0.9890 - val_loss: 0.0551
```

### Step 2: Read the output

This printout tells a story, so learn to read it. The `23/23` is the number of batches per epoch: 364 training examples (after the validation split) divided by a batch size of 16 rounds up to 23. The `loss` falls steadily from 0.58 to 0.06, which means the model's predictions are getting closer to the truth. The `accuracy` rises from 0.73 to 0.98 on the training data. Most importantly, `val_accuracy` climbs to 0.99 on the validation slice the model never trained on, so the model is genuinely learning patterns, not just memorizing. When the training and validation scores move up together like this, training is healthy.

The `history` object you saved holds these numbers for every epoch, which is handy for plotting a learning curve later in the course.

---

## 6. Evaluate and Use the Model

Training scores look good, but the real test is data the model has never touched. That is what the held-out test set is for.

### Step 1: Evaluate on the test set

```python
test_loss, test_acc = model.evaluate(X_test, y_test, verbose=0)
print("Test loss:", round(test_loss, 4))
print("Test accuracy:", round(test_acc, 4))
```

Output:

```
Test loss: 0.1097
Test accuracy: 0.9474
```

`model.evaluate` runs the model on the test set and returns the loss and any metrics you compiled with. About 0.95 accuracy on completely unseen tumors is a strong result for a model this small with so little code. Setting `verbose=0` just keeps it from printing its own progress bar.

### Step 2: Predict with confidence scores

```python
probs = model.predict(X_test[:5], verbose=0)
print("probabilities:", probs.ravel().round(3))
print("predicted labels:", (probs.ravel() > 0.5).astype(int))
print("true labels:    ", y_test[:5])
```

Output:

```
probabilities: [0.    1.    0.002 0.506 0.   ]
predicted labels: [0 1 0 1 0]
true labels:     [0 1 0 1 0]
```

Because the output layer uses a sigmoid, each prediction is a probability between 0 and 1 that the tumor is benign. To turn a probability into a decision, you apply a threshold of 0.5: above it predicts benign (1), below it predicts malignant (0). All five predictions match the true labels here. Notice the fourth value, 0.506. The model is barely above the threshold, so it predicts benign but with low confidence. Those borderline cases are exactly where you would want a human to take a closer look, and reading the raw probability instead of just the label is what lets you spot them.

---

## 7. How the Network Learned

Step back and look at what just happened, because the same loop powers every model in this course. You never told the network which measurements matter or how to weigh them. You gave it raw features and correct answers, and it found the pattern by itself.

Here is the cycle that ran 20 times. The network made predictions on a batch of tumors, the loss function measured how wrong those predictions were, and the optimizer nudged all 641 weights a little in the direction that would reduce that error. Repeat across every batch and every epoch, and the loss falls while accuracy rises. That is the entire idea behind training a neural network: predict, measure the error, adjust, and repeat.

This is also what makes deep learning different from the logistic regression you may have used before on a similar task. Logistic regression draws a single straight boundary between classes. Your network, with its hidden layers, can bend and combine features into a more flexible boundary, which is why even this tiny model performs so well. In Lesson 4 you will open up this learning loop and see exactly how the loss and the optimizer work together to find good weights.

---

## 8. Fix the Errors in Your Code

These mistakes trip up almost everyone training their first network. Learn to recognize them.

**Mistake 1: Forgetting to scale the features.**

```python
# Wrong: training on raw, unscaled features
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
model.fit(X_train, y_train, epochs=20, batch_size=16)
```

```python
# Correct: scale first, then train
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)
model.fit(X_train, y_train, epochs=20, batch_size=16)
```

Unscaled features make gradient descent unstable, so the model trains slowly or gets stuck at poor accuracy. Scaling is one of the highest-impact habits in deep learning.

**Mistake 2: Using the wrong output layer for the task.**

```python
# Wrong: no activation on the output, but using a probability loss
layers.Dense(1)  # raw number, not a probability
# compiled with loss="binary_crossentropy"
```

```python
# Correct: sigmoid squeezes the output into a 0 to 1 probability
layers.Dense(1, activation="sigmoid")
```

For binary classification with `binary_crossentropy`, the output must be a probability, which means a single neuron with a `sigmoid` activation. Leaving the activation off produces unbounded numbers that do not match the loss.

**Mistake 3: Fitting the scaler on the test data.**

```python
# Wrong: this leaks test information into preprocessing
X_test = scaler.fit_transform(X_test)
```

```python
# Correct: only transform the test set with the scaler fit on training data
X_test = scaler.transform(X_test)
```

The scaler must learn its mean and standard deviation from the training data alone. Calling `fit_transform` on the test set lets information leak in and gives you an overly optimistic, dishonest score.

---

## 9. Exercises

**Exercise 1:** Build a deeper network for the same task with three hidden layers of 32, 16, and 8 neurons (all `relu`) plus the sigmoid output. Train it for 20 epochs with the same settings and print the test accuracy. Did the extra depth help?

**Exercise 2:** Take the original network from the lesson but train it for only 5 epochs instead of 20. Print the test accuracy and compare it to the 20-epoch result. What does this tell you about training time?

**Exercise 3:** Using the trained model, predict on the test example at index 3 (the borderline one) and print its probability, its predicted label, and its true label. Decide whether you would trust this prediction.

---

## 10. Solutions

**Solution for Exercise 1:**

```python
from tensorflow import keras
from tensorflow.keras import layers

keras.utils.set_random_seed(42)
deep_model = keras.Sequential([
    layers.Input(shape=(30,)),
    layers.Dense(32, activation="relu"),
    layers.Dense(16, activation="relu"),
    layers.Dense(8, activation="relu"),
    layers.Dense(1, activation="sigmoid")
])
deep_model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
deep_model.fit(X_train, y_train, validation_split=0.2, epochs=20, batch_size=16, verbose=0)
loss, acc = deep_model.evaluate(X_test, y_test, verbose=0)
print("deeper net test accuracy:", round(acc, 4))
```

Output:

```
deeper net test accuracy: 0.9561
```

The deeper network reaches about 0.956, a small step up from the original 0.947. On a clean, simple dataset like this one, more depth gives only a modest gain, and bigger networks can even start to overfit. Adding capacity is not automatically better, a theme you will explore in Module 3.

**Solution for Exercise 2:**

```python
keras.utils.set_random_seed(42)
short_model = keras.Sequential([
    layers.Input(shape=(30,)),
    layers.Dense(16, activation="relu"),
    layers.Dense(8, activation="relu"),
    layers.Dense(1, activation="sigmoid")
])
short_model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
short_model.fit(X_train, y_train, validation_split=0.2, epochs=5, batch_size=16, verbose=0)
loss, acc = short_model.evaluate(X_test, y_test, verbose=0)
print("5-epoch test accuracy:", round(acc, 4))
```

Output:

```
5-epoch test accuracy: 0.9123
```

With only 5 epochs the model reaches about 0.912, noticeably lower than the 0.947 from 20 epochs. The network simply had fewer passes to refine its weights. More epochs usually help up to a point, after which the gains flatten and overfitting can set in.

**Solution for Exercise 3:**

```python
i = 3
prob = float(model.predict(X_test[i:i+1], verbose=0).ravel()[0])
print("probability:", round(prob, 3))
print("predicted label:", int(prob > 0.5))
print("true label:", int(y_test[i]))
```

Output:

```
probability: 0.506
predicted label: 1
true label: 1
```

The probability is 0.506, just barely over the 0.5 threshold, so the model predicts benign and happens to be right. But a confidence this low is a warning sign. In a real medical setting, a near-coin-flip prediction like this is exactly the kind of case you would flag for a specialist rather than trust outright. Reading the probability, not just the label, is what makes that judgment possible.

---

## Next Up - Lesson 4

You built and trained your first real neural network. You prepared and scaled the data, assembled a classifier with a sigmoid output, compiled it with a loss and an optimizer, trained it with `fit` while watching accuracy climb, and evaluated it on unseen tumors at about 95 percent accuracy. You also turned probabilities into decisions and learned to respect borderline predictions. That is a complete deep learning project end to end.

In Lesson 4, you will open up the training loop you just ran. You will see what a loss function really measures, how gradient descent uses it to improve the weights, and what the optimizer and learning rate actually do, so that `compile` and `fit` stop being magic and start being tools you understand.
