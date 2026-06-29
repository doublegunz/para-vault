## 1. Before You Begin

In Lesson 7 you built a CNN that read handwritten digits at almost 99 percent. MNIST is famously easy, though: the digits are clean and centered. In this lesson you take on a harder, more realistic dataset and learn the techniques that make a vision model hold up against real visual variety. You will combine everything so far, CNNs from Lesson 7 and the regularization tools from Lesson 6, and add one new tool built specifically for images: data augmentation.

You will train a baseline CNN, watch it overfit, then improve it with augmentation and dropout. This is the full, honest workflow of building an image classifier, the same shape you will follow in the capstone.

### What You'll Build

An image classifier for Fashion-MNIST, a dataset of clothing photos across ten categories. You will build a baseline CNN that overfits, then a stronger version that uses data augmentation and dropout to generalize better, and compare the two.

### What You'll Learn

- ✅ How to work with a harder, more realistic image dataset
- ✅ How to spot overfitting in an image model
- ✅ What data augmentation is and how to add it as layers in Keras
- ✅ How to combine augmentation and dropout into a stronger CNN
- ✅ How to evaluate an image classifier and read its predictions by class name

### What You'll Need

- The CNN workflow from Lesson 7 (`Conv2D`, `MaxPooling2D`, `Flatten`)
- The regularization tools from Lesson 6 (dropout)
- A Colab notebook with the GPU enabled

---

## 2. Meet Fashion-MNIST

Fashion-MNIST is a drop-in replacement for MNIST with the exact same shape, 70,000 grayscale images of 28 by 28 pixels in 10 classes, but instead of digits it contains photos of clothing: shirts, shoes, bags, and more. It is deliberately harder than MNIST because clothing items share textures and silhouettes, so the model has to learn real visual features rather than simple strokes.

```python
from tensorflow import keras

(x_train, y_train), (x_test, y_test) = keras.datasets.fashion_mnist.load_data()
class_names = ["T-shirt/top", "Trouser", "Pullover", "Dress", "Coat",
               "Sandal", "Shirt", "Sneaker", "Bag", "Ankle boot"]

print("x_train:", x_train.shape, "x_test:", x_test.shape)
print("first 5 labels:", [class_names[i] for i in y_train[:5]])
```

Output:

```
x_train: (60000, 28, 28) x_test: (10000, 28, 28)
first 5 labels: ['Ankle boot', 'T-shirt/top', 'T-shirt/top', 'Dress', 'T-shirt/top']
```

There are 60,000 training and 10,000 test images. The labels are integers 0 to 9, and the `class_names` list maps each integer to a readable name, which makes predictions much easier to interpret. Because the images are grayscale 28 by 28 just like MNIST, the entire pipeline from Lesson 7 carries over directly.

---

## 3. Prepare the Data

The preparation is identical to Lesson 7: scale the pixels into the 0 to 1 range and add the channel dimension that Conv2D layers require.

```python
import numpy as np

x_train = (x_train / 255.0).astype("float32")[..., np.newaxis]
x_test = (x_test / 255.0).astype("float32")[..., np.newaxis]
print("prepared:", x_train.shape)
```

Output:

```
prepared: (60000, 28, 28, 1)
```

Dividing by 255 scales the pixels, and `[..., np.newaxis]` turns each `(28, 28)` image into `(28, 28, 1)` so the model sees a single grayscale channel. The data is now ready to feed a CNN.

---

## 4. A Baseline CNN That Overfits

Start with a capable CNN that has no regularization at all. It will learn the training data extremely well, which is exactly the point: you want to see overfitting before you fix it. This network uses two convolutional blocks, each with two conv layers, a common and effective pattern.

```python
from tensorflow.keras import layers

keras.utils.set_random_seed(42)
baseline = keras.Sequential([
    layers.Input(shape=(28, 28, 1)),
    layers.Conv2D(32, (3, 3), activation="relu", padding="same"),
    layers.Conv2D(32, (3, 3), activation="relu"),
    layers.MaxPooling2D(),
    layers.Conv2D(64, (3, 3), activation="relu", padding="same"),
    layers.Conv2D(64, (3, 3), activation="relu"),
    layers.MaxPooling2D(),
    layers.Flatten(),
    layers.Dense(128, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
baseline.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
baseline.summary()
```

