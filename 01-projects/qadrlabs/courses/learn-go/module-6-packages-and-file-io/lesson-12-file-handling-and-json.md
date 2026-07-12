## 1. Before You Begin

Programs need to persist data beyond a single run. Go's `os` package provides all the file operations you need: creating, reading, writing, and appending. The `encoding/json` package handles serialization: converting Go structs into JSON text and back. These two skills combined give you persistent storage for CLI tools, configuration files, and data processing pipelines.

In Lesson 11, you organized code into packages. This lesson introduces two packages from Go's standard library that you will use together in the final project in Lesson 14: `os` for disk access and `encoding/json` for the JSON data format.

### What You'll Build

You will create a program that reads and writes text files line by line, and a contacts manager that stores structured data in a JSON file with load and save functions.

### What You'll Learn

- ✅ Writing files with `os.WriteFile()` and `os.Create()`
- ✅ Reading files with `os.ReadFile()` and `bufio.Scanner`
- ✅ Checking if a file exists
- ✅ JSON encoding with `json.Marshal()` and `json.MarshalIndent()`
- ✅ JSON decoding with `json.Unmarshal()`
- ✅ Struct tags for JSON field names
- ✅ Reading and writing JSON files

### What You'll Need

- Lesson 11 completed

---

## 2. Setup

Create a new folder `lesson-12` inside `learn-go`. Open the terminal and initialize the module:

```bash
mkdir lesson-12 && cd lesson-12
go mod init lesson-12
```

This creates the `go.mod` file for this lesson. You will create multiple `.go` files in this lesson, each demonstrating a different aspect of file and JSON handling.

---

## 3. Writing and Reading Text Files

Go's `os` package provides simple, direct functions for file I/O. The most commonly used are `os.WriteFile` for writing, `os.ReadFile` for reading an entire file at once, and `os.Open` combined with `bufio.Scanner` for reading large files line by line.

### Step 1: Create `files.go`

Create the file `files.go` inside `lesson-12`. This file will demonstrate all the fundamental file operations you need for real programs.

### Step 2: Write the Code

Write the following program to see file creation, reading, and appending in action:

```go
package main

import (
    "bufio"
    "fmt"
    "os"
    "strings"
)

func main() {
    content := "Hello, Go!\nThis is line 2.\nThis is line 3.\n"
    err := os.WriteFile("output.txt", []byte(content), 0644)
    if err != nil {
        fmt.Println("Error writing file:", err)
        return
    }
    fmt.Println("File written: output.txt")

    data, err := os.ReadFile("output.txt")
    if err != nil {
        fmt.Println("Error reading file:", err)
        return
    }
    fmt.Println("\n=== File Content ===")
    fmt.Println(string(data))

    file, err := os.Open("output.txt")
    if err != nil {
        fmt.Println("Error opening file:", err)
        return
    }
    defer file.Close()

    fmt.Println("=== Line by Line ===")
    scanner := bufio.NewScanner(file)
    lineNum := 1
    for scanner.Scan() {
        line := scanner.Text()
        fmt.Printf("Line %d: %s\n", lineNum, line)
        lineNum++
    }

    f, err := os.OpenFile("output.txt", os.O_APPEND|os.O_WRONLY, 0644)
    if err != nil {
        fmt.Println("Error:", err)
        return
    }
    defer f.Close()
    f.WriteString("This line was appended.\n")
    fmt.Println("\nLine appended to output.txt")

    if _, err := os.Stat("output.txt"); err == nil {
        fmt.Println("output.txt exists")
    } else {
        fmt.Println("output.txt does not exist")
    }

    data2, _ := os.ReadFile("output.txt")
    words := strings.Fields(string(data2))
    fmt.Printf("Word count: %d\n", len(words))
}
```

`os.WriteFile("output.txt", []byte(content), 0644)` creates or overwrites the file with the provided data. The first argument is the file path. The second is the content as a byte slice: `[]byte(content)` converts a string to `[]byte`. The third argument `0644` is the Unix file permission in octal notation: owner can read and write, everyone else can only read. If the file already exists, it is completely overwritten.

`os.ReadFile("output.txt")` reads the entire file into memory as a `[]byte`. Converting it back to a string with `string(data)` gives you the text content. This function is convenient for small files. For large files (hundreds of megabytes), use line-by-line reading instead to avoid loading everything into memory at once.

