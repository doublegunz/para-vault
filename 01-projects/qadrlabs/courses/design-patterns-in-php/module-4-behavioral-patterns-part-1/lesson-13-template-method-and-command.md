## 1. Before You Begin

Some algorithms have a fixed structure but variable steps. An ETL process always follows Extract-Transform-Load, but each step differs per data source. The **Template Method** defines the algorithm skeleton in a base class and lets subclasses override specific steps. Meanwhile, the **Command** pattern encapsulates an action as an object, enabling undo/redo, queuing, and logging. Template Method uses inheritance to vary algorithm steps; Command uses composition to encapsulate actions as first-class objects.

### What You'll Build

You will create a data import system (Template Method) and a text editor with undo/redo (Command).

### What You'll Learn

- ✅ Template Method: algorithm skeleton with customizable steps
- ✅ Hook methods (optional overrides)
- ✅ Command: encapsulate actions as objects
- ✅ Command queue, undo, and history
- ✅ Template Method in Laravel: Artisan commands, form requests

### What You'll Need

- Lesson 12 completed

---

## 2. Template Method

The base class defines the algorithm's structure. Subclasses override specific steps without changing the overall flow. Create an abstract `DataImporter` with a `final import()` template method, and two concrete importers (`CsvImporter` and `JsonImporter`) that override only the variable steps:

```php
<?php
namespace App\Behavioral\TemplateMethod;

abstract class DataImporter
{
    // Template method: fixed algorithm structure
    final public function import(string $source): void
    {
        $raw = $this->extract($source);
        $data = $this->transform($raw);
        $this->validate($data);
        $this->load($data);
        $this->notify();  // Hook: optional override
    }

    abstract protected function extract(string $source): array;
    abstract protected function transform(array $raw): array;
    abstract protected function load(array $data): void;

    protected function validate(array $data): void
    {
        if (empty($data)) throw new \RuntimeException('No data to import.');
        echo "  Validated: " . count($data) . " records\n";
    }

    // Hook method: subclasses CAN override but don't have to
    protected function notify(): void
    {
        echo "  Import complete.\n";
    }
}

class CsvImporter extends DataImporter
{
    protected function extract(string $source): array
    {
        echo "  Extracting CSV from: {$source}\n";
        return [['name' => 'Budi', 'age' => 25], ['name' => 'Citra', 'age' => 22]];
    }
    protected function transform(array $raw): array
    {
        echo "  Transforming CSV data\n";
        return array_map(fn($r) => [...$r, 'source' => 'csv'], $raw);
    }
    protected function load(array $data): void
    {
        echo "  Loading " . count($data) . " records into database\n";
    }
}

class JsonImporter extends DataImporter
{
    protected function extract(string $source): array
    {
        echo "  Extracting JSON from: {$source}\n";
        return [['name' => 'Dewi', 'age' => 28]];
    }
    protected function transform(array $raw): array
    {
        echo "  Transforming JSON data\n";
        return array_map(fn($r) => [...$r, 'source' => 'json'], $raw);
    }
    protected function load(array $data): void
    {
        echo "  Loading " . count($data) . " records into database\n";
    }
    protected function notify(): void
    {
        echo "  JSON import complete. Webhook triggered.\n";  // Custom notification
    }
}

$csv = new CsvImporter();
$csv->import('users.csv');

$json = new JsonImporter();
$json->import('https://api.example.com/users');
```

The `import()` method is `final`: subclasses cannot change the algorithm structure, only the individual steps.

---

## 3. Command Pattern

Command encapsulates an action as an object. This enables queuing actions, storing history, and implementing undo.

```php
<?php
namespace App\Behavioral\Command;

// Command interface
interface Command
{
    public function execute(): void;
    public function undo(): void;
}

// Receiver: the actual object being modified
class TextEditor
{
    private string $content = '';

    public function insertText(string $text, int $position): void
    {
        $this->content = substr($this->content, 0, $position) . $text . substr($this->content, $position);
    }

    public function deleteText(int $position, int $length): void
    {
        $this->content = substr($this->content, 0, $position) . substr($this->content, $position + $length);
    }

    public function getContent(): string { return $this->content; }
}

// Concrete commands
class InsertCommand implements Command
{
    public function __construct(
        private TextEditor $editor,
        private string $text,
        private int $position,
    ) {}

    public function execute(): void { $this->editor->insertText($this->text, $this->position); }
    public function undo(): void { $this->editor->deleteText($this->position, strlen($this->text)); }
}

class DeleteCommand implements Command
{
    private string $deletedText = '';

    public function __construct(
        private TextEditor $editor,
        private int $position,
        private int $length,
    ) {}

    public function execute(): void
    {
        $this->deletedText = substr($this->editor->getContent(), $this->position, $this->length);
        $this->editor->deleteText($this->position, $this->length);
    }

    public function undo(): void { $this->editor->insertText($this->deletedText, $this->position); }
}

// Invoker: manages command history
class CommandHistory
{
    private array $history = [];

    public function execute(Command $command): void
    {
        $command->execute();
        $this->history[] = $command;
    }

    public function undo(): void
    {
        $command = array_pop($this->history);
        $command?->undo();
    }
}

// Usage
$editor = new TextEditor();
$history = new CommandHistory();

$history->execute(new InsertCommand($editor, 'Hello', 0));
echo "After insert: '{$editor->getContent()}'\n";  // Hello

$history->execute(new InsertCommand($editor, ', World!', 5));
echo "After insert: '{$editor->getContent()}'\n";  // Hello, World!

$history->undo();
echo "After undo: '{$editor->getContent()}'\n";    // Hello

$history->undo();
echo "After undo: '{$editor->getContent()}'\n";    // (empty)
```

