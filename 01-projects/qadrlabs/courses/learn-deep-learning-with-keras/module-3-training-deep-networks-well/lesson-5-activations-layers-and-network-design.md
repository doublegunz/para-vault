## 1. Before You Begin

So far you have built networks by following recipes: stack a couple of `Dense` layers, put `relu` on the hidden ones, and `sigmoid` on the output. In this lesson you learn why those choices are made, so you can design a network on purpose instead of by imitation. You will also build your first multiclass classifier, which is a direct stepping stone to the image models in Module 4.

The two design decisions this lesson focuses on are activations and architecture. Activations are the small functions that give a network its power to model complex patterns, and the right output activation depends entirely on your task. Architecture is how many layers and neurons you use. Get these right and a network learns well; get them wrong and it either cannot learn or learns the wrong thing.

### What You'll Build

A multiclass neural network that recognizes handwritten digits from 0 to 9, using a softmax output. Along the way you will see exactly what each activation function does to numbers, and you will compare architectures of different sizes to see how depth and width affect accuracy.

### What You'll Learn

- ✅ What activation functions do and why a network needs them
- ✅ The behavior of `relu`, `sigmoid`, `tanh`, and `softmax`
- ✅ How to choose the output activation and loss for regression, binary, and multiclass tasks
- ✅ How to build and train a multiclass classifier with `softmax`
- ✅ How to reason about the number of layers and neurons

### What You'll Need

- The Keras workflow from Lessons 3 and 4 (`compile`, `fit`, `evaluate`)
- A Colab notebook with Keras ready
- Comfort with scaling data and reading training output

---

## 2. Why Activation Functions Matter

An activation function is applied to the output of each neuron, and it is what lets a network learn curved, complex relationships instead of just straight lines. Here is the crucial fact: without activation functions, stacking layers is pointless. A stack of plain `Dense` layers with no activation is mathematically equal to a single linear layer, no matter how many you add, because chaining linear steps just produces another linear step. The activation injects nonlinearity, and nonlinearity is where the power comes from.

Let us see what the common activations actually do to a range of numbers.

```python
import numpy as np

vals = np.array([-2.0, -1.0, 0.0, 1.0, 2.0])
print("input  :", vals)
print("relu   :", np.maximum(0, vals))
print("sigmoid:", (1 / (1 + np.exp(-vals))).round(3))
print("tanh   :", np.tanh(vals).round(3))
```

Output:

```
input  : [-2. -1.  0.  1.  2.]
relu   : [0. 0. 0. 1. 2.]
sigmoid: [0.119 0.269 0.5   0.731 0.881]
tanh   : [-0.964 -0.762  0.     0.762  0.964]
```

Each one shapes numbers differently:

- **relu** (rectified linear unit) keeps positive values unchanged and turns every negative value into 0. It is simple and fast, which is why it is the default for hidden layers in almost every modern network.
- **sigmoid** squeezes any number into the range 0 to 1, which is why you used it for a binary probability in Lesson 3. Notice it maps 0 to exactly 0.5.
- **tanh** is similar to sigmoid but maps into the range -1 to 1, centered at 0. It shows up in some older and recurrent architectures you will meet in Module 5.

For hidden layers, reach for `relu` unless you have a specific reason not to. The interesting choices happen at the output layer, which is the next section.

---

## 3. Choosing the Output Activation for Your Task

The output layer is where the network's job is decided, and its activation must match the kind of answer you want. This single table is one of the most useful things to memorize in this course.

| Task | Output layer | Loss |
|---|---|---|
| Regression (predict a number) | `Dense(1)` with no activation | `mse` |
| Binary classification (two classes) | `Dense(1, activation="sigmoid")` | `binary_crossentropy` |
| Multiclass (one label out of many) | `Dense(n, activation="softmax")` | `sparse_categorical_crossentropy` |

For regression you leave the output activation off, because you want any real number, not a squashed one. For two classes you use one sigmoid neuron giving a single probability, as you already did. For more than two classes you use **softmax**, which is the new one here.

Softmax takes one number per class and turns them into probabilities that are all positive and add up to 1, so you can read them as "how likely is each class". Watch it work on three raw scores:

```python
logits = np.array([2.0, 1.0, 0.1])
exp = np.exp(logits)
softmax = exp / exp.sum()
print("softmax:", softmax.round(3), "sum:", round(float(softmax.sum()), 3))
```

Output:

```
softmax: [0.659 0.242 0.099] sum: 1.0
```

The largest score, 2.0, gets the largest probability, 0.659, and the three probabilities sum to exactly 1. That is exactly what you want for picking one class out of several. One note on the loss: use `sparse_categorical_crossentropy` when your labels are plain integers like 0, 1, 2, which is the common case. If your labels are one-hot vectors instead, use `categorical_crossentropy`. Same idea, different label format.

---

## 4. Build a Multiclass Classifier

Time to put softmax to work on a real problem with ten classes: recognizing handwritten digits. The `load_digits` dataset in scikit-learn holds small 8 by 8 grayscale images of digits 0 through 9, flattened into 64 features. It is a gentle preview of the image work coming in Module 4.

