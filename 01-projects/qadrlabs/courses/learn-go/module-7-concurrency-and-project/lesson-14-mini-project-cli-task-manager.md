## 1. Before You Begin

This is where everything comes together. You will build a complete command-line task manager that uses every major concept from this course: variables, functions, structs, methods, interfaces, slices, error handling, file I/O, and JSON. The program persists tasks to a JSON file so they survive between runs. When you finish, you will have a working, real-world Go application that demonstrates all 13 lessons in a single cohesive program.

Building projects is how concepts become skills. Reading about structs and interfaces is one thing. Using them to build a real command dispatcher, a persistent storage layer, and a formatted display system is what makes them second nature.

### What You'll Build

A CLI application called `taskman` with the following features:

- Add a new task with a description and timestamp
- List all tasks with status indicators and statistics
- Mark a task as done by its ID
- Delete a task by its ID
- Save and load all tasks from a JSON file automatically

### What You'll Learn

- ✅ How to combine all Go concepts in one project
- ✅ How to structure a CLI application
- ✅ How to process command-line arguments with `os.Args`
- ✅ How to build a complete CRUD system in Go
- ✅ The recommended learning path after this course

### What You'll Need

- All previous lessons completed (Lessons 1 through 13)

---

## 2. Setup

Create a new folder `lesson-14` inside `learn-go`. Open the terminal and initialize the module:

```bash
mkdir lesson-14 && cd lesson-14
go mod init taskman
```

This initializes a module named `taskman`, which will also be the name of the compiled binary. The entire project is a single `main.go` file to keep the structure simple and focused on the Go concepts rather than project organization.

---

## 3. Build the Task Manager

The task manager is organized into four logical sections within a single file: data types, storage functions, command functions, and the main dispatcher. This structure mirrors how a larger Go project would be organized across packages.

### Step 1: Create `main.go`

Create the file `main.go` inside `lesson-14`. This is the complete source of the task manager.

### Step 2: Write the Code

Write the following program. Read through it carefully before building: each section connects directly to a lesson from the course.

