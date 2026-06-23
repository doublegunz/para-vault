## 1. Before You Begin

In Lesson 10, we added `author_id` to the books table. But nothing stops someone from inserting `author_id = 999` even though author 999 does not exist. A **foreign key** enforces this: it guarantees that the value in one table's column must exist in another table's primary key. Foreign keys formalize relationships between tables and make the database enforce data integrity rules automatically, without relying on application code.

### What You'll Build

You will add foreign key constraints to the `books` and `orders` tables, understand how ON DELETE behavior works, and see how foreign keys prevent orphaned data.

### What You'll Learn

- ✅ What a foreign key is and why it matters
- ✅ One-to-many relationships
- ✅ Adding foreign keys to existing tables with ALTER TABLE
- ✅ `ON DELETE CASCADE` and `ON DELETE SET NULL`
- ✅ Many-to-many relationships (concept)
- ✅ Entity Relationship diagrams (text-based)

### What You'll Need

- The `bookstore` database with books, authors, customers, and orders tables
- The `author_id` column added in Lesson 10

---

## 2. Setup

Connect to MySQL and select the bookstore database before running any statements in this lesson.

```sql
mysql -u root -p
USE bookstore;
```

Once you see `Database changed`, you are ready to add foreign key constraints to the bookstore tables.

---

## 3. What Is a Foreign Key?

A **foreign key** is a column in one table that references the primary key of another table. It enforces **referential integrity**: every value stored in the foreign key column must correspond to an existing row in the referenced table.

```
authors table                   books table
+----+-------------------+     +----+------------------+-----------+
| id | name              |     | id | title            | author_id |
+----+-------------------+     +----+------------------+-----------+
| 1  | Robert C. Martin  |     | 1  | Clean Code       | 1         |
| 2  | Martin Fowler     |     | 3  | Refactoring      | 2         |
+----+-------------------+     +----+------------------+-----------+
                                              ^
                                              |
                            author_id REFERENCES authors(id)
```

Without a foreign key, you could insert `author_id = 999` into `books` even though no author with ID 999 exists. With the foreign key in place, MySQL rejects that INSERT immediately with an error. This prevents orphaned data - rows that reference records that do not exist.

---

## 4. Add Foreign Keys

Foreign keys can be added to existing tables using ALTER TABLE. Each constraint gets a name (like `fk_books_author`) so it can be identified and removed later if needed.

```sql
ALTER TABLE books
    ADD CONSTRAINT fk_books_author
    FOREIGN KEY (author_id) REFERENCES authors(id)
    ON DELETE SET NULL;
```

```sql
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id)
    ON DELETE CASCADE;
```

```sql
ALTER TABLE orders
    ADD CONSTRAINT fk_orders_book
    FOREIGN KEY (book_id) REFERENCES books(id)
    ON DELETE CASCADE;
```

```sql
SHOW CREATE TABLE books;
SHOW CREATE TABLE orders;
```

`FOREIGN KEY (author_id) REFERENCES authors(id)` tells MySQL that every value in `books.author_id` must exist as an `id` in the `authors` table. The `ON DELETE` clause controls what happens to the child row when the referenced parent row is deleted. `SET NULL` means the foreign key column becomes NULL (the book is kept but loses its author link). `CASCADE` means the child row is deleted automatically along with the parent.

`SHOW CREATE TABLE` displays the full table definition including all constraints. This is useful to verify that the foreign key was added correctly.

### ON DELETE Options

The right ON DELETE behavior depends on the business logic of the relationship.

| Option | Behavior when parent row is deleted |
|--------|-------------------------------------|
| `CASCADE` | Delete all child rows automatically |
| `SET NULL` | Set the foreign key to NULL (child row kept) |
| `RESTRICT` | Prevent deletion if child rows exist (default) |
| `NO ACTION` | Same as RESTRICT in MySQL |

`ON DELETE CASCADE` on orders means: if a customer is deleted, all their orders are deleted too - because orders without a customer make no business sense. `ON DELETE SET NULL` on books means: if an author is deleted, the book's `author_id` becomes NULL - because the book still exists and can be linked to another author later.

---

## 5. Test the Foreign Key

The best way to understand what a foreign key does is to try to violate it and observe the error, then compare with a valid insert that succeeds.

```sql
INSERT INTO orders (customer_id, book_id, quantity, total_price, status, order_date)
VALUES (999, 1, 1, 45.00, 'pending', '2026-04-08');
```

