# Laporan Uji Coba Course "Learn Laravel: Beyond the Basics" (Lesson 1–16)

**Tanggal uji:** 2026-06-12
**Penguji:** Claude Code
**Hasil keseluruhan:** ✅ Lesson 1–16 berhasil dijalankan dari project Catatku yang sama (lanjutan course Beginner), tanpa error yang menghambat. Lesson 17–18 di luar cakupan (lihat catatan).
**Status perbaikan (2026-06-13):** ✅ Keempat temuan di bawah sudah ditindaklanjuti pada file lesson. #4 (snippet observer L14) & #1 (catatan urutan migrasi L2) diperbaiki langsung; #3 (privasi komentar) didokumentasikan via callout di L8 & L5; #2 ditangani dengan **mempromosikan** `CommentController@destroy` (L1), `CommentPolicy` (L5), dan `TagController` + view tag (L2) dari bagian Latihan ke badan lesson, lalu memperbaiki kalimat di L6. Slot Latihan yang dikosongkan diganti latihan baru setara.

## Cakupan & metode

Aplikasi **Catatku** dibangun ulang dari Beginner Lesson 2–11, lalu diperluas dengan Beyond Lesson 1–16, semuanya di `sandbox/catatku` (gitignored dari vault, punya repo git sendiri). Tiap lesson dikerjakan di **branch git terpisah** (`beginner/lesson-NN-*`, `beyond/lesson-NN-*`) dan **di-commit di akhir lesson** lalu di-merge ke `main` — total 25 branch lesson + `main`, 51 commit. Uji dilakukan dengan benar-benar menjalankan perintah: `php artisan serve` + `curl` (cookie jar + token CSRF), `php artisan tinker --execute`, `php artisan test`, dan `npm run build`.

