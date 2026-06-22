# Laporan Uji Coba: Learn PHP for Beginners (Lesson 2-13)

Tanggal uji: 2026-06-22. Diuji di `sandbox/learn-php-test/learn-php`
dengan PHP built-in server dan MySQL lokal. Lesson 1 ("What We Will Build")
dan Lesson 14 ("What's Next") tidak diuji karena tidak berisi langkah build
aplikasi.

## Ringkasan

| Lesson | Materi | Status |
|--------|--------|--------|
| L2 | Setup environment, echo, PHP + HTML | PASS |
| L3 | Variables dan data types | PASS |
| L4 | Operators dan control structures | PASS |
| L5 | Loops | PASS |
| L6 | Arrays | PASS |
| L7 | Functions | PASS |
| L8 | Forms, GET/POST, validation, XSS escaping | PASS |
| L9 | Includes, shared header/footer/config | PASS (1 temuan minor) |
| L10 | MySQL + PDO, schema, seed data | PASS |
| L11 | Read data, list/detail, JOIN | PASS |
| L12 | Create, update, delete, PRG | PASS (1 temuan penting) |
| L13 | Sessions, register, login, logout, protected list | PASS (1 temuan penting) |

Semua file PHP utama yang terbentuk dari snippet course lolos `php -l`.
Validasi runtime dilakukan lewat `curl`, cookie jar untuk session, dan query
langsung ke MySQL.

## Lingkungan uji

| Komponen | Versi / Nilai |
|----------|---------------|
| PHP | 8.5.4 (NTS) |
| Database | MariaDB 11.8.6 |
| Web server | PHP built-in server `127.0.0.1:8091` |
| Lokasi project | `sandbox/learn-php-test/learn-php` |
| DB name | `db_learn_php` |
| DB user | `learn_php_user` |

Course ditulis untuk Windows + Laragon + VS Code + HeidiSQL. Uji coba ini
dijalankan di Linux. Langkah GUI Laragon/HeidiSQL/VS Code diganti dengan CLI
setara: file dibuat di sandbox, server dijalankan dengan `php -S`, request
diuji dengan `curl`, dan database diperiksa memakai `mysql`.

Konfigurasi database disesuaikan dari contoh course:

```php
$db_host = "127.0.0.1";
$db_name = "db_learn_php";
$db_user = "learn_php_user";
$db_pass = "password_yang_kuat";
```

## Verifikasi teknis

### Lint PHP

Semua file utama Lesson 2 sampai 13 yang terbentuk dari snippet course berhasil
melewati syntax check:

```bash
find sandbox/learn-php-test/learn-php -name '*.php' -print0 | xargs -0 -n1 php -l
```

Hasil: tidak ada syntax error.

### Database Lesson 10

Schema dibuat ulang sesuai SQL Lesson 10 di `db_learn_php`:

- `users`
- `entries`

`lesson-10/test-connection.php` mengembalikan HTTP 200 dan mendeteksi 2 tabel.
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

### Read dan detail Lesson 11

| Skenario | Hasil |
|----------|-------|
| `lesson-11/list.php` | HTTP 200, entry tampil |
| `lesson-11/detail.php?id=1` | HTTP 200, detail entry tampil |
| `lesson-11/detail.php?id=999` | HTTP 200, menampilkan "Entry Not Found" |

Validasi ID, prepared statement, JOIN ke `users`, dan handling record tidak
ditemukan berjalan sesuai materi.

### CRUD Lesson 12

| Skenario | Hasil |
|----------|-------|
| GET `create.php` | HTTP 200 |
| POST create tanpa title | HTTP 200, muncul `Title is required.` |
| POST create valid | HTTP 302 ke list |
| POST edit valid | HTTP 302 ke list |
| GET delete valid | HTTP 302 ke list |

Setelah create, edit, lalu delete entry uji, jumlah entry kembali ke 3. Pola
Post/Redirect/Get terbukti berjalan karena write operation mengembalikan redirect
302, bukan render langsung.

### Auth dan session Lesson 13

| Skenario | Hasil |
|----------|-------|
| Guest akses `lesson-13/list.php` | HTTP 302 ke login |
| Login Budi (`budi@example.com` / `password123`) | HTTP 302 ke list |
| Budi akses list | HTTP 200, melihat 3 entry miliknya |
| Logout | HTTP 302 ke login |
| Register user baru `andi@example.com` | HTTP 302 ke list dan auto-login |
| Andi akses list | HTTP 200, list kosong |

Data akhir setelah register:

| ID | Name | Email |
|----|------|-------|
| 1 | Budi Santoso | `budi@example.com` |
| 2 | Andi | `andi@example.com` |

Scoping `WHERE user_id = :user_id` pada list Lesson 13 terbukti bekerja:
Budi melihat 3 entry, user baru Andi melihat list kosong.

### Form dan XSS Lesson 8

`form-get.php` diuji dengan input:

```text
<script>alert(1)</script>
```

Output halaman menampilkan input sebagai teks escaped:

```html
&lt;script&gt;alert(1)&lt;/script&gt;
```

Artinya penggunaan `htmlspecialchars()` pada output user input berjalan sesuai
materi.

