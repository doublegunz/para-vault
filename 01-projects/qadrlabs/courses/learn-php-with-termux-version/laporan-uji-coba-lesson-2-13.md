# Laporan Uji Coba: Learn PHP for Beginners with Termux (Lesson 2-13)

Tanggal uji: 2026-06-22. Diuji di `sandbox/learn-php-termux-test/learn-php`
dengan PHP built-in server dan MySQL lokal. Lesson 1 ("What We Will Build")
dan Lesson 14 ("What's Next") tidak diuji karena tidak berisi langkah build
aplikasi.

## Ringkasan

| Lesson | Materi | Status |
|--------|--------|--------|
| L2 | Setup Termux, Apache, PHP file pertama | PASS |
| L3 | Variables dan data types | PASS |
| L4 | Operators dan control structures | PASS |
| L5 | Loops | PASS |
| L6 | Arrays | PASS |
| L7 | Functions | PASS |
| L8 | Forms, GET/POST, validation | PASS |
| L9 | Includes, shared header/footer/config | PASS |
| L10 | MariaDB/MySQL + PDO, schema, seed data | PASS |
| L11 | Read data, list/detail, JOIN | PASS |
| L12 | Create, update, delete, detail, PRG | PASS |
| L13 | Sessions, register, login, protected CRUD | PASS |

Semua file PHP yang terbentuk dari snippet course lolos `php -l`. Validasi
runtime dilakukan lewat `curl`, cookie jar untuk session, dan query langsung ke
MySQL.

## Lingkungan uji

| Komponen | Versi / Nilai |
|----------|---------------|
| PHP | 8.5.4 (NTS) |
| Database | MariaDB 11.8.6 |
| Web server uji | PHP built-in server `127.0.0.1:8092` |
| Lokasi project | `sandbox/learn-php-termux-test/learn-php` |
| DB name | `db_learn_php` |
| DB user | `learn_php_user` |

Course ditulis untuk Android + Termux + Apache + MariaDB. Uji coba ini
dijalankan di Linux, jadi langkah Termux seperti `pkg install`, `micro`, dan
`apachectl` diganti dengan tindakan CLI setara. Untuk database, dipakai
kredensial lokal yang sudah tersedia:

```php
$db_host = "127.0.0.1";
$db_name = "db_learn_php";
$db_user = "learn_php_user";
$db_pass = "password_yang_kuat";
```

## Verifikasi teknis

### Lint PHP

Semua file PHP hasil ekstraksi snippet Lesson 2 sampai 13 berhasil melewati:

```bash
find sandbox/learn-php-termux-test/learn-php -name '*.php' -print0 | xargs -0 -n1 php -l
```

Hasil: tidak ada syntax error.

### Database Lesson 10

Schema dibuat ulang sesuai SQL Lesson 10:

- `users`
- `entries`

`lesson-10/seed-data.php` mengembalikan HTTP 200 dan menghasilkan:

| Tabel | Jumlah |
|-------|--------|
| `users` | 1 |
| `entries` | 3 |

Data seed:

| User | Email |
|------|-------|
| Budi Santoso | `budi@example.com` |

Entry seed:

| ID | User ID | Title |
|----|---------|-------|
| 1 | 1 | My first entry |
| 2 | 1 | Learning PHP |
| 3 | 1 | Weekend plans |

### Lesson 9 includes

| Skenario | Hasil |
|----------|-------|
| `lesson-09/index.php` | HTTP 200 |
| `lesson-09/pages/about.php` | HTTP 200 |
| `lesson-09/pages/contact.php` | HTTP 200 |

Versi Termux sudah membuat halaman Contact di alur utama, jadi link navigasi
header tidak putus.

### Lesson 11 read/detail

| Skenario | Hasil |
|----------|-------|
| `lesson-11/list.php` | HTTP 200, entry tampil |
| `lesson-11/detail.php?id=1` | HTTP 200, detail entry tampil |

List, detail, prepared statement, JOIN author, dan escaping output berjalan
sesuai materi.

### Lesson 12 CRUD

| Skenario | Hasil |
|----------|-------|
| `lesson-12/list.php` | HTTP 200 |
| POST create valid | HTTP 302 ke list |
| `lesson-12/detail.php?id=4` setelah create | HTTP 200 |
| POST edit valid | HTTP 302 ke list |
| GET delete valid | HTTP 302 ke list |

Setelah create, edit, lalu delete entry uji, jumlah entry kembali ke 3. Lesson
12 versi Termux sudah membuat `detail.php` di alur utama, sehingga link Read
tidak putus.

