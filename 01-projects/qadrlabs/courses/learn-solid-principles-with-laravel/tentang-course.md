---
title: "Learn SOLID Principles with Laravel"
slug: "learn-solid-principles-with-laravel"
status: "draft"
---

# Learn SOLID Principles with Laravel

## Deskripsi
Learn the five SOLID principles by refactoring real Laravel 13 code. Build SolidLab, then fix a bloated controller, an if/else payment service, a broken sender hierarchy, a fat interface, and a tightly coupled newsletter, with Pest proving nothing broke.

## Konten
Most Laravel developers learn the framework long before they learn how to structure the code they write in it. Routes, controllers, and Eloquent get you shipping quickly, and then one day you open a controller that has grown to six hundred lines, change one thing, and watch three unrelated tests turn red. SOLID is the set of five design habits that prevents that day from arriving.

This course teaches those habits the only way they actually stick: by writing bad code on purpose and then fixing it. You will build SolidLab, a single Laravel 13 application, and grow it lesson by lesson with five feature areas that each start out broken in an instructive way. An invoice controller that does five jobs at once. A payment service with an if/else chain that grows every quarter. A notification hierarchy whose subclasses quietly break their parent's promises. A reporting interface so fat that half its implementations throw exceptions. A newsletter controller welded to Mailchimp.

Every refactor is protected by Pest. You write tests against the ugly version first, capture a green baseline, refactor, and run the same tests again. That loop is the point: it shows you that a SOLID refactor changes structure without changing behavior, and it gives you a repeatable safety net for the refactors you will do at work. The final module puts all five principles to work in one pass and gives you a code review checklist you can use on your own projects the next day.

**Prerequisites:**
- PHP 8.3 or later and Composer 2.x installed
- Comfortable with Laravel routing, controllers, Eloquent models, and migrations
- Basic object oriented PHP: classes, interfaces, inheritance, type hints
- A terminal and a code editor. No prior testing experience required, Pest is introduced from scratch

**By the end, you will have:**
- A working definition of all five SOLID principles and the ability to spot violations in real code
- SolidLab, a Laravel 13 application containing five refactored feature areas
- Single Responsibility applied by splitting a bloated invoice controller into four focused services
- Open/Closed applied by replacing an if/else payment dispatcher with a gateway contract and container tagging
- Liskov Substitution applied by finding and fixing three silent violations in a notification sender hierarchy
- Interface Segregation applied by splitting a fat reporting interface into capability based contracts
- Dependency Inversion applied by binding a newsletter contract in a service provider and testing against a fake
- A Pest test suite that proves each refactor preserved behavior
- A SOLID code review checklist and the judgment to know when applying a principle is over engineering

## Daftar Modul

### 1. Module 1 — SOLID Foundations
Build the mental model behind all five principles, then scaffold SolidLab, the Laravel 13 application you will refactor for the rest of the course, and learn to read a Pest baseline.

- Lesson 1 — What SOLID Really Means
- Lesson 2 — Setting Up SolidLab and Your Pest Baseline

### 2. Module 2 — Single Responsibility and Open/Closed
Split a bloated invoice controller into four focused services, then replace a growing if/else payment dispatcher with a gateway contract you can extend without editing tested code.

- Lesson 3 — Refactoring a Bloated Invoice Controller
- Lesson 4 — Building an Extensible Payment Gateway

### 3. Module 3 — Liskov Substitution and Interface Segregation
Hunt down three silent substitution bugs in a notification sender hierarchy, then split a fat reporting interface into capability based contracts that no class has to fake.

- Lesson 5 — Notification Senders That Keep Their Promises
- Lesson 6 — Splitting a Fat Reporting Interface

### 4. Module 4 — Dependency Inversion and Putting It Together
Invert a newsletter controller onto a contract resolved by the service container, then apply all five principles in a single refactor and take away a reusable code review checklist.

- Lesson 7 — Newsletter Providers and the Service Container
- Lesson 8 — Applying SOLID Together
- Lesson 9 — What's Next
