# Laporan Uji Coba Course "Learn CodeIgniter 3" (Lesson 1-14)

**Tanggal uji:** 2026-06-19  
**Penguji:** Codex  
**Hasil keseluruhan:** PASS dengan catatan penting pada Lesson 12.

Course berhasil dijalankan end-to-end di `sandbox/ci3-blog` menggunakan repo git tersendiri, satu branch per lesson. Runtime uji memakai PHP 7.4 karena PHP default OS adalah PHP 8.5 dan CodeIgniter 3 tidak cocok dijadikan target uji utama di PHP 8.5.

## Environment

| Komponen | Versi / Nilai |
|----------|---------------|
| CodeIgniter | 3.1.13 dari `bcit-ci-CodeIgniter-3.1.13-0-gbcb17eb.zip` |
| Runtime PHP uji | PHP 7.4.33 (`/home/linuxbrew/.linuxbrew/opt/php@7.4/bin/php`) |
| PHP default OS | PHP 8.5.4, tidak dipakai untuk menjalankan CI3 |
| Database | MariaDB 11.8.6 |
| Lokasi project | `sandbox/ci3-blog` |
| DB name | `db_ci3` |
| DB user | `ci3_user` |
| Server uji | `php -S 127.0.0.1:8000 index.php` |

## Verifikasi per lesson

| Lesson | Yang diuji | Hasil |
|--------|------------|-------|
| 1 | Review konsep CI3, MVC, roadmap course | PASS |
| 2 | Extract CI3, `base_url`, `.htaccess`, autoload helper/library, welcome page | PASS dengan adaptasi DB config awal |
| 3 | `Posts` controller, `index` dan `show`, view `posts/index` dan `posts/show` | PASS |
| 4 | Default controller, custom routes, clean URL `/posts/1` | PASS |
| 5 | Tabel `posts`, seed 3 post, database config, listing dari MySQL | PASS |
| 6 | `Post_model`, Query Builder, 404 untuk post tidak ada | PASS |
| 7 | Tampilan read/list/detail, action links, status badge, flash placeholder | PASS |
| 8 | Create form, form validation, slug generation, insert post | PASS |
| 9 | Edit form, update validation, update title/content/status/slug | PASS |
| 10 | Delete method, redirect, row terhapus, deleted detail 404 | PASS |
| 11 | Header/footer template partial, semua view memakai layout | PASS |
| 12 | Auth controller/model/view, login/logout, route protection, navbar session | PASS dengan bug credential di materi |
| 13 | Checklist end-to-end full CRUD + auth | PASS |
| 14 | Review dan next steps, tanpa perubahan kode | PASS |

## Detail pengujian fungsional

### Lesson 5 - database

- `posts` dibuat dengan kolom `id, title, slug, content, status, created_at, updated_at`.
- Seed 3 row berhasil:
  - `Getting Started with CodeIgniter`
  - `Understanding MVC Pattern`
  - `Query Builder in CI3`
- `/posts` menampilkan data dari MySQL tanpa PHP error setelah session path diset.

### Lesson 8 sampai 10 - CRUD

- POST kosong ke `/posts/store` menampilkan error validasi untuk `title`, `content`, dan `status`.
- POST valid membuat post baru, redirect ke `/posts`, count naik 3 ke 4, slug `course-test-post`.
- POST update ke `/posts/update/4` mengubah title, content, status, dan slug menjadi `course-test-post-edited`.
- GET `/posts/delete/4` redirect ke `/posts`, count turun 4 ke 3, `/posts/4` menjadi 404.

### Lesson 12 sampai 13 - auth dan full flow

- Guest akses `/posts/create` redirect ke `/auth/login`.
- Login page dan validasi kosong berjalan.
- Login berhasil dengan `admin@example.com` dan password `password`, lalu navbar menampilkan `Create`, `Admin`, dan `Logout`.
- Authenticated user bisa create, update, delete.
- Logout menghancurkan session dan redirect ke `/auth/login`.

## Temuan yang perlu diperbaiki di materi

### 1. Hash password Lesson 12 tidak cocok dengan narasi

Materi menyebut user test memakai:

```text
admin@example.com / password123
```

Namun hash yang disediakan:

```text
$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
```

tidak cocok dengan `password123`. Pada uji coba, `password123` redirect balik ke `/auth/login`, sedangkan password `password` berhasil login.

Saran perbaikan: ganti narasi menjadi `admin@example.com / password`, atau ganti hash SQL dengan hash dari `password_hash('password123', PASSWORD_DEFAULT)`.

### 2. Lesson 2 meng-autoload database sebelum database config dijelaskan

Lesson 2 meminta:

```php
$autoload['libraries'] = array('database', 'session');
```

Tetapi database config baru dijelaskan pada Lesson 5. Jika `database.php` masih default, halaman langsung error saat database library diload. Dalam uji ini credential `db_ci3` dikonfigurasi lebih awal supaya Lesson 2 sampai Lesson 4 tetap bisa diuji via browser.

Saran perbaikan: pindahkan autoload `database` ke Lesson 5, atau tambahkan instruksi konfigurasi database minimal sebelum meng-autoload database.

### 3. PHP 7.4 Homebrew membutuhkan session save path eksplisit

Dengan PHP 7.4 Homebrew, `session.save_path` kosong sehingga CI3 session driver mengeluarkan warning:

```text
mkdir(): Invalid path
session_start(): Failed to initialize storage module: user (path: )
```

Uji coba diselesaikan dengan:

```php
$config['sess_save_path'] = APPPATH.'cache/sessions';
```

dan folder `application/cache/sessions/` dibuat. Ini bukan bug utama materi Laragon/Windows, tetapi berguna sebagai catatan lintas environment.

## Catatan environment

- Clean URL `/posts/1` berhasil dengan server PHP built-in karena server dijalankan memakai router script `index.php`.
- Redirect CI3 menghasilkan kombinasi status `303 See Other` untuk POST redirect dan `307 Temporary Redirect` untuk GET redirect. Perilaku fungsionalnya benar karena header `Location` sesuai.
- CSRF tidak diaktifkan di materi, sehingga POST via `curl` tanpa token diterima. Ini konsisten dengan config default CI3.

## Catatan git

Repo sandbox: `sandbox/ci3-blog`.

Branch lesson yang dibuat:

```text
ci3/lesson-01
ci3/lesson-02
ci3/lesson-03
ci3/lesson-04
ci3/lesson-05
ci3/lesson-06
ci3/lesson-07
ci3/lesson-08
ci3/lesson-09
ci3/lesson-10
ci3/lesson-11
ci3/lesson-12
ci3/lesson-13
ci3/lesson-14
```

Semua branch sudah di-merge `--no-ff` ke `main`. Status repo sandbox bersih setelah uji coba.

## Kesimpulan

Course **layak dilanjutkan/publish setelah memperbaiki catatan Lesson 12 dan alur autoload database Lesson 2**. Secara fungsional, aplikasi blog CI3 lengkap berhasil dibangun dari awal sampai akhir: read, create, update, delete, template layout, session authentication, route protection, login, dan logout.

Masalah paling penting adalah credential Lesson 12, karena pembaca akan gagal login jika mengikuti `password123` dari materi. Setelah itu diperbaiki, alur teknis course berjalan baik di PHP 7.4 dan MariaDB.
