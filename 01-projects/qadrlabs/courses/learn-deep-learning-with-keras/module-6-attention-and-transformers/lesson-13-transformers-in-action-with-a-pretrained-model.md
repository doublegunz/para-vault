## 1. Before You Begin

In Lesson 12 you built a Transformer block from scratch to understand attention. In the real world, you almost never do that. The Transformers that power modern AI are trained on enormous text collections using huge amounts of computing power, far beyond what any single project can manage. Instead, you download one of these pretrained models and put it to work. This lesson shows you how, using ready-made Transformers to solve language tasks with essentially no training of your own.

This is exactly how modern AI applications are built today. A pretrained model that has already learned language deeply can classify sentiment, sort text into categories you invent on the spot, and more, all from a few lines of code. You will use the popular Hugging Face library, which gives you access to thousands of pretrained Transformers through one simple interface.

### What You'll Build

A set of working language tools powered by pretrained Transformers: a sentiment analyzer, a zero-shot classifier that sorts text into labels you define yourself, and one more task of your choosing, all without training a model.

### What You'll Learn

- ✅ Why you use pretrained Transformers instead of training your own
- ✅ How to run a pretrained model with the Hugging Face `pipeline`
- ✅ How to do sentiment analysis with a real Transformer
- ✅ How zero-shot classification sorts text into labels with no training
- ✅ How these models connect to the attention you learned in Lesson 12

### What You'll Need

- The attention and Transformer concepts from Lesson 12
- A Colab notebook with the GPU enabled (faster, though not required)
- An internet connection so Colab can download the pretrained models

---

## 2. Why Use Pretrained Transformers

Training a Transformer like BERT or GPT from scratch takes vast datasets, weeks of computation, and budgets most teams will never have. But once such a model is trained, its learned understanding of language can be reused by anyone. These are often called foundation models: trained once at great expense, then adapted to countless tasks cheaply.

There are two ways to use them. You can fine-tune one on your own labeled data, the same idea as the image transfer learning in Lesson 9 but for text. Or, even simpler, you can use a model that is already fine-tuned for a task and just run it. This lesson focuses on the second path, because it is the fastest way to get real results and it shows the power of what these models already know.

The Hugging Face `transformers` library is the standard tool for this. It hosts thousands of pretrained models and wraps them in a `pipeline` helper that handles everything: downloading the model, tokenizing your text, running it, and formatting the output. You will use it for several tasks in a few lines each.

---

## 3. Sentiment Analysis with a Pipeline

First install the library, then build a sentiment pipeline. In Colab you install with a `!pip` command in a cell.

```python
!pip install -q transformers
```

```python
from transformers import pipeline

classifier = pipeline("sentiment-analysis")
result = classifier("I absolutely loved this movie, it was wonderful!")
print(result)
```

Output:

```
[{'label': 'POSITIVE', 'score': 0.9999}]
```

That is it. `pipeline("sentiment-analysis")` downloads a Transformer already fine-tuned for sentiment (a DistilBERT model trained on movie reviews) and returns a ready-to-use classifier. Calling it on a sentence returns the predicted label and a confidence score. Compare this to Lessons 10 and 11, where you built and trained a sentiment model yourself: here a far stronger model is ready in one line. It handles a batch just as easily.

```python
reviews = [
    "This is the best film I have seen all year.",
    "What a tedious, lifeless waste of time.",
    "It was fine, nothing special but watchable.",
]
for r in classifier(reviews):
    print(f"{r['label']:8s} {r['score']:.4f}")
```

Output:

```
POSITIVE 0.9998
NEGATIVE 0.9997
POSITIVE 0.9899
```

The model is highly confident on the clear cases and still leans positive on the lukewarm one. This pretrained Transformer reaches accuracy well above the models you trained from scratch, because it learned language from a massive corpus before ever seeing a sentiment label.

---

## 4. Zero-Shot Classification

Sentiment is impressive, but the model was fine-tuned for it. The truly striking ability of large Transformers is classifying text into categories they were never trained on, called zero-shot classification. You provide the text and a list of candidate labels you invent, and the model scores how well each fits.

```python
zero_shot = pipeline("zero-shot-classification")

text = "The new graphics card delivers incredible frame rates in modern games."
labels = ["technology", "sports", "cooking", "politics"]
result = zero_shot(text, candidate_labels=labels)

for label, score in zip(result["labels"], result["scores"]):
    print(f"{label:12s} {score:.4f}")
```

Output:

```
technology   0.9663
sports       0.0231
cooking      0.0058
politics     0.0048
```

You never trained anything on these categories, yet the model confidently picks "technology". It works because the model understands language well enough to judge how well a sentence matches the meaning of each label. Change the labels to anything you like and it adapts instantly, with no training. This flexibility is why foundation models are so powerful in real applications: one model handles tasks you define at runtime.

---

## 5. How This Connects to What You Learned

It can feel like magic, but everything here builds on the pieces you already understand. These pretrained models are deep stacks of the exact Transformer blocks you wrote in Lesson 12: multi-head self-attention, feed-forward networks, residual connections, and layer normalization, repeated many times and trained on enormous text.

The pipeline hides a few steps you have already met in spirit. It tokenizes your text into pieces and maps them to integer IDs, just like the `TextVectorization` layer in Lesson 11. It looks those IDs up in an embedding table, like the embedding layers in Module 5. Then it runs them through layer after layer of self-attention, where every token attends to every other token exactly as in your hand-coded attention. The only real differences are scale and pretraining: these models are vastly larger and have already learned language from billions of words.

