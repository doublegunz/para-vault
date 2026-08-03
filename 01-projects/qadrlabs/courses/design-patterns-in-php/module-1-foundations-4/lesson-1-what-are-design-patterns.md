## 1. Before You Begin

Software developers face the same problems over and over: how to create objects flexibly, how to add behavior without modifying existing code, how to decouple components that need to communicate. **Design patterns** are proven, reusable solutions to these recurring problems. They are not code you copy-paste; they are blueprints you adapt to your specific situation. This lesson explains what design patterns are, where they come from, how they are categorized, and when to use and not use them. By the end, you will understand the vocabulary that every senior developer uses and know the roadmap for the rest of this course.

### What You'll Build

You will set up the project structure used throughout this entire course: a Composer-autoloaded PHP project organized by pattern category, with a central `run.php` runner that lets you execute any pattern demo with a single command.

### What You'll Learn

- ✅ What design patterns are and why they matter
- ✅ The Gang of Four (GoF) and the 23 patterns
- ✅ The three categories: Creational, Structural, Behavioral
- ✅ How to read pattern descriptions: intent, problem, solution, structure
- ✅ When to use patterns and when to avoid them
- ✅ How patterns appear in PHP frameworks

### What You'll Need

- PHP OOP knowledge: classes, interfaces, abstract classes, inheritance
- A working PHP 8 environment (Laragon or CLI)
- Composer installed (for autoloading)

---

## 2. What Is a Design Pattern?

A design pattern is a general, reusable solution to a commonly occurring problem in software design. It is not a finished piece of code. It is a template that describes how to solve a problem in many different situations.

Think of a design pattern like an architectural blueprint for a house. The blueprint shows the general layout (living room, kitchen, bedrooms), but the exact dimensions, materials, and finishes depend on the specific house being built.

In programming, design patterns describe the relationships between classes and objects, the responsibilities each participant has, and the collaboration between them. You learn the pattern once and apply it to thousands of different situations.

---

## 3. The Gang of Four

In 1994, four authors -- Erich Gamma, Richard Helm, Ralph Johnson, and John Vlissides -- published "Design Patterns: Elements of Reusable Object-Oriented Software." They cataloged 23 design patterns that remain the foundation of software architecture to this day. The authors are known as the "Gang of Four" (GoF).

The 23 patterns are organized into three categories based on their purpose:

| Category | Purpose | Patterns |
|----------|---------|----------|
| **Creational** (5) | How objects are created | Singleton, Factory Method, Abstract Factory, Builder, Prototype |
| **Structural** (7) | How objects are composed | Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy |
| **Behavioral** (11) | How objects communicate | Chain of Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, Strategy, Template Method, Visitor |

---

## 4. How to Read a Pattern

Every pattern in this course follows a consistent structure. Understanding this structure helps you learn patterns faster and apply them correctly.

**Intent:** What the pattern does in one sentence. "Ensure a class has only one instance and provide a global point of access to it" (Singleton).

**Problem:** The situation where this pattern is useful. "You need exactly one database connection shared across the application."

**Solution:** How the pattern solves the problem. "Make the constructor private. Store the instance in a static property. Provide a static method to access it."

**Structure:** The classes involved and their relationships. We use simplified text diagrams.

**Real-world analogy:** A non-programming example that illustrates the concept.

**PHP Implementation:** Working code you can run.

**When to use:** Specific situations where the pattern fits.

**When to avoid:** Situations where the pattern is overkill or harmful.

---

## 5. When to Use (and Not Use) Patterns

Design patterns are tools, not rules. Using them incorrectly is worse than not using them at all.

**Use patterns when:**
- You have a recurring problem that matches a known pattern
- You need to communicate a design decision to other developers
- You want to make code flexible for future changes
- The complexity of the pattern is justified by the complexity of the problem

**Avoid patterns when:**
- The problem is simple (a pattern adds unnecessary complexity)
- You are using a pattern just to "use a pattern" (resume-driven development)
- A simpler solution exists (YAGNI: You Aren't Gonna Need It)
- The pattern makes the code harder to understand, not easier

A common mistake is applying the Strategy pattern to a function with one implementation, or using the Singleton pattern when a regular object would suffice. Patterns should simplify, not complicate.

---

## 6. Project Setup

Every lesson in this course uses the same project structure. Let us set it up once.

### Step 1: Create the Project

Create a new folder for the project and initialize it with Composer. Run the following commands in your terminal:

```bash
mkdir design-patterns
cd design-patterns
composer init --name=learn/design-patterns --type=project --autoload=src/ -n
```

### Step 2: Configure Autoloading

Open `composer.json` and verify the autoload section:

```json
{
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    }
}
```

Run:

```bash
composer dump-autoload
```

### Step 3: Create the Runner

Create `run.php` in the project root:

```php
<?php

require_once __DIR__ . '/vendor/autoload.php';

// Usage: php run.php Creational/Singleton
$pattern = $argv[1] ?? '';
$file = __DIR__ . '/src/' . $pattern . '/Demo.php';

if (file_exists($file)) {
    require $file;
} else {
    echo "Usage: php run.php Category/PatternName\n";
    echo "Example: php run.php Creational/Singleton\n";
}
```

### Step 4: Folder Structure

Create the following folder structure inside `src/`. You can create these directories now or add them as you work through each lesson:

```
design-patterns/
    src/
        Creational/
            Singleton/
            FactoryMethod/
            AbstractFactory/
            Builder/
            Prototype/
        Structural/
            Adapter/
            Bridge/
            Decorator/
            Proxy/
            Facade/
            Flyweight/
            Composite/
        Behavioral/
            Strategy/
            Observer/
            TemplateMethod/
            Command/
            ChainOfResponsibility/
            State/
            Iterator/
            Mediator/
            Memento/
            Visitor/
            Interpreter/
    run.php
    composer.json
```

Each pattern gets its own folder with the pattern classes and a `Demo.php` file.

---

## 7. Patterns in PHP Frameworks

Design patterns are not academic exercises. Every PHP framework uses them extensively:

| Pattern | Laravel | Symfony |
|---------|---------|---------|
| Facade | `Cache::get()`, `DB::table()` | - |
| Factory | Model factories, container bindings | Service container |
| Strategy | Filesystem drivers, cache drivers | Voters, serializers |
| Observer | Eloquent events, model observers | Event dispatcher |
| Decorator | Middleware stack | Security voters chain |
| Builder | Query builder, mail builder | Form builder |
| Repository | Eloquent (implicit) | Doctrine repositories |
| Singleton | Service container (shared) | Service container |
| Template Method | Artisan commands, form requests | Console commands |
| Iterator | Collections, lazy collections | Finder component |

Understanding patterns means understanding frameworks at a deeper level.

---

## 8. Next Up - Lesson 2

Design patterns are proven solutions to recurring software design problems. The 23 GoF patterns are organized into three categories: Creational (object creation), Structural (object composition), and Behavioral (object communication). Each pattern has an intent, a problem it solves, and a structure. Use patterns when the complexity is justified. Avoid them when a simpler solution works.

In Lesson 2, you will learn the SOLID principles: the five guidelines that make object-oriented code flexible and maintainable, and the foundation that makes every design pattern in this course feel intuitive rather than arbitrary.