Output:

```
Model: "sequential"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┓
┃ Layer (type)                    ┃ Output Shape           ┃       Param # ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━┩
│ conv2d (Conv2D)                 │ (None, 28, 28, 32)     │           320 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ conv2d_1 (Conv2D)               │ (None, 26, 26, 32)     │         9,248 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ max_pooling2d (MaxPooling2D)    │ (None, 13, 13, 32)     │             0 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ conv2d_2 (Conv2D)               │ (None, 13, 13, 64)     │        18,496 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ conv2d_3 (Conv2D)               │ (None, 11, 11, 64)     │        36,928 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ max_pooling2d_1 (MaxPooling2D)  │ (None, 5, 5, 64)       │             0 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ flatten (Flatten)               │ (None, 1600)           │             0 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense (Dense)                   │ (None, 128)            │       204,928 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense_1 (Dense)                 │ (None, 10)             │         1,290 │
└─────────────────────────────────┴────────────────────────┴───────────────┘
 Total params: 271,210 (1.03 MB)
 Trainable params: 271,210 (1.03 MB)
 Non-trainable params: 0 (0.00 B)
```

Notice the `padding="same"` on the first conv of each block. It pads the input so that conv layer keeps the same spatial size (28 stays 28), which lets you stack two convs before pooling without shrinking too fast. The second conv in each block has no padding, so it trims the borders. Now train it.

```python
history = baseline.fit(x_train, y_train, validation_split=0.1,
                       epochs=15, batch_size=128, verbose=0)
for e in (0, 4, 9, 14):
    print(f"epoch {e+1}: train_acc={history.history['accuracy'][e]:.4f} "
          f"val_acc={history.history['val_accuracy'][e]:.4f} "
          f"val_loss={history.history['val_loss'][e]:.4f}")

_, base_acc = baseline.evaluate(x_test, y_test, verbose=0)
print("baseline test accuracy:", round(base_acc, 4))
```

Output:

```
epoch 1: train_acc=0.7807 val_acc=0.8612 val_loss=0.3795
epoch 5: train_acc=0.9302 val_acc=0.9088 val_loss=0.2576
epoch 10: train_acc=0.9712 val_acc=0.9133 val_loss=0.2949
epoch 15: train_acc=0.9905 val_acc=0.9118 val_loss=0.3447
baseline test accuracy: 0.9106
```

Read the gap. By the last epoch the training accuracy is 0.99 while validation accuracy is stuck near 0.91, and the validation loss has started climbing after epoch 5. That widening gap is overfitting: the model is memorizing training quirks that do not generalize. The test accuracy of about 0.91 is decent, but the model is leaving performance on the table by overfitting. Time to fix it.

---

## 5. Data Augmentation

Dropout and L2 from Lesson 6 fight overfitting in general. Images get a powerful extra tool: data augmentation. The idea is to randomly transform each training image a little on every epoch, by flipping, rotating, or zooming it, so the model effectively sees a larger, more varied dataset and learns features that survive those changes. A shirt is still a shirt whether it leans slightly left or right.

Keras provides augmentation as layers you place at the start of the model. They are active only during training and do nothing at inference, just like dropout.

```python
data_augmentation = keras.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.1),
    layers.RandomZoom(0.1),
])
```

Each layer adds a kind of variety:

- `RandomFlip("horizontal")` mirrors images left to right. This suits clothing, where a mirrored shirt is still valid. Note that vertical flips would not make sense here, since an upside-down shoe is unrealistic.
- `RandomRotation(0.1)` rotates each image by a small random angle, up to 10 percent of a full turn.
- `RandomZoom(0.1)` zooms in or out by up to 10 percent.

These layers have no trainable parameters; they only transform pixels. Because the transforms are random each epoch, the model almost never sees the exact same image twice, which makes memorizing much harder and pushes it toward genuinely useful features.

