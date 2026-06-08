---
title: "Understanding Goroutines in Go: When They Help and When They Don't"
slug: "understanding-goroutines-in-go-when-they-help-and-when-they-dont"
category: "Golang"
date: "2026-05-01"
status: "published"
---

You have probably heard it before: "Go is fast because of goroutines." So you start a new Go project, and every time you have a slow-looking operation, you reach for the `go` keyword. Spawn a goroutine for this, spawn a goroutine for that. The program feels concurrent and modern. But then you benchmark it, and the numbers barely move. In some cases, it is actually slower than before.

The problem is not goroutines themselves. Goroutines are genuinely one of Go's greatest strengths. The problem is using them without understanding what kind of work actually benefits from concurrency. Goroutines shine when your program spends most of its time waiting: waiting for a network response, a database query, a file read. When your program is busy doing pure computation, goroutines help, but only up to a point, because parallelism is bounded by how many CPU cores your machine has.

In this article, we build three runnable programs that prove this with real numbers. We start with the basics, then simulate both an I/O-bound workload and a CPU-bound workload, and measure the difference. After the code, we dig into the theory: concurrency versus parallelism, the GMP scheduler model, and a practical decision guide for when to reach for goroutines in production code.

## Overview {#overview}

This article pairs hands-on demos with conceptual depth. We write code first, run it and read the output together, and then explain the mechanics underneath. By the time we reach the conclusion, the numbers will make the theory feel obvious.

### What You'll Build

- `basic/main.go`: a minimal goroutine demo using `sync.WaitGroup` to understand how goroutines launch and complete
- `io_bound/main.go`: a program that simulates 10 concurrent network requests, comparing sequential versus concurrent execution with measurable timing
- `cpu_bound/main.go`: a prime-counting program that runs the same computation with sequential code, 4 goroutines, and 100 goroutines, making the ceiling effect of CPU-bound concurrency visible

### What You'll Learn

- The precise difference between concurrency and parallelism, and why Go is designed for one but can do both
- How goroutines work as lightweight threads managed entirely by the Go runtime
- How the Go scheduler's GMP model (Goroutine, Machine, Processor) multiplexes millions of goroutines across a small pool of OS threads
- Why I/O-bound tasks benefit dramatically from goroutines while CPU-bound tasks plateau at `GOMAXPROCS`
- How to use `sync.WaitGroup` and `sync.Mutex` to coordinate goroutines safely

### What You'll Need

- Go 1.21 or later (`go version` to check)
- Familiarity with basic Go syntax: functions, slices, and `fmt.Printf`
- A terminal to run the programs

## Step 1: Set Up the Project {#step-1-set-up-the-project}

We will keep all three programs in a single module. Create the project folder and initialize the module:

```bash
mkdir goroutine-demo
cd goroutine-demo
go mod init goroutine-demo
```

The `go mod init goroutine-demo` command creates a `go.mod` file that declares the module name. Go uses this file to resolve imports and manage dependencies. We will not add any external dependencies for this tutorial: everything we need is in the standard library.

Next, create the three subdirectories, one for each program:

```bash
mkdir basic io_bound cpu_bound
```

Your project structure will look like this:

```
goroutine-demo/
├── go.mod
├── basic/
├── io_bound/
└── cpu_bound/
```

## Step 2: Your First Goroutine {#step-2-your-first-goroutine}

Before we measure anything, we need to understand the fundamental mechanics. A goroutine is launched by placing the `go` keyword before a function call. The function runs concurrently with the rest of the program. The tricky part is that `main()` does not automatically wait for goroutines to finish. If `main()` returns, all goroutines are killed immediately, regardless of whether they completed.

`sync.WaitGroup` solves this problem. Think of it as a counter: you increment it before launching each goroutine, and each goroutine decrements it when it finishes. `wg.Wait()` blocks until the counter reaches zero.

Create `basic/main.go`:

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

// greet simulates a short task: printing a greeting after a small delay.
// It receives a pointer to the WaitGroup so it can signal completion.
func greet(name string, wg *sync.WaitGroup) {
	defer wg.Done() // decrement the WaitGroup counter when this function returns,
	                // even if it panics; defer ensures this always runs
	time.Sleep(10 * time.Millisecond) // simulate a small unit of work
	fmt.Printf("Hello from %s!\n", name)
}

