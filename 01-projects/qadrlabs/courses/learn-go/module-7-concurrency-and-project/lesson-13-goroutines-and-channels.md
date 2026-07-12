## 1. Before You Begin

Concurrency is Go's superpower. While other languages bolt on threads or async/await as an afterthought, Go was designed from the ground up for concurrent programming. A goroutine is a lightweight thread managed by the Go runtime at a fraction of the cost of an operating system thread. A channel is a typed pipe that lets goroutines communicate safely without shared memory.

Together, goroutines and channels implement Go's concurrency philosophy: "Do not communicate by sharing memory; instead, share memory by communicating." This lesson introduces the tools you need to run multiple tasks simultaneously and coordinate their results.

### What You'll Build

You will create programs that run multiple tasks concurrently: a parallel file download simulator that runs downloads in parallel and collects results through a channel, a producer-consumer pipeline, and a timeout mechanism using `select`.

### What You'll Learn

- ✅ Creating goroutines with the `go` keyword
- ✅ `sync.WaitGroup` for waiting on goroutines
- ✅ Channels for goroutine communication
- ✅ Buffered vs unbuffered channels
- ✅ `select` for multiplexing channels
- ✅ Common concurrency patterns

### What You'll Need

- Lesson 12 completed

---

## 2. Setup

Create a new folder `lesson-13` inside `learn-go`. Open the terminal and initialize the module:

```bash
mkdir lesson-13 && cd lesson-13
go mod init lesson-13
```

This creates the `go.mod` file for this lesson. You will create three standalone programs, each demonstrating a different concurrency concept. Every file has its own `func main()`, so run and check it separately with commands such as `go run channels.go` and `go vet channels.go`. Do not run `go test ./...` from this lesson folder because Go would try to compile the three `main` functions together.

---

## 3. Goroutines

A goroutine is launched by prefixing a function call with the `go` keyword. The function runs concurrently with the calling code. Goroutines are multiplexed onto OS threads by Go's scheduler, so you can launch thousands of goroutines without creating thousands of OS threads.

### Step 1: Create `goroutines.go`

Create the file `goroutines.go` inside `lesson-13`. This file will show the difference between sequential and concurrent execution by running the same functions both ways and measuring the time taken.

### Step 2: Write the Code

Write the following program to compare sequential versus concurrent execution:

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

func printNumbers(label string) {
    for i := 1; i <= 5; i++ {
        fmt.Printf("[%s] %d\n", label, i)
        time.Sleep(100 * time.Millisecond)
    }
}

func main() {
    fmt.Println("=== Sequential ===")
    start := time.Now()
    printNumbers("A")
    printNumbers("B")
    fmt.Printf("Sequential took: %v\n\n", time.Since(start))

    fmt.Println("=== Concurrent ===")
    start = time.Now()

    var wg sync.WaitGroup
    wg.Add(2)

    go func() {
        defer wg.Done()
        printNumbers("A")
    }()

    go func() {
        defer wg.Done()
        printNumbers("B")
    }()

    wg.Wait()
    fmt.Printf("Concurrent took: %v\n", time.Since(start))
}
```

`printNumbers("A")` followed by `printNumbers("B")` runs sequentially: B cannot start until A finishes. With five iterations of 100ms sleep each, the total time is about 1000ms.

`go func() { ... }()` launches an anonymous function as a goroutine. The calling code does not wait for the goroutine to finish: it continues immediately to the next line. Both goroutines run simultaneously, each taking about 500ms, so the total concurrent time is about 500ms.

`sync.WaitGroup` is the standard tool for waiting on a known number of goroutines. `wg.Add(2)` tells the WaitGroup that 2 goroutines will complete. Each goroutine calls `wg.Done()` when it finishes, decrementing the counter. `wg.Wait()` blocks until the counter reaches 0. `defer wg.Done()` ensures `Done` is called even if the goroutine panics, preventing a deadlock in `main`.

### Step 3: Save and Run

```bash
go run goroutines.go
```

Observe that the sequential output is `[A] 1`, `[A] 2`, ..., `[A] 5`, `[B] 1`, ... while the concurrent output interleaves `[A]` and `[B]` lines. The concurrent version takes half the time.

### Key Points

`go func() { ... }()` launches a goroutine. `sync.WaitGroup` tracks running goroutines. `wg.Add(n)` sets the count. `wg.Done()` decrements it. `wg.Wait()` blocks until the count reaches zero. `defer wg.Done()` ensures Done is called even if the goroutine panics.

---

## 4. Channels

Channels are typed pipes for sending values between goroutines. They provide safe, synchronized communication without mutexes or locks. A channel blocks the sender until a receiver is ready (for unbuffered channels) or until the buffer has space (for buffered channels).

### Step 1: Create `channels.go`

Create the file `channels.go` inside `lesson-13`. This file demonstrates unbuffered channels, buffered channels, and iterating over a channel with `range`.

### Step 2: Write the Code

Write the following program to see all three channel patterns in action:

```go
package main