---

## 4. Fix the Errors in Your Code

These are the three most common Template Method and Command mistakes in PHP codebases.

**Error 1: Template method is not declared `final`.**

If the template method is not `final`, subclasses can override the entire algorithm structure instead of just the variable steps. This defeats the pattern's purpose of enforcing a fixed execution flow.

```php
// Wrong: subclass can override the entire import() method and break the structure
public function import(string $source): void
{
    $raw = $this->extract($source);
    $data = $this->transform($raw);
    $this->load($data);
}

// Correct: final prevents subclasses from overriding the algorithm structure
final public function import(string $source): void
{
    $raw = $this->extract($source);
    $data = $this->transform($raw);
    $this->validate($data);
    $this->load($data);
    $this->notify();
}
```

Always mark the template method as `final`. Abstract the variable steps as `abstract protected` methods that subclasses must override individually.

**Error 2: Command without saving state for undo.**

If a Command does not capture the state it is about to change before executing, it cannot reverse its effect in `undo()`. The deleted text no longer exists after deletion, so it must be saved before the operation runs.

```php
// Wrong: execute() deletes text without saving it, so undo() has nothing to restore
class DeleteCommand implements Command
{
    public function execute(): void
    {
        $this->editor->deleteText($this->position, $this->length);
    }

    public function undo(): void
    {
        // Cannot undo! The deleted text was not captured.
    }
}

// Correct: capture the text in execute() before deleting it
class DeleteCommand implements Command
{
    private string $deletedText = '';

    public function execute(): void
    {
        $this->deletedText = substr($this->editor->getContent(), $this->position, $this->length);
        $this->editor->deleteText($this->position, $this->length);
    }

    public function undo(): void
    {
        $this->editor->insertText($this->deletedText, $this->position);
    }
}
```

Always capture the pre-operation state inside `execute()` before making changes. Store it in a private property so `undo()` can use it to reverse the effect.

**Error 3: Hook method declared as `abstract` (forces subclass override).**

Hook methods are optional override points. If they are declared `abstract`, every subclass is forced to implement them, which removes the optional nature of the hook and defeats its purpose.

```php
// Wrong: abstract hook forces every subclass to implement notify()
abstract protected function notify(): void;

// Correct: hook has a default implementation, override is optional
protected function notify(): void
{
    echo "Import complete.\n";
}
```

Declare hook methods as `protected` (not abstract) with a default implementation. Subclasses that need custom behavior can override them; subclasses that do not need to do anything different can simply inherit the default.

---

## 5. Exercises

**Exercise 1:** Create a Template Method for report generation: `AbstractReportGenerator` with steps `fetchData()`, `formatData()`, `generateOutput()`. Implement `PdfReport` and `CsvReport`.

**Exercise 2:** Create a Command for a shopping cart: `AddToCartCommand`, `RemoveFromCartCommand`. Implement undo for both.

**Exercise 3:** Create a macro Command that executes multiple commands in sequence. Undo reverses all commands in reverse order.

---

## 6. Solutions

**Solution for Exercise 3:**

```php
class MacroCommand implements Command
{
    private array $commands = [];
    public function add(Command $cmd): void { $this->commands[] = $cmd; }
    public function execute(): void { foreach ($this->commands as $cmd) $cmd->execute(); }
    public function undo(): void { foreach (array_reverse($this->commands) as $cmd) $cmd->undo(); }
}
```

---

## 7. Next Up - Lesson 14

Template Method defines an algorithm skeleton in a base class with customizable steps. Use `final` on the template method to lock the structure. Abstract methods force subclass implementation; hook methods with default implementations are optional. Command encapsulates actions as objects, enabling undo, redo, and queuing. Both patterns replace complex conditional branching with polymorphism and clear class responsibilities.

In Lesson 14, you will learn Chain of Responsibility and State: Chain of Responsibility passes requests along a handler pipeline, and State encapsulates behavior that changes based on an object's internal state.