> Bagian Laragon/VSCode/Windows **dilewati** (lingkungan Linux memakai PHP/Composer/MariaDB sistem). Latihan (Exercises/Solutions) **tidak** diuji kecuali bila route file lesson lain bergantung padanya (lihat Temuan #3).

## Environment

| Komponen | Versi / Nilai |
|----------|---------------|
| Laravel Framework | 13.15.0 |
| PHP | 8.5.4 (NTS) |
| Composer | 2.10.0 |
| Node.js / npm | 25.9.0 / 11.12.1 |
| Database | MariaDB 11.8.6 |
| Pest | 4.7 |
| Tailwind / Vite | v4 / v8 |
| Lokasi project | `sandbox/catatku` (gitignored) |
| DB | `db_learn_laravel_13` / `learn_laravel_user` |

## Verifikasi per lesson (Beyond)

| Lesson | Yang diuji | Hasil |
|--------|-----------|-------|
| 1 | One-to-many: model+migration `Comment`, `hasMany`/`belongsTo`, form & tampil komentar | ✅ Komentar tampil (count/author/body), post valid 2→3, validasi `min:2` menolak 1-char |
| 2 | Many-to-many: `Tag` + pivot `entry_tag`, `belongsToMany`, `sync()`, checkbox, badge | ✅ 5 tag, store dgn tag, edit pre-check & sync (Travel→Work), `exists:tags,id` menolak ID 999 |
| 3 | Scopes (`recent`/`search`/`byUser`/`hasComments`), accessors (`excerpt`/`reading_time`/`created_at_human`), title mutator | ✅ Semua scope & accessor benar; mutator `  hello world  `→`Hello world`; search di browser memfilter |
| 4 | Eager loading, soft deletes (`deleted_at`), pagination, trash/restore | ✅ delete/trashed/onlyTrashed/restore; paginate total=4, page1=[6,1] page2=[2,3] |
| 5 | Gates & `EntryPolicy` via `Gate::authorize`, `@can`, admin bypass `Gate::before` | ✅ cross-user show/edit/delete → 403; owner 200 + tombol; admin bypass jalan |
| 6 | Middleware `LogRequest`, `Route::resource`, group `['auth','log.request']`, `throttle:10,1` | ✅ logging tiap request, guest→login, komentar ke-11 → 429 |
| 7 | File upload cover image: `storage:link`, validasi `image/mimes/max`, Storage facade | ✅ upload tersimpan & accessible /storage (200), non-image ditolak, update ganti file lama, no-file mempertahankan |
| 8 | Mailables `WelcomeEmail` & `NewCommentEmail` (driver `log`), kirim saat register/comment | ✅ welcome email saat register; new-comment email ke pemilik (subject/panel/button); self-comment ditekan |
| 9 | REST API: `install:api`, `Api/EntryController`, JSON + status code | ✅ `/api/entries` 200 paginated, show relasi, 404 hilang, 401 POST tanpa token |
| 10 | API Resources + Sanctum: `EntryResource`, `HasApiTokens`, login/logout Bearer | ✅ login→token, create via token 201 (author tanpa email/password), logout→401, validasi 422 |
| 11 | Pest feature test: install Pest, `RefreshDatabase`, `EntryFactory` | ✅ 6 test feature hijau (guest redirect, CRUD, 403, soft-delete, validasi) |
| 12 | Unit test: accessor/mutator/scope + `dataset()` | ✅ unit test hijau; total suite **18 test / 28 assertion** lulus |
| 13 | Queues: `ShouldQueue` `NewCommentEmail`, driver `database`, `CleanupOldEntries` + schedule | ✅ komentar→job di tabel (email tertunda), worker memproses; cleanup hapus permanen trashed >30 hari; scheduler harian |
| 14 | Events: `CommentPosted` + 3 listener (auto-discovery), `EntryObserver` | ✅ 3 listener terpicu (log sync, touch sync, email queued); observer created log + deleted hapus file |
| 15 | Blade components: `Button`/`Alert` (anonymous), `EntryCard` (class-based) | ✅ entry-card class-based render, x-button, x-alert flash hijau |
| 16 | Vite + Tailwind v4: brand color, `@vite`, migrasi view, `npm run build` | ✅ build sukses (app CSS 45.8 kB), `@vite` menyajikan aset build (bukan CDN), utility ter-scan ke bundle |

Beginner Lesson 2–11 juga dijalankan ulang sebagai fondasi dan lulus penuh (CRUD + auth + privasi per-user), konsisten dengan laporan sebelumnya (`../learn-laravel-for-beginners/laporan-uji-coba-lesson-2-11.md`).

## Temuan penting

1. **Urutan migrasi bertimestamp sama (Lesson 2).** `make:model Tag -m` lalu `make:migration create_entry_tag_table` yang dijalankan dalam detik yang sama bisa menghasilkan **timestamp identik**. Karena urut alfabet `create_entry_tag_table` < `create_tags_table`, migrasi pivot jalan **sebelum** tabel `tags` ada → gagal foreign key (`Table 'tags' doesn't exist`). Diperbaiki dengan menamai ulang file pivot ke timestamp lebih lambat. Di mesin nyata jeda antar perintah biasanya cukup, tapi course sebaiknya menambahkan catatan agar pivot dibuat setelah tabel utama.

2. **Notifikasi komentar lintas-user tak terpicu lewat UI (Lesson 8).** Sejak Policy Lesson 5, halaman detail entry (tempat form komentar) bersifat **owner-only** (`view` → 403 untuk non-pemilik). Akibatnya skenario "User B berkomentar di entry User A" yang dijadikan dasar uji email tidak bisa terjadi melalui navigasi normal — hanya pemilik yang melihat form, dan komentar pemilik justru ditekan. Endpoint `comments.store` sendiri tidak ber-gate `view`, jadi mekanisme email **terbukti benar** saat endpoint dipanggil langsung. Ini ketegangan desain (privasi entry vs. notifikasi komentar) yang layak diklarifikasi di course.

3. **Lesson 6 bergantung pada solusi latihan Lesson 1 & 2.** Route file utama Lesson 6 mengimpor `TagController` (tags.index/show) dan mendaftarkan `comments.destroy` (`CommentController@destroy`) — keduanya hanya muncul di **Exercises/Solutions** Lesson 1 & 2, bukan badan lesson utama. Pembaca yang hanya mengikuti lesson inti akan mendapat error "class not found" saat route dimuat. Saya implementasikan `TagController`, `CommentController@destroy`, dan `CommentPolicy` (dari solusi latihan) agar route valid. Course sebaiknya memindahkan komponen ini ke badan lesson atau menandai ketergantungannya secara eksplisit.

4. **Snippet uji observer Lesson 14 keliru.** Section 7 memakai `Entry::create(['user_id'=>$user->id, ...])`, tetapi `user_id` **tidak** ada di `#[Fillable]` model Entry (`['title','content','cover_image']`), sehingga `create()` gagal: `Field 'user_id' doesn't have a default value`. Cara yang benar (dan konsisten dengan seluruh course) adalah lewat relasi: `$user->entries()->create([...])`. Observer-nya sendiri berfungsi (created→log, deleted→hapus cover).

## Catatan akurasi minor (tidak menghambat)

- **Atribut `#[Fillable]` / `#[Hidden]` Laravel 13 akurat** — scaffold `laravel/laravel` 13.15 memang memakai sintaks atribut ini pada model `User`, seperti diklaim course.
- **`laravel/pao`** dihapus di Lesson 2 agar output `php artisan test` normal (bukan JSON ringkas).
- Contoh output di beberapa lesson memakai nilai placeholder (mis. tanggal `2026-04-17`, DB `Admin`); tidak berdampak fungsional.
- Tailwind v4 di project sudah pre-configured; `app.css` perlu tambahan `@source '../**/*.blade.php'` agar utility di Blade ter-scan (sudah ada di versi course, ditambahkan saat uji).

## Yang tidak diuji

- **Lesson 17 (Deploying to Production)** — butuh VPS Ubuntu nyata, domain, DNS, SSL Let's Encrypt, Supervisor; tidak dapat dijalankan di mesin lokal. Tidak disentuh.
- **Lesson 18 (What's Next)** — konten review/roadmap, bukan hands-on.
- Proses long-lived (`npm run dev` HMR, `queue:work` permanen, SMTP nyata/Mailtrap) tidak dijalankan permanen; diverifikasi dengan `npm run build`, `queue:work --stop-when-empty`, dan mail driver `log`.

## Kesimpulan

Course **layak dipublikasikan dari sisi teknis** untuk Lesson 1–16. Semua perintah, potongan kode, dan alur dapat diikuti dan menghasilkan Catatku berfitur lengkap (relasi, scopes/accessors, otorisasi, file upload, email, REST API + Sanctum, Pest, queue, events, Blade components, Tailwind/Vite) di atas Laravel 13 asli, dengan suite test 18 hijau. Empat temuan di atas (terutama #3 ketergantungan pada latihan dan #4 snippet observer) sebaiknya diperbaiki sebelum publikasi agar pembaca yang mengikuti badan lesson tidak tersandung.
