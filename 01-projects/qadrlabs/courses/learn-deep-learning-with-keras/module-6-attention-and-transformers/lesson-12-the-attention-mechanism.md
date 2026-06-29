## 1. Before You Begin

The LSTMs from Module 5 read a sequence one step at a time, passing memory along a chain. That works, but it has two real weaknesses: it is slow because it cannot be parallelized, and information from far back still fades. In 2017 a new idea swept these problems aside and now powers every large language model: attention. In this lesson you will understand how attention works, compute it by hand, and build a small Transformer block with it.

The core idea is simple and powerful. Instead of passing memory step by step, attention lets every position in a sequence look directly at every other position and decide which ones matter most. When processing the word "it", the model can attend straight to the noun it refers to, however far away, in a single step. This is the mechanism behind Transformers, and understanding it is your gateway to modern AI.

### What You'll Build

A from-scratch numpy implementation of scaled dot-product attention to demystify the math, followed by a small Transformer encoder block built with Keras layers and used to classify IMDB reviews.

### What You'll Learn

- ✅ Why attention replaced recurrence at the cutting edge
- ✅ The query, key, and value idea at the heart of attention
- ✅ How to compute scaled dot-product attention step by step
- ✅ What self-attention and multi-head attention are
- ✅ How a Transformer encoder block is assembled in Keras

### What You'll Need

- The embedding and sequence ideas from Module 5
- A Colab notebook with Keras ready
- Comfort with NumPy and matrix multiplication

---

## 2. The Limits of Recurrence

An LSTM processes a sentence like a person reading with a finger, one word at a time, updating a single memory as it goes. Two problems follow from that design. First, because each step depends on the previous one, the work cannot be done in parallel, which makes training on long sequences slow. Second, even with its gates, an LSTM still compresses everything into one running memory, so distant connections weaken.

Attention throws out the step-by-step chain. It lets the model consider all positions at once and, for each position, compute how much it should focus on every other position. There is no fixed memory to bottleneck through and no long chain for gradients to fade along. Relationships between far-apart words become direct, one-step lookups rather than information that has to survive a long relay.

This is why Transformers, built entirely on attention, scaled to the enormous models you hear about today. They train efficiently in parallel and model long-range structure directly. The rest of this lesson builds attention up from its pieces.

---

## 3. What Is Attention?

Attention is built on three roles that every position in a sequence plays, named by an analogy to looking something up in a database: query, key, and value.

- The **query** is what the current position is looking for.
- The **key** is what each position offers, used to match against queries.
- The **value** is the actual information each position carries.

The mechanism works like this. For a given position's query, you compare it against the key of every position to get a score of how relevant each one is. You turn those scores into weights with softmax, so they are positive and sum to 1. Then you take a weighted sum of all the values using those weights. The result is a new representation of the position that blends in information from wherever it found the strongest match.

In self-attention, the queries, keys, and values all come from the same sequence, so every word builds a new version of itself by attending to the other words around it. The word "bank" can pull in context from "river" or "money" elsewhere in the sentence to disambiguate itself. The next section makes this concrete with numbers.

---

## 4. Scaled Dot-Product Attention by Hand

The standard form of attention is called scaled dot-product attention, and its whole formula is: score queries against keys with a dot product, scale, softmax, then weight the values. You can implement it in a few lines of NumPy on a tiny three-token example.

```python
import numpy as np

def softmax(x):
    e = np.exp(x - x.max(axis=-1, keepdims=True))
    return e / e.sum(axis=-1, keepdims=True)

# Three tokens, each a 2-dimensional vector
Q = np.array([[1, 0], [0, 1], [1, 1]], dtype=float)
K = np.array([[1, 0], [0, 1], [1, 1]], dtype=float)
V = np.array([[10, 0], [0, 10], [5, 5]], dtype=float)

d_k = Q.shape[-1]
scores = Q @ K.T / np.sqrt(d_k)
weights = softmax(scores)
output = weights @ V

print("attention weights:")
print(weights.round(3))
print("output:")
print(output.round(2))
```

Output:

```
attention weights:
[[0.401 0.198 0.401]
 [0.198 0.401 0.401]
 [0.248 0.248 0.503]]
output:
[[6.02 3.98]
 [3.98 6.02]
 [5.   5.  ]]
```

Walk through token 0. Its query `[1, 0]` matches the keys of token 0 and token 2 most strongly (both contain a 1 in the first slot), so it gives them the highest weights, 0.401 each, and only 0.198 to token 1. The output for token 0 is then a weighted blend of the values, leaning toward `V[0]` and `V[2]`, giving `[6.02, 3.98]`. The `/ np.sqrt(d_k)` is the "scaled" part: it keeps the dot products from growing too large as the vectors get longer, which keeps the softmax stable. That is the entire attention mechanism, just a dot product, a softmax, and a weighted sum.

---

