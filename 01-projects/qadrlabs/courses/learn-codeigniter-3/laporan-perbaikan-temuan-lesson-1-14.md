# Laporan Perbaikan Temuan Course "Learn CodeIgniter 3" (Lesson 1-14)

**Tanggal perbaikan:** 2026-06-21  
**Pelaksana:** Codex  
**Sumber temuan:** `laporan-uji-coba-lesson-1-14.md`  
**Hasil:** Temuan utama sudah diperbaiki pada materi course.

## Ringkasan

Perbaikan dilakukan berdasarkan hasil uji coba end-to-end Lesson 1 sampai Lesson 14. Ada dua masalah utama yang berpotensi mengganggu pembaca saat mengikuti course:

- Lesson 12 menyediakan hash password yang tidak cocok dengan credential narasi `admin@example.com` / `password123`.
- Lesson 2 menginstruksikan autoload database sebelum konfigurasi database dibahas di Lesson 5.

Selain itu, catatan session save path dari environment uji ditambahkan sebagai troubleshooting lintas environment, bukan sebagai instruksi utama untuk Laragon.

## Detail Perbaikan

### 1. Hash password Lesson 12 disesuaikan dengan `password123`

File yang diperbaiki:

```text
module-6-layout-and-authentication/lesson-12-simple-authentication.md
```

Hash lama:

```text
$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
```

Hash tersebut cocok untuk password `password`, bukan `password123`. Materi tetap mempertahankan credential latihan:

```text
admin@example.com / password123
```

Hash SQL diganti menjadi hash bcrypt yang valid untuk `password123`:

```text
$2y$10$bD0v3dD4gJ5dT47J4XfEn.HiP2rsZ5Ym57d/Xsilm5iFx3nLu6e1C
```

Dampak perbaikan:

- Narasi credential dan data seed SQL sekarang konsisten.
- Pembaca dapat login memakai credential yang ditulis di materi.
- Exercise Lesson 12 tetap memakai `admin@example.com` / `password123` tanpa perubahan tambahan.

### 2. Autoload database dipindahkan dari Lesson 2 ke Lesson 5

File yang diperbaiki:

```text
module-1-foundations-2/lesson-2-installation-and-project-structure.md
module-7-review-and-next-steps/lesson-13-testing-the-complete-application.md
```

Instruksi Lesson 2 sebelumnya:

```php
$autoload['libraries'] = array('database', 'session');
$autoload['helper'] = array('url', 'form');
```

Instruksi Lesson 2 sekarang:

```php
$autoload['libraries'] = array('session');
$autoload['helper'] = array('url', 'form');
```

Lesson 2 juga diberi penjelasan bahwa database library baru akan ditambahkan di Lesson 5 setelah database dan `database.php` dikonfigurasi.

Lesson 5 sudah memuat instruksi yang benar:

```php
$autoload['libraries'] = array('database', 'session');
```

Lesson 13 diperbarui agar ringkasan final menyebut alur yang benar: `session`, `url`, dan `form` dimuat sejak Lesson 2, sedangkan `database` ditambahkan di Lesson 5.

Dampak perbaikan:

- Lesson 2 sampai Lesson 4 tidak lagi memicu error koneksi database pada project baru.
- Alur belajar menjadi lebih natural: database dibuat dan dikonfigurasi dulu, baru library database diautoload.
- Ringkasan akhir course konsisten dengan instruksi lesson.

### 3. Catatan `sess_save_path` ditambahkan sebagai troubleshooting environment

File yang diperbaiki:

```text
module-1-foundations-2/lesson-2-installation-and-project-structure.md
```

Catatan troubleshooting ditambahkan untuk kasus PHP tertentu yang memiliki session save path kosong. Materi sekarang memberi solusi:

```php
$config['sess_save_path'] = APPPATH.'cache/sessions';
```

dan menginstruksikan pembuatan folder:

```text
application/cache/sessions/
```

Catatan ini diposisikan sebagai perbaikan opsional jika warning session muncul. Laragon tetap dianggap tidak membutuhkan langkah tambahan dalam kondisi normal.

## Verifikasi

Verifikasi yang sudah dilakukan:

- Pencarian referensi hash lama pada file materi course tidak menemukan hash lama di lesson aktif.
- Pencarian autoload menunjukkan Lesson 2 sekarang hanya memuat `session`.
- Lesson 5 tetap menjadi titik pertama yang menambahkan `database` ke autoload.
- Hash baru diverifikasi dengan PHP 7.4 memakai `password_verify('password123', $hash)` dan menghasilkan `true`.
- `git diff --check` tidak menemukan whitespace error pada file yang diperbaiki.

Catatan verifikasi:

- File report uji coba lama masih menyimpan hash lama dan detail bug lama sebagai histori temuan. File tersebut tidak diubah.
- Git menampilkan warning CRLF ke LF untuk `lesson-13-testing-the-complete-application.md` saat diff/check. Ini adalah warning line ending, bukan error konten.

## File yang Berubah

```text
module-1-foundations-2/lesson-2-installation-and-project-structure.md
module-6-layout-and-authentication/lesson-12-simple-authentication.md
module-7-review-and-next-steps/lesson-13-testing-the-complete-application.md
```

File laporan ini ditambahkan:

```text
laporan-perbaikan-temuan-lesson-1-14.md
```

## Kesimpulan

Temuan kritis dari uji coba sudah ditangani. Materi sekarang lebih aman untuk diikuti secara berurutan karena Lesson 2 tidak lagi bergantung pada database yang belum dibuat, dan Lesson 12 menyediakan credential login yang benar-benar berfungsi sesuai narasi.
