# Lesson 5 — Bekerja dengan Database

## Tujuan Pembelajaran

Di akhir lesson ini, kamu akan:
- Mengkonfigurasi koneksi database di file `.env`
- Memahami apa itu migration dan mengapa lebih baik dari SQL manual
- Membuat migration untuk tabel `entries`
- Menjalankan migration dan memverifikasi tabel terbuat di database

---

## Mengkonfigurasi Database

Sebelum Laravel bisa berkomunikasi dengan database, kita perlu memberitahu di mana database itu berada. Buka file `.env` di root project dan cari bagian konfigurasi database:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_catatku
DB_USERNAME=root
DB_PASSWORD=
```

Sesuaikan `DB_USERNAME` dan `DB_PASSWORD` dengan kredensial MySQL di komputermu. Jika menggunakan XAMPP dengan konfigurasi default, username adalah `root` dan password kosong.

> **Catatan keamanan**: File `.env` sudah otomatis masuk ke `.gitignore` bawaan Laravel. Artinya file ini tidak akan ter-commit ke Git — ini praktik yang benar karena file ini menyimpan informasi sensitif seperti password database.

---

## Apa itu Migration?

Sebelum ada migration, developer membuat tabel database secara manual lewat phpMyAdmin atau dengan menjalankan SQL langsung:

```sql
CREATE TABLE entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

Pendekatan ini punya masalah nyata:
- Tidak ada catatan siapa yang membuat atau mengubah apa
- Developer lain harus menjalankan SQL yang sama secara manual
- Jika ada yang salah, rollback harus dilakukan secara manual

**Migration** adalah solusi Laravel. Migration adalah file PHP yang mendefinisikan perubahan struktur database. Dengan migration, semua perubahan database terlacak di Git seperti kode biasa, dan cukup satu perintah untuk menyiapkan database dari nol.

---

## Membuat Migration untuk Tabel Entries

Jalankan perintah artisan berikut untuk membuat model sekaligus migration-nya:

```bash
php artisan make:model Entry -m
```

Flag `-m` artinya "buat juga file migration untuk model ini". Output yang diharapkan:

```
INFO  Model [app/Models/Entry.php] created successfully.
INFO  Migration [database/migrations/2025_xx_xx_xxxxxx_create_entries_table.php] created successfully.
```

Dua file dibuat sekaligus: model `Entry.php` dan migration untuk tabel `entries`. Kita akan kembali ke model di lesson berikutnya — sekarang fokus pada migration dulu.

---

## Mendefinisikan Struktur Tabel

Buka file migration yang baru dibuat di folder `database/migrations/`. Nama filenya diawali timestamp, misalnya `2025_02_26_000000_create_entries_table.php`.

Isinya:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('entries', function (Blueprint $table) {
            $table->id();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('entries');
    }
};
```

Laravel menyediakan dua method:
- `up()` — dijalankan saat `php artisan migrate` (membuat tabel)
- `down()` — dijalankan saat rollback (menghapus tabel)

Kita perlu menambahkan kolom-kolom untuk data catatan. Perbarui method `up()`:

```php
public function up(): void
{
    Schema::create('entries', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->cascadeOnDelete();
        $table->string('title');
        $table->text('content');
        $table->timestamps();
    });
}
```

Penjelasan setiap kolom:

**`id()`** — Kolom `id` bertipe integer auto-increment sebagai primary key. Sudah ada bawaan.

**`foreignId('user_id')->constrained()->cascadeOnDelete()`** — Kolom `user_id` yang merupakan foreign key ke tabel `users`. `constrained()` otomatis membuat relasi ke `users.id`. `cascadeOnDelete()` berarti jika user dihapus, semua catatan miliknya ikut terhapus secara otomatis.

**`string('title')`** — Kolom `title` bertipe VARCHAR(255) untuk judul catatan.

**`text('content')`** — Kolom `content` bertipe TEXT untuk isi catatan yang panjang, tidak terbatas seperti VARCHAR.

**`timestamps()`** — Dua kolom `created_at` dan `updated_at` yang diisi otomatis oleh Laravel.

---

## Mengenal Tipe Kolom Blueprint

Laravel menyediakan banyak tipe kolom yang bisa digunakan:

```php
$table->string('title');           // VARCHAR(255) — untuk teks pendek
$table->string('title', 100);      // VARCHAR(100) — dengan panjang kustom
$table->text('content');           // TEXT — untuk teks panjang tak terbatas
$table->integer('page_count');     // INTEGER
$table->decimal('price', 10, 2);   // DECIMAL — untuk angka desimal seperti harga
$table->boolean('is_published');   // TINYINT(1)
$table->foreignId('user_id');      // UNSIGNED BIGINT untuk foreign key
```

---

## Menjalankan Migration

Jalankan migration untuk membuat tabel di database:

```bash
php artisan migrate
```

Jika database `db_catatku` belum ada, Laravel akan bertanya apakah ingin dibuat otomatis:

```
WARN  The database 'db_catatku' does not exist on the 'mysql' connection.

┌ Would you like to create it? ──────────────────────────────┐
│ ● Yes / ○ No                                               │
└────────────────────────────────────────────────────────────┘
```

Pilih `Yes`. Laravel akan membuat database dan menjalankan semua migration:

```
INFO  Running migrations.

  0001_01_01_000000_create_users_table .............. DONE
  0001_01_01_000001_create_cache_table .............. DONE
  0001_01_01_000002_create_jobs_table ............... DONE
  xxxx_xx_xx_create_entries_table .................. DONE
```

Perhatikan bahwa Laravel juga menjalankan migration bawaan, termasuk `create_users_table` yang akan kita butuhkan untuk fitur autentikasi.

---

## Rollback Migration

Jika ada kesalahan dalam migration dan perlu diulang:

```bash
php artisan migrate:rollback
```

Perintah ini menjalankan method `down()` dari migration terbaru, yang akan menghapus tabel `entries`. Setelah itu perbaiki file migration dan jalankan `php artisan migrate` lagi.

> **Penting**: Rollback hanya aman di environment development. Di production, rollback bisa menyebabkan kehilangan data nyata.

---

## Ringkasan

Kita telah:
- Mengkonfigurasi koneksi database di `.env`
- Memahami mengapa migration lebih baik dari SQL manual
- Membuat migration dengan kolom `user_id`, `title`, `content`, dan timestamps
- Menjalankan migration dan memverifikasi tabel terbuat

Database Catatku sudah siap. Di lesson berikutnya, kita akan belajar cara berinteraksi dengan tabel `entries` menggunakan **Eloquent Model**.
