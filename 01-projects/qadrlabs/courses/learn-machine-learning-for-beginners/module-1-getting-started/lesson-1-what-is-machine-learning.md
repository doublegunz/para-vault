## 1. Before You Begin

Machine learning powers things you use every day. The spam filter in your email, the recommendations on YouTube, the face detection in your phone camera, and the fraud alerts from your bank are all built with machine learning. It can feel like magic, but underneath it is a practical idea you can learn step by step.

This lesson has no code. The goal is to build the right mental model before you write a single line. Once you understand what machine learning actually is, how it differs from normal programming, and what the typical workflow looks like, every later lesson will make far more sense.

### What You'll Build

This lesson is conceptual, so there is nothing to run yet. By the end, you will have a clear picture of what machine learning is, the main types of problems it solves, the standard workflow every project follows, and a preview of the models you will build throughout this course.

### What You'll Learn

- ✅ What machine learning is, in plain language
- ✅ How machine learning differs from traditional programming
- ✅ The main types of machine learning: supervised and unsupervised
- ✅ The difference between regression and classification
- ✅ The end-to-end machine learning workflow
- ✅ What you will build in this course and the roadmap ahead

### What You'll Need

- Curiosity and a little basic Python knowledge
- A Google account so you can use Google Colab in the next lesson
- No machine learning background at all

---

## 2. What Is Machine Learning?

Machine learning is a way of getting a computer to learn patterns from examples instead of being told exactly what to do. You show the computer many examples of a problem and its answers, and it figures out the rule that connects them on its own.

Here is a simple way to picture it. Imagine you want a program that decides whether an email is spam. The traditional approach is to write rules by hand: if the subject contains "free money", mark it as spam; if it has too many exclamation marks, mark it as spam. You quickly end up with hundreds of fragile rules that spammers learn to dodge.

The machine learning approach is different. You collect thousands of emails that are already labeled "spam" or "not spam", and you let an algorithm study them. The algorithm discovers the patterns by itself: which words, senders, and structures tend to appear in spam. The result is a model, a kind of trained function that takes a new email and predicts a label.

A few terms you will see throughout this course:

- A **dataset** is a table of examples. Each row is one example, like one email or one house.
- A **feature** is an input column the model learns from, like the number of links in an email or the size of a house.
- A **label** or **target** is the answer you want to predict, like "spam" or the price of a house.
- A **model** is the trained result that maps features to a prediction.

Machine learning shines when the rules are too complex or too fuzzy to write by hand, but you have plenty of examples to learn from.

---

## 3. How Machine Learning Differs from Traditional Programming

The clearest way to understand machine learning is to compare it with the programming you already know. In traditional programming, you write the rules and the computer applies them. In machine learning, you provide the data and the answers, and the computer writes the rules for you.

| | Traditional Programming | Machine Learning |
|---|---|---|
| You provide | Rules and data | Data and answers (labels) |
| The computer produces | Answers | The rules (a model) |
| Best for | Problems with clear logic | Problems with patterns but no clear rules |
| Example | Calculate tax from income | Predict if a transaction is fraud |

Think about recognizing a handwritten digit. Writing rules by hand for every possible way a person can draw a "7" is nearly impossible. But if you collect thousands of labeled images of digits, a machine learning model can learn to recognize them with high accuracy. That is the kind of problem where machine learning is not just convenient, it is the only realistic option.

This does not mean machine learning replaces normal programming. You still write plenty of code to load data, prepare it, train the model, and use its predictions. The model is just one new tool in your toolbox, and this course teaches you how to use it.

---

## 4. The Main Types of Machine Learning

Machine learning problems fall into a few broad families. Knowing which family your problem belongs to tells you which tools and algorithms to reach for. This course focuses on the two most common families, with a brief mention of a third.

**Supervised learning.** You have labeled data, meaning every example comes with the correct answer. The model learns the relationship between the features and the label so it can predict the label for new, unseen examples. Spam detection and house price prediction are both supervised learning. This is where most beginners start, and it is the main focus of this course.

Supervised learning splits into two types based on what you are predicting:

- **Regression** predicts a number on a continuous scale. Examples: predicting a house price, a person's weight, or tomorrow's temperature. The answer can be 250000, 312500, or any value in between.
- **Classification** predicts a category from a fixed set of options. Examples: spam or not spam, which species a flower is, or whether a customer will churn. The answer is one of a limited list of labels.

A quick test: if the answer is a quantity, it is regression. If the answer is a choice from a set of categories, it is classification.

**Unsupervised learning.** You have data with no labels, and you want the algorithm to find structure on its own. A common task is clustering, where the model groups similar examples together, such as segmenting customers into groups with similar buying habits. You will explore unsupervised learning in the follow-up course, "Machine Learning: Beyond the Basics".

**Reinforcement learning.** An agent learns by trial and error, receiving rewards or penalties for its actions, like a program learning to play a game. It is a fascinating field but well beyond a beginner course, so we only mention it here so you know the term.

---

## 5. The Machine Learning Workflow

Almost every machine learning project follows the same sequence of steps. You will repeat this workflow so many times in this course that it will become second nature. Here is the big picture before you dive into the details in later lessons.

1. **Define the problem.** Decide what you want to predict and whether it is a regression or classification task. Everything else depends on this.
2. **Collect and load the data.** Get a dataset of examples. In this course you will use clean, built-in datasets so you can focus on learning, not on hunting for data.
3. **Explore the data.** Look at it, summarize it, and visualize it. Understanding your data is half the battle and is the focus of Module 2.
4. **Prepare the data.** Handle missing values, convert text categories into numbers, and scale features when needed. This is Module 6.
5. **Split the data.** Set aside part of the data for testing so you can check whether the model truly learned or just memorized.
6. **Choose and train a model.** Pick an algorithm suited to your problem and let it learn from the training data.
7. **Evaluate the model.** Measure how well it performs on the test data using the right metrics. This is Module 5.
8. **Improve and use the model.** Tune it, then use it to make predictions on new data.

Do not worry about memorizing this list. Each step gets its own lessons with hands-on practice. The point right now is to see that machine learning is a process, not a single magic command.

---

## 6. What You Will Build in This Course

Rather than studying theory in the abstract, you will train real models on real datasets from your very first model onward. Each module adds one piece of the workflow, and the course ends with a complete project you build yourself.

Along the way you will build:

- A **regression model** that predicts California house prices from features like income and house age
- A **classification model** that identifies the species of an iris flower from its measurements
- Several **classifiers compared side by side**, including decision trees and k-nearest neighbors, so you can see their trade-offs
- A **capstone predictor** for the famous Titanic dataset, where you take messy, real-world data through the full workflow and predict who survived

Everything runs in Google Colab, a free notebook environment in your browser. There is nothing to install, and your work saves automatically to your Google account. You set that up in the next lesson.

---

## 7. Course Roadmap

This course is organized into seven modules across fourteen lessons, moving from concepts to hands-on models to a finished project. Each group of lessons focuses on one part of the machine learning workflow.

**Module 1** introduces machine learning and gets you set up in Google Colab.

**Module 2** teaches the Python data tools you will use constantly: NumPy and pandas for handling data, and matplotlib and seaborn for exploring it visually.

**Module 3** walks through the core machine learning workflow and has you build your first model, a regression model that predicts house prices.

**Module 4** moves into classification, where you predict categories using logistic regression, decision trees, and k-nearest neighbors.

**Module 5** teaches how to evaluate models honestly with the right metrics, and how to spot overfitting and underfitting.

**Module 6** covers preparing messy data: handling missing values, encoding categories, and scaling features.

**Module 7** brings everything together in a capstone project and maps out your next steps after this course.

---

## Next Up - Lesson 2

Machine learning is the practice of learning patterns from examples instead of coding rules by hand. In supervised learning you train on labeled data to predict either a number (regression) or a category (classification), and every project follows the same workflow: define, load, explore, prepare, split, train, evaluate, and use. You now have the mental model you need for everything that follows.

In Lesson 2, you will set up Google Colab, create your first notebook, run Python in the cloud, and import the machine learning libraries you will use for the rest of the course.
