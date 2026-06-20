# Laporan Uji Coba: Learn PHP OOP for Beginners (Lesson 2-13)

Tanggal uji: 2026-06-20. Diuji end-to-end di `sandbox/catatku-oop` (di luar
vault, repo git tersendiri, satu branch + commit per lesson, plus seluruh
Exercises/Solutions tiap lesson). Mulai dari Lesson 2 (setup project) sampai
Lesson 13. Lesson 1 ("What We Will Build") dan Lesson 14 ("What's Next") tanpa
kode, jadi tidak diuji.

## Ringkasan

| Lesson | Materi | Status |
|--------|--------|--------|
| L2 | Setup project, Composer PSR-4, dev server | PASS |
| L3 | Class & object (Entry), method | PASS |
| L4 | Constructor & encapsulation (private + getter/setter) | PASS |
| L5 | Namespace & autoloading (User, Database placeholder) | PASS |
| L6 | Koneksi MySQL PDO (Singleton), config, schema | PASS |
| L7 | Repository pattern (Entry/UserRepository, seed) | PASS |
| L8 | Front controller & Router, controller, template | PASS |
| L9 | View class & shared layout (output buffering) | PASS (1 temuan) |
| L10 | Form create + CSRF + validasi | PASS |
| L11 | Edit & delete + ownership check | PASS |
| L12 | Autentikasi (register/login/logout, route guard) | PASS (1 catatan) |
| L13 | Inheritance, interface, abstract (Base classes) | PASS |

