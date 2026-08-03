## 1. Before You Begin

The final three behavioral patterns solve specialized problems. **Memento** saves and restores an object's state without violating encapsulation, enabling undo and redo functionality. **Visitor** adds operations to a class hierarchy without modifying the classes, using a technique called double dispatch. **Interpreter** defines a grammar and an interpreter for a simple language. These patterns are less common in everyday PHP but essential to know when you encounter their specific use cases — Memento in editors and form wizards, Visitor in AST processing and report generation, Interpreter in template engines and query parsers.

### What You'll Build

You will create a Memento-based undo system for an editor, a Visitor for calculating statistics on different shape types, and a simple expression Interpreter.

### What You'll Learn

- ✅ Memento: save/restore state without exposing internals
- ✅ Caretaker, Originator, and Memento roles
- ✅ Visitor: add operations to classes without modifying them
- ✅ Double dispatch mechanism
- ✅ Interpreter: define and evaluate simple grammars

### What You'll Need

- Lesson 15 completed

---

## 2. Memento Pattern

Memento captures an object's internal state as a snapshot. The originator creates the memento. The caretaker stores it. The originator can later restore from a memento.

```php
<?php
namespace App\Behavioral\Memento;

// Memento: stores a snapshot of state
class EditorMemento
{
    public function __construct(
        private readonly string $content,
        private readonly int $cursorPosition,
    ) {}

    public function getContent(): string { return $this->content; }
    public function getCursorPosition(): int { return $this->cursorPosition; }
}

// Originator: creates and restores from mementos
class Editor
{
    private string $content = '';
    private int $cursorPosition = 0;

    public function type(string $text): void
    {
        $this->content = substr($this->content, 0, $this->cursorPosition) . $text . substr($this->content, $this->cursorPosition);
        $this->cursorPosition += strlen($text);
    }

    public function save(): EditorMemento
    {
        return new EditorMemento($this->content, $this->cursorPosition);
    }

    public function restore(EditorMemento $memento): void
    {
        $this->content = $memento->getContent();
        $this->cursorPosition = $memento->getCursorPosition();
    }

    public function getContent(): string { return $this->content; }
}

// Caretaker: manages memento history
class History
{
    private array $snapshots = [];

    public function push(EditorMemento $memento): void { $this->snapshots[] = $memento; }

    public function pop(): ?EditorMemento
    {
        return array_pop($this->snapshots);
    }
}

// Usage
$editor = new Editor();
$history = new History();

$editor->type('Hello');
$history->push($editor->save());

$editor->type(', World');
$history->push($editor->save());

$editor->type('!!!');
echo "Current: {$editor->getContent()}\n";  // Hello, World!!!

$editor->restore($history->pop());
echo "Undo: {$editor->getContent()}\n";     // Hello, World

$editor->restore($history->pop());
echo "Undo: {$editor->getContent()}\n";     // Hello
```

---

## 3. Visitor Pattern

Visitor adds operations to a class hierarchy without modifying the classes. Each class accepts a visitor, and the visitor performs the operation. This uses "double dispatch": the element calls the visitor method corresponding to its type. Create the `ShapeVisitor` interface, a `Shape` element interface, three concrete shapes, and two visitors that add different operations without touching the shape classes:

