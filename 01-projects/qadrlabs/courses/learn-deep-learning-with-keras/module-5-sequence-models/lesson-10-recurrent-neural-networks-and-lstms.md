## 1. Before You Begin

So far your models have treated each input as a fixed bundle of features: a row of measurements, or a grid of pixels. But a lot of important data is a sequence, where order carries meaning. The words in a sentence, the days in a stock chart, the notes in a melody: rearrange them and the meaning changes or vanishes. In this lesson you meet the architecture built for ordered data, the recurrent neural network, and its powerful upgrade, the LSTM.

You will use a movie review dataset to predict sentiment, positive or negative, from the words of a review. Along the way you will learn how an RNN carries memory across a sequence, why plain RNNs forget long-range information, and how an LSTM fixes that. This is your entry into deep learning for text.

### What You'll Build

A sentiment classifier for IMDB movie reviews. You will build a simple RNN with a word embedding layer, see its limits, then build an LSTM that handles the sequence far better, and compare the two.

### What You'll Learn

- ✅ Why sequential data needs a recurrent architecture
- ✅ How an RNN uses a hidden state to carry memory across steps
- ✅ What a word embedding layer does
- ✅ The vanishing gradient problem that limits plain RNNs
- ✅ How an LSTM remembers long-range information and why it usually wins

### What You'll Need

- The Keras workflow from earlier modules (`Sequential`, `compile`, `fit`)
- A Colab notebook with the GPU enabled
- Comfort with binary classification and the sigmoid output from Lesson 3

---

## 2. Why Sequences Need a Different Architecture

Consider the two sentences "the movie was not good" and "the movie was good, not bad". They share almost the same words but mean opposite things, because order and context decide meaning. A dense network sees a bag of features with no notion of order, and a CNN looks at fixed local windows. Neither naturally models "what came earlier changes what comes next" across a whole sequence.

A recurrent neural network is built exactly for this. It reads a sequence one element at a time, and crucially it carries a memory, called the hidden state, from each step to the next. When it reads the word "not", that information is stored in the hidden state and influences how it interprets "good" two steps later. The network processes the sequence in order, updating its memory as it goes, which is fundamentally different from looking at everything at once.

This same mechanism applies to any ordered data: text, time series, audio, sensor streams. Wherever the position of a value matters, a recurrent model can capture the dependency that a dense or convolutional model would miss.

---

## 3. How an RNN Works

An RNN has one simple, powerful trick: it applies the same small network repeatedly, once per time step, and feeds its own output back in as input for the next step. That fed-back value is the hidden state, a vector that acts as the network's running memory of everything it has seen so far.

At each step the RNN does three things. It takes the current input (say, the next word) and the previous hidden state. It combines them through a shared set of weights to produce a new hidden state. And it passes that new hidden state forward to the next step. After the final step, the last hidden state is a summary of the whole sequence, which a `Dense` layer can use to make a prediction.

Two ideas make this work. First, the weights are shared across all time steps, just as a convolution shares one filter across all positions in an image. This keeps the model compact and lets it handle sequences of any length. Second, the hidden state is the channel through which early information reaches later steps. If the hidden state can carry "I saw the word not" forward, the network can use it. As you will see, that "if" is exactly where plain RNNs run into trouble.

---

## 4. Load IMDB and Prepare Sequences

The IMDB dataset is 50,000 movie reviews labeled positive or negative, and it ships with Keras already converted to sequences of word indices, so each review is a list of integers where each integer represents a word.

```python
from tensorflow import keras

vocab_size = 10000
(x_train, y_train), (x_test, y_test) = keras.datasets.imdb.load_data(num_words=vocab_size)
print("train reviews:", len(x_train), "test reviews:", len(x_test))
print("first review length:", len(x_train[0]), "label:", y_train[0])
print("start of first review:", x_train[0][:10])
```

Output:

```
train reviews: 25000 test reviews: 25000
first review length: 218 label: 1
start of first review: [1, 14, 22, 16, 43, 530, 973, 1622, 1385, 65]
```

The argument `num_words=10000` keeps only the 10,000 most common words, which is plenty and keeps the vocabulary manageable. Each review is a list of integers of varying length, and the label is 1 for positive or 0 for negative. Networks need fixed-length input, so pad or truncate every review to the same length.

```python
maxlen = 200
x_train = keras.utils.pad_sequences(x_train, maxlen=maxlen)
x_test = keras.utils.pad_sequences(x_test, maxlen=maxlen)
print("x_train shape:", x_train.shape)
```

Output:

```
x_train shape: (25000, 200)
```

`pad_sequences` makes every review exactly 200 integers long, cutting longer ones and padding shorter ones with zeros at the front. Now every input is a clean `(200,)` sequence of word indices.

---

## 5. Build an RNN with an Embedding Layer

Word indices like 973 are just IDs; the number itself means nothing. The first layer of a text model is almost always an embedding layer, which turns each word index into a dense vector that the network learns. Words used in similar ways end up with similar vectors, giving the model a meaningful representation of language.

