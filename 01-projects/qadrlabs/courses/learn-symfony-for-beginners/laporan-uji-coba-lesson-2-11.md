# Laporan Uji Coba Course "Learn Symfony for Beginners" (Lesson 2-11)

Tanggal: 2026-11-02. Sumber awal: `~/Downloads/learn-symfony-for-beginners` (tidak diubah). Hasil penyesuaian ada di folder ini.

## Lingkungan Uji

- Ubuntu, PHP 8.5.9 (course menulis PHP 8.4 untuk Windows/Laragon; Symfony 8 butuh >= 8.4)
- Symfony **8.1.10** (`symfony/skeleton:"^8.0"` + `webapp`), Doctrine ORM 3.7, doctrine-fixtures-bundle 4.3
- MariaDB 11.8.6, database `db_catatku` (user `catatku_symfony`, lihat `00-inbox/membuat-database-catatku-symfony.md`). `.env` diisi persis seperti lesson, kredensial lokal di `.env.local`.
- Proyek: `sandbox/catatku-symfony`, satu branch per lesson (`symfony/lesson-02` ... `symfony/lesson-11-register`), di-merge `--no-ff` ke `main`.
- Cara uji: `php -S localhost:8080 -t public`, curl dengan cookie jar + ekstraksi token CSRF, `debug:router`, `doctrine:schema:validate`, query MariaDB langsung. Output terminal di lesson diambil dari jalankan asli (perintah interaktif `make:*` direkam lewat pseudo-TTY).

## Hasil per Lesson

| Lesson | Hasil | Catatan |
|---|---|---|
| 2 Setup | PASS | Migrasi sekarang di `src/Migrations/`, bukan `migrations/`; `src/Security/` tidak dibuat |
| 3 Route & View | PASS | Route tanpa `methods` tercatat `ANY`, bukan GET |
| 4 MVC | PASS | `debug:router` biasa tidak menampilkan controller, dipakai `--show-controllers` |
| 5 Database | PASS | Migrasi juga membuat `messenger_messages` (4 tabel, bukan 3) |
| 6 Repository & Fixtures | PASS | Ketiga entry punya `createdAt` sama, urutan "newest first" tidak terlihat |
| 7 Layout & Detail | **FAIL lalu diperbaiki** | 500 karena route belum ada; detail selalu 403 |
| 8 Create | **FAIL lalu diperbaiki** | POST form ditelan `entry_index`; anonim dapat 401, bukan 403 |
| 9 Edit & Delete | PASS (setelah template dipindah) | GET ke delete -> 405 |
| 10 Registration (lama) | **FAIL** | `FormLoginAuthenticator` tidak bisa di-autowire; butuh `app_login` dari L11 |
| 11 Login (lama) | PASS dengan urutan baru | |

Setelah perbaikan, alur penuh lulus: login Budi, CRUD, logout, register Siti + auto-login, Siti tidak bisa melihat/mengedit entry Budi (403), Budi tidak melihat entry Siti.

## Bug yang Ditemukan dan Diperbaiki

1. **L7 template memanggil route yang belum ada.** `base.html.twig` memakai `app_login/app_logout/app_register` (L10-11), `index.html.twig` memakai `entry_create/entry_edit/entry_delete` (L8-9). Halaman `/entries` jadi 500. Perbaikan: tiap tombol/link ditambahkan di lesson yang membuat route-nya (Write di L8, Edit/Delete di L9, Log In/Logout di L10, Register di L11), dengan versi file lengkap di tiap step.
2. **L7 ownership check sebelum ada login.** `show()` selalu 403 karena belum ada user login. Cek dipindah ke L8 setelah `/dev-login` ada.
3. **L8 form create tidak pernah menyimpan.** `entry_index` (`/entries`, tanpa `methods`) didefinisikan sebelum `entry_store` (`/entries`, POST), sehingga POST ditangani `index()`. Perbaikan: `methods: ['GET']` pada `entry_index`, plus Error baru di Fix the Errors.
4. **L10 (lama) registrasi tidak jalan.** Injeksi `FormLoginAuthenticator` gagal ("no such service exists"), dan auto-login butuh authenticator `form_login` yang baru dikonfigurasi di L11. `Security::login()` juga gagal sebelum ada authenticator ("No authenticators found for firewall "main""). **Keputusan user: urutan ditukar.** L10 sekarang Login & Logout (Budi dari fixtures, `/dev-login` dihapus), L11 Registration dengan `$security->login($user, 'form_login', 'main')`.
5. **L7 Fix the Errors salah klaim.** Komentar Twig sebelum `{% extends %}` ternyata tidak error; yang error adalah konten HTML di luar block. Contoh diganti dengan pesan error asli.
6. **L6 fixtures**: entry diberi tanggal berbeda (`-3 days`, `-2 days`, `-1 day`) supaya urutan terbaru terlihat.
7. **L2 exercise**: `registerBundles()` tidak ada lagi di `Kernel.php` (pakai `MicroKernelTrait`), diganti ke `config/bundles.php`; `grep` diganti `php bin/console list make` (Windows tidak punya grep), jumlah asli 28 perintah.
8. **L9 Solution 2**: varian `json_encode|raw` di dalam atribut HTML merusak atribut; dihapus, tersisa versi `|e('js')` yang sudah diuji.
9. Terminologi **ParamConverter** diganti "entity value resolver" (pesan error Symfony 8 menyebut `EntityValueResolver`).
10. Tailwind CDN v3 (`cdn.tailwindcss.com`) di home diseragamkan ke v4 seperti template lain.

## Penyesuaian House Style

- Paragraf sebelum `## 1. Before You Begin` dipindah ke dalamnya (semua lesson).
- Em dash/en dash dihapus (L1, L2, L3, tentang-course).
- Semua code fence diberi label bahasa; blok output diawali `Output:`.
- Step dengan potongan method diganti file lengkap (controller, template, fixtures, repository), termasuk solusi exercise.
- `tentang-course.md` diubah ke format copy-friendly dengan short description modul dan lesson (semua <= 255 karakter).
- L12 terakhir: "Next Up" diganti `## 10. Closing Thoughts`.
- Nama folder/file tanpa sufiks `-2`/`-6`.

## Perbedaan Windows vs Linux (perlu dicek ulang di Laragon)

- Pesan error koneksi DB: Linux `[2002] Connection refused`; Windows berbunyi "No connection could be made because the target machine actively refused it". Di lesson dijelaskan keduanya.
- Versi Symfony bisa lebih baru dari 8.1.10; nama file migrasi berisi timestamp berbeda.
- **CSRF stateless**: Symfony 8 memakai token stateless untuk `authenticate` dan `logout` (`config/packages/csrf.yaml`). Nilai hidden field tampil `csrf-token` dan validasi mengandalkan header `Origin` dari browser. Uji dengan curl wajib mengirim `-H 'Origin: http://localhost:8080'`. Sudah dijelaskan di L10.
- Bagian Laragon/HeidiSQL tidak bisa diuji di Linux.

## Yang Belum Diuji

- Lesson 1, 4 (sebagian), dan 12 tidak berisi kode yang perlu dijalankan.
- Tampilan visual Tailwind belum dicek di browser (hanya status HTTP dan isi HTML).