### Step 1: Load and prepare the data

```python
from sklearn.datasets import load_digits
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

digits = load_digits()
X, y = digits.data, digits.target
print("X shape:", X.shape, "classes:", len(np.unique(y)))

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)
```

Output:

```
X shape: (1797, 64) classes: 10
```

There are 1,797 digit images, each with 64 pixel features, across 10 classes. You apply the same split, stratify, and scale routine from Lesson 3, because neural networks always benefit from scaled inputs.

### Step 2: Build the network with a softmax output

```python
from tensorflow import keras
from tensorflow.keras import layers

keras.utils.set_random_seed(42)
model = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(64, activation="relu"),
    layers.Dense(32, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)
model.summary()
```

Output:

```
Model: "sequential"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┓
┃ Layer (type)                    ┃ Output Shape           ┃       Param # ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━┩
│ dense (Dense)                   │ (None, 64)             │         4,160 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense_1 (Dense)                 │ (None, 32)             │         2,080 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense_2 (Dense)                 │ (None, 10)             │           330 │
└─────────────────────────────────┴────────────────────────┴───────────────┘
 Total params: 6,570 (25.66 KB)
 Trainable params: 6,570 (25.66 KB)
 Non-trainable params: 0 (0.00 B)
```

The only differences from your binary classifier are the output layer and the loss. The output is now `Dense(10, activation="softmax")`, one neuron per digit, and the loss is `sparse_categorical_crossentropy` because the labels are integers 0 through 9. Everything else, including `relu` on the hidden layers, is unchanged.

### Step 3: Train and evaluate

```python
history = model.fit(X_train, y_train, validation_split=0.2,
                    epochs=20, batch_size=32, verbose=0)
print("epoch1 val_acc:", round(history.history['val_accuracy'][0], 4))
print("epoch20 val_acc:", round(history.history['val_accuracy'][-1], 4))

test_loss, test_acc = model.evaluate(X_test, y_test, verbose=0)
print("Test accuracy:", round(test_acc, 4))
```

Output:

```
epoch1 val_acc: 0.4618
epoch20 val_acc: 0.9583
```
```
Test accuracy: 0.9667
```

Here `verbose=0` keeps `fit` quiet and you read progress from the saved `history` instead. Validation accuracy leaps from 0.46 after the first epoch to 0.96 by the end, and the model reaches about 0.97 on the unseen test set. A small network with ten outputs learned to read handwritten digits.

### Step 4: Read a prediction

```python
probs = model.predict(X_test[:1], verbose=0)[0]
print("probabilities:", probs.round(3))
print("sum:", round(float(probs.sum()), 3))
print("predicted:", int(np.argmax(probs)), "true:", int(y_test[0]))
```

Output:

```
probabilities: [0.    0.    0.    0.    0.    0.992 0.    0.    0.    0.008]
sum: 1.0
predicted: 5 true: 5
```

The softmax output gives a probability for each of the ten digits, and they sum to 1. The model puts 0.992 on class 5 and almost nothing on the rest, so `np.argmax` picks index 5 as the prediction, which matches the true label. Reading the full probability vector tells you not just the answer but how confident the model is in it.

---

## 5. Designing the Architecture: Width and Depth

You chose 64 and 32 neurons across two hidden layers, but how would you decide that yourself? Architecture is the number of layers (depth) and the number of neurons per layer (width). More of either gives the network more capacity to learn, but also more ways to overfit and more compute to train. The art is using enough, but not too much.

Compare a much smaller network on the same digits task, with a single hidden layer of just 16 neurons.

```python
keras.utils.set_random_seed(42)
small = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(16, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
small.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
small.fit(X_train, y_train, validation_split=0.2, epochs=20, batch_size=32, verbose=0)
_, small_acc = small.evaluate(X_test, y_test, verbose=0)
print("small (1x16) test accuracy:", round(small_acc, 4))
```

Output:

```
small (1x16) test accuracy: 0.9417
```

The tiny network still reaches about 0.94, only a few points behind the larger one at 0.97. That is a useful lesson: a small network often gets you most of the way, and extra capacity brings diminishing returns. A few practical rules of thumb to start from:

- Begin small and simple, then grow only if the model is underperforming on the training data.
- One or two hidden layers handle most tabular problems. Very deep stacks are for richer data like images and text, which need specialized layers you will meet soon.
- Common widths are powers of two like 32, 64, and 128, mostly out of convention and convenience.
- If a bigger model scores better on training data but worse on validation, you have gone too far and started overfitting, which is the entire subject of Lesson 6.

There is no single correct architecture. You make a reasonable choice, watch the training and validation scores, and adjust. The goal of this section is to give you the vocabulary and instincts to make that choice deliberately.

---

## 6. Fix the Errors in Your Code

These mistakes all come from mismatched activations, outputs, or losses, and they are extremely common.

**Mistake 1: Forgetting activations on the hidden layers.**

```python
# Wrong: no activations, so the whole network collapses to a linear model
model = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(64),
    layers.Dense(32),
    layers.Dense(10, activation="softmax"),
])
```

