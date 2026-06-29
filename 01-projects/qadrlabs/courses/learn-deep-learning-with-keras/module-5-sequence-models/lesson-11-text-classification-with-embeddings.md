## 1. Before You Begin

In Lesson 10 the IMDB reviews arrived pre-packaged as lists of integers, with the hard work of turning text into numbers already done for you. Real text never arrives that way. It comes as raw strings, and turning those strings into something a network can learn from is a core skill. In this lesson you build a complete text classifier from raw movie reviews, handling the entire pipeline yourself.

You will learn to use the `TextVectorization` layer to convert text into integer sequences, train your own word embeddings, and assemble a sentiment model that you can feed an actual sentence and get a prediction. By the end you will have an end-to-end model that takes a raw string in and returns a sentiment out.

### What You'll Build

A sentiment classifier trained on the raw IMDB text dataset. You will adapt a `TextVectorization` layer to the data, build an embedding-based model, train it, then wrap it into a single model that accepts plain text strings and predicts sentiment.

### What You'll Learn

- ✅ How `TextVectorization` turns raw text into integer sequences
- ✅ How to load a text dataset directly from folders of files
- ✅ How to train word embeddings as part of a classifier
- ✅ How a simple averaging model over embeddings can classify text well
- ✅ How to build an end-to-end model that accepts raw strings

### What You'll Need

- The embedding and sequence ideas from Lesson 10
- A Colab notebook with the GPU enabled
- Comfort with `compile`, `fit`, and binary classification

---

## 2. The Text Pipeline: From Words to Vectors

Before any model, raw text must become numbers. The `TextVectorization` layer does this in three automatic steps: it standardizes the text (lowercasing and stripping punctuation), splits it into tokens (words), and maps each token to an integer using a vocabulary it learns from your data. See it on a tiny example.

```python
from tensorflow.keras import layers

vectorizer = layers.TextVectorization(max_tokens=10, output_sequence_length=5)
vectorizer.adapt(["the movie was great", "the film was really bad"])

print("vocabulary:", vectorizer.get_vocabulary())
print("vectorized:", vectorizer(["the movie was great"]).numpy())
```

Output:

```
vocabulary: ['', '[UNK]', 'the', 'was', 'movie', 'great', 'film', 'really', 'bad']
vectorized: [[2 4 3 5 0]]
```

Calling `adapt` builds the vocabulary from the example sentences. The list is ordered by frequency, with two special entries first: `''` is the padding token (index 0) and `[UNK]` is for unknown words (index 1) not in the vocabulary. Then `the` and `was` come next because they appear twice. Vectorizing "the movie was great" yields `[2, 4, 3, 5, 0]`: the indices for the four words, padded to length 5 with a trailing 0. `max_tokens` caps the vocabulary size and `output_sequence_length` fixes the output length, so every input becomes a clean, equal-length integer sequence.

---

## 3. Load the Raw IMDB Text

Now get the real reviews as text files. The full IMDB dataset is distributed as folders of plain text, one file per review, organized into `pos` and `neg` subfolders. Keras can read that structure directly.

```python
import os, shutil
from tensorflow import keras

url = "https://ai.stanford.edu/~amaas/data/sentiment/aclImdb_v1.tar.gz"
dataset = keras.utils.get_file("aclImdb_v1", url, untar=True, cache_dir=".")
dataset_dir = os.path.join(os.path.dirname(dataset), "aclImdb")

# The train folder has an extra "unsup" folder with no labels; remove it
shutil.rmtree(os.path.join(dataset_dir, "train", "unsup"), ignore_errors=True)

train_ds = keras.utils.text_dataset_from_directory(
    os.path.join(dataset_dir, "train"), batch_size=32,
    validation_split=0.2, subset="training", seed=42)
val_ds = keras.utils.text_dataset_from_directory(
    os.path.join(dataset_dir, "train"), batch_size=32,
    validation_split=0.2, subset="validation", seed=42)
test_ds = keras.utils.text_dataset_from_directory(
    os.path.join(dataset_dir, "test"), batch_size=32)
```

Output:

```
Found 25000 files belonging to 2 classes.
Using 20000 files for training.
Found 25000 files belonging to 2 classes.
Using 5000 files for validation.
Found 25000 files belonging to 2 classes.
```

`get_file` downloads and unpacks the archive. The `train` folder includes an `unsup` folder of unlabeled reviews, which you delete so only `pos` and `neg` remain. Then `text_dataset_from_directory` builds datasets where each example is a raw review string and its label is taken from the folder name. You split the 25,000 training reviews into 20,000 for training and 5,000 for validation, with the test set kept separate.

---

## 4. Adapt a TextVectorization Layer

Create the vectorizer for the full task and adapt it to the training text so it learns a vocabulary from real reviews.

