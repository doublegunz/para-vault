# Laporan Uji Coba: Learn CodeIgniter 4 for Beginners (Lesson 2-11)

Tanggal uji: 2026-06-17. Diuji end-to-end di `sandbox/catatku-ci4` (di luar
vault, repo git tersendiri, satu branch + commit per lesson). Mulai dari
Lesson 2 Step 6 sampai Lesson 11. Lesson 12 ("What's Next") tanpa kode.

## Ringkasan

| Lesson | Materi | Status |
|--------|--------|--------|
| L2 (Step 6-8) | Scaffold project, .env, spark serve | PASS |
| L3 | Route & view pertama (home + entries) | PASS |
| L4 | MVC, EntryController | PASS |
| L5 | Database & migrations (users, entries) | PASS |
| L6 | Models & seeder | PASS |
| L7 | Layout, partial, halaman detail | PASS |
| L8 | Create entry + AuthFilter | PASS |
| L9 | Edit & delete (CRUD lengkap) | PASS |
| L10 | Registrasi + GuestFilter | PASS |
| L11 | Login/logout + scoping per user | PASS |

Semua langkah kode pada lesson berjalan sesuai yang dijanjikan. Verifikasi
dilakukan lewat `curl` (cookie jar + status code) dan query langsung ke MariaDB.

## Lingkungan uji (berbeda dari instruksi lesson)

Course ditulis untuk **Windows + Laragon**, sedangkan uji coba dijalankan di
**Linux**. Penyesuaian yang dipakai (tidak mengubah logika aplikasi):

- **OS/tooling:** Step 1-5 Lesson 2 (install VS Code, Laragon, upgrade PHP via
  GUI) tidak relevan di Linux dan dilewati. Server dijalankan dengan
  `php8.5 spark serve`, pengujian UI digantikan `curl`.
- **PHP:** hanya tersedia **PHP 8.5.4**. CodeIgniter **4.7.3** (versi yang
  ter-install dari appstarter) berjalan tanpa error fatal maupun deprecation
  yang mengganggu di PHP 8.5. Lesson menyebut PHP 8.3; 8.1+ sudah cukup untuk CI4.
- **Database:** lesson memakai `db_catatku` dengan user `root` password kosong.
  Di mesin uji, MariaDB `root` butuh sudo interaktif, jadi dipakai database
  `db_learn_laravel_13` (kosong) dengan user `learn_laravel_user`. Konfigurasi
  `.env`:
  ```
  database.default.database = db_learn_laravel_13
  database.default.username = learn_laravel_user
  database.default.password = password_yang_kuat
  database.default.DBDriver = MySQLi
  ```
  Tidak memengaruhi materi; pembaca tetap mengikuti `db_catatku`/`root`.

## Temuan yang perlu diperbaiki di materi

### 1. Sisa teks "Laravel" di Lesson 2 (penting) — SUDAH DIPERBAIKI (2026-06-17)
Beberapa kalimat di Lesson 2 masih menyebut Laravel (copy-paste dari course
Laravel), padahal ini course CodeIgniter:
- Step 4: "**Laravel 13 requires PHP 8.3 or higher.** The default Laragon
  installation comes with PHP 8.1..." — alasan upgrade salah konteks. CI4 hanya
  butuh PHP 8.1+, bukan karena Laravel.
- Akhir Step 5: "Both the browser and the CLI now confirm that PHP 8.3 is active.
  **We are ready to create our Laravel project.**" — harusnya "CodeIgniter project".

Saran: ganti semua referensi "Laravel" menjadi "CodeIgniter" dan sesuaikan alasan
versi PHP.

**Status:** Lesson 2 sudah ditulis ulang: referensi Laravel diganti, rationale PHP
diperbaiki (CodeIgniter 4 butuh PHP 8.2+; Laragon 6 free ship 8.1 jadi upgrade ke
8.3 tetap perlu), ditambah bagian "Tools You'll Need" + "Choose Your Operating
System" (lintas-OS, Laragon free sebagai contoh Windows), dan langkah web server
(Nginx + verifikasi phpinfo di browser) dihapus karena app dijalankan via
`php spark serve`.

### 2. CSRF tidak aktif secara default (penting, keamanan) — SUDAH DIPERBAIKI (2026-06-17)
Semua form memakai `csrf_field()` (praktik bagus), tetapi pada CI4 default
**filter `csrf` tidak diaktifkan** (tidak ada di `$globals`/`$methods`
`app/Config/Filters.php`). Akibatnya token CSRF dirender tapi **tidak
divalidasi** - POST tanpa token tetap diterima (terbukti saat uji: POST tanpa
token tidak 403). Materi mengklaim `csrf_field()` "protects forms from CSRF
attacks", padahal proteksi belum nyala.

Saran: tambahkan satu langkah mengaktifkan filter `csrf`, misalnya di
`app/Config/Filters.php`:
```php
public array $globals = [
    'before' => [
        'csrf',
    ],
    ...
];
```
(atau lewat `$methods` untuk POST), agar klaim keamanan di L8/L10/L11 benar.

**Status:** Lesson 8 Step 1 kini punya subbagian "Enable CSRF Protection" yang
menyuruh uncomment `'csrf'` di `$globals['before']` (`app/Config/Filters.php`),
plus penjelasan (token `csrf_test_name`, regenerate, di development gagal CSRF =
403, GET tidak terpengaruh). Narasi klaim CSRF di L8 (Step 4 + Conclusion) sudah
diakuratkan, dan L7 diberi forward note bahwa proteksi baru aktif di L8.
Terverifikasi di sandbox: setelah `'csrf'` diaktifkan, POST `/entries` tanpa token
-> 403; dengan token (login + create) -> 303 dan row bertambah; GET tetap normal.

