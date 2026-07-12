## 1. Before You Begin

In Java or PHP, a class explicitly declares `implements InterfaceName`. In Go, interfaces are satisfied implicitly: if a type has all the methods an interface requires, it automatically satisfies the interface. No `implements` keyword is needed anywhere. This implicit satisfaction is one of Go's most powerful design choices because it means you can write an interface after the types that satisfy it, and existing types can satisfy new interfaces without modification.

In Lesson 9, you learned how to define structs and attach methods to them using receivers. Interfaces build directly on that knowledge: an interface specifies what methods a type must have, and any type that has those methods automatically satisfies the interface.

### What You'll Build

You will create a `Shape` interface implemented by `Rectangle`, `Circle`, and `Triangle`, then build a payment system where different payment types share a common interface and can be processed polymorphically.

### What You'll Learn

- ✅ Defining interfaces with method signatures
- ✅ Implicit interface satisfaction (no `implements`)
- ✅ Polymorphism: treating different types uniformly
- ✅ The empty interface `interface{}` and `any`
- ✅ Type assertions and type switches
- ✅ Common standard library interfaces: `Stringer`, `error`

### What You'll Need

- Lesson 9 completed

---

## 2. Setup

Create a new folder `lesson-10` inside `learn-go`. Open the terminal and initialize the module:

```bash
cd lesson-10
go mod init learn-go/lesson-10
```

This creates the `go.mod` file for this lesson. You will create multiple standalone programs in this folder so that each section stays focused and readable. Each file has its own `func main()`, so run and check it separately with commands such as `go run stringer.go` and `go vet stringer.go`. Do not run `go test ./...` from this lesson folder because Go would try to compile the multiple `main` functions together.

---

## 3. Defining and Implementing Interfaces

An interface in Go is a named set of method signatures. Any type that implements all those methods automatically satisfies the interface, without any explicit declaration. This is called structural typing or "duck typing" with compile-time verification.

### Step 1: Create `main.go`

Create the file `main.go` in the `lesson-10` folder. This file defines the `Shape` interface and three concrete types that satisfy it.

### Step 2: Write the Code

Write the following program to see how three different types satisfy the same interface:

```go
package main

import (
    "fmt"
    "math"
)

type Shape interface {
    Area() float64
    Perimeter() float64
}

type Rectangle struct {
    Width, Height float64
}

func (r Rectangle) Area() float64      { return r.Width * r.Height }
func (r Rectangle) Perimeter() float64 { return 2 * (r.Width + r.Height) }

type Circle struct {
    Radius float64
}

func (c Circle) Area() float64      { return math.Pi * c.Radius * c.Radius }
func (c Circle) Perimeter() float64 { return 2 * math.Pi * c.Radius }

type Triangle struct {
    A, B, C float64
    Base, H float64
}

func (t Triangle) Area() float64      { return 0.5 * t.Base * t.H }
func (t Triangle) Perimeter() float64 { return t.A + t.B + t.C }

func PrintShapeInfo(name string, s Shape) {
    fmt.Printf("%-12s Area: %8.2f   Perimeter: %8.2f\n", name, s.Area(), s.Perimeter())
}

func main() {
    rect := Rectangle{Width: 10, Height: 5}
    circle := Circle{Radius: 7}
    tri := Triangle{A: 3, B: 4, C: 5, Base: 4, H: 3}

    fmt.Println("=== Shapes ===")
    PrintShapeInfo("Rectangle", rect)
    PrintShapeInfo("Circle", circle)
    PrintShapeInfo("Triangle", tri)

    fmt.Println("\n=== All Shapes ===")
    shapes := []Shape{rect, circle, tri}
    var totalArea float64
    for _, s := range shapes {
        totalArea += s.Area()
    }
    fmt.Printf("Total area of %d shapes: %.2f\n", len(shapes), totalArea)
}
```

`type Shape interface { Area() float64; Perimeter() float64 }` defines the interface. It declares that any type satisfying `Shape` must have both an `Area()` method and a `Perimeter()` method, both returning `float64`.

`Rectangle`, `Circle`, and `Triangle` each define `Area()` and `Perimeter()` methods with exactly those signatures. Go automatically recognizes that all three types satisfy `Shape`. No special declaration is needed in the type definitions.

`func PrintShapeInfo(name string, s Shape)` accepts any value that satisfies `Shape`. It does not know or care whether the value is a `Rectangle`, `Circle`, or `Triangle`. This is polymorphism: one function works correctly with multiple concrete types.

