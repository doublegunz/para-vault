## 1. Before You Begin

Deep learning is the engine behind the most impressive AI you use today. The voice assistant that understands your speech, the camera that recognizes faces, the app that translates a photo of a menu, and the chatbots that write fluent text are all powered by deep learning. In the machine learning courses you trained models that learned from features you prepared by hand. Deep learning takes the next step: the model learns the useful features by itself, straight from raw data like pixels, audio, or text.

This lesson has no code. The goal is to build the right mental model before you write a single line in Keras. Once you understand what deep learning actually is, how it relates to the classical machine learning you already know, and what a neural network really does, every later lesson will click into place.

### What You'll Build

This lesson is conceptual, so there is nothing to run yet. By the end, you will have a clear picture of what deep learning is, how it differs from classical machine learning, what a neural network is made of, when deep learning is the right tool, and a preview of the models you will build throughout this course.

### What You'll Learn

- ✅ What deep learning is, in plain language
- ✅ How deep learning relates to and differs from classical machine learning
- ✅ What a neural network is: neurons, layers, and weights
- ✅ Why deep learning took off when it did
- ✅ When to reach for deep learning and when classical ML is the better choice
- ✅ What you will build in this course and the roadmap ahead

### What You'll Need

- Completion of the machine learning courses, or comfort with the train/test workflow and `fit`/`predict`
- A little basic Python knowledge
- A Google account so you can use Google Colab in the next lesson
- No deep learning background at all

---

## 2. What Is Deep Learning?

Deep learning is a branch of machine learning that uses neural networks with many layers to learn directly from raw data. The word "deep" simply refers to the number of layers stacked on top of each other. Where a classical model needs you to hand it a clean table of features, a deep learning model can take in raw pixels, raw audio, or raw text and learn what matters on its own.

Here is the key idea. In the machine learning courses, you spent real effort preparing features: encoding categories, scaling numbers, and engineering new columns from old ones. You were doing the thinking about what the model should pay attention to. A deep learning model flips this around. You feed it the raw input and the correct answers, and it discovers the useful features for itself, layer by layer. This ability to learn its own features is the single most important thing that sets deep learning apart.

Think about recognizing a cat in a photo. There is no clean table of "cat features" you can write down by hand. But a deep network can learn to detect edges in its first layer, combine those edges into shapes in the next layer, combine shapes into parts like ears and eyes deeper in, and finally decide "cat" at the end. Each layer builds on the one before it, turning raw pixels into meaning. That layered, automatic feature learning is what makes deep learning so powerful on images, audio, and language.

A few terms you will see throughout this course:

- A **neural network** is a model made of connected layers of simple units that transform the input step by step into a prediction.
- A **layer** is one stage of that transformation. Stacking many layers is what makes a network "deep".
- A **weight** is a number the network adjusts during training. The weights are what the model actually learns.
- **Training** is the process of showing the network examples and slowly tuning its weights so its predictions get better.

Deep learning is still machine learning. It follows the same spirit of learning from examples. It just does more of the work for you, at the cost of needing more data and more computing power.

---

## 3. How Deep Learning Differs from Classical Machine Learning

The clearest way to understand deep learning is to compare it with the classical machine learning you already practiced. With scikit-learn, you carefully built features and then handed them to a model like a random forest or a logistic regression. With deep learning, you hand the network raw data and let it build the features as part of training.

| | Classical Machine Learning | Deep Learning |
|---|---|---|
| Features | You engineer them by hand | The network learns them automatically |
| Best data type | Tabular data in tidy columns | Raw images, audio, and text |
| Data needed | Works well on small datasets | Usually needs a lot of data |
| Computing power | Trains fine on a normal CPU | Often wants a GPU to train quickly |
| Interpretability | Often easier to explain | Harder to interpret directly |

Notice that neither column is "better" in every case. Classical machine learning is often the smarter choice for small tables of structured data, like the Titanic dataset you worked with. Deep learning earns its keep when the input is raw and unstructured and you have enough examples to learn from, like thousands of images or large amounts of text.

Deep learning does not replace what you already know. The whole workflow you learned still applies: you define the problem, split the data into training and test sets, fit a model, and evaluate it honestly. Keras even mirrors scikit-learn with its `fit` and `predict` calls, so the new ideas in this course are about the model itself, not about relearning the process.

---

## 4. What Is a Neural Network?

A neural network is the model at the heart of deep learning, and it is built from a very simple part repeated many times. That part is called a neuron, or a unit. Understanding one neuron, and then how neurons form layers, is enough to picture the whole network.

A single neuron does three small things. First, it takes several input numbers and multiplies each one by its own weight. Second, it adds those products together along with an extra number called a bias. Third, it passes that sum through an activation function, which decides how strongly the neuron should fire. The result is a single number that becomes input to the next layer. You do not need the math right now. The point is that a neuron is just a weighted sum followed by a simple transformation.

Neurons are organized into layers, and layers are stacked in order:

- The **input layer** is where your raw data enters, such as the pixel values of an image.
- The **hidden layers** are the middle layers that do the real work of transforming the input. A network is "deep" when it has several of these.
- The **output layer** produces the final prediction, such as a probability for each class.

