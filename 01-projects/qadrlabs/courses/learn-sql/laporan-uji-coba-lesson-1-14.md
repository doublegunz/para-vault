# Laporan Uji Coba Course "Learn SQL" (Lesson 1-14)

**Tanggal uji:** 2026-06-23
**Penguji:** Codex
**Hasil keseluruhan:** OK. Seluruh alur utama course berhasil dijalankan. Dua error yang muncul adalah negative test foreign key yang memang diharapkan oleh materi.

## Environment

| Komponen | Versi / Nilai |
|----------|---------------|
| Database engine | MariaDB 11.8.6 |
| MySQL client | MariaDB client 15.2 |
| Database | `bookstore` |
| DB user | `learn_sql_user` |
| Lokasi course | `01-projects/qadrlabs/courses/learn-sql` |
| Objek akhir | 8 tabel + 4 view |

> Catatan: Database dan credential disiapkan manual lebih dulu dengan root. User `learn_sql_user` memiliki privilege `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `ALTER`, `DROP`, `INDEX`, `REFERENCES`, `CREATE VIEW`, dan `SHOW VIEW` pada `bookstore.*`.

## Metode Uji

Blok SQL dari lesson 2 sampai 13 diekstrak dan dijalankan berurutan terhadap database `bookstore`. Sebelum uji dijalankan, objek course dibersihkan lebih dulu supaya hasil dapat diulang dari state kosong.

Blok berikut tidak dijalankan sebagai bagian dari alur utama:

- Command client seperti `mysql -u root -p`, karena koneksi dijalankan langsung dengan credential uji.
- Lifecycle database seperti `CREATE DATABASE bookstore` dan latihan `testdb`, karena database sudah dibuat manual dengan root.
- Blok `-- Wrong` pada section "Fix the Errors in Your Code", karena memang dirancang untuk menghasilkan error atau menunjukkan anti-pattern.

Total blok yang diuji:

| Jenis blok | Jumlah |
|------------|--------|
| Runnable SQL blocks | 199 |
| Skipped instructional/error blocks | 47 |

## Verifikasi per lesson

| Lesson | Yang diuji | Hasil |
|--------|------------|-------|
| 1 | Materi konsep database, SQL, kategori statement, roadmap course | OK, tidak ada command untuk dieksekusi |
| 2 | Koneksi, `SHOW DATABASES`, `USE bookstore`, `CREATE TABLE books`, seed 15 books, `DESCRIBE books` | OK |
| 3 | `SELECT`, pemilihan kolom, alias, arithmetic expression, string functions, `NULL` helpers | OK |
| 4 | `WHERE`, comparison operators, `AND`/`OR`/`NOT`, `BETWEEN`, `IN`, `LIKE`, `IS NULL` | OK |
| 5 | `ORDER BY`, multi-column sort, `LIMIT`, `OFFSET`, `DISTINCT`, calculated sort | OK |
| 6 | `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING`, aggregate exercises | OK |
| 7 | `INSERT` single row, multi-row insert, `LAST_INSERT_ID()`, `authors`, `customers`, `categories` | OK |
| 8 | `UPDATE`, `DELETE`, safe select-before-write workflow, DML exercises | OK |
| 9 | `CREATE TABLE`, data types, constraints, `orders`, `reviews`, `employees` | OK |
| 10 | `ALTER TABLE`, add/modify/rename/drop columns, normalization, `author_id` backfill | OK |
| 11 | Foreign keys, `ON DELETE`, invalid FK insert, `order_items`, review FKs | OK, expected FK errors appeared |
| 12 | `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, multi-table reports, join exercises | OK |
| 13 | Subqueries, derived tables, correlated subqueries, `EXISTS`, `CREATE VIEW`, view queries | OK |
| 14 | Final review, schema recap, roadmap, next topics | OK, no command for execution |

## Detail pengujian fungsional

### Lesson 2 - struktur awal `books`

Course berhasil membuat tabel `books` dan mengisi 15 baris awal. Query dasar seperti `SELECT * FROM books`, `DESCRIBE books`, `SELECT VERSION()`, dan `SHOW DATABASES` berjalan dengan credential uji.

### Lesson 7 - data tambahan