```php
<?php
namespace App\Behavioral\Visitor;

// Visitor interface
interface ShapeVisitor
{
    public function visitCircle(Circle $circle): void;
    public function visitRectangle(Rectangle $rectangle): void;
    public function visitTriangle(Triangle $triangle): void;
}

// Element interface
interface Shape
{
    public function accept(ShapeVisitor $visitor): void;
}

// Concrete elements
class Circle implements Shape
{
    public function __construct(public readonly float $radius) {}
    public function accept(ShapeVisitor $visitor): void { $visitor->visitCircle($this); }
}

class Rectangle implements Shape
{
    public function __construct(public readonly float $width, public readonly float $height) {}
    public function accept(ShapeVisitor $visitor): void { $visitor->visitRectangle($this); }
}

class Triangle implements Shape
{
    public function __construct(public readonly float $base, public readonly float $height) {}
    public function accept(ShapeVisitor $visitor): void { $visitor->visitTriangle($this); }
}

// Concrete visitors: add operations without modifying shapes
class AreaCalculator implements ShapeVisitor
{
    private float $totalArea = 0;

    public function visitCircle(Circle $c): void { $this->totalArea += M_PI * $c->radius ** 2; }
    public function visitRectangle(Rectangle $r): void { $this->totalArea += $r->width * $r->height; }
    public function visitTriangle(Triangle $t): void { $this->totalArea += 0.5 * $t->base * $t->height; }

    public function getTotalArea(): float { return $this->totalArea; }
}

class ShapeDescriber implements ShapeVisitor
{
    public function visitCircle(Circle $c): void { echo "Circle with radius {$c->radius}\n"; }
    public function visitRectangle(Rectangle $r): void { echo "Rectangle {$r->width}x{$r->height}\n"; }
    public function visitTriangle(Triangle $t): void { echo "Triangle base {$t->base}, height {$t->height}\n"; }
}

// Usage
$shapes = [new Circle(5), new Rectangle(4, 6), new Triangle(3, 8)];

$areaCalc = new AreaCalculator();
$describer = new ShapeDescriber();

foreach ($shapes as $shape) {
    $shape->accept($areaCalc);
    $shape->accept($describer);
}

echo "Total area: " . round($areaCalc->getTotalArea(), 2) . "\n";
```

Adding a new operation (e.g., `PerimeterCalculator`) requires one new Visitor class. No changes to Shape classes. But adding a new Shape requires updating all Visitors.

---

## 4. Interpreter Pattern

Interpreter defines a grammar for a simple language and provides an interpreter to evaluate sentences in that language. It is used in template engines, math expression parsers, and query languages. Build a composable expression tree using `NumberExpression`, `VariableExpression`, `AddExpression`, and `MultiplyExpression` that evaluates arbitrary arithmetic expressions from a context map:

```php
<?php
namespace App\Behavioral\Interpreter;

interface Expression
{
    public function interpret(array $context): float;
}

class NumberExpression implements Expression
{
    public function __construct(private float $number) {}
    public function interpret(array $context): float { return $this->number; }
}

class VariableExpression implements Expression
{
    public function __construct(private string $name) {}
    public function interpret(array $context): float
    {
        return $context[$this->name] ?? throw new \RuntimeException("Undefined: {$this->name}");
    }
}

class AddExpression implements Expression
{
    public function __construct(private Expression $left, private Expression $right) {}
    public function interpret(array $context): float
    {
        return $this->left->interpret($context) + $this->right->interpret($context);
    }
}

class MultiplyExpression implements Expression
{
    public function __construct(private Expression $left, private Expression $right) {}
    public function interpret(array $context): float
    {
        return $this->left->interpret($context) * $this->right->interpret($context);
    }
}

// Build expression: (price * quantity) + tax
$expr = new AddExpression(
    new MultiplyExpression(new VariableExpression('price'), new VariableExpression('quantity')),
    new VariableExpression('tax'),
);

$result = $expr->interpret(['price' => 50000, 'quantity' => 3, 'tax' => 15000]);
echo "Result: {$result}\n";  // 165000
```

---

## 5. Fix the Errors in Your Code

These are the three most common Memento, Visitor, and Interpreter mistakes in PHP codebases.

**Error 1: Memento class exposes internal state publicly.**

A Memento must protect the originator's internal state from outside access. If the snapshot's properties are public, any code can read or modify the saved state, violating encapsulation and making the snapshot unreliable.

```php
// Wrong: public property allows anyone to read or modify the snapshot
class BadMemento
{
    public string $content;
}
$m = $editor->save();
$m->content = 'Tampered!'; // snapshot is now corrupted

// Correct: use readonly properties so state is set once and never changed
class EditorMemento
{
    public function __construct(
        private readonly string $content,
        private readonly int $cursorPosition,
    ) {}

    public function getContent(): string { return $this->content; }
    public function getCursorPosition(): int { return $this->cursorPosition; }
}
```