Semua langkah kode pada alur utama tiap lesson berjalan sesuai yang dijanjikan,
begitu juga seluruh Exercises/Solutions, kecuali satu exercise di L9 yang memang
keliru ketika ditulis (lihat Temuan #1). Verifikasi dilakukan lewat `curl`
(cookie jar + ekstraksi token CSRF dari form) dan query langsung ke MySQL.

## Lingkungan uji (berbeda dari instruksi lesson)

Course ditulis untuk **Windows + Laragon + HeidiSQL + VS Code**, sedangkan uji
coba dijalankan di **Linux** tanpa browser. Penyesuaian yang dipakai (tidak
mengubah logika aplikasi):

- **OS/tooling:** langkah "buka Laragon/HeidiSQL/VS Code, klik kanan New File"
  diganti setara CLI. Server dijalankan `php -S localhost:8080 -t public`,
  pengujian UI digantikan `curl` (status code + potongan HTML + ekstraksi token
  CSRF), pengecekan data lewat PDO/`mysql` langsung.
- **PHP:** hanya tersedia **PHP 8.5.4**. Lesson menyebut PHP 8.3. Seluruh kode
  course berjalan **tanpa error maupun deprecation** di PHP 8.5 (named arguments,
  constructor promotion, nullable types `?string`, covariant return, return type
  `never`, `mixed` pada interface semuanya aman). **Composer 2.10.0** tersedia.
- **Database:** lesson memakai `db_catatku` dengan user `root` password kosong.
  Di mesin uji, MySQL/MariaDB `root` butuh sudo interaktif, jadi dipakai
  kredensial khusus course yang sudah disiapkan
  (`00-inbox/membuat credentials untuk database mysql.md`):
  ```php
  // config/database.php
  'database' => 'db_php_oop',
  'username' => 'oop_user',
  'password' => 'password_yang_kuat',
  ```
  Tidak memengaruhi materi; pembaca tetap mengikuti `db_catatku`/`root`.

## Konvensi Git

Repo di dalam `sandbox/catatku-oop` (sandbox di-gitignore dari vault). Branch
utama `main`, satu branch per lesson (`oop/lesson-02` .. `oop/lesson-13`), commit
di akhir tiap lesson (mencakup alur utama + exercises lesson tersebut), lalu
`git merge --no-ff` ke `main`. Total 12 commit lesson + 11 merge = 23 commit.
Trailer: `Co-Authored-By: Claude Opus 4.8`.

## Temuan yang perlu diperbaiki di materi

> **Update 2026-06-20:** Kelima temuan di bawah SUDAH DIPERBAIKI langsung di file
> lesson. Ringkasan: (#1) definisi `e()` dipindah ke `public/index.php` di
> Exercise 3 L9; (#2) pembuatan `templates/errors/404.php` ditambahkan ke alur
> utama L12 (Section 3 Step 4); (#3) seed L7 dibuat idempoten (DELETE dulu) plus
> note di L6 Exercise 2; (#4) callout script latihan usang ditambah di L4; (#5)
> Exercise 3 L13 diarahkan ke `public/test-count.php`, bukan `public/index.php`.

### 1. (PENTING, SUDAH DIPERBAIKI) Exercise 3 Lesson 9 (`e()` helper) salah lokasi, bikin fatal error

Exercise 3 L9 menyuruh mendefinisikan helper `e()` **di bagian atas
`templates/layouts/main.php`**, lalu "replace all `htmlspecialchars()` calls in
the templates with the shorter `e()`". Jika dijalankan apa adanya, halaman yang
memakai `e()` di **child template** akan fatal:

```
PHP Fatal error: Uncaught Error: Call to undefined function e()
```

Penyebabnya ada di desain `View::render()` sendiri: child template di-`require`
dan ditangkap dengan output buffering **sebelum** layout di-`require`. Padahal
`e()` baru didefinisikan di dalam layout, sehingga saat child template
dieksekusi, fungsi `e()` belum ada.

```php
// src/View.php
ob_start();
require __DIR__ . '/../templates/' . $template . '.php';  // child jalan duluan -> e() belum ada
$content = ob_get_clean();
if ($layout) {
    require __DIR__ . '/../templates/' . $layout . '.php'; // e() baru didefinisikan di sini
}
```

Saran perbaikan: definisikan `e()` di tempat yang dimuat **sebelum** template apa
pun dirender, mis. di front controller `public/index.php` (setelah autoload),
atau di file helper yang di-autoload Composer lewat `"files"`. Pada uji coba ini
`e()` didefinisikan di `public/index.php` dan terbukti bekerja di semua template.
Sebagai alternatif, redaksi exercise bisa membatasi penggunaan `e()` hanya di
file layout (di mana fungsi itu memang sudah terdefinisi).

### 2. (SUDAH DIPERBAIKI) Handler 404 di Lesson 12 bergantung pada solusi Exercise Lesson 9

Mulai Lesson 12, handler 404 di `Router::dispatch()` memanggil:

```php
\App\View::render('errors/404', [], 'layouts/main');
```

tetapi file `templates/errors/404.php` **hanya dibuat di Exercise 1 Lesson 9**,
bukan di alur utama L9. Artinya pembaca yang hanya mengikuti alur utama (skip
exercises) akan mendapat fatal error setiap kali halaman 404 dipanggil sejak L12.
Saran: pindahkan pembuatan `templates/errors/404.php` ke alur utama (mis. di L9
atau L12), atau tambahkan catatan bahwa handler 404 baru ini mensyaratkan file
tersebut. (Pola temuan yang sama pernah muncul di course Laravel beginner.)

### 3. (SUDAH DIPERBAIKI) Seed Lesson 7 bentrok dengan seed Exercise Lesson 6

Exercise 2 Lesson 6 membuat `config/seed.php` yang meng-insert
`budi@example.com`. Lalu Lesson 7 (alur utama) menimpa `config/seed.php` dengan
versi berbasis repository yang **juga** meng-insert `budi@example.com`. Karena
kolom `email` UNIQUE, menjalankan seed L7 setelah seed L6 akan gagal duplicate.
Catatan "run this once" di L7 tidak memperhitungkan bahwa seed L6 (kalau exercise
dikerjakan) sudah lebih dulu memasukkan Budi. Pada uji ini tabel di-`TRUNCATE`
dulu sebelum seed L7. Saran: samakan email atau ingatkan untuk mengosongkan
tabel sebelum menjalankan seed L7.

### 4. (SUDAH DIPERBAIKI) Script latihan standalone dari lesson awal jadi rusak setelah refactor

Karena tiap lesson sering "replace the entire content" sebuah class, file
latihan standalone dari lesson sebelumnya bisa rusak diam-diam. Contoh konkret:
`public/test-objects.php` (Exercise 3 Lesson 3) memakai assignment properti
publik (`$entry->id = 1; ...`). Setelah Lesson 4 mengubah `Entry` jadi
private + constructor wajib, file itu menghasilkan HTTP 500:

```
ArgumentCountError: Too few arguments to function App\Models\Entry::__construct()
```

Ini wajar sebagai konsekuensi desain course, tapi tidak pernah disinggung. Saran
ringan: beri catatan bahwa script latihan lama bisa usang setelah refactor, atau
minta pembaca menghapusnya.

### 5. Catatan kecil (tidak menggagalkan)

- **Exercise 3 Lesson 13 (SUDAH DIPERBAIKI)** menyuruh memanggil
  `$entryRepo->count()` dan `$userRepo->count()` "in `public/index.php`". Padahal
  sejak L8 `public/index.php` sudah jadi front controller (router), bukan file
  scratch. Sudah diarahkan ke `public/test-count.php`. Pada uji ini `count()`
  diverifikasi lewat CLI (hasil benar: entries=5, users=3).
- **Route exercise L8** (`/about` dan `/entries/{id}/json`) ikut hilang ketika
  `public/index.php` ditulis ulang utuh di L9 dan L12. Wajar untuk gaya "replace
  entire content", tapi perlu disadari pembaca.
- **Urutan tabel L6 benar:** `users` dibuat sebelum `entries` dalam satu skrip,
  jadi tidak ada masalah urutan foreign key seperti pada course berbasis
  migration (Laravel/CI4) sebelumnya.

## Hal yang sudah benar dan terverifikasi

- **CSRF**: token sesi diverifikasi pada semua POST (create/update/delete/
  duplicate/register/login/change-password); token salah -> 403. Terverifikasi.
- **Ownership**: `findOwnedEntry()` menolak akses entry milik user lain -> 403
  (diuji dengan menyisipkan user kedua + entry-nya).
- **Auth & route guard**: guest ke `/entries` -> redirect `/login`; user login
  ke `/login` -> redirect `/entries`; pesan login salah sengaja samar
  ("incorrect"); `session_regenerate_id(true)` dipanggil setelah login/register.
- **Scoping per user**: `index()` memakai `findByUserId()`; user baru melihat
  "No entries yet", Budi hanya melihat 4 entry miliknya (bukan entry user lain).
- **Password**: `password_hash`/`password_verify` bekerja; login dengan user
  hasil seed (`budi@example.com` / `password123`) sukses; change-password
  meng-update hash dan memvalidasi konfirmasi.
- **OOP L13**: `new BaseRepository()` ditolak (Cannot instantiate abstract
  class); `Entry` dan `User` `instanceof Renderable`; `count()` warisan jalan di
  kedua repository; refactor `BaseController` tidak merusak satu pun route
  (home/auth/CRUD/404/logout semua hijau).

## Kesimpulan

Course PHP OOP ini solid dan konsisten secara teknis: seluruh alur build dari
nol (Composer/PSR-4 -> class/encapsulation -> PDO/Repository -> Router/MVC ->
View engine -> CRUD+CSRF -> auth -> base classes) berjalan persis seperti yang
diajarkan, termasuk di PHP 8.5. Yang perlu diperbaiki utamanya **Temuan #1**
(exercise `e()` yang fatal karena urutan render layout) dan **Temuan #2** (file
`errors/404.php` yang dibutuhkan alur utama L12 tapi cuma ada di exercise L9).
Temuan #3 dan #4 sifatnya minor/kosmetik tapi sebaiknya diberi catatan agar
pembaca tidak bingung.
