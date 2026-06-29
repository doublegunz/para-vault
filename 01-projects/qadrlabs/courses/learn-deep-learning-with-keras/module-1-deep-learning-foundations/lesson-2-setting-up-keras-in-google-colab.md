## 1. Before You Begin

In Lesson 1 you built the mental model for deep learning: networks made of layers that learn their own features from raw data. Now it is time to set up the place where you will train those networks for the rest of this course. You will use Google Colab again, just like in the machine learning courses, but with two important additions: a free GPU to make training fast, and Keras, the library you will use to build every model.

By the end of this lesson you will have a notebook with the GPU switched on, you will have confirmed that TensorFlow and Keras are ready, and you will have built and run a tiny neural network to prove your environment works end to end. From here on, every lesson assumes this setup is in place.

### What You'll Build

A working Colab notebook named `dl-setup` that runs on a GPU, prints your TensorFlow and Keras versions, confirms the GPU is visible, and builds a tiny two-layer neural network that you inspect and run a prediction through. This proves your deep learning environment is fully working.

### What You'll Learn

- ✅ Why Colab with a free GPU is ideal for deep learning
- ✅ How Keras relates to TensorFlow
- ✅ How to create a notebook and switch on the GPU runtime
- ✅ How to check your TensorFlow and Keras versions and confirm the GPU is active
- ✅ How to build a simple model with `keras.Sequential` and inspect it with `summary()`
- ✅ How to run a prediction through an untrained network to confirm everything works

### What You'll Need

- A Google account (the same one you use for Gmail or Drive)
- A web browser, Chrome recommended
- The mental model of deep learning from Lesson 1

---

## 2. Why Google Colab for Deep Learning

You already know Colab from the machine learning courses: it runs Python notebooks in your browser with the common data libraries preinstalled, so there is nothing to set up on your computer. For deep learning, Colab brings one extra benefit that matters a lot.

The big addition is the **GPU**. As you saw in Lesson 1, training a neural network means doing a huge number of small calculations, and a graphics card is built to do exactly that kind of math in parallel. Training that would take many minutes on a normal processor can finish in seconds on a GPU. Colab gives you a GPU for free, which is why you can train real models in this course without owning any special hardware.

The other convenience is that the deep learning libraries are already installed. In particular, **TensorFlow** comes preinstalled, and **Keras** ships inside it. TensorFlow is the engine that does the heavy math, and Keras is the friendly, high-level interface you write your code against. You will meet that relationship more closely at the end of this lesson. For now, the takeaway is simple: open a notebook, turn on the GPU, and the whole deep learning stack is ready to go.

---

## 3. Create Your Notebook and Turn On the GPU

Let us create the notebook for this lesson and, most importantly, switch on the GPU. Enabling the GPU is the one new setup step compared to the earlier courses, so do not skip it.

### Step 1: Create and rename a notebook

