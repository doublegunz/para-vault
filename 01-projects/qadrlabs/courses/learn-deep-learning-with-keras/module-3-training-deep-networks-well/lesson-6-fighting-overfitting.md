## 1. Before You Begin

In Lesson 5 you saw that bigger networks have more capacity to learn. This lesson is about the danger that comes with that capacity: overfitting. An overfit model memorizes its training data, scoring almost perfectly there, but fails to generalize to new data. It is the single most common problem in deep learning, and recognizing and fixing it is a core skill.

You will first make a model overfit on purpose so you can see the warning signs clearly. Then you will fix it with the three tools every practitioner reaches for: dropout, weight regularization, and early stopping. By the end you will know how to read a training curve for trouble and how to respond.

### What You'll Build

An experiment where a network deliberately overfits a small dataset, followed by three improved versions that each fight overfitting a different way. You will compare their behavior and learn when to use each technique.

### What You'll Learn

- ✅ What overfitting is and how to spot it in the training output
- ✅ How dropout randomly disables neurons to force a more robust network
- ✅ How L2 regularization penalizes large weights to keep a model simple
- ✅ How early stopping halts training at the right moment automatically
- ✅ How to choose among these techniques

### What You'll Need

- The digit data and modeling workflow from Lesson 5
- A Colab notebook with Keras ready
- Comfort reading `loss`, `accuracy`, `val_loss`, and `val_accuracy`

---

## 2. What Overfitting Looks Like

The cleanest way to understand overfitting is to cause it. You will train a large network on a deliberately small slice of the digits data, which makes memorizing easy and generalizing hard. Validate against the full test set so the generalization gap is obvious.

```python
import numpy as np
from sklearn.datasets import load_digits
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from tensorflow import keras
from tensorflow.keras import layers

digits = load_digits()
X_train_full, X_test, y_train_full, y_test = train_test_split(
    digits.data, digits.target, test_size=0.3, random_state=42, stratify=digits.target
)
scaler = StandardScaler()
X_train_full = scaler.fit_transform(X_train_full)
X_test = scaler.transform(X_test)

# Use only 120 training examples to make overfitting easy to see
X_train, y_train = X_train_full[:120], y_train_full[:120]

keras.utils.set_random_seed(42)
base = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(256, activation="relu"),
    layers.Dense(128, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
base.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
history = base.fit(X_train, y_train, validation_data=(X_test, y_test),
                   epochs=150, batch_size=16, verbose=0)
```

Now read selected epochs from the training history to see the story unfold:

```python
H = history.history
print("epoch  train_loss  train_acc  val_loss  val_acc")
for e in (1, 10, 31, 75, 150):
    i = e - 1
    print(f"{e:5d}  {H['loss'][i]:.4f}     {H['accuracy'][i]:.4f}    {H['val_loss'][i]:.4f}   {H['val_accuracy'][i]:.4f}")
```

Output:

```
epoch  train_loss  train_acc  val_loss  val_acc
    1  2.1782     0.2917    1.8477   0.4815
   10  0.0415     1.0000    0.4046   0.8815
   31  0.0037     1.0000    0.3651   0.8907
   75  0.0007     1.0000    0.3768   0.9037
  150  0.0002     1.0000    0.3974   0.9074
```

This table is the signature of overfitting, so learn to read it. By epoch 10 the training accuracy is already a perfect 1.0 and the training loss is near zero: the model has memorized all 120 examples. But look at the validation column. The validation loss reaches its lowest point of 0.3651 around epoch 31, and after that it creeps back up to 0.3974 even as the training loss keeps falling toward zero. That divergence, training loss still dropping while validation loss rises, is exactly what overfitting looks like. The model is getting better at the training set and worse at the real world. The fix is not to train longer but to train smarter, which the next three sections do.

---

## 3. Dropout

Dropout is the most popular regularization technique in deep learning, and the idea is delightfully simple: during training, randomly switch off a fraction of the neurons in a layer on every step. Because the network can never rely on any single neuron always being present, it is forced to spread what it learns across many neurons, which makes it more robust and less able to memorize.

