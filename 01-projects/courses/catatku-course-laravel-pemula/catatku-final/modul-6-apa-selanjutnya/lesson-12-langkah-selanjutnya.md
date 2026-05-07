# Lesson 12 — Langkah Selanjutnya

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Merefleksikan semua yang sudah dipelajari sepanjang course
- Mendapatkan peta jalan konkret untuk melanjutkan belajar Laravel
- Mengetahui ide-ide fitur yang bisa ditambahkan ke Catatku sebagai latihan mandiri

---

## Selamat — Catatku Sudah Jadi!

Sebelas lesson yang lalu, kamu memulai dari sebuah project Laravel yang kosong. Sekarang kamu punya aplikasi catatan harian yang benar-benar berfungsi: bisa dipakai, bisa didemokan, dan bisa dijadikan portofolio.

Itu bukan pencapaian kecil.

---

## Apa yang Sudah Kamu Kuasai

Lihat jauh ke belakang — ini semua yang sudah kamu pelajari dan terapkan secara langsung:

**Routing** — Kamu memahami bagaimana URL dihubungkan ke kode, perbedaan HTTP method (GET, POST, PUT, DELETE), dan cara mengelompokkan route dengan middleware. Kamu juga memahami mengapa urutan route itu penting.

**Pola MVC** — Kamu bisa memisahkan tanggung jawab antara Model, View, dan Controller. Route hanya berisi peta, controller berisi logika, view hanya berisi tampilan.

**Blade Template Engine** — Kamu menguasai `{{ }}`, `@foreach`, `@forelse`, `@if`, `@auth`, `@error`, `@csrf`, dan `@method`. Kamu juga sudah membuat Blade components yang reusable dengan `@props` dan `{{ $slot }}`.

**Eloquent ORM** — Kamu bisa berinteraksi dengan database menggunakan objek PHP, mendefinisikan relasi `belongsTo` dan `hasMany`, dan melakukan query dengan `latest()`, `get()`, dan `create()`.

**Migration** — Kamu bisa mendefinisikan dan menjalankan perubahan struktur database secara terprogram, termasuk membuat kolom dengan berbagai tipe dan mendefinisikan foreign key.

**Validasi** — Kamu memahami cara memvalidasi input pengguna dengan aturan `required`, `string`, `email`, `unique`, `max`, `min`, dan `confirmed`.

**Autentikasi** — Kamu membangun sistem registrasi, login, dan logout dari nol. Kamu memahami hashing password, session management, dan proteksi route dengan middleware.

**Keamanan Dasar** — Kamu menerapkan CSRF protection, mass assignment protection, authorization dengan `abort(403)`, dan session fixation prevention.

---

## Apa yang Belum Kita Pelajari

Course ini sengaja fokus pada fondasi. Banyak topik Laravel lain yang menunggu:

**Form Request** — Kelas tersendiri untuk menampung logika validasi, agar controller tidak terlalu panjang.

**Policy dan Gate** — Cara yang lebih terstruktur untuk mengelola authorization, terutama berguna saat ada banyak peran pengguna.

**Eloquent yang lebih dalam** — Scope, accessor, mutator, observer, dan factory untuk data testing.

**Queue dan Job** — Menjalankan tugas berat di latar belakang agar respons aplikasi tetap cepat.

**API Development** — Membangun REST API yang bisa dikonsumsi aplikasi mobile atau frontend terpisah.

**Testing** — Menulis automated test untuk memastikan fitur tidak rusak saat kode berubah.

---

## Ide Fitur untuk Mengembangkan Catatku

Catatku yang sudah kita bangun adalah fondasi yang solid. Berikut ide fitur yang bisa kamu tambahkan sebagai latihan mandiri:

### Level Pemula

**Pagination** — Saat ini semua catatan ditampilkan sekaligus. Ganti `.get()` dengan `.paginate(10)` di controller dan tambahkan `{{ $entries->links() }}` di view untuk memecah daftar menjadi beberapa halaman.

