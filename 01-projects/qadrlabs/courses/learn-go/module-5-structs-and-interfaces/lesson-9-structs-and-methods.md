## 1. Before You Begin

Go does not have classes. Instead, it uses structs to group related data and methods to attach behavior to that data. A struct is a named collection of fields, each with its own type. Methods are functions declared with a receiver: a parameter that specifies which type the method belongs to. The result is a clean separation between data definition and behavior, without the complexity of class hierarchies.

In Lesson 8, you learned Go's error handling pattern. That pattern becomes essential in this lesson too: methods that can fail will return errors using the same `(result, error)` pattern you already know. Understanding structs thoroughly is also crucial preparation for Lesson 10, where interfaces define what a type can do.

### What You'll Build

You will create a `Product` struct with methods for displaying, computing total price, applying discounts, and restocking. You will also build a `Library` struct that manages a slice of `Book` structs.

### What You'll Learn

- ✅ Defining structs with fields
- ✅ Creating and initializing structs
- ✅ Accessing and modifying fields
- ✅ Methods with value receivers vs pointer receivers
- ✅ Struct embedding (Go's version of composition)
- ✅ Constructor functions (Go convention)

### What You'll Need

- Lesson 8 completed

---

## 2. Setup

Create a new folder `lesson-09` inside `learn-go`. Open the terminal and initialize the module:

```bash
cd lesson-09
go mod init learn-go/lesson-09
```

This creates the `go.mod` file for this lesson. You will create multiple standalone programs in the same folder. Each file declares its own `func main()`, so run and check each demonstration separately with commands such as `go run methods.go` and `go vet methods.go`. Do not run `go test ./...` from this lesson folder because Go would try to compile the multiple `main` functions together.

---

## 3. Defining Structs

A struct is declared with the `type` keyword, a name, and the keyword `struct` followed by a block of field definitions. Each field has a name and a type. Fields with uppercase names are exported (accessible from other packages); fields with lowercase names are unexported (private to the package).

### Step 1: Create `main.go`

Create the file `main.go` in `lesson-09`. This file defines the `Contact` struct and demonstrates all three ways to create a struct value.

### Step 2: Write the Code

Write the following program to see struct creation and field access in action:

```go
package main

import "fmt"

type Contact struct {
    Name  string
    Email string
    Age   int
    Phone string
}

func main() {
    person1 := Contact{
        Name:  "Budi Santoso",
        Email: "budi@example.com",
        Age:   25,
        Phone: "081234567890",
    }

    person2 := Contact{"Citra Dewi", "citra@example.com", 22, "089876543210"}

    var person3 Contact
    person3.Name = "Andi Pratama"
    person3.Email = "andi@example.com"
    person3.Age = 30

    fmt.Println("=== Contacts ===")
    fmt.Printf("Name: %s, Email: %s, Age: %d\n", person1.Name, person1.Email, person1.Age)
    fmt.Printf("Name: %s, Email: %s, Age: %d\n", person2.Name, person2.Email, person2.Age)
    fmt.Printf("Name: %s, Email: %s, Age: %d\n", person3.Name, person3.Email, person3.Age)

    person1.Age = 26
    fmt.Printf("\nBudi's new age: %d\n", person1.Age)

    var empty Contact
    fmt.Printf("\nEmpty struct: Name='%s', Age=%d, Email='%s'\n", empty.Name, empty.Age, empty.Email)
}
```

The first form `Contact{Name: "Budi Santoso", ...}` uses field names explicitly. This is the recommended style because it is clear, order-independent, and safe when new fields are added to the struct later. The second form `Contact{"Citra Dewi", ...}` is positional: values are assigned to fields in the order they are declared. Avoid this style outside of simple test data because it breaks silently if the struct field order changes. The third form declares a zero-valued `Contact` with `var person3 Contact`, then assigns fields individually using dot notation.

`person1.Age = 26` modifies the `Age` field directly using dot notation. The empty struct shows Go's zero value guarantee: every field is initialized to its type's zero value. `string` fields are `""`, `int` fields are `0`, `bool` fields are `false`, and pointer fields are `nil`.

### Step 3: Save and Run

```bash
go run main.go
```

Verify that all three contacts display correctly and that the empty struct shows zero values for each field.

### Key Points

Go structs use uppercase field names to make them exported (accessible from other packages). Lowercase field names are unexported and private to the package where the struct is defined. This is Go's visibility system: no `public`, `private`, or `protected` keywords.

---

## 4. Methods

A method is a function with a receiver. The receiver appears in parentheses between `func` and the method name. It specifies which type the method operates on. Go has two kinds of receivers: value receivers and pointer receivers.

### Step 1: Create `methods.go`

Create a new file `methods.go` inside `lesson-09`. This file is a standalone demonstration with its own `func main()`. Run it by naming the file explicitly so Go does not combine it with the other demonstrations in this folder.

### Step 2: Write the Code

Write the following program to see both value and pointer receivers in action:

```go
package main

import "fmt"

type Product struct {
    Name     string
    Price    float64
    Quantity int
}

func (p Product) Display() {
    fmt.Printf("%-15s Rp %10.0f  x%d\n", p.Name, p.Price, p.Quantity)
}

func (p Product) TotalPrice() float64 {
    return p.Price * float64(p.Quantity)
}

func (p *Product) ApplyDiscount(percent float64) {
    p.Price = p.Price * (1 - percent/100)
}

func (p *Product) Restock(amount int) {
    p.Quantity += amount
}

func NewProduct(name string, price float64, qty int) Product {
    return Product{
        Name:     name,
        Price:    price,
        Quantity: qty,
    }
}

func main() {
    laptop := NewProduct("Laptop", 8500000, 10)
    mouse := NewProduct("Mouse", 150000, 50)
    keyboard := NewProduct("Keyboard", 750000, 30)

    fmt.Println("=== Product List ===")
    laptop.Display()
    mouse.Display()
    keyboard.Display()

    fmt.Printf("\nLaptop total: Rp %.0f\n", laptop.TotalPrice())

    fmt.Println("\n=== After 10% Discount on Laptop ===")
    laptop.ApplyDiscount(10)
    laptop.Display()
    fmt.Printf("New total: Rp %.0f\n", laptop.TotalPrice())

    mouse.Restock(20)
    fmt.Printf("\nMouse after restock: %d units\n", mouse.Quantity)
}
```

`func (p Product) Display()` uses a value receiver. Go passes a copy of the `Product` value to this method. Any changes made to `p` inside `Display` do not affect the original variable. Value receivers are appropriate for read-only methods like `Display` and `TotalPrice`.

`func (p *Product) ApplyDiscount(percent float64)` uses a pointer receiver. Go passes a pointer to the original `Product` value, not a copy. Changes to `p.Price` inside `ApplyDiscount` modify the original calling variable. Pointer receivers are required for any method that modifies the struct's fields.

`NewProduct(name string, price float64, qty int) Product` is a constructor function. Go has no built-in constructors, but by convention, constructor functions are named `NewTypeName` and return an initialized value of the type. Using a constructor centralizes initialization logic and allows you to add validation later without changing the call sites.

### Step 3: Save and Run

```bash
go run methods.go
```

Call `laptop.Display()` before and after `ApplyDiscount` to confirm the price changed. Then call `mouse.Restock(20)` and verify the quantity increased.

### Value Receiver vs Pointer Receiver

**Value receiver** `(p Product)` receives a copy. Changes inside the method do not affect the original. Use for read-only operations like `Display()` and `TotalPrice()`.

**Pointer receiver** `(p *Product)` receives a pointer to the original. Changes modify the original. Use when the method needs to update fields like `ApplyDiscount()` and `Restock()`.

The rule of thumb in Go: if any method on a type uses a pointer receiver, all methods on that type should use pointer receivers for consistency.

---

## 5. Struct Embedding (Composition)

Go uses composition instead of inheritance. When you embed one struct inside another, the embedded struct's fields and methods are promoted to the outer struct. This means you can access them directly without going through the embedded field name.

### Step 1: Create `embedding.go`

Create a new file `embedding.go` inside `lesson-09`. This file demonstrates how embedding creates "is-a" relationships through composition rather than inheritance.

### Step 2: Write the Code

Write the following program to see struct embedding and promoted methods:

```go
package main

import "fmt"

type Address struct {
    Street string
    City   string
    State  string
}

func (a Address) FullAddress() string {
    return a.Street + ", " + a.City + ", " + a.State
}

type Employee struct {
    Name    string
    Title   string
    Salary  float64
    Address
}

func (e Employee) Display() {
    fmt.Printf("Name   : %s\n", e.Name)
    fmt.Printf("Title  : %s\n", e.Title)
    fmt.Printf("Salary : Rp %.0f\n", e.Salary)
    fmt.Printf("Address: %s\n", e.FullAddress())
}

func main() {
    emp := Employee{
        Name:   "Budi Santoso",
        Title:  "Software Engineer",
        Salary: 15000000,
        Address: Address{
            Street: "Jl. Merdeka No. 10",
            City:   "Bandung",
            State:  "Jawa Barat",
        },
    }

    emp.Display()

    fmt.Printf("\nCity: %s\n", emp.City)
    fmt.Printf("Full: %s\n", emp.FullAddress())
}
```

`type Employee struct { ... Address }` embeds the `Address` struct without a field name. This is different from `Address Address` (which would create a named field). With embedding, all of `Address`'s fields and methods are promoted to `Employee`. You can access them directly as `emp.City` instead of `emp.Address.City`, and `emp.FullAddress()` instead of `emp.Address.FullAddress()`.

This is Go's answer to inheritance: rather than saying "Employee extends Address", Go says "Employee has an Address embedded inside it". The behavior is similar for consumers of the type (field and method access looks the same), but the model is simpler: there is no implicit type hierarchy, no overriding, and no super-method calls.

### Step 3: Save and Run

```bash
go run embedding.go
```

Verify that `emp.City` and `emp.FullAddress()` both work without explicitly referencing `emp.Address`.

---

## 6. Slice of Structs

Slices of structs are Go's standard way to manage collections of entities. Combining the `for range` loop from Lesson 5 with struct methods creates clean, readable programs that model real-world data.

### Step 1: Create `collection.go`

Create a new file `collection.go` inside `lesson-09`. This file defines a `Student` struct with a method and demonstrates how to iterate over, aggregate, and analyze a slice of structs.

### Step 2: Write the Code

Write the following program to analyze a collection of students:

```go
package main

import (
    "fmt"
    "strings"
)

type Student struct {
    Name  string
    Grade float64
}

func NewStudent(name string, grade float64) Student {
    return Student{Name: name, Grade: grade}
}

func (s Student) Status() string {
    if s.Grade >= 70 {
        return "Pass"
    }
    return "Fail"
}

func main() {
    students := []Student{
        NewStudent("Andi", 85),
        NewStudent("Budi", 67),
        NewStudent("Citra", 92),
        NewStudent("Dewi", 55),
        NewStudent("Eka", 78),
    }

    fmt.Printf("%-10s %6s %8s\n", "Name", "Grade", "Status")
    fmt.Println(strings.Repeat("-", 26))
    for _, s := range students {
        fmt.Printf("%-10s %6.1f %8s\n", s.Name, s.Grade, s.Status())
    }

    var total float64
    for _, s := range students {
        total += s.Grade
    }
    avg := total / float64(len(students))
    fmt.Printf("\nAverage: %.1f\n", avg)

    pass, fail := 0, 0
    for _, s := range students {
        if s.Grade >= 70 {
            pass++
        } else {
            fail++
        }
    }
    fmt.Printf("Pass: %d, Fail: %d\n", pass, fail)
}
```

`[]Student{NewStudent("Andi", 85), ...}` creates a slice of `Student` values using the constructor function. The `for _, s := range students` loop gives you each `Student` value by copy. Inside the loop, `s.Status()` calls the method on the copy, which is fine for `Status()` because it only reads the struct.

`strings.Repeat("-", 26)` generates a separator line without manually counting dashes. The format string `"%-10s %6.1f %8s\n"` aligns the name (left, 10 wide), the grade (right, 6 wide, 1 decimal), and the status (right, 8 wide) into consistent columns.

### Step 3: Save and Run

```bash
go run collection.go
```

Verify the table is properly aligned and that the pass/fail counts are correct (3 pass, 2 fail).

---

## 7. Fix the Errors in Your Code

These three errors are the most common struct and method mistakes in Go.

**Error 1: Modifying a struct through a value receiver.**

A value receiver receives a copy of the struct. Any changes you make inside the method affect the copy, not the original. The caller's variable is unchanged.

```go
// Wrong: modifies a copy, the original Product.Price is unchanged
func (p Product) SetPrice(price float64) {
    p.Price = price
}

// Correct: pointer receiver modifies the original
func (p *Product) SetPrice(price float64) {
    p.Price = price
}
```

This error is particularly frustrating because the code compiles and runs without error. The bug is that the price appears to be set but the original struct is unchanged. The fix is always to change the receiver from `(p Product)` to `(p *Product)` when the method needs to modify the struct.

**Error 2: Missing trailing comma in multi-line struct literals.**

Go requires a trailing comma after the last field in a multi-line struct literal. This is a deliberate grammar rule that prevents common formatting mistakes.

```go
// Wrong: missing trailing comma after the last field
p := Product{
    Name:  "Laptop",
    Price: 8500000
}

// Correct: trailing comma after every field, including the last
p := Product{
    Name:  "Laptop",
    Price: 8500000,
}
```

The compile error is `syntax error: unexpected newline in composite literal; possibly missing comma or }`. The fix is always to add a comma after every field value in a multi-line literal. If you use single-line format `Product{Name: "Laptop", Price: 8500000}`, the trailing comma is not required.

**Error 3: Accessing unexported fields from another package.**

Lowercase field and type names are unexported and cannot be accessed from outside the package where they are defined. This is Go's visibility system.

```go
// Wrong: lowercase type and field names are unexported
type product struct {
    name  string
    price float64
}

// Correct: uppercase names are exported and accessible from other packages
type Product struct {
    Name  string
    Price float64
}
```

If another package imports your package and tries to access `p.name`, the compile error is `p.name undefined (cannot refer to unexported field or method name)`. Use uppercase names for any type or field that is part of a package's public API. Use lowercase only for internal implementation details.

---

## 8. Exercises

**Exercise 1:** Create a `Rectangle` struct with `Width` and `Height` fields (both `float64`). Add three methods: `Area() float64`, `Perimeter() float64`, and `IsSquare() bool`. Create a slice of three rectangles and display all properties for each.

**Exercise 2:** Create a `BankAccount` struct with `Owner` (string) and `Balance` (float64) fields. Add methods: `Deposit(amount float64)`, `Withdraw(amount float64) error` (return an error if the balance is insufficient), and `Display()`. Use pointer receivers for `Deposit` and `Withdraw`. Test with valid and invalid withdrawals.

**Exercise 3:** Create `Book` and `Library` structs. `Library` contains a `Books` field which is a slice of `Book`. Add three methods to `Library`: `AddBook(book Book)`, `FindByTitle(title string) (Book, bool)`, and `ListAll()`. Test all three from `main`.

---

## 9. Solutions

**Solution for Exercise 1:**

```go
package main

import "fmt"

type Rectangle struct {
    Width, Height float64
}

func (r Rectangle) Area() float64 {
    return r.Width * r.Height
}

func (r Rectangle) Perimeter() float64 {
    return 2 * (r.Width + r.Height)
}

func (r Rectangle) IsSquare() bool {
    return r.Width == r.Height
}

func main() {
    rects := []Rectangle{
        {Width: 10, Height: 5},
        {Width: 7, Height: 7},
        {Width: 3, Height: 8},
    }
    for _, r := range rects {
        fmt.Printf("%.0fx%.0f: Area=%.0f, Perimeter=%.0f, Square=%t\n",
            r.Width, r.Height, r.Area(), r.Perimeter(), r.IsSquare())
    }
}
```

All three methods use value receivers because they only read `Width` and `Height` without modifying them. `IsSquare` compares the two fields with `==`. For `float64` fields this works correctly because the values are assigned directly from literals. The slice uses the field-name form `{Width: 10, Height: 5}` which is safer than the positional form if the struct gains new fields in the future.

**Solution for Exercise 2:**

```go
package main

import (
    "errors"
    "fmt"
)

type BankAccount struct {
    Owner   string
    Balance float64
}

func (a *BankAccount) Deposit(amount float64) {
    a.Balance += amount
}

func (a *BankAccount) Withdraw(amount float64) error {
    if amount > a.Balance {
        return errors.New("insufficient funds")
    }
    a.Balance -= amount
    return nil
}

func (a BankAccount) Display() {
    fmt.Printf("%s: Rp %.0f\n", a.Owner, a.Balance)
}

func main() {
    acc := BankAccount{Owner: "Budi", Balance: 1000000}
    acc.Display()

    acc.Deposit(500000)
    acc.Display()

    if err := acc.Withdraw(2000000); err != nil {
        fmt.Println("Error:", err)
    }

    acc.Withdraw(300000)
    acc.Display()
}
```

`Deposit` and `Withdraw` use pointer receivers because they modify `a.Balance`. `Display` uses a value receiver because it only reads fields. The `if err := acc.Withdraw(2000000); err != nil` form uses the `if` initialization statement from Lesson 4 to scope `err` to the block where it is needed. The second `acc.Withdraw(300000)` call discards the error because the balance is 1,500,000 after the deposit and the withdrawal is valid.

**Solution for Exercise 3:**

```go
package main

import (
    "fmt"
    "strings"
)

type Book struct {
    Title  string
    Author string
}

type Library struct {
    Books []Book
}

func (l *Library) AddBook(b Book) {
    l.Books = append(l.Books, b)
}

func (l Library) FindByTitle(title string) (Book, bool) {
    for _, b := range l.Books {
        if strings.EqualFold(b.Title, title) {
            return b, true
        }
    }
    return Book{}, false
}

func (l Library) ListAll() {
    for i, b := range l.Books {
        fmt.Printf("%d. %s by %s\n", i+1, b.Title, b.Author)
    }
}

func main() {
    lib := Library{}
    lib.AddBook(Book{Title: "Go Programming", Author: "Budi"})
    lib.AddBook(Book{Title: "Clean Code", Author: "Robert C. Martin"})
    lib.AddBook(Book{Title: "The Go Programming Language", Author: "Donovan & Kernighan"})

    lib.ListAll()

    if b, ok := lib.FindByTitle("clean code"); ok {
        fmt.Printf("\nFound: %s by %s\n", b.Title, b.Author)
    }

    if _, ok := lib.FindByTitle("nonexistent"); !ok {
        fmt.Println("Not found: nonexistent")
    }
}
```

`AddBook` uses a pointer receiver because it appends to `l.Books`, modifying the `Library` struct. `FindByTitle` and `ListAll` use value receivers because they only read data. `strings.EqualFold` makes the title search case-insensitive: searching for `"clean code"` finds `"Clean Code"`. `FindByTitle` returns `(Book, bool)` following the comma-ok idiom: the caller checks `ok` before using the returned `Book`.

---

## Next Up - Lesson 10

Structs group related data fields. Methods attach behavior to structs using receivers. Value receivers work on copies and are appropriate for read-only operations. Pointer receivers modify the original struct and are required for any method that changes fields. Constructor functions follow the `NewTypeName` convention. Struct embedding promotes the embedded type's fields and methods to the outer struct, enabling composition without inheritance. Slices of structs combined with `for range` are Go's standard pattern for managing collections.

In Lesson 10, you will learn about interfaces: how Go defines behavioral contracts that multiple types can satisfy implicitly, without declaring that they implement anything.