Declare all Memento properties as `private readonly`. Provide only getter methods. This ensures the snapshot is immutable once captured and only the originator can meaningfully interpret it.

**Error 2: Visitor implemented as an `if/instanceof` chain instead of using double dispatch.**

Checking `instanceof` inside the visitor brings us back to type-checking conditionals, which is exactly what the pattern is meant to replace. It also defeats the type safety that double dispatch provides.

```php
// Wrong: isinstance check means adding a new shape requires editing this method
class BadVisitor
{
    public function visit(Shape $shape): void
    {
        if ($shape instanceof Circle) {
            // handle circle
        } elseif ($shape instanceof Rectangle) {
            // handle rectangle
        }
    }
}

// Correct: use accept() + specific visit methods (double dispatch)
class AreaCalculator implements ShapeVisitor
{
    public function visitCircle(Circle $c): void { ... }
    public function visitRectangle(Rectangle $r): void { ... }
}
// Each shape calls $visitor->visitCircle($this) or $visitor->visitRectangle($this)
```

Implement `accept(ShapeVisitor $visitor): void` on every element class. Inside `accept()`, call the specific visitor method (`$visitor->visitCircle($this)`). This is double dispatch and the heart of the Visitor pattern.

**Error 3: Interpreter without terminal expressions, causing infinite recursion.**

Composite expressions (Add, Multiply) delegate to child expressions. If no terminal expressions (Number, Variable) exist as the base case, a composed expression tree has no stopping point and will recurse forever.

```php
// Wrong: only composite expressions exist — no base case
class AddExpression implements Expression
{
    public function __construct(private Expression $left, private Expression $right) {}
    public function interpret(array $context): float
    {
        return $this->left->interpret($context) + $this->right->interpret($context);
    }
}
// Without NumberExpression or VariableExpression, this recurses infinitely

// Correct: always include terminal expressions as the recursion base case
class NumberExpression implements Expression
{
    public function __construct(private float $number) {}
    public function interpret(array $context): float { return $this->number; }
}
```

Every Interpreter tree must have terminal expressions (Number, Variable, Literal) that return a value without recursing. Composite expressions (Add, Multiply) recursively call `interpret()` on their children, which eventually resolve to a terminal expression.

---

## 6. Exercises

**Exercise 1:** Add redo functionality to the Memento editor: a second stack stores undone states that can be redone.

**Exercise 2:** Add a `JsonExportVisitor` to the shape system that outputs each shape as a JSON object with type and dimensions.

**Exercise 3:** Add `SubtractExpression` and `DivideExpression` to the Interpreter. Build and evaluate `(a - b) / c`.

---

## 7. Solutions

**Solution for Exercise 1:**

```php
class EditorWithRedo
{
    private array $undoStack = [];
    private array $redoStack = [];
    public function save(Editor $editor): void { $this->undoStack[] = $editor->save(); $this->redoStack = []; }
    public function undo(Editor $editor): void
    {
        if ($snapshot = array_pop($this->undoStack)) { $this->redoStack[] = $editor->save(); $editor->restore($snapshot); }
    }
    public function redo(Editor $editor): void
    {
        if ($snapshot = array_pop($this->redoStack)) { $this->undoStack[] = $editor->save(); $editor->restore($snapshot); }
    }
}
```

---

## 8. Next Up - Lesson 17

Memento saves and restores object state for undo/redo without violating encapsulation — use `readonly` properties to keep snapshots immutable. Visitor adds operations to class hierarchies without modifying them: ideal for adding new operations, but costly when adding new element types because all Visitors must be updated. Interpreter evaluates sentences in a simple grammar through composable expression trees. Always include terminal expressions as the recursion base case.

This concludes all 23 GoF Behavioral Patterns. In Lesson 17, you will see how these design patterns appear in PHP frameworks like Laravel and Symfony — the patterns you have learned are exactly what powers their most important features.