### 3. Migration: urutan & risiko foreign key (penting) — SUDAH DIPERBAIKI (2026-06-17)
FK `entries.user_id -> users.id` mengharuskan migrasi `users` jalan lebih dulu.
CI4 mengurutkan migrasi by timestamp prefix; **jika `CreateUsersTable` dan
`CreateEntriesTable` dibuat pada detik yang sama**, urutan jatuh ke nama file dan
"...CreateEntriesTable" < "...CreateUsersTable" secara alfabet -> entries jalan
duluan -> FK gagal. Saat uji, kedua file sengaja dibuat berjarak agar
timestamp berbeda.

Saran: beri catatan di L5 untuk membuat migrasi `users` lebih dulu (atau pastikan
timestamp berbeda). Ini pernah jadi masalah serupa di course Laravel.

**Status:** Lesson 5 Step 3 sudah diberi callout "Important: migration order
matters" yang menjelaskan aturan urut CI4 (timestamp, lalu nama class alfabet),
kenapa `users` harus duluan, gejala FK error kalau timestamp kembar, dan solusinya
(rename detik file `CreateEntriesTable` jadi satu lebih besar). Step 4 juga diberi
kalimat penegasan urutan output yang benar. Aturan dikonfirmasi dari source
`system/Database/MigrationRunner.php` (`ksort` atas key `<digit-timestamp><ClassName>`).

### 4. Inkonsistensi status ownership 403 vs 404 (kecil) — SUDAH DIPERBAIKI (2026-06-18)
L7 `show()` mengembalikan **403** untuk entry milik orang lain
(`setStatusCode(403)`). L9 me-refactor jadi `findOwnedEntry()` yang melempar
`PageNotFoundException` -> **404** untuk kasus yang sama, tanpa menjelaskan
perubahan perilaku tersebut. Keduanya valid, tapi sebaiknya disebutkan bahwa
404 dipilih agar tidak membocorkan keberadaan resource.

**Status:** Diselaraskan ke **403 di semua** (keputusan user). L9 sekarang punya
subbagian yang membuat `app/Exceptions/ForbiddenException.php` (implement
`HTTPExceptionInterface`, code 403) + view `app/Views/errors/html/error_403.php`,
lalu `findOwnedEntry()` melempar `ForbiddenException` untuk not-owned (404 tetap
untuk not-found). Docblock "403 if not owned" kini cocok dengan kode. Terverifikasi
di sandbox: Ani akses entry Budi -> 403 (halaman error_403 rapi), entry hilang ->
404, edit milik orang lain -> 403, pemilik -> 200. (Catatan: CI4 hanya memetakan
kode exception ke status HTTP bila implement `HTTPExceptionInterface`.)

### 5. Typo "life of code" di Lesson 9 (kecil) — SUDAH DIPERBAIKI (2026-06-18)
Komentar `// add this life of code` (3x) seharusnya `// add this line of code`.

**Status:** Seluruh kemunculan (6x) di L9 diganti jadi `// add this line of code`.

### 6. Paragraf berbahasa Indonesia di Lesson 9 Step 4 (kecil) — SUDAH DIPERBAIKI (2026-06-18)
Satu paragraf masih Indonesia ("Selanjutnya kita kembali ke halaman daftar
entry...") di tengah course berbahasa Inggris. Perlu diterjemahkan agar konsisten.

**Status:** Paragraf diterjemahkan ke Inggris ("Next, go back to the entries list
page and click the delete link... A confirmation popup will appear before the entry
is deleted.").

### 7. Versi CDN Tailwind berbeda antar view (kecil) — SUDAH DIPERBAIKI (2026-06-18)
`home.php` memakai `https://cdn.tailwindcss.com` (Tailwind v3 Play CDN),
sedangkan `entries/index.php`, `layouts/main.php`, dll memakai
`https://unpkg.com/@tailwindcss/browser@4` (v4). Sebaiknya seragam.

**Status:** Diseragamkan ke **v4**. Kedua `home.php` (L3 dan L11) kini memakai
`https://unpkg.com/@tailwindcss/browser@4`. Terverifikasi di sandbox: halaman `/`
tetap HTTP 200 dan tampil rapi dengan v4.

## Verifikasi kunci yang lulus

- Welcome page CI4 (L2), home + listing array (L3), MVC controller (L4).
- 3 tabel (`users`, `entries`, `migrations`) terbuat, schema & FK sesuai (L5).
- Seeder mengisi 1 user (bcrypt `$2y$12$`) + 3 entry, tampil di listing (L6).
- Layout + partial render, detail owner-only: guest 403 / missing 404 (L7).
- AuthFilter redirect guest, `/dev-login` set session, create + validasi +
  insert sukses (entry id bertambah) (L8).
- Edit prefilled, update validasi + persist (`updated_at` berubah), delete
  menghapus row, non-owner 404 (L9).
- Registrasi: user baru + hash + auto-login, validasi `min_length`/`matches`/
  `is_unique` jalan, GuestFilter redirect user login, `/dev-login` jadi 404 (L10).
- Login: kredensial salah ditolak, login benar redirect, `/entries` masuk grup
  auth (guest -> /login), `index()` hanya entry milik user, privasi multi-user
  (Ani tak bisa lihat entry Budi -> 404), logout hancurkan session (L11).

## Catatan git

Repo `sandbox/catatku-ci4` (gitignored dari vault). 10 branch
`ci4/lesson-02..11`, di-merge `--no-ff` ke `main`. Trailer commit:
`Co-Authored-By: Claude Opus 4.8`.
