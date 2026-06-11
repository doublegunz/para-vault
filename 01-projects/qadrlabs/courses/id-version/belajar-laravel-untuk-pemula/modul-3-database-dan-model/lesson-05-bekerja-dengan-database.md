Sampai saat ini, entri jurnal yang ditampilkan di browser masih berupa array hardcoded yang ditulis langsung di dalam controller. Kita sengaja menggunakan data palsu tersebut agar dapat fokus memahami routing, view, dan MVC terlebih dahulu. Lesson ini adalah titik baliknya. Mulai dari sini, kita akan bekerja dengan database sungguhan, dan entri yang kita simpan akan benar-benar persisten. Data tersebut tidak akan hilang ketika server di-restart.

## Ikhtisar {#overview}

### Apa yang Akan Anda Bangun

Di akhir lesson ini, tabel `entries` akan ada di database Anda dengan kolom-kolom yang tepat: `id`, `user_id`, `title`, `content`, `created_at`, dan `updated_at`. Kita belum akan memasukkan data dari aplikasi (itu akan dilakukan di lesson-lesson berikutnya), tetapi fondasi database sudah akan sepenuhnya siap.

### Apa yang Akan Anda Pelajari

- Cara menghubungkan Laravel ke database MySQL melalui file `.env`
- Apa itu migration dan mengapa migration jauh lebih baik dibandingkan membuat tabel secara manual
- Cara membuat model dan migration sekaligus menggunakan satu perintah Artisan
- Cara mendefinisikan kolom tabel menggunakan Schema Builder milik Laravel
- Cara menjalankan migration dengan `php artisan migrate`
- Cara melakukan rollback migration ketika terjadi kesalahan
- Tipe kolom Blueprint umum yang akan Anda gunakan dalam proyek nyata

### Apa yang Anda Butuhkan

- Proyek `catatku` terbuka di VS Code dengan development server yang sedang berjalan
- MySQL yang sedang berjalan (jika Anda menggunakan Laragon, klik **Start All**)
- Kredensial MySQL Anda: nama database, username, dan password. Jika Anda menggunakan Laragon dengan konfigurasi default, username-nya adalah `root` dan password-nya kosong

---

## Step 1: Konfigurasi Koneksi Database {#step-1-configure-the-database-connection}

Sebelum Laravel dapat berkomunikasi dengan database, kita perlu memberi tahu di mana database tersebut berada. Buka file `.env` di root proyek Anda dan cari bagian konfigurasi database:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=db_catatku
DB_USERNAME=root
DB_PASSWORD=
```

Perbarui `DB_USERNAME` dan `DB_PASSWORD` agar sesuai dengan kredensial MySQL di komputer Anda. Jika Anda menggunakan Laragon atau XAMPP dengan konfigurasi default, username-nya adalah `root` dan password-nya kosong (biarkan `DB_PASSWORD=` kosong).

Nilai `DB_DATABASE` adalah `db_catatku`. Ini adalah nama database yang akan digunakan Laravel. Anda tidak perlu membuatnya secara manual. Laravel akan menawarkan untuk membuatkannya untuk Anda saat kita menjalankan migration di langkah berikutnya.

> **Security note**: File `.env` sudah termasuk dalam `.gitignore` default Laravel. Ini berarti file tersebut tidak akan pernah di-commit ke Git, yang merupakan praktik yang benar karena file ini berisi informasi sensitif seperti password database.

---

## Step 2: Membuat Entry Model dan Migration {#step-2-create-the-entry-model-and-migration}

Laravel memungkinkan Anda membuat sebuah model beserta file migration-nya dalam satu perintah. Jalankan perintah berikut di terminal Anda:

```bash
php artisan make:model Entry -m
```

Flag `-m` berarti "buat juga file migration untuk model ini." Anda akan melihat output berikut:

```
$ php artisan make:model Entry -m

   INFO  Model [app/Models/Entry.php] created successfully.  

   INFO  Migration [database/migrations/2026_03_29_080101_create_entries_table.php] created successfully. 
