## 1. Before You Begin

Everything you have built so far used `Dense` layers on tabular data and flattened digit images. Those work, but they throw away something crucial about images: the fact that nearby pixels belong together. In this lesson you meet the convolutional neural network, or CNN, the architecture designed specifically to understand images by respecting their spatial structure. CNNs are the reason deep learning can recognize faces, read handwriting, and drive cars.

You will start by seeing exactly why dense networks are a poor fit for images, then learn the two building blocks of a CNN: the convolution and the pooling operation. You will watch a single filter detect an edge with plain arithmetic, then assemble a real CNN and train it to read handwritten digits, beating a dense network while respecting how images are built.

### What You'll Build

A convolutional neural network that classifies handwritten digits from the MNIST dataset, plus a dense network trained on the same data so you can compare them head to head. Along the way you will compute a convolution by hand to demystify what a filter does.

### What You'll Learn

- ✅ Why dense networks struggle with images
- ✅ What a convolution is and how a filter detects features like edges
- ✅ What pooling does and why it helps
- ✅ How the Conv, Pool, Flatten, Dense pattern forms a CNN
- ✅ How to build and train a CNN with Keras and why it beats a dense model on images

### What You'll Need

- The Keras workflow from Modules 2 and 3
- A Colab notebook with the GPU enabled (CNNs train much faster on a GPU)
- Comfort with `Sequential` models, `compile`, and `fit`

---

## 2. Why Dense Networks Struggle with Images

To feed an image into a `Dense` layer, you have to flatten it into a long list of numbers. A 28 by 28 digit becomes a flat vector of 784 values. This causes two real problems.

First, flattening destroys spatial structure. Once the image is a flat list, the network has no idea that two pixels were next to each other. The shape of a stroke, the corner of a 7, the loop of a 9, all of that geometry is scrambled. The network has to relearn from scratch that certain positions tend to relate, which is wasteful.

Second, dense layers explode in size on images. A single dense layer with 128 neurons on a 784 pixel input already needs about 100,000 weights. That is for tiny grayscale digits. A modest color photo of 224 by 224 pixels has over 150,000 input values, and a first dense layer would need tens of millions of weights. That does not scale.

A CNN solves both problems with one idea: instead of connecting every pixel to every neuron, it slides a small set of weights, called a filter, across the image. The same filter is reused at every position, which keeps the weight count tiny and, crucially, preserves the 2D layout of the image. The next section shows exactly how that sliding works.

---

## 3. The Convolution Operation

A convolution slides a small grid of weights, the filter or kernel, across an image. At each position it multiplies the filter by the patch of image underneath it and sums the result into a single number. Collect those numbers and you get a feature map that highlights wherever the filter's pattern appears. The best way to believe this is to compute one by hand.

Here is a 6 by 6 image with a clear vertical edge: the left half is 0 and the right half is 1. You will slide a vertical-edge filter over it.

```python
import numpy as np

image = np.array([
    [0, 0, 0, 1, 1, 1],
    [0, 0, 0, 1, 1, 1],
    [0, 0, 0, 1, 1, 1],
    [0, 0, 0, 1, 1, 1],
    [0, 0, 0, 1, 1, 1],
    [0, 0, 0, 1, 1, 1],
], dtype=float)

kernel = np.array([
    [-1, 0, 1],
    [-1, 0, 1],
    [-1, 0, 1],
], dtype=float)

out_h = image.shape[0] - kernel.shape[0] + 1
out_w = image.shape[1] - kernel.shape[1] + 1
feature = np.zeros((out_h, out_w))
for i in range(out_h):
    for j in range(out_w):
        patch = image[i:i+3, j:j+3]
        feature[i, j] = np.sum(patch * kernel)

print(feature.astype(int))
```

Output:

```
[[0 3 3 0]
 [0 3 3 0]
 [0 3 3 0]
 [0 3 3 0]]
```

Read what happened. The filter has negative weights on the left and positive on the right, so it responds strongly where dark turns to light from left to right, which is exactly a vertical edge. Over the flat left region (all 0s) and the flat right region (all 1s), the filter sums to 0 because there is no change. Right at the boundary, it lights up with a value of 3. The feature map has found the edge and ignored everything else. A 3 by 3 filter on a 6 by 6 image produces a 4 by 4 map, because the filter cannot hang off the edges.

This is the whole idea. A CNN does not use hand-picked filters like this one. It starts with random filters and learns the useful ones during training. Early layers tend to learn simple filters like edges and colors, and deeper layers combine those into complex shapes like loops and corners. You provide the architecture; gradient descent discovers the filters.

