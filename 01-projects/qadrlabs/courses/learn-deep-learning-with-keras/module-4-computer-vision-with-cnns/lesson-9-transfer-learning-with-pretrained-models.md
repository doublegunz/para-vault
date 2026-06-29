## 1. Before You Begin

Every model you have built learned from scratch, starting with random weights and figuring everything out from your data. That works when you have lots of data and time. But the most practical skill in modern computer vision is the opposite: reusing a model that someone else already trained on millions of images, and adapting it to your problem with very little data. This is transfer learning, and it is how most real image projects are actually built.

In this lesson you will take MobileNetV2, a network pretrained on the huge ImageNet dataset, and teach it to classify flowers using only a few thousand photos. You will reuse its powerful learned features, train a small new head on top, and then fine-tune it for an extra boost. The result will beat anything you could train from scratch on so little data.

### What You'll Build

A flower classifier built on a pretrained MobileNetV2. You will load a color photo dataset, attach a pretrained feature extractor, train a new classification head, and then fine-tune the top of the base network for higher accuracy.

### What You'll Learn

- ✅ What transfer learning is and why it works so well
- ✅ How to load a real color image dataset from folders
- ✅ How to load a pretrained model and freeze it as a feature extractor
- ✅ How to add and train a new head with the Keras functional API
- ✅ How to fine-tune the top layers for extra accuracy

### What You'll Need

- The CNN and image workflow from Lessons 7 and 8
- A Colab notebook with the GPU enabled (strongly recommended here)
- An understanding of overfitting and dropout from Lesson 6

---

## 2. What Is Transfer Learning?

A network trained on ImageNet has seen over a million photos across a thousand categories. To do that, its early and middle layers learned to detect an enormous vocabulary of visual features: edges, textures, patterns, shapes, and parts of objects. Those features are general. The same edge and texture detectors that help recognize a cat also help recognize a flower.

Transfer learning reuses that learned vocabulary. Instead of training a CNN from scratch, you take a pretrained network, keep its feature-detecting layers, and only train a small new piece on top for your specific classes. There are two stages:

1. **Feature extraction.** Freeze the pretrained base so its weights do not change, and train only a new head on top. The base acts as a fixed, expert feature extractor.
2. **Fine-tuning.** Optionally unfreeze the top of the base and train it gently at a low learning rate, so its high-level features adapt a little to your data.

The payoff is huge: you get strong accuracy with far less data and training time, because you are standing on the shoulders of a model that already learned to see. This is the default approach for most real-world image tasks.

---

## 3. Load a Real Color Dataset

You will use the flowers dataset, about 3,670 color photos of five flower types, organized into one folder per class. Keras can download it and build a dataset that reads images straight from those folders.

```python
from tensorflow import keras

data_url = "https://storage.googleapis.com/download.tensorflow.org/example_images/flower_photos.tgz"
data_dir = keras.utils.get_file("flower_photos", origin=data_url, untar=True)

train_ds = keras.utils.image_dataset_from_directory(
    data_dir, validation_split=0.2, subset="training", seed=123,
    image_size=(160, 160), batch_size=32)
val_ds = keras.utils.image_dataset_from_directory(
    data_dir, validation_split=0.2, subset="validation", seed=123,
    image_size=(160, 160), batch_size=32)

class_names = train_ds.class_names
print(class_names)
```

Output:

```
Found 3670 files belonging to 5 classes.
Using 2936 files for training.
Found 3670 files belonging to 5 classes.
Using 734 files for validation.
['daisy', 'dandelion', 'roses', 'sunflowers', 'tulips']
```

`keras.utils.get_file` downloads and unpacks the archive, and `image_dataset_from_directory` turns the folders into a dataset, using the folder names as labels. The `validation_split` and `subset` arguments carve out 80 percent for training and 20 percent for validation. Every image is resized to 160 by 160 with 3 color channels, the input size MobileNetV2 expects here.

---

## 4. Load a Pretrained Base

Now bring in MobileNetV2, pretrained on ImageNet. You ask for it without its original classification head, because you will attach your own, and you freeze it.

```python
base_model = keras.applications.MobileNetV2(
    input_shape=(160, 160, 3),
    include_top=False,
    weights="imagenet")

base_model.trainable = False
print("base output shape:", base_model.output_shape)
print("base layers:", len(base_model.layers))
```

Output:

```
Downloading data from https://storage.googleapis.com/tensorflow/keras-applications/mobilenet_v2/mobilenet_v2_weights_tf_dim_ordering_tf_kernels_1.0_160_no_top.h5
9406464/9406464 ━━━━━━━━━━━━━━━━━━━━ 0s 0us/step
base output shape: (None, 5, 5, 1280)
base layers: 154
```

Three arguments matter. `include_top=False` drops the original 1,000-class ImageNet classifier, leaving just the feature-extracting body. `weights="imagenet"` downloads the pretrained weights. Setting `base_model.trainable = False` freezes all 154 layers so they keep their learned features during the next step. The base turns a 160 by 160 image into a 5 by 5 grid of 1,280 rich features, which your head will classify.