import (
    "fmt"
    "time"
)

func fetchData(source string, ch chan string) {
    time.Sleep(time.Duration(100+len(source)*50) * time.Millisecond)
    ch <- fmt.Sprintf("Data from %s: OK (%d bytes)", source, len(source)*100)
}

func main() {
    fmt.Println("=== Basic Channel ===")
    ch := make(chan string)

    go func() {
        ch <- "Hello from goroutine!"
    }()

    msg := <-ch
    fmt.Println(msg)

    fmt.Println("\n=== Parallel Fetch ===")
    sources := []string{"api.example.com", "db.local", "cache.redis"}
    results := make(chan string, len(sources))

    start := time.Now()
    for _, src := range sources {
        go fetchData(src, results)
    }

    for range sources {
        fmt.Println(<-results)
    }
    fmt.Printf("All done in %v\n", time.Since(start))

    fmt.Println("\n=== Range over Channel ===")
    numbers := make(chan int)

    go func() {
        for i := 1; i <= 5; i++ {
            numbers <- i * i
        }
        close(numbers)
    }()

    for n := range numbers {
        fmt.Printf("%d ", n)
    }
    fmt.Println()
}
```

`ch := make(chan string)` creates an unbuffered channel. When the goroutine executes `ch <- "Hello from goroutine!"`, it blocks until `main` receives with `msg := <-ch`. The send and receive happen at the same moment, synchronized between the two goroutines.

`make(chan string, len(sources))` creates a buffered channel with capacity equal to the number of sources. A buffered channel allows senders to send up to the buffer capacity before blocking. Here, all three goroutines can send their results without waiting for the receiver, because the buffer can hold all three values.

The parallel fetch pattern is a common idiom: launch multiple goroutines, each sending one result to a shared buffered channel. Then collect all results with a loop. The total time is determined by the slowest goroutine, not the sum of all goroutines.

`close(numbers)` signals that no more values will be sent on the channel. The `for n := range numbers` loop reads values from the channel until it is closed, then exits. Without `close(numbers)`, the `range` loop would block forever after the last square number is received.

### Step 3: Save and Run

```bash
go run channels.go
```

Notice that all three data sources complete much faster concurrently than they would sequentially. The "All done in" time should be close to the slowest single fetch.

### Channel Basics

`ch := make(chan string)` creates an unbuffered channel. Sends block until a receiver is ready. `ch <- value` sends a value into the channel. `value := <-ch` receives a value (blocks until one is available). `make(chan string, 3)` creates a buffered channel that can hold 3 values without blocking the sender. `close(ch)` signals no more values will be sent and is required before using `range` on a channel.

---

## 5. Select Statement

The `select` statement works like a `switch` for channels. It waits on multiple channel operations simultaneously and executes the first one that is ready. If multiple channels are ready at the same time, Go chooses one at random.

### Step 1: Create `select_demo.go`

Create the file `select_demo.go` inside `lesson-13`. This file demonstrates two essential `select` patterns: selecting the first result from competing goroutines, and implementing a timeout.

### Step 2: Write the Code

Write the following program to see `select` in action:

```go
package main

import (
    "fmt"
    "time"
)

func slowTask(ch chan string) {
    time.Sleep(2 * time.Second)
    ch <- "slow task completed"
}

func fastTask(ch chan string) {
    time.Sleep(500 * time.Millisecond)
    ch <- "fast task completed"
}