See what a dropout layer actually does to its input. It zeros out a random fraction of values during training and scales up the survivors to keep the overall total similar. At inference time it does nothing, passing every value through.

```python
keras.utils.set_random_seed(0)
d = layers.Dropout(0.5)
x = np.ones((1, 8), dtype="float32")
print("inference (training=False):", d(x, training=False).numpy()[0])
print("training  (training=True) :", d(x, training=True).numpy()[0])
```

Output:

```
inference (training=False): [1. 1. 1. 1. 1. 1. 1. 1.]
training  (training=True) : [2. 0. 2. 0. 0. 0. 0. 2.]
```

At inference all eight values pass through unchanged. During training, about half are zeroed and the rest are doubled (because the rate is 0.5, survivors are scaled by `1 / (1 - 0.5)`). Keras handles this switch automatically: dropout is active during `fit` and silent during `predict` and `evaluate`. Now add dropout layers to the network.

```python
keras.utils.set_random_seed(42)
drop = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(256, activation="relu"),
    layers.Dropout(0.5),
    layers.Dense(128, activation="relu"),
    layers.Dropout(0.5),
    layers.Dense(10, activation="softmax"),
])
drop.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
hd = drop.fit(X_train, y_train, validation_data=(X_test, y_test),
              epochs=150, batch_size=16, verbose=0)
print("dropout val_acc:", round(hd.history['val_accuracy'][-1], 4))
print("dropout best val_loss:", round(min(hd.history['val_loss']), 4),
      "at epoch", int(np.argmin(hd.history['val_loss'])) + 1)
```

Output:

```
dropout val_acc: 0.9167
dropout best val_loss: 0.3699 at epoch 50
```

Validation accuracy edges up from the baseline's 0.9074 to 0.9167, and just as importantly the best validation loss now arrives at epoch 50 instead of 31. Dropout slowed the memorization down, giving the model more useful training before it starts to overfit. A rate of 0.5 is a strong, common starting point for hidden layers.

---

## 4. Weight Regularization with L2

A second way to fight overfitting is to discourage the network from using large weights. Overfit models often develop a few very large weights to fit individual training examples exactly. L2 regularization adds a penalty to the loss proportional to the size of the weights, so the optimizer is pushed to keep them small, which leads to a simpler, smoother model that generalizes better.

You add it per layer with the `kernel_regularizer` argument.

```python
from tensorflow.keras import regularizers

keras.utils.set_random_seed(42)
l2_model = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(256, activation="relu", kernel_regularizer=regularizers.l2(0.001)),
    layers.Dense(128, activation="relu", kernel_regularizer=regularizers.l2(0.001)),
    layers.Dense(10, activation="softmax"),
])
l2_model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
hl = l2_model.fit(X_train, y_train, validation_data=(X_test, y_test),
                  epochs=150, batch_size=16, verbose=0)
print("l2 val_acc:", round(hl.history['val_accuracy'][-1], 4))
print("l2 best val_loss:", round(min(hl.history['val_loss']), 4),
      "at epoch", int(np.argmin(hl.history['val_loss'])) + 1)
```

Output:

```
l2 val_acc: 0.9074
l2 best val_loss: 0.3646 at epoch 150
```

The accuracy is about the same as the baseline, but notice the validation loss: its best value of 0.3646 occurs at the very last epoch, 150. That means the validation loss never turned around and climbed the way the baseline's did after epoch 31. L2 kept the model from overfitting at all across the whole run. That stability is the real win, and it is why regularization is valuable even when the headline accuracy looks similar. The number `0.001` is the regularization strength: larger values penalize weights harder, and you will see in the exercises that too much can hurt.

---

## 5. Early Stopping

The baseline experiment revealed something useful: the best model existed around epoch 31, and every epoch after that just made things worse. Early stopping turns that observation into an automatic rule. It watches the validation loss and stops training when it stops improving, then restores the weights from the best epoch. You no longer have to guess the right number of epochs.

You implement it as a callback passed to `fit`.