```sql
INSERT INTO orders (customer_id, book_id, quantity, total_price, status, order_date)
VALUES (1, 1, 1, 45.00, 'pending', '2026-04-08');
```

The first INSERT will fail with `ERROR 1452: Cannot add or update a child row: a foreign key constraint fails`. Customer 999 does not exist in the `customers` table, so MySQL rejects the insert entirely. The second INSERT succeeds because customer 1 (Andi Pratama) does exist. This demonstrates that the foreign key is actively enforcing data integrity.

---

## 6. Relationship Types

Understanding the three types of relationships helps you decide how to structure tables and where to place foreign keys.

### One-to-Many (Most Common)

In a one-to-many relationship, one row in the parent table corresponds to many rows in the child table. The foreign key always lives on the "many" side.

```
authors (1) ----< books (many)
customers (1) ----< orders (many)
```

One author can write many books, but each book has only one author. One customer can place many orders, but each order belongs to one customer. The foreign key (`author_id` in books, `customer_id` in orders) lives on the many side and points back to the one side.

### Many-to-Many

In a many-to-many relationship, one row in either table can relate to many rows in the other. This cannot be represented with a direct foreign key. It requires a **junction table** (also called a bridge table or pivot table) that sits between the two tables with foreign keys pointing to both.

```sql
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    book_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
);
```

In this pattern, `order_items` links `orders` and `books`: one order can contain many books (via multiple `order_items` rows), and one book can appear in many orders. Note: our simplified `orders` table has `book_id` directly on the order, which works only for single-book orders. The `order_items` pattern is the production-ready design for orders that contain multiple books.

### One-to-One

In a one-to-one relationship, each row in one table corresponds to exactly one row in another. For example, one customer has one billing address. The foreign key can go on either table. This relationship type is less common and is typically used to split a table that has grown too wide.

---

## 7. The Bookstore Entity Relationship Diagram

This diagram shows the current state of the bookstore database after adding foreign keys. Lines with `1:N` indicate one-to-many relationships.

```
+-----------+        +---------+        +------------+
|  authors  |        |  books  |        | customers  |
+-----------+        +---------+        +------------+
| id (PK)   |--1:N--<| id (PK) |        | id (PK)    |
| name      |        | title   |        | name       |
| country   |        | author_id (FK)   | email      |
+-----------+        | price   |        | city       |
                     | stock   |        +-----+------+
                     +---------+              |
                          |                   | 1:N
                          | 1:N               |
                          v                   v
                     +---------+        +---------+
                     | reviews |        | orders  |
                     +---------+        +---------+
                     | id (PK) |        | id (PK) |
                     | book_id (FK)     | customer_id (FK)
                     | rating  |        | book_id (FK)
                     +---------+        | total_price
                                        +---------+
```

Each arrow shows the direction of the relationship. `authors` is the parent of `books`. `customers` is the parent of `orders`. `books` is the parent of both `reviews` and `orders`. Understanding this diagram helps you write JOIN queries in Lesson 12, because every line in this diagram represents a JOIN condition.

---

## 8. Fix the Errors in Your Code

These three errors are the most common mistakes when working with foreign keys for the first time.

**Error 1: Adding a foreign key on a column that does not exist.**

The column must be created before you can add a foreign key constraint on it.

```sql
-- Wrong: publisher_id column does not exist in books
ALTER TABLE books ADD CONSTRAINT fk_test FOREIGN KEY (publisher_id) REFERENCES publishers(id);

-- Correct: add the column first, then the constraint
ALTER TABLE books ADD COLUMN publisher_id INT;
ALTER TABLE books ADD CONSTRAINT fk_test FOREIGN KEY (publisher_id) REFERENCES publishers(id);
```

MySQL returns `ERROR 1072: Key column 'publisher_id' doesn't exist in table`. The fix is to run an `ADD COLUMN` statement first to create the column, and then a separate statement to add the foreign key constraint on that column.

**Error 2: Data type mismatch between foreign key and referenced column.**

The foreign key column and the referenced primary key column must have the same data type. If `authors.id` is INT but `books.author_id` is VARCHAR, MySQL will reject the constraint.

