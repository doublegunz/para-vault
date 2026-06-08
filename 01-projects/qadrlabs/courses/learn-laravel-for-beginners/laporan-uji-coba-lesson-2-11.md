# Laporan Uji Coba Course "Learn Laravel for Beginners" (Lesson 2–11)

**Tanggal uji:** 2026-06-08
**Penguji:** Claude Code
**Hasil keseluruhan:** ✅ Seluruh course berhasil dijalankan dari lesson 2 sampai 11 tanpa error.

## Environment

| Komponen | Versi / Nilai |
|----------|---------------|
| Laravel Framework | 13.14.0 |
| PHP | 8.5.4 (NTS) |
| Composer | 2.10.0 |
| Node.js | 25.9.0 |
| Database | MariaDB 11.8.6 |
| Lokasi project | `sandbox/catatku` (gitignored) |
| DB name | `db_learn_laravel_13` |
| DB user | `learn_laravel_user` |

> Catatan: Bagian instalasi **Laragon/Windows dilewati** sesuai instruksi. Di Linux dipakai PHP/Composer/MySQL sistem. Course tetap bisa diikuti penuh karena semua langkah inti berbasis Composer & Artisan. Kredensial & database MySQL disiapkan manual sebelum uji coba.

## Verifikasi per lesson

| Lesson | Yang diuji | Hasil |
|--------|-----------|-------|
| 2 | `composer create-project` + `php artisan serve` | ✅ Welcome page 200 |
| 3 | Route home + `/entries` (dummy array), Blade `@foreach` | ✅ Dua halaman 200, data tampil |
| 4 | Refactor ke `EntryController`, `route:list` | ✅ Route → `EntryController@index` |
| 5 | `.env` MySQL, migration `entries`, `migrate` | ✅ 6 kolom benar (`id, user_id, title, content, created_at, updated_at`) |
| 6 | `#[Fillable]`, relasi `belongsTo`/`hasMany`, Eloquent, seed Tinker | ✅ Data DB tampil, tanggal Carbon terformat |
| 7 | Blade components (`<x-layout>`, `<x-entry-card>`), `show()` + Route Model Binding | ✅ Layout jalan, detail → 403 untuk guest (sesuai course) |
| 8 | `middleware('auth')`, `/dev-login`, `create`/`store`, validasi, `@csrf` | ✅ Login dev, simpan entry (3→4), validasi redirect balik |
| 9 | `edit`/`update`/`destroy`, `@method('PUT'/'DELETE')`, cek `abort(403)` | ✅ Update & delete jalan, otorisasi antar-user → 403 |
| 10 | `AuthController` register, `unique`/`confirmed`/`min:8`, `guest` middleware | ✅ Register + auto-login, semua validasi benar |
| 11 | Login/logout, `Auth::attempt`, scoping `auth()->user()->entries()`, home page | ✅ 6 skenario lolos (privasi multi-user terbukti) |

## Detail pengujian fungsional

### Lesson 5 — verifikasi struktur tabel
```
Schema::getColumnListing('entries')
=> [id, user_id, title, content, created_at, updated_at]
```

### Lesson 8 — create & validasi
- POST entry valid → `302 -> /entries`, jumlah entry bertambah 3 → 4
- POST field kosong → `302 -> /entries/create` (validasi gagal, redirect balik)

### Lesson 9 — update, delete, otorisasi
- PUT entry 1 → `302 -> /entries/1`, title berubah jadi "My first entry (edited)"
- DELETE entry → jumlah entry berkurang 4 → 3
- User 1 (Budi) baca/edit entry milik User 2 (Siti) → **403** (ownership check bekerja)

### Lesson 10 — registrasi
- Halaman register → 200
- POST kosong → redirect balik (validasi)
- POST password tidak cocok → redirect balik (rule `confirmed`)
- POST valid → `302 -> /entries` + auto-login (jumlah user jadi 3)
- User login akses `/register` → dialihkan (middleware `guest`)

### Lesson 11 — autentikasi lengkap (6 skenario)
1. Guest akses `/entries` → `302 -> /login` ✅
2. Login password salah → redirect balik ke `/login` ✅
3. Login benar (Budi) → `302 -> /entries` ✅
4. **Privasi:** Budi hanya melihat 3 entry miliknya, tidak melihat "Siti private" ✅
5. Logout (POST) → `302 -> /login`, sesi hangus ✅
6. User login akses `/login` → dialihkan (middleware `guest`) ✅
7. Cross-check: Siti login → hanya melihat entry "Siti private" ✅

**Status DB akhir:** 3 user (Budi, Siti, Andi), 4 entry. Tidak ada error di `storage/logs`.

## Temuan penting

1. **Klaim "Laravel 13" + atribut `#[Fillable]` AKURAT.** Sintaks atribut `#[Fillable(...)]` / `#[Hidden(...)]` ini tidak umum dijumpai, namun terbukti `composer create-project laravel/laravel` menghasilkan Laravel 13.14.0 yang model `User` default-nya memang sudah memakai atribut tersebut. Course benar di bagian ini.

2. **PHP 8.5 kompatibel.** Course mensyaratkan minimal PHP 8.3; lingkungan uji memakai PHP 8.5.4 dan berjalan tanpa masalah.

3. **Default SQLite → MySQL.** Sesuai penjelasan Lesson 2, project segar memang membuat `database/database.sqlite` dan menjalankan migrasi default di atasnya. Peralihan ke MySQL di Lesson 5 berjalan mulus.

4. **Urutan route penting (Lesson 8).** `/entries/create` harus dideklarasikan sebelum `/entries/{entry}` — sudah benar di course, terverifikasi via `route:list`.

## Catatan akurasi minor (tidak menghambat)

- **Lesson 5 & 6** menampilkan contoh output yang menyebut `db_catatku`, kredensial Laragon (`root`/kosong), dan "PHP 8.4.5" pada output Tinker. Ini hanya teks contoh; pada lingkungan nyata nilainya menyesuaikan konfigurasi masing-masing. Tidak ada dampak fungsional.
- **Lesson 5** mengatakan Laravel akan menawarkan membuat database otomatis saat `migrate`. Pada uji ini database sudah dibuat manual lebih dulu, jadi prompt tersebut tidak muncul — perilaku tetap benar.

## Kesimpulan

Course **layak dipublikasikan dari sisi teknis**. Semua perintah, potongan kode, dan alur dari Lesson 2 sampai 11 dapat diikuti dan menghasilkan aplikasi Catatku yang berfungsi penuh (CRUD + autentikasi + privasi per-user) di atas Laravel 13 asli.