```python
# Correct: relu on the hidden layers gives the network real expressive power
model = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(64, activation="relu"),
    layers.Dense(32, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
```

Without activations on the hidden layers, stacking them buys you nothing, because the network can only represent straight-line relationships. Always put `relu` (or another nonlinearity) on hidden layers.

**Mistake 2: Using the wrong output shape for multiclass.**

```python
# Wrong: one sigmoid neuron cannot represent 10 classes
layers.Dense(1, activation="sigmoid")
```

```python
# Correct: one softmax neuron per class
layers.Dense(10, activation="softmax")
```

A multiclass problem needs one output neuron per class with softmax. A single sigmoid only works for two classes.

**Mistake 3: Pairing the loss with the wrong label format.**

```python
# Wrong: categorical_crossentropy expects one-hot labels, but y is integers
model.compile(optimizer="adam", loss="categorical_crossentropy", metrics=["accuracy"])
```

```python
# Correct: integer labels go with sparse_categorical_crossentropy
model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
```

When your labels are plain integers like 0 through 9, use `sparse_categorical_crossentropy`. Use `categorical_crossentropy` only when you have converted labels to one-hot vectors. Mixing them up is one of the most frequent Keras errors.

---

## 7. Exercises

**Exercise 1:** Apply `relu` and `sigmoid` by hand to the array `[-3.0, -0.5, 0.0, 0.5, 3.0]`, then confirm your results match `keras.activations.relu` and `keras.activations.sigmoid`.

**Exercise 2:** Build a digit classifier with a single wide hidden layer of 128 neurons (plus the softmax output), train it for 20 epochs, and print the test accuracy. Compare it to the two-layer model from the lesson.

**Exercise 3:** Predict on the test image at index 5, print the full softmax probability vector rounded to 3 places, confirm it sums to 1, and check that the most probable class matches the true label.

---

## 8. Solutions

**Solution for Exercise 1:**

```python
import numpy as np
import tensorflow as tf
from tensorflow import keras

arr = np.array([-3.0, -0.5, 0.0, 0.5, 3.0], dtype="float32")
print("relu hand    :", np.maximum(0, arr))
print("relu keras   :", keras.activations.relu(tf.constant(arr)).numpy())
print("sigmoid hand :", (1 / (1 + np.exp(-arr))).round(4))
print("sigmoid keras:", keras.activations.sigmoid(tf.constant(arr)).numpy().round(4))
```

Output:

```
relu hand    : [0.  0.  0.  0.5 3. ]
relu keras   : [0.  0.  0.  0.5 3. ]
sigmoid hand : [0.0474 0.3775 0.5    0.6225 0.9526]
sigmoid keras: [0.0474 0.3775 0.5    0.6225 0.9526]
```

The hand calculations match Keras exactly. `relu` zeroes the negatives and passes the positives through, while `sigmoid` squashes everything into 0 to 1 with 0 mapping to 0.5. Seeing that the library functions are just these formulas removes any mystery about activations.

**Solution for Exercise 2:**

```python
keras.utils.set_random_seed(42)
wide = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(128, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
wide.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
wide.fit(X_train, y_train, validation_split=0.2, epochs=20, batch_size=32, verbose=0)
_, wide_acc = wide.evaluate(X_test, y_test, verbose=0)
print("wide (1x128) test accuracy:", round(wide_acc, 4))
```

Output:

```
wide (1x128) test accuracy: 0.9778
```

A single wide layer of 128 neurons reaches about 0.978, slightly above the two-layer model's 0.967. This shows that width can substitute for depth on a simple dataset, and that there is rarely one "correct" architecture. What matters is having enough capacity for the problem, then watching for overfitting.

**Solution for Exercise 3:**

```python
probs = model.predict(X_test[5:6], verbose=0)[0]
print("probs:", probs.round(3))
print("sum:", round(float(probs.sum()), 3))
print("predicted:", int(np.argmax(probs)), "true:", int(y_test[5]))
```

Output:

```
probs: [0.    0.    0.944 0.056 0.    0.    0.    0.    0.    0.   ]
sum: 1.0
predicted: 2 true: 2
```

The model puts 0.944 on class 2 and 0.056 on class 3, with everything else near zero, and the probabilities sum to 1. It predicts digit 2, which is correct, though the small mass on class 3 hints the model sees a slight resemblance. Reading the whole vector, not just the winner, is how you gauge confidence and spot near-misses.

---

## Next Up - Lesson 6

You can now design a network with intent. You know that activations give a network its nonlinear power, that `relu` is the default for hidden layers, and that the output activation and loss must match the task: none and `mse` for regression, sigmoid and `binary_crossentropy` for two classes, softmax and `sparse_categorical_crossentropy` for many. You built a digit classifier that hits about 97 percent, and you saw how width and depth trade off when you compared architectures.

In Lesson 6, you will confront the flip side of capacity: overfitting. You will see what it looks like when a model memorizes the training data instead of learning the general pattern, and you will fight back with three essential tools: dropout, regularization, and early stopping.
