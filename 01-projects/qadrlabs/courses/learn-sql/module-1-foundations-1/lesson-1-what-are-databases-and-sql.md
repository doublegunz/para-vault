## 1. Before You Begin

Every app you use stores data somewhere. Instagram stores your photos and followers. Shopee stores products and orders. Google stores search results and user accounts. Behind all of them is a **database**: a structured system for storing, organizing, and retrieving data. And the language you use to talk to most databases is **SQL** (Structured Query Language).

This lesson has no code. The focus is on understanding what relational databases are, how SQL works, and what you will build throughout this course.

### What You'll Build

You will not write code in this lesson. Instead, you will understand the structure of the bookstore database that the entire course builds around, so every query you write in later lessons has clear context and purpose.

### What You'll Learn

- ✅ What a relational database is
- ✅ How data is organized in tables, rows, and columns
- ✅ What SQL is and what it can do
- ✅ The four categories of SQL: DDL, DML, DQL, DCL
- ✅ What you will build in this course

### What You'll Need

- No software installation needed for this lesson
- No prior database experience required

---

## 2. What Is a Database?

A **database** is an organized collection of data stored electronically. A **relational database** organizes data into **tables** (like spreadsheets) with **rows** (records) and **columns** (fields). This structure makes it easy to store large amounts of data and retrieve exactly what you need without loading everything at once.

Example: a `books` table

| id | title | author | price | published_year |
|----|-------|--------|-------|----------------|
| 1 | Clean Code | Robert C. Martin | 45.00 | 2008 |
| 2 | The Pragmatic Programmer | David Thomas | 50.00 | 2019 |
| 3 | Refactoring | Martin Fowler | 55.00 | 2018 |

Each **row** is one book (one record). Each **column** is one piece of information about the book (one field). The `id` column uniquely identifies each row. Because every row has a unique ID, the database can always pinpoint the exact record you are looking for.

Popular relational database systems include MySQL, PostgreSQL, SQLite, Microsoft SQL Server, and Oracle. This course uses **MySQL**, the most widely used open-source database.

---

## 3. What Is SQL?

SQL (pronounced "sequel" or "S-Q-L") is the standard language for interacting with relational databases. You write SQL statements to describe what you want, and the database engine figures out how to retrieve or modify the data efficiently.

Common SQL operations include:

- **Retrieve data**: "Show me all books published after 2015."
- **Insert data**: "Add a new book to the catalog."
- **Update data**: "Change the price of book #3 to 60.00."
- **Delete data**: "Remove book #1 from the catalog."
- **Create structures**: "Create a new table called `orders`."

SQL is **declarative**: you describe **what** you want, not **how** to get it. This is why SQL looks so readable compared to other programming languages. You write something close to plain English, and the database handles the low-level execution.

---

## 4. The Four Categories of SQL

SQL statements are grouped into four categories depending on what they do. Understanding these categories helps you know which type of statement to reach for in any situation.

| Category | Name | Purpose | Key Statements |
|----------|------|---------|----------------|
| DQL | Data Query Language | Retrieve data | SELECT |
| DML | Data Manipulation Language | Modify data | INSERT, UPDATE, DELETE |
| DDL | Data Definition Language | Define structure | CREATE, ALTER, DROP |
| DCL | Data Control Language | Manage permissions | GRANT, REVOKE |

This course focuses on DQL (SELECT), DML (INSERT, UPDATE, DELETE), and DDL (CREATE, ALTER, DROP). These cover 95% of what a developer needs day-to-day. DCL is used by database administrators and is outside the scope of this course.

---

## 5. What You Will Build

Throughout this course, you will build a **bookstore database** that grows more complete with every lesson. The database will contain these tables:

- **books** - title, price, published year, stock, category
- **authors** - name, country, birth year
- **customers** - name, email, city
- **orders** - customer, book, quantity, order date, status

Each table connects to the others using relationships. By the end, you will be able to answer questions like:

- "What are the top 5 most expensive books?"
- "How many books has each author written?"
- "Which customers have placed more than 3 orders?"
- "What is the total revenue from orders this month?"
- "Which books have never been ordered?"

Every lesson adds tables, data, and queries to this database. Nothing is thrown away or replaced; each lesson picks up exactly where the previous one left off.

---

## 6. SQL in the Real World

SQL is not just a tool for database administrators. It is used by developers, analysts, and data engineers across virtually every technology stack.

| Technology | How It Uses SQL |
|-----------|----------------|
| PHP / Laravel | Eloquent ORM generates SQL behind the scenes |
| Java / Spring Boot | JPA/Hibernate translates entities to SQL |
| Python / Django | Django ORM generates SQL queries |
| Go | `database/sql` package sends raw SQL |
| Data Analysis | Analysts query databases directly with SQL |
| Business Intelligence | Tools like Metabase, Tableau query databases |

Learning SQL means understanding what every ORM, framework, and analytics tool does under the hood. When an ORM does not behave as expected, SQL knowledge is what lets you diagnose and fix the problem.

---

## 7. Course Roadmap

Here is the path you will follow across the 14 lessons. Each module builds on the one before it.

**Lessons 1-2** cover what databases are and how to install MySQL.

**Lessons 3-4** teach querying: SELECT and WHERE (the most-used SQL skills).

**Lessons 5-6** add sorting, limiting, and aggregation (COUNT, SUM, AVG, GROUP BY).

**Lessons 7-8** cover data manipulation: INSERT, UPDATE, DELETE.

**Lessons 9-10** teach table design: CREATE TABLE, data types, constraints, ALTER TABLE.

**Lessons 11-12** introduce relationships and JOINs (the most powerful SQL feature).

**Lessons 13-14** cover subqueries, views, and the path forward.

---

## Next Up - Lesson 2

A relational database stores data in tables with rows and columns. SQL is the standard language for querying and managing that data. SQL statements are declarative: you say what you want, and the database figures out how. The four categories are DQL (SELECT), DML (INSERT, UPDATE, DELETE), DDL (CREATE, ALTER, DROP), and DCL (GRANT, REVOKE).

In Lesson 2, you will install MySQL, connect to it from the command line, and create the `bookstore` database that every lesson in this course depends on.