---

## 4. Pooling and the CNN Architecture

Convolution has a partner operation called pooling. After a convolution produces feature maps, a pooling layer shrinks them by summarizing small regions. The most common kind, max pooling, slides a 2 by 2 window across the map and keeps only the largest value in each window, halving the width and height.

Pooling does two useful things. It reduces the amount of data the network has to process, which speeds up training, and it makes the network a little tolerant to where exactly a feature appears, since the max in a region survives even if the feature shifts by a pixel. A digit that is shifted slightly still activates the same pooled feature.

Put together, a CNN follows a recognizable pattern:

1. One or more **Conv** layers detect features, producing feature maps.
2. A **Pool** layer shrinks those maps.
3. This Conv then Pool block repeats, with each stage learning more complex features from the previous stage's output.
4. A **Flatten** layer turns the final small feature maps into a vector.
5. One or more **Dense** layers use those features to make the final classification.

The intuition is a funnel: the image starts large and shallow (many pixels, one channel) and ends small and deep (few spatial positions, many learned features), at which point a dense layer can classify it. Now you will build exactly this.

---

## 5. Build a CNN for MNIST

MNIST is the classic dataset of 70,000 handwritten digits, 28 by 28 pixels each, and it ships with Keras. It is the "hello world" of computer vision.

### Step 1: Load and prepare the images

```python
from tensorflow import keras

(x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()
print("x_train:", x_train.shape, "x_test:", x_test.shape)
print("pixel range:", int(x_train.min()), "to", int(x_train.max()))
```

Output:

```
Downloading data from https://storage.googleapis.com/tensorflow/tf-keras-datasets/mnist.npz
11490434/11490434 ━━━━━━━━━━━━━━━━━━━━ 0s 0us/step
x_train: (60000, 28, 28) x_test: (10000, 28, 28)
pixel range: 0 to 255
```

There are 60,000 training and 10,000 test images, and pixel values run from 0 to 255. Two preparation steps remain.

```python
import numpy as np

x_train = (x_train / 255.0).astype("float32")[..., np.newaxis]
x_test = (x_test / 255.0).astype("float32")[..., np.newaxis]
print("after reshape:", x_train.shape)
```

Output:

```
after reshape: (60000, 28, 28, 1)
```

Dividing by 255 scales pixels into the 0 to 1 range, the same scaling habit that helps every network train. Then `[..., np.newaxis]` adds a final channel dimension, turning each `(28, 28)` image into `(28, 28, 1)`. Conv2D layers expect a channel axis: 1 for grayscale, 3 for color (red, green, blue).

### Step 2: Build the CNN

```python
from tensorflow.keras import layers

keras.utils.set_random_seed(42)
cnn = keras.Sequential([
    layers.Input(shape=(28, 28, 1)),
    layers.Conv2D(32, (3, 3), activation="relu"),
    layers.MaxPooling2D((2, 2)),
    layers.Conv2D(64, (3, 3), activation="relu"),
    layers.MaxPooling2D((2, 2)),
    layers.Flatten(),
    layers.Dense(64, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
cnn.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
cnn.summary()
```

Output:

```
Model: "sequential"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┓
┃ Layer (type)                    ┃ Output Shape           ┃       Param # ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━┩
│ conv2d (Conv2D)                 │ (None, 26, 26, 32)     │           320 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ max_pooling2d (MaxPooling2D)    │ (None, 13, 13, 32)     │             0 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ conv2d_1 (Conv2D)               │ (None, 11, 11, 64)     │        18,496 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ max_pooling2d_1 (MaxPooling2D)  │ (None, 5, 5, 64)       │             0 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ flatten (Flatten)               │ (None, 1600)           │             0 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense (Dense)                   │ (None, 64)             │       102,464 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense_1 (Dense)                 │ (None, 10)             │           650 │
└─────────────────────────────────┴────────────────────────┴───────────────┘
 Total params: 121,930 (476.29 KB)
 Trainable params: 121,930 (476.29 KB)
 Non-trainable params: 0 (0.00 B)
```

Trace the shapes, because this is the funnel in action. The first `Conv2D` turns the 28 by 28 image into 26 by 26 with 32 feature maps (a 3 by 3 filter trims one pixel off each edge). Max pooling halves it to 13 by 13. The second conv and pool bring it down to 5 by 5 with 64 maps. `Flatten` turns that 5 by 5 by 64 block into a vector of 1,600, which two dense layers classify into 10 digits. Notice how cheap the conv layers are: the first has just 320 weights because the filter is tiny and reused everywhere. The image shrinks spatially while growing deeper in features, exactly as designed.

