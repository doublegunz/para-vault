## 1. Before You Begin

File systems have files and folders. Folders contain files and other folders. Menus have menu items and submenus. Organization charts have employees and departments. In all these cases, you need to treat individual objects and groups of objects the same way. The **Composite** pattern lets you compose objects into tree structures and treat individual objects and compositions uniformly. Composite defines a common interface for both leaf nodes (individual objects) and composite nodes (containers of objects), enabling recursive tree structures where you can call the same methods on a single item or an entire tree.

### What You'll Build

You will create a file system (files and directories) and a menu system (items and submenus) using the Composite pattern.

### What You'll Learn

- ✅ Composite: tree structure with uniform interface
- ✅ Component interface, Leaf, and Composite classes
- ✅ Recursive operations on the tree
- ✅ Adding and removing children
- ✅ Real-world use: file systems, menus, UI components, pricing

### What You'll Need

- Lesson 9 completed

---

## 2. File System Example

A directory can contain files and other directories. Both files and directories share a common interface, so you can ask any node for its size, name, or to display itself.

```php
<?php
namespace App\Structural\Composite;

// Component interface
interface FileSystemNode
{
    public function getName(): string;
    public function getSize(): int;
    public function display(int $indent = 0): void;
}

// Leaf: individual file
class File implements FileSystemNode
{
    public function __construct(
        private readonly string $name,
        private readonly int $size,
    ) {}

    public function getName(): string { return $this->name; }
    public function getSize(): int { return $this->size; }

    public function display(int $indent = 0): void
    {
        echo str_repeat('  ', $indent) . "📄 {$this->name} ({$this->size} KB)\n";
    }
}

// Composite: directory (contains files and other directories)
class Directory implements FileSystemNode
{
    private array $children = [];

    public function __construct(private readonly string $name) {}

    public function add(FileSystemNode $node): void { $this->children[] = $node; }

    public function remove(FileSystemNode $node): void
    {
        $this->children = array_filter($this->children, fn($c) => $c !== $node);
    }

    public function getName(): string { return $this->name; }

    // Recursive: sum of all children's sizes
    public function getSize(): int
    {
        return array_sum(array_map(fn($c) => $c->getSize(), $this->children));
    }

    public function display(int $indent = 0): void
    {
        echo str_repeat('  ', $indent) . "📁 {$this->name}/ ({$this->getSize()} KB)\n";
        foreach ($this->children as $child) {
            $child->display($indent + 1);
        }
    }
}

// Build the tree
$root = new Directory('project');

$src = new Directory('src');
$src->add(new File('App.php', 15));
$src->add(new File('Router.php', 8));

$models = new Directory('Models');
$models->add(new File('User.php', 5));
$models->add(new File('Post.php', 4));
$src->add($models);

$root->add($src);
$root->add(new File('composer.json', 2));
$root->add(new File('README.md', 3));

// Display the entire tree
$root->display();
echo "Total size: {$root->getSize()} KB\n";
```

Output:

```
📁 project/ (37 KB)
  📁 src/ (32 KB)
    📄 App.php (15 KB)
    📄 Router.php (8 KB)
    📁 Models/ (9 KB)
      📄 User.php (5 KB)
      📄 Post.php (4 KB)
  📄 composer.json (2 KB)
  📄 README.md (3 KB)
Total size: 37 KB
```

The beauty: `$root->getSize()` works the same whether `$root` is a File or a Directory. The recursive structure handles any depth.

---

## 3. Menu System Example

The same Composite principle applies to navigation menus. A `MenuItem` represents a single link (leaf), and a `SubMenu` contains multiple items (composite). Both implement the same `MenuComponent` interface so the rendering code never needs to distinguish between them:

```php
<?php
namespace App\Structural\Composite;

interface MenuComponent
{
    public function render(int $depth = 0): string;
}

class MenuItem implements MenuComponent
{
    public function __construct(private string $label, private string $url) {}
    public function render(int $depth = 0): string
    {
        $indent = str_repeat('  ', $depth);
        return "{$indent}<a href=\"{$this->url}\">{$this->label}</a>\n";
    }
}

class SubMenu implements MenuComponent
{
    private array $items = [];
    public function __construct(private string $label) {}
    public function add(MenuComponent $item): void { $this->items[] = $item; }
    public function render(int $depth = 0): string
    {
        $indent = str_repeat('  ', $depth);
        $output = "{$indent}<li>{$this->label}\n{$indent}  <ul>\n";
        foreach ($this->items as $item) {
            $output .= $item->render($depth + 2);
        }
        $output .= "{$indent}  </ul>\n{$indent}</li>\n";
        return $output;
    }
}
```