```python
from tensorflow.keras import layers

keras.utils.set_random_seed(42)
rnn = keras.Sequential([
    layers.Input(shape=(200,)),
    layers.Embedding(input_dim=vocab_size, output_dim=32),
    layers.SimpleRNN(32),
    layers.Dense(1, activation="sigmoid"),
])
rnn.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
rnn.summary()
```

Output:

```
Model: "sequential"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┓
┃ Layer (type)                    ┃ Output Shape           ┃       Param # ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━┩
│ embedding (Embedding)           │ (None, 200, 32)        │       320,000 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ simple_rnn (SimpleRNN)          │ (None, 32)             │         2,080 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense (Dense)                   │ (None, 1)              │            33 │
└─────────────────────────────────┴────────────────────────┴───────────────┘
 Total params: 322,113 (1.23 MB)
 Trainable params: 322,113 (1.23 MB)
 Non-trainable params: 0 (0.00 B)
```

Read the layers. `Embedding(input_dim=10000, output_dim=32)` learns a 32-number vector for each of the 10,000 words, which is the 320,000 parameters, and turns each `(200,)` review into a `(200, 32)` sequence of word vectors. `SimpleRNN(32)` reads that sequence step by step and outputs its final 32-number hidden state. The `Dense(1, sigmoid)` turns that summary into a sentiment probability. Train it.

```python
history = rnn.fit(x_train, y_train, validation_split=0.2,
                  epochs=5, batch_size=128, verbose=0)
for e in range(5):
    print(f"epoch {e+1}: train_acc={history.history['accuracy'][e]:.4f} "
          f"val_acc={history.history['val_accuracy'][e]:.4f}")

_, rnn_acc = rnn.evaluate(x_test, y_test, verbose=0)
print("SimpleRNN test accuracy:", round(rnn_acc, 4))
```

Output:

```
epoch 1: train_acc=0.5614 val_acc=0.6402
epoch 2: train_acc=0.7188 val_acc=0.7026
epoch 3: train_acc=0.7905 val_acc=0.7384
epoch 4: train_acc=0.8316 val_acc=0.7122
epoch 5: train_acc=0.8521 val_acc=0.6988
```
```
SimpleRNN test accuracy: 0.7035
```

The SimpleRNN learns something, reaching about 0.70, but it is unstable and the validation accuracy wobbles and even drops. For 200-word reviews, the plain RNN struggles to carry information from the start of a review to the end. The next section explains why and fixes it.

---

## 6. The Vanishing Gradient Problem and the LSTM

The SimpleRNN's weakness has a name: the vanishing gradient problem. During training, the error signal has to travel backward through every time step. Over a long sequence, that signal gets multiplied by small numbers again and again until it shrinks to almost nothing. The result is that the network cannot learn long-range dependencies; by the end of a 200-word review, it has effectively forgotten the beginning.

The LSTM, short for Long Short-Term Memory, was designed to solve exactly this. Alongside the hidden state, it maintains a separate cell state, a kind of conveyor belt that carries information across many steps with little change. It uses small neural gates to decide, at each step, what to forget from the cell state, what new information to add, and what to output. These gates let an LSTM hold onto important context, like the word "not", across long distances. In Keras it is a drop-in replacement for `SimpleRNN`.

```python
keras.utils.set_random_seed(42)
lstm = keras.Sequential([
    layers.Input(shape=(200,)),
    layers.Embedding(input_dim=vocab_size, output_dim=32),
    layers.LSTM(32),
    layers.Dense(1, activation="sigmoid"),
])
lstm.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])

history = lstm.fit(x_train, y_train, validation_split=0.2,
                   epochs=5, batch_size=128, verbose=0)
for e in range(5):
    print(f"epoch {e+1}: train_acc={history.history['accuracy'][e]:.4f} "
          f"val_acc={history.history['val_accuracy'][e]:.4f}")

_, lstm_acc = lstm.evaluate(x_test, y_test, verbose=0)
print("LSTM test accuracy:", round(lstm_acc, 4))
```

Output:

```
epoch 1: train_acc=0.6729 val_acc=0.8124
epoch 2: train_acc=0.8606 val_acc=0.8590
epoch 3: train_acc=0.8978 val_acc=0.8704
epoch 4: train_acc=0.9145 val_acc=0.8722
epoch 5: train_acc=0.9268 val_acc=0.8698
```
```
LSTM test accuracy: 0.8662
```

The difference is dramatic. The LSTM trains smoothly and reaches about 0.87 on the test set, well above the SimpleRNN's 0.70, with a single layer changed. Its cell state and gates let it carry sentiment cues across the whole review without forgetting them. This is why, for almost any real sequence task, you reach for an LSTM (or its close cousin the GRU) rather than a plain RNN.

---

## 7. Fix the Errors in Your Code

These sequence-model mistakes are common the first time.

**Mistake 1: Forgetting to pad sequences to equal length.**

```python
# Wrong: raw reviews have different lengths, which the model cannot batch
(x_train, y_train), _ = keras.datasets.imdb.load_data(num_words=10000)
rnn.fit(x_train, y_train, epochs=5)
```

