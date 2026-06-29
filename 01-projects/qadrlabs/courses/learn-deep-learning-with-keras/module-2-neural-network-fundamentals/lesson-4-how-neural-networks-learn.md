## 1. Before You Begin

In Lesson 3 you trained a network and watched its loss fall and its accuracy rise, but the two lines that made it happen, `compile` and `fit`, were still a black box. You picked `adam` and `binary_crossentropy` because the lesson told you to. Now you will open that box.

This lesson is about the single idea at the core of all deep learning: a network learns by measuring how wrong it is and then nudging its weights to be a little less wrong, over and over. You will see exactly what a loss function computes, watch gradient descent walk downhill to a minimum, feel how the learning rate changes everything, and understand why Adam usually beats plain gradient descent. The math stays light and every idea comes with code you can run.

### What You'll Build

A set of small, runnable demonstrations: you will compute a loss by hand and confirm it matches Keras, write a tiny gradient descent loop that finds the minimum of a function, see how three different learning rates succeed or fail, and compare two optimizers training the network from Lesson 3.

### What You'll Learn

- ✅ What a loss function measures and why lower is better
- ✅ How gradient descent uses the slope of the loss to improve weights
- ✅ What the learning rate is, and what too small and too large look like
- ✅ The difference between SGD and Adam, and why Adam is a strong default
- ✅ How epochs, batches, and backpropagation fit into one training loop

### What You'll Need

- The trained classifier and prepared data from Lesson 3
- A Colab notebook with Keras ready
- Comfort reading the per-epoch training output from Lesson 3

---

## 2. What a Loss Function Measures

A loss function turns "how wrong is the model right now" into a single number. Lower is better, and the entire goal of training is to make this number small. In Lesson 3 the `loss` column fell from 0.58 to 0.06, and that falling number was the model getting better.

Different tasks use different losses. Regression usually uses mean squared error, which averages the squared gaps between predictions and truth. Binary classification, like your tumor model, uses binary crossentropy. It sounds intimidating, but you can compute it by hand to see there is no magic.

```python
import numpy as np
from tensorflow import keras

y_true = np.array([1.0, 0.0, 1.0, 1.0])
y_pred = np.array([0.9, 0.2, 0.6, 0.3])

manual = -np.mean(y_true * np.log(y_pred) + (1 - y_true) * np.log(1 - y_pred))
print("manual BCE:", round(float(manual), 4))

bce = keras.losses.BinaryCrossentropy()
print("keras  BCE:", round(float(bce(y_true, y_pred)), 4))
```

Output:

```
manual BCE: 0.5108
keras  BCE: 0.5108
```

Read the formula one example at a time. When the true label is 1, the penalty is `-log(predicted probability)`, so a confident correct guess like 0.9 earns a tiny penalty, while the underconfident 0.3 for a true 1 earns a large one. When the true label is 0, the penalty flips to `-log(1 - predicted probability)`. Averaging these penalties gives the loss. The key intuition: confident and correct costs almost nothing, confident and wrong costs a lot. Your hand calculation matching Keras exactly proves the loss is just arithmetic the optimizer is trying to minimize.

---

## 3. Gradient Descent: Following the Slope Downhill

So the loss tells you how wrong the model is. How does the model use that to improve? Through gradient descent, the algorithm behind nearly all deep learning training.

Picture the loss as a hilly landscape where the height is the loss and your position is the current set of weights. You want to reach the lowest valley. At any point, the gradient is the slope: it points in the direction the loss increases fastest. So to go downhill, you take a step in the opposite direction. Repeat, and you walk steadily toward a minimum.

You can watch this happen on a simple function. Take `f(x) = (x - 3)^2`, a bowl with its lowest point at `x = 3`. Its slope is `2 * (x - 3)`. Start at `x = 0` and repeatedly step against the slope.

```python
def f(x): return (x - 3) ** 2
def grad(x): return 2 * (x - 3)

x = 0.0
lr = 0.1
print(f"start: x={x:.4f}, loss={f(x):.4f}")
for step in range(1, 16):
    x = x - lr * grad(x)
    if step in (1, 2, 3, 5, 10, 15):
        print(f"step {step:2d}: x={x:.4f}, loss={f(x):.4f}")
```

Output:

```
start: x=0.0000, loss=9.0000
step  1: x=0.6000, loss=5.7600
step  2: x=1.0800, loss=3.6864
step  3: x=1.4640, loss=2.3593
step  5: x=2.0170, loss=0.9664
step 10: x=2.6779, loss=0.1038
step 15: x=2.8944, loss=0.0111
```

The line `x = x - lr * grad(x)` is gradient descent in one line: move `x` opposite to the slope by a small step. Watch `x` climb from 0 toward 3 and the loss shrink from 9 toward 0. The steps are big at first, where the slope is steep, and get smaller as you near the bottom, where the slope flattens. This is exactly what your network did in Lesson 3, except instead of one `x` it adjusted all 641 weights at once, each by its own slope, on every batch.

---

## 4. The Learning Rate

In that loop, `lr` was the learning rate: how big a step you take each time. It is the single most important setting in training, and getting it wrong is the most common reason a network fails to learn. Run the same descent with three different learning rates and the difference is stark.