```python
keras.utils.set_random_seed(42)
es_model = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(256, activation="relu"),
    layers.Dense(128, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
es_model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])

early = keras.callbacks.EarlyStopping(
    monitor="val_loss", patience=10, restore_best_weights=True
)
he = es_model.fit(X_train, y_train, validation_data=(X_test, y_test),
                  epochs=150, batch_size=16, callbacks=[early], verbose=0)

stopped_epoch = len(he.history['loss'])
test_loss, test_acc = es_model.evaluate(X_test, y_test, verbose=0)
print("stopped at epoch:", stopped_epoch)
print("restored test accuracy:", round(test_acc, 4))
```

Output:

```
stopped at epoch: 41
restored test accuracy: 0.8907
```

The three arguments do all the work. `monitor="val_loss"` tells it what to watch, `patience=10` means "wait 10 epochs with no improvement before giving up", and `restore_best_weights=True` rolls the model back to its best point. Training stopped at epoch 41, which is patience of 10 past the best epoch of 31, and the restored model scores 0.8907 on the test set, the value from that best epoch. Even though you asked for 150 epochs, early stopping saved you about 109 of them and handed back the best model automatically. This is the most convenient of the three tools and pairs well with the other two.

---

## 6. Choosing Your Regularization

You now have three tools, and the good news is they are not exclusive. A common, effective recipe is to use all three together: add dropout between layers, optionally add a little L2, and wrap training in early stopping so you can set a generous epoch count without worry.

A few guidelines for when to lean on each:

- **Early stopping** is almost always worth using. It costs nothing, prevents wasted training, and removes the guesswork around epoch count. Start here.
- **Dropout** is your first choice when a model clearly overfits. Rates of 0.2 to 0.5 are typical. Higher rates regularize more aggressively.
- **L2 regularization** helps keep weights small and the model smooth. It is especially handy when dropout alone is not enough, but too strong a penalty can stop the model from learning.
- The deeper cure is **more data**. Every technique here compensates for limited data, and nothing beats simply having more examples when that is possible.

The honest takeaway from this lesson is that on a small, clean dataset the accuracy gains from regularization are modest, but the control over overfitting is real and matters enormously on the larger, messier problems ahead, especially the image models in the next module.

---

## 7. Fix the Errors in Your Code

These mistakes around regularization are common and quietly damaging.

**Mistake 1: Expecting dropout to act during evaluation.**

```python
# Wrong: assuming dropout randomly drops neurons at predict time too
predictions = model.predict(X_test)  # then puzzling over "why are results stable?"
```

```python
# Correct: dropout is automatically OFF during predict and evaluate
predictions = model.predict(X_test)  # full network is used, as intended
```

Dropout is only active during training. Keras turns it off automatically for `predict` and `evaluate`, so your inference uses the full network. That is the desired behavior, not a bug.

**Mistake 2: Setting the L2 penalty far too high.**

```python
# Wrong: a huge penalty crushes the weights and the model cannot learn
layers.Dense(256, activation="relu", kernel_regularizer=regularizers.l2(1.0))
```

```python
# Correct: a small penalty regularizes without preventing learning
layers.Dense(256, activation="relu", kernel_regularizer=regularizers.l2(0.001))
```

Regularization strength is a dial. Values like 0.001 to 0.01 are typical. A value like 1.0 penalizes the weights so hard that the model underfits and accuracy collapses.

**Mistake 3: Using early stopping without restoring the best weights.**

```python
# Wrong: stops late, but keeps the worse final weights
early = keras.callbacks.EarlyStopping(monitor="val_loss", patience=10)
```

```python
# Correct: roll back to the best epoch when stopping
early = keras.callbacks.EarlyStopping(monitor="val_loss", patience=10,
                                      restore_best_weights=True)
```

Without `restore_best_weights=True`, the model keeps the weights from the final epoch, which are by definition worse than the best epoch that triggered the patience countdown. Always restore the best weights.

---

## 8. Exercises

**Exercise 1:** Rebuild the dropout network using a lighter rate of 0.3 instead of 0.5, train for 150 epochs, and print the final validation accuracy and the best validation loss. Did the lighter rate help here?