```python
# Correct: pad every sequence to the same length first
x_train = keras.utils.pad_sequences(x_train, maxlen=200)
rnn.fit(x_train, y_train, epochs=5)
```

A network needs fixed-length input. Without `pad_sequences`, the reviews are lists of different lengths and cannot be stacked into a batch.

**Mistake 2: Mismatching the embedding vocabulary size.**

```python
# Wrong: data uses 10000 words but the embedding only allows 5000
(x_train, _), _ = keras.datasets.imdb.load_data(num_words=10000)
layers.Embedding(input_dim=5000, output_dim=32)
```

```python
# Correct: the embedding input_dim must cover every index in the data
layers.Embedding(input_dim=10000, output_dim=32)
```

The embedding's `input_dim` must be at least as large as the largest word index in your data. If the data uses indices up to 9,999, an `input_dim` of 5,000 causes out-of-range errors.

**Mistake 3: Reaching for SimpleRNN on long sequences.**

```python
# Wrong: a plain RNN forgets long-range context in long reviews
layers.SimpleRNN(32)
```

```python
# Correct: an LSTM carries information across long sequences
layers.LSTM(32)
```

For anything beyond very short sequences, a SimpleRNN suffers from vanishing gradients. Default to an LSTM or GRU, which are built to remember.

---

## 8. Exercises

**Exercise 1:** Rebuild the LSTM but make the embedding richer, with `output_dim=64` instead of 32, train for 5 epochs, and compare the test accuracy to the original LSTM.

**Exercise 2:** Wrap the LSTM in `layers.Bidirectional(...)` so it reads each review both forward and backward, train for 5 epochs, and report the test accuracy. Why might reading in both directions help?

**Exercise 3:** Take the trained LSTM and predict the sentiment probability of the first three test reviews. Print each probability and whether it matches the true label.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
keras.utils.set_random_seed(42)
model = keras.Sequential([
    layers.Input(shape=(200,)),
    layers.Embedding(input_dim=vocab_size, output_dim=64),
    layers.LSTM(32),
    layers.Dense(1, activation="sigmoid"),
])
model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
model.fit(x_train, y_train, validation_split=0.2, epochs=5, batch_size=128, verbose=0)
_, acc = model.evaluate(x_test, y_test, verbose=0)
print("64-dim embedding test accuracy:", round(acc, 4))
```

Output:

```
64-dim embedding test accuracy: 0.8703
```

A richer 64-dimensional embedding reaches about 0.87, a small gain over the 32-dimensional version. A larger embedding gives each word more room to encode meaning, which can help, though it also adds parameters and risk of overfitting. As always, bigger is not automatically better; it is a dial to tune.

**Solution for Exercise 2:**

```python
keras.utils.set_random_seed(42)
model = keras.Sequential([
    layers.Input(shape=(200,)),
    layers.Embedding(input_dim=vocab_size, output_dim=32),
    layers.Bidirectional(layers.LSTM(32)),
    layers.Dense(1, activation="sigmoid"),
])
model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
model.fit(x_train, y_train, validation_split=0.2, epochs=5, batch_size=128, verbose=0)
_, acc = model.evaluate(x_test, y_test, verbose=0)
print("bidirectional LSTM test accuracy:", round(acc, 4))
```

Output:

```
bidirectional LSTM test accuracy: 0.8742
```

A bidirectional LSTM runs two LSTMs, one reading the review left to right and one right to left, then combines them. It reaches about 0.87, a touch above the single-direction LSTM. Reading both ways helps because context can come from either side: a word's meaning often depends on what follows it, not just what precedes it, and a backward pass captures that.

**Solution for Exercise 3:**

```python
probs = lstm.predict(x_test[:3], verbose=0).ravel()
for i in range(3):
    label = int(probs[i] > 0.5)
    print(f"review {i}: prob={probs[i]:.3f} predicted={label} true={y_test[i]}")
```

Output:

```
review 0: prob=0.142 predicted=0 true=0
review 1: prob=0.889 predicted=1 true=1
review 2: prob=0.673 predicted=1 true=1
```

The sigmoid output is a probability that the review is positive. The first review scores 0.142, a confident negative, and the next two score above 0.5 as positive, all matching their true labels. As with the tumor classifier in Lesson 3, the raw probability tells you how confident the model is, and review 2 at 0.673 is a less certain positive than review 1.

---

## Next Up - Lesson 11

You learned how deep learning handles ordered data. A recurrent network carries a hidden state from step to step so earlier inputs influence later ones, an embedding layer turns word indices into learned vectors, and an LSTM uses a cell state and gates to remember long-range context that a plain RNN forgets. Your LSTM classified movie reviews at about 87 percent, far ahead of the SimpleRNN.

In Lesson 11, you will build a more complete text classifier from raw text, not pre-encoded integers. You will use a `TextVectorization` layer to turn real sentences into sequences, train your own embeddings, and assemble a solid sentiment model end to end, which is the natural bridge from sequences to the attention and Transformer ideas in Module 6.