So the journey of this course leads right here. You started with a single neuron, learned how networks train, taught them to see with CNNs and to read with RNNs, then understood the attention mechanism, and now you can wield the state-of-the-art models built from it. As a note, if you prefer to stay fully in the Keras ecosystem, the KerasHub library offers many of these same pretrained Transformers with a Keras-native API.

---

## 6. Fix the Errors in Your Code

These pitfalls are common when first using pretrained pipelines.

**Mistake 1: Forgetting to install or import the library.**

```python
# Wrong: using pipeline without installing transformers first
from transformers import pipeline   # ModuleNotFoundError
```

```python
# Correct: install in a cell first, then import
# !pip install -q transformers
from transformers import pipeline
```

Colab does not always have `transformers` preinstalled. Run `!pip install -q transformers` in a cell before importing it.

**Mistake 2: Recreating the pipeline on every call.**

```python
# Wrong: rebuilding the pipeline each time re-downloads and reloads the model
for text in many_texts:
    result = pipeline("sentiment-analysis")(text)
```

```python
# Correct: build the pipeline once, then reuse it
classifier = pipeline("sentiment-analysis")
for text in many_texts:
    result = classifier(text)
```

Creating a pipeline loads a large model into memory, which is slow. Build it once and reuse the object for all your inputs.

**Mistake 3: Expecting zero-shot without providing candidate labels.**

```python
# Wrong: zero-shot classification needs the labels you want to use
zero_shot("Some text to classify")
```

```python
# Correct: pass candidate_labels for the model to choose among
zero_shot("Some text to classify", candidate_labels=["news", "review", "question"])
```

Zero-shot classification chooses among labels you define, so you must pass `candidate_labels`. Without them the model has nothing to classify into.

---

## 7. Exercises

**Exercise 1:** Run the sentiment pipeline on five sentences of your own, including one sarcastic or ambiguous sentence. Look at the scores and note where the model is less confident or gets it wrong.

**Exercise 2:** Use the zero-shot classifier on a sentence about food, with the candidate labels `["cooking", "travel", "finance"]`. Confirm it picks the right one, then change the labels and rerun.

**Exercise 3:** Try a different pipeline task. Create a `pipeline("summarization")` and summarize a short paragraph of a few sentences. Inspect the generated summary.

---

## 8. Solutions

**Solution for Exercise 1:**

```python
from transformers import pipeline

classifier = pipeline("sentiment-analysis")
sentences = [
    "This product exceeded all my expectations.",
    "I will never buy from this company again.",
    "The package arrived on time.",
    "Oh great, another software update that breaks everything.",
    "It's not the worst thing I've ever watched.",
]
for s in classifier(sentences):
    print(f"{s['label']:8s} {s['score']:.4f}")
```

Output:

```
POSITIVE 0.9999
NEGATIVE 0.9995
POSITIVE 0.9970
NEGATIVE 0.9931
NEGATIVE 0.9210
```

The clear cases score near certainty. The sarcastic "Oh great, another update that breaks everything" is correctly read as negative, because the word "breaks" carries the real sentiment. The double-negative "not the worst" is labeled negative with lower confidence (0.92), showing the model can stumble on subtle phrasing. Reading the scores, not just the labels, reveals where the model is unsure.

**Solution for Exercise 2:**

```python
zero_shot = pipeline("zero-shot-classification")

text = "I slow-roasted the lamb for six hours with garlic and rosemary."
result = zero_shot(text, candidate_labels=["cooking", "travel", "finance"])
for label, score in zip(result["labels"], result["scores"]):
    print(f"{label:8s} {score:.4f}")
```

Output:

```
cooking  0.9842
travel   0.0103
finance  0.0055
```

The model confidently picks "cooking" from labels it was never trained on. If you rerun with different labels, say `["recipe", "restaurant review", "shopping list"]`, it will re-score against those instead. This is the flexibility that makes zero-shot classification so useful: you define the categories at runtime to fit your problem.

**Solution for Exercise 3:**

```python
summarizer = pipeline("summarization")

paragraph = (
    "Deep learning has transformed artificial intelligence over the past decade. "
    "Neural networks now power image recognition, speech systems, and language models. "
    "Convolutional networks handle images, recurrent networks handle sequences, and "
    "Transformers, built on attention, have become the dominant architecture for language. "
    "These advances were driven by larger datasets, faster hardware, and better software tools."
)
summary = summarizer(paragraph, max_length=40, min_length=15, do_sample=False)
print(summary[0]["summary_text"])
```

Output:

```
Deep learning has transformed artificial intelligence over the past decade. Convolutional networks handle images, recurrent networks handle sequences, and Transformers have become the dominant architecture for language.
```

A summarization pipeline uses a pretrained Transformer to condense the paragraph into its key points. The output keeps the main ideas and drops the supporting detail. The `max_length` and `min_length` arguments control the summary's size. Different pipeline tasks, sentiment, zero-shot, summarization, translation, and more, all follow the same simple pattern, which is what makes pretrained Transformers so practical.

---

## Next Up - Lesson 14

You learned to use pretrained Transformers, the way modern AI is actually built. With the Hugging Face `pipeline` you ran sentiment analysis, zero-shot classification, and summarization in a few lines each, using foundation models trained on enormous text. And you saw that these models are exactly the attention-based Transformer blocks from Lesson 12, scaled up and pretrained, connecting everything you have learned.

You now have the full toolkit of modern deep learning. In Lesson 14, you bring it all together in a capstone: an end-to-end image classifier built, trained, evaluated, and saved from start to finish, the way you would deliver a real project.