`defer file.Close()` schedules the file to close when the enclosing function returns. Always add `defer file.Close()` immediately after a successful `os.Open()` call. Without it, the file handle remains open until the program exits, which wastes resources and can cause problems when limits on open file handles are reached.

`bufio.NewScanner(file)` creates a scanner that reads line by line. `scanner.Scan()` reads the next line and returns `true` if successful. `scanner.Text()` returns the current line as a string without the newline character.

`os.OpenFile("output.txt", os.O_APPEND|os.O_WRONLY, 0644)` opens the file for appending. The flags `os.O_APPEND|os.O_WRONLY` tell the OS to seek to the end of the file before each write and to open for writing only. Without `os.O_APPEND`, writing would overwrite from the beginning.

`os.Stat("output.txt")` returns file metadata. If the error is `nil`, the file exists. If the error matches `os.IsNotExist(err)`, the file does not exist.

### Step 3: Save and Run

```bash
go run files.go
```

Verify that `output.txt` is created, read, and appended. Open `output.txt` in VS Code to confirm the appended line was added correctly.

### Key Points

`os.WriteFile` and `os.ReadFile` are the simplest file operations - use them for small files. `defer file.Close()` must appear immediately after every successful `os.Open()` to prevent resource leaks. `bufio.Scanner` is efficient for large files because it reads only one line into memory at a time.

---

## 4. JSON Encoding and Decoding

JSON is the universal data format for configuration files, APIs, and data storage. Go's `encoding/json` package provides two directions: encoding converts Go values to JSON bytes, and decoding converts JSON bytes back to Go values. Struct tags control how field names appear in the JSON output.

### Step 1: Create `json_demo.go`

Create the file `json_demo.go` inside `lesson-12`. This file demonstrates struct tags, encoding, decoding, and working with slices of structs.

### Step 2: Write the Code

Write the following program to see JSON encoding and decoding in action:

```go
package main

import (
    "encoding/json"
    "fmt"
)

type Contact struct {
    Name  string `json:"name"`
    Email string `json:"email"`
    Age   int    `json:"age"`
    Phone string `json:"phone,omitempty"`
}

func main() {
    contact := Contact{
        Name:  "Budi Santoso",
        Email: "budi@example.com",
        Age:   25,
        Phone: "081234567890",
    }

    jsonBytes, err := json.Marshal(contact)
    if err != nil {
        fmt.Println("Error:", err)
        return
    }
    fmt.Println("=== Compact JSON ===")
    fmt.Println(string(jsonBytes))

    prettyJSON, _ := json.MarshalIndent(contact, "", "  ")
    fmt.Println("\n=== Pretty JSON ===")
    fmt.Println(string(prettyJSON))

    jsonString := `{"name":"Citra Dewi","email":"citra@example.com","age":22}`
    var decoded Contact
    err = json.Unmarshal([]byte(jsonString), &decoded)
    if err != nil {
        fmt.Println("Error:", err)
        return
    }
    fmt.Println("\n=== Decoded ===")
    fmt.Printf("Name: %s, Email: %s, Age: %d\n", decoded.Name, decoded.Email, decoded.Age)

    contacts := []Contact{
        {Name: "Andi", Email: "andi@example.com", Age: 30},
        {Name: "Budi", Email: "budi@example.com", Age: 25, Phone: "081234"},
        {Name: "Citra", Email: "citra@example.com", Age: 22},
    }

    sliceJSON, _ := json.MarshalIndent(contacts, "", "  ")
    fmt.Println("\n=== Contact List (JSON) ===")
    fmt.Println(string(sliceJSON))

    var decodedList []Contact
    json.Unmarshal(sliceJSON, &decodedList)
    fmt.Printf("\nDecoded %d contacts\n", len(decodedList))
}
```

The backtick annotations after each field in `type Contact struct` are struct tags. `json:"name"` tells the `encoding/json` package to use `"name"` as the key in JSON output instead of the Go field name `Name`. Without tags, JSON keys would use the Go field names exactly: `"Name"`, `"Email"`, which is non-standard in JSON (typically lowercase keys are expected). `json:"phone,omitempty"` uses two directives: `phone` sets the key name and `omitempty` tells the encoder to skip the field entirely if its value is the zero value for its type (empty string for `string`).