---

## 5. Add a Head and Train

You will assemble the full model with the Keras functional API, which connects layers explicitly and is the standard way to build models that are not a simple stack. It lets you insert the required MobileNetV2 preprocessing and run the frozen base in inference mode.

```python
from tensorflow.keras import layers

inputs = keras.Input(shape=(160, 160, 3))
x = keras.applications.mobilenet_v2.preprocess_input(inputs)
x = base_model(x, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.Dropout(0.2)(x)
outputs = layers.Dense(5, activation="softmax")(x)
model = keras.Model(inputs, outputs)

model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])
model.summary()
```

Output (final lines):

```
 Total params: 2,264,389 (8.64 MB)
 Trainable params: 6,405 (25.02 KB)
 Non-trainable params: 2,257,984 (8.61 MB)
```

Walk through the pieces. `preprocess_input` scales pixels into the range MobileNetV2 was trained on. `base_model(x, training=False)` runs the frozen base as a feature extractor. `GlobalAveragePooling2D` collapses the 5 by 5 by 1,280 features into a single 1,280 vector by averaging each feature map, a clean way to flatten for transfer learning. A dropout and a `Dense(5, softmax)` finish the head. The summary tells the real story: of 2.26 million parameters, only 6,405 are trainable, the tiny head. The 2.26 million frozen parameters are the pretrained knowledge you are borrowing. Now train just that head.

```python
history = model.fit(train_ds, validation_data=val_ds, epochs=10, verbose=0)
for e in (0, 4, 9):
    print(f"epoch {e+1}: train_acc={history.history['accuracy'][e]:.4f} "
          f"val_acc={history.history['val_accuracy'][e]:.4f}")
```

Output:

```
epoch 1: train_acc=0.6907 val_acc=0.8597
epoch 5: train_acc=0.8995 val_acc=0.8965
epoch 10: train_acc=0.9230 val_acc=0.9046
```

In ten quick epochs, training only 6,405 weights, the model reaches about 0.90 validation accuracy on five flower types. Training a CNN from scratch on just 2,936 images would struggle to get close. That leap is the power of transfer learning: the frozen base already knew how to see, so the head only had to learn which features mean "rose" versus "tulip".

---

## 6. Fine-Tuning for Extra Accuracy

The head is trained, and the base is still frozen with its general ImageNet features. You can often squeeze out more accuracy by fine-tuning: unfreezing the top layers of the base and training them gently so their high-level features adapt to flowers. The key is a very low learning rate, so you nudge the pretrained weights rather than wreck them.

```python
base_model.trainable = True
# Freeze all but the last 30 layers
for layer in base_model.layers[:-30]:
    layer.trainable = False

model.compile(optimizer=keras.optimizers.Adam(learning_rate=1e-5),
              loss="sparse_categorical_crossentropy", metrics=["accuracy"])

history_ft = model.fit(train_ds, validation_data=val_ds, epochs=10, verbose=0)
for e in (0, 4, 9):
    print(f"epoch {e+1}: train_acc={history_ft.history['accuracy'][e]:.4f} "
          f"val_acc={history_ft.history['val_accuracy'][e]:.4f}")

_, val_acc = model.evaluate(val_ds, verbose=0)
print("final val accuracy:", round(val_acc, 4))
```

Output:

```
epoch 1: train_acc=0.9298 val_acc=0.9114
epoch 5: train_acc=0.9612 val_acc=0.9387
epoch 10: train_acc=0.9734 val_acc=0.9442
final val accuracy: 0.9442
```

Two things make this work. First, you unfroze only the last 30 layers, the ones holding the most specialized features, while keeping the general early layers frozen. Second, you recompiled with a learning rate of `1e-5`, a hundred times smaller than the default, so the update is gentle. Fine-tuning lifts validation accuracy from about 0.90 to 0.94. Always train the head first with the base frozen, then fine-tune; trying to fine-tune from random head weights would send huge gradients through the base and destroy its pretrained features.

---

## 7. Fix the Errors in Your Code

These transfer learning mistakes are easy to make and quietly ruin results.

**Mistake 1: Forgetting the model's preprocessing.**

```python
# Wrong: feeding raw 0 to 255 pixels straight into MobileNetV2
x = base_model(inputs, training=False)
```

```python
# Correct: apply the model's own preprocessing first
x = keras.applications.mobilenet_v2.preprocess_input(inputs)
x = base_model(x, training=False)
```

Each pretrained model expects its inputs scaled exactly the way it was trained. Skipping `preprocess_input` feeds out-of-range values and accuracy collapses. Always use the preprocessing that ships with the model.

**Mistake 2: Fine-tuning with a normal learning rate.**

```python
# Wrong: a large learning rate wrecks the pretrained weights
base_model.trainable = True
model.compile(optimizer="adam", loss="sparse_categorical_crossentropy")
```

```python
# Correct: fine-tune gently with a very small learning rate
base_model.trainable = True
model.compile(optimizer=keras.optimizers.Adam(learning_rate=1e-5),
              loss="sparse_categorical_crossentropy")
```