`shapes := []Shape{rect, circle, tri}` creates a slice that holds values of different concrete types, all stored under the `Shape` interface. The `for range` loop calls `s.Area()` on each element, and Go dispatches to the correct implementation at runtime.

### Step 3: Save and Run

```bash
go run main.go
```

Verify that each shape displays the correct area and perimeter, and that the total area is the sum of all three.

### How It Works

`Rectangle`, `Circle`, and `Triangle` each have `Area()` and `Perimeter()` methods with the correct signatures. They satisfy the `Shape` interface automatically. `PrintShapeInfo` accepts any `Shape`, so it works with all three types without modification.

---

## 4. The Stringer Interface

Go's `fmt` package recognizes a special interface called `fmt.Stringer`. Any type that has a `String() string` method satisfies `Stringer`, and `fmt.Println` and `%v` will call that method automatically when printing the value.

### Step 1: Create `stringer.go`

Create the file `stringer.go` inside `lesson-10`. This file demonstrates how implementing a standard library interface changes the behavior of existing functions.

### Step 2: Write the Code

Write the following program to see how `fmt.Stringer` works:

```go
package main

import "fmt"

type Product struct {
    Name  string
    Price float64
}

func (p Product) String() string {
    return fmt.Sprintf("%s (Rp %.0f)", p.Name, p.Price)
}

type Student struct {
    Name  string
    Grade float64
}

func (s Student) String() string {
    status := "Fail"
    if s.Grade >= 70 {
        status = "Pass"
    }
    return fmt.Sprintf("%s: %.1f (%s)", s.Name, s.Grade, status)
}

func main() {
    p := Product{Name: "Laptop", Price: 8500000}
    s := Student{Name: "Budi", Grade: 85}

    fmt.Println(p)
    fmt.Println(s)

    fmt.Printf("Product: %v\n", p)
    fmt.Printf("Student: %v\n", s)
}
```

`func (p Product) String() string` implements the `fmt.Stringer` interface. The `fmt` package checks whether the value being printed satisfies this interface. If it does, `fmt.Println` and `%v` call `String()` instead of using the default struct representation `{Laptop 8.5e+06}`.

`Product` returns a formatted string combining the product name and price. `Student` computes the pass/fail status and includes it in the output. Both types now print exactly the way you want them to, simply by implementing one interface method.

The `error` type you have been using since Lesson 8 works the same way: it is an interface with one method `Error() string`, and `fmt` calls it automatically when printing an error value.

### Step 3: Save and Run

```bash
go run stringer.go
```

Confirm that `fmt.Println(p)` does not print `{Laptop 8.5e+06}` but instead prints `Laptop (Rp 8500000)`.

---

## 5. Type Assertions and Type Switches

When you have an interface value, you sometimes need to know the underlying concrete type and access its specific fields or methods. Type assertions and type switches are Go's tools for this.

### Step 1: Create `typeswitch.go`

Create the file `typeswitch.go` inside `lesson-10`. This file demonstrates how to safely extract concrete types from interface values.

### Step 2: Write the Code

Write the following program to see both type assertions and type switches in action:

```go
package main

import "fmt"

type Shape interface {
    Area() float64
}

type Rect struct{ W, H float64 }

func (r Rect) Area() float64 { return r.W * r.H }

type Circ struct{ R float64 }

func (c Circ) Area() float64 { return 3.14159 * c.R * c.R }

func Describe(s Shape) {
    switch v := s.(type) {
    case Rect:
        fmt.Printf("Rectangle: %.0f x %.0f, Area: %.2f\n", v.W, v.H, v.Area())
    case Circ:
        fmt.Printf("Circle: radius %.0f, Area: %.2f\n", v.R, v.Area())
    default:
        fmt.Printf("Unknown shape, Area: %.2f\n", v.Area())
    }
}

func main() {
    shapes := []Shape{
        Rect{10, 5},
        Circ{7},
        Rect{3, 3},
    }

    for _, s := range shapes {
        Describe(s)
    }

    var s Shape = Rect{8, 4}
    r, ok := s.(Rect)
    if ok {
        fmt.Printf("\nExtracted Rect: %.0f x %.0f\n", r.W, r.H)
    }
}
```

`switch v := s.(type)` is a type switch. It checks the underlying concrete type of the interface value `s` and assigns the unwrapped value to `v`. Inside each `case`, `v` has the specific concrete type, so `v.W` and `v.H` are accessible in the `Rect` case.