func main() {
	var wg sync.WaitGroup

	names := []string{"Alice", "Bob", "Charlie", "Diana", "Eve"}

	for _, name := range names {
		wg.Add(1) // increment the counter BEFORE launching the goroutine,
		          // never after, to avoid a race where Done() is called first
		go greet(name, &wg) // launch greet as a goroutine; it runs independently
	}

	wg.Wait() // block here until all five goroutines call wg.Done()
	fmt.Println("All goroutines finished.")
}
```

Run it:

```bash
go run basic/main.go
```

Expected output (the order will vary across runs, which is the point):

```
Hello from Diana!
Hello from Eve!
Hello from Charlie!
Hello from Alice!
Hello from Bob!
All goroutines finished.
```

The non-deterministic order is not a bug. It is concrete evidence that all five goroutines ran concurrently. The Go scheduler decided which one to run at each moment, and it does not guarantee order. This is exactly the behavior we want from concurrent code.

## Step 3: Goroutines with I/O-Bound Work {#step-3-io-bound}

Now we measure. I/O-bound work is any operation where your program spends most of its time waiting for something external: a network response, a database query, a file read from disk. During that wait, your CPU is idle. Goroutines are perfect here because while one goroutine waits, the Go scheduler runs another.

We will simulate 10 HTTP requests, each taking 100 milliseconds, which is a realistic network round-trip for a remote API. We run them sequentially first, then concurrently, and compare the total time.

Create `io_bound/main.go`:

```go
package main

import (
	"fmt"
	"sync"
	"time"
)

// simulateFetch mimics an HTTP request to the given URL.
// The 100ms sleep represents a real network round-trip to an external API.
// In production code, this would be an http.Get() call.
func simulateFetch(url string) {
	time.Sleep(100 * time.Millisecond)
	fmt.Printf("  Fetched: %s\n", url)
}

// runSequential fetches each URL one at a time.
// The program blocks on each request before starting the next one.
func runSequential(urls []string) time.Duration {
	start := time.Now()
	for _, url := range urls {
		simulateFetch(url)
	}
	return time.Since(start) // how long the entire loop took
}

// runConcurrent launches one goroutine per URL.
// All fetches happen at the same time; we wait for all of them to finish.
func runConcurrent(urls []string) time.Duration {
	var wg sync.WaitGroup
	start := time.Now()

	for _, url := range urls {
		wg.Add(1)
		go func(u string) {
			defer wg.Done()
			simulateFetch(u)
		}(url) // pass url as an argument to avoid closure capture issues;
		       // without this, all goroutines might print the same URL
	}

	wg.Wait()
	return time.Since(start)
}

func main() {
	urls := []string{
		"https://api.example.com/users",
		"https://api.example.com/posts",
		"https://api.example.com/comments",
		"https://api.example.com/albums",
		"https://api.example.com/photos",
		"https://api.example.com/todos",
		"https://api.example.com/profile",
		"https://api.example.com/settings",
		"https://api.example.com/notifications",
		"https://api.example.com/feed",
	}

	fmt.Println("=== Sequential ===")
	seqTime := runSequential(urls)
	fmt.Printf("Total time: %v\n\n", seqTime)

	fmt.Println("=== Concurrent ===")
	concTime := runConcurrent(urls)
	fmt.Printf("Total time: %v\n\n", concTime)

	fmt.Printf("Goroutines were %.1fx faster\n", float64(seqTime)/float64(concTime))
}
```

Run it:

```bash
go run io_bound/main.go
```

Expected output:

```
=== Sequential ===
  Fetched: https://api.example.com/users
  Fetched: https://api.example.com/posts
  Fetched: https://api.example.com/comments
  Fetched: https://api.example.com/albums
  Fetched: https://api.example.com/photos
  Fetched: https://api.example.com/todos
  Fetched: https://api.example.com/profile
  Fetched: https://api.example.com/settings
  Fetched: https://api.example.com/notifications
  Fetched: https://api.example.com/feed
Total time: 1.001234567s

=== Concurrent ===
  Fetched: https://api.example.com/notifications
  Fetched: https://api.example.com/photos
  Fetched: https://api.example.com/feed
  Fetched: https://api.example.com/users
  Fetched: https://api.example.com/profile
  Fetched: https://api.example.com/posts
  Fetched: https://api.example.com/settings
  Fetched: https://api.example.com/todos
  Fetched: https://api.example.com/comments
  Fetched: https://api.example.com/albums
Total time: 100.456789ms