`json.Marshal(contact)` converts the struct to a single-line compact JSON byte slice. This format saves space but is difficult to read. `json.MarshalIndent(contact, "", "  ")` produces pretty-printed JSON with each field on its own line, indented with two spaces. The second argument is the prefix added before each line (empty string means no prefix). Use `MarshalIndent` when writing to files that humans need to read.

`json.Unmarshal([]byte(jsonString), &decoded)` parses the JSON byte slice and populates the `decoded` struct. The second argument must be a pointer (`&decoded`) because `Unmarshal` needs to write into the variable. The backtick string `` `{"name":"Citra Dewi",...}` `` is a raw string literal in Go: backslashes and quotes inside it are literal characters, no escaping needed.

Notice that the Citra contact does not have a `Phone` field in the JSON string. `Unmarshal` leaves `decoded.Phone` as the zero value (`""`) for fields that are missing from the JSON. This is correct behavior: missing JSON fields do not cause errors, they simply use the zero value.

### Step 3: Save and Run

```bash
go run json_demo.go
```

Compare the compact and pretty JSON output. Notice that Andi and Citra do not have a `"phone"` key in the pretty output because their Phone fields are empty strings and `omitempty` is set.

### Struct Tags

Struct tags provide fine-grained control over JSON serialization:

```go
type Contact struct {
    Name  string `json:"name"`            // JSON field = "name"
    Phone string `json:"phone,omitempty"` // Skip if Phone is ""
    Age   int    `json:"-"`               // Always skip this field
}
```

`json:"-"` tells the encoder to always skip the field, regardless of its value. This is useful for sensitive fields like passwords that should never appear in JSON output.

---

## 5. Practical: JSON File Storage

Combining `os.WriteFile`, `os.ReadFile`, and `encoding/json` gives you a simple persistent storage system. This pattern is the foundation of the CLI task manager you will build in Lesson 14.

### Step 1: Create `storage.go`

Create the file `storage.go` inside `lesson-12`. This file implements a complete save and load system for a task list stored in a JSON file.

### Step 2: Write the Code

Write the following program to see the full save-and-load pattern:

```go
package main

import (
    "encoding/json"
    "fmt"
    "os"
)

type Task struct {
    ID   int    `json:"id"`
    Text string `json:"text"`
    Done bool   `json:"done"`
}

const filename = "tasks.json"

func loadTasks() ([]Task, error) {
    data, err := os.ReadFile(filename)
    if err != nil {
        if os.IsNotExist(err) {
            return []Task{}, nil
        }
        return nil, err
    }
    var tasks []Task
    err = json.Unmarshal(data, &tasks)
    return tasks, err
}

func saveTasks(tasks []Task) error {
    data, err := json.MarshalIndent(tasks, "", "  ")
    if err != nil {
        return err
    }
    return os.WriteFile(filename, data, 0644)
}

func main() {
    tasks, err := loadTasks()
    if err != nil {
        fmt.Println("Error loading:", err)
        return
    }

    if len(tasks) == 0 {
        tasks = append(tasks, Task{ID: 1, Text: "Learn Go structs", Done: true})
        tasks = append(tasks, Task{ID: 2, Text: "Learn Go interfaces", Done: true})
        tasks = append(tasks, Task{ID: 3, Text: "Build a CLI app", Done: false})

        err = saveTasks(tasks)
        if err != nil {
            fmt.Println("Error saving:", err)
            return
        }
        fmt.Println("Tasks saved to", filename)
    }

    fmt.Println("\n=== Task List ===")
    for _, t := range tasks {
        status := "[ ]"
        if t.Done {
            status = "[x]"
        }
        fmt.Printf("%s %d. %s\n", status, t.ID, t.Text)
    }
    fmt.Printf("\nTotal: %d tasks\n", len(tasks))

    for i := range tasks {
        if tasks[i].ID == 3 {
            tasks[i].Done = true
        }
    }
    saveTasks(tasks)
    fmt.Println("Task 3 marked as done and saved.")
}
```

`loadTasks` reads the JSON file and unmarshals it into a `[]Task` slice. The guard `if os.IsNotExist(err)` handles the first run: if the file does not exist yet, it returns an empty slice instead of an error. This is a common Go pattern: distinguish between "file not found" (a recoverable situation) and "I/O error" (a genuine failure).