`r, ok := s.(Rect)` is a type assertion. It attempts to extract the underlying `Rect` from the `Shape` interface value. If the underlying type is indeed `Rect`, it assigns the value to `r` and sets `ok` to `true`. If the underlying type is something else, `ok` is `false` and `r` is the zero value. Always use the two-value form (`r, ok := s.(Rect)`) to avoid panics.

### Step 3: Save and Run

```bash
go run typeswitch.go
```

Verify that each shape in the slice is described correctly using its specific fields, even though they are all stored as the `Shape` interface type.

---

## 6. The Empty Interface and `any`

The empty interface has no methods, so every type in Go satisfies it. It is useful when you need to accept values of any type. Since Go 1.18, `any` is an alias for `interface{}`.

```go
package main

import "fmt"

func PrintAnything(val any) {
    fmt.Printf("Type: %T, Value: %v\n", val, val)
}

func main() {
    PrintAnything(42)
    PrintAnything("hello")
    PrintAnything(true)
    PrintAnything([]int{1, 2, 3})
}
```

`func PrintAnything(val any)` accepts a value of any type. Inside the function, `%T` prints the concrete type name and `%v` prints the value. Because you have lost the specific type information, you would need a type assertion or type switch to access type-specific fields or methods.

Use `any` sparingly. When you accept `any`, the compiler cannot help you catch type mismatches. Prefer specific interface types whenever possible so the compiler can verify that values satisfy the required contract.

---

## 7. Fix the Errors in Your Code

These three errors are the most common mistakes when working with Go interfaces.

**Error 1: Missing method in interface implementation.**

A type must implement all methods of an interface. Implementing only some methods means the type does not satisfy the interface, which is a compile error.

```go
// Wrong: Square has Area() but not Perimeter(), so it does not satisfy Shape
type Shape interface {
    Area() float64
    Perimeter() float64
}
type Square struct{ Side float64 }
func (s Square) Area() float64 { return s.Side * s.Side }

// Correct: implement all required methods
type Square struct{ Side float64 }
func (s Square) Area() float64      { return s.Side * s.Side }
func (s Square) Perimeter() float64 { return 4 * s.Side }
```

The compile error is `Square does not implement Shape (missing Perimeter method)`. Go lists exactly which method is missing. Add all missing methods to resolve the error.

**Error 2: Type assertion without the comma-ok form.**

A single-value type assertion panics at runtime if the underlying type does not match. Always use the two-value form to check safely.

```go
// Wrong: panics if s does not hold a Rectangle
var s Shape = Circle{Radius: 5}
r := s.(Rectangle)

// Correct: check ok before using r
var s Shape = Circle{Radius: 5}
r, ok := s.(Rectangle)
if ok {
    fmt.Println("Width:", r.Width)
}
```

The runtime panic message is `interface conversion: interface is Circle, not Rectangle`. The two-value form never panics: it sets `ok` to `false` and `r` to the zero value when the assertion fails.

**Error 3: Pointer receiver breaks interface satisfaction.**

When a method is defined on a pointer receiver (`*Car`), only `*Car` satisfies the interface. The value type `Car` does not, because Go cannot take the address of a value in all cases.

```go
// Wrong: Move() is on *Car, not Car; an unaddressable Car cannot satisfy Mover
type Mover interface{ Move() }
type Car struct{}
func (c *Car) Move() {}
var m Mover = Car{}

// Correct: use a pointer to satisfy the interface
type Mover interface{ Move() }
type Car struct{}
func (c *Car) Move() {}
var m Mover = &Car{}
```

The compile error is `Car does not implement Mover (Move method has pointer receiver)`. The fix is always to use `&Car{}` when storing a value whose methods have pointer receivers into an interface variable.

---

## 8. Exercises

**Exercise 1:** Create a `PaymentMethod` interface with one method: `Pay(amount float64) string`. Implement it with three structs: `CreditCard` (with a card number field), `BankTransfer` (with a bank name field), and `EWallet` (with a wallet name field). Each `Pay` method returns a different confirmation message. Process a slice of payments polymorphically from `main`.

**Exercise 2:** Create a `Sortable` interface with three methods: `Len() int`, `Less(i, j int) bool`, and `Swap(i, j int)`. Implement it on a custom type `IntSlice` (defined as `type IntSlice []int`). Write a `BubbleSort(s Sortable)` function and test it from `main`.

**Exercise 3:** Create a `Logger` interface with one method: `Log(message string)`. Implement `ConsoleLogger` (prints to stdout) and `FileLogger` (appends entries to a `[]string` field). Write a function `ProcessOrder(logger Logger, item string)` that calls `logger.Log` for three steps. Test with both logger types.

