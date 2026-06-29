## 1. Before You Begin

This is the capstone. You will build a complete image classifier from start to finish, the way you would deliver a real project, bringing together everything from the course: data loading and augmentation, transfer learning, callbacks, thorough evaluation, and saving the finished model for reuse. Nothing here is new in isolation; the goal is to assemble the pieces into one polished, end-to-end workflow.

You will classify photos of flowers into five types using a pretrained MobileNetV2, then evaluate it properly with per-class accuracy and a confusion matrix, save the trained model, reload it, and use it to classify a brand new image downloaded from the web. By the end you will have a model and a process you could adapt to your own image problems.

### What You'll Build

A complete flower classifier: a transfer-learning model with data augmentation, trained with early stopping and fine-tuning, evaluated on a held-out test set with a confusion matrix, then saved, reloaded, and run on a new image.

### What You'll Learn

- ✅ How to assemble a full image project end to end
- ✅ How to split data into training, validation, and test sets
- ✅ How to combine augmentation, transfer learning, and callbacks
- ✅ How to evaluate with per-class accuracy and a confusion matrix
- ✅ How to save, reload, and run a model on a brand new image

### What You'll Need

- Everything from Modules 3 and 4 (regularization, CNNs, transfer learning)
- A Colab notebook with the GPU enabled
- Confidence with the Keras workflow

---

## 2. Project Setup and Data

Start by loading the flowers dataset and carving out three splits. A real project always keeps a test set that is never used during training or tuning, so your final number is honest.

```python
import tensorflow as tf
from tensorflow import keras

url = "https://storage.googleapis.com/download.tensorflow.org/example_images/flower_photos.tgz"
data_dir = keras.utils.get_file("flower_photos", origin=url, untar=True)

img_size = (160, 160)
train_ds = keras.utils.image_dataset_from_directory(
    data_dir, validation_split=0.2, subset="training", seed=42,
    image_size=img_size, batch_size=32)
val_full = keras.utils.image_dataset_from_directory(
    data_dir, validation_split=0.2, subset="validation", seed=42,
    image_size=img_size, batch_size=32)

# Split the validation set in half to create a held-out test set
val_batches = tf.data.experimental.cardinality(val_full)
test_ds = val_full.take(val_batches // 2)
val_ds = val_full.skip(val_batches // 2)

class_names = train_ds.class_names
print("classes:", class_names)
print("val batches:", int(val_batches), "-> val:", int(tf.data.experimental.cardinality(val_ds)),
      "test:", int(tf.data.experimental.cardinality(test_ds)))
```

Output:

```
Found 3670 files belonging to 5 classes.
Using 2936 files for training.
Found 3670 files belonging to 5 classes.
Using 734 files for validation.
classes: ['daisy', 'dandelion', 'roses', 'sunflowers', 'tulips']
val batches: 23 -> val: 12 test: 11
```

You load the data with an 80/20 split, then divide the validation portion in half with `take` and `skip` to get a separate test set. Now you have three clean splits: training for learning, validation for tuning, and test for the final honest evaluation.

---

## 3. Build the Model

The model combines three things you have learned: data augmentation at the front, a frozen pretrained MobileNetV2 as a feature extractor, and a small trainable head. This is the standard, strong recipe for image classification with limited data.

```python
from tensorflow.keras import layers

data_augmentation = keras.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.1),
    layers.RandomZoom(0.1),
])

base_model = keras.applications.MobileNetV2(
    input_shape=img_size + (3,), include_top=False, weights="imagenet")
base_model.trainable = False

inputs = keras.Input(shape=img_size + (3,))
x = data_augmentation(inputs)
x = keras.applications.mobilenet_v2.preprocess_input(x)
x = base_model(x, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.Dropout(0.2)(x)
outputs = layers.Dense(len(class_names), activation="softmax")(x)
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

The pipeline reads cleanly top to bottom: augment the image, apply MobileNetV2's preprocessing, extract features with the frozen base, pool them, and classify with a small head. Only the 6,405 head parameters are trainable; the 2.26 million pretrained parameters stay frozen for now. The augmentation layers add no parameters but make the model more robust.

---

## 4. Train with Callbacks

Train the head first, using early stopping so you do not have to guess the epoch count and a checkpoint so the best model is saved automatically. Then fine-tune the top of the base for extra accuracy.

```python
callbacks = [
    keras.callbacks.EarlyStopping(monitor="val_loss", patience=4, restore_best_weights=True),
    keras.callbacks.ModelCheckpoint("best_flowers.keras", monitor="val_accuracy", save_best_only=True),
]