### Lesson 13 auth dan protected CRUD

| Skenario | Hasil |
|----------|-------|
| Guest akses `lesson-13/list.php` | HTTP 302 ke login |
| Guest akses `lesson-13/create.php` | HTTP 302 ke login |
| Guest akses `lesson-13/edit.php?id=1` | HTTP 302 ke login |
| Guest akses `lesson-13/delete.php?id=1` | HTTP 302 ke login |
| Login Budi (`budi@example.com` / `password123`) | HTTP 302 ke list |
| Budi akses list | HTTP 200, melihat entry miliknya |
| Budi create entry dari protected `create.php` | HTTP 302 ke list |
| Budi edit entry miliknya dari protected `edit.php` | HTTP 302 ke list |
| Register user baru `andi-termux-fixed@example.com` | HTTP 302 ke list dan auto-login |
| User baru create entry dari protected `create.php` | HTTP 302 ke list |
| Budi akses `edit.php?id=5` milik Andi | HTTP 200, `Entry not found` |
| Budi akses `delete.php?id=5` milik Andi | HTTP 200, `Entry not found` |
| Budi delete entry miliknya sendiri | HTTP 302 ke list |

Data akhir setelah register:

| ID | Name | Email |
|----|------|-------|
| 1 | Budi Santoso | `budi@example.com` |
| 2 | Andi | `andi-termux-fixed@example.com` |

Scoping `WHERE user_id = :user_id` pada `list.php`, `edit.php`, dan
`delete.php` terbukti bekerja: Budi melihat entry miliknya, tidak melihat entry
Andi, dan tidak bisa edit/delete entry Andi lewat URL langsung.

## Temuan yang perlu diperbaiki

### 1. Lesson 13 `list.php` menautkan `create.php`, `edit.php`, dan `delete.php`, tetapi alur utama tidak membuat file-file itu (SUDAH DIPERBAIKI)

`lesson-13/list.php` menampilkan link berikut:

```php
<p><a href="create.php">+ Write New Entry</a></p>
<a href="edit.php?id=<?= $entry['id'] ?>">Edit</a>
<a href="delete.php?id=<?= $entry['id'] ?>">Delete</a>
```

Namun alur utama Lesson 13 hanya membuat:

- `session-demo.php`
- `register.php`
- `login.php`
- `logout.php`
- `list.php`

`create.php` baru muncul sebagai Exercise 1 solution, bukan alur utama.
`edit.php` dan `delete.php` tidak dibuat di alur utama maupun solution.

Hasil uji setelah login:

```text
GET /learn-php/lesson-13/create.php -> 404
GET /learn-php/lesson-13/edit.php?id=1 -> 404
GET /learn-php/lesson-13/delete.php?id=1 -> 404
```

Update 2026-06-22: perbaikan sudah diterapkan. Lesson 13 sekarang membuat
protected `create.php`, `edit.php`, dan `delete.php` di alur utama. Query
protected edit/delete memakai filter `WHERE id = :id AND user_id = :user_id`,
dan Exercise 1 dipindahkan menjadi protected `detail.php`. Retest menunjukkan
link `create.php`, `edit.php`, dan `delete.php` tidak lagi 404.

Catatan tambahan dari retest: query update awal sempat memakai kolom
`updated_at`, tetapi schema Lesson 10 tidak membuat kolom itu. Query `edit.php`
sudah disesuaikan agar hanya memperbarui `title` dan `content`.

## Hal yang sudah benar dan terverifikasi

- **Termux flow jelas:** instruksi memakai `micro`, `localhost:8080`, dan MariaDB
  terminal sesuai konteks Android.
- **Lesson 9 lengkap:** Home, About, dan Contact semua dibuat.
- **Lesson 12 lengkap:** list, create, detail, edit, dan delete semua dibuat dan
  saling terhubung.
- **PDO aman:** query dengan input eksternal memakai prepared statement.
- **Password hashing:** seed/register memakai `password_hash()`, login memakai
  `password_verify()`.
- **Session guard:** protected list mengalihkan guest ke login.
- **Data isolation:** list, edit, dan delete Lesson 13 hanya mengambil atau
  mengubah entry milik user login.

## Kesimpulan

Course **Learn PHP for Beginners with Termux** sekarang berjalan baik sampai
Lesson 13. Versi Termux sudah lebih lengkap pada Lesson 9 dan Lesson 12
dibanding temuan course PHP desktop sebelumnya, dan temuan Lesson 13 terkait
protected CRUD sudah diperbaiki serta diuji ulang.


codex resume 019eed09-ae0f-7c73-b474-36ffd1146671