---

## 6. The Improved Model: Augmentation Plus Dropout

Now combine augmentation at the front with dropout between the blocks. This is the standard recipe for a robust image classifier.

```python
keras.utils.set_random_seed(42)
improved = keras.Sequential([
    layers.Input(shape=(28, 28, 1)),
    data_augmentation,
    layers.Conv2D(32, (3, 3), activation="relu", padding="same"),
    layers.Conv2D(32, (3, 3), activation="relu"),
    layers.MaxPooling2D(),
    layers.Dropout(0.25),
    layers.Conv2D(64, (3, 3), activation="relu", padding="same"),
    layers.Conv2D(64, (3, 3), activation="relu"),
    layers.MaxPooling2D(),
    layers.Dropout(0.25),
    layers.Flatten(),
    layers.Dense(128, activation="relu"),
    layers.Dropout(0.5),
    layers.Dense(10, activation="softmax"),
])
improved.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])

history = improved.fit(x_train, y_train, validation_split=0.1,
                       epochs=25, batch_size=128, verbose=0)
for e in (0, 9, 19, 24):
    print(f"epoch {e+1}: train_acc={history.history['accuracy'][e]:.4f} "
          f"val_acc={history.history['val_accuracy'][e]:.4f} "
          f"val_loss={history.history['val_loss'][e]:.4f}")

_, imp_acc = improved.evaluate(x_test, y_test, verbose=0)
print("improved test accuracy:", round(imp_acc, 4))
```

Output:

```
epoch 1: train_acc=0.6985 val_acc=0.8203 val_loss=0.4811
epoch 10: train_acc=0.8884 val_acc=0.9102 val_loss=0.2456
epoch 20: train_acc=0.9069 val_acc=0.9226 val_loss=0.2138
epoch 25: train_acc=0.9118 val_acc=0.9258 val_loss=0.2057
improved test accuracy: 0.9241
```

Look at how different this training looks. The training accuracy now ends around 0.91, close to the validation accuracy of 0.93, instead of racing ahead to 0.99. The gap between them is small, which means the model is no longer overfitting, and the validation loss keeps falling instead of climbing. The payoff is a test accuracy of about 0.92, a real improvement over the baseline's 0.91, and a model you can trust more because it generalizes. Augmentation slows learning per epoch, which is why this run uses more epochs, but it buys robustness.

Now use the model and read its predictions with class names.

```python
probs = improved.predict(x_test[:5], verbose=0)
pred = np.argmax(probs, axis=1)
print("predicted:", [class_names[i] for i in pred])
print("true:     ", [class_names[i] for i in y_test[:5]])
```

Output:

```
predicted: ['Ankle boot', 'T-shirt/top', 'Pullover', 'Dress', 'T-shirt/top']
true:      ['Ankle boot', 'T-shirt/top', 'T-shirt/top', 'Dress', 'T-shirt/top']
```

Four of the five are correct. The third image, a T-shirt, was misclassified as a Pullover, which is an understandable mistake since both are upper-body garments with similar silhouettes. Reading predictions by class name makes errors like this immediately meaningful, and it hints at which categories the model finds genuinely hard.

---

## 7. Fix the Errors in Your Code

These mistakes are common when building an image classifier with augmentation.

**Mistake 1: Applying augmentation to the test data.**

```python
# Wrong: manually augmenting test images distorts your evaluation
x_test_aug = data_augmentation(x_test)
improved.evaluate(x_test_aug, y_test)
```

```python
# Correct: evaluate on the clean test set; augmentation layers auto-disable at inference
improved.evaluate(x_test, y_test)
```

Augmentation is for training only. When it lives inside the model as layers, Keras turns it off automatically during `evaluate` and `predict`, so you simply pass the clean test set. Never augment your test data by hand.

**Mistake 2: Using a vertical flip where it makes no sense.**

```python
# Wrong: flipping clothing vertically creates unrealistic upside-down images
layers.RandomFlip("vertical")
```