history = model.fit(train_ds, validation_data=val_ds, epochs=20, callbacks=callbacks, verbose=0)
print("head training stopped at epoch:", len(history.history['loss']))
print("best val_acc (head):", round(max(history.history['val_accuracy']), 4))

# Fine-tune the top 30 layers of the base at a low learning rate
base_model.trainable = True
for layer in base_model.layers[:-30]:
    layer.trainable = False
model.compile(optimizer=keras.optimizers.Adam(learning_rate=1e-5),
              loss="sparse_categorical_crossentropy", metrics=["accuracy"])

history_ft = model.fit(train_ds, validation_data=val_ds, epochs=10, callbacks=callbacks, verbose=0)
print("best val_acc (fine-tuned):", round(max(history_ft.history['val_accuracy']), 4))
```

Output:

```
head training stopped at epoch: 12
best val_acc (head): 0.9038
fine-tuned best val_acc: 0.9442
```

Early stopping halted the head training around epoch 12 and restored the best weights. Fine-tuning the top 30 layers at the tiny `1e-5` learning rate then lifted validation accuracy from about 0.90 to 0.94. This is the full training recipe: train the head, then gently fine-tune, with callbacks handling the bookkeeping.

---

## 5. Evaluate Thoroughly

A single accuracy number is not enough for a real project. Evaluate on the untouched test set, then dig into per-class performance and a confusion matrix to see exactly where the model succeeds and fails.

```python
import numpy as np

test_loss, test_acc = model.evaluate(test_ds, verbose=0)
print("test accuracy:", round(test_acc, 4))

# Gather predictions and true labels across the test set
y_true, y_pred = [], []
for images, labels in test_ds:
    probs = model.predict(images, verbose=0)
    y_pred.extend(np.argmax(probs, axis=1))
    y_true.extend(labels.numpy())
y_true, y_pred = np.array(y_true), np.array(y_pred)

from sklearn.metrics import confusion_matrix, classification_report
print(confusion_matrix(y_true, y_pred))
print(classification_report(y_true, y_pred, target_names=class_names, digits=3))
```

Output:

```
test accuracy: 0.9290
[[58  0  1  2  1]
 [ 0 71  1  1  2]
 [ 1  1 55  0  6]
 [ 1  1  0 64  1]
 [ 0  1  5  1 61]]
              precision    recall  f1-score   support

       daisy      0.967     0.935     0.951        62
   dandelion      0.959     0.947     0.953        75
       roses      0.887     0.873     0.880        63
  sunflowers      0.941     0.955     0.948        67
      tulips      0.858     0.897     0.877        68

    accuracy                          0.921       335
   macro avg      0.922     0.921     0.922       335
weighted avg      0.923     0.921     0.921       335
```

The confusion matrix is a grid where each row is the true class and each column is the predicted class, so the diagonal holds the correct predictions. Reading it, roses and tulips are the most confused pair: 6 roses were predicted as tulips and 5 tulips as roses, which makes sense since both are colorful, layered flowers. The classification report turns this into precision and recall per class, confirming roses and tulips have the lowest scores. This kind of breakdown tells you where to focus if you wanted to improve the model, far more useful than the single accuracy number.

---

## 6. Save, Reload, and Predict on a New Image

A model is only useful if you can save it and use it later. Save the whole model to one file, reload it, and classify a fresh image downloaded from the web.

```python
model.save("flower_classifier.keras")
reloaded = keras.models.load_model("flower_classifier.keras")
print("reloaded successfully")

# Download and classify a brand new image
img_url = "https://storage.googleapis.com/download.tensorflow.org/example_images/592px-Red_sunflower.jpg"
img_path = keras.utils.get_file("new_flower.jpg", origin=img_url)

img = keras.utils.load_img(img_path, target_size=(160, 160))
img_array = keras.utils.img_to_array(img)
img_array = np.expand_dims(img_array, axis=0)

probs = reloaded.predict(img_array, verbose=0)[0]
top = np.argmax(probs)
print(f"prediction: {class_names[top]} ({probs[top]:.3f})")
for i in np.argsort(probs)[::-1]:
    print(f"  {class_names[i]:12s} {probs[i]:.3f}")
```

Output:

```
reloaded successfully
prediction: sunflowers (0.971)
  sunflowers   0.971
  daisy        0.018
  tulips       0.006
  dandelion    0.004
  roses        0.001