## 5. Self-Attention and Multi-Head Attention

In a real model you do not hand-pick the query, key, and value vectors. The model learns three weight matrices that project each input into its query, key, and value. Because all three come from the same input sequence, this is called self-attention: every token learns how to query the others.

One refinement makes attention much stronger: doing it many times in parallel. Multi-head attention runs several attention operations, called heads, side by side, each with its own learned projections. One head might learn to track grammatical subjects, another to link pronouns to nouns, another to match adjectives to the words they describe. Their outputs are combined. Keras provides this as a single layer.

```python
from tensorflow import keras
from tensorflow.keras import layers
import numpy as np

mha = layers.MultiHeadAttention(num_heads=4, key_dim=16)
# A batch of 2 sequences, each 10 tokens, each token a 32-dim vector
x = np.random.rand(2, 10, 32).astype("float32")
out = mha(query=x, value=x, key=x)
print("input shape: ", x.shape)
print("output shape:", out.shape)
```

Output:

```
input shape:  (2, 10, 32)
output shape: (2, 10, 32)
```

You pass the same tensor as query, value, and key, which is what makes it self-attention. `num_heads=4` runs four attention heads, each with `key_dim=16` sized projections. The output has the same shape as the input, `(2, 10, 32)`, because attention produces a new, context-aware representation of each of the 10 tokens. This drop-in layer is the engine of a Transformer.

---

## 6. A Transformer Encoder Block

A Transformer is built by stacking a simple unit called the encoder block. Each block is multi-head self-attention followed by a small feed-forward network, with two helpful tricks around them: residual connections (adding the input back to the output) and layer normalization, both of which stabilize training of deep stacks. You can write one as a reusable layer.

```python
class TransformerBlock(layers.Layer):
    def __init__(self, embed_dim, num_heads, ff_dim):
        super().__init__()
        self.att = layers.MultiHeadAttention(num_heads=num_heads, key_dim=embed_dim)
        self.ffn = keras.Sequential([
            layers.Dense(ff_dim, activation="relu"),
            layers.Dense(embed_dim),
        ])
        self.norm1 = layers.LayerNormalization()
        self.norm2 = layers.LayerNormalization()
        self.drop = layers.Dropout(0.1)

    def call(self, inputs, training=False):
        attn = self.att(inputs, inputs)
        x = self.norm1(inputs + self.drop(attn, training=training))
        ffn = self.ffn(x)
        return self.norm2(x + self.drop(ffn, training=training))
```

Read the `call` method, because it is the whole pattern. It computes self-attention over the inputs, adds the result back to the inputs (the residual connection) and normalizes, then runs a feed-forward network and again adds and normalizes. Now use this block to classify IMDB reviews, reusing the padded integer data from Lesson 10.

```python
vocab_size, maxlen, embed_dim = 10000, 200, 32
keras.utils.set_random_seed(42)
inputs = keras.Input(shape=(maxlen,))
x = layers.Embedding(vocab_size, embed_dim)(inputs)
x = TransformerBlock(embed_dim, num_heads=2, ff_dim=32)(x)
x = layers.GlobalAveragePooling1D()(x)
x = layers.Dropout(0.1)(x)
outputs = layers.Dense(1, activation="sigmoid")(x)
model = keras.Model(inputs, outputs)
model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])

history = model.fit(x_train, y_train, validation_split=0.2,
                    epochs=5, batch_size=128, verbose=0)
print("final val_acc:", round(history.history['val_accuracy'][-1], 4))
_, test_acc = model.evaluate(x_test, y_test, verbose=0)
print("Transformer test accuracy:", round(test_acc, 4))
```

Output:

```
final val_acc: 0.8704
Transformer test accuracy: 0.8619
```

The attention-based model classifies sentiment at about 0.86, in the same league as the LSTM, but the self-attention lets every word relate to every other word directly rather than through a sequential chain. On large datasets and models, this direct, parallel design is what lets Transformers pull far ahead of recurrent networks. You have built the core of one yourself.

---

## 7. Fix the Errors in Your Code

These attention mistakes are common when starting out.

**Mistake 1: Forgetting to scale the dot product.**

```python
# Wrong: unscaled scores grow with dimension and push softmax into tiny gradients
scores = Q @ K.T
weights = softmax(scores)
```

```python
# Correct: scale by the square root of the key dimension
scores = Q @ K.T / np.sqrt(Q.shape[-1])
weights = softmax(scores)
```

Without the `1/sqrt(d_k)` scaling, dot products grow large as vectors get longer, which makes the softmax extremely peaked and its gradients vanish. The scaling keeps attention trainable.

**Mistake 2: Passing the wrong inputs to MultiHeadAttention.**

```python
# Wrong: only one argument; the layer needs query and value
out = layers.MultiHeadAttention(num_heads=4, key_dim=16)(x)
```

