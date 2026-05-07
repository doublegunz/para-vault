# Lesson 1 — Apa yang Akan Kita Bangun?

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Memahami gambaran lengkap aplikasi Catatku yang akan kita bangun
- Mengetahui fitur-fitur yang akan diimplementasikan
- Memahami alur belajar sepanjang course ini

---

## Kenalan dengan Catatku

Bayangkan kamu punya buku harian digital. Kamu bisa menulis catatan kapan saja, membaca kembali catatan lama, mengedit jika ada yang ingin diubah, dan menghapus yang sudah tidak relevan. Semua catatan itu hanya bisa kamu sendiri yang lihat — tidak ada orang lain yang bisa mengintip.

Itulah **Catatku** — aplikasi catatan harian pribadi yang akan kita bangun bersama dari nol menggunakan Laravel.

Sederhana, tapi mengandung semua konsep penting yang perlu dikuasai seorang developer Laravel pemula: routing, MVC, database, model, validasi form, dan autentikasi.

---

## Fitur yang Akan Kita Bangun

### Daftar Catatan
Halaman utama setelah login menampilkan semua catatan milik pengguna, diurutkan dari yang paling baru. Setiap catatan menampilkan judul, potongan isi, dan tanggal penulisan.

### Menulis Catatan Baru
Pengguna bisa membuat catatan baru melalui form yang memiliki dua field: **judul** dan **isi catatan**. Keduanya divalidasi sebelum disimpan.

### Membaca Catatan
Pengguna bisa membuka catatan tertentu untuk membaca isinya secara lengkap.

### Mengedit Catatan
Pengguna bisa mengubah judul dan isi catatan yang sudah ditulis.

### Menghapus Catatan
Pengguna bisa menghapus catatan yang tidak lagi diperlukan, dengan konfirmasi terlebih dahulu.

### Registrasi, Login, dan Logout
Hanya pengguna yang sudah punya akun dan login yang bisa mengakses aplikasi. Semua catatan bersifat privat — tidak ada pengguna lain yang bisa melihat catatan kamu.

---

## Tampilan Akhir Aplikasi

**Halaman Daftar Catatan**
```
┌─────────────────────────────────────────────────────┐
│  Catatku 📓                    Budi · [Logout]       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Catatanku            [+ Tulis Catatan Baru]        │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Rencana liburan akhir tahun                  │  │
│  │  Sudah lama tidak liburan, mungkin ke...      │  │
│  │  20 Februari 2026          [Edit] [Hapus]     │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  Belajar Laravel hari pertama                 │  │
│  │  Hari ini mulai belajar Laravel. Ternyata...  │  │
│  │  19 Februari 2026          [Edit] [Hapus]     │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

**Halaman Detail Catatan**
```
┌─────────────────────────────────────────────────────┐
│  Catatku 📓                    Budi · [Logout]       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ← Kembali ke daftar                               │
│                                                     │
│  Rencana liburan akhir tahun                        │
│  20 Februari 2026                                   │
│                                                     │
│  Sudah lama tidak liburan. Mungkin bisa ke          │
│  Yogyakarta atau Lombok. Perlu riset dulu           │
│  soal budget dan waktu yang tepat...                │
│                                                     │
│                          [Edit Catatan] [Hapus]     │
└─────────────────────────────────────────────────────┘
```

---

## Kenapa Catatku Cocok untuk Belajar?

Dibanding aplikasi publik seperti Twitter-clone, aplikasi catatan harian memiliki keunggulan pedagogis:

**Authorization yang lebih natural** — Di aplikasi publik, kita perlu menjelaskan secara khusus kenapa user hanya boleh edit/hapus miliknya sendiri. Di Catatku, ini sudah *self-evident* — tentu saja kamu tidak boleh baca atau ubah catatan orang lain. Konsepnya langsung masuk akal.

**Privasi sebagai fitur utama** — Konsep "hanya pemilik yang bisa melihat" memperkenalkan query yang ter-scope ke user aktif (`auth()->user()->entries()`), sebuah pola yang sangat umum di aplikasi nyata.

**Field yang lebih kaya** — Dengan dua field (`title` + `content`), kamu akan belajar validasi dan pengelolaan form yang sedikit lebih realistis.

---

## Teknologi yang Digunakan

**Laravel 12** — Framework PHP yang menangani routing, database, validasi, session, dan banyak lagi.

**PHP 8.2+** — Bahasa pemrograman di balik Laravel.

**MySQL** — Database untuk menyimpan akun pengguna dan catatan.

**Blade** — Template engine Laravel untuk halaman HTML yang dinamis.

**Tailwind CSS** — Framework CSS untuk tampilan yang bersih tanpa menulis CSS dari nol.

---

## Alur Belajar Course Ini

```
Lesson 1–2   →  Orientasi & setup project
Lesson 3–4   →  Routing, view, dan pola MVC
Lesson 5–6   →  Database dan Eloquent model
Lesson 7–9   →  Fitur CRUD: daftar, buat, detail, edit, hapus
Lesson 10–11 →  Autentikasi: registrasi, login, logout
Lesson 12    →  Refleksi dan langkah selanjutnya
```

Di akhir Lesson 11, kamu akan memiliki aplikasi Catatku yang benar-benar berjalan dan bisa kamu jadikan portofolio. Mari mulai!
