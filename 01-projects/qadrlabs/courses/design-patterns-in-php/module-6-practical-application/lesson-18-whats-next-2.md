## 1. Before You Begin

You have completed the Design Patterns in PHP course. You now understand all 23 GoF patterns, the SOLID principles that underpin them, and how they appear in real PHP frameworks. This final lesson reviews the complete catalog, provides a pattern selection guide, and maps out your next steps.

### What You'll Learn

- ✅ Complete review of all 23 patterns
- ✅ Pattern selection guide: which pattern for which problem
- ✅ Patterns beyond the GoF catalog
- ✅ Advanced topics
- ✅ Recommended learning roadmap

---

## 2. The Complete Catalog

All 23 GoF patterns organized by category with one-line descriptions.

### Creational Patterns (How objects are created)

| Pattern | One-Line Description |
|---------|---------------------|
| **Singleton** | Ensure one instance; global access point |
| **Factory Method** | Delegate instantiation to subclasses |
| **Abstract Factory** | Create families of related objects |
| **Builder** | Construct complex objects step by step |
| **Prototype** | Create by cloning existing objects |

### Structural Patterns (How objects are composed)

| Pattern | One-Line Description |
|---------|---------------------|
| **Adapter** | Make incompatible interfaces work together |
| **Bridge** | Separate abstraction from implementation |
| **Composite** | Treat individuals and groups uniformly (tree) |
| **Decorator** | Add behavior without modifying the class |
| **Facade** | Simple interface to complex subsystem |
| **Flyweight** | Share common state between many objects |
| **Proxy** | Control access (caching, lazy loading, access control) |

### Behavioral Patterns (How objects communicate)

| Pattern | One-Line Description |
|---------|---------------------|
| **Chain of Responsibility** | Pass request through a handler chain |
| **Command** | Encapsulate actions as objects (undo, queue) |
| **Interpreter** | Evaluate sentences in a grammar |
| **Iterator** | Traverse collections uniformly |
| **Mediator** | Centralize complex communication |
| **Memento** | Save and restore state (undo/redo) |
| **Observer** | Notify many objects of state changes |
| **State** | Change behavior based on internal state |
| **Strategy** | Swap algorithms at runtime |
| **Template Method** | Algorithm skeleton with customizable steps |
| **Visitor** | Add operations without modifying classes |

---

## 3. Pattern Selection Guide

When you encounter a problem, use this guide to identify the right pattern.

**"I need to create objects without specifying the exact class"** -- Factory Method or Abstract Factory

**"I need to build a complex object step by step"** -- Builder

**"I need only one instance of something"** -- Singleton (or DI container singleton binding)

**"I need to add behavior without modifying a class"** -- Decorator

**"A third-party library has the wrong interface"** -- Adapter

**"I need a simple API for a complex system"** -- Facade

**"I need to swap algorithms at runtime"** -- Strategy

**"Multiple objects need to react when something changes"** -- Observer

**"I need undo/redo functionality"** -- Command + Memento

**"An object's behavior depends on its state"** -- State

**"I need to process a request through multiple handlers"** -- Chain of Responsibility

**"I need to traverse a collection without knowing its structure"** -- Iterator

---

## 4. Patterns Beyond GoF

The 23 GoF patterns are not the only ones. Additional patterns commonly used in PHP:

| Pattern | Description |
|---------|-------------|
| **Repository** | Abstracts data access layer (Doctrine, Eloquent) |
| **Data Transfer Object (DTO)** | Carries data between layers without behavior |
| **Value Object** | Immutable object defined by its values (Money, Email) |
| **Specification** | Encapsulate business rules as objects |
| **Unit of Work** | Track changes and commit atomically (Doctrine) |
| **Active Record** | Object wraps a database row (Eloquent) |
| **Data Mapper** | Separates domain and database (Doctrine) |
| **Service Layer** | Defines application boundary with services |
| **CQRS** | Separate read and write models |
| **Event Sourcing** | Store state changes as events |

---

## 5. Learning Roadmap

The following path takes you from pattern knowledge to architectural mastery.

```
Design Patterns -- This Course (completed) ✓
    |
    v
Apply in Projects
    ├── Refactor existing code using patterns
    ├── Identify patterns in framework source code
    └── Build a project using 5+ patterns
    |
    v
Architectural Patterns
    ├── Repository pattern
    ├── CQRS (Command Query Responsibility Segregation)
    ├── Event Sourcing
    ├── Domain-Driven Design (DDD)
    └── Hexagonal Architecture (Ports & Adapters)
    |
    v
Advanced OOP
    ├── GRASP principles
    ├── Tell, Don't Ask
    ├── Law of Demeter
    └── Composition over Inheritance
    |
    v
System Design
    ├── Microservices patterns
    ├── API design patterns
    ├── Distributed systems patterns
    └── Cloud architecture patterns
```

---

## 6. Key Takeaways

**Patterns are tools, not goals.** Use them when they simplify your code. Avoid them when they add unnecessary complexity.

**Start with SOLID.** If your code follows SOLID principles, patterns emerge naturally.

**Know the intent.** Understanding WHY a pattern exists is more important than memorizing its structure.

**Composition over inheritance.** Most patterns prefer composition (has-a) over inheritance (is-a).

**Patterns combine.** Real applications use multiple patterns together: Strategy + Factory, Observer + Command, Decorator + Composite.

**Frameworks are pattern libraries.** Laravel and Symfony are built on these patterns. Understanding patterns means understanding frameworks deeply.

---

## 7. You Have Completed the Course

You started with "What are design patterns?" and have now mastered all 23 GoF patterns: 5 creational (Singleton, Factory Method, Abstract Factory, Builder, Prototype), 7 structural (Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy), and 11 behavioral (Chain of Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, Strategy, Template Method, Visitor). You understand the SOLID principles that underpin them, the selection guide for choosing the right pattern, and how Laravel and Symfony implement these patterns in production code.

Design patterns are the vocabulary of professional software design. Use them when they simplify your code; avoid them when a simpler solution works. The foundation you built here will serve you in every PHP project, framework contribution, and architectural decision you make.

Happy designing.