In your browser, go to [https://colab.research.google.com](https://colab.research.google.com) and sign in with your Google account if needed. Click **New notebook** in the bottom right of the dialog, or use **File > New notebook**. A fresh notebook opens with one empty code cell.

At the top left, click the name (something like `Untitled0.ipynb`) and rename it to `dl-setup`. Clear names save you confusion once you have many notebooks.

### Step 2: Switch on the GPU

This is the key step. In the menu, go to **Runtime > Change runtime type**. In the dialog that appears, find the **Hardware accelerator** setting, choose a **GPU** option (often labeled "T4 GPU"), and click **Save**.

Colab will connect you to a machine that has a GPU attached. You only need to do this once per notebook. If your session disconnects after a long idle period, you may need to reconnect, but the GPU setting stays saved with the notebook.

### Step 3: Know what the GPU gives you

You will not see anything dramatic happen yet. The GPU simply means that when you train a model later, TensorFlow can offload the math to the graphics card automatically. You do not write any special code to use it. In the next section you will confirm that the GPU is actually available.

---

## 4. Check Your Setup

Before relying on the environment, confirm that the libraries are present and that the GPU is active. This doubles as a quick test that everything is wired up correctly.

### Step 1: Print your versions

Click into the first code cell, type the following, and run it with **Shift + Enter**:

```python
import sys
import numpy as np
import tensorflow as tf
from tensorflow import keras

print("Python version:", sys.version.split()[0])
print("TensorFlow:", tf.__version__)
print("Keras:", keras.__version__)
print("NumPy:", np.__version__)
```

Line by line: `import sys` gives access to interpreter details, `numpy` is the array library aliased to `np`, and `import tensorflow as tf` loads TensorFlow with its universal alias `tf`. The line `from tensorflow import keras` pulls out the Keras interface that lives inside TensorFlow, so you can write `keras.something` from now on. The `print()` lines then report each version.

The output looks something like this, though your exact numbers will differ because Colab updates its libraries over time:

```
Python version: 3.12.13
TensorFlow: 2.21.0
Keras: 3.15.0
NumPy: 2.5.0
```

If this runs without errors, TensorFlow and Keras are installed and ready. The specific version numbers do not matter for this course.

### Step 2: Confirm the GPU is visible

Now check that the GPU you enabled is actually available to TensorFlow. In a new cell, run:

```python
print("GPUs:", tf.config.list_physical_devices('GPU'))
```

`tf.config.list_physical_devices('GPU')` asks TensorFlow which GPUs it can see. When the GPU runtime is active, you will see a list with one device, like this:

```
GPUs: [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

If instead you see an empty list:

```
GPUs: []
```

then the GPU is not enabled. Go back to **Runtime > Change runtime type**, select **GPU**, click **Save**, and run the cell again. An empty list means TensorFlow will fall back to the CPU, which still works but trains much more slowly.

---

## 5. Build and Run a Tiny Network

Time to build your very first neural network. It will be tiny and untrained, so it will not do anything useful yet. The goal is only to confirm that you can define a model with Keras, inspect it, and pass data through it. This is the same pattern you will use for every model in the course, just smaller.

### Step 1: Import the building blocks

In a new cell, import the pieces you need and run it:

```python
from tensorflow import keras
from tensorflow.keras import layers
```

`keras` gives you the tools to assemble and run models, and `layers` is the module that holds the layer types you stack together, such as the `Dense` layer you are about to use. A successful import is silent, so seeing no output is expected.

### Step 2: Define a Sequential model

Now define a small network. In a new cell, type:

```python
model = keras.Sequential([
    layers.Input(shape=(4,)),
    layers.Dense(8, activation="relu"),
    layers.Dense(1)
])
```

`keras.Sequential` builds a model as a simple stack of layers, one after another, which is the most common way to start. Inside the list:

- `layers.Input(shape=(4,))` tells the model to expect inputs with 4 features each. Declaring the input shape lets Keras build the model right away.
- `layers.Dense(8, activation="relu")` is a fully connected layer with 8 neurons. As you saw in Lesson 1, each neuron computes a weighted sum and then an activation. Here the activation is `relu`, a common choice you will learn about in Module 3.
- `layers.Dense(1)` is the output layer with a single neuron, which would produce one number per input, suitable for predicting a quantity.

This cell produces no output. It just defines the model.

### Step 3: Inspect the model with summary

A great habit is to look at a model right after building it. In a new cell, run:

```python
model.summary()
```

`model.summary()` prints a table of the layers, the shape of the data leaving each one, and how many weights (parameters) the model has. You will see:

```
Model: "sequential"
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┓
┃ Layer (type)                    ┃ Output Shape           ┃       Param # ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━┩
│ dense (Dense)                   │ (None, 8)              │            40 │
├─────────────────────────────────┼────────────────────────┼───────────────┤
│ dense_1 (Dense)                 │ (None, 1)              │             9 │
└─────────────────────────────────┴────────────────────────┴───────────────┘
 Total params: 49 (196.00 B)
 Trainable params: 49 (196.00 B)
 Non-trainable params: 0 (0.00 B)
```

Read this table carefully because it teaches you how a network is sized. The first `Dense` layer has 40 parameters: each of its 8 neurons takes 4 inputs (4 times 8 is 32 weights) plus one bias per neuron (8 biases), giving 40. The second layer has 9 parameters: 8 weights coming in plus 1 bias. The `None` in the output shape is a placeholder for the batch size, meaning the model handles any number of rows at once. With 49 total trainable parameters, this is about as small as a network gets, which is perfect for a quick check.

### Step 4: Run a prediction through it

Finally, push some data through the untrained model to confirm it runs. In a new cell:

```python
import numpy as np

X = np.random.rand(3, 4)
predictions = model.predict(X)
print("Input shape:", X.shape)
print("Output shape:", predictions.shape)
```

`np.random.rand(3, 4)` makes a small batch of fake data: 3 examples, each with 4 features, matching the input shape you declared. `model.predict(X)` runs that data forward through the network and returns its outputs. You then print the shapes. Running it shows a short progress bar and then the shapes:

```
1/1 ━━━━━━━━━━━━━━━━━━━━ 0s 36ms/step
Input shape: (3, 4)
Output shape: (3, 1)
```

The output shape `(3, 1)` is exactly what you should expect: 3 examples in, so 3 predictions out, each a single number because the output layer has one neuron. The actual values are meaningless right now because the model is untrained, with random weights. What matters is that data flowed through cleanly. Your deep learning environment works.

---

## 6. How Keras Relates to TensorFlow

Now that you have built a model, it is worth pinning down the relationship between the two names you keep seeing, because it explains why the code reads so cleanly.

**TensorFlow** is the engine. It handles the heavy numerical work, runs calculations on the GPU, and computes the gradients that let a network learn. It is powerful but low level, and writing networks directly against it would mean a lot of detail.

**Keras** is the high-level interface that sits on top of that engine. When you wrote `keras.Sequential`, stacked a couple of `layers.Dense`, and called `model.predict`, Keras translated those readable instructions into the low-level operations TensorFlow runs for you. This is exactly why you will spend your time thinking about layers and architecture rather than raw math.

If you came from the machine learning courses, the shape of this will feel familiar. You created a model object, and you will soon call `model.fit` to train it and `model.predict` to use it, just like scikit-learn. The data that flows through these models is held in **tensors**, which are simply multi dimensional arrays much like the NumPy arrays you already know. You passed a plain NumPy array into `predict` a moment ago and Keras handled the conversion. Keep that mental picture: Keras is the friendly steering wheel, TensorFlow is the engine, and your data rides through as tensors.

---

## 7. Fix the Errors in Your Code

A few mistakes catch almost everyone setting up their first deep learning notebook. Here is how to recognize and fix them.

**Mistake 1: Expecting a GPU when the runtime is still on CPU.**

```python
# Wrong: you assumed the GPU is on, but never enabled it
print("GPUs:", tf.config.list_physical_devices('GPU'))
# GPUs: []
```

```python
# Correct: enable the GPU first via Runtime > Change runtime type > GPU,
# then re-run the check
print("GPUs:", tf.config.list_physical_devices('GPU'))
# GPUs: [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

An empty list does not mean your code is broken. It means the notebook is running on the CPU. Enable the GPU runtime and run the cell again. Training will still work on CPU, just slowly.

**Mistake 2: Forgetting to declare the input shape.**

```python
# Wrong: no Input layer, so the model is not built yet
model = keras.Sequential([
    layers.Dense(8, activation="relu"),
    layers.Dense(1)
])
model.summary()
```

If you call `summary()` on this model, the layers show `?` for their output shape and `0 (unbuilt)` for parameters, because Keras does not yet know the input size.

```python
# Correct: declare the input shape so the model builds immediately
model = keras.Sequential([
    layers.Input(shape=(4,)),
    layers.Dense(8, activation="relu"),
    layers.Dense(1)
])
model.summary()
```

Starting with `layers.Input(shape=(...))` lets Keras size every layer right away, so `summary()` shows real shapes and parameter counts.

**Mistake 3: Feeding data with the wrong number of features.**

```python
# Wrong: the model expects 4 features, but this data has 5
X = np.random.rand(3, 5)
model.predict(X)
# ValueError: ... incompatible shape ...
```

```python
# Correct: the number of columns must match the declared input shape
X = np.random.rand(3, 4)
model.predict(X)
```

A neural network is strict about input shape. If you declared `shape=(4,)`, every example must have exactly 4 features, or Keras raises a `ValueError`. Match your data's column count to the input shape.

---

## 8. Exercises

**Exercise 1:** In your `dl-setup` notebook, add a text (markdown) cell at the top with a heading like `# Deep Learning Setup` and a sentence describing what the notebook does. Run it to see it render.

**Exercise 2:** Build a slightly bigger model that expects 10 features and has two hidden layers of 16 and 8 neurons (both with `relu`) and a single output neuron. Call `model.summary()` and find the total parameter count.

**Exercise 3:** Create a batch of 5 fake examples with the right number of features for your Exercise 2 model, run `model.predict` on it, and print the output shape. Confirm it matches the number of examples you sent in.

---

## 9. Solutions

**Solution for Exercise 1:**

Add a text cell (use **+ Text**) and type:

```markdown
# Deep Learning Setup

This notebook confirms my TensorFlow and Keras versions, checks that the GPU is enabled, and builds and runs a tiny neural network to prove the environment works.
```

Text cells use Markdown, where `#` creates a heading. When you run the cell, Colab renders it as formatted text. Documenting your notebooks keeps them readable as they grow.

**Solution for Exercise 2:**

```python
from tensorflow import keras
from tensorflow.keras import layers

model = keras.Sequential([
    layers.Input(shape=(10,)),
    layers.Dense(16, activation="relu"),
    layers.Dense(8, activation="relu"),
    layers.Dense(1)
])
model.summary()
```

The total comes to 321 parameters. The first hidden layer has 10 times 16 plus 16 biases, which is 176. The second has 16 times 8 plus 8 biases, which is 136. The output has 8 plus 1, which is 9. Adding 176, 136, and 9 gives 321. Working through the math by hand a few times builds a real feel for how layer sizes drive a model's size.

**Solution for Exercise 3:**

```python
import numpy as np

X = np.random.rand(5, 10)
predictions = model.predict(X)
print("Output shape:", predictions.shape)
```

Output:

```
1/1 ━━━━━━━━━━━━━━━━━━━━ 0s 40ms/step
Output shape: (5, 1)
```

You sent in 5 examples, each with 10 features to match the model's input shape, so you get 5 predictions back, each a single number. The `(5, 1)` shape confirms the data flowed through correctly. As before, the values themselves are random because the model is untrained.

---

## Next Up - Lesson 3

You now have a deep learning notebook with the GPU enabled, you have confirmed your TensorFlow and Keras versions, and you have built, inspected, and run a tiny network from start to finish. You also know how Keras and TensorFlow fit together: Keras is the readable interface, TensorFlow is the engine underneath, and your data flows through as tensors. Your environment is proven and ready.

In Lesson 3, you will build your first real neural network and actually train it on a dataset. You will compile the model with a loss function and an optimizer, call `model.fit` to train it, and watch its predictions improve, taking the leap from a model that merely runs to one that genuinely learns.