```

Dua file dibuat sekaligus: model `Entry.php` di `app/Models/Entry.php` dan sebuah file migration di dalam `database/migrations/`. Kita akan kembali membahas model di lesson berikutnya. Untuk saat ini, mari fokus pada migration.

Perhatikan bagaimana Laravel secara otomatis mengetahui bahwa model bernama `Entry` harus berkorespondensi dengan tabel bernama `entries`. Ini adalah salah satu konvensi Laravel: nama model bersifat singular (`Entry`), dan nama tabel adalah bentuk plural-nya (`entries`). Anda tidak pernah perlu menentukan pemetaan ini secara manual.

---

## Step 3: Definisikan Struktur Table {#step-3-define-the-table-structure}

Buka file migration yang baru saja dibuat di dalam `database/migrations/`. Nama filenya diawali dengan timestamp, misalnya `2026_03_29_080101_create_entries_table.php`.

Berikut tampilannya:

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

Laravel menyediakan dua method di setiap migration. Method `up()` dijalankan saat Anda mengeksekusi `php artisan migrate`. Di sinilah Anda mendefinisikan apa yang akan dibuat. Method `down()` dijalankan saat Anda melakukan rollback migration. Method ini harus membatalkan apa pun yang dilakukan oleh `up()`. Dalam kasus ini, `up()` membuat tabel `entries` dan `down()` menghapusnya.

Migration default hanya menyertakan `id()` dan `timestamps()`. Kita perlu menambahkan kolom untuk data entri jurnal kita. Perbarui method `up()` agar terlihat seperti ini:

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

Berikut fungsi dari masing-masing kolom:

`$table->id()` membuat kolom `id` auto-incrementing sebagai primary key. Ini sudah disertakan dalam migration default. Setiap entri akan otomatis mendapatkan ID numerik yang unik.

`$table->foreignId('user_id')->constrained()->cascadeOnDelete()` membuat kolom `user_id` yang merupakan foreign key yang mengarah ke tabel `users`. Method `constrained()` secara otomatis mengatur relasi ke `users.id`. Bagian `cascadeOnDelete()` berarti jika seorang user dihapus, semua entri jurnal miliknya juga akan otomatis terhapus. Ini mencegah record yatim (orphaned records) tertinggal di database.

`$table->string('title')` membuat kolom `title` bertipe VARCHAR(255), cocok untuk teks pendek seperti judul entri.

`$table->text('content')` membuat kolom `content` bertipe TEXT, yang dapat menampung teks yang jauh lebih panjang dibandingkan VARCHAR. Ini sesuai untuk isi entri jurnal, yang bisa terdiri dari beberapa paragraf.

`$table->timestamps()` membuat dua kolom: `created_at` dan `updated_at`. Laravel mengisi kolom-kolom ini secara otomatis setiap kali sebuah record dibuat atau diperbarui, sehingga Anda tidak pernah perlu mengelolanya secara manual.

---

## Step 4: Jalankan Migration {#step-4-run-the-migration}

Setelah file migration siap, jalankan perintah berikut untuk membuat tabel di database:

```bash
php artisan migrate
```

Jika database `db_catatku` belum ada, Laravel akan menanyakan apakah Anda ingin membuatnya secara otomatis:

```
WARN  The database 'db_catatku' does not exist on the 'mysql' connection.

┌ Would you like to create it? ──────────────────────────────┐
│ ● Yes / ○ No                                               │
└────────────────────────────────────────────────────────────┘
```

Pilih `Yes`. Laravel akan membuat database tersebut dan menjalankan semua migration yang tertunda:

```
INFO  Running migrations.

  0001_01_01_000000_create_users_table .............. DONE
  0001_01_01_000001_create_cache_table .............. DONE
  0001_01_01_000002_create_jobs_table ............... DONE
  xxxx_xx_xx_create_entries_table .................. DONE
```

Perhatikan bahwa Laravel juga menjalankan beberapa migration bawaan. Migration `create_users_table` sangat penting karena kita akan membutuhkan tabel `users` saat membangun fitur authentication nanti. Foreign key `user_id` di tabel `entries` kita sudah mengarah ke tabel ini.

---

## Step 5: Verifikasi Table {#step-5-verify-the-table}

Untuk memastikan migration berhasil, Anda dapat memeriksa database menggunakan database manager bawaan Laragon atau MySQL client apa pun. Tabel `entries` harus memiliki enam kolom: `id`, `user_id`, `title`, `content`, `created_at`, dan `updated_at`.

Anda juga dapat memverifikasinya dari terminal dengan membuka Tinker REPL milik Laravel:

```bash
php artisan tinker
```

Lalu jalankan:

```php
Schema::getColumnListing('entries');
```

Output:
```
$ php artisan tinker
Psy Shell v0.12.22 (PHP 8.4.5 — cli) by Justin Hileman
New PHP manual is available (latest: 3.0.2). Update with `doc --update-manual`

> Schema::getColumnListing('entries');

= [
    "id",
    "user_id",
    "title",
    "content",
    "created_at",
    "updated_at",
  ]


```

Ini akan mengembalikan array berisi nama-nama kolom, yang mengonfirmasi bahwa tabel telah dibuat dengan struktur yang benar.

Ketik `exit` untuk keluar dari Tinker.

---

## Apa itu Migration? {#what-is-a-migration}

Sekarang setelah Anda membuat dan menjalankan sebuah migration, mari kita mundur sejenak untuk memahami mengapa pendekatan ini penting.

Sebelum migration ada, developer membuat tabel database secara manual melalui phpMyAdmin atau dengan menjalankan statement SQL mentah:

```sql
CREATE TABLE entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