```python
max_features = 10000
seq_length = 200

vectorize_layer = layers.TextVectorization(
    max_tokens=max_features, output_mode="int", output_sequence_length=seq_length)

# Adapt on the training text only (labels dropped)
train_text = train_ds.map(lambda text, label: text)
vectorize_layer.adapt(train_text)

print("vocabulary size:", len(vectorize_layer.get_vocabulary()))
print("sample tokens:", vectorize_layer.get_vocabulary()[:8])
```

Output:

```
vocabulary size: 10000
sample tokens: ['', '[UNK]', 'the', 'and', 'a', 'of', 'to', 'is']
```

You adapt the vectorizer on the training text only, never the test set, the same no-leakage rule from earlier modules. It learns the 10,000 most common words, and the sample shows the most frequent ones are exactly the words you would expect. Now turn every dataset into integer sequences by mapping the vectorizer over them.

```python
def vectorize(text, label):
    return vectorize_layer(text), label

train_int = train_ds.map(vectorize)
val_int = val_ds.map(vectorize)
test_int = test_ds.map(vectorize)
```

This applies the vectorizer to every review, so the datasets now yield `(200,)` integer sequences and their labels, ready for a model.

---

## 5. Build and Train the Classifier

You will use a simple but surprisingly effective architecture: an embedding layer followed by global average pooling. Instead of an LSTM reading word by word, this averages all the word vectors in a review into one vector, then classifies it. It is fast, hard to overfit, and a strong baseline for sentiment.

```python
keras.utils.set_random_seed(42)
model = keras.Sequential([
    layers.Input(shape=(200,)),
    layers.Embedding(input_dim=max_features, output_dim=32),
    layers.GlobalAveragePooling1D(),
    layers.Dropout(0.3),
    layers.Dense(64, activation="relu"),
    layers.Dropout(0.3),
    layers.Dense(1, activation="sigmoid"),
])
model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])

history = model.fit(train_int, validation_data=val_int, epochs=10, verbose=0)
for e in (0, 4, 9):
    print(f"epoch {e+1}: train_acc={history.history['accuracy'][e]:.4f} "
          f"val_acc={history.history['val_accuracy'][e]:.4f}")

_, test_acc = model.evaluate(test_int, verbose=0)
print("test accuracy:", round(test_acc, 4))
```

Output:

```
epoch 1: train_acc=0.6421 val_acc=0.7704
epoch 5: train_acc=0.8907 val_acc=0.8770
epoch 10: train_acc=0.9176 val_acc=0.8852
test accuracy: 0.8745
```

The model reaches about 0.87 on the test set, right in the range of the LSTM from Lesson 10, with a much simpler and faster architecture. `GlobalAveragePooling1D` collapses the `(200, 32)` sequence of word vectors into a single 32-number average, which the dense layers classify. For sentiment, where the overall balance of positive and negative words matters more than exact order, averaging works remarkably well. The embedding still learned meaningful word vectors during training.

---

## 6. Use the Model on New Reviews

Right now the model expects integer sequences, so you would have to vectorize any new text by hand. Better to bundle the vectorizer and the trained model into one end-to-end model that accepts raw strings directly.

```python
inputs = keras.Input(shape=(1,), dtype="string")
x = vectorize_layer(inputs)
outputs = model(x)
end_to_end = keras.Model(inputs, outputs)

reviews = [
    "An absolute masterpiece, beautifully acted and deeply moving.",
    "A boring, predictable mess that wasted two hours of my life.",
    "It was okay, some good moments but mostly forgettable.",
]
probs = end_to_end.predict(reviews, verbose=0).ravel()
for r, p in zip(reviews, probs):
    sentiment = "positive" if p > 0.5 else "negative"
    print(f"{p:.3f} ({sentiment}): {r}")
```

Output:

```
0.921 (positive): An absolute masterpiece, beautifully acted and deeply moving.
0.083 (negative): A boring, predictable mess that wasted two hours of my life.
0.512 (positive): It was okay, some good moments but mostly forgettable.
```

The end-to-end model takes raw strings, vectorizes them with the adapted layer, and runs them through the trained network in one call. The clearly positive and negative reviews get confident scores near 0.92 and 0.08, while the lukewarm third review sits right at 0.51, almost undecided, which is exactly right for an ambivalent sentence. This is the model you would actually deploy, because it handles real text from start to finish.

---

## 7. Fix the Errors in Your Code

These text-pipeline mistakes are common and often silent.

**Mistake 1: Adapting the vectorizer on the test data.**

```python
# Wrong: adapting on test text leaks information about the test set
all_text = train_ds.concatenate(test_ds).map(lambda t, l: t)
vectorize_layer.adapt(all_text)
```

```python
# Correct: adapt on the training text only
train_text = train_ds.map(lambda text, label: text)
vectorize_layer.adapt(train_text)
```

The vocabulary is learned information, so it must come from the training data alone. Adapting on test text leaks the test distribution into your model and inflates your scores.

**Mistake 2: Forgetting to remove the unlabeled folder.**

```python
# Wrong: the train folder still has an "unsup" folder, creating a phantom 3rd class
train_ds = keras.utils.text_dataset_from_directory(os.path.join(dataset_dir, "train"))
# Found 75000 files belonging to 3 classes.
```