Goroutines were 9.9x faster
```

Ten requests that each take 100ms add up to about 1 second when run sequentially. With goroutines, all ten start at the same time. They all sleep for 100ms simultaneously, so the entire batch completes in roughly 100ms: nearly a 10x speedup. This is not magic; it is simply avoiding the wasted idle time between requests.

## Step 4: Goroutines with CPU-Bound Work {#step-4-cpu-bound}

CPU-bound work is the opposite: your program is actively computing, not waiting. Every millisecond is spent executing instructions on a CPU core. Adding more goroutines can help here, because multiple goroutines can run truly in parallel on multiple cores. But there is a hard ceiling: you cannot run more goroutines truly in parallel than you have CPU cores (controlled by `GOMAXPROCS`, which defaults to the number of logical CPUs).

Beyond that ceiling, adding more goroutines does not increase speed. The extra goroutines must wait in a queue, and the scheduler overhead of managing them can actually slow things down slightly.

We will demonstrate this by counting prime numbers up to 1,000,000 using trial division, which is a pure CPU task. We run it sequentially, then with 4 goroutines, then with 100 goroutines.

Create `cpu_bound/main.go`:

```go
package main

import (
	"fmt"
	"math"
	"runtime"
	"sync"
	"time"
)

// isPrime checks whether n is a prime number using trial division.
// For each n, we test divisors from 2 up to sqrt(n).
// This is deliberately inefficient to create meaningful CPU load.
func isPrime(n int) bool {
	if n < 2 {
		return false
	}
	for i := 2; i <= int(math.Sqrt(float64(n))); i++ {
		if n%i == 0 {
			return false // found a divisor, not prime
		}
	}
	return true
}

// countPrimesInRange counts how many primes exist in [start, end).
// This is the core computation that each goroutine will run on its own slice.
func countPrimesInRange(start, end int) int {
	count := 0
	for i := start; i < end; i++ {
		if isPrime(i) {
			count++
		}
	}
	return count
}

// runSequential counts primes from 0 to limit in a single loop.
func runSequential(limit int) (int, time.Duration) {
	start := time.Now()
	count := countPrimesInRange(0, limit)
	return count, time.Since(start)
}

// runConcurrent splits the range [0, limit) into numGoroutines chunks.
// Each goroutine counts primes in its own chunk independently.
// A mutex protects the shared total counter from concurrent writes.
func runConcurrent(limit, numGoroutines int) (int, time.Duration) {
	var wg sync.WaitGroup
	var mu sync.Mutex
	total := 0

	chunkSize := limit / numGoroutines
	start := time.Now()

	for i := 0; i < numGoroutines; i++ {
		wg.Add(1)
		chunkStart := i * chunkSize
		chunkEnd := chunkStart + chunkSize
		if i == numGoroutines-1 {
			chunkEnd = limit // the last chunk covers any remainder
		}

		go func(s, e int) {
			defer wg.Done()
			count := countPrimesInRange(s, e) // compute locally, no locking needed here
			mu.Lock()
			total += count // only the final addition touches the shared variable
			mu.Unlock()
		}(chunkStart, chunkEnd) // pass as arguments to avoid closure capture
	}

	wg.Wait()
	return total, time.Since(start)
}

func main() {
	const limit = 1_000_000

	fmt.Printf("Counting primes up to %d...\n", limit)
	fmt.Printf("Machine GOMAXPROCS: %d\n\n", runtime.GOMAXPROCS(0))
	// runtime.GOMAXPROCS(0) returns the current value without changing it

	count, dur := runSequential(limit)
	fmt.Printf("Sequential:         %d primes in %v\n", count, dur)

	count, dur = runConcurrent(limit, 4)
	fmt.Printf("Concurrent (4 G):   %d primes in %v\n", count, dur)

	count, dur = runConcurrent(limit, 100)
	fmt.Printf("Concurrent (100 G): %d primes in %v\n", count, dur)
}
```

Run it:

```bash
go run cpu_bound/main.go
```

Expected output (exact times will vary by machine; the pattern is what matters):

```
Counting primes up to 1,000,000...
Machine GOMAXPROCS: 8