Lesson 7 berhasil menambahkan data baru ke `books`, membuat dan mengisi `authors`, `customers`, serta `categories`. Setelah seluruh course dijalankan, tabel `books` berisi 20 baris karena ada data tambahan dari lesson dan exercise.

### Lesson 8 - perubahan data

Query `UPDATE` dan `DELETE` berjalan sesuai materi. Contoh safe workflow dengan `SELECT` sebelum `UPDATE`/`DELETE` dapat dijalankan. Data akhir berubah sesuai urutan lesson, termasuk penghapusan beberapa baris yang memang menjadi bagian dari materi DML.

### Lesson 11 - foreign key negative test

Dua error berikut muncul dan sesuai ekspektasi lesson:

```text
ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
```

Sumber error:

- `module-6-relationships-and-joins/lesson-11-foreign-keys-and-relationships.md:112`
- `module-6-relationships-and-joins/lesson-11-foreign-keys-and-relationships.md:282`

Keduanya berasal dari insert `orders.customer_id = 999`. Ini memang demonstrasi bahwa foreign key menolak order untuk customer yang tidak ada.

### Lesson 13 - views

Dengan privilege baru, semua view berhasil dibuat dan bisa di-query:

- `v_book_catalog`
- `v_order_summary`
- `v_customer_spending`
- `v_category_stats`

Bagian ini sebelumnya gagal jika credential tidak memiliki `CREATE VIEW` dan `SHOW VIEW`. Credential `learn_sql_user` sudah memenuhi kebutuhan tersebut.

## Status database akhir

Setelah semua blok utama dijalankan, database `bookstore` berisi:

| Objek | Jumlah / Status |
|-------|-----------------|
| `books` | 20 rows |
| `authors` | 6 rows |
| `customers` | 7 rows |
| `orders` | 12 rows |
| `reviews` | 4 rows |
| `order_items` | 0 rows |
| Views | 4 views |

Tabel akhir yang terbentuk:

- `authors`
- `books`
- `categories`
- `customers`
- `employees`
- `order_items`
- `orders`
- `reviews`

## Temuan penting

1. **Credential course harus menyertakan privilege view.** Lesson 13 menggunakan `CREATE VIEW`, jadi user database perlu `CREATE VIEW` dan `SHOW VIEW`, bukan hanya DML, DDL, dan `REFERENCES`.

2. **Negative test foreign key bekerja benar.** Insert dengan `customer_id = 999` ditolak oleh MySQL/MariaDB, sesuai penjelasan lesson 11.

3. **Course kompatibel dengan MariaDB 11.8.6.** Semua SQL utama berjalan di MariaDB lokal. Sintaks MySQL yang dipakai course tidak menimbulkan masalah pada environment uji.

4. **Lesson 2 membutuhkan konteks root/admin.** Pembuatan database `bookstore` dan user database tetap perlu dijalankan oleh root/admin terlebih dahulu. Setelah itu seluruh alur utama dapat dijalankan dengan `learn_sql_user`.

5. **Blok "Wrong" sebaiknya tidak dimasukkan ke script otomatis.** Beberapa section memang mengandung contoh salah untuk pembelajaran. Ini valid secara pedagogis, tetapi harus dipisahkan dari uji eksekusi alur utama.

## Catatan akurasi minor

- Course menyebut MySQL, sedangkan environment uji memakai MariaDB 11.8.6. Untuk scope SQL di course ini, hasilnya kompatibel.
- Lesson 5 sampai 13 sering menampilkan setup `mysql -u root -p` lalu `USE bookstore;`. Pada uji otomatis, koneksi langsung memakai `learn_sql_user` dan database `bookstore`.
- Exercise yang membuat dan menghapus database `testdb` tidak diuji dengan user course karena operasi tersebut berada di luar privilege database `bookstore.*` dan membutuhkan root/admin.

## Kesimpulan

Course **layak dipublikasikan dari sisi teknis**. Alur utama dari konsep awal, setup database, query dasar, filtering, sorting, aggregation, insert/update/delete, table design, foreign key, join, subquery, sampai view berhasil dijalankan menggunakan database `bookstore`.

Satu kebutuhan penting untuk dokumentasi credential adalah memastikan user course memiliki `CREATE VIEW` dan `SHOW VIEW`. Setelah privilege tersebut ditambahkan, seluruh bagian praktis course berjalan sesuai materi.