```python
def run_gd(lr, steps=15, start=0.0):
    x = start
    for _ in range(steps):
        x = x - lr * grad(x)
    return x

for lr in (0.01, 0.1, 1.1):
    xf = run_gd(lr)
    print(f"lr={lr:<4}: x after 15 steps = {xf:.4f}, loss = {f(xf):.4f}")
```

Output:

```
lr=0.01: x after 15 steps = 0.7843, loss = 4.9094
lr=0.1 : x after 15 steps = 2.8944, loss = 0.0111
lr=1.1 : x after 15 steps = 49.2211, loss = 2136.3868
```

Three very different stories from the same function:

- **Too small (0.01):** the steps are tiny, so after 15 of them you have barely crawled from 0 to 0.78. The model would eventually get there, but training would take forever.
- **Just right (0.1):** smooth, fast progress to nearly 3. This is the sweet spot.
- **Too large (1.1):** each step overshoots the minimum so badly that you bounce further away every time. The value explodes to 49 and the loss to over 2000. This is divergence, and in a real network it often shows up as the loss turning into `nan`.

The lesson is that the learning rate must be small enough to be stable but large enough to make real progress. Tuning it is one of the first things you try when a model will not learn.

---

## 5. Optimizers: From SGD to Adam

An optimizer is the rule that decides how to use the gradients to update the weights. The plain version you just coded by hand, applied to mini-batches of data, is called stochastic gradient descent, or SGD. It works, but it uses one fixed learning rate for every weight. Modern optimizers like Adam are smarter: they adapt the step size for each weight automatically and add momentum to push through flat spots, which usually means faster, more reliable training.

You can see the gap by training the Lesson 3 network with each optimizer. Make sure your prepared `X_train`, `y_train`, and the breast cancer data from Lesson 3 are still in memory.

```python
from tensorflow.keras import layers

def build():
    return keras.Sequential([
        layers.Input(shape=(30,)),
        layers.Dense(16, activation="relu"),
        layers.Dense(8, activation="relu"),
        layers.Dense(1, activation="sigmoid"),
    ])

for opt_name in ("sgd", "adam"):
    keras.utils.set_random_seed(42)
    model = build()
    model.compile(optimizer=opt_name, loss="binary_crossentropy", metrics=["accuracy"])
    history = model.fit(X_train, y_train, validation_split=0.2,
                        epochs=10, batch_size=16, verbose=0)
    print(f"{opt_name:>4}: epoch1 val_acc={history.history['val_accuracy'][0]:.4f}  "
          f"epoch10 val_acc={history.history['val_accuracy'][-1]:.4f}")
```

Output:

```
 sgd: epoch1 val_acc=0.8132  epoch10 val_acc=0.9341
adam: epoch1 val_acc=0.8462  epoch10 val_acc=0.9780
```

Both optimizers learn, but Adam is ahead from the very first epoch and reaches a higher validation accuracy by epoch 10. That head start is why Lesson 3 used Adam, and why it is the default you should reach for first. When you do need to control the step size yourself, you pass an optimizer object instead of a string, like `keras.optimizers.Adam(learning_rate=0.001)`, which lets you set the exact learning rate.

---

## 6. Epochs, Batches, and the Full Picture

You now have every piece of the training loop, so let us assemble them into the complete cycle that `fit` runs for you. Two words from Lesson 3 finally make full sense here.

A **batch** is a small group of examples, 16 in your case. The model predicts on one batch, computes the loss for it, and updates the weights once. An **epoch** is one full pass over all the batches, so the weights get updated many times per epoch. With 364 training examples and a batch size of 16, that was 23 updates per epoch, which is the `23/23` you saw.

Here is the whole loop, start to finish:

1. Take a batch of examples and run them through the network to get predictions. This is the forward pass.
2. Use the **loss function** to measure how wrong those predictions are.
3. Use **backpropagation** to compute the gradient of the loss with respect to every weight. This is the method that figures out each weight's slope efficiently, and Keras does it for you automatically.
4. Let the **optimizer** take a step, nudging every weight against its gradient by an amount set by the **learning rate**.
5. Move to the next batch and repeat. After all batches, one epoch is done. Repeat for all epochs.

That is the entire engine of deep learning. Everything you build for the rest of the course, no matter how large, trains with this same loop. `compile` is where you choose the loss and the optimizer; `fit` is where you set the epochs and batch size and let the loop run. The pieces are no longer magic.

---

## 7. Fix the Errors in Your Code

These mistakes all relate to how a model learns, and they are easy to make.

**Mistake 1: Using a regression loss for a classification task.**

```python
# Wrong: mean squared error does not fit a 0/1 classification problem
model.compile(optimizer="adam", loss="mse", metrics=["accuracy"])
```

```python
# Correct: binary crossentropy is the right loss for two classes
model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
```

The loss must match the task. Crossentropy is built to push probabilities toward the correct class, while mean squared error is meant for predicting continuous numbers and will train poorly on labels.

**Mistake 2: Trying to set the learning rate with a string.**