---

## 6. Train and Compare to a Dense Network

Now train the CNN and, to prove the architecture matters, train a plain dense network on the same data and compare.

### Step 1: Train the CNN

```python
history = cnn.fit(x_train, y_train, validation_split=0.1,
                  epochs=5, batch_size=128, verbose=0)
for e in range(5):
    print(f"epoch {e+1}: loss={history.history['loss'][e]:.4f} "
          f"acc={history.history['accuracy'][e]:.4f} "
          f"val_acc={history.history['val_accuracy'][e]:.4f}")

test_loss, test_acc = cnn.evaluate(x_test, y_test, verbose=0)
print("CNN test accuracy:", round(test_acc, 4))
```

Output:

```
epoch 1: loss=0.2492 acc=0.9281 val_acc=0.9817
epoch 2: loss=0.0673 acc=0.9793 val_acc=0.9853
epoch 3: loss=0.0480 acc=0.9849 val_acc=0.9877
epoch 4: loss=0.0363 acc=0.9887 val_acc=0.9885
epoch 5: loss=0.0291 acc=0.9908 val_acc=0.9893
```
```
CNN test accuracy: 0.9888
```

In just five epochs the CNN reaches about 98.9 percent on the test set. Your exact numbers will vary slightly by hardware and run, but they will be very close. On a GPU each epoch takes only a few seconds; on a CPU it is noticeably slower, which is why enabling the GPU runtime matters here.

### Step 2: Compare to a dense network

```python
keras.utils.set_random_seed(42)
dense = keras.Sequential([
    layers.Input(shape=(28, 28, 1)),
    layers.Flatten(),
    layers.Dense(128, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
dense.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
dense.fit(x_train, y_train, validation_split=0.1, epochs=5, batch_size=128, verbose=0)
_, dense_acc = dense.evaluate(x_test, y_test, verbose=0)

print("CNN  test accuracy:", round(test_acc, 4), "params:", cnn.count_params())
print("Dense test accuracy:", round(dense_acc, 4), "params:", dense.count_params())
```

Output:

```
CNN  test accuracy: 0.9888 params: 121930
Dense test accuracy: 0.9702 params: 101770
```

The CNN beats the dense network, 98.9 percent against 97.0, with a similar number of parameters. That gap is significant: the CNN's remaining errors are nearly a third fewer. And notice where the parameters go. The dense model spends almost all of its 101,770 weights on one giant first layer that stares at scrambled pixels, while the CNN spends most of its budget on a flexible dense head fed by cheap, powerful convolutional features. Same scale of model, smarter use of it, because the CNN respects how images are built.

### Step 3: Check a few predictions

```python
probs = cnn.predict(x_test[:5], verbose=0)
print("predicted:", np.argmax(probs, axis=1))
print("true:     ", y_test[:5])
```

Output:

```
predicted: [7 2 1 0 4]
true:      [7 2 1 0 4]
```

All five match. You have a working digit recognizer built the right way for images.

---

## 7. Fix the Errors in Your Code

These CNN-specific mistakes are extremely common the first time.

**Mistake 1: Forgetting the channel dimension.**

```python
# Wrong: Conv2D expects a channel axis, but these images are (n, 28, 28)
x_train = x_train / 255.0
cnn.fit(x_train, y_train, epochs=5)
```

```python
# Correct: add a channel dimension so each image is (28, 28, 1)
x_train = (x_train / 255.0)[..., np.newaxis]
cnn.fit(x_train, y_train, epochs=5)
```

Conv2D layers require a 4D input of shape `(batch, height, width, channels)`. Grayscale images need an explicit channel of 1. Without it, the model raises a shape error.

**Mistake 2: Forgetting to normalize the pixels.**

```python
# Wrong: feeding raw 0 to 255 pixel values
x_train = x_train[..., np.newaxis]
```

```python
# Correct: scale pixels to 0 to 1 first
x_train = (x_train / 255.0)[..., np.newaxis]
```

Large raw pixel values make training slow and unstable. Dividing by 255 puts every pixel in the 0 to 1 range, just like the scaling you applied to tabular features.

**Mistake 3: Missing the Flatten before the Dense layers.**

```python
# Wrong: Dense after Conv without flattening leaves the output 2D
model = keras.Sequential([
    layers.Input(shape=(28, 28, 1)),
    layers.Conv2D(32, (3, 3), activation="relu"),
    layers.MaxPooling2D((2, 2)),
    layers.Dense(10, activation="softmax"),  # output ends up (None, 13, 13, 10)
])
```