func main() {
    fmt.Println("=== Select (first wins) ===")
    slow := make(chan string)
    fast := make(chan string)

    go slowTask(slow)
    go fastTask(fast)

    select {
    case msg := <-slow:
        fmt.Println("Received:", msg)
    case msg := <-fast:
        fmt.Println("Received:", msg)
    }

    fmt.Println("\n=== Timeout ===")
    result := make(chan string)
    go slowTask(result)

    select {
    case msg := <-result:
        fmt.Println("Got:", msg)
    case <-time.After(1 * time.Second):
        fmt.Println("Timeout! Task took too long.")
    }
}
```

The first `select` block waits on both `slow` and `fast` channels. `fastTask` finishes in 500ms and `slowTask` takes 2 seconds. The `case msg := <-fast` branch becomes ready first, so `select` executes it and exits. `slowTask` continues running in the background but its result is never received.

The second `select` block demonstrates the timeout pattern. `time.After(1 * time.Second)` returns a channel that sends a single value after the specified duration. If `slowTask` does not complete within 1 second, the `time.After` channel fires first and the `Timeout!` message is printed. This is the standard way to implement timeouts in Go without any external libraries.

### Step 3: Save and Run

```bash
go run select_demo.go
```

Verify that the first `select` prints the fast task result (around 500ms) and that the second `select` prints the timeout message (around 1 second, before the slow task's 2 seconds).

### How Select Works

`select` pauses execution and waits for one of its cases to become ready. The first channel that is ready wins, and that case's body executes. Unlike `switch`, `select` blocks until one case is ready. A `default` case makes `select` non-blocking: if no channel is ready, the default executes immediately.

---

## 6. Fix the Errors in Your Code

These three errors are the most common concurrency mistakes in Go programs. Each one can cause subtle bugs that are difficult to reproduce and debug.

**Error 1: Main exits before goroutines finish.**

When `main()` returns, Go terminates all goroutines immediately. Any goroutine that has not finished yet is killed silently.

```go
// Wrong: goroutine is launched but main exits before it runs
func main() {
    go func() {
        fmt.Println("Hello from goroutine")
    }()
    // main() returns here. The goroutine may never print.
}

// Correct: use WaitGroup to wait for the goroutine to complete
func main() {
    var wg sync.WaitGroup
    wg.Add(1)
    go func() {
        defer wg.Done()
        fmt.Println("Hello from goroutine")
    }()
    wg.Wait()
}
```

This is the most common mistake when first learning goroutines. The goroutine is launched but the main function reaches its last line before the goroutine has a chance to execute. Adding a `sync.WaitGroup` ensures `main` blocks until all goroutines have completed.

**Error 2: Deadlock from sending on an unbuffered channel with no concurrent receiver.**

An unbuffered channel send blocks until another goroutine receives. If the send and receive both happen in the same goroutine sequentially, neither can proceed.

```go
// Wrong: the send blocks forever because no goroutine is receiving
func main() {
    ch := make(chan int)
    ch <- 42
    fmt.Println(<-ch)
}

// Correct: send in a goroutine so main can receive concurrently
func main() {
    ch := make(chan int)
    go func() {
        ch <- 42
    }()
    fmt.Println(<-ch)
}
```

The runtime detects this situation and panics with `all goroutines are asleep - deadlock!`. The fix is to ensure the send happens in a separate goroutine, or to use a buffered channel large enough to hold the value without blocking.

**Error 3: Forgetting to close a channel before using `range`.**

`for v := range ch` iterates until the channel is closed. If the sender never closes the channel, the receiver blocks forever after the last value is consumed.

```go
// Wrong: range blocks after all 5 values are received
ch := make(chan int)
go func() {
    for i := 0; i < 5; i++ {
        ch <- i
    }
    // Missing: close(ch)
}()
for v := range ch {
    fmt.Println(v)
}
// Program hangs here forever