`saveTasks` marshals the task slice to indented JSON and writes it to the file. If marshaling fails (which would only happen for unsupported types), it returns the error. `os.WriteFile` creates or overwrites the file atomically.

The update loop `for i := range tasks { if tasks[i].ID == 3 { tasks[i].Done = true } }` iterates by index, not by value. This is essential: `for _, t := range tasks` gives you a copy of each `Task`. Modifying `t.Done` modifies the copy, not the slice element. Using `tasks[i].Done = true` modifies the element in the slice directly.

### Step 3: Save and Run

```bash
go run storage.go
```

Run the program twice. The first run creates `tasks.json` and saves three tasks. The second run loads the existing tasks without creating new ones (because `len(tasks) > 0`). Open `tasks.json` in VS Code after the first run to see the formatted JSON.

---

## 6. Fix the Errors in Your Code

These three errors cause bugs that range from resource leaks to silently missing data in your JSON output.

**Error 1: Forgetting to close a file.**

Every opened file must eventually be closed. If you open a file and forget to close it, the file handle remains open for the lifetime of the program, wasting resources and potentially preventing other processes from accessing the file.

```go
// Wrong: file is opened but never closed
file, err := os.Open("data.txt")
if err != nil {
    return err
}
scanner := bufio.NewScanner(file)
for scanner.Scan() {
    fmt.Println(scanner.Text())
}

// Correct: defer Close() immediately after the successful Open
file, err := os.Open("data.txt")
if err != nil {
    return err
}
defer file.Close()
scanner := bufio.NewScanner(file)
for scanner.Scan() {
    fmt.Println(scanner.Text())
}
```

`defer file.Close()` must appear on the line immediately after handling the open error. This guarantees the close happens even if the function returns early due to a scanner error or a `return` statement inside the loop.

**Error 2: Unexported struct fields are invisible to `encoding/json`.**

`json.Marshal` and `json.Unmarshal` can only access exported (uppercase) struct fields. If a field starts with lowercase, the JSON encoder pretends it does not exist.

```go
// Wrong: name is unexported, it will be missing from JSON output
type Person struct {
    name string `json:"name"`
    Age  int    `json:"age"`
}
p := Person{name: "Budi", Age: 25}
data, _ := json.Marshal(p)
// data is {"age":25} --- "name" is missing!

// Correct: use uppercase field names
type Person struct {
    Name string `json:"name"`
    Age  int    `json:"age"`
}
```

This is one of the most common JSON bugs in Go because the code compiles and runs without errors. The only symptom is missing fields in the output. The fix is to always use uppercase field names on any struct you intend to marshal or unmarshal.

**Error 3: Passing a value instead of a pointer to `json.Unmarshal`.**

`json.Unmarshal` must modify the target variable to write the decoded data into it. This requires a pointer. Passing a non-pointer value means `Unmarshal` cannot write anywhere, and the decoding silently fails.

```go
// Wrong: p is a value, Unmarshal cannot modify it
var p Person
json.Unmarshal(data, p)
// p is still empty after this call

// Correct: pass a pointer so Unmarshal can write into p
var p Person
err := json.Unmarshal(data, &p)
if err != nil {
    fmt.Println("Error:", err)
}
```

`json.Unmarshal` accepts an `interface{}` parameter, so passing a non-pointer compiles without error. But internally, `Unmarshal` cannot write into a non-pointer value and returns an error like `json: Unmarshal(non-pointer Person)`. Always check the error from `json.Unmarshal` to catch this.

---

## 7. Exercises

**Exercise 1:** Create a program that reads a text file (use the `output.txt` created in Section 3), counts the number of lines, words, and characters, and displays the statistics in a formatted table.

**Exercise 2:** Create a `Config` struct with `AppName` (string), `Port` (int), and `Debug` (bool) fields. Write a `SaveConfig(c Config) error` function that saves to `config.json` and a `LoadConfig() (Config, error)` function that loads from it. Use struct tags for JSON keys in snake_case. Test both from `main`.

**Exercise 3:** Create a log file writer. Each time the program runs, it appends a timestamped entry like `2026-04-07 14:30:00 - Application started` to `app.log`. Use `time.Now().Format("2006-01-02 15:04:05")` to format the timestamp. Run the program three times and verify that each run adds a new line.

---

## 8. Solutions