Pendekatan ini memiliki masalah nyata. Tidak ada catatan tentang siapa yang membuat atau mengubah apa. Developer lain di tim harus menjalankan statement SQL yang sama secara manual di komputer mereka masing-masing. Dan jika terjadi kesalahan, rollback harus dilakukan secara manual.

**Migration** menyelesaikan semua masalah ini. Migration adalah file PHP yang mendefinisikan perubahan struktur database. Dengan migration, setiap perubahan pada database dilacak di Git seperti perubahan kode biasa. Mengatur database dari awal hanya membutuhkan satu perintah (`php artisan migrate`). Dan rollback pun sama mudahnya (`php artisan migrate:rollback`).

Ini adalah salah satu fitur Laravel yang paling berharga dalam lingkungan profesional. Ini bukan sekadar kemudahan dari framework. Ini adalah solusi nyata untuk masalah nyata yang dihadapi oleh setiap tim development.

---

## Rollback Migration {#rolling-back-migrations}

Jika Anda membuat kesalahan dalam sebuah migration dan perlu mengulanginya, Anda dapat melakukan rollback:

```bash
php artisan migrate:rollback
```

Perintah ini menjalankan method `down()` dari migration yang paling baru dieksekusi. Dalam kasus kita, ini akan menghapus tabel `entries`. Setelah memperbaiki file migration, Anda dapat menjalankan `php artisan migrate` lagi untuk membuat ulang tabel tersebut.

> **Important**: Rollback hanya aman dilakukan di lingkungan development. Di production, rollback dapat menyebabkan kehilangan data yang sebenarnya. Selalu periksa kembali migration Anda sebelum menjalankannya di production.

---

## Referensi Tipe Column Blueprint {#blueprint-column-types-reference}

Schema Builder milik Laravel menyediakan banyak tipe kolom melalui class `Blueprint`. Berikut beberapa yang paling sering Anda temui:

```php
$table->string('title');            // VARCHAR(255) for short text
$table->string('title', 100);      // VARCHAR(100) with a custom length
$table->text('content');            // TEXT for long, unbounded text
$table->integer('page_count');      // INTEGER
$table->decimal('price', 10, 2);   // DECIMAL for precise numbers like prices
$table->boolean('is_published');    // TINYINT(1) for true/false values
$table->foreignId('user_id');       // UNSIGNED BIGINT for foreign keys
```

Anda tidak perlu menghafal semua ini sekarang. Kita akan memperkenalkan setiap tipe saat dibutuhkan sepanjang course ini. Intinya adalah Laravel menyediakan method PHP untuk setiap tipe kolom umum, sehingga Anda tidak pernah perlu menulis SQL mentah untuk mendefinisikan struktur tabel Anda.

---

## Kesimpulan {#conclusion}

Lesson ini membawa Catatku dari data palsu menuju fondasi database yang sesungguhnya. Berikut poin-poin pentingnya:

- File **`.env`** menyimpan detail koneksi database Anda. Laravel membaca nilai-nilai ini untuk terhubung ke MySQL. File ini tidak boleh pernah di-commit ke Git.
- **Migration** adalah file PHP yang mendefinisikan perubahan struktur database. Migration dilacak di Git, dapat dijalankan dengan satu perintah, dan dapat di-rollback bila diperlukan.
- `php artisan make:model Entry -m` membuat model dan file migration dalam satu langkah. Laravel secara otomatis memetakan nama model singular (`Entry`) ke nama tabel plural (`entries`).
- Method **`up()`** mendefinisikan apa yang terjadi saat migration dijalankan. Method **`down()`** membatalkannya.
- `foreignId('user_id')->constrained()->cascadeOnDelete()` membuat relasi foreign key ke tabel `users` dan memastikan bahwa menghapus seorang user juga akan menghapus semua entri miliknya.
- `$table->string()` digunakan untuk teks pendek, `$table->text()` digunakan untuk teks panjang, dan `$table->timestamps()` secara otomatis menambahkan kolom `created_at` dan `updated_at`.
- `php artisan migrate` menjalankan semua migration yang tertunda. `php artisan migrate:rollback` membatalkan batch yang paling baru.
- Rollback aman dilakukan di development tetapi berbahaya di production karena dapat menyebabkan kehilangan data.

Di lesson berikutnya, kita akan mempelajari cara berkomunikasi dengan tabel `entries` yang baru saja kita buat menggunakan **Eloquent**, ORM milik Laravel. Alih-alih menulis SQL mentah, Anda akan menulis kode PHP yang ekspresif seperti `auth()->user()->entries()->latest()->get()`, dan Anda akan segera menyadari mengapa cara ini jauh lebih menyenangkan untuk bekerja dengan data.