The pretrained weights are already good. A normal learning rate takes huge steps that destroy them. Fine-tuning always uses a small learning rate to make small adjustments.

**Mistake 3: Forgetting to recompile after changing trainable.**

```python
# Wrong: flipping trainable without recompiling has no effect on training
base_model.trainable = True
model.fit(train_ds, epochs=10)
```

```python
# Correct: recompile so the change takes effect
base_model.trainable = True
model.compile(optimizer=keras.optimizers.Adam(learning_rate=1e-5),
              loss="sparse_categorical_crossentropy", metrics=["accuracy"])
model.fit(train_ds, epochs=10)
```

Changing a layer's `trainable` flag only takes effect after you call `compile` again. Forget this and your "fine-tuning" run silently trains nothing new.

---

## 8. Exercises

**Exercise 1:** Print the predicted and true class names for one batch of validation images using the fine-tuned model, and count how many of the 32 it gets right.

**Exercise 2:** Build the same transfer model but freeze the base for the entire run (no fine-tuning) and train for 20 epochs. Compare its final validation accuracy to the fine-tuned model and explain the difference.

**Exercise 3:** Without changing anything else, swap the base for `keras.applications.MobileNetV3Small` and print the trainable and non-trainable parameter counts of the new frozen model. How does its size compare to MobileNetV2?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
import numpy as np

images, labels = next(iter(val_ds))
probs = model.predict(images, verbose=0)
pred = np.argmax(probs, axis=1)
correct = int((pred == labels.numpy()).sum())
print("predicted:", [class_names[i] for i in pred[:8]])
print("true:     ", [class_names[i] for i in labels.numpy()[:8]])
print(f"correct in this batch: {correct}/{len(labels)}")
```

Output:

```
predicted: ['tulips', 'daisy', 'roses', 'sunflowers', 'dandelion', 'roses', 'tulips', 'daisy']
true:      ['tulips', 'daisy', 'roses', 'sunflowers', 'dandelion', 'tulips', 'tulips', 'daisy']
correct in this batch: 30/32
```

The model gets 30 of 32 right in this batch, matching its roughly 94 percent validation accuracy. The errors tend to be between visually similar flowers, like roses and tulips. Reading predictions by name makes the model's behavior concrete and shows where it still confuses classes.

**Solution for Exercise 2:**

```python
inputs = keras.Input(shape=(160, 160, 3))
x = keras.applications.mobilenet_v2.preprocess_input(inputs)
x = base_model(x, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.Dropout(0.2)(x)
outputs = layers.Dense(5, activation="softmax")(x)
frozen_model = keras.Model(inputs, outputs)
frozen_model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])

frozen_model.fit(train_ds, validation_data=val_ds, epochs=20, verbose=0)
_, acc = frozen_model.evaluate(val_ds, verbose=0)
print("frozen-only val accuracy:", round(acc, 4))
```

Output:

```
frozen-only val accuracy: 0.9101
```

Even with 20 epochs, training only the head plateaus around 0.91, because the frozen base never adapts its features to flowers. Fine-tuning reached about 0.94 by letting the top layers specialize a little. Feature extraction alone is fast and strong, and fine-tuning adds the final few points when you need them.

**Solution for Exercise 3:**

```python
small_base = keras.applications.MobileNetV3Small(
    input_shape=(160, 160, 3), include_top=False, weights="imagenet")
small_base.trainable = False

inputs = keras.Input(shape=(160, 160, 3))
x = small_base(inputs, training=False)
x = layers.GlobalAveragePooling2D()(x)
outputs = layers.Dense(5, activation="softmax")(x)
small_model = keras.Model(inputs, outputs)
small_model.compile(optimizer="adam", loss="sparse_categorical_crossentropy", metrics=["accuracy"])

trainable = sum(keras.backend.count_params(w) for w in small_model.trainable_weights)
non_trainable = sum(keras.backend.count_params(w) for w in small_model.non_trainable_weights)
print("trainable:", trainable)
print("non-trainable:", non_trainable)
```

Output:

```
trainable: 2885
non-trainable: 939120
```

MobileNetV3Small has under a million parameters in its base, less than half of MobileNetV2's 2.26 million, yet it is also a capable ImageNet model. Smaller pretrained bases like this are ideal when you need a model that is fast to run or small to deploy, and swapping bases is as simple as changing one line. Keras offers many pretrained models you can transfer from this way.

---

## Next Up - Lesson 10

You learned the most practical technique in computer vision. Transfer learning reuses a model pretrained on millions of images: you freeze it as a feature extractor, train a small head on your own classes, then fine-tune the top layers at a low learning rate for extra accuracy. With only a few thousand flower photos you reached about 94 percent, far beyond what training from scratch could manage on so little data.

That completes your tour of computer vision. In Lesson 10, you switch from images to sequences. You will meet recurrent neural networks and LSTMs, architectures designed for ordered data like text and time series, where what came before changes the meaning of what comes next.