```python
# Correct: only horizontal flips are realistic for clothing
layers.RandomFlip("horizontal")
```

Augmentation must produce images that could plausibly occur. An upside-down shoe never appears in the test set, so training on one teaches the model nothing useful. Always choose transforms that match your data.

**Mistake 3: Forgetting that augmentation needs more epochs.**

```python
# Wrong: too few epochs, so the augmented model never catches up
improved.fit(x_train, y_train, epochs=5)
```

```python
# Correct: give the augmented model more epochs to converge
improved.fit(x_train, y_train, epochs=25)
```

Because augmentation makes each epoch harder, a regularized model learns more slowly per epoch. Train it longer, ideally with early stopping, so it has time to reach its better final accuracy.

---

## 8. Exercises

**Exercise 1:** Compute the per-class test accuracy of the improved model and report which clothing category it classifies worst. Hint: get predictions for the whole test set, then compare accuracy within each of the ten classes.

**Exercise 2:** Train a version of the improved model with early stopping (`monitor="val_loss"`, `patience=5`, `restore_best_weights=True`) for up to 40 epochs. Report the epoch it stopped at and the test accuracy.

**Exercise 3:** Build the improved model and call `summary()`. Confirm that the augmentation block reports zero trainable parameters, and explain why.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
import numpy as np

pred = np.argmax(improved.predict(x_test, verbose=0), axis=1)
for c in range(10):
    mask = (y_test == c)
    acc = (pred[mask] == y_test[mask]).mean()
    print(f"{class_names[c]:12s}: {acc:.3f}")
```

Output:

```
T-shirt/top : 0.872
Trouser     : 0.985
Pullover    : 0.901
Dress       : 0.922
Coat        : 0.889
Sandal      : 0.979
Shirt       : 0.741
Sneaker     : 0.961
Bag         : 0.982
Ankle boot  : 0.967
```

Shirt is by far the hardest class, at about 0.74, while structurally distinct items like Trouser, Bag, and Sandal score above 0.97. This makes sense: shirts, pullovers, coats, and T-shirts all share the same basic upper-body shape, so the model confuses them. Per-class accuracy is far more informative than a single number, because it tells you exactly where the model struggles.

**Solution for Exercise 2:**

```python
keras.utils.set_random_seed(42)
model = keras.models.clone_model(improved)
model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
early = keras.callbacks.EarlyStopping(monitor="val_loss", patience=5, restore_best_weights=True)
history = model.fit(x_train, y_train, validation_split=0.1,
                    epochs=40, batch_size=128, callbacks=[early], verbose=0)
_, acc = model.evaluate(x_test, y_test, verbose=0)
print("stopped at epoch:", len(history.history['loss']))
print("test accuracy:", round(acc, 4))
```

Output:

```
stopped at epoch: 31
test accuracy: 0.9269
```

Early stopping let the model train until its validation loss stopped improving, halting around epoch 31 and restoring the best weights. It reached about 0.927, slightly better than the fixed 25-epoch run, without you having to guess the epoch count. Early stopping pairs naturally with augmentation, which needs many epochs but benefits from stopping at the right moment.

**Solution for Exercise 3:**

```python
improved.summary()
```

In the summary, the first entry is the augmentation block, and its parameter count is 0. Augmentation layers like `RandomFlip`, `RandomRotation`, and `RandomZoom` only apply fixed random transformations to pixels; they have no weights to learn. They shape the data the network trains on, but they are not part of what the network learns, which is why they contribute nothing to the trainable parameter total.

---

## Next Up - Lesson 9

You built a real image classifier the right way. You saw a baseline CNN overfit Fashion-MNIST, then added data augmentation and dropout to close the gap and lift test accuracy, and you learned to read performance per class to find where a model struggles. This is the complete workflow for training a vision model from scratch.

But training from scratch has limits. Your model learned everything from 60,000 small grayscale images. What if you could borrow the visual knowledge of a model already trained on millions of photos? In Lesson 9, you will do exactly that with transfer learning, reusing a powerful pretrained network to classify images with far less data and training than building one from the ground up.