```python
# Correct: flatten the feature maps before the dense classifier
model = keras.Sequential([
    layers.Input(shape=(28, 28, 1)),
    layers.Conv2D(32, (3, 3), activation="relu"),
    layers.MaxPooling2D((2, 2)),
    layers.Flatten(),
    layers.Dense(10, activation="softmax"),
])
```

A `Dense` layer applied to feature maps acts only on the last axis, leaving an output with spatial dimensions still attached. You must `Flatten` the maps into a vector before the dense classifier so the output has the right shape.

---

## 8. Exercises

**Exercise 1:** Build a 6 by 6 image with a horizontal edge (top half 0, bottom half 1) and convolve it with the horizontal-edge filter `[[-1,-1,-1],[0,0,0],[1,1,1]]`. Print the feature map and confirm it lights up at the horizontal boundary.

**Exercise 2:** Apply the vertical-edge filter from the lesson to a completely flat 6 by 6 image of all 1s. What feature map do you get, and what does it tell you about what filters respond to?

**Exercise 3:** Add a third `Conv2D(64, (3, 3))` plus `MaxPooling2D((2, 2))` block to the MNIST CNN (before the Flatten) and print `model.summary()`. Look at the spatial size after the third pool and explain why you cannot keep stacking pooling layers forever.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
import numpy as np

def convolve(image, kernel):
    oh = image.shape[0] - kernel.shape[0] + 1
    ow = image.shape[1] - kernel.shape[1] + 1
    out = np.zeros((oh, ow))
    for i in range(oh):
        for j in range(ow):
            out[i, j] = np.sum(image[i:i+3, j:j+3] * kernel)
    return out

image = np.array([
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1],
], dtype=float)
kernel = np.array([[-1, -1, -1], [0, 0, 0], [1, 1, 1]], dtype=float)
print(convolve(image, kernel).astype(int))
```

Output:

```
[[0 0 0 0]
 [3 3 3 3]
 [3 3 3 3]
 [0 0 0 0]]
```

The horizontal-edge filter is just the vertical one rotated, with negative weights on top and positive on the bottom. It now lights up along the horizontal boundary where 0 turns into 1, and stays at 0 in the flat regions. Rotating the filter rotates the kind of edge it detects, which is exactly why a network needs many different filters.

**Solution for Exercise 2:**

```python
flat = np.ones((6, 6), dtype=float)
kernel = np.array([[-1, 0, 1], [-1, 0, 1], [-1, 0, 1]], dtype=float)
print(convolve(flat, kernel).astype(int))
```

Output:

```
[[0 0 0 0]
 [0 0 0 0]
 [0 0 0 0]
 [0 0 0 0]]
```

The feature map is entirely 0. With no change anywhere in the image, the edge filter has nothing to respond to. This is the key insight about convolution: filters detect changes and patterns, not absolute brightness. A flat region, however bright, produces no response from an edge detector.

**Solution for Exercise 3:**

```python
from tensorflow import keras
from tensorflow.keras import layers

model = keras.Sequential([
    layers.Input(shape=(28, 28, 1)),
    layers.Conv2D(32, (3, 3), activation="relu"),
    layers.MaxPooling2D((2, 2)),
    layers.Conv2D(64, (3, 3), activation="relu"),
    layers.MaxPooling2D((2, 2)),
    layers.Conv2D(64, (3, 3), activation="relu"),
    layers.MaxPooling2D((2, 2)),
    layers.Flatten(),
    layers.Dense(64, activation="relu"),
    layers.Dense(10, activation="softmax"),
])
model.summary()
```

Looking at the output shapes, the spatial size marches down 28, 26, 13, 11, 5, 3, 1: after the third pooling layer the feature maps are just 1 by 1. There is nothing left to pool. Each Conv then Pool block roughly halves the spatial size, so on a 28 by 28 image you run out of pixels after about three blocks. This is why deeper CNNs for larger images use bigger inputs and careful design rather than endless pooling, a constraint you will feel when you work with real photos in the next lesson.

---

## Next Up - Lesson 8

You learned why images need a different architecture and built one. A convolution slides learned filters across an image to produce feature maps that highlight patterns like edges, pooling shrinks those maps and adds a little position tolerance, and stacking Conv then Pool blocks before a dense head forms a CNN. Your MNIST CNN reached almost 99 percent and clearly beat a dense network of similar size, because it respects the spatial structure of images.

In Lesson 8, you will build a more serious image classifier on a harder, more realistic dataset of clothing photos. You will add techniques like dropout and data augmentation to a CNN, and follow the full workflow of training a vision model that has to handle real visual variety.