When you connect these layers, information flows from the input, through the hidden layers, to the output. Each layer reshapes the data a little, and together they turn raw input into a useful answer. The values that make this work are the weights and biases, and there can be thousands or millions of them in a real network.

So how does the network find good weights? It starts with random weights, makes a prediction, measures how wrong it was, and nudges every weight a tiny bit in the direction that reduces the error. Repeat this over many examples and the network gradually learns. You will see exactly how this loop works in Lesson 4, but the high-level idea is simple: predict, measure the error, adjust, and repeat.

---

## 5. Why Deep Learning Took Off

Neural networks are not a new idea. The core concepts are decades old. Yet deep learning only became dominant in roughly the last fifteen years. It helps to know why, because the same three forces are what make a course like this one possible from your browser.

**More data.** Neural networks are hungry for examples, and the internet finally provided them. Huge labeled collections of images, text, and audio gave networks enough material to learn rich features instead of overfitting tiny datasets.

**More computing power.** Training a deep network means doing an enormous number of small calculations. Graphics cards, or GPUs, turned out to be extremely good at exactly this kind of math. A GPU can train a network many times faster than an ordinary processor, which turned week-long experiments into hour-long ones. Google Colab gives you a free GPU, which is why you can train real models in this course without buying any hardware.

**Better tools.** Early neural networks were painful to build. Modern libraries like TensorFlow and its high-level interface Keras let you describe a network in a few readable lines and handle all the hard math behind the scenes. This course uses Keras precisely because it lets you focus on ideas instead of plumbing.

Together, these three forces, lots of data, fast GPUs, and friendly libraries, turned deep learning from a research curiosity into the technology behind everyday AI.

---

## 6. When to Use Deep Learning

It is tempting to reach for deep learning on every problem, but a good practitioner knows when it actually helps. Deep learning is powerful, but it is not always the right tool, and using it where it does not fit just wastes time and data.

Deep learning tends to win when:

- The input is raw and unstructured, such as images, audio, or natural language
- You have a large amount of data to learn from
- The patterns are too complex to capture with hand-built features
- You can use a GPU to train in a reasonable time

Classical machine learning is often the better choice when:

- Your data is a modest table of structured columns, like the datasets in the earlier courses
- You have a small dataset where a deep network would simply overfit
- You need a model that is fast to train and easier to explain
- A simple model already performs well enough

A healthy habit is to start simple. If a logistic regression or a random forest solves the problem, there is no shame in shipping it. Deep learning is the tool you bring out when the data is rich and unstructured and simpler methods are not enough. In this course you will focus on exactly the kinds of problems where deep learning shines, especially images, so you can see its strengths firsthand.

---

## 7. What You Will Build in This Course

Rather than studying theory in the abstract, you will build and train real neural networks from early on. Each module adds one capability, and the course ends with a complete project you assemble yourself. Everything runs in Google Colab with Keras, so there is nothing to install.

Along the way you will build:

- Your **first neural network** with Keras, trained to make predictions on a real dataset
- A **convolutional neural network** that classifies images by learning visual features
- An image classifier powered by **transfer learning**, where you reuse a powerful pretrained model
- A **recurrent network** with LSTM layers, and a text classifier built on word embeddings
- A small demonstration of **attention and Transformers**, the ideas behind modern language models
- A **capstone image classifier** that takes a dataset through the full deep learning workflow end to end

By the end you will not just know what deep learning is. You will have trained networks yourself and understand how the pieces fit together.

---

## 8. Course Roadmap

This course is organized into seven modules across fifteen lessons, moving from foundations to hands-on networks to a finished project. Each group of lessons focuses on one part of building deep learning models.

**Module 1** introduces deep learning and gets you set up in Google Colab with Keras and a free GPU.

**Module 2** has you build your first neural network and learn how a network actually learns, from loss and gradients to optimizers.

**Module 3** teaches how to train networks well by choosing good activations and architecture, then fighting overfitting with dropout, regularization, and early stopping.

**Module 4** moves into computer vision with convolutional neural networks, an image classifier you build from scratch, and transfer learning with pretrained models.

**Module 5** handles sequences like text with recurrent networks and LSTMs, and builds a text classifier using word embeddings.

**Module 6** introduces the attention mechanism and shows how Transformers work by putting a pretrained model to use.

**Module 7** brings everything together in a capstone image classifier and maps out where to go next.

---

## Next Up - Lesson 2

Deep learning is the branch of machine learning that uses many-layered neural networks to learn features directly from raw data. It differs from classical machine learning mainly in that the network engineers its own features, which makes it shine on unstructured data like images and text when you have enough examples and enough computing power. A neural network is built from simple neurons organized into input, hidden, and output layers, and it learns by adjusting its weights to reduce its error. You now have the mental model you need for everything that follows.

In Lesson 2, you will set up Google Colab, switch on a free GPU, confirm that Keras and TensorFlow are ready, and build and run a tiny network so your environment is proven before the real work begins.