## Temuan yang perlu diperbaiki di materi

> Update 2026-06-22: ketiga temuan di bawah sudah diperbaiki langsung di file
> lesson. Ringkasan: Lesson 9 sekarang membuat `pages/contact.php`; Lesson 12
> sekarang membuat `detail.php`; Lesson 13 sekarang membuat protected
> `create.php`, `edit.php`, dan `delete.php` di alur utama.

### 1. (SUDAH DIPERBAIKI) Lesson 12 `list.php` menautkan `detail.php`, tetapi Lesson 12 tidak membuat file itu

`lesson-12/list.php` berisi link:

```php
<a href="detail.php?id=<?= $entry['id'] ?>">Read</a>
```

Namun alur Lesson 12 hanya membuat:

- `create.php`
- `list.php`
- `edit.php`
- `delete.php`

Tidak ada instruksi membuat atau menyalin `detail.php` dari Lesson 11 ke folder
Lesson 12. Saat diuji:

```text
GET /learn-php/lesson-12/detail.php?id=1 -> 404
```

Perbaikan: Lesson 12 sekarang menambahkan Step 5 untuk membuat
`lesson-12/detail.php`. Setelah diuji ulang, `lesson-12/detail.php?id=1`
mengembalikan HTTP 200 dan `lesson-12/detail.php?id=999` menampilkan pesan
not found yang benar.

### 2. (SUDAH DIPERBAIKI) Lesson 13 `list.php` menautkan `create.php`, `edit.php`, dan `delete.php`, tetapi alur utama tidak membuat file-file itu

`lesson-13/list.php` menampilkan link:

```php
<a href="create.php">+ Write New Entry</a>
<a href="edit.php?id=<?= $entry['id'] ?>">Edit</a>
<a href="delete.php?id=<?= $entry['id'] ?>">Delete</a>
```

Namun alur utama Lesson 13 hanya membuat:

- `session-demo.php`
- `register.php`
- `login.php`
- `logout.php`
- `list.php`

Instruksi membuat protected `create.php` baru muncul di bagian Exercise 1, bukan
alur utama. Tidak ada instruksi membuat protected `edit.php` dan `delete.php`.
Saat diuji setelah login:

```text
GET /learn-php/lesson-13/create.php -> 404
GET /learn-php/lesson-13/edit.php?id=1 -> 404
```

Perbaikan: Lesson 13 sekarang membuat protected `create.php`, `edit.php`, dan
`delete.php` di alur utama setelah protected list. Ketiga file memakai
`session_start()`, auth guard, dan filter `user_id`. Setelah diuji ulang, guest
ke `create.php` redirect ke login; user login bisa create, edit, dan delete
entry sendiri; user lain mendapat "Entry not found" ketika mencoba edit/delete
entry yang bukan miliknya.

### 3. (SUDAH DIPERBAIKI) Lesson 9 header menampilkan link Contact, tetapi course tidak membuat halaman contact

`includes/header.php` menambahkan:

```html
<a href="/learn-php/lesson-09/pages/contact.php">Contact</a>
```

Materi membuat `pages/about.php`, tetapi tidak ada langkah membuat
`pages/contact.php`. Di server Apache/Laragon, link ini kemungkinan menjadi 404.
Pada PHP built-in server, path missing sempat jatuh balik ke `index.php`, jadi
status HTTP saja bisa menyesatkan. Secara struktur file, `contact.php` memang
tidak dibuat.

Perbaikan: Lesson 9 sekarang menambahkan instruksi membuat
`pages/contact.php`. Setelah diuji ulang, halaman tersebut mengembalikan HTTP
200 dan memakai shared header/footer yang sama.

## Hal yang sudah benar dan terverifikasi

- **PDO config terpusat:** `config.php` bisa dipakai lintas lesson dengan
  `require_once __DIR__ . '/../config.php'`.
- **Prepared statements:** query dengan input eksternal pada detail, create,
  edit, login, dan register memakai prepared statement.
- **Password hashing:** seed dan register memakai `password_hash()`, login
  memakai `password_verify()`.
- **Validation:** create form menolak title kosong dan mempertahankan input lama.
- **PRG:** create/edit/delete Lesson 12 redirect setelah operasi tulis.
- **Session guard:** protected list Lesson 13 mengalihkan guest ke login.
- **Data isolation:** list Lesson 13 hanya menampilkan entry milik user login.
- **Output escaping:** form dan output database memakai `htmlspecialchars()` pada
  titik-titik penting.

## Kesimpulan

Course **Learn PHP for Beginners** layak dari sisi alur pembelajaran dasar:
materi PHP procedural, forms, includes, PDO, CRUD, dan session authentication
berjalan di PHP 8.5 dengan MySQL/MariaDB. Bagian inti database dan auth terbukti
berfungsi dengan kredensial `db_learn_php`.

Tiga temuan link/alur file missing sudah diperbaiki dan divalidasi ulang. Status
akhir: Lesson 9, Lesson 12, dan Lesson 13 tidak lagi memiliki link utama yang
mengarah ke file yang belum dibuat dalam alur tutorial.