// Correct: close the channel when done sending
ch := make(chan int)
go func() {
    for i := 0; i < 5; i++ {
        ch <- i
    }
    close(ch)
}()
for v := range ch {
    fmt.Println(v)
}
```

The runtime detects this situation too, and panics with `all goroutines are asleep - deadlock!`. The convention is: the goroutine that sends values is responsible for closing the channel when it is done. Closing a channel is a one-time operation: sending to a closed channel panics.

---

## 7. Exercises

**Exercise 1:** Create a program that launches 5 goroutines. Each goroutine simulates downloading a file (sleep a random time between 100 and 500 milliseconds), then sends the filename and duration through a channel. `main` collects all results and displays them in the order they complete.

**Exercise 2:** Create a producer-consumer pattern. One goroutine produces the numbers 1 through 20 on a channel, then closes it. Two consumer goroutines read from the same channel and print each number with their worker ID. Use a `sync.WaitGroup` to wait for both consumers to finish.

**Exercise 3:** Create a three-stage pipeline. Stage 1 generates the numbers 1 through 10 on a channel and closes it. Stage 2 reads from that channel, squares each number, and sends the result on a new channel which it closes when done. Stage 3 reads from the squared channel and prints each value. Use separate goroutines for stages 1 and 2, with `main` running stage 3.

---

## 8. Solutions

**Solution for Exercise 1:**

```go
package main

import (
    "fmt"
    "math/rand"
    "time"
)

func download(name string, ch chan string) {
    d := time.Duration(100+rand.Intn(400)) * time.Millisecond
    time.Sleep(d)
    ch <- fmt.Sprintf("%-15s downloaded in %v", name, d)
}

func main() {
    files := []string{"index.html", "style.css", "app.js", "logo.png", "data.json"}
    ch := make(chan string, len(files))

    for _, f := range files {
        go download(f, ch)
    }

    for range files {
        fmt.Println(<-ch)
    }
}
```

`make(chan string, len(files))` creates a buffered channel with capacity equal to the number of files. This allows all goroutines to send their results without blocking, even if `main` has not started receiving yet. The `for range files` loop receives one result per file, printing them in the order they complete (fastest first) rather than in the order they were launched. `rand.Intn(400)` generates a random integer from 0 to 399, so each download takes between 100 and 499 milliseconds.

**Solution for Exercise 2:**

```go
package main

import (
    "fmt"
    "sync"
)

func consumer(id int, ch chan int, wg *sync.WaitGroup) {
    defer wg.Done()
    for n := range ch {
        fmt.Printf("Worker %d: %d\n", id, n)
    }
}

func main() {
    ch := make(chan int, 5)
    var wg sync.WaitGroup

    wg.Add(2)
    go consumer(1, ch, &wg)
    go consumer(2, ch, &wg)

    for i := 1; i <= 20; i++ {
        ch <- i
    }
    close(ch)

    wg.Wait()
}
```

Both consumer goroutines read from the same channel. When consumer 1 takes a value, consumer 2 cannot take the same value because channels are safe for concurrent access. The distribution of numbers between the two workers is non-deterministic: some numbers go to worker 1, others to worker 2, depending on which goroutine is ready when each value is sent. `close(ch)` signals both consumers to stop when the channel is empty, causing their `range` loops to exit. `wg.Wait()` ensures `main` does not return until both consumers have processed all numbers.

**Solution for Exercise 3:**

```go
package main

import "fmt"

func generate(out chan int) {
    for i := 1; i <= 10; i++ {
        out <- i
    }
    close(out)
}

func square(in chan int, out chan int) {
    for n := range in {
        out <- n * n
    }
    close(out)
}

func main() {
    nums := make(chan int)
    squares := make(chan int)

    go generate(nums)
    go square(nums, squares)

    for v := range squares {
        fmt.Println(v)
    }
}
```

The pipeline consists of three stages connected by two channels: `nums` connects `generate` to `square`, and `squares` connects `square` to `main`. `generate` closes `nums` when done, which causes the `range` loop in `square` to exit. `square` then closes `squares`, which causes the `range` loop in `main` to exit. Each stage only knows about its own input and output channels, not about the other stages. This loose coupling makes pipeline stages easy to test and replace independently.

---

## Next Up - Lesson 14

Goroutines are lightweight concurrent functions launched with the `go` keyword. Channels let goroutines communicate safely: unbuffered channels synchronize send and receive, buffered channels allow sending without an immediate receiver. `sync.WaitGroup` waits for a known number of goroutines to complete. `select` multiplexes multiple channels and executes the first ready case. `time.After` creates a timeout channel. Always close a channel from the sender side, and always use `range` only on channels that will be closed.

In Lesson 14, you will combine every concept from this course into a complete CLI task manager application: structs, slices, maps, interfaces, error handling, file I/O, and JSON storage.