```python
# Correct: delete unsup so only pos and neg remain
shutil.rmtree(os.path.join(dataset_dir, "train", "unsup"), ignore_errors=True)
train_ds = keras.utils.text_dataset_from_directory(os.path.join(dataset_dir, "train"))
# Found 25000 files belonging to 2 classes.
```

`text_dataset_from_directory` treats every subfolder as a class. The leftover `unsup` folder would add a bogus third class of unlabeled reviews and break your binary classifier.

**Mistake 3: Vectorizing twice.**

```python
# Wrong: feeding already-vectorized integers back into the end-to-end string model
ints = vectorize_layer(reviews)
end_to_end.predict(ints)
```

```python
# Correct: the end-to-end model expects raw strings; the integer model expects integers
end_to_end.predict(reviews)        # raw strings
model.predict(vectorize_layer(reviews))  # integers
```

Keep clear which model eats what. The `end_to_end` model vectorizes internally, so give it raw strings. The inner `model` expects integers. Passing the wrong one causes type or shape errors.

---

## 8. Exercises

**Exercise 1:** Adapt a small `TextVectorization` layer (max_tokens=12, output_sequence_length=6) on three short sentences of your own, then print the vocabulary and the vectorized form of one sentence.

**Exercise 2:** Replace the `GlobalAveragePooling1D` model with one that uses an `LSTM(32)` after the embedding, train it for 5 epochs, and compare the test accuracy to the averaging model.

**Exercise 3:** Write three of your own short reviews (clearly positive, clearly negative, and mixed) and run them through the `end_to_end` model. Do the probabilities match your intuition?

---

## 9. Solutions

**Solution for Exercise 1:**

```python
from tensorflow.keras import layers

v = layers.TextVectorization(max_tokens=12, output_sequence_length=6)
v.adapt(["I loved this film", "I hated this film", "this film was fine"])
print("vocabulary:", v.get_vocabulary())
print("vectorized:", v(["I loved this film"]).numpy())
```

Output:

```
vocabulary: ['', '[UNK]', 'this', 'film', 'i', 'loved', 'hated', 'was', 'fine']
vectorized: [[4 5 2 3 0 0]]
```

The layer lowercases everything, so "I" becomes "i", and orders the vocabulary by frequency, with `this` and `film` appearing most. "I loved this film" maps to `[4, 5, 2, 3, 0, 0]`, padded to length 6. Building a tiny vectorizer by hand makes the standardize, split, and index steps concrete.

**Solution for Exercise 2:**

```python
keras.utils.set_random_seed(42)
lstm_model = keras.Sequential([
    layers.Input(shape=(200,)),
    layers.Embedding(input_dim=max_features, output_dim=32),
    layers.LSTM(32),
    layers.Dense(1, activation="sigmoid"),
])
lstm_model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
lstm_model.fit(train_int, validation_data=val_int, epochs=5, verbose=0)
_, acc = lstm_model.evaluate(test_int, verbose=0)
print("LSTM test accuracy:", round(acc, 4))
```

Output:

```
LSTM test accuracy: 0.8693
```

The LSTM reaches about 0.87, very close to the averaging model, but it takes noticeably longer to train because it processes each review word by word. For sentiment, where the overall mix of words is what matters, the simple averaging model is competitive with the heavier LSTM. The right choice depends on the task: order-sensitive problems favor the LSTM, while topic or sentiment problems often do fine with averaging.

**Solution for Exercise 3:**

```python
my_reviews = [
    "One of the best films I have ever seen, truly unforgettable.",
    "Terrible acting and a lazy script. Avoid it.",
    "Not bad, but it dragged in the middle and felt too long.",
]
probs = end_to_end.predict(my_reviews, verbose=0).ravel()
for r, p in zip(my_reviews, probs):
    print(f"{p:.3f} ({'positive' if p > 0.5 else 'negative'}): {r}")
```

Output:

```
0.945 (positive): One of the best films I have ever seen, truly unforgettable.
0.061 (negative): Terrible acting and a lazy script. Avoid it.
0.387 (negative): Not bad, but it dragged in the middle and felt too long.
```

The clearly positive and negative reviews land near 0.95 and 0.06, while the mixed review tips slightly negative at 0.39, reflecting its overall complaining tone despite the "not bad" opening. The model captures sentiment from your own words, which is the real test of a text classifier.

---

## Next Up - Lesson 12

You built a text classifier from raw strings end to end. You used `TextVectorization` to standardize, tokenize, and index text, adapted it on the training data only, trained your own word embeddings, and reached about 87 percent with a simple averaging model before wrapping everything into a model that accepts plain sentences. That is the complete modern text pipeline.

Recurrent models read text one step at a time, which is powerful but slow and forgetful over long passages. In Lesson 12, you will meet the idea that replaced them at the cutting edge: attention. You will see how a model can look at every word at once and decide which words matter most for each other, the core mechanism behind Transformers and modern language models.