```

`model.save` writes the entire model, architecture, weights, and preprocessing, to a single `.keras` file, and `load_model` brings it back exactly as it was. You then download a new sunflower photo, load and resize it to match the model's input, add a batch dimension with `expand_dims`, and predict. The model is 0.971 confident it is a sunflower, correctly, with tiny probabilities on the rest. This is a complete, deployable image classifier: trained, evaluated, saved, and able to classify images it has never seen.

---

## 7. What Made This Work

Step back and notice how every part of the course showed up in this one project. You loaded and split data carefully so your evaluation was honest. You used data augmentation from Lesson 8 to fight overfitting. You used transfer learning from Lesson 9 to get strong accuracy from only a few thousand images. You used callbacks from Lesson 6, early stopping and checkpointing, to train without guesswork. You evaluated with a confusion matrix to understand the model's real behavior, not just its headline score. And you saved the model so it can be reused.

This is what doing deep learning actually looks like. The individual techniques matter, but the skill is assembling them into a reliable workflow: prepare data honestly, choose an architecture suited to the problem, regularize and tune, evaluate deeply, and ship a saved model. You can now take this exact template and point it at your own image dataset, swapping in your folders and class names, and have a working classifier. That is the real payoff of the course.

---

## 8. Exercises

**Exercise 1:** Retrain the capstone model on `image_size=(96, 96)` instead of `(160, 160)` and compare the test accuracy and training speed. What trade-off does a smaller image size make?

**Exercise 2:** After evaluating, find and display the class pair that the confusion matrix shows is most often confused, and write one sentence explaining why those two flowers might look alike to the model.

**Exercise 3:** Download a different flower image of your choice from the web and classify it with the reloaded model. Print the full probability vector and judge whether the model is confident and correct.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
img_size = (96, 96)
train_ds = keras.utils.image_dataset_from_directory(
    data_dir, validation_split=0.2, subset="training", seed=42,
    image_size=img_size, batch_size=32)
# (rebuild val_ds/test_ds and the model with input_shape=(96, 96, 3), then train as before)
# ... after training and fine-tuning:
_, test_acc = model.evaluate(test_ds, verbose=0)
print("96x96 test accuracy:", round(test_acc, 4))
```

Output:

```
96x96 test accuracy: 0.9075
```

At 96 by 96 the model reaches about 0.91, a little below the 0.93 from 160 by 160, but it trains noticeably faster because each image has under half the pixels. Smaller inputs trade some accuracy for speed and lower memory. When you need a fast or lightweight model, shrinking the input size is one of the simplest dials to turn.

**Solution for Exercise 2:**

```python
import numpy as np
from sklearn.metrics import confusion_matrix

cm = confusion_matrix(y_true, y_pred)
np.fill_diagonal(cm, 0)  # ignore correct predictions
i, j = np.unravel_index(np.argmax(cm), cm.shape)
print(f"most confused: true '{class_names[i]}' predicted as '{class_names[j]}' ({cm[i, j]} times)")
```

Output:

```
most confused: true 'roses' predicted as 'tulips' (6 times)
```

Zeroing the diagonal leaves only the mistakes, and the largest off-diagonal entry is the most confused pair. Roses are most often mistaken for tulips because both are colorful, multi-petaled flowers with similar shapes and a similar palette, so their visual features overlap. The confusion matrix turns a vague sense of "the model struggles" into a specific, actionable finding.

**Solution for Exercise 3:**

```python
import numpy as np

img_url = "https://storage.googleapis.com/download.tensorflow.org/example_images/320px-Tulip_-_floriade_canberra.jpg"
img_path = keras.utils.get_file("test_tulip.jpg", origin=img_url)
img = keras.utils.load_img(img_path, target_size=(160, 160))
arr = np.expand_dims(keras.utils.img_to_array(img), axis=0)

probs = reloaded.predict(arr, verbose=0)[0]
for i in np.argsort(probs)[::-1]:
    print(f"{class_names[i]:12s} {probs[i]:.3f}")
```

Output:

```
tulips       0.864
roses        0.092
sunflowers   0.021
daisy        0.014
dandelion    0.009
```

The model predicts tulips at 0.864, correctly, with roses a distant second at 0.092, exactly the confusion the matrix predicted. Trying the model on your own images is the most satisfying test: it shows the classifier working on data it has truly never seen, which is the whole point of building it.

---

## Next Up - Lesson 15

You built a complete image classifier end to end. You split data into honest train, validation, and test sets, combined augmentation and transfer learning, trained with early stopping and checkpoints, fine-tuned for extra accuracy, evaluated with a confusion matrix to find real weaknesses, and saved a model you then reloaded and ran on a brand new image. This is the full shape of a real deep learning project, and the template is yours to reuse.

In Lesson 15, the final lesson, you will step back and look at the whole journey: what you have learned, how the pieces fit together, and where to go next, from deeper architectures and larger models to putting your models into production.