```python
# Correct: pass query and value (and optionally key) for self-attention
mha = layers.MultiHeadAttention(num_heads=4, key_dim=16)
out = mha(query=x, value=x, key=x)
```

`MultiHeadAttention` needs at least a query and a value. For self-attention, you pass the same tensor for all of them.

**Mistake 3: Dropping the residual connections.**

```python
# Wrong: no residual, so deep stacks of blocks become hard to train
x = self.norm1(self.drop(attn))
```

```python
# Correct: add the input back before normalizing
x = self.norm1(inputs + self.drop(attn))
```

The residual connection, adding the block's input back to its output, is what lets you stack many Transformer blocks without training breaking down. Leaving it out is a subtle but serious bug.

---

## 8. Exercises

**Exercise 1:** Change the values matrix to `V = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]` (keeping Q and K 2-dimensional as in the lesson) and recompute the attention output. What does each output row now represent?

**Exercise 2:** Create a `MultiHeadAttention` layer with `num_heads=8` and `key_dim=8`, apply it to a `(4, 12, 64)` input as self-attention, and print the output shape. Does the number of heads change the output shape?

**Exercise 3:** Build the IMDB Transformer model with two stacked `TransformerBlock` layers instead of one, train for 5 epochs, and compare the test accuracy to the single-block model.

---

## 9. Solutions

**Solution for Exercise 1:**

```python
import numpy as np

def softmax(x):
    e = np.exp(x - x.max(axis=-1, keepdims=True))
    return e / e.sum(axis=-1, keepdims=True)

Q = np.array([[1, 0], [0, 1], [1, 1]], dtype=float)
K = np.array([[1, 0], [0, 1], [1, 1]], dtype=float)
V = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1]], dtype=float)

weights = softmax(Q @ K.T / np.sqrt(Q.shape[-1]))
print((weights @ V).round(3))
```

Output:

```
[[0.401 0.198 0.401]
 [0.198 0.401 0.401]
 [0.248 0.248 0.503]]
```

With the values set to the identity matrix, each output row is simply the attention weights themselves, because multiplying the weights by the identity returns them unchanged. This makes the interpretation crystal clear: each row shows exactly how much that token attends to each of the three tokens. Using identity values is a handy trick for inspecting attention patterns directly.

**Solution for Exercise 2:**

```python
from tensorflow.keras import layers
import numpy as np

mha = layers.MultiHeadAttention(num_heads=8, key_dim=8)
x = np.random.rand(4, 12, 64).astype("float32")
out = mha(query=x, value=x, key=x)
print("output shape:", out.shape)
```

Output:

```
output shape: (4, 12, 64)
```

The output shape `(4, 12, 64)` matches the input exactly, regardless of the number of heads. Multi-head attention runs its heads internally and recombines them back to the input's feature size, so adding heads increases the layer's capacity and the variety of relationships it can learn without changing the output shape. This is why you can stack attention layers freely.

**Solution for Exercise 3:**

```python
from tensorflow import keras
from tensorflow.keras import layers

vocab_size, maxlen, embed_dim = 10000, 200, 32
keras.utils.set_random_seed(42)
inputs = keras.Input(shape=(maxlen,))
x = layers.Embedding(vocab_size, embed_dim)(inputs)
x = TransformerBlock(embed_dim, num_heads=2, ff_dim=32)(x)
x = TransformerBlock(embed_dim, num_heads=2, ff_dim=32)(x)
x = layers.GlobalAveragePooling1D()(x)
x = layers.Dropout(0.1)(x)
outputs = layers.Dense(1, activation="sigmoid")(x)
model = keras.Model(inputs, outputs)
model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
model.fit(x_train, y_train, validation_split=0.2, epochs=5, batch_size=128, verbose=0)
_, acc = model.evaluate(x_test, y_test, verbose=0)
print("two-block Transformer test accuracy:", round(acc, 4))
```

Output:

```
two-block Transformer test accuracy: 0.8647
```

Stacking two Transformer blocks reaches about 0.86, similar to the single block on this small dataset. Extra blocks add depth and capacity, which pays off most on large datasets and longer sequences where there is more structure to model. The fact that you can stack blocks cleanly, thanks to residual connections and layer normalization, is exactly what lets real Transformers grow to dozens or hundreds of layers.

---

## Next Up - Lesson 13

You learned the mechanism behind modern AI. Attention lets every position in a sequence look at every other position and blend in the most relevant information, using queries, keys, and values, scored with a scaled dot product and a softmax. Multi-head attention runs several of these in parallel, and a Transformer block wraps self-attention and a feed-forward network with residual connections and normalization. You built one and classified text with it.

Building Transformers from scratch is instructive, but in practice you almost never do it. The real power comes from using enormous Transformers that others have pretrained on vast text collections. In Lesson 13, you will put a pretrained Transformer to work, using a ready-made model to solve a language task with almost no training of your own, the same way modern AI applications are actually built.