```python
# Wrong: you cannot pass a learning rate inside the string name
model.compile(optimizer="adam(0.001)", loss="binary_crossentropy")
```

```python
# Correct: use an optimizer object to set the learning rate
model.compile(optimizer=keras.optimizers.Adam(learning_rate=0.001),
              loss="binary_crossentropy")
```

The string form like `"adam"` gives you sensible defaults. To control the learning rate, build the optimizer object and pass `learning_rate` to it.

**Mistake 3: Setting the learning rate far too high.**

```python
# Wrong: a huge learning rate makes training overshoot and the loss explode
model.compile(optimizer=keras.optimizers.Adam(learning_rate=1.0),
              loss="binary_crossentropy", metrics=["accuracy"])
```

```python
# Correct: start near the default and only adjust in small factors
model.compile(optimizer=keras.optimizers.Adam(learning_rate=0.001),
              loss="binary_crossentropy", metrics=["accuracy"])
```

A learning rate that is too high causes the same divergence you saw with `lr=1.1` on the bowl. Watch the loss, not just accuracy: if the loss climbs or turns into `nan`, lower the learning rate.

---

## 8. Exercises

**Exercise 1:** Compute mean squared error by hand for `y_true = [3.0, 5.0, 2.5, 7.0]` and `y_pred = [2.5, 5.5, 3.0, 6.0]`, then confirm it matches `keras.losses.MeanSquaredError()`.

**Exercise 2:** Run the gradient descent loop on `f(x) = (x - 3)^2` but start from `x = 10.0` with a learning rate of 0.1 for 15 steps. Print the final `x` and loss. Does it still find the minimum from the other side?

**Exercise 3:** Train the Lesson 3 network with `keras.optimizers.Adam(learning_rate=1.0)` for 10 epochs and print the final `val_loss`. Compare it to the healthy loss values from Lesson 3 and explain what a high loss tells you.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
import numpy as np
from tensorflow import keras

y_true = np.array([3.0, 5.0, 2.5, 7.0])
y_pred = np.array([2.5, 5.5, 3.0, 6.0])

manual = np.mean((y_true - y_pred) ** 2)
print("manual MSE:", round(float(manual), 4))

mse = keras.losses.MeanSquaredError()
print("keras  MSE:", round(float(mse(y_true, y_pred)), 4))
```

Output:

```
manual MSE: 0.4375
keras  MSE: 0.4375
```

Mean squared error is just the average of the squared differences. Three of the four gaps are 0.5 in size and one is 1.0, so the squared errors are 0.25, 0.25, 0.25, and 1.0, averaging to 0.4375. Squaring punishes larger errors much more than small ones, which is why a single big miss dominates the score.

**Solution for Exercise 2:**

```python
def f(x): return (x - 3) ** 2
def grad(x): return 2 * (x - 3)

x = 10.0
for _ in range(15):
    x = x - 0.1 * grad(x)
print("final x:", round(x, 4), "loss:", round(f(x), 4))
```

Output:

```
final x: 3.2463 loss: 0.0607
```

Starting from the other side at 10, gradient descent still walks downhill to the same minimum at 3, landing at about 3.25 after 15 steps. The direction of the step always depends on the slope, so wherever you start, you head toward the valley. The minimum is a property of the function, not of where you begin.

**Solution for Exercise 3:**

```python
keras.utils.set_random_seed(42)
model = keras.Sequential([
    layers.Input(shape=(30,)),
    layers.Dense(16, activation="relu"),
    layers.Dense(8, activation="relu"),
    layers.Dense(1, activation="sigmoid"),
])
model.compile(optimizer=keras.optimizers.Adam(learning_rate=1.0),
              loss="binary_crossentropy", metrics=["accuracy"])
history = model.fit(X_train, y_train, validation_split=0.2,
                    epochs=10, batch_size=16, verbose=0)
print("high-lr final val_loss:", round(history.history['val_loss'][-1], 4))
print("high-lr final val_accuracy:", round(history.history['val_accuracy'][-1], 4))
```

Output:

```
high-lr final val_loss: 5.0268
high-lr final val_accuracy: 0.9451
```

The validation loss is about 5.03, roughly a hundred times worse than the 0.055 you saw in Lesson 3, even though accuracy still looks acceptable. That gap is the warning sign: a learning rate of 1.0 makes the optimizer overshoot wildly, so the model's probabilities are unstable and badly calibrated even when the final label often lands on the right side of 0.5. This is exactly why you watch the loss and not just accuracy. A healthy run shows both improving together.

---

## Next Up - Lesson 5

You opened up the training loop and saw what really happens inside `compile` and `fit`. A loss function scores how wrong the model is, gradient descent steps downhill against the slope to reduce that loss, the learning rate sets how big each step is, and the optimizer decides how to apply the gradients, with Adam adapting the step size for you. All of it runs batch by batch, epoch by epoch, with backpropagation computing the gradients automatically. Training is now a process you understand, not a spell you cast.

In Lesson 5, you turn to the design choices that shape how well a network can learn in the first place: activation functions like `relu` and `sigmoid`, how many layers and neurons to use, and how to reason about the architecture of a network instead of guessing.