**Exercise 2:** Train the L2 model again but with a much stronger penalty of 0.01, and print the final validation accuracy and best validation loss. Compare it to the 0.001 version and explain what the stronger penalty did.

**Exercise 3:** Use early stopping with a tighter `patience=5` and `restore_best_weights=True`, and print the epoch it stopped at and the restored test accuracy. How does it compare to patience of 10?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
keras.utils.set_random_seed(42)
model = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(256, activation="relu"),
    layers.Dropout(0.3),
    layers.Dense(128, activation="relu"),
    layers.Dropout(0.3),
    layers.Dense(10, activation="softmax"),
])
model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
h = model.fit(X_train, y_train, validation_data=(X_test, y_test),
              epochs=150, batch_size=16, verbose=0)
print("val_acc:", round(h.history['val_accuracy'][-1], 4))
print("best val_loss:", round(min(h.history['val_loss']), 4))
```

Output:

```
val_acc: 0.9130
best val_loss: 0.3507
```

A dropout rate of 0.3 reaches a validation accuracy of 0.9130 and a best validation loss of 0.3507, the lowest validation loss of any version so far. On this small dataset a lighter dropout slightly outperforms the heavier 0.5, a reminder that the dropout rate is worth tuning rather than fixing at one value.

**Solution for Exercise 2:**

```python
from tensorflow.keras import regularizers

keras.utils.set_random_seed(42)
model = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(256, activation="relu", kernel_regularizer=regularizers.l2(0.01)),
    layers.Dense(128, activation="relu", kernel_regularizer=regularizers.l2(0.01)),
    layers.Dense(10, activation="softmax"),
])
model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
h = model.fit(X_train, y_train, validation_data=(X_test, y_test),
              epochs=150, batch_size=16, verbose=0)
print("val_acc:", round(h.history['val_accuracy'][-1], 4))
print("best val_loss:", round(min(h.history['val_loss']), 4))
```

Output:

```
val_acc: 0.9074
best val_loss: 0.4157
```

The stronger penalty of 0.01 gives a best validation loss of 0.4157, which is actually worse than the 0.3646 from the 0.001 version. The heavier penalty squeezed the weights too hard, nudging the model toward underfitting. This shows that more regularization is not automatically better: the strength is a setting you tune.

**Solution for Exercise 3:**

```python
keras.utils.set_random_seed(42)
model = keras.Sequential([
    layers.Input(shape=(64,)),
    layers.Dense(256, activation="relu"),
    layers.Dense(128, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
early = keras.callbacks.EarlyStopping(monitor="val_loss", patience=5, restore_best_weights=True)
h = model.fit(X_train, y_train, validation_data=(X_test, y_test),
              epochs=150, batch_size=16, callbacks=[early], verbose=0)
_, test_acc = model.evaluate(X_test, y_test, verbose=0)
print("stopped at epoch:", len(h.history['loss']))
print("restored test accuracy:", round(test_acc, 4))
```

Output:

```
stopped at epoch: 36
restored test accuracy: 0.8907
```

With patience of 5, training stops at epoch 36, five epochs sooner than the patience-of-10 run that stopped at 41. The restored test accuracy is identical at 0.8907, because both runs roll back to the same best epoch around 31. A smaller patience saves more time but risks stopping during a temporary plateau, so it is a trade-off between speed and giving the model room to recover.

---

## Next Up - Lesson 7

You learned to recognize overfitting from the telltale gap between a falling training loss and a rising validation loss, and you fought it three ways. Dropout randomly disables neurons to force robustness, L2 regularization penalizes large weights for a simpler model, and early stopping halts training at the best moment and restores those weights. Together they are the standard toolkit for making a model generalize, and you will rely on them constantly from here on.

This also completes the fundamentals. You can build, train, design, and regularize networks on tabular data. In Lesson 7, you step into the field where deep learning truly shines: computer vision. You will meet the convolutional neural network, a specialized architecture built to understand images, and learn why it beats the dense networks you have used so far at seeing.