```go
package main

import (
    "encoding/json"
    "fmt"
    "os"
    "strconv"
    "strings"
    "time"
)

type Task struct {
    ID        int    `json:"id"`
    Text      string `json:"text"`
    Done      bool   `json:"done"`
    CreatedAt string `json:"created_at"`
}

func (t Task) StatusIcon() string {
    if t.Done {
        return "[x]"
    }
    return "[ ]"
}

func (t Task) String() string {
    return fmt.Sprintf("%s %d. %s", t.StatusIcon(), t.ID, t.Text)
}

const dataFile = "tasks.json"

func loadTasks() ([]Task, error) {
    data, err := os.ReadFile(dataFile)
    if err != nil {
        if os.IsNotExist(err) {
            return []Task{}, nil
        }
        return nil, fmt.Errorf("failed to read %s: %w", dataFile, err)
    }
    var tasks []Task
    if err := json.Unmarshal(data, &tasks); err != nil {
        return nil, fmt.Errorf("failed to parse JSON: %w", err)
    }
    return tasks, nil
}

func saveTasks(tasks []Task) error {
    data, err := json.MarshalIndent(tasks, "", "  ")
    if err != nil {
        return fmt.Errorf("failed to encode JSON: %w", err)
    }
    return os.WriteFile(dataFile, data, 0644)
}

func nextID(tasks []Task) int {
    maxID := 0
    for _, t := range tasks {
        if t.ID > maxID {
            maxID = t.ID
        }
    }
    return maxID + 1
}

func cmdAdd(tasks []Task, text string) []Task {
    task := Task{
        ID:        nextID(tasks),
        Text:      text,
        Done:      false,
        CreatedAt: time.Now().Format("2006-01-02 15:04"),
    }
    tasks = append(tasks, task)
    fmt.Printf("Added: %s\n", task)
    return tasks
}

func cmdList(tasks []Task) {
    if len(tasks) == 0 {
        fmt.Println("No tasks. Add one with: taskman add \"your task\"")
        return
    }

    fmt.Println("=== Task List ===")
    for _, t := range tasks {
        fmt.Println(t)
    }

    done, pending := 0, 0
    for _, t := range tasks {
        if t.Done {
            done++
        } else {
            pending++
        }
    }
    fmt.Printf("\nTotal: %d | Done: %d | Pending: %d\n", len(tasks), done, pending)
}

func cmdDone(tasks []Task, idStr string) []Task {
    id, err := strconv.Atoi(idStr)
    if err != nil {
        fmt.Println("Error: invalid task ID. Use a number.")
        return tasks
    }

    found := false
    for i := range tasks {
        if tasks[i].ID == id {
            tasks[i].Done = true
            fmt.Printf("Completed: %s\n", tasks[i])
            found = true
            break
        }
    }

    if !found {
        fmt.Printf("Error: task with ID %d not found.\n", id)
    }
    return tasks
}

func cmdDelete(tasks []Task, idStr string) []Task {
    id, err := strconv.Atoi(idStr)
    if err != nil {
        fmt.Println("Error: invalid task ID. Use a number.")
        return tasks
    }

    for i, t := range tasks {
        if t.ID == id {
            fmt.Printf("Deleted: %s\n", t)
            return append(tasks[:i], tasks[i+1:]...)
        }
    }

    fmt.Printf("Error: task with ID %d not found.\n", id)
    return tasks
}

func printUsage() {
    fmt.Println("TaskMan - CLI Task Manager")
    fmt.Println()
    fmt.Println("Usage:")
    fmt.Println("  taskman add \"task description\"  Add a new task")
    fmt.Println("  taskman list                     List all tasks")
    fmt.Println("  taskman done <id>                Mark task as done")
    fmt.Println("  taskman delete <id>              Delete a task")
    fmt.Println("  taskman help                     Show this help")
}

func main() {
    if len(os.Args) < 2 {
        printUsage()
        return
    }

    tasks, err := loadTasks()
    if err != nil {
        fmt.Println("Error:", err)
        os.Exit(1)
    }

    command := strings.ToLower(os.Args[1])
    modified := false

    switch command {
    case "add":
        if len(os.Args) < 3 {
            fmt.Println("Error: please provide a task description.")
            fmt.Println("Usage: taskman add \"Buy groceries\"")
            return
        }
        text := strings.Join(os.Args[2:], " ")
        tasks = cmdAdd(tasks, text)
        modified = true

    case "list", "ls":
        cmdList(tasks)

    case "done":
        if len(os.Args) < 3 {
            fmt.Println("Error: please provide a task ID.")
            fmt.Println("Usage: taskman done 1")
            return
        }
        tasks = cmdDone(tasks, os.Args[2])
        modified = true

    case "delete", "rm":
        if len(os.Args) < 3 {
            fmt.Println("Error: please provide a task ID.")
            fmt.Println("Usage: taskman delete 1")
            return
        }
        tasks = cmdDelete(tasks, os.Args[2])
        modified = true

    case "help":
        printUsage()

    default:
        fmt.Printf("Unknown command: %s\n\n", command)
        printUsage()
    }

    if modified {
        if err := saveTasks(tasks); err != nil {
            fmt.Println("Error saving:", err)
            os.Exit(1)
        }
    }
}
```

The `Task` struct (from Lesson 9) groups all the data needed to represent a task. The struct tags `json:"id"`, `json:"text"`, `json:"done"`, and `json:"created_at"` (from Lesson 12) control how each field appears in the JSON file. `CreatedAt` uses snake_case in JSON, which is the standard convention for JSON keys.

`StatusIcon()` and `String()` are value receiver methods (from Lesson 9). `String()` satisfies the `fmt.Stringer` interface (from Lesson 10): when you write `fmt.Printf("%s", task)` or `fmt.Println(task)`, Go calls `task.String()` automatically, which calls `task.StatusIcon()` to produce `[x]` or `[ ]`.