**Pencarian catatan** — Tambahkan form pencarian di halaman daftar yang memfilter catatan berdasarkan judul atau isi. Gunakan `->where('title', 'like', "%{$query}%")` di query Eloquent.

**Hitung kata** — Tampilkan jumlah kata di setiap catatan menggunakan `str_word_count($entry->content)` sebagai informasi tambahan di daftar atau detail catatan.

**Edit profil** — Buat halaman pengaturan akun di mana user bisa mengubah nama dan email mereka.

### Level Menengah

**Kategori / Tag** — Buat model `Category` dan relasi many-to-many dengan `Entry`. User bisa menandai catatan dengan kategori seperti "Pekerjaan", "Pribadi", atau "Ide". Tambahkan filter di daftar catatan berdasarkan kategori.

**Pin catatan** — Tambahkan kolom `is_pinned` (boolean) di tabel `entries`. Catatan yang di-pin selalu tampil di bagian atas daftar, tidak peduli kapan ditulis.

**Mode draft dan terbit** — Tambahkan kolom `status` dengan nilai `draft` atau `published`. User bisa menyimpan catatan sebagai draft dulu sebelum benar-benar disimpan.

**Statistik penulisan** — Halaman sederhana yang menampilkan total catatan, total kata yang pernah ditulis, hari paling produktif, dan streak hari berturut-turut.

### Level Lanjutan

**Ekspor catatan** — Izinkan user mengunduh semua catatannya sebagai file TXT atau PDF menggunakan Laravel's `Storage` facade.

**Mood tracker** — Tambahkan field mood (emoji atau skala 1–5) ke setiap catatan. Tampilkan grafik sederhana yang memperlihatkan tren mood dari waktu ke waktu.

**Pengingat** — Gunakan Laravel Scheduler dan Notifications untuk mengirim email pengingat jika user tidak menulis catatan selama beberapa hari.

---

## Peta Jalan Belajar Selanjutnya

```
Course ini (selesai ✓)
    │
    ▼
1. Perdalam Eloquent
   - Query scope dan local scope
   - Accessor dan mutator
   - Factory dan Seeder untuk data dummy
    │
    ▼
2. Testing dengan Pest
   - Feature test untuk route dan controller
   - Unit test untuk model dan logika bisnis
    │
    ▼
3. API Development
   - Resource Controller untuk API
   - Laravel Sanctum untuk autentikasi token
    │
    ▼
4. Deployment
   - Konfigurasi untuk production environment
   - Deploy ke platform cloud (Railway, Fly.io, atau VPS)
```

---

## Sumber Belajar yang Direkomendasikan

**Dokumentasi resmi Laravel** di `laravel.com/docs` — referensi terlengkap yang selalu diperbarui. Setelah menyelesaikan course ini, kamu sudah punya konteks yang cukup untuk membacanya secara mandiri.

**Laracasts** — platform video khusus Laravel oleh Jeffrey Way. Penjelasannya mendalam dan gaya mengajarnya sangat cocok untuk developer dari berbagai level.

**Laravel Daily** — blog dan channel YouTube yang membahas tips dan praktik terbaik Laravel dalam format singkat dan langsung ke inti.

---

## Penutup

Membangun aplikasi web yang nyata — dengan database, validasi, autentikasi, dan keamanan yang dipikirkan dengan baik — adalah pencapaian yang tidak boleh diremehkan.

Kamu sekarang memiliki pemahaman dasar yang solid tentang bagaimana web application bekerja menggunakan Laravel. Dari sini, satu-satunya cara untuk terus berkembang adalah dengan terus membangun.

Tambahkan fitur baru ke Catatku. Mulai project baru dari nol. Hadapi error, baca pesannya, cari solusinya. Setiap bug yang kamu selesaikan adalah pelajaran yang tidak akan kamu lupakan.

Selamat berkarya!
