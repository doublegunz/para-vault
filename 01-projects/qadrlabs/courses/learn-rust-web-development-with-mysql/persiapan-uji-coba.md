# Persiapan Uji Coba Course Rust Web + MySQL

Catatan setup lingkungan untuk menguji lesson course `learn-rust-web-development-with-mysql` di `sandbox/`. Kredensial di bawah adalah contoh untuk sandbox lokal, bukan kredensial produksi.

| Item | Nilai |
| --- | --- |
| Database utama | `db_rust_todo` |
| User MySQL | `todo_user` |
| Password | `todo_password` |
| Database test (`#[sqlx::test]`) | otomatis, berawalan `_sqlx_test` |
| Project utama | `sandbox/todo-web` |
| Contoh kecil per lesson | `sandbox/rust-web-lessons/` |

## 1. Buat Database dan User

Masuk ke MariaDB/MySQL sebagai root:

```bash
sudo mysql
```

Lalu jalankan SQL berikut:

```sql
CREATE DATABASE IF NOT EXISTS db_rust_todo
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'todo_user'@'localhost' IDENTIFIED BY 'todo_password';

-- Akses penuh ke database aplikasi
GRANT ALL PRIVILEGES ON db_rust_todo.* TO 'todo_user'@'localhost';

-- Untuk #[sqlx::test] (Lesson 18): sqlx membuat database _sqlx_test dan _sqlx_test_<n>
GRANT ALL PRIVILEGES ON `\_sqlx\_test%`.* TO 'todo_user'@'localhost';

FLUSH PRIVILEGES;
EXIT;
```

Versi satu baris (bisa dijalankan dari prompt Claude Code dengan awalan `!`):

```bash
sudo mysql -e "CREATE DATABASE IF NOT EXISTS db_rust_todo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; CREATE USER IF NOT EXISTS 'todo_user'@'localhost' IDENTIFIED BY 'todo_password'; GRANT ALL PRIVILEGES ON db_rust_todo.* TO 'todo_user'@'localhost'; GRANT ALL PRIVILEGES ON \`\\_sqlx\\_test%\`.* TO 'todo_user'@'localhost'; FLUSH PRIVILEGES;"
```

## 2. Verifikasi Koneksi

```bash
mysql -u todo_user -ptodo_password -e "SELECT CURRENT_USER(); SHOW GRANTS;"
mysql -u todo_user -ptodo_password -e "SHOW DATABASES;"
```

Yang diharapkan: `CURRENT_USER()` berisi `todo_user@localhost`, `SHOW GRANTS` menampilkan dua grant di atas, dan `db_rust_todo` muncul di daftar database.

## 3. Install sqlx-cli

Sudah terpasang di mesin ini (2026-11-01). Perintah untuk memasang ulang:

```bash
cargo install sqlx-cli --no-default-features --features mysql,rustls
sqlx --version
```

## 4. File .env Project

Di `sandbox/todo-web/.env`:

```bash
DATABASE_URL=mysql://todo_user:todo_password@localhost:3306/db_rust_todo
```

Cek dari sqlx-cli:

```bash
cd ~/obsidian-vault/sandbox/todo-web
sqlx database create   # aman jika database sudah ada
sqlx migrate info      # muncul setelah folder migrations dibuat (Lesson 8)
```

## 5. Unduh dan Build Dependency

Project utama (`sandbox/todo-web`) sudah selesai sampai Lesson 19, dengan satu commit git per lesson (`git log --oneline`). Dependency: axum 0.8.9, tokio 1.54.1, sqlx 0.9.0, askama 0.16.1, serde, dotenvy, chrono, tracing, tracing-subscriber, tower-http 0.7.1, dan tower 0.5.3 (dev). Build pertama mengunduh crate dan folder `target/` berukuran sekitar 3 GB (debug, test, dan release).

```bash
cd ~/obsidian-vault/sandbox/todo-web
cargo fetch      # hanya unduh crate
cargo build      # compile semua dependency
du -sh target    # cek ukuran hasil build
```

Untuk melihat kode di akhir lesson tertentu: `git checkout <hash-commit-lesson>` lalu kembali dengan `git checkout master`. Contoh kecil Lesson 1 dan 2 ada di `sandbox/rust-web-lessons/raw-http` dan `sandbox/rust-web-lessons/async-basics`.

## 6. Reset dan Bersih-Bersih

Reset isi database (hapus semua tabel lalu jalankan ulang migration):

```bash
cd ~/obsidian-vault/sandbox/todo-web
sqlx database reset -y
```

Lihat database test sisa `#[sqlx::test]` (hapus dengan `DROP DATABASE <nama>;` bila perlu):

```bash
mysql -u todo_user -ptodo_password -N -e "SHOW DATABASES LIKE '\_sqlx\_test%';"
```

Kosongkan hasil build untuk menghemat disk:

```bash
cargo clean
```

Hapus semuanya setelah course selesai diuji:

```bash
sudo mysql -e "DROP DATABASE IF EXISTS db_rust_todo; DROP USER IF EXISTS 'todo_user'@'localhost'; FLUSH PRIVILEGES;"
```