`loadTasks()` follows the exact pattern from Lesson 12: read the file, check for file-not-found separately from other errors, then unmarshal the JSON. The `fmt.Errorf(..., %w, err)` wrapping (from Lesson 8) adds context to each error so callers know which operation failed.

`nextID(tasks)` finds the maximum existing ID by iterating over all tasks and returns one more than the maximum. This ensures new tasks always get a unique ID even after deletions.

`cmdAdd` creates a `Task` value, appends it to the slice, and returns the updated slice. The caller must capture the return value (`tasks = cmdAdd(tasks, text)`) because `append` may allocate a new backing array. The timestamp `time.Now().Format("2006-01-02 15:04")` uses Go's reference time format from Lesson 12.

`cmdDone` searches for the task by ID using an index range loop (`for i := range tasks`). This is essential: `for _, t := range tasks` gives you a copy of each task, so `t.Done = true` would modify a copy and not the slice element. `tasks[i].Done = true` modifies the element in the slice directly.

`cmdDelete` uses `append(tasks[:i], tasks[i+1:]...)` to remove element at index `i`. `tasks[:i]` is all elements before index `i`. `tasks[i+1:]...` spreads all elements after `i` as individual arguments to `append`. This is Go's standard slice deletion idiom.

`main` reads `os.Args[1]` (the command) and dispatches to the correct function using `switch`. `os.Args[0]` is the program name itself. `os.Args[2:]` is all remaining arguments. `strings.Join(os.Args[2:], " ")` joins them back with spaces so a task description like `"Buy groceries today"` (three words) is treated as one task.

The `modified` flag avoids writing to disk when no changes were made (for `list` and `help` commands), which saves unnecessary disk I/O.

### Step 3: Save the File

Press **Ctrl+S** to save. VS Code will format the code automatically on save.

### Step 4: Build and Test

Build the program to create an executable binary:

```bash
go build -o taskman
```

`go build -o taskman` compiles all Go files in the current directory and produces an executable named `taskman`. The `-o` flag specifies the output filename. This is different from `go run` which compiles and runs in one step without keeping the binary.

Now test every command to verify all features work:

```bash
./taskman help

./taskman add "Learn Go variables"
./taskman add "Learn Go functions"
./taskman add "Learn Go structs"
./taskman add "Build CLI task manager"

./taskman list

./taskman done 1
./taskman done 2

./taskman list

./taskman delete 3

./taskman list
```

After running `./taskman add`, check the `tasks.json` file in VS Code to see the stored data in formatted JSON. Run `./taskman list` multiple times and notice the task count stays consistent between runs because the data is loaded from the JSON file each time.

On Windows, use `taskman.exe` instead of `./taskman`.

---

## 4. How All Concepts Connect

Understanding how each lesson's concepts appear in the task manager makes the entire course feel cohesive. The following table shows which features use which lessons:

| Feature | Concepts Used |
|---------|---------------|
| `Task` struct | Structs (Lesson 9), struct tags (Lesson 12) |
| `StatusIcon()`, `String()` | Methods (Lesson 9), Stringer interface (Lesson 10) |
| `loadTasks()`, `saveTasks()` | File I/O (Lesson 12), JSON (Lesson 12), error handling (Lesson 8) |
| `cmdAdd()` | Slices (Lesson 5), time formatting (Lesson 12) |
| `cmdDone()`, `cmdDelete()` | Loops (Lesson 5), `strconv` (Lesson 3), error handling (Lesson 8) |
| `os.Args`, `switch` | Input (Lesson 4), control flow (Lesson 4) |
| `fmt.Errorf("%w", err)` | Error wrapping (Lesson 8) |
| Persistent storage | JSON + file I/O (Lesson 12) |

---

## 5. What You Built in This Course

Starting from an empty editor, you progressed through every foundational Go concept and applied each one in a real program. The following table maps each lesson to where it appears in the task manager:

| Lesson | Concept | Applied in Task Manager |
|--------|---------|------------------------|
| 1 | Why Go | Philosophy behind the design decisions |
| 2 | Setup | `go build`, `go run`, `go mod init` |
| 3 | Variables, types, output | Task fields, `Printf` formatting |
| 4 | Input, operators, control flow | `os.Args`, `switch`, argument validation |
| 5 | Arrays, slices, loops | `[]Task`, `range`, `append`, delete idiom |
| 6 | Maps | Available for category-based extensions |
| 7 | Functions | `cmdAdd`, `cmdList`, `cmdDone`, `nextID` |
| 8 | Error handling | `loadTasks`, `saveTasks`, `%w` wrapping |
| 9 | Structs and methods | `Task` struct, `StatusIcon`, `String` |
| 10 | Interfaces | `Stringer` interface via `String()` method |
| 11 | Packages and modules | `go mod init taskman`, module structure |
| 12 | File I/O and JSON | `tasks.json` persistence, struct tags |
| 13 | Goroutines | Available for concurrent operation extensions |
| 14 | Mini project | All concepts working together |

---

## 6. Extension Ideas

The task manager is a solid foundation. Here are concrete ways to extend it using what you have learned:

**Priority levels.** Add a `Priority` string field to the `Task` struct with values like `"low"`, `"medium"`, `"high"`. Modify `cmdAdd` to accept a `-p` flag. Sort the task list by priority before displaying.

**Due dates.** Add a `DueDate` string field. Parse the date with `time.Parse`. In `cmdList`, compare `DueDate` to `time.Now()` and mark overdue tasks with a different status icon.

**Categories.** Add a `Category` field. Add a `taskman list --category work` subcommand that filters tasks. Use a map to group tasks by category for the statistics display.

**Search.** Add `taskman search "keyword"` that filters and displays only tasks whose text contains the keyword. Use `strings.Contains` for case-sensitive search or `strings.EqualFold` for case-insensitive.

**Web interface.** Build an HTTP server with Go's `net/http` package that serves the same task manager as a JSON API. Each CLI command maps to an HTTP endpoint: `GET /tasks`, `POST /tasks`, `PUT /tasks/{id}/done`, `DELETE /tasks/{id}`.

---

## 7. Learning Roadmap After This Course

You now have a solid foundation in Go. Here is a structured path for what to learn next:

```
Go Basics --- This Course (completed)
    |
    v
Web Development with Go
    - net/http (standard library HTTP server)
    - html/template (server-side rendering)
    - REST APIs (JSON responses with encoding/json)
    - Routing libraries: chi, gorilla/mux, or Gin
    |
    v
Database Integration
    - database/sql with MySQL or PostgreSQL driver
    - GORM (Go Object-Relational Mapper)
    - Schema migrations
    |
    v
Advanced Go
    - context.Context (cancellation and timeouts)
    - Testing with the testing package (table-driven tests)
    - Generics (Go 1.18 and later)
    - Concurrency patterns: worker pools and pipelines
    |
    v
Production and Cloud
    - Docker deployment
    - CI/CD pipelines
    - Microservices architecture
    - gRPC for inter-service communication
```

Each step builds on the previous one. The `net/http` package uses the same `error` return pattern and `io.Reader` interface you already know. Testing uses the same function and struct patterns. The foundation you built in this course carries through every next step.

---

## Next Up - You Have Completed the Course

You started with "Hello, World!" and built a complete CLI application that creates, reads, updates, and deletes tasks with persistent JSON storage. Every Go concept from this course appeared in the final project: variables, functions, slices, maps, structs, methods, interfaces, error handling, file I/O, and JSON. You also learned how to build and run a compiled Go binary.

Go's philosophy is simplicity: a small set of powerful features that combine to solve complex problems. No classes, no exceptions, no inheritance. Just structs, interfaces, goroutines, and explicit error handling. The code style you practiced in this course is the same style used in Docker, Kubernetes, Terraform, and thousands of production services around the world.

The next step is to pick one project from the extension ideas or the learning roadmap and start building. The best way to deepen your Go knowledge is to write Go code for something you care about.

Happy coding with Go.