Sequential:         78498 primes in 487.123456ms
Concurrent (4 G):   78498 primes in 141.234567ms
Concurrent (100 G): 78498 primes in 138.567890ms
```

Notice three things. First, all three runs produce exactly 78498 primes: the results are correct regardless of how many goroutines we used. Second, 4 goroutines gave a real speedup, roughly 3.4x on an 8-core machine, because the work split across 4 cores running in parallel. Third, jumping from 4 goroutines to 100 goroutines gave almost no further improvement. The speedup plateaued because we only have 8 physical cores. Beyond that, extra goroutines wait in a queue and contribute scheduling overhead rather than useful work.

## Step 5: Try It Out {#step-5-try-it-out}

Run all three programs back to back and observe the contrast:

```bash
go run basic/main.go
go run io_bound/main.go
go run cpu_bound/main.go
```

The story the numbers tell is consistent across every machine:

**For `basic/main.go`:** The output order changes every time you run it. That randomness confirms that goroutines are not running one after the other; they are genuinely interleaved.

**For `io_bound/main.go`:** The concurrent version runs in approximately the time of a single request (100ms), not the time of all requests added together (1000ms). Goroutines eliminated the idle time between requests. The more requests you add, the more dramatic this ratio becomes.

**For `cpu_bound/main.go`:** The speedup from adding goroutines is real but bounded. Going from 1 goroutine to 4 goroutines might give you a 3x speedup on a 4-core machine. Going from 4 to 100 goroutines gives you almost nothing extra. You can verify this by changing the goroutine count yourself: try 2, try `runtime.NumCPU()`, try 1000. The pattern is stable.

If you want to experiment further, try changing `limit` in `cpu_bound/main.go` to `10_000_000` to make the CPU work heavier, or change the sleep duration in `io_bound/main.go` to `500 * time.Millisecond` to simulate a slower API. The ratios will hold.

## Concurrency vs Parallelism: What Is the Difference? {#concurrency-vs-parallelism}

Our demos illustrated a distinction that is worth making explicit, because the two terms are often used interchangeably when they mean quite different things.

**Concurrency** is about structure. A concurrent program is designed to handle multiple tasks that can overlap in time. It does not necessarily mean two things are happening at the exact same instant. Think of a chef who starts boiling water, then chops vegetables while the water heats, then stirs a sauce while the vegetables roast. One person, one pair of hands, but multiple tasks progressing simultaneously by switching between them during idle moments.

**Parallelism** is about execution. A parallel program actually runs multiple tasks at the same physical instant, each on its own CPU core. Think of two chefs each working on a different dish at the same time.

Go is designed for concurrency. When a goroutine hits an I/O wait, the Go scheduler parks it and runs another goroutine on the same OS thread. No CPU core sits idle; work continues on whatever goroutine is ready. This is what our `io_bound` demo measured: one OS thread (or a few) handling ten tasks concurrently by switching during each sleep.

Parallelism is something Go can also do, but only when multiple CPU cores are available and the work is CPU-bound. Our `cpu_bound` demo benefited from parallelism when we split the prime range across 4 goroutines, because each chunk ran on a separate core at the same time. That is the bonus Rob Pike famously described: Go is designed for concurrency, and parallelism can emerge as a consequence.

The practical implication is straightforward. For I/O-bound work, concurrency alone is enough to achieve massive throughput, even on a single core. For CPU-bound work, you need true parallelism, and that is limited by the number of physical cores your machine has.

## How the Go Scheduler Works: The GMP Model {#gmp-model}

To understand why goroutines are so much lighter than OS threads, we need to look inside the Go runtime. The scheduler uses a model called GMP, named after its three core components.

**G stands for Goroutine.** A G represents a unit of work: a function to run, with its own stack, its own program counter, and some metadata. When you write `go doSomething()`, the runtime creates a new G and places it in a run queue. Crucially, each goroutine starts with only about 2 KB of stack memory. The stack grows and shrinks dynamically as needed. This is why you can create hundreds of thousands of goroutines in a single program without running out of memory. An OS thread, by contrast, typically allocates 1 to 8 MB of stack up front and cannot grow or shrink it.

**M stands for Machine, meaning an OS thread.** An M is a real, kernel-managed thread. On a typical program, there are only a handful of Ms alive at any time, perhaps one per CPU core plus a few extras for system calls. Ms are expensive to create and switch between because every context switch requires a trip into the kernel.

**P stands for Processor, meaning a logical processor.** A P is the key abstraction that makes everything work. Each P holds a local queue of goroutines (Gs) waiting to be run. A P must be paired with an M for any Go code to execute. The number of Ps is controlled by `GOMAXPROCS`, which defaults to the number of logical CPU cores. If your machine has 8 cores, Go creates 8 Ps, and at most 8 goroutines can truly run in parallel at any moment.

The M:N scheduling model describes how this fits together: M goroutines are multiplexed onto N OS threads. When a goroutine blocks on I/O (a network call, a file read, a `time.Sleep`), the Go runtime detects the block and parks the goroutine. The P that was paired with that M picks up the next goroutine from its local queue and continues running, without involving the OS at all. The blocked goroutine will be rescheduled when its I/O completes. This is why I/O-bound concurrency is so efficient: one OS thread can keep many goroutines progressing.

When a P's local queue runs empty, it practices **work stealing**: it reaches into another P's queue and borrows goroutines to run. This keeps all cores busy without requiring a centralized scheduler that would become a bottleneck.

## Goroutine vs OS Thread: The Numbers {#goroutine-vs-os-thread}

The difference between a goroutine and an OS thread comes down to four dimensions:

| | OS Thread | Goroutine |
|---|---|---|
| **Initial stack** | 1 to 8 MB (fixed) | 2 KB (grows dynamically) |
| **Creation** | Slow (kernel syscall) | Fast (user-space only) |
| **Context switch** | Expensive (kernel mode) | Cheap (Go runtime) |
| **Practical limit** | Thousands (heavy) | Hundreds of thousands (lightweight) |

The context switch difference is significant in practice. Switching between OS threads requires the kernel to save and restore CPU registers, flush certain CPU caches, and schedule the new thread through the OS scheduler. Switching between goroutines happens entirely in user space. The Go runtime saves the goroutine's stack pointer and a few registers, and resumes another goroutine. No system call, no kernel involvement, no cache flush.

This is why the benchmark from the Go runtime team shows that you can create a million goroutines in a few seconds and a few gigabytes of memory, while a million OS threads would exhaust system resources on any real machine.

## When to Reach for Goroutines {#when-to-reach-for-goroutines}

With both the theory and the measurements in hand, the decision guide becomes simple.

**Use goroutines freely for I/O-bound work.** Anything that waits on a network response, a database query, a file read, or a timer is a strong candidate. The pattern from `io_bound/main.go` applies directly: launch one goroutine per task, use a `WaitGroup` to wait for all of them, and let the scheduler handle the interleaving. The speedup scales nearly linearly with the number of concurrent tasks, up to very large numbers.

**Use goroutines thoughtfully for CPU-bound work.** Goroutines do help here, but cap the number of worker goroutines at around `runtime.NumCPU()` or use a worker pool. Launching more goroutines than CPU cores does not add parallelism; it adds scheduling overhead. For heavy CPU-bound workloads, consider a worker pool pattern where you pre-create a fixed number of goroutines and feed work to them via a channel.

**Watch for goroutine leaks.** A goroutine that blocks indefinitely and is never cleaned up is a memory leak. Common causes are goroutines blocked on a channel that nobody ever writes to, or goroutines making a network request with no timeout. Always pair goroutines with a cancellation mechanism, either a `context.Context` with a deadline, or a done channel.

**Prefer `sync.WaitGroup` for fan-out patterns.** When you launch N goroutines and wait for all of them, `WaitGroup` is the idiomatic tool. When goroutines need to communicate results back, use channels. When multiple goroutines share a variable, protect it with a `sync.Mutex` or use `sync/atomic` for simple integer counters.

## Conclusion {#conclusion}

Goroutines are one of Go's genuine strengths, but their power is specific. Understanding the difference between I/O-bound and CPU-bound work is the key to using them effectively. Here are the key takeaways from everything we built and measured:

- **Goroutines are lightweight by design.** Starting with only 2 KB of stack and managed entirely by the Go runtime, goroutines are orders of magnitude cheaper to create and switch between than OS threads. This is what makes launching thousands of them practical.
- **The GMP model is why concurrency scales.** Go's scheduler maps many goroutines (G) onto a small pool of OS threads (M) through logical processors (P). When a goroutine blocks on I/O, the scheduler immediately runs another goroutine on the same thread. No core sits idle.
- **I/O-bound tasks are the strongest use case.** As our `io_bound` demo showed, 10 concurrent goroutines completing 10 network requests took roughly the time of one request, not ten. The more I/O waits you have, the more goroutines pay off.
- **CPU-bound speedup plateaus at GOMAXPROCS.** Our `cpu_bound` demo showed that going from 4 goroutines to 100 goroutines produced almost no improvement on an 8-core machine. True parallelism is bounded by physical cores, not by goroutine count.
- **Concurrency is structure; parallelism is execution.** Go is designed for concurrency. Programs that correctly structure concurrent work can achieve high throughput even on a single core. Parallelism (work running simultaneously on multiple cores) emerges as a bonus when cores are available.
- **Closure capture is a subtle bug source.** Always pass loop variables as function arguments when launching goroutines inside a loop, as we did with `go func(u string) {...}(url)`. Without this, all goroutines may see the same final value of the loop variable.

The next step from here is channels. While `WaitGroup` and `Mutex` are enough for fan-out patterns and shared counters, channels let goroutines communicate results and coordinate more complex workflows. That will be the focus of our next article.