---

## 9. Solutions

**Solution for Exercise 1:**

```go
package main

import "fmt"

type PaymentMethod interface {
    Pay(amount float64) string
}

type CreditCard struct{ Number string }

func (c CreditCard) Pay(amount float64) string {
    last4 := c.Number[len(c.Number)-4:]
    return fmt.Sprintf("Paid Rp %.0f via Credit Card ending %s", amount, last4)
}

type BankTransfer struct{ Bank string }

func (b BankTransfer) Pay(amount float64) string {
    return fmt.Sprintf("Paid Rp %.0f via %s transfer", amount, b.Bank)
}

type EWallet struct{ Name string }

func (e EWallet) Pay(amount float64) string {
    return fmt.Sprintf("Paid Rp %.0f via %s", amount, e.Name)
}

func main() {
    methods := []PaymentMethod{
        CreditCard{"4111111111111234"},
        BankTransfer{"BCA"},
        EWallet{"GoPay"},
    }
    for _, m := range methods {
        fmt.Println(m.Pay(150000))
    }
}
```

All three types satisfy `PaymentMethod` because each has a `Pay(amount float64) string` method. The slice `[]PaymentMethod{...}` stores values of three different concrete types under the same interface type. The `for range` loop calls `m.Pay(150000)` on each, and Go dispatches to the correct implementation. `c.Number[len(c.Number)-4:]` extracts the last 4 characters of the card number for display without exposing the full number.

**Solution for Exercise 2:**

```go
package main

import "fmt"

type Sortable interface {
    Len() int
    Less(i, j int) bool
    Swap(i, j int)
}

type IntSlice []int

func (s IntSlice) Len() int           { return len(s) }
func (s IntSlice) Less(i, j int) bool { return s[i] < s[j] }
func (s IntSlice) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }

func BubbleSort(s Sortable) {
    for i := 0; i < s.Len()-1; i++ {
        for j := 0; j < s.Len()-1-i; j++ {
            if !s.Less(j, j+1) {
                s.Swap(j, j+1)
            }
        }
    }
}

func main() {
    nums := IntSlice{42, 17, 8, 33, 25}
    fmt.Println("Before:", nums)
    BubbleSort(nums)
    fmt.Println("After: ", nums)
}
```

`type IntSlice []int` creates a new named type based on `[]int`. Because it is a named type, you can define methods on it. The three methods `Len`, `Less`, and `Swap` satisfy the `Sortable` interface. `BubbleSort` only knows about `Sortable`, so it works with any type that implements those three methods. This is the same pattern used by the standard library's `sort.Interface`.

**Solution for Exercise 3:**

```go
package main

import "fmt"

type Logger interface {
    Log(msg string)
}

type ConsoleLogger struct{}

func (c ConsoleLogger) Log(msg string) {
    fmt.Println("[LOG]", msg)
}

type FileLogger struct {
    Entries []string
}

func (f *FileLogger) Log(msg string) {
    f.Entries = append(f.Entries, msg)
}

func ProcessOrder(l Logger, item string) {
    l.Log("Order received: " + item)
    l.Log("Processing payment")
    l.Log("Order complete: " + item)
}

func main() {
    cl := ConsoleLogger{}
    ProcessOrder(cl, "Laptop")

    fl := &FileLogger{}
    ProcessOrder(fl, "Mouse")
    fmt.Println("\nFile log entries:", fl.Entries)
}
```

`ConsoleLogger` uses a value receiver for `Log` because it does not modify any fields. `FileLogger` uses a pointer receiver for `Log` because it appends to `f.Entries`, which modifies the struct. Because `FileLogger` uses a pointer receiver, you must pass `&FileLogger{}` (a pointer) when assigning to the `Logger` interface. `ProcessOrder` only depends on the `Logger` interface, so it works with both loggers without knowing their concrete types.

---

## Next Up - Lesson 11

Go interfaces are satisfied implicitly: any type that has the required methods automatically satisfies the interface, with no declaration needed. This enables polymorphism: one function can accept values of any type that satisfies the interface. The `fmt.Stringer` interface customizes how types are printed. Type assertions (`val, ok := s.(ConcreteType)`) safely extract the underlying concrete type. Type switches check multiple types at once. The empty interface `any` accepts every type. Prefer small, focused interfaces with one or two methods.

In Lesson 11, you will learn about packages and modules: how Go organizes code across multiple files, how to create your own packages, and how to manage dependencies.