```sql
-- Wrong: type mismatch (author_id is VARCHAR, but authors.id is INT)
ALTER TABLE books ADD CONSTRAINT fk_bad FOREIGN KEY (author_id) REFERENCES authors(id);

-- Correct: ensure both columns are INT
-- First: ALTER TABLE books MODIFY COLUMN author_id INT;
-- Then: add the foreign key constraint
```

Check the data types of both columns with `DESCRIBE` before adding the constraint. The parent column (the referenced one) and the child column must use the same base type: INT with INT, VARCHAR(n) with VARCHAR(n), and so on.

**Error 3: Trying to delete a parent row that has child rows, with RESTRICT.**

When the ON DELETE option is RESTRICT (the default), MySQL prevents you from deleting a parent row that has dependent child rows.

```sql
-- Wrong: author 1 has books referencing it; RESTRICT blocks the delete
DELETE FROM authors WHERE id = 1;

-- Correct option A: use ON DELETE CASCADE so child rows are deleted automatically
-- Correct option B: delete or update the child rows first, then delete the parent
UPDATE books SET author_id = NULL WHERE author_id = 1;
DELETE FROM authors WHERE id = 1;
```

The error message is `ERROR 1451: Cannot delete or update a parent row: a foreign key constraint fails`. To fix this, either change the foreign key to CASCADE or SET NULL, or manually handle the child rows before deleting the parent.

---

## 9. Exercises

**Exercise 1:** Add a foreign key from `reviews.book_id` to `books.id` with ON DELETE CASCADE. Add a foreign key from `reviews.customer_id` to `customers.id` with ON DELETE CASCADE. Test by inserting a review.

**Exercise 2:** Try to insert an order with a non-existent `customer_id` (e.g., 999). Observe the error. Then insert a valid order and verify it works.

**Exercise 3:** Select all orders for customer 5. Then delete customer 5 from the `customers` table. Check the `orders` table again to confirm the orders were removed automatically by CASCADE.

---

## 10. Solutions

**Solution for Exercise 1:**

Add both foreign keys with separate ALTER TABLE statements, then test with an insert.

```sql
ALTER TABLE reviews
    ADD CONSTRAINT fk_reviews_book
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE;

ALTER TABLE reviews
    ADD CONSTRAINT fk_reviews_customer
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE;

INSERT INTO reviews (book_id, customer_id, rating, comment) VALUES (2, 1, 5, 'Great read!');
```

`ON DELETE CASCADE` means if book 2 or customer 1 is ever deleted, any reviews linked to them are also deleted automatically. The INSERT succeeds because book 2 ("The Pragmatic Programmer") and customer 1 (Andi Pratama) both exist in the database.

**Solution for Exercise 2:**

First attempt the invalid insert to see the error, then insert a valid order.

```sql
INSERT INTO orders (customer_id, book_id, quantity, total_price, status, order_date)
VALUES (999, 1, 1, 45.00, 'pending', '2026-04-08');

INSERT INTO orders (customer_id, book_id, quantity, total_price, status, order_date)
VALUES (2, 3, 1, 55.00, 'pending', '2026-04-08');
```

The first INSERT returns `ERROR 1452: Cannot add or update a child row: a foreign key constraint fails`. Customer 999 does not exist so MySQL blocks the operation entirely. The second INSERT works because customer 2 (Budi Santoso) and book 3 ("Refactoring") both exist in their respective tables.

**Solution for Exercise 3:**

Check the orders first, then delete the customer, then verify the cascade.

```sql
SELECT * FROM orders WHERE customer_id = 5;

DELETE FROM customers WHERE id = 5;

SELECT * FROM orders WHERE customer_id = 5;
```

The first SELECT shows the orders belonging to customer 5 (Eka Wahyuni). The DELETE removes customer 5 from the `customers` table. Because the foreign key on `orders.customer_id` was defined with `ON DELETE CASCADE`, MySQL automatically deletes all orders where `customer_id = 5` as part of the same operation. The third SELECT returns an empty set, confirming the cascade worked correctly.

---

## Next Up - Lesson 12

Foreign keys enforce referential integrity: every referenced ID must exist in the parent table. `ON DELETE CASCADE` removes child rows automatically when the parent is deleted. `ON DELETE SET NULL` sets the foreign key to NULL instead. One-to-many relationships use a foreign key on the many side. Many-to-many relationships require a junction table. Foreign key columns must have the same data type as the referenced primary key column.

In Lesson 12, you will learn **JOIN**: how to combine data from multiple connected tables into a single query result, which is the most powerful feature of relational databases.