---

## 4. Fix the Errors in Your Code

These are the three most common Composite pattern mistakes in PHP codebases.

**Error 1: Leaf node implementing add/remove methods.**

Leaf nodes represent individual objects that cannot have children. Adding `add()` or `remove()` methods to a leaf violates its contract and creates confusing, unused code that callers might accidentally call.

```php
// Wrong: File is a leaf — it cannot contain children
class File implements FileSystemNode
{
    public function add(FileSystemNode $node): void
    {
        // Files cannot have children, so this does nothing or throws an error
    }
}

// Correct: add/remove belong only on the Composite class
class Directory implements FileSystemNode
{
    private array $children = [];
    public function add(FileSystemNode $node): void { $this->children[] = $node; }
    public function remove(FileSystemNode $node): void { ... }
}
// File has no add() or remove() method
```

Only the Composite class (Directory) should implement `add()` and `remove()`. Leaf classes implement only the shared component interface methods.

**Error 2: Recursive method that returns early instead of accumulating.**

A common mistake when implementing recursive operations is returning from the first child found instead of accumulating results from all children. This produces incorrect totals and silently ignores the rest of the tree.

```php
// Wrong: returns after the first child — only the first child's size is counted
public function getSize(): int
{
    foreach ($this->children as $child) {
        return $child->getSize();
    }
}

// Correct: accumulate results from all children using array_sum and array_map
public function getSize(): int
{
    return array_sum(array_map(fn($c) => $c->getSize(), $this->children));
}
```

Always accumulate recursive results. Use `array_sum()` with `array_map()` for numeric totals, or build a result array and merge it across children.

**Error 3: Circular reference causes infinite recursion.**

If a Composite node contains itself (directly or indirectly), calling any recursive method on it will cause a stack overflow. PHP has no automatic cycle detection in custom tree structures.

```php
// Wrong: directory contains itself — getSize() and display() loop forever
$dir = new Directory('a');
$dir->add($dir);
$dir->getSize(); // infinite recursion!

// Correct: validate that the node being added is not already an ancestor
public function add(FileSystemNode $node): void
{
    if ($node === $this) {
        throw new \InvalidArgumentException('A directory cannot contain itself.');
    }
    $this->children[] = $node;
}
```

Add a self-reference check in `add()`. For deeper cycle detection, traverse the candidate node's ancestry and verify the current node does not already appear in it.

---

## 5. Exercises

**Exercise 1:** Add a `find(string $name): ?FileSystemNode` method to Directory that searches recursively for a file or directory by name.

**Exercise 2:** Create a Composite for an organization chart: `Employee` (leaf) and `Department` (composite). Each has a `getTotalSalary()` method.

**Exercise 3:** Create a Composite for a pricing system: `Product` (leaf with price) and `Bundle` (composite with discount). `getPrice()` calculates the total with bundle discounts.

---

## 6. Solutions

**Solution for Exercise 1:**

```php
public function find(string $name): ?FileSystemNode
{
    if ($this->name === $name) return $this;
    foreach ($this->children as $child) {
        if ($child->getName() === $name) return $child;
        if ($child instanceof Directory) {
            $found = $child->find($name);
            if ($found) return $found;
        }
    }
    return null;
}
```

---

## 7. Next Up - Lesson 11

Composite organizes objects into tree structures with a uniform interface. Leaf nodes handle individual objects. Composite nodes contain children and delegate recursive operations to them. The same method call traverses the entire tree regardless of depth. Use Composite for hierarchical data: file systems, menus, organization charts, UI component trees, and pricing structures.

This concludes the Structural Patterns module. In Lesson 11, you will begin Behavioral Patterns with the Strategy pattern: a way to encapsulate interchangeable algorithms behind a common interface and swap them at runtime.