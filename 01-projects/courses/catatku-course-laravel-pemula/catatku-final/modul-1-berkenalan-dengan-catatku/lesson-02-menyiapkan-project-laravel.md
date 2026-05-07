# Lesson 2 — Menyiapkan Project Laravel

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Memiliki PHP 8.2+ dan Composer terinstall di komputer
- Berhasil membuat project Laravel baru bernama Catatku
- Memahami struktur folder dasar Laravel
- Menjalankan development server dan melihat halaman pertama Laravel

---

## Persiapan: Apa yang Perlu Diinstall

Kita butuh dua alat sebelum bisa mulai:

**PHP 8.2 atau lebih tinggi**
PHP adalah bahasa pemrograman yang menjalankan seluruh aplikasi Laravel. Laravel 12 membutuhkan minimal PHP 8.2.

**Composer**
Composer adalah package manager untuk PHP — seperti npm untuk JavaScript. Kita gunakan Composer untuk menginstall Laravel beserta semua dependensinya.

### Verifikasi Instalasi

Buka terminal dan jalankan kedua perintah ini:

```bash
php -v
```

Output yang diharapkan:
```
PHP 8.2.x (cli) ...
```

```bash
composer -V
```

Output yang diharapkan:
```
Composer version 2.x.x ...
```

Jika muncul error "command not found", install terlebih dahulu melalui php.net dan getcomposer.org sesuai sistem operasi kamu.

---

## Membuat Project Catatku

Setelah PHP dan Composer siap, jalankan perintah berikut di terminal:

```bash
composer create-project --prefer-dist laravel/laravel catatku
```

Perintah ini akan mengunduh Laravel versi terbaru dan menyiapkan seluruh konfigurasi awal ke dalam folder `catatku`. Proses ini membutuhkan koneksi internet dan mungkin memakan beberapa menit.

Setelah selesai, masuk ke direktori project:

```bash
cd catatku
```

Buka project di VS Code:

```bash
code .
```

---

## Mengenal Struktur Folder Laravel

Ketika project terbuka di VS Code, kamu akan melihat banyak folder. Jangan khawatir — kita tidak perlu memahami semuanya sekarang. Berikut folder-folder yang akan paling sering kita gunakan:

```
catatku/
├── app/
│   ├── Http/
│   │   └── Controllers/    ← Tempat controller berada
│   └── Models/             ← Tempat model Eloquent berada
├── database/
│   └── migrations/         ← Definisi struktur tabel database
├── resources/
│   └── views/              ← File Blade template (HTML)
├── routes/
│   └── web.php             ← Daftar semua route aplikasi
├── .env                    ← Konfigurasi environment (database, dll)
└── artisan                 ← CLI tool Laravel
```

**`app/Http/Controllers/`** — Logika aplikasi ada di sini. Controller menerima request, memproses data, dan mengirim response ke pengguna.

**`app/Models/`** — Model adalah representasi PHP dari tabel database. Model `Entry` yang akan kita buat nanti berkorespondensi dengan tabel `entries` di database.

**`database/migrations/`** — File PHP yang mendefinisikan struktur tabel database secara terprogram.

**`resources/views/`** — Semua file Blade template ada di sini. Blade adalah template engine Laravel untuk membuat HTML yang dinamis.

**`routes/web.php`** — "Peta" aplikasi kita. Di sinilah semua URL didefinisikan dan dihubungkan ke controller.

**`.env`** — File konfigurasi environment, termasuk koneksi database. File ini tidak boleh di-commit ke Git karena berisi informasi sensitif.

---

## Menjalankan Development Server

Laravel menyediakan development server bawaan melalui `artisan`. Jalankan:

```bash
php artisan serve
```

Output:
```
INFO  Server running on [http://127.0.0.1:8000].

Press Ctrl+C to stop the server
```

Buka browser dan akses `http://127.0.0.1:8000`. Kamu akan melihat halaman welcome Laravel — tanda bahwa project berhasil dibuat dan berjalan.

> **Tip**: Biarkan terminal ini tetap berjalan. Buka terminal baru untuk menjalankan perintah artisan lainnya selama development.

---

## Berkenalan dengan Artisan

`artisan` adalah command-line interface bawaan Laravel yang akan sering kita gunakan. Berikut perintah-perintah yang akan paling sering dipakai:

```bash
php artisan serve              # Menjalankan development server
php artisan make:model         # Membuat model baru
php artisan make:controller    # Membuat controller baru
php artisan make:migration     # Membuat file migration baru
php artisan migrate            # Menjalankan semua migration
php artisan route:list         # Menampilkan semua route yang terdaftar
php artisan tinker             # Membuka REPL interaktif Laravel
```

---

## Ringkasan

Kita telah:
- Memverifikasi PHP dan Composer terinstall dengan benar
- Membuat project Laravel baru bernama `catatku`
- Memahami fungsi folder-folder utama
- Menjalankan development server

Project Catatku sudah berdiri. Di lesson berikutnya, kita akan membuat route dan view pertama — langkah awal mengubah project kosong ini menjadi aplikasi nyata.