**Solution for Exercise 1:**

```go
package main

import (
    "fmt"
    "os"
    "strings"
)

func main() {
    data, err := os.ReadFile("output.txt")
    if err != nil {
        fmt.Println("Error:", err)
        return
    }
    text := string(data)
    lines := strings.Split(strings.TrimRight(text, "\n"), "\n")
    words := strings.Fields(text)

    fmt.Printf("%-10s %d\n", "Lines:", len(lines))
    fmt.Printf("%-10s %d\n", "Words:", len(words))
    fmt.Printf("%-10s %d\n", "Chars:", len(text))
}
```

`strings.TrimRight(text, "\n")` removes the trailing newline before splitting so the last "line" is not an empty string. `strings.Split(text, "\n")` splits the content into a slice of lines. `strings.Fields(text)` splits by any whitespace and handles multiple consecutive spaces correctly, making it more robust than `strings.Split(text, " ")` for counting words.

**Solution for Exercise 2:**

```go
package main

import (
    "encoding/json"
    "fmt"
    "os"
)

type Config struct {
    AppName string `json:"app_name"`
    Port    int    `json:"port"`
    Debug   bool   `json:"debug"`
}

func SaveConfig(c Config) error {
    data, err := json.MarshalIndent(c, "", "  ")
    if err != nil {
        return fmt.Errorf("SaveConfig: %w", err)
    }
    return os.WriteFile("config.json", data, 0644)
}

func LoadConfig() (Config, error) {
    var c Config
    data, err := os.ReadFile("config.json")
    if err != nil {
        return c, fmt.Errorf("LoadConfig: %w", err)
    }
    err = json.Unmarshal(data, &c)
    if err != nil {
        return c, fmt.Errorf("LoadConfig parse: %w", err)
    }
    return c, nil
}

func main() {
    cfg := Config{AppName: "MyApp", Port: 8080, Debug: true}

    if err := SaveConfig(cfg); err != nil {
        fmt.Println("Error:", err)
        return
    }
    fmt.Println("Config saved.")

    loaded, err := LoadConfig()
    if err != nil {
        fmt.Println("Error:", err)
        return
    }
    fmt.Printf("App: %s, Port: %d, Debug: %t\n", loaded.AppName, loaded.Port, loaded.Debug)
}
```

Both functions wrap their errors with context (`"SaveConfig: ..."`) using `fmt.Errorf` and `%w`. This makes it easy to trace which function failed when the error propagates to the caller. `json.MarshalIndent` produces readable JSON with each field on its own line. `LoadConfig` returns the zero-value `Config{}` on error, which is safe because the caller checks `err` before using the returned config.

**Solution for Exercise 3:**

```go
package main

import (
    "fmt"
    "os"
    "time"
)

func main() {
    f, err := os.OpenFile("app.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
    if err != nil {
        fmt.Println("Error:", err)
        return
    }
    defer f.Close()

    entry := time.Now().Format("2006-01-02 15:04:05") + " - Application started\n"
    _, err = f.WriteString(entry)
    if err != nil {
        fmt.Println("Error writing log:", err)
        return
    }
    fmt.Print("Logged: " + entry)
}
```

`os.O_APPEND|os.O_CREATE|os.O_WRONLY` opens the file for appending, creates it if it does not exist, and opens it write-only. The three flags are combined with the bitwise OR operator `|`. Without `os.O_CREATE`, opening a non-existent file would fail. `time.Now().Format("2006-01-02 15:04:05")` uses Go's reference time format: the digits `2006`, `01`, `02`, `15`, `04`, `05` are not arbitrary but represent the specific reference time January 2, 2006, 15:04:05 used by the Go time package.

---

## Next Up - Lesson 13

`os.WriteFile` and `os.ReadFile` handle simple file operations. `bufio.Scanner` reads files line by line for memory-efficient processing of large files. Always close files with `defer file.Close()` immediately after a successful open. `json.Marshal` converts structs to compact JSON; `json.MarshalIndent` produces human-readable indented JSON. `json.Unmarshal` converts JSON back to structs, requiring a pointer as the destination. Struct tags (`json:"name"`) control field names; `omitempty` skips zero-value fields.

In Lesson 13, you will learn about goroutines and channels: Go's built-in concurrency model that lets you run multiple tasks simultaneously